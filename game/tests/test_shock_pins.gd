extends SceneTree
## Assignment 7's pins for the shock clip (CHANGE-BRIEF.md, the revision #377-#383), written and
## committed before the clip: what Mission 1 does after the hit now, driven through the game with
## real input, so they must still pass once the shot through the windshield plays inside the hold.
##   PIN4 the hold: the van stops after the hit and holds 4.0 s (HOLD_SECONDS) before "DRIVE.";
##        throughout it Ethan stays in the van (occupied, his body inactive) and E does nothing;
##        at "DRIVE." the checkpoint is saved where the van stands.

const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const LaneKeeper = preload("res://tests/lane_keeper.gd")
const APPROACH := 672
const LANE := 1.0
const RUN_SPEED := 8.0
const TICK := 1.0 / 60.0

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _hud: CanvasLayer
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(200.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-a7-shock-pins-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_hud = _app.get_node("DrivingHud")
	await process_frame
	_app.call("_resume")
	await physics_frame
	var driver := _app.get("driver") as CharacterBody3D
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", APPROACH))
	_van.call("recover", Transform3D(basis, points[APPROACH] + basis.x * LANE + Vector3.UP * 0.1))
	_van.set("speed", RUN_SPEED)
	var keeper := LaneKeeper.new(_road, APPROACH)
	var clock := 0.0
	var pedestrian: Node3D = null
	while clock < 60.0:
		await physics_frame
		clock += TICK
		pedestrian = _route.get("pedestrian")
		if is_instance_valid(pedestrian) and not bool(pedestrian.get("waiting")):
			break
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < RUN_SPEED)
	keeper.release()
	_hold("accelerate", false)
	_hold("brake", true)
	clock = 0.0
	while clock < 6.0 and not (is_instance_valid(pedestrian) and bool(pedestrian.get("hit"))):
		await physics_frame
		clock += TICK
	_hold("brake", false)
	var hit := is_instance_valid(pedestrian) and bool(pedestrian.get("hit"))
	var stopped_at := -1.0
	var drive_at := -1.0
	var stayed := true
	var e_pressed := false
	var objective_in_hold := ""
	clock = 0.0
	while clock < 20.0 and hit:
		await physics_frame
		clock += TICK
		if stopped_at < 0.0 and bool(_van.get("held")) and absf(float(_van.get("speed"))) < 0.05:
			stopped_at = clock
		if stopped_at >= 0.0 and drive_at < 0.0:
			stayed = stayed and bool(_van.get("occupied")) and not bool(driver.get("active"))
			if not e_pressed and clock - stopped_at > 1.5:
				e_pressed = true
				await _press("interact")
				clock += TICK
			if clock - stopped_at > 2.0 and objective_in_hold.is_empty():
				objective_in_hold = _objective()
		if bool(_route.get("fleeing")) and drive_at < 0.0:
			drive_at = clock
			break
	var held := drive_at - stopped_at
	check(("PIN4: after the hit (%s) the van stops and holds %.2f s (HOLD_SECONDS %.1f) before "
		+ "the objective reads %s; in the hold it read '%s'") % [hit, held, Mission.HOLD_SECONDS,
		_objective(), objective_in_hold], hit and stopped_at >= 0.0
		and absf(held - Mission.HOLD_SECONDS) < 0.05 and _objective() == "DRIVE."
		and objective_in_hold != "DRIVE.")
	check("PIN4: throughout the hold Ethan stays in the van, his body inactive, and E does nothing"
		+ " (%s, pressed %s)" % [stayed, e_pressed], stayed and e_pressed
		and bool(_van.get("occupied")))
	await _frames(5)
	var saved := ConfigFile.new()
	var pose: Variant = saved.get_value("drive", "recovery", null) if saved.load(_scratch) == OK \
		else null
	var near := pose is Transform3D and (pose as Transform3D).origin.distance_to(
		_van.global_position) < 0.5
	check("PIN4: at DRIVE. the checkpoint is saved where the van stands (%s)" % near, near)
	_finish()


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


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
	print("SHOCK PINS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
