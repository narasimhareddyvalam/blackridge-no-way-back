extends SceneTree
## Part A's look (#245–#246): Ethan up and down the dock stair, filmed in a 1280x800 window with
## Godot's Movie Maker on Mission 2's start save, first from his own camera, then from a camera at
## the stair's open side. He gets out of the van at bay 9 by E and, behind a short fade, stands at
## the foot of the stair; from there he walks by the game's own W key, his camera turned as the
## mouse would turn it, slowly round at the top. Keys and clicks from the keyboard and mouse are
## swallowed; the script's own keys carry a tag that lets them by. Usage, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --write-movie <absolute folder>/stair.avi \
##     --fixed-fps 30 --script ../tools/captures/capture_stair.gd

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const SENT := "capture_stair_key"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const BELOW := Vector3(-44.2, 0.0, 17.6)
const ABOVE := Vector3(-44.2, 0.0, 13.45)
const SIDE_CAMERA := Vector3(-40.5, 2.35, 15.5)
const SIDE_LOOKS_AT := Vector3(-44.2, 1.1, 14.6)
const TURN_SECONDS := 1.4


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if (event is InputEventMouse or event is InputEventKey) and not event.has_meta(SENT):
			get_viewport().set_input_as_handled()


var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_stair_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	await process_frame
	_hud = _app.get_node("DrivingHud")
	_app.call("_begin")
	_hud.call("fade", 1.0, 0.01)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	await _seconds(1.0)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _take(null)
	var side := Camera3D.new()
	side.fov = 60.0
	root.add_child(side)
	side.look_at_from_position(SIDE_CAMERA, SIDE_LOOKS_AT)
	await _take(side)
	await _take(side, true)
	quit(0)


## One take: at the foot of the stair behind the fade, up it, slowly round at the top, and down;
## `running`, up it holding the run key (#257).
func _take(camera: Camera3D, running := false) -> void:
	_hud.call("fade", 1.0, 0.3)
	await _seconds(0.4)
	_driver.global_position = BELOW
	_driver.velocity = Vector3.ZERO
	_driver.call("face", Vector3.FORWARD)
	_driver.call("look_toward", Vector3.FORWARD)
	if camera != null:
		camera.make_current()
	else:
		_driver.get_camera().make_current()
	await _seconds(0.6)
	_hud.call("fade", 0.0, 0.5)
	await _seconds(0.8)
	if running:
		Input.action_press("sprint")
	await _walk(ABOVE)
	Input.action_release("sprint")
	await _seconds(0.8)
	await _turn(Vector3.FORWARD, Vector3.BACK)
	await _seconds(0.4)
	await _walk(BELOW)
	await _seconds(1.0)


func _walk(goal: Vector3) -> void:
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(goal - _driver.global_position).length() > 0.3 and time < 14.0:
		_driver.call("look_toward", _flat(goal - _driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")


## His camera turned round as a mouse turns it, smoothly, and him with it once he walks.
func _turn(from: Vector3, to: Vector3) -> void:
	var start := atan2(from.x, from.z)
	var turn := angle_difference(start, atan2(to.x, to.z))
	if absf(turn) > PI - 0.01:
		turn = PI - 0.01
	var time := 0.0
	while time < TURN_SECONDS:
		var yaw := start + turn * smoothstep(0.0, 1.0, time / TURN_SECONDS)
		_driver.call("look_toward", Vector3(sin(yaw), 0.0, cos(yaw)))
		await physics_frame
		time += 1.0 / 60.0
	_driver.call("look_toward", to)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta(SENT, true)
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _seconds(duration: float) -> void:
	await create_timer(duration, true, false, true).timeout
