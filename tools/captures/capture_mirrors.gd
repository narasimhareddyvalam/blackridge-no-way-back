extends SceneTree

const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const BEHIND := 14
const ALONG := 25


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _camera: Camera3D
var _folder: String
var _fov: float
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var args := OS.get_cmdline_user_args()
	_folder = args[0] if not args.is_empty() else "evidence/phase_1/mirror/run33"
	DirAccess.make_dir_recursive_absolute(_folder)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-mirror-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(_app.get_node("Driver") as Node3D).visible = false
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_camera = _van.call("get_camera")
	_fov = _camera.fov
	await _frames(90)
	await _mirror_views("start")
	await _passenger_views("start")
	await _shot_ahead("start_ahead")
	await _outside("start_outside_mirror", Vector3(-1.3, 0.2, 2.4), _left_glass())
	await _outside("start_outside_gravel", Vector3(-4.5, 2.2, -7.0), _van.global_position
		+ _van.global_basis * Vector3(0.0, 0.6, -1.0))
	await _outside("start_outside_passenger_mirror", Vector3(1.1, 0.3, -2.4), _right_glass())
	_van.set("driver_door", 1.0)
	await _frames(30)
	await _outside("door_open_mirror", Vector3(-2.2, 0.6, 1.6), _left_glass())
	_van.set("driver_door", 0.0)
	await _frames(30)
	Input.action_press("brake")
	await _frames(20)
	await _outside("tail_glow_braking", Vector3(-2.5, 1.6, 9.0), _van.global_position
		+ _van.global_basis * Vector3(0.0, 0.4, 3.5))
	Input.action_release("brake")
	await _behind()
	await _mirror_views("behind")
	await _passenger_views("behind")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("mirror_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _left_glass() -> Vector3:
	for found in (_presentation.get("_door_glass") as Node3D).find_children("MainGlass",
			"MeshInstance3D", true, false):
		var glass := found as MeshInstance3D
		return glass.global_transform * glass.mesh.get_aabb().get_center()
	return _van.global_position


func _right_glass() -> Vector3:
	for found in (_presentation.find_child("PassengerMirror", true, false) as Node3D).find_children(
			"MainGlass", "MeshInstance3D", true, false):
		var glass := found as MeshInstance3D
		return glass.global_transform * glass.mesh.get_aabb().get_center()
	return _van.global_position


func _passenger_views(stem: String) -> void:
	var target := _right_glass()
	await _aim_eye(target, _fov)
	await _save("%s_passenger_mirror_glance" % stem)
	await _aim_eye(target, 24.0)
	await _save("%s_passenger_mirror_closer" % stem)
	_camera.fov = _fov
	_presentation.set("_look_target", Vector2.ZERO)
	await _frames(30)


func _mirror_views(stem: String) -> void:
	var target := _left_glass() + _van.global_basis * Vector3(0.0, -0.07, 0.0)
	await _aim_eye(target, _fov)
	await _save("%s_left_mirror_glance" % stem)
	await _aim_eye(target, 22.0)
	await _save("%s_left_mirror_zoom" % stem)
	_camera.fov = _fov
	_presentation.set("_look_target", Vector2.ZERO)
	await _frames(30)
	var rendered := await _frame_rate()
	_report.append("%s: %.1f FPS with the mirrors updating (vsync off)" % [stem, rendered])


func _shot_ahead(stem: String) -> void:
	_camera.fov = _fov
	_presentation.set("_look_target", Vector2.ZERO)
	await _frames(60)
	await _save(stem)


func _outside(stem: String, offset: Vector3, target: Vector3) -> void:
	var outside := Camera3D.new()
	outside.fov = 40.0
	outside.cull_mask = 0xFFFFF & ~Presentation.MIRROR_LAYER
	root.add_child(outside)
	outside.look_at_from_position(target + _van.global_basis * offset, target, Vector3.UP)
	outside.make_current()
	await _frames(30)
	await _save(stem)
	outside.queue_free()
	_camera.make_current()
	await _frames(5)


func _behind() -> void:
	var road: RefCounted = _app.get_node("IndustrialLoop").get("road")
	var points: PackedVector3Array = road.points
	var count := points.size()
	var start := 0
	for index in range(count):
		if points[index].distance_squared_to(_van.global_position) \
				< points[start].distance_squared_to(_van.global_position):
			start = index
	var at := (start + ALONG) % count
	var heading := points[(at - 1 + count) % count] - points[(at + 1) % count]
	heading.y = 0.0
	heading = heading.normalized()
	_van.recover(Transform3D(Basis.looking_at(heading, Vector3.UP),
		points[at] + heading.cross(Vector3.UP).normalized() * 1.4))
	var follower := OncomingVan.new()
	_app.add_child(follower)
	follower.configure(road, _van, at + BEHIND, 0)
	follower.set_physics_process(false)
	await _frames(120)
	_report.append("behind: a van stands %.1f m behind, its headlights on" % [
		follower.global_position.distance_to(_van.global_position)])


func _frame_rate() -> float:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _frames(30)
	var started := Time.get_ticks_usec()
	await _frames(240)
	var seconds := float(Time.get_ticks_usec() - started) / 1000000.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	return 240.0 / seconds


func _aim_eye(target: Vector3, fov: float) -> void:
	_camera.fov = fov
	var offset := _van.global_basis.inverse() * (target - _camera.global_position)
	var look := Vector2(atan2(offset.y, Vector2(offset.x, offset.z).length()) + 0.15,
		atan2(-offset.x, -offset.z))
	_presentation.set("_look_target", look)
	await _frames(90)
	for attempt in range(5):
		var screen := _camera.unproject_position(target)
		var middle := Vector2(root.get_visible_rect().size) / 2.0
		var error := (screen - middle) / middle.y * deg_to_rad(fov) / 2.0
		look -= Vector2(error.y, error.x)
		_presentation.set("_look_target", look)
		await _frames(45)


func _save(stem: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	_report.append("saved " + stem)


func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame
