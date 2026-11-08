extends SceneTree

const DOOR_VIEW := [Vector3(-2.45, 1.6, -2.3), Vector3(-1.05, 1.15, -0.4), 40.0]
const PUSH_VIEW := [Vector3(-3.7, 1.65, -2.1), Vector3(-1.5, 1.15, -0.75), 50.0]
const WINDOW_LOOK := Vector2(-0.3, 1.2)
const LAMP_LOOK := Vector2(0.85, 0.05)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _driver: CharacterBody3D
var _hud: CanvasLayer
var _camera: Camera3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-fixes-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_hud = _app.get_node("DrivingHud")
	_hud.emit_signal("resume_requested")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/fixes/run24")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_driver = _app.get("driver")
	_camera = Camera3D.new()
	root.add_child(_camera)
	await _seconds(2.0)
	await _press("interact")
	await _seconds(1.8)
	await _press("interact")
	await _seconds(0.6)
	await _shot("guide_after_signing")
	var toward := _van.global_position - _driver.global_position
	toward = Vector3(toward.x, 0.0, toward.z).normalized()
	_driver.call("face", toward)
	_driver.call("look_toward", toward)
	await _seconds(0.8)
	await _shot("guide_marker_over_the_van")
	await _boarding()
	await _seat()
	await _window()
	await _exit()
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("fixes_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _boarding() -> void:
	_driver.global_position = _van.to_global(Vector3(-3.4, 0.0, 0.6))
	await _seconds(0.3)
	_app.call("_board_van")
	_view(DOOR_VIEW)
	for moment: float in [1.05, 1.45]:
		while float(_driver.call("clip_time")) < moment or not _clip("EnterVan"):
			await process_frame
		await _shot("hand_on_the_handle_%.2f" % moment)
	while not _van.get("occupied"):
		await process_frame


func _seat() -> void:
	await _seconds(3.5)
	_presentation.set("_look_target", LAMP_LOOK)
	await _seconds(0.8)
	await _shot("seat_cabin_lamp_off")
	await _press("cabin_light")
	await _seconds(0.5)
	await _shot("seat_cabin_lamp_on")
	await _press("cabin_light")
	await _seconds(2.5)


func _window() -> void:
	_presentation.set("_look_target", WINDOW_LOOK)
	await _seconds(0.8)
	await _press("window_left")
	for stop: float in [0.5, 1.0]:
		while float(_van.get("left_window")) < stop - 0.001:
			await process_frame
		await _shot("window_%d" % int(stop * 100))
	await _press("window_left")
	while float(_van.get("left_window")) > 0.0:
		await process_frame
	_presentation.set("_look_target", Vector2.ZERO)
	await _seconds(0.6)


func _exit() -> void:
	_app.call("_exit_van")
	while not _clip("ExitVan"):
		await process_frame
	for moment: float in [2.9, 3.6, 3.95, 4.25]:
		while float(_driver.call("clip_time")) < moment:
			await process_frame
		await _shot("getting_out_%.2f" % moment)
		if moment == 3.95:
			var own := root.get_viewport().get_camera_3d()
			_view(PUSH_VIEW)
			await _shot("pushing_the_door_side")
			own.make_current()
	while bool(_app.get("_boarding")):
		await process_frame
	await _seconds(0.5)
	await _shot("out_with_the_door_shut")


func _view(view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(_van.to_global(view[0]), _van.to_global(view[1]))
	_camera.make_current()


func _clip(name: String) -> bool:
	var player := _driver.get_node("Ethan").find_children("*", "AnimationPlayer", true,
		false)[0] as AnimationPlayer
	return _driver.visible and player.current_animation == name


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	var lamp := _presentation.get("cabin_lamp") as OmniLight3D
	var guide := _hud.get("van_guide") as Control
	var handle: Vector3 = _van.call("door_handle")
	_report.append("saved %s.png: door %.0f deg, cabin lamp %.2f, window %.2f, guide %s, "
		% [stem, rad_to_deg(float(_van.get("driver_door")) * 0.541), lamp.light_energy,
		float(_van.get("left_window")), guide.call("label") if guide.call("shown") else "hidden"]
		+ "hand to handle %.2f m" % (_driver.call("grip_point") as Vector3).distance_to(handle))


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
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
