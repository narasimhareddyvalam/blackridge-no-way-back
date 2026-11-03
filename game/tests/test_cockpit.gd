extends SceneTree

const ART := "res://features/vehicles/freight_van/art/"
const EXTERIOR := "iveco/iveco_exterior.glb"
const CAB := "iveco/iveco_cab.glb"
const OLD_PARTS := ["body.glb", "door.glb", "tire.glb", "cabin.glb", "steering.glb",
	"cockpit/cockpit_front.gltf", "cockpit/cockpit_back.gltf", "cockpit/cockpit_roof.gltf",
	"cockpit/cockpit_wheel.gltf", "cockpit/cockpit_shadow.glb", "cockpit/cockpit_wheel_shadow.glb"]
const SCREEN_SHADER := "res://features/vehicles/freight_van/cockpit_screen.gdshader"
const SIDE_RAIN := "res://features/vehicles/freight_van/side_window_rain.gdshader"
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const VAN_TRIANGLES := 88428
const WHEEL_HUB := Vector3(-0.476, 1.473, -1.142)
const COLUMN := Vector3(0.0, 0.703, 0.711)
const ROOF_CROSSINGS: Array[Vector2] = [Vector2(-0.4, -0.7), Vector2(-0.2, -0.6),
	Vector2(0.0, -0.7), Vector2(0.3, -0.5), Vector2(-0.3, -0.45)]
const ON_DASH := 0.012

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
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
	_check_art()
	_check_layers_and_shadows()
	_check_screens()
	_check_mirrors()
	_check_moon_roof()
	await _check_wheel()
	_finish()


func _start_game() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-cockpit-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	_app.call("_resume")
	await _wait_physics(10)


func _check_art() -> void:
	var scenes := _scenes()
	_check(scenes.has(EXTERIOR) and scenes.has(CAB),
		"The van is the Iveco: it draws %s and %s (C31)" % [EXTERIOR, CAB])
	var old: Array[String] = []
	for part: String in OLD_PARTS:
		if scenes.has(part):
			old.append(part)
	_check(old.is_empty(), "No part of the old van or the Honda cockpit is drawn (the files stay "
		+ "in the repo; drawn: %s)" % ", ".join(old))
	var triangles := 0
	for mesh: MeshInstance3D in _van_meshes():
		for surface in mesh.mesh.get_surface_count():
			var indices: int = mesh.mesh.surface_get_array_index_len(surface)
			var corners: int = mesh.mesh.surface_get_array_len(surface)
			triangles += (indices if indices > 0 else corners) / 3
	_check(triangles == VAN_TRIANGLES, "The van draws all of the converted Iveco (%d triangles)"
		% triangles)


func _check_layers_and_shadows() -> void:
	var scenes := _scenes()
	var outside: Array[MeshInstance3D] = _meshes(scenes.get(EXTERIOR))
	var inside: Array[MeshInstance3D] = _meshes(scenes.get(CAB))
	var body_layer := not outside.is_empty()
	for mesh in outside:
		body_layer = body_layer and mesh.layers == 2
	var cab_layer := not inside.is_empty()
	var no_shadow := true
	for mesh in inside:
		cab_layer = cab_layer and mesh.layers == 4
		no_shadow = no_shadow and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for glass: MeshInstance3D in [_presentation.get("_windshield")] + _presentation.get("_windows"):
		cab_layer = cab_layer and glass.layers == 4
	_check(body_layer, "The outside (body, doors, wheels and lamps; %d meshes) is on the body "
		% outside.size() + "layer, which the mirrors draw")
	_check(cab_layer, "The cab, steering wheel and glass (%d meshes) are on the cabin layer, which "
		% (inside.size() + 3) + "the mirrors never draw")
	var camera: Camera3D = _presentation.get("driving_camera")
	var mirrors_ok := true
	for mirror: Camera3D in _presentation.get("mirror_cameras"):
		mirrors_ok = mirrors_ok and mirror.cull_mask == 3
	_check(camera.cull_mask == 7 and mirrors_ok,
		"From the seat the driver sees the world, the van's own body and the cab; the mirrors see "
		+ "the world and the body")
	var body := (scenes.get(EXTERIOR) as Node).get_node_or_null("Body") as MeshInstance3D
	_check(body != null and body.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		and no_shadow, "The body casts the van's shadow; the cab inside it casts none")


func _check_screens() -> void:
	var cluster := _screen_showing(_cluster_viewport())
	var map_view := (_presentation.get("navigation") as Node).get_parent() as SubViewport
	var map := _screen_showing(map_view)
	var reverse_view: SubViewport = _presentation.get("reverse_view")
	var reverse := _screen_showing(reverse_view)
	var eye: Vector3 = Presentation.EYE
	_check(cluster != null and _on_dash(cluster) and _faces(cluster, eye) > 0.85
		and _seen_from(eye, cluster),
		"The gauges sit on the Iveco's cluster, face the driver and show through the wheel")
	_check(map != null and _on_dash(map) and _faces(map, eye) > 0.7,
		"The map sits on the Iveco's centre screen, facing the cab")
	_check(reverse != null and map != null and _local(reverse).origin.distance_to(
		_local(map).origin) < 0.004 and not reverse.visible
		and _presentation.get("reverse_screen") == reverse,
		"The reverse camera shares the map's place and starts hidden")
	var dark: Array = _presentation.get("_dark_screens")
	var powered: Array = _presentation.get("_powered_screens")
	_presentation.call("_power_screens", false)
	var off := dark.size() == powered.size() and powered.size() == 2
	for index in range(mini(dark.size(), powered.size())):
		off = off and (dark[index] as Node3D).visible and not (powered[index] as Node3D).visible \
			and (dark[index] as Node3D).global_position.distance_to(
			(powered[index] as Node3D).global_position) < 0.004
	_presentation.call("_power_screens", true)
	for screen: Node3D in dark:
		off = off and not screen.visible
	_check(off, "With the engine off the gauges and the centre screen go dark, instead of showing "
		+ "the model's lit dials and picture")


func _check_mirrors() -> void:
	var views: Array = _presentation.get("mirrors")
	_check(views.size() == 2, "Only the two door mirrors have live views: the Iveco has no inside "
		+ "mirror (C32)")
	for index in range(mini(views.size(), 2)):
		var side := -1.0 if index == 0 else 1.0
		var glass := _screens_showing(views[index])
		var fits := glass.size() == 2
		for screen in glass:
			var at := _local(screen)
			fits = fits and at.origin.x * side > 1.05 and at.origin.x * side < 1.25 \
				and at.basis.z.z > 0.99 \
				and bool((screen.material_override as ShaderMaterial).get_shader_parameter("mirrored"))
		var swings := index != 0 or (glass.size() > 0
			and (_presentation.get("_door_glass") as Node).is_ancestor_of(glass[0]))
		_check(fits and swings, "The %s door mirror shows its live view, mirrored, on both its "
			% ("left" if index == 0 else "right") + "glasses, facing back%s"
			% (" and swinging with the door" if index == 0 else ""))
	var others := 0
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var surface := (found as MeshInstance3D).material_override as ShaderMaterial
		if surface != null and surface.shader != null \
				and surface.shader.resource_path == SCREEN_SHADER:
			others += 1
	_check(others == 7, "The screens are the cluster, the map, the reverse camera and the four "
		+ "mirror glasses (%d)" % others)


func _check_moon_roof() -> void:
	var blockers := _opaque_faces()
	var eye: Vector3 = Presentation.EYE
	var clear := 0
	var from_above := 0
	for crossing in ROOF_CROSSINGS:
		var on_roof := Vector3(crossing.x, Presentation.MOON_ROOF_HEIGHT, crossing.y)
		var sky := eye + (on_roof - eye) * 1.6
		clear += 1 if _clear(blockers, eye, sky) else 0
		var above := Vector3(crossing.x, 3.2, crossing.y)
		from_above += 1 if _clear(blockers, above, Vector3(crossing.x, 2.0, crossing.y)) else 0
	_check(clear == ROOF_CROSSINGS.size(),
		"The driver sees open sky through the moon roof cut into the Iveco's roof (%d of %d sight "
		% [clear, ROOF_CROSSINGS.size()] + "lines clear)")
	_check(from_above == ROOF_CROSSINGS.size(),
		"From above, the roof and the headliner are open over the front seats (%d of %d)"
		% [from_above, ROOF_CROSSINGS.size()])
	var glass := _presentation.find_child("MoonRoofGlass", true, false) as MeshInstance3D
	var rain := _presentation.find_child("MoonRoofRain", true, false) as MeshInstance3D
	var fits := glass != null and rain != null
	if fits:
		var frame: Rect2 = Presentation.MOON_ROOF
		var at := _local(glass).origin
		var surface := rain.material_override as ShaderMaterial
		fits = Vector2(at.x, at.z).distance_to(frame.get_center()) < 0.01 \
			and absf(at.y - Presentation.MOON_ROOF_HEIGHT) < 0.002 \
			and (glass.mesh as QuadMesh).size.is_equal_approx(frame.size) \
			and _local(rain).origin.y > at.y + 0.005 and rain.sorting_offset < 0.0 \
			and surface != null and surface.shader.resource_path == SIDE_RAIN
	_check(fits, "The moon roof has tinted glass the size of the opening, with rain lying on top "
		+ "of it")
	var trim := 0
	var seal := 0
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		if part.material_override == _presentation.get("_trim") and part.layers == 4:
			trim += 1
		elif part.material_override == _presentation.get("_seal") and part.layers == 2:
			seal += 1
	_check(trim == 4 and seal == 4,
		"A dark frame lines the opening inside, and a rubber seal surrounds it on the roof")
	var camera: Camera3D = _presentation.get("driving_camera")
	var highest := rad_to_deg(Presentation.LOOK_UP + camera.rotation.x) + camera.fov * 0.5
	var back := Presentation.MOON_ROOF.end.y
	var edge := Vector3(eye.x, Presentation.MOON_ROOF_HEIGHT, back) - eye
	var needed := 180.0 - rad_to_deg(atan2(edge.y, -edge.z))
	_check(highest > minf(needed, 89.0) + 2.0,
		"Looking up shows the whole moon roof (view reaches %.0f degrees up)" % highest)


func _check_wheel() -> void:
	var wheel: Node3D = _presentation.get("_wheel")
	var hub := _local(wheel).origin
	var column := _local(wheel).basis.z.normalized()
	_check(hub.distance_to(WHEEL_HUB) < 0.002 and column.distance_to(COLUMN) < 0.01,
		"The wheel pivots on its hub, on the Iveco's column, which leans 44.7 degrees toward the "
		+ "driver")
	_check(wheel.name == "SteeringWheel" and wheel is MeshInstance3D
		and _scenes().get(CAB) != null and (_scenes()[CAB] as Node).is_ancestor_of(wheel),
		"The Iveco's own steering wheel turns with the steering")
	Input.action_press("steer_left")
	await _wait_physics(20)
	var left_turn := wheel.rotation.z
	var top_left := (_local(wheel).basis * Vector3.UP).x
	Input.action_release("steer_left")
	await _wait_physics(40)
	Input.action_press("steer_right")
	await _wait_physics(20)
	var top_right := (_local(wheel).basis * Vector3.UP).x
	Input.action_release("steer_right")
	await _wait_physics(40)
	_check(left_turn > 0.3 and top_left < -0.25,
		"Steering left turns the top of the wheel to the left (%.2f rad)" % left_turn)
	_check(top_right > 0.25, "Steering right turns the top of the wheel to the right")
	_check(_local(wheel).origin.distance_to(hub) < 0.0001 and absf(wheel.rotation.z) < 0.05,
		"The hub stays put and the wheel centres again")


func _scenes() -> Dictionary:
	var scenes := {}
	for node in _presentation.find_children("*", "", true, false):
		if not node.scene_file_path.is_empty():
			scenes[node.scene_file_path.trim_prefix(ART)] = node
	return scenes


func _meshes(scene: Variant) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if scene is Node:
		for found in (scene as Node).find_children("*", "MeshInstance3D", true, false):
			result.append(found as MeshInstance3D)
	return result


func _van_meshes() -> Array[MeshInstance3D]:
	var scenes := _scenes()
	var result := _meshes(scenes.get(EXTERIOR)) + _meshes(scenes.get(CAB))
	result.append(_presentation.get("_windshield"))
	for window: MeshInstance3D in _presentation.get("_windows"):
		result.append(window)
	return result


func _opaque_faces() -> PackedVector3Array:
	var faces := PackedVector3Array()
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		if part.mesh == null or not part.is_visible_in_tree() \
				or part.material_override is ShaderMaterial:
			continue
		var see_through := false
		for surface in range(part.mesh.get_surface_count()):
			var material := part.get_active_material(surface) as BaseMaterial3D
			see_through = see_through or (material != null
				and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)
		if not see_through:
			faces.append_array(_local(part) * part.mesh.get_faces())
	return faces


func _clear(faces: PackedVector3Array, from: Vector3, to: Vector3) -> bool:
	var direction := to - from
	var reach := direction.length()
	direction /= reach
	for first in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, direction, faces[first],
			faces[first + 1], faces[first + 2])
		if hit != null and from.distance_to(hit) < reach:
			return false
	return true


func _on_dash(screen: MeshInstance3D) -> bool:
	var cab := _scenes().get(CAB) as Node
	if cab == null:
		return false
	var at := _local(screen)
	var faces := PackedVector3Array()
	for found in cab.find_children("*", "MeshInstance3D", true, false):
		faces.append_array(_local(found as MeshInstance3D) * (found as MeshInstance3D).mesh.get_faces())
	var hit := false
	var size := (screen.mesh as QuadMesh).size * 0.4
	for corner in [Vector2.ZERO, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var from: Vector3 = at * Vector3(corner.x * size.x, corner.y * size.y, 0.0)
		hit = not _clear(faces, from, from - at.basis.z.normalized() * ON_DASH)
		if not hit:
			return false
	return hit


func _faces(screen: MeshInstance3D, eye: Vector3) -> float:
	var at := _local(screen)
	return at.basis.z.normalized().dot((eye - at.origin).normalized())


func _seen_from(eye: Vector3, screen: MeshInstance3D) -> bool:
	var blockers := _opaque_faces()
	var target := _local(screen).origin + _local(screen).basis.z.normalized() * 0.003
	return _clear(blockers, eye, target)


func _cluster_viewport() -> SubViewport:
	var dimming: Material = (_presentation.get("night_dimming") as Node).get("material")
	for viewport in _presentation.get_children():
		if viewport is SubViewport:
			for control in viewport.get_children():
				if control is CanvasItem and control.material == dimming:
					return viewport
	return null


func _screens_showing(viewport: SubViewport) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if viewport == null:
		return result
	for mesh in _presentation.find_children("*", "MeshInstance3D", true, false):
		var surface := (mesh as MeshInstance3D).material_override as ShaderMaterial
		if surface and surface.shader and surface.shader.resource_path == SCREEN_SHADER \
				and surface.get_shader_parameter("display") == viewport.get_texture():
			result.append(mesh as MeshInstance3D)
	return result


func _screen_showing(viewport: SubViewport) -> MeshInstance3D:
	var found := _screens_showing(viewport)
	return found[0] if found.size() == 1 else null


func _local(node: Node3D) -> Transform3D:
	return _presentation.global_transform.affine_inverse() * node.global_transform


func _wait_physics(count: int) -> void:
	for step in range(count):
		await physics_frame


func _finish() -> void:
	print("COCKPIT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Cockpit test finished within 120 s of game time")
	quit(1)
