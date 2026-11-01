extends SceneTree


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-runners-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	app.get_node("FreightVan/VanPresentation").set("_look_target", Vector2(-0.05, 0.0))
	for i in range(2):
		var press := InputEventAction.new()
		press.action = "wipers"
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventAction.new()
		release.action = "wipers"
		Input.parse_input_event(release)
		await process_frame
	var camera: Camera3D = app.get_node("FreightVan").call("get_camera")
	var folder := _output_folder("evidence/phase_1/rain/runners")
	DirAccess.make_dir_recursive_absolute(folder)
	await _seconds(7.0)
	camera.fov = 40.0
	await _seconds(0.3)
	for index in range(6):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("windshield_%d.png" % index))
		await _seconds(0.45)
	quit(0)


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
