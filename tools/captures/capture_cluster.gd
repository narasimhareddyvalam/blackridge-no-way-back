extends SceneTree

var _app: Node3D
var _van: CharacterBody3D
var _cluster: SubViewport
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
		"blackridge-cluster-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/cluster")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	var presentation := _van.get_node("VanPresentation")
	presentation.set("_look_target", Vector2(-0.18, 0.0))
	for viewport in presentation.get_children():
		if viewport is SubViewport:
			for control in viewport.get_children():
				if control.get_script() and control.get_script().resource_path.ends_with(
						"instruments.gd"):
					_cluster = viewport
	_hold("accelerate", true)
	await _seconds(2.6)
	_hold("accelerate", false)
	await _save_both("driving_headlights_on")
	_hold("brake", true)
	await _seconds(0.25)
	await _save_cluster("braking_headlights_on.png")
	await _seconds(2.5)
	_hold("brake", false)
	await _press("headlights")
	await _seconds(0.6)
	await _save_cluster("stopped_headlights_off.png")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("cluster_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _save_both(stem: String) -> void:
	await _save_cluster(stem + "_cluster.png")
	var view := root.get_texture().get_image()
	view.save_png(_folder.path_join(stem + "_cockpit.png"))
	_report.append("saved %s_cockpit.png" % stem)


func _save_cluster(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := _cluster.get_texture().get_image()
	image.save_png(_folder.path_join(file_name))
	_report.append("saved %s %dx%d speed %.1f km/h braking %s headlights %s" % [file_name,
		image.get_width(), image.get_height(), absf(_van.get("actual_speed")) * 3.6,
		str(_van.get("braking")), str(_van.get("headlights_on"))])


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
