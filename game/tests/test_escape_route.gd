extends SceneTree
## Mission 2's escape can be won (#358, step 6): on the stage 3 save, a player who gets out at
## once and goes round the back of the east warehouse, between the warehouses, into the cover
## of the trailer dropped at the west one's second dock, by its wall, and waits there for the
## guard by the cut to walk away east, reaches the cut and goes through without being caught, every step by real keys
## (the camera turned toward the next point, W held, Shift to run).

const STAGE_THREE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=3\n"
## The way round, in order: east along the warehouse's front, down its east side, west along its
## back, between the warehouses, to the east side of the west warehouse's eastern trailer.
const ROUND: Array[Vector3] = [Vector3(269.5, 0.0, 135.0), Vector3(270.6, 0.0, 105.0),
	Vector3(231.0, 0.0, 104.0), Vector3(205.0, 0.0, 109.0), Vector3(172.0, 0.0, 124.5),
	Vector3(157.5, 0.0, 125.3)]
const TO_THE_CUT: Array[Vector3] = [Vector3(157.0, 0.0, 138.4), Vector3(139.6, 0.0, 139.9),
	Vector3(136.6, 0.0, 140.0)]
const REACHED := 0.6

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _driver: CharacterBody3D
var _escape: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-escape-route-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_THREE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _frames(10)
	_driver = _app.get("driver") as CharacterBody3D
	_escape = (_app.get("cargo") as Node).get("escape") as Node
	if _escape == null:
		_check(false, "R1: the escape can be won (no escape)")
		_finish()
		return
	await _press("interact")
	var out := 0.0
	while not bool(_driver.get("active")) or bool(_app.get("_boarding")):
		await physics_frame
		out += 1.0 / 60.0
		if out > 6.0:
			break
	var round_ok := await _go(ROUND, true)
	var by_the_cut: Node3D = (_escape.get("guards") as Array)[1]
	var waited := 0.0
	while not (by_the_cut.global_position.x > 160.0 and (by_the_cut.call("facing") as Vector3).x
			> 0.7) and waited < 90.0:
		await physics_frame
		waited += 1.0 / 60.0
	var through := await _go(TO_THE_CUT, true)
	await _frames(10)
	_check(round_ok and through and bool(_escape.get("outside"))
		and int(_escape.get("caught_count")) == 0, ("R1: out at once, round the back of the east "
		+ "warehouse and between the warehouses to the trailers (%s), waiting %.1f s for the guard "
		+ "by the cut to walk away east, then through the cut (%s): out (%s), caught %d times")
		% [round_ok, waited, through, _escape.get("outside"), _escape.get("caught_count")])
	_finish()


## Runs Ethan through `points` by the keys; false if he is caught or stuck on the way.
func _go(points: Array[Vector3], run: bool) -> bool:
	if run:
		Input.action_press("sprint")
	Input.action_press("accelerate")
	var ok := true
	for point in points:
		var spent := 0.0
		while ok:
			var to := Vector3(point.x - _driver.global_position.x, 0.0,
				point.z - _driver.global_position.z)
			if to.length() < REACHED:
				break
			_driver.call("look_toward", to.normalized())
			await physics_frame
			spent += 1.0 / 60.0
			if int(_escape.get("caught_count")) > 0 or spent > 40.0:
				print("STOPPED at %s on the way to %s (caught %d)" % [_driver.global_position,
					point, _escape.get("caught_count")])
				ok = false
	Input.action_release("accelerate")
	Input.action_release("sprint")
	return ok


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


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("ESCAPE ROUTE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
