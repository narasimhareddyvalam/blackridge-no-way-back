extends SceneTree

const SPEEDS_KMH: Array[float] = [30.0, 45.0, 60.0]
const SIDE_LOOK := Vector2(0.0, 0.75)
const LIMIT_SECONDS := 9.0

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
		"blackridge-rain-speed-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/rain/speed")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_camera = _van.call("get_camera")
	var presentation := _app.get_node("FreightVan/VanPresentation")
	presentation.set("_look_target", Vector2.ZERO)
	await _press("wipers")
	await _press("wipers")
	await _seconds(3.0)
	_camera.fov = 40.0
	await _save("parked_wipers_off.png")
	_hold("accelerate", true)
	var start := Time.get_ticks_msec()
	var next := 0
	while next < SPEEDS_KMH.size() and Time.get_ticks_msec() - start < LIMIT_SECONDS * 1000.0:
		await process_frame
		if _kmh() >= SPEEDS_KMH[next]:
			await _save("speed_%d.png" % int(SPEEDS_KMH[next]))
			next += 1
	await _seconds(0.15)
	await _save("speed_top_later.png")
	presentation.set("_look_target", SIDE_LOOK)
	_camera.fov = 30.0
	await _seconds(0.35)
	await _save("side_window_speed.png")
	_hold("accelerate", false)
	_hold("brake", true)
	await _seconds(2.0)
	_hold("brake", false)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("rain_speed_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _kmh() -> float:
	return absf(float(_van.get("actual_speed"))) * 3.6


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(file_name))
	_report.append("saved %s at %.1f km/h, wipers %d" % [file_name, _kmh(),
		_van.get("wiper_setting")])


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
