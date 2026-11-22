extends SceneTree
## Assignment 7's two clips in the running game, for the author to see (#376): a Movie Maker run
## (`--write-movie`, `--fixed-fps 30`). First the dash, zoomed in on the navigation screen while
## Maya's call rings (the `ring` cycle on its RingIcon), held for several wraps; then Ethan stops,
## gets out, and boards again (EnterVan), seen from his own camera turned to the driver's door.
## Real input throughout; the author's keys and mouse are kept from the window while it records.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const BEFORE_CALL := 84
const LANE := 1.0
const SPEED := 8.0
const DASH_LOOK := Vector2(-0.32, -0.668)
const DASH_FOV := 14.0


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-clips-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_camera = _van.call("get_camera")
	var road: RefCounted = _app.get_node("IndustrialLoop").get("road")
	var navigation: Control = _presentation.get("navigation")
	var points: PackedVector3Array = road.points
	var basis := Basis(Vector3.UP, road.call("heading_at", BEFORE_CALL))
	_van.call("recover", Transform3D(basis, points[BEFORE_CALL] + basis.x * LANE
		+ Vector3.UP * 0.1))
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(road, BEFORE_CALL)
	while not String(navigation.get("call_state")) in ["ringing", "auto"]:
		await physics_frame
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED)
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", true)
	print("CLIP: the call rings; zooming to the dash")
	var wide := _camera.fov
	_camera.fov = DASH_FOV
	_presentation.set("_look_target", DASH_LOOK)
	await _seconds(6.0)
	_camera.fov = wide
	_presentation.set("_look_target", Vector2.ZERO)
	await _seconds(1.0)
	while absf(float(_van.get("speed"))) > 0.05:
		await physics_frame
	_hold("brake", false)
	await _seconds(0.5)
	print("CLIP: getting out")
	await _press("interact")
	var driver: CharacterBody3D = _app.get("driver")
	while not (bool(driver.get("active")) and not bool(_app.get("_boarding"))):
		await physics_frame
	await _seconds(0.6)
	_hold("brake", true)
	await _seconds(0.9)
	_hold("brake", false)
	await _seconds(0.4)
	driver.call("aim_toward", _van.to_global(Vector3(-1.0, 1.1, -0.6)))
	await _seconds(1.0)
	print("CLIP: E by the door, EnterVan")
	await _press("interact")
	while not bool(_van.get("occupied")):
		await physics_frame
	await _seconds(2.0)
	print("CLIP: seated; done")
	quit(0)


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
	await physics_frame


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _seconds(duration: float) -> void:
	await create_timer(duration, true, false, true).timeout
