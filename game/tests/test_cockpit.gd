extends SceneTree

const ART := "res://features/vehicles/freight_van/art/"
const SCREEN_SHADER := "res://features/vehicles/freight_van/cockpit_screen.gdshader"
const PARTS := ["cockpit/cockpit_front.gltf", "cockpit/cockpit_back.gltf",
	"cockpit/cockpit_roof.gltf", "cockpit/cockpit_wheel.gltf"]
const STAND_INS := ["cockpit/cockpit_shadow.glb", "cockpit/cockpit_wheel_shadow.glb"]
const COCKPIT_TRIANGLES := 847408
const EYE := Vector3(-0.52, 2.03, -0.32)
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const SIDE_RAIN := "res://features/vehicles/freight_van/side_window_rain.gdshader"
const SIGHTS: Array[Vector3] = [Vector3(-0.45, 2.75, -0.62), Vector3(-0.15, 2.75, -0.85),
	Vector3(0.0, 2.75, -0.73), Vector3(0.3, 2.75, -0.6), Vector3(0.5, 2.75, -0.85)]
const ROOF_BACK_EDGE := Vector3(-0.52, 2.745, -0.511)

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
	_check_centre_mirror()
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
	var scenes := {}
	for node in _presentation.find_children("*", "", true, false):
		if not node.scene_file_path.is_empty():
			scenes[node.scene_file_path.trim_prefix(ART)] = node
	for part: String in PARTS + STAND_INS:
		_check(scenes.has(part), "The cockpit uses %s" % part)
	_check(not scenes.has("cabin.glb") and not scenes.has("steering.glb"),
		"The old cabin.glb and steering.glb are no longer drawn (the files stay in the repo)")
	var triangles := 0
	for part: String in PARTS:
		if scenes.has(part):
			for mesh: MeshInstance3D in (scenes[part] as Node).find_children("*",
					"MeshInstance3D", true, false):
				for surface in mesh.mesh.get_surface_count():
					triangles += mesh.mesh.surface_get_array_index_len(surface) / 3
	_check(triangles == COCKPIT_TRIANGLES,
		"The cockpit draws the slimmed model (%d triangles)" % triangles)


func _check_layers_and_shadows() -> void:
	var visible_parts := _meshes_under(PARTS)
	var stand_ins := _meshes_under(STAND_INS)
	var on_cabin := true
	var no_shadow := true
	for mesh in visible_parts:
		on_cabin = on_cabin and mesh.layers == 4
		no_shadow = no_shadow and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_check(visible_parts.size() == 93 and on_cabin,
		"All 93 cockpit meshes are on the cabin layer, which the mirrors never draw")
	_check(no_shadow, "The detailed cockpit casts no shadows itself")
	var shadow_only := stand_ins.size() == 2
	for mesh in stand_ins:
		var surface := mesh.material_override as BaseMaterial3D
		shadow_only = shadow_only and mesh.layers == 4 \
			and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
			and surface != null and surface.cull_mode == BaseMaterial3D.CULL_DISABLED
	_check(shadow_only, "Two shadow stand-ins cast the cockpit's shadows, from both sides")


func _check_screens() -> void:
	var cluster_view := _cluster_viewport()
	var map_view := (_presentation.get("navigation") as Node).get_parent() as SubViewport
	var mirrors: Array = _presentation.get("mirrors")
	var reverse_view: SubViewport = _presentation.get("reverse_view")
	var cluster := _screen_showing(cluster_view)
	var map := _screen_showing(map_view)
	var reverse := _screen_showing(reverse_view)
	_check(cluster != null and _on_screen(cluster, "Cockpit_Screen_Cluster"),
		"The gauge cluster sits on the Honda driver display, just in front of its glass")
	_check(map != null and _on_screen(map, "Cockpit_Screen_Centre")
		and _local(map).origin.x < -0.08,
		"The map sits on the driver's half of the Honda centre screen")
	_check(reverse != null and map != null and _local(reverse).origin.distance_to(
		_local(map).origin) < 0.003 and not reverse.visible,
		"The reverse camera shares the map's place and starts hidden")
	_check(reverse_view != null and _presentation.get("reverse_screen") == reverse,
		"reverse_screen is the dash screen that shows the reverse camera")
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var screen := _screen_showing(mirrors[index])
		var faces_driver := false
		if screen != null:
			var at := _local(screen)
			faces_driver = at.basis.z.normalized().dot((EYE - at.origin).normalized()) > 0.7
		_check(screen != null and _on_screen(screen, "Cockpit_Screen_Mirrors")
			and _local(screen).origin.x * side > 0.98 and faces_driver
			and (screen.material_override as ShaderMaterial).get_shader_parameter("mirrored"),
			"The %s mirror view shows, mirrored, on the dash-end screen facing the driver"
			% ("left" if index == 0 else "right"))


func _check_wheel() -> void:
	var wheel: Node3D = _presentation.get("_wheel")
	var hub := wheel.position
	_check(hub.distance_to(Vector3(-0.57, 1.7328, -0.8167)) < 0.001
		and absf(rad_to_deg(wheel.rotation.x) + 18.49) < 0.01,
		"The wheel pivots on its hub, 5 cm left of the driver, on a column tilted 18.49 degrees")
	var rim := _meshes_under(["cockpit/cockpit_wheel.gltf"])
	_check(rim.size() == 1 and rim[0].get_parent().get_parent() == wheel,
		"The Honda wheel turns with the steering pivot")
	Input.action_press("steer_left")
	await _wait_physics(20)
	var left_turn := wheel.rotation.z
	var top_left := (wheel.basis * Vector3.UP).x
	Input.action_release("steer_left")
	await _wait_physics(40)
	Input.action_press("steer_right")
	await _wait_physics(20)
	var top_right := (wheel.basis * Vector3.UP).x
	Input.action_release("steer_right")
	await _wait_physics(40)
	_check(left_turn > 0.3 and top_left < -0.25,
		"Steering left turns the top of the wheel to the left (%.2f rad)" % left_turn)
	_check(top_right > 0.25, "Steering right turns the top of the wheel to the right")
	_check(wheel.position.distance_to(hub) < 0.0001 and absf(wheel.rotation.z) < 0.05,
		"The hub stays put and the wheel centres again")


func _check_centre_mirror() -> void:
	var views: Array = _presentation.get("mirrors")
	var inside: SubViewport = views[2] if views.size() > 2 else null
	var showing: Array[MeshInstance3D] = []
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var shader := mesh.material_override as ShaderMaterial
		var plain := mesh.material_override as BaseMaterial3D
		if inside != null and ((shader != null and shader.get_shader_parameter("display")
				== inside.get_texture()) or (plain != null
				and plain.albedo_texture == inside.get_texture())):
			showing.append(mesh)
	_check(showing.size() == 1 and _on_screen(showing[0], "Cockpit_Plastic25_Roof"),
		"The rear view shows only on the Honda's centre mirror (%d screens)" % showing.size())
	var glass_z := -1.34 + (_local(showing[0]).origin.y - 2.17) * tan(0.32) \
		if showing.size() == 1 else -9.0
	_check(showing.size() == 1 and _local(showing[0]).origin.z > glass_z + 0.05,
		"No rear-view mirror is left outside the windshield")


func _check_moon_roof() -> void:
	var roof := _clear_sights(_meshes_under(["cockpit/cockpit_roof.gltf"]))
	_check(roof == SIGHTS.size(),
		"The driver sees open sky through the moon roof (%d of %d sight lines clear)" % [roof,
		SIGHTS.size()])
	var shade := _clear_sights(_meshes_under(["cockpit/cockpit_shadow.glb"]))
	_check(shade == SIGHTS.size(),
		"The shadow stand-in is open at the moon roof too (%d of %d)" % [shade, SIGHTS.size()])
	var glass := _presentation.find_child("MoonRoofGlass", true, false) as MeshInstance3D
	var rain := _presentation.find_child("MoonRoofRain", true, false) as MeshInstance3D
	var fits := glass != null and rain != null
	if fits:
		var frame: Rect2 = Presentation.MOON_ROOF
		var at := _local(glass).origin
		var surface := rain.material_override as ShaderMaterial
		fits = Vector2(at.x, at.z).distance_to(frame.get_center()) < 0.01 and at.y > 2.75 \
			and (glass.mesh as QuadMesh).size.is_equal_approx(frame.size) \
			and _local(rain).origin.y > at.y + 0.005 and rain.sorting_offset < 0.0 \
			and surface != null and surface.shader.resource_path == SIDE_RAIN
	_check(fits, "The moon roof has tinted glass the size of the Honda's frame, with rain lying "
		+ "on top of it")
	var outside := _presentation.find_child("MoonRoofOutside", true, false) as MeshInstance3D
	var covered := outside != null and outside.layers == 2
	if covered:
		var top := _local(outside).origin
		covered = Vector2(top.x, top.z).distance_to(Presentation.MOON_ROOF.get_center()) < 0.01 \
			and top.y >= Presentation.BODY_ROOF
	_check(covered, "The van's outside roof has dark glass over the moon roof")
	var camera: Camera3D = _presentation.get("driving_camera")
	var highest := rad_to_deg(Presentation.LOOK_UP + camera.rotation.x) + camera.fov * 0.5
	var edge := ROOF_BACK_EDGE - EYE
	var needed := rad_to_deg(atan2(edge.y, -edge.z))
	_check(highest > needed + 2.0,
		"Looking up shows the whole moon roof (view reaches %.0f degrees up, roof edge at %.0f)"
		% [highest, needed])


func _clear_sights(meshes: Array[GeometryInstance3D]) -> int:
	var near := PackedVector3Array()
	for geometry in meshes:
		var part := geometry as MeshInstance3D
		if part == null or part.mesh == null:
			continue
		var faces := part.mesh.get_faces()
		var to_cab := _local(part)
		for first in range(0, faces.size(), 3):
			var a := to_cab * faces[first]
			var b := to_cab * faces[first + 1]
			var c := to_cab * faces[first + 2]
			var low := minf(a.x, minf(b.x, c.x))
			var high := maxf(a.x, maxf(b.x, c.x))
			var front := minf(a.z, minf(b.z, c.z))
			var back := maxf(a.z, maxf(b.z, c.z))
			if high < -0.9 or low > 0.9 or back < -1.1 or front > -0.3:
				continue
			near.append_array([a, b, c])
	var clear := 0
	for sight in SIGHTS:
		var direction := (sight - EYE).normalized()
		var blocked := false
		for first in range(0, near.size(), 3):
			if Geometry3D.ray_intersects_triangle(EYE, direction, near[first], near[first + 1],
					near[first + 2]) != null:
				blocked = true
				break
		clear += 0 if blocked else 1
	return clear


func _meshes_under(files: Array) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	for node in _presentation.find_children("*", "", true, false):
		if node.scene_file_path.trim_prefix(ART) in files:
			for mesh in node.find_children("*", "GeometryInstance3D", true, false):
				result.append(mesh as GeometryInstance3D)
	return result


func _cluster_viewport() -> SubViewport:
	var dimming: Material = (_presentation.get("night_dimming") as Node).get("material")
	for viewport in _presentation.get_children():
		if viewport is SubViewport:
			for control in viewport.get_children():
				if control is CanvasItem and control.material == dimming:
					return viewport
	return null


func _screen_showing(viewport: SubViewport) -> MeshInstance3D:
	if viewport == null:
		return null
	for mesh in _presentation.find_children("*", "MeshInstance3D", true, false):
		var surface := (mesh as MeshInstance3D).material_override as ShaderMaterial
		if surface and surface.shader and surface.shader.resource_path == SCREEN_SHADER \
				and surface.get_shader_parameter("display") == viewport.get_texture():
			return mesh as MeshInstance3D
	return null


func _local(node: Node3D) -> Transform3D:
	return _presentation.global_transform.affine_inverse() * node.global_transform


func _on_screen(quad: MeshInstance3D, screen_name: String) -> bool:
	var screen := _presentation.find_child(screen_name, true, false) as MeshInstance3D
	if screen == null:
		return false
	var bounds := _local(screen) * screen.get_aabb()
	bounds = bounds.grow(0.004)
	var size := (quad.mesh as QuadMesh).size / 2.0
	var at := _local(quad)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var point: Vector3 = at * Vector3(corner.x * size.x, corner.y * size.y, 0.0)
		if not bounds.has_point(point):
			return false
	return true


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
