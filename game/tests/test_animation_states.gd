extends SceneTree
## Assignment 7's state test (CHANGE-BRIEF.md §5): the game driven through real input
## (`Input.parse_input_event`) and each state's clip read through the property its route uses:
## the ring's `RingPlayer.current_animation`, `is_playing()`, `RingIcon.visible` and `frame`;
## Ethan's `AnimationPlayer.current_animation`.
##   T1-T3 the dash: ringing (or answering itself) plays 'ring' with the handset shown; missed,
##         talking and no call show and play nothing; the cycle shows every cell and wraps.
##   T4-T6 Ethan on foot: no input Idle, a move key Walk, with sprint Run, released Idle.
##   T7-T8 boarding: E by the door plays EnterVan; then seated, Ethan hidden, nothing playing on
##         the dash's ring.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const BEFORE_CALL := 84
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


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-states-%d-%d.cfg" % [OS.get_process_id(), Time.get_ticks_usec()])
	root.add_child(_app)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	_driver = _app.get("driver") as CharacterBody3D
	_navigation = _van.get_node("VanPresentation").get("navigation")
	await physics_frame
	await _dash()
	await _on_foot()
	await _boarding()
	_finish()


func _dash() -> void:
	var player := _navigation.get_node("RingPlayer") as AnimationPlayer
	var icon := _navigation.get_node("RingIcon") as Sprite2D
	_place(BEFORE_CALL)
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(_road, BEFORE_CALL)
	var wrong := {}
	var seen := {}
	var wraps := 0
	var last_frame := -1
	var ringing_frames := 0
	var quiet_frames := 0
	var was := ""
	var clock := 0.0
	var talked := false
	while clock < 120.0:
		await physics_frame
		clock += TICK
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED and clock < 8.0)
		_hold("brake", clock >= 8.0)
		var state := String(_navigation.get("call_state"))
		var ringing := state in ["ringing", "auto"] and float(_navigation.get("call_seconds")) < 0.0
		if state == was:
			var shows := icon.visible and player.is_playing() and player.current_animation == "ring"
			var hidden := not icon.visible and not player.is_playing()
			if (ringing and not shows) or (not ringing and not hidden):
				wrong[state] = int(wrong.get(state, 0)) + 1
			if ringing:
				ringing_frames += 1
				seen[icon.frame] = true
				if last_frame == 5 and icon.frame == 0:
					wraps += 1
				last_frame = icon.frame
			else:
				quiet_frames += 1
				last_frame = -1
		was = state
		talked = talked or state == "talking"
		if talked and state == "talking" and float(_navigation.get("call_seconds")) > 2.0:
			break
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", false)
	check(("T1 the ring shows and plays 'ring' exactly while the call rings or answers itself, "
		+ "and nothing shows otherwise (%d ringing frames, %d quiet; wrong by state %s)") % [
		ringing_frames, quiet_frames, wrong], ringing_frames > 0 and quiet_frames > 0
		and wrong.is_empty())
	var cells := seen.keys()
	cells.sort()
	check("T2 while it rings the handset shows every cell of the sheet %s and wraps 5 -> 0 (%d)" % [
		cells, wraps], cells == [0, 1, 2, 3, 4, 5] and wraps > 10)
	check("T3 the call is answered and talking: the ring hidden and stopped (%s, %s)" % [
		icon.visible, player.is_playing()], talked and not icon.visible and not player.is_playing())


func _on_foot() -> void:
	await _stop()
	await _press("interact")
	await _until_on_foot()
	check("T4 on foot with no input: Idle (%s)" % _clip(), _clip() == "Idle")
	_hold("accelerate", true)
	await _frames(40)
	var walking := _clip()
	_hold("sprint", true)
	await _frames(40)
	var running := _clip()
	_hold("sprint", false)
	_hold("accelerate", false)
	await _frames(40)
	check("T5 a move key walks (%s), with sprint runs (%s)" % [walking, running],
		walking == "Walk" and running == "Run")
	check("T6 released, he stands: Idle (%s)" % _clip(), _clip() == "Idle")


func _boarding() -> void:
	await _press("interact")
	var clips := {}
	var clock := 0.0
	var boarded := false
	while clock < 20.0:
		await physics_frame
		clock += TICK
		if bool(_app.get("_boarding")) and _driver.visible:
			clips[_clip()] = true
			boarded = true
		if boarded and bool(_van.get("occupied")):
			break
	check("T7 E by the van boards him playing EnterVan (clips while boarding %s)" % [clips.keys()],
		boarded and clips.has("EnterVan"))
	await _frames(5)
	check("T8 boarding over: seated, Ethan hidden, inactive (%s, %s, %s)" % [
		_van.get("occupied"), _driver.visible, _driver.get("active")],
		bool(_van.get("occupied")) and not _driver.visible and not bool(_driver.get("active")))


func _clip() -> String:
	return String((_driver.get("_player") as AnimationPlayer).current_animation)


func _until_on_foot() -> void:
	var clock := 0.0
	while clock < 12.0 and not (bool(_driver.get("active")) and not bool(_app.get("_boarding"))):
		await physics_frame
		clock += TICK
	await _frames(20)


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
	print("ANIMATION STATES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
