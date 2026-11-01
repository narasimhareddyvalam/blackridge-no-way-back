extends SceneTree

var _app: Node3D
var _van: CharacterBody3D
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
		"blackridge-rain-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/rain")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_camera = _van.call("get_camera")
	_app.get_node("FreightVan/VanPresentation").set("_look_target", Vector2.ZERO)
	await _seconds(2.5)
	for index in range(6):
		await _save("wipers_low_%d.png" % index)
		await _seconds(0.25)
	await _press("wipers")
	await _seconds(0.2)
	await _press("wipers")
	await _seconds(9.0)
	await _save("wipers_off_9s.png")
	_camera.fov = 28.0
	await _seconds(0.3)
	await _save("wipers_off_9s_zoom.png")
	await _press("wipers")
	await _seconds(0.9)
	await _save("first_wipe_zoom.png")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("rain_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(file_name))
	_report.append("saved %s %dx%d wiper_angle %.2f setting %d" % [file_name, image.get_width(),
		image.get_height(), _van.get("wiper_angle"), _van.get("wiper_setting")])


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


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


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
