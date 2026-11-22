extends SceneTree
## Assignment 7's behaviour pins (CHANGE-BRIEF.md §8), written before either clip is set up and
## committed before they are wired: what the game does now, driven through the real game loop
## with real input (`Input.parse_input_event`), so they must still pass afterwards except where the
## brief says they change.
##   PIN1 Maya's call on the climb: the dash's call states in order and their timing (the ring
##        cycle will play exactly while `call_seconds < 0` during a call).
##   PIN2 Boarding: on foot, E by the driver's door, then boarding (EnterVan) and seated, the
##        engine still running; the clip times at which the door begins to open, is fully open,
##        and Ethan is seated, as measured (the brief re-expresses the boarding moments in
##        frames: these move by at most 1/60 s, and the pin is re-run then).
##   PIN3 R during boarding (its active phase) recovers: boarding cancelled, seated, door shut.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const BEFORE_CALL := 84
const PAST_CALL := 120
const LANE := 1.0
const SPEED := 8.0
const TICK := 1.0 / 60.0

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _road: RefCounted
var _navigation: Control


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-pins-%d-%d.cfg" % [OS.get_process_id(), Time.get_ticks_usec()])
	root.add_child(_app)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	_driver = _app.get("driver") as CharacterBody3D
	_navigation = _van.get_node("VanPresentation").get("navigation")
	await physics_frame
	await _pin_call()
	await _pin_boarding()
	await _pin_recover()
	_finish()


## PIN1: the call's states as the dash shows them, and how long each lasts: Maya's call rings out
## unanswered (four rings of 2.2 s, then missed), calls again and is missed again, and the third
## time answers itself after two rings; it talks, then ends.
func _pin_call() -> void:
	_place(BEFORE_CALL)
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(_road, BEFORE_CALL)
	var states: Array[String] = []
	var starts: Array[float] = []
	var ringing_seconds_negative := true
	var clock := 0.0
	while clock < 120.0:
		await physics_frame
		clock += TICK
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED and clock < 8.0)
		_hold("brake", clock >= 8.0)
		var state := String(_navigation.get("call_state"))
		if states.is_empty() or states[-1] != state:
			states.append(state)
			starts.append(clock)
		if state in ["auto", "ringing"]:
			ringing_seconds_negative = ringing_seconds_negative \
				and float(_navigation.get("call_seconds")) < 0.0
		if states.size() > 1 and states[-1] == "" and states.has("talking"):
			break
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", false)
	var lasted: Array[float] = []
	for index in range(starts.size() - 1):
		lasted.append(snappedf(starts[index + 1] - starts[index], 0.01))
	var expected: Array[String] = ["", "ringing", "missed", "ringing", "missed", "auto",
		"talking", ""]
	var timed := lasted.size() >= 6 and absf(lasted[1] - 8.8) < 0.1 and absf(lasted[3] - 8.8) < 0.1 \
		and absf(lasted[5] - 4.4) < 0.1
	_check(states == expected and timed and ringing_seconds_negative, ("PIN1: the call goes %s, "
		+ "each lasting %s s (rings 8.8, 8.8, then 4.4 before it answers itself); call_seconds "
		+ "< 0 whenever it rings (%s)") % [states, lasted, ringing_seconds_negative])


## PIN2: out (E, stopped), then in again (E by the door): the states in order and the clip times.
func _pin_boarding() -> void:
	await _stop()
	await _press("interact")
	await _until_on_foot()
	var states: Array[String] = ["on foot"]
	await _press("interact")
	var door_from := -1.0
	var door_open := -1.0
	var seated_at := -1.0
	var engine_after := -1.0
	var clock := 0.0
	var seated_clock := -1.0
	while clock < 20.0:
		await physics_frame
		clock += TICK
		var state := _state()
		if states[-1] != state:
			states.append(state)
		var time: float = _driver.call("clip_time")
		var door := float(_van.get("driver_door"))
		if state == "boarding" and _clip() == "EnterVan":
			if door > 0.001 and door_from < 0.0:
				door_from = time
			if door > 0.999 and door_open < 0.0:
				door_open = time
			seated_at = time
		if state == "seated" and seated_clock < 0.0:
			seated_clock = clock
		if seated_clock > 0.0 and bool(_van.get("engine_on")):
			engine_after = clock - seated_clock
			break
	_check(states == ["on foot", "boarding", "seated"] and absf(door_from - 1.083) <= 0.02
		and absf(door_open - 1.617) <= 0.02 and absf(seated_at - 2.017) <= 0.02
		and is_zero_approx(engine_after), ("PIN2: boarding goes %s; the door starts opening at "
		+ "clip %.3f s (1.083), is fully open at %.3f s (1.617); seated %.3f s in (2.017); the "
		+ "engine, never stopped when he got out, is running as he sits (%.2f s)") % [states,
		door_from, door_open, seated_at, engine_after])


## PIN3: R in boarding's active phase recovers: seated at once, boarding cancelled, door shut.
func _pin_recover() -> void:
	await _stop()
	await _press("interact")
	await _until_on_foot()
	await _press("interact")
	var clock := 0.0
	while clock < 10.0 and not (_clip() == "EnterVan" and float(_driver.call("clip_time")) >= 1.2):
		await physics_frame
		clock += TICK
	var mid := float(_driver.call("clip_time"))
	await _press("recover")
	await _frames(5)
	_check(bool(_van.get("occupied")) and not bool(_app.get("_boarding"))
		and not bool(_driver.get("active")) and is_zero_approx(float(_van.get("driver_door"))),
		("PIN3: R at clip %.2f s (the door opening) recovers: seated (%s), boarding over (%s), "
		+ "the door shut (%.2f)") % [mid, _van.get("occupied"), not bool(_app.get("_boarding")),
		float(_van.get("driver_door"))])


func _state() -> String:
	if bool(_van.get("occupied")):
		return "seated"
	if bool(_app.get("_boarding")):
		return "boarding"
	return "on foot"


func _clip() -> String:
	var player := _driver.get("_player") as AnimationPlayer
	return String(player.current_animation)


func _until_on_foot() -> void:
	var clock := 0.0
	while clock < 12.0 and not (bool(_driver.get("active")) and not bool(_app.get("_boarding"))):
		await physics_frame
		clock += TICK
	await _frames(10)


func _stop() -> void:
	_hold("brake", true)
	var clock := 0.0
	while clock < 8.0 and absf(float(_van.get("speed"))) > 0.05:
		await physics_frame
		clock += TICK
	_hold("brake", false)
	await _frames(5)


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var ahead := (points[index + 1] - points[index]).normalized()
	_van.call("recover", Transform3D(Basis.looking_at(ahead, Vector3.UP), points[index]
		+ Vector3.UP * 0.1))


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


func _hold(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	event.strength = 1.0 if down else 0.0
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("ANIMATION PINS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
