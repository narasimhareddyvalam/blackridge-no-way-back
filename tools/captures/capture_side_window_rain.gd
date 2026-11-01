extends SceneTree

const SIDE_LOOK := Vector2(0.0, 0.75)

var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-side-rain-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var folder := _output_folder("evidence/phase_1/side_window_rain")
	DirAccess.make_dir_recursive_absolute(folder)
	var van := app.get_node("FreightVan")
	var camera: Camera3D = van.call("get_camera")
	app.get_node("FreightVan/VanPresentation").set("_look_target", SIDE_LOOK)
	await _seconds(2.0)
	await _save(folder, "parked.png", van)
	camera.fov = 30.0
	await _seconds(0.2)
	await _save(folder, "parked_zoom.png", van)
	camera.fov = 74.0
	var drive := InputEventAction.new()
	drive.action = "accelerate"
	drive.pressed = true
	Input.parse_input_event(drive)
	await _seconds(3.5)
	camera.fov = 30.0
	await _seconds(0.1)
	await _save(folder, "driving_zoom.png", van)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(folder.path_join("side_window_rain_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _save(folder: String, file_name: String, van: Node) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file_name))
	_report.append("saved %s speed %.1f km/h" % [file_name, absf(van.get("actual_speed")) * 3.6])


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
