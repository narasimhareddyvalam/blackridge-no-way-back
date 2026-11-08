extends SceneTree

const PROJECTOR_PATH := "res://features/vehicles/freight_van/art/low_beam_pattern.png"
const HIGH_PATH := "res://features/vehicles/freight_van/art/high_beam_pattern.png"
const HALF_ANGLE := 35.0
const CUTOFF := 0.6
const WET_BARK := 0.6

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
	_check_patterns()
	_check_low_beam_shape()
	_check_wet_bark()
	await _check_beam_rain()
	_finish()


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


func _check_patterns() -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var high := Image.load_from_file(ProjectSettings.globalize_path(HIGH_PATH))
	var region := Rect2i(96, 108, 64, 12)
	var gain := _mean(high, region) / maxf(_mean(low, region), 0.001)
	_check(gain > 3.0 and _mean(high, Rect2i(0, 160, 256, 96)) >= _mean(low, Rect2i(0, 160, 256,
		96)) - 0.01, "High beams light far up the road, above the low beam's cutoff, "
		+ "and keep the low beam's near light (%.1fx brighter at the horizon)" % gain)


func _check_reach(lamp: SpotLight3D) -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var column := low.get_width() / 2
	var band := 0.0
	for row in range(low.get_height()):
		band = maxf(band, low.get_pixel(column, row).srgb_to_linear().r)
	var edge := 0
	while edge < low.get_height() and low.get_pixel(column, edge).srgb_to_linear().r < band * 0.1:
		edge += 1
	var tan_half := tan(deg_to_rad(HALF_ANGLE))
	var above_axis := rad_to_deg(atan(-((edge + 0.5) / (low.get_height() / 2.0) - 1.0) * tan_half))
	var pitch := rad_to_deg(asin(clampf(-lamp.global_basis.z.y, -1.0, 1.0)))
	var below := -(pitch + above_axis)
	var query := PhysicsRayQueryParameters3D.create(lamp.global_position,
		lamp.global_position + Vector3.DOWN * 5.0, 1, [_van.get_rid()])
	var hit := lamp.get_world_3d().direct_space_state.intersect_ray(query)
	var height := lamp.global_position.y - (hit["position"] as Vector3).y if not hit.is_empty() \
		else 1.0
	var reach := height / tan(deg_to_rad(below)) if below > 0.05 else INF
	_check(reach > 30.0 and reach < 50.0 and lamp.spot_range <= 80.0,
		"Low beams light the road to about %.0f m ahead and fade out by %.0f m" % [reach,
		lamp.spot_range])


func _check_low_beam_shape() -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var centre := _beam(low, 0.0, 1.3)
	var side := _beam(low, -20.0, 1.3)
	var ground := _beam(low, 0.0, 15.0)
	_check(side <= centre * 0.25 and ground <= centre * 0.1,
		"The low beam fades as a real one does: %.0f%% of its centre at 20 degrees to the side, "
		% (100.0 * side / maxf(centre, 0.001)) + "%.0f%% on the ground just ahead"
		% (100.0 * ground / maxf(centre, 0.001)))


func _beam(image: Image, side: float, below: float) -> float:
	var tan_half := tan(deg_to_rad(HALF_ANGLE))
	var cutoff := CUTOFF + clampf(side * tan(deg_to_rad(15.0)), 0.0, 1.0)
	var column := (tan(deg_to_rad(side)) / tan_half + 1.0) * image.get_width() / 2.0
	var row := (-tan(deg_to_rad(cutoff - below)) / tan_half + 1.0) * image.get_height() / 2.0
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
