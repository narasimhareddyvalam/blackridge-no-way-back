extends SceneTree
## Assignment 7's edge tests (CHANGE-BRIEF.md §4): EnterVan at every phase boundary of the table,
## frames 0 (startup), 32 (active), 48 (recovery) and 69 (seated; 60 before TUNING.md's r1
## moved the cut from 53 to 62), with an input arriving one clip
## frame before the boundary, on it, and one frame after, each through real input
## (`Input.parse_input_event`), and the brief's rule for each interrupt asserted:
##   W (a move key, held) and E: ignored; Ethan does not move, the clip runs on, he ends seated;
##   R: recovers; boarding cancelled, seated, the door shut, at once;
##   Esc: pauses; the clip and the door freeze on their frame, and resume from it on Esc again.
## Before frame 0 there is no clip frame: the input arrives after E while he steps to the door,
## EnterVan not yet begun. An input after the boarding has ended (seated) meets the van's state
## instead, and the test asserts that one: W drives the van, E gets him out, R recovers, Esc
## pauses. Which rule applies is the phase table's: before frame 69 boarding's, after it the van's
## (on frame 69, where he sits, the state the game shows a tick later). The clip's frame is its time x 30, read on the process tick (its own clock); the input
## is posted on that tick and handled at the start of the next, before the clip advances.

const FPS := 30.0
const TICK := 1.0 / 60.0
const BOUNDARIES := [0, 32, 48, 69]
const INTERRUPTS := ["W", "E", "R", "Esc"]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _rows: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(1500.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-edges-%d-%d.cfg" % [OS.get_process_id(), Time.get_ticks_usec()])
	root.add_child(_app)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	await process_frame
	_app.call("_resume")
	_driver = _app.get("driver") as CharacterBody3D
	var road: RefCounted = _app.get_node("IndustrialLoop").get("road")
	var points: PackedVector3Array = road.points
	_van.call("recover", Transform3D(Basis.looking_at((points[41] - points[40]).normalized(),
		Vector3.UP), points[40] + Vector3.UP * 0.1))
	await _frames(30)
	for boundary in BOUNDARIES:
		for offset in [-1, 0, 1]:
			for interrupt in INTERRUPTS:
				await _trial(boundary, offset, interrupt)
	print("TABLE: boundary offset interrupt | state at the input, clip frame | result")
	for row in _rows:
		print("TABLE: " + row)
	_finish()


func _trial(boundary: int, offset: int, interrupt: String) -> void:
	var label := "frame %d%s, %s" % [boundary, ["-1", "", "+1"][offset + 1], interrupt]
	await _get_out()
	await _press("interact")
	var target := float(boundary + offset)
	var clock := 0.0
	while clock < 8.0:
		var boarding := bool(_app.get("_boarding"))
		if boundary == 0 and offset == -1:
			if boarding and _clip() != "EnterVan":
				break
		elif _clip() == "EnterVan" and _frame() >= target - 0.01:
			break
		elif not boarding and bool(_van.get("occupied")):
			break
		await process_frame
		clock += TICK
	var state := _state()
	var at := _frame() if _clip() == "EnterVan" else -1.0
	var ok := false
	var detail := ""
	match interrupt:
		"W", "E":
			var before := _driver.global_position
			var spot := _van.to_global(Vector3(-2.02, 0.0, -0.51))
			if interrupt == "W":
				_hold("accelerate", true)
			else:
				_post("interact", true)
			await process_frame
			var handled := _state()
			if at > 69.0 + 0.01:
				handled = "seated"
			if interrupt == "E":
				_post("interact", false)
			var ended_in_window := false
			for tick in range(18):
				await physics_frame
				ended_in_window = ended_in_window or bool(_van.get("occupied"))
			var moved := _driver.global_position.distance_to(before)
			var nearer := _driver.global_position.distance_to(spot) <= before.distance_to(spot) \
				+ 0.01
			var later := _frame()
			var clip_then := _clip()
			if interrupt == "W":
				_hold("accelerate", false)
			if handled == "boarding" and at < 0.0:
				var seated := await _until_seated()
				ok = nearer and seated
				detail = ("ignored: he walks on to the door as scripted (%.3f m, nearer %s), then "
					+ "EnterVan, seated %s") % [moved, nearer, seated]
			elif handled == "boarding":
				var seated := await _until_seated()
				ok = moved < 0.01 and seated and (ended_in_window or (clip_then == "EnterVan"
					and later > at))
				detail = ("ignored: moved %.3f m, the clip ran on (%s at frame %.1f, seated in the "
					+ "window %s), seated %s") % [moved, clip_then, later, ended_in_window, seated]
			elif interrupt == "W":
				ok = bool(_van.get("occupied")) and not _driver.visible
				detail = "boarding over when handled: the van takes W (occupied %s, hidden %s)" % [
					_van.get("occupied"), not _driver.visible]
			else:
				var out := not bool(_van.get("occupied")) or clip_then == "ExitVan"
				ok = out or (bool(_van.get("occupied")) and clip_then != "EnterVan")
				detail = ("boarding over when handled: E in the van gets him out (%s, clip %s; "
					+ "getting out holds _boarding as its own lock, first_drive.gd:785)") % [out,
					clip_then]
		"R":
			await _press("recover")
			await _frames(3)
			ok = bool(_van.get("occupied")) and not bool(_app.get("_boarding")) \
				and not bool(_driver.get("active")) and is_zero_approx(float(_van.get("driver_door")))
			detail = "recovered: seated %s, boarding over %s, door %.2f" % [_van.get("occupied"),
				not bool(_app.get("_boarding")), float(_van.get("driver_door"))]
		"Esc":
			await _press("pause")
			await _frames(2)
			var frozen := _frame()
			var door := float(_van.get("driver_door"))
			var seated_then := bool(_van.get("occupied"))
			await _frames(30)
			var held := paused and is_equal_approx(_frame(), frozen) \
				and is_equal_approx(float(_van.get("driver_door")), door) \
				and bool(_van.get("occupied")) == seated_then
			await _press("pause")
			await _frames(4)
			var resumed := not paused
			var from := _frame()
			var runs_on := _clip() != "EnterVan" or (from > frozen and from - frozen < 4.0)
			var seated := await _until_seated()
			ok = held and resumed and runs_on and seated
			detail = ("paused: frozen at frame %.1f, door %.3f for 30 ticks %s; resumed %s at "
				+ "frame %.1f; seated %s") % [frozen, door, held, resumed, from, seated]
	_rows.append("%s | %s, %s | %s" % [label, state, ("%.1f" % at) if at >= 0.0 else "-",
		detail])
	check("EDGE %s (%s at frame %s): %s" % [label, state, ("%.1f" % at) if at >= 0.0 else "-",
		detail], ok)


func _state() -> String:
	if bool(_app.get("_boarding")):
		return "boarding"
	if bool(_van.get("occupied")):
		return "seated"
	return "on foot"


func _clip() -> String:
	return String((_driver.get("_player") as AnimationPlayer).current_animation)


func _frame() -> float:
	return float(_driver.call("clip_time")) * FPS


func _until_seated() -> bool:
	var clock := 0.0
	while clock < 8.0 and not (bool(_van.get("occupied")) and not bool(_app.get("_boarding"))):
		await physics_frame
		clock += TICK
	return bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _get_out() -> void:
	if paused:
		await _press("pause")
	if not bool(_van.get("occupied")) and not bool(_app.get("_boarding")) \
			and bool(_driver.get("active")):
		await _frames(10)
		return
	await _until_seated()
	_hold("brake", true)
	var clock := 0.0
	while clock < 8.0 and absf(float(_van.get("speed"))) > 0.05:
		await physics_frame
		clock += TICK
	_hold("brake", false)
	await _frames(5)
	await _press("interact")
	clock = 0.0
	while clock < 12.0 and not (bool(_driver.get("active")) and not bool(_app.get("_boarding"))
			and _clip() != "ExitVan"):
		await physics_frame
		clock += TICK
	await _frames(10)


func _press(action: String) -> void:
	_post(action, true)
	await process_frame
	_post(action, false)
	await physics_frame


func _post(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)


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
	print("ANIMATION EDGES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
