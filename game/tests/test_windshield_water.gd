extends SceneTree
## The windshield's water as a real one (#346), step 1, the heavy film: on glass the blades have
## not wiped, drops grow and merge into blobs over tens of seconds (a second, slower wipe map, the
## soak), up to the size at which a drop starts sliding at the glass's rake (then it runs), and
## each drop is a lens showing a small inverted image of about 8 degrees of the scene behind it,
## so a lamp behind the glass appears in every drop near it. Merged patches 1.5-3.5 cm wide but no
## taller down the glass than a drop that holds still (its weight and its hold both grow with its
## width), and every drop and patch near a bright lamp catches its light (#346, the author's
## "Patches + catch light"): the world's lamps are handed to the van once, and the brightest eight
## on the glass, not hidden, are drawn into the water near them.

const RainPhysics = preload("res://features/vehicles/freight_van/rain_physics.gd")
const WipeMap = preload("res://features/vehicles/freight_van/windshield_wipe_map.gd")
const UNIFORMS: Array[String] = ["soak_mask", "blob_most", "blob_lens"]
const CATCH_UNIFORMS: Array[String] = ["catch_points", "catch_colours", "catch_reach",
	"patch_width", "patch_height"]
const CATCH_MOST := 8
const LAMPS_LEAST := 20
const PATCH_LEAST := 0.015
const PATCH_MOST := 0.035
const FACING_LAMPS := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
const FACING_SHED := Transform3D(Basis.IDENTITY, Vector3(-60.0, 0.1, 34.0))
const SEEN_NEAR := 0.6
const PATCH_HALF := 4.0
const SLIDE_LEAST := 0.002
const SLIDE_MOST := 0.008
const SOAKED_BY := Vector2(20.0, 0.9)
const STILL_GROWING_AT := Vector2(6.0, 0.6)

var _checks := 0
var _failures := 0
var _app: Node3D
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
	_scratch = OS.get_temp_dir().path_join("blackridge-windshield-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var van := _app.get_node("FreightVan") as Node3D
	var presentation := van.find_child("VanPresentation", true, false)
	var glass := presentation.get("_glass") as ShaderMaterial
	var names: Array[String] = []
	for uniform in glass.shader.get_shader_uniform_list():
		names.append(String(uniform["name"]))
	var missing := UNIFORMS.filter(func(name: String) -> bool: return not names.has(name))
	_check(missing.is_empty(), "W1: the windshield's shader takes the soak and its blobs (missing %s)"
		% [missing])
	var rake := float(presentation.get_script().get_script_constant_map()["WINDSHIELD_RAKE"])
	var down := Vector2(0.0, -cos(rake))
	var physics: Object = RainPhysics.new()
	var slide := float(physics.call("slide_radius", down)) \
		if physics.has_method("slide_radius") else 0.0
	var holds := slide > 0.0 and RainPhysics.drop_velocity(slide * 0.99, down, Vector2.ZERO) \
		== Vector2.ZERO and RainPhysics.drop_velocity(slide * 1.01, down, Vector2.ZERO) \
		!= Vector2.ZERO
	_check(holds and slide >= SLIDE_LEAST and slide <= SLIDE_MOST, ("W2: on the glass's rake a "
		+ "still drop holds just below %.2f mm and slides just above it (between %.0f and %.0f mm)")
		% [slide * 1000.0, SLIDE_LEAST * 1000.0, SLIDE_MOST * 1000.0])
	var most := _float(glass, "blob_most")
	_check(slide > 0.0 and absf(most - slide) < 0.00001, ("W3: the blobs grow to that size and "
		+ "no further (%.2f mm), then run") % [most * 1000.0])
	var camera := presentation.get("driving_camera") as Camera3D
	var lens := tan(deg_to_rad(PATCH_HALF)) / (2.0 * tan(deg_to_rad(camera.fov * 0.5)))
	var blob_lens := _float(glass, "blob_lens")
	_check(absf(blob_lens - lens) <= lens * 0.05, ("W4: each blob shows an inverted image of "
		+ "%.0f degrees of the scene behind it from the driver's eye (lens %.4f of the screen, "
		+ "wanted %.4f)") % [PATCH_HALF * 2.0, blob_lens, lens])
	var soak := glass.get_shader_parameter("soak_mask") as Texture2D
	var painters := presentation.find_children("*", "Node2D", true, false).filter(
		func(node: Node) -> bool: return node.get_script() == WipeMap)
	var slow: Node = null
	var seconds := 0.0
	for painter in painters:
		var value: Variant = painter.get("rewet_seconds")
		if value != null and float(value) > WipeMap.REWET_SECONDS:
			slow = painter
			seconds = float(value)
	var builds := seconds > 0.0 and 1.0 - exp(-SOAKED_BY.x / seconds) >= SOAKED_BY.y \
		and 1.0 - exp(-STILL_GROWING_AT.x / seconds) <= STILL_GROWING_AT.y
	var fed: bool = soak != null and slow != null and soak == (slow.get_parent() as SubViewport) \
		.get_texture() and slow.get("vehicle") == van
	_check(builds and fed, ("W5: the soak is a second wipe map that the blades wipe as they do the "
		+ "first, filling over %.1f s: at least %.0f%% by %.0f s, no more than %.0f%% by %.0f s")
		% [seconds, SOAKED_BY.y * 100.0, SOAKED_BY.x, STILL_GROWING_AT.y * 100.0,
		STILL_GROWING_AT.x])
	await _catches(van, presentation, glass, names)
	_finish()


func _catches(van: Node3D, presentation: Node, glass: ShaderMaterial,
		names: Array[String]) -> void:
	var missing := CATCH_UNIFORMS.filter(func(name: String) -> bool: return not names.has(name))
	_check(missing.is_empty(), "W6: the shader takes the lamps' catch light and the patches "
		+ "(missing %s)" % [missing])
	var lamps: Array = presentation.get("lamps") if presentation.get("lamps") != null else []
	var worldly := lamps.size() >= LAMPS_LEAST and lamps.all(func(lamp: Variant) -> bool:
		return lamp is Light3D and not van.is_ancestor_of(lamp))
	_check(worldly, "W7: the world's lamps are handed to the van, none of its own (%d)"
		% lamps.size())
	van.call("recover", FACING_LAMPS)
	for step in range(10):
		await physics_frame
	await process_frame
	var points: Variant = glass.get_shader_parameter("catch_points")
	var caught: Array[Vector4] = []
	if points is PackedVector4Array or points is Array:
		for point: Vector4 in points:
			if point.z > 0.0:
				caught.append(point)
	var eye := (presentation.get("driving_camera") as Camera3D).global_position
	var half := WipeMap.GLASS_SIZE * 0.5
	var matched := not caught.is_empty() and caught.size() <= CATCH_MOST
	var falling := true
	for index in range(caught.size()):
		var point := caught[index]
		if index > 0 and point.z > caught[index - 1].z:
			falling = false
		var nearest := INF
		for lamp: Light3D in lamps:
			var at: Vector2 = presentation.call("_on_windshield", eye, lamp.global_position)
			nearest = minf(nearest, at.distance_to(Vector2(point.x, point.y)))
		matched = matched and nearest < 0.001 and absf(point.x) <= half.x \
			and absf(point.y) <= half.y
	_check(matched and falling, ("W8: facing the yard's lamps, the brightest on the glass (%d, "
		+ "at most %d) are drawn where each lamp is seen through the glass, brightest first")
		% [caught.size(), CATCH_MOST])
	van.call("recover", FACING_SHED)
	for step in range(10):
		await physics_frame
	await process_frame
	var shed_eye := (presentation.get("driving_camera") as Camera3D).global_position
	var hidden := 0
	var shown := 0
	var lit: Variant = glass.get_shader_parameter("catch_points")
	for point: Vector4 in lit:
		if point.z <= 0.0:
			continue
		shown += 1
		for lamp: Light3D in lamps:
			var at: Vector2 = presentation.call("_on_windshield", shed_eye, lamp.global_position)
			if at.distance_to(Vector2(point.x, point.y)) < 0.001 and _hidden(van, shed_eye,
					lamp.global_position):
				hidden += 1
	var behind := 0
	for lamp: Light3D in lamps:
		if presentation.call("_on_windshield", shed_eye, lamp.global_position) != Vector2(9.0, 9.0) \
				and _hidden(van, shed_eye, lamp.global_position):
			behind += 1
	_check(behind > 0 and hidden == 0, ("W11: facing the shed, none of the %d lamps caught is "
		+ "hidden from the driver's eye, though %d lamps on the glass are behind its walls")
		% [shown, behind])
	var pane := (presentation.get("_windshield") as Node3D).global_position
	var reach := tan(deg_to_rad(PATCH_HALF)) * shed_eye.distance_to(pane)
	var catch_reach := _float(glass, "catch_reach")
	_check(absf(catch_reach - reach) <= reach * 0.1, ("W9: a drop catches a lamp within its lens's "
		+ "%.0f degrees: %.1f cm on the glass (wanted %.1f)") % [PATCH_HALF, catch_reach * 100.0,
		reach * 100.0])
	var width: Variant = glass.get_shader_parameter("patch_width")
	var wide: bool = width is Vector2 and width.x >= PATCH_LEAST - 0.000001 and width.y <= PATCH_MOST + 0.000001 \
		and width.x < width.y
	var tall := _float(glass, "patch_height")
	_check(wide and absf(tall - 2.0 * _float(glass, "blob_most")) < 0.00001, ("W10: patches %s m "
		+ "wide, no taller down the glass than a still drop is across (%.2f mm)")
		% [width, tall * 1000.0])


func _hidden(van: Node3D, eye: Vector3, target: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(eye, target, 1, [(van as CollisionObject3D).get_rid()])
	var hit := van.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and (hit.position as Vector3).distance_to(target) > SEEN_NEAR


func _float(material: ShaderMaterial, name: String) -> float:
	var value: Variant = material.get_shader_parameter(name)
	return float(value) if value != null else 0.0


func _finish() -> void:
	print("WINDSHIELD WATER RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The windshield water test finished within 120 s of game time")
	quit(1)
