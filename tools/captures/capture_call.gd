extends SceneTree

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const BEFORE_CALL := 84
const LANE := 1.0
const SPEED := 8.0
const DASH_LOOK := Vector2(-0.32, -0.668)
const DASH_FOV := 14.0
const LATER_LINE := "Lock your door tonight."


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _route: Node
var _road: RefCounted
var _hud: CanvasLayer
var _camera: Camera3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-call-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/call/run24_step1")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_hud = _app.get_node("DrivingHud")
	_camera = _van.call("get_camera")
	var audio: Node = _app.get("_audio")
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", BEFORE_CALL))
	_van.call("recover", Transform3D(basis, points[BEFORE_CALL] + basis.x * LANE
		+ Vector3.UP * 0.1))
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(_road, BEFORE_CALL)
	while not bool(audio.call("calling")):
		await physics_frame
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED)
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", true)
	await _seconds(0.6)
	await _shot("phone_ringing")
	var wide := _camera.fov
	_camera.fov = DASH_FOV
	await _look(DASH_LOOK)
	await _shot("dash_incoming_call")
	var call: Node = _route.get("phone_call")
	while not bool(call.get("talking")) or float(call.get("elapsed")) < 3.2:
		await process_frame
	await _shot("dash_call_connected")
	_camera.fov = wide
	await _look(Vector2.ZERO)
	await _shot("first_lines")
	while not String(_hud.call("subtitle")).ends_with(LATER_LINE):
		await process_frame
	await _seconds(0.5)
	await _shot("lock_your_door")
	while bool(call.get("active")):
		await process_frame
	await _seconds(1.0)
	await _shot("after_the_call")
	_hold("brake", false)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("call_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _look(target: Vector2) -> void:
	_presentation.set("_look_target", target)
	await _seconds(0.8)


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var navigation: Control = _presentation.get("navigation")
	_report.append("saved %s.png: subtitle \"%s\", dash caller \"%s\" at %.1f s, fov %.0f"
		% [stem, _hud.call("subtitle"), navigation.get("caller"),
		float(navigation.get("call_seconds")), _camera.fov])


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
