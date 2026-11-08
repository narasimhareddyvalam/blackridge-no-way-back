extends SceneTree

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const START_AT := 60
const BEFORE_HAIRPIN := 104
const LANE := 1.0
const SPEED := 8.0
const CLOSE_FOV := 9.0
const AT_SCREEN := Vector2(-0.22, -0.55)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _nav: Control
var _road: RefCounted
var _close: Camera3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-dash-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/dash/run26")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_nav = _presentation.get("navigation")
	_road = _app.get_node("IndustrialLoop").get("road")
	_close = Camera3D.new()
	_close.fov = CLOSE_FOV
	_presentation.add_child(_close)
	_place(START_AT)
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(_road, START_AT)
	var audio: Node = _app.get("_audio")
	var shot_driving := false
	while not bool(audio.call("calling")):
		await physics_frame
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED)
		if not shot_driving and int(_nav.get("route_index")) >= 76:
			shot_driving = true
			await _seat("seat_driving", Vector2.ZERO)
			await _closeup("screen_driving")
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", true)
	await _seconds(1.0)
	await _seat("seat_ringing", Vector2.ZERO)
	await _seat("seat_looking_at_the_ringing_screen", AT_SCREEN)
	await _closeup("screen_ringing")
	await _press("answer_call")
	await _seconds(4.0)
	await _closeup("screen_talking")
	_app.get_node("DrivingTrial").call("restart")
	_app.call("_resume")
	await _seconds(0.5)
	_hold("brake", false)
	_place(BEFORE_HAIRPIN)
	_van.set("speed", SPEED)
	await _seconds(1.0)
	await _closeup("screen_hairpin_ahead")
	_hold("brake", true)
	await _seconds(1.5)
	_van.set("gear", -1)
	await _seconds(0.6)
	await _closeup("screen_reverse")
	_van.set("gear", 1)
	_van.call("switch_off")
	await _seconds(1.6)
	await _closeup("screen_engine_off")
	_van.call("start_engine")
	await _seconds(0.6)
	await _closeup("screen_starting_up")
	_hold("brake", false)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("dash_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _seat(stem: String, look: Vector2) -> void:
	_presentation.set("_look_target", look)
	await _seconds(0.8)
	(_presentation.get("driving_camera") as Camera3D).make_current()
	await _shot(stem)
	_presentation.set("_look_target", Vector2.ZERO)


func _closeup(stem: String) -> void:
	var screen: MeshInstance3D = _presentation.get("_map_screen")
	var eye := _presentation.global_transform * Presentation.EYE
	_close.look_at_from_position(eye, screen.global_position)
	_close.make_current()
	await _shot(stem)
	(_presentation.get("driving_camera") as Camera3D).make_current()


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	_report.append("saved %s.png: call %s, depot turn %.0f m, hairpin %.0f m, wrong way %s, "
		% [stem, str(_nav.get("call_state")), float(_nav.get("to_turn")),
		float(_nav.get("next_hairpin")), str(_nav.get("wrong_way"))]
		+ "screen power %.2f, clock %s, %.0f FPS" % [float(_presentation.get("_screen_power")),
		str(_van.call("clock_text")), Engine.get_frames_per_second()])


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * LANE + Vector3.UP * 0.1))


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


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


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
