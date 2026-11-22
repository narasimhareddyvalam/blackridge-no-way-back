extends SceneTree
## Assignment 7's state test for the shock (the fourth clip, C67), driven through the game with
## real input as the pins are: when the van comes to rest after the hit, the shot plays: Ethan seen
## seated (his model shown, his body still inactive in the van), his own player on shock/Shock,
## the cutscene's camera current, both wrists on their places at the wheel's rim once the grip has
## closed (#404; read where the IK's result shows, in skeleton_updated); when it ends (SHOCK_SECONDS) he is hidden again and the cab's
## camera is back; and "DRIVE." still comes HOLD_SECONDS after the stop (PIN4 unchanged).

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
	var seen_seated := false
	var playing_shock := false
	var cutscene_camera := false
	var after_hidden := false
	var after_cab := false
	var worst_grip := -1.0
	var skeleton := driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var targets: Array = driver.get("_hold_targets")
	var wrists: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	skeleton.skeleton_updated.connect(func() -> void:
		for side in range(2):
			wrists[side] = (skeleton.global_transform * skeleton.get_bone_global_pose(
				skeleton.find_bone("mixamorig_%sHand" % ["Left", "Right"][side]))).origin)
	var player := driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var cut := _app.get("cutscene") as Node
	clock = 0.0
	while clock < 20.0 and hit:
		await physics_frame
		clock += TICK
		if stopped_at < 0.0 and bool(_van.get("held")) and absf(float(_van.get("speed"))) < 0.05:
			stopped_at = clock
		if stopped_at >= 0.0 and clock - stopped_at > 0.5 and clock - stopped_at < 2.5:
			seen_seated = seen_seated or (driver.visible and not bool(driver.get("active")))
			playing_shock = playing_shock or player.current_animation == "shock/Shock"
			cutscene_camera = cutscene_camera or (cut.get("camera") as Camera3D).is_current()
			for index in range(2):
				worst_grip = maxf(worst_grip, wrists[index].distance_to(
					(targets[index] as Node3D).global_position))
		if stopped_at >= 0.0 and clock - stopped_at > 3.75 and clock - stopped_at < 3.95:
			after_hidden = not driver.visible
			after_cab = (_van.call("get_camera") as Camera3D).is_current()
		if bool(_route.get("fleeing")) and drive_at < 0.0:
			drive_at = clock
			break
	check(("SHOCK STATE: as the van comes to rest the shot plays: Ethan seen seated (%s), his own "
		+ "player on shock/Shock (%s), the cutscene's camera current (%s)") % [seen_seated,
		playing_shock, cutscene_camera], hit and seen_seated and playing_shock and cutscene_camera)
	check("SHOCK STATE: his wrists stay within %.3f m of their places at the rim (under 0.03)"
		% worst_grip, worst_grip >= 0.0 and worst_grip < 0.03)
	check(("SHOCK STATE: after it he is hidden again (%s), the cab's camera back (%s), and DRIVE. "
		+ "comes %.2f s after the stop (HOLD_SECONDS %.1f)") % [after_hidden, after_cab,
		drive_at - stopped_at, Mission.HOLD_SECONDS], after_hidden and after_cab
		and absf(drive_at - stopped_at - Mission.HOLD_SECONDS) < 0.05)
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
	print("SHOCK STATE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
