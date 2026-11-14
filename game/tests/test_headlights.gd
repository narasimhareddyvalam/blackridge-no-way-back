extends SceneTree

const PROJECTOR_PATH := "res://features/vehicles/freight_van/art/low_beam_pattern.png"
const HIGH_PATH := "res://features/vehicles/freight_van/art/high_beam_pattern.png"
const MEASURED_PATH := "../tools/data/umtri_2004_23_low_beam_medians.csv"
const HIGH_MEASURED_PATH := "../tools/data/umtri_2001_19_us_high_beam_medians.csv"
const LENS_SHADER := "res://features/vehicles/freight_van/headlamp_lens.gdshader"
const ONCOMING_SCENE := "res://features/vehicles/oncoming_van/oncoming_van.gd"
const MIST_SHADER := "res://features/vehicles/freight_van/beam_mist.gdshader"
const WORLD_SCRIPT := "res://features/environments/industrial_loop/industrial_loop.gd"
const HALF_ANGLE := 35.0
const WET_BARK := 0.6
## UN Regulation 48, 6.2.6.1.2: the dipped beam's initial aim, per cent: under 0.8 m up -1.0 to
## -1.5; from 0.8 m, -1.5 to -2.0 (between 0.8 and 1.0 m the manufacturer's second alternative,
## over 1.0 m the only one).
const R48_LOW := Vector2(-1.0, -1.5)
const R48_HIGH := Vector2(-1.5, -2.0)
const HOT_SPOT_BELOW := 1.0
const HIGH_TILT := 0.0
const LOW_TILT := -1.25
## UMTRI-2001-19's high-beam test points, [degrees right, degrees up].
const HIGH_POINTS: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(0.0, -2.0), Vector2(-10.0, 0.0),
	Vector2(10.0, 0.0), Vector2(0.0, 3.0), Vector2(20.0, 0.0), Vector2(0.0, -4.0),
	Vector2(-5.0, 1.5)]
const MATCH := 0.2
## UMTRI-2004-23's test points, [degrees right, degrees up], away from the cutoff's steep edge.
const TEST_POINTS: Array[Vector2] = [Vector2(1.0, -1.0), Vector2(0.0, -2.0), Vector2(-10.0, -2.0),
	Vector2(10.0, -2.0), Vector2(20.0, -1.0), Vector2(-5.0, -3.0), Vector2(0.0, -4.0),
	Vector2(0.0, 1.5)]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	await _start_game()
	var lights := _headlights()
	_check(lights.size() == 2, "The van has two headlight SpotLight3Ds (found %d)" % lights.size())
	var camera: Camera3D = _van.call("get_camera")
	for index in range(lights.size()):
		var light := lights[index]
		_check(light.layers & camera.cull_mask != 0,
			"Headlight %d is on a layer the driving camera sees (layers %d, cull mask %d)" % [
			index, light.layers, camera.cull_mask])
		_check(light.light_cull_mask & 1 != 0, "Headlight %d lights the world layer" % index)
		_check(light.shadow_enabled, "Headlight %d casts shadows, which its pattern needs" % index)
		_check(light.light_projector != null
			and light.light_projector.resource_path == PROJECTOR_PATH,
			"Headlight %d uses the low-beam pattern" % index)
	_check(_van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, true) and _all_patterns(lights, PROJECTOR_PATH),
		"Headlights start on, on low beams")
	await _press("headlights")
	await _wait_physics(3)
	_check(_van.get("headlights_on") and _van.get("high_beams") and _all_visible(lights, true)
		and _all_patterns(lights, HIGH_PATH) and lights[0].spot_range > 200.0,
		"A real L press switches both headlights to high beams")
	var high_energy := lights[0].light_energy
	var high_range := lights[0].spot_range
	await _press("headlights")
	await _wait_physics(3)
	_check(not _van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, false), "A second L press switches both headlights off")
	await _press("headlights")
	await _wait_physics(3)
	_check(_van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, true) and _all_patterns(lights, PROJECTOR_PATH),
		"A third L press brings the low beams back")
	_check(high_range >= 250.0 and high_energy > lights[0].light_energy,
		"High beams reach %.0f m, with more light than the low beams (%.0f against %.0f)"
		% [high_range, high_energy, lights[0].light_energy])
	_check_reach(lights[0])
	_check_patterns(lights)
	_check_high_measured(lights)
	_check_low_beam_shape()
	_check_measured()
	_check_imported(lights)
	_check_aim(lights)
	_check_wet_bark()
	await _check_beam_rain()
	await _check_beam_mist(lights)
	await _check_lens()
	await _check_oncoming()
	_finish()


func _check_lens() -> void:
	var lens := _van.get_node("VanPresentation").get("_front_lenses")[0] as MeshInstance3D
	var states := {}
	for state in ["low", "high", "off"]:
		var air := lens.material_override as ShaderMaterial
		states[state] = Vector2(-1.0, -1.0) if air == null or air.shader == null \
			or air.shader.resource_path != LENS_SHADER else Vector2(
			float(air.get_shader_parameter("low_lit")), float(air.get_shader_parameter("high_lit")))
		await _press("headlights")
		await _wait_physics(3)
	var shader := load(LENS_SHADER) as Shader
	var clear := shader != null and shader.code.contains("ALPHA")
	_check(states["low"] == Vector2(1, 0) and states["high"] == Vector2(1, 1)
		and states["off"] == Vector2(0, 0) and clear,
		"The headlamps light as real ones do, behind their clear covers: the low-beam projector on "
		+ "low beams, the high-beam reflector too on high beams, nothing with the lights off, so "
		+ "the housing and the indicator show through (%s)" % states)


func _check_oncoming() -> void:
	await process_frame
	var oncoming := (load(ONCOMING_SCENE) as GDScript).new() as Node3D
	_app.add_child(oncoming)
	oncoming.call("configure", _app.get_node("IndustrialLoop").get("road"), _van, 0, 100)
	oncoming.set_physics_process(false)
	oncoming.set_process(false)
	var lamps: Array = oncoming.get("lamps")
	var script := _van.get_node("VanPresentation").get_script() as GDScript
	var constants := script.get_script_constant_map()
	var lens := oncoming.get_node("Iveco/Headlights") as MeshInstance3D
	var lit := lens.material_override is ShaderMaterial \
		and (lens.material_override as ShaderMaterial).shader.resource_path == LENS_SHADER
	var matched := not lamps.is_empty()
	for high in [true, false]:
		oncoming.call("_set_high", high)
		for lamp: SpotLight3D in lamps:
			var tilt := float(constants["HIGH_BEAM_TILT" if high else "LOW_BEAM_TILT"])
			var energy := float(constants["HIGH_BEAM_ENERGY" if high else "LOW_BEAM_ENERGY"])
			matched = matched and absf(lamp.rotation_degrees.x - tilt) < 0.01 \
				and absf(lamp.light_energy - energy) < 0.5
	oncoming.queue_free()
	_check(matched and lit, "The oncoming van's headlamps are aimed, as bright and lit as the "
		+ "player's, on both beams")


func _check_measured() -> void:
	var table := _measured()
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var peak: float = table["peak"]
	var worst := 1.0
	var notes: Array[String] = []
	for point in TEST_POINTS:
		var measured: float = _table_at(table, point.x, point.y) / peak
		var drawn := _beam(low, point.x, point.y)
		var ratio := drawn / maxf(measured, 1e-6)
		worst = maxf(worst, maxf(ratio, 1.0 / maxf(ratio, 1e-6)))
		notes.append("%s %.0f/%.0f cd" % [point, drawn * peak, measured * peak])
	_check(table["rows"] > 20 and worst <= 1.0 + MATCH,
		"The low beam is UMTRI-2004-23's measured US low beam, within %.0f%% at its test points "
		% (100.0 * MATCH) + "(%s)" % ", ".join(notes))


func _check_imported(lights: Array[SpotLight3D]) -> void:
	var worst := 0.0
	for pair in [[lights[0].light_projector, PROJECTOR_PATH], [load(HIGH_PATH), HIGH_PATH]]:
		var source := Image.load_from_file(ProjectSettings.globalize_path(pair[1]))
		var used: Image = (pair[0] as Texture2D).get_image() if pair[0] != null else null
		if used == null or used.get_size() != source.get_size():
			worst = 1.0
			continue
		for y in range(0, source.get_height(), 4):
			for x in range(0, source.get_width(), 4):
				worst = maxf(worst, absf(used.get_pixel(x, y).r - source.get_pixel(x, y).r))
	_check(worst <= 1.5 / 255.0, "The headlights shine both patterns as drawn, not a stale "
		+ "import (largest difference %.0f of 255)" % (worst * 255.0))


func _check_aim(lights: Array[SpotLight3D]) -> void:
	var lamp := lights[0]
	var pitch := rad_to_deg(asin(clampf(-lamp.global_basis.z.y, -1.0, 1.0))) \
		- rad_to_deg(asin(clampf(-_van.global_basis.z.y, -1.0, 1.0)))
	var cutoff := _cutoff(_measured())
	var inclination := 100.0 * tan(deg_to_rad(cutoff + pitch))
	var lens := _van.get_node("VanPresentation").get("_front_lenses")[0] as MeshInstance3D
	var lower := lens.global_transform * lens.get_aabb().position
	var query := PhysicsRayQueryParameters3D.create(lower + Vector3.UP, lower + Vector3.DOWN * 3.0,
		1, [_van.get_rid()])
	var hit := lamp.get_world_3d().direct_space_state.intersect_ray(query)
	var height := lower.y - (hit["position"] as Vector3).y if not hit.is_empty() else 0.0
	var aim := R48_HIGH if height >= 0.8 else R48_LOW
	_check(inclination <= aim.x and inclination >= aim.y,
		"The low beams are aimed as UN Regulation 48 allows lamps %.2f m up: the " % height
		+ "cutoff %.2f%% down (%.2f degrees "
		% [-inclination, -(cutoff + pitch)] + "below the horizon), within %.1f%% to %.1f%%"
		% [-aim.x, -aim.y])


func _cutoff(table: Dictionary) -> float:
	var ups: PackedFloat64Array = table["ups"]
	var column := (table["sides"] as PackedFloat64Array).find(0.0)
	var steepest := 0.0
	var at := 0.0
	for row in range(ups.size() - 1):
		if ups[row] > 2.0 or ups[row + 1] < -1.0:
			continue
		var upper := (table["values"][row] as PackedFloat64Array)[column]
		var lower := (table["values"][row + 1] as PackedFloat64Array)[column]
		var gradient := (log(lower) - log(upper)) / (ups[row] - ups[row + 1])
		if gradient > steepest:
			steepest = gradient
			at = (ups[row] + ups[row + 1]) / 2.0
	return at


func _check_beam_mist(lights: Array[SpotLight3D]) -> void:
	var low_ok := _mists_follow(lights)
	await _press("headlights")
	await _wait_physics(3)
	var high_ok := _mists_follow(lights)
	var high_pitch := rad_to_deg(asin(clampf(-lights[0].global_basis.z.y, -1.0, 1.0))) \
		- rad_to_deg(asin(clampf(-_van.global_basis.z.y, -1.0, 1.0)))
	await _press("headlights")
	await _wait_physics(3)
	var dark := true
	for light in lights:
		var mist := _mist(light)
		dark = dark and mist != null and not mist.is_visible_in_tree()
	await _press("headlights")
	await _wait_physics(3)
	var world_mist: float = (load(WORLD_SCRIPT) as GDScript).get_script_constant_map().get(
		"MIST_SCATTERING", -1.0)
	var scattering := -1.0
	if _mist(lights[0]) != null:
		scattering = float((_mist(lights[0]).material_override as ShaderMaterial)
			.get_shader_parameter("scattering"))
	_check(low_ok and high_ok, "Each beam lights the rain-filled air it crosses, with its own "
		+ "pattern, reach and strength, on low and on high beams")
	_check(dark, "No haze shows with the headlights off")
	_check(absf(scattering - world_mist) < 1e-6,
		"The beams' air scatters as the street lamps' does (%.3f against %.3f)" % [scattering,
		world_mist])
	_check(absf(high_pitch - HIGH_TILT) < 0.05,
		"High beams are aimed level, as the measured lamps (%.1f degrees)" % high_pitch)


func _mists_follow(lights: Array[SpotLight3D]) -> bool:
	for light in lights:
		var mist := _mist(light)
		if mist == null or not mist.is_visible_in_tree():
			return false
		var air := mist.material_override as ShaderMaterial
		var colour := light.light_color.srgb_to_linear() * light.light_energy
		if air.get_shader_parameter("pattern") != light.light_projector \
				or absf(float(air.get_shader_parameter("light_range")) - light.spot_range) > 0.01 \
				or (air.get_shader_parameter("light_colour") as Vector3).distance_to(
				Vector3(colour.r, colour.g, colour.b)) > 0.01:
			return false
	return not lights.is_empty()


func _mist(light: SpotLight3D) -> MeshInstance3D:
	for child in light.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override is ShaderMaterial:
			var air := (child as MeshInstance3D).material_override as ShaderMaterial
			if air.shader != null and air.shader.resource_path == MIST_SHADER:
				return child
	return null


func _table_lerp(table: Dictionary, side: float, up: float) -> float:
	var sides: PackedFloat64Array = table["sides"]
	var ups: PackedFloat64Array = table["ups"]
	if sides.is_empty():
		return 0.0
	up = clampf(up, ups[ups.size() - 1], ups[0])
	var row := 0
	while row < ups.size() - 2 and ups[row + 1] > up:
		row += 1
	var column := 0
	while column < sides.size() - 2 and sides[column + 1] < side:
		column += 1
	var across := (side - sides[column]) / (sides[column + 1] - sides[column])
	var down := (ups[row] - up) / (ups[row] - ups[row + 1])
	var values: Array = table["values"]
	var top := lerpf(log((values[row] as PackedFloat64Array)[column]),
		log((values[row] as PackedFloat64Array)[column + 1]), across)
	var bottom := lerpf(log((values[row + 1] as PackedFloat64Array)[column]),
		log((values[row + 1] as PackedFloat64Array)[column + 1]), across)
	return exp(lerpf(top, bottom, down))


func _measured(relative: String = MEASURED_PATH) -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(relative).simplify_path()
	var file := FileAccess.open(path, FileAccess.READ)
	var result := {"sides": PackedFloat64Array(), "ups": PackedFloat64Array(), "values": [],
		"peak": 1.0, "rows": 0}
	if file == null:
		return result
	var header := file.get_csv_line()
	for index in range(1, header.size()):
		result["sides"].append(float(header[index]))
	var peak := 0.0
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < 2:
			continue
		result["ups"].append(float(line[0]))
		var values := PackedFloat64Array()
		for index in range(1, line.size()):
			values.append(float(line[index]))
			peak = maxf(peak, float(line[index]))
		result["values"].append(values)
	result["peak"] = peak
	result["rows"] = (result["ups"] as PackedFloat64Array).size()
	return result


func _table_at(table: Dictionary, side: float, up: float) -> float:
	var sides: PackedFloat64Array = table["sides"]
	var ups: PackedFloat64Array = table["ups"]
	var column := sides.find(side)
	var row := ups.find(up)
	if column < 0 or row < 0:
		return 0.0
	return (table["values"][row] as PackedFloat64Array)[column]


func _check_beam_rain() -> void:
	var presentation := _van.get_node("VanPresentation")
	var layers: Array = presentation.get("_rain_layers")
	var rain: ShaderMaterial = presentation.get("_beam_rain_material")
	var low_lit := _rain_shows(layers, true) and _rain_pattern(rain) == PROJECTOR_PATH
	var low_glow := float(rain.get_shader_parameter("glow"))
	await _press("headlights")
	await _wait_physics(3)
	var high_lit := _rain_shows(layers, true) and _rain_pattern(rain) == HIGH_PATH \
		and float(rain.get_shader_parameter("reach")) > 200.0
	var high_glow := float(rain.get_shader_parameter("glow"))
	await _press("headlights")
	await _wait_physics(3)
	var dark := _rain_shows(layers, false)
	await _press("headlights")
	await _wait_physics(3)
	_check(layers.size() >= 6 and low_lit and high_lit,
		"Rain falls through the beams, lit by the low and then the high pattern (%d layers)"
		% layers.size())
	_check(dark and _rain_shows(layers, true), "No rain shows in the dark with the lights off")
	_check(high_glow >= low_glow * 3.0 and low_glow > 0.0,
		"High beams show at least 3x as much rain as low beams (%.1f against %.1f)" % [
		high_glow, low_glow])


func _rain_shows(layers: Array, expected: bool) -> bool:
	for layer: MeshInstance3D in layers:
		if layer.visible != expected:
			return false
	return not layers.is_empty()


func _rain_pattern(rain: ShaderMaterial) -> String:
	var pattern: Texture2D = rain.get_shader_parameter("pattern")
	return pattern.resource_path if pattern != null else ""


func _check_patterns(lights: Array[SpotLight3D]) -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var high := Image.load_from_file(ProjectSettings.globalize_path(HIGH_PATH))
	var energies := _energies(lights)
	var gain := _beam(high, 0.0, 1.0) * energies.y / maxf(_beam(low, 0.0, 1.0 - LOW_TILT)
		* energies.x, 1e-6)
	var near_high := _beam(high, 0.0, -8.0) * energies.y
	var near_low := _beam(low, 0.0, -8.0 - LOW_TILT) * energies.x
	_check(gain > 3.0 and near_high >= near_low * 0.97,
		"High beams light far up the road, above the low beam's cutoff, and keep the low beam's "
		+ "near light (%.1fx brighter 1 degree above the horizon, %.0f%% of it 8 degrees down)"
		% [gain, 100.0 * near_high / maxf(near_low, 1e-6)])


func _energies(lights: Array[SpotLight3D]) -> Vector2:
	var low := lights[0].light_energy if not _van.get("high_beams") else 0.0
	var script := _van.get_node("VanPresentation").get_script() as GDScript
	var constants := script.get_script_constant_map()
	return Vector2(float(constants.get("LOW_BEAM_ENERGY", low)),
		float(constants.get("HIGH_BEAM_ENERGY", 0.0)))


func _check_high_measured(lights: Array[SpotLight3D]) -> void:
	var high_table := _measured(HIGH_MEASURED_PATH)
	var low_table := _measured()
	var high := Image.load_from_file(ProjectSettings.globalize_path(HIGH_PATH))
	var both_peak := 0.0
	var worst := 1.0
	var notes: Array[String] = []
	var expected: Array[float] = []
	for point in HIGH_POINTS:
		var candelas := _table_at(high_table, point.x, point.y) + _table_lerp(low_table, point.x,
			point.y + HIGH_TILT - LOW_TILT)
		expected.append(candelas)
	for up in range(-50, 71, 5):
		for side in [-3.0, -1.0, 0.0, 1.0, 2.0, 3.0]:
			both_peak = maxf(both_peak, _table_lerp(high_table, side, up / 10.0)
				+ _table_lerp(low_table, side, up / 10.0 + HIGH_TILT - LOW_TILT))
	for index in range(HIGH_POINTS.size()):
		var drawn := _beam(high, HIGH_POINTS[index].x, HIGH_POINTS[index].y) * both_peak
		var ratio := drawn / maxf(expected[index], 1e-6)
		worst = maxf(worst, maxf(ratio, 1.0 / maxf(ratio, 1e-6)))
		notes.append("%s %.0f/%.0f cd" % [HIGH_POINTS[index], drawn, expected[index]])
	var energies := _energies(lights)
	var per_candela := energies.x / float(low_table["peak"])
	var high_energy := both_peak * per_candela
	_check(high_table["rows"] > 20 and worst <= 1.0 + MATCH,
		"High beams are UMTRI-2001-19's measured US high beam with the low beam still lit, within "
		+ "%.0f%% (%s)" % [100.0 * MATCH, ", ".join(notes)])
	_check(absf(energies.y - high_energy) <= high_energy * 0.02,
		"High beams are as much brighter as the measured lamps: %.0f cd at their brightest "
		% both_peak + "against the low beam's %.0f, energy %.0f against %.0f"
		% [float(low_table["peak"]), energies.y, energies.x])


func _check_reach(lamp: SpotLight3D) -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var pitch := rad_to_deg(asin(clampf(-lamp.global_basis.z.y, -1.0, 1.0)))
	var height := _lamp_height(lamp)
	var near := _road_light(low, lamp, pitch, height, 10.0)
	var middle := _road_light(low, lamp, pitch, height, 40.0) / maxf(near, 1e-9)
	var far := _road_light(low, lamp, pitch, height, 55.0) / maxf(near, 1e-9)
	_check(middle >= 0.03 and far <= 0.01 and lamp.spot_range <= 80.0,
		"Low beams light the road to about 40 m ahead (%.0f%% of their light 10 m ahead) and "
		% (100.0 * middle) + "fade out by 55 m (%.1f%%), the light gone by %.0f m"
		% [100.0 * far, lamp.spot_range])


func _road_light(image: Image, lamp: SpotLight3D, pitch: float, height: float,
		ahead: float) -> float:
	var reach := sqrt(height * height + ahead * ahead)
	var below := rad_to_deg(atan(height / ahead))
	var window := pow(maxf(1.0 - pow(reach / lamp.spot_range, 4.0), 0.0), 2.0)
	return _beam(image, 0.0, -below - pitch) * height / pow(reach, 3.0) * window


func _lamp_height(lamp: SpotLight3D) -> float:
	var query := PhysicsRayQueryParameters3D.create(lamp.global_position,
		lamp.global_position + Vector3.DOWN * 5.0, 1, [_van.get_rid()])
	var hit := lamp.get_world_3d().direct_space_state.intersect_ray(query)
	return lamp.global_position.y - (hit["position"] as Vector3).y if not hit.is_empty() else 1.0


func _check_low_beam_shape() -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var centre := _beam(low, 0.0, -HOT_SPOT_BELOW)
	var side := maxf(_beam(low, -20.0, -HOT_SPOT_BELOW), _beam(low, 20.0, -HOT_SPOT_BELOW))
	var ground := _beam(low, 0.0, -15.0)
	_check(side <= centre * 0.25 and ground <= centre * 0.1,
		"The low beam fades as a real one does: %.0f%% of its centre at 20 degrees to the side, "
		% (100.0 * side / maxf(centre, 0.001)) + "%.0f%% on the ground just ahead"
		% (100.0 * ground / maxf(centre, 0.001)))


func _beam(image: Image, side: float, up: float) -> float:
	var tan_half := tan(deg_to_rad(HALF_ANGLE))
	var column := (tan(deg_to_rad(side)) / tan_half + 1.0) * image.get_width() / 2.0
	var row := (-tan(deg_to_rad(up)) / tan_half + 1.0) * image.get_height() / 2.0
	return image.get_pixel(clampi(int(column), 0, image.get_width() - 1),
		clampi(int(row), 0, image.get_height() - 1)).srgb_to_linear().r


func _check_wet_bark() -> void:
	var shades: Array[float] = []
	var forest := _app.get_node("IndustrialLoop/RoadsideForest")
	for node in forest.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		if node is MeshInstance3D:
			mesh = (node as MeshInstance3D).mesh
		elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
			mesh = (node as MultiMeshInstance3D).multimesh.mesh
		if mesh == null:
			continue
		for surface in range(mesh.get_surface_count()):
			var bark := mesh.surface_get_material(surface) as ORMMaterial3D
			if bark != null and bark.albedo_texture != null \
					and bark.albedo_texture.resource_path.contains("pine_bark"):
				shades.append(bark.albedo_color.r)
	var lightest: float = shades.max() if not shades.is_empty() else 1.0
	_check(not shades.is_empty() and absf(lightest - WET_BARK) < 0.01,
		"The trunks' bark is darkened for the rain (the lightest bark is %.0f%% of the dry "
		% (100.0 * lightest) + "texture)")


func _mean(image: Image, region: Rect2i) -> float:
	var total := 0.0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			total += image.get_pixel(x, y).srgb_to_linear().r
	return total / float(region.get_area())


func _start_game() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-headlights-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	await process_frame
	_app.call("_resume")
	await _wait_physics(10)


func _headlights() -> Array[SpotLight3D]:
	var result: Array[SpotLight3D] = []
	for node in _van.find_children("*", "SpotLight3D", true, false):
		var light := node as SpotLight3D
		if (_van.global_basis.inverse() * -light.global_basis.z).z < -0.8:
			result.append(light)
	return result


func _all_patterns(lights: Array[SpotLight3D], path: String) -> bool:
	for light in lights:
		if light.light_projector == null or light.light_projector.resource_path != path:
			return false
	return not lights.is_empty()


func _all_visible(lights: Array[SpotLight3D], expected: bool) -> bool:
	for light in lights:
		if light.visible != expected:
			return false
	return not lights.is_empty()


func _press(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _wait_physics(count: int) -> void:
	for step in range(count):
		await physics_frame


func _finish() -> void:
	print("HEADLIGHTS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Headlight test finished within 120 s of game time")
	quit(1)
