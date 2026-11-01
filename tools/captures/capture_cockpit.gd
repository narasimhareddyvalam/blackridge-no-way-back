extends SceneTree

const LOOKS := {
	"driver_view": Vector2.ZERO,
	"look_left": Vector2(-0.12, 1.0),
	"look_right": Vector2(-0.12, -1.0),
	"look_down": Vector2(-0.45, 0.0),
}
const ZOOMS := {
	"zoom_cluster": [Vector2(-0.1655, 0.0019), 24.0],
	"zoom_map": [Vector2(-0.1597, -0.3833), 24.0],
	"zoom_mirror_left": [Vector2(-0.1179, 0.6166), 24.0],
	"zoom_mirror_right": [Vector2(0.0097, -1.1385), 14.0],
}

var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _camera: Camera3D
var _folder: String
var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-cockpit-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/cockpit")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_camera = _presentation.get("driving_camera")
	await _seconds(3.0)
	for stem: String in LOOKS:
		await _look(LOOKS[stem])
		await _save(stem)
	await _look(Vector2.ZERO)
	_hold("steer_left", true)
	await _seconds(0.8)
	await _save("steering_left")
	_hold("steer_left", false)
	_hold("steer_right", true)
	await _seconds(1.3)
	await _save("steering_right")
	_hold("steer_right", false)
	await _seconds(1.0)
	var wide := _camera.fov
	for stem: String in ZOOMS:
		_camera.fov = ZOOMS[stem][1]
		await _look(ZOOMS[stem][0])
		await _save(stem)
	_camera.fov = ZOOMS["zoom_cluster"][1]
	await _look(ZOOMS["zoom_cluster"][0])
	await _press("headlights")
	await _press("headlights")
	await _seconds(1.5)
	await _save("zoom_cluster_lights_off")
	await _press("headlights")
	_camera.fov = ZOOMS["zoom_map"][1]
	await _look(ZOOMS["zoom_map"][0])
	await _press("change_gear")
	await _seconds(1.0)
	await _save("zoom_map_reverse")
	await _press("change_gear")
	_camera.fov = wide
	await _look(Vector2.ZERO)
	_hold("accelerate", true)
	await _seconds(3.0)
	await _save("driving")
	_hold("accelerate", false)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("cockpit_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _look(target: Vector2) -> void:
	_presentation.set("_look_target", target)
	await _seconds(0.8)


func _save(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var wheel: Node3D = _presentation.get("_wheel")
	_report.append(("saved %s.png %dx%d look %s fov %.0f wheel %.2f rad speed %.1f km/h "
		+ "gear %d lights %s") % [stem, image.get_width(), image.get_height(),
		str(_presentation.get("_look_target")),
		_camera.fov, wheel.rotation.z, absf(_van.get("actual_speed")) * 3.6, _van.get("gear"),
		str(_van.get("headlights_on"))])


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _press(action: String) -> void:
	_hold(action, true)
	await process_frame
	_hold(action, false)
	await process_frame


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
