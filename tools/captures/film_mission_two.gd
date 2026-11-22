extends SceneTree
## Mission 2, The Wrong Cargo, filmed as played (#362): from Mission 1's end (its save with the
## opening to play) to PULL OVER and the quiet ending, every step by the real controls through
## `film_kit.gd`'s player and the helpers below, no cuts: the opening and Maya's call; out of the
## depot, up the spur to the transfer shed's gate (stopped level with the guard's window, the run
## sheet handed over); round the yard to bay 9, the rear doors opened, backed onto it, the wheel
## chocked; in by the side door and up the stair, the pallet jacked onto the lift, the lift down,
## the pallet into the hold and strapped, the jack out, the lift up; the chock out, forward, the
## doors shut, the dock hand's seal checked; the bill of lading read; down the spur and round to
## the container yard, the code keyed, the van left in the marked bay, the dark van taken; on to
## the warehouse compound, the run sheet through the booth's window, the rear doors opened, backed
## onto door 3; out and round the back of the warehouses past the patrols to the cut; round to the
## yard's keypad on foot, his van taken back; out and west along the valley road past the depot to
## where the hill road begins; stopped; the quiet ending; the title. Run windowed with Movie
## Maker, from the repository root:
##   HOME=<empty folder> Godot --path game --resolution 1280x800 --fixed-fps 30 \
##     --write-movie <absolute .avi> --script ../tools/captures/film_mission_two.gd
## A first argument names a part to start from, for working on it alone (a save and a pose set up
## there; never used for the film): shed, dock, load, seal, yard, compound, door, escape, getaway.

const Kit = preload("film_kit.gd")
const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=%d\n%s"
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const LANE_X := -71.0
const BAY := -47.75
const BUMPERS := 20.13
const COURT := Vector3(-47.75, 0.1, 31.0)
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const TO_THE_REAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 4.3),
	Vector3(0.0, 0.0, 4.3)]
const BESIDE := Vector3(-1.6, 0.0, 0.5)
const BY_THE_WHEEL := Vector3(-1.5, 0.0, 1.5)
const AT_THE_DOOR := Vector3(-2.0, 0.0, -0.5)
const TO_THE_SIDE_DOOR: Array[Vector3] = [Vector3(-39.0, 0.0, 22.0), Vector3(-39.0, 0.0, 17.5)]
const INTO_THE_DOCK: Array[Vector3] = [Vector3(-41.2, 0.0, 17.5), Vector3(-44.2, 0.0, 16.0),
	Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 13.4), Vector3(-45.6, 0.0, 13.4)]
const OUT_OF_THE_DOCK: Array[Vector3] = [Vector3(-46.0, 0.0, 13.4), Vector3(-44.2, 0.0, 13.4),
	Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 16.0), Vector3(-41.2, 0.0, 17.5),
	Vector3(-39.0, 0.0, 17.5), Vector3(-39.0, 0.0, 22.0)]
const ROUND_THE_LOAD: Array[Vector3] = [Vector3(-46.3, 0.0, 15.0), Vector3(-47.2, 0.0, 15.15)]
const PAST_THE_GUARD := Vector2(-47.75, 20.6)
const TO_THE_BULKHEAD := Vector2(-47.75, 22.9)
const BEHIND_THE_HANDLE := 0.3
const TRAVEL := 8.0
const STROKE := 0.6
const LOWERED := 1.6
const PULL_OUT := 3.4
const STEER_GAIN := 3.0
const STEER_EASE := 1.5
const STEER_MOST := deg_to_rad(35.0)
const STEER_HOLD := deg_to_rad(2.0)
const DOOR_THREE_X := 248.0
const DOOR_THREE_BUMPERS := 131.66
const ROUND: Array[Vector3] = [Vector3(269.5, 0.0, 135.0), Vector3(270.6, 0.0, 105.0),
	Vector3(231.0, 0.0, 104.0), Vector3(205.0, 0.0, 109.0), Vector3(172.0, 0.0, 124.5),
	Vector3(157.5, 0.0, 125.3)]
const TO_THE_CUT: Array[Vector3] = [Vector3(157.0, 0.0, 138.4), Vector3(139.6, 0.0, 139.9),
	Vector3(136.6, 0.0, 140.0)]
const TO_THE_KEYPAD: Array[Vector3] = [Vector3(137.5, 0.0, 145.0), Vector3(138.0, 0.0, 163.5),
	Vector3(104.0, 0.0, 164.0), Vector3(98.4, 0.0, 163.0)]
const END_SAMPLE := 990

var kit: Kit
var app: Node3D
var van: CharacterBody3D
var driver: CharacterBody3D
var hud: CanvasLayer
var cargo: Node
var shed: Node3D
var yard: Node3D
var compound: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _log(text: String) -> void:
	print("FILM %7.1f s  %s | %s" % [Engine.get_physics_frames() / 60.0, text, _objective()])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var part := args[0] if not args.is_empty() else "opening"
	var stages := {"opening": 0, "shed": 0, "dock": 0, "load": 0, "seal": 0, "yard": 1,
		"compound": 2, "door": 2, "escape": 3, "getaway": 4}
	var progress := OS.get_user_data_dir().path_join("film_mission_2.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE % [stages[part], "opening=true\n" if part == "opening" else ""])
	file.close()
	app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	await process_frame
	await process_frame
	kit = Kit.new(self, app)
	van = kit.van
	driver = kit.driver
	hud = kit.hud
	cargo = app.get("cargo") as Node
	var world := app.get_node("IndustrialLoop")
	shed = world.get("transfer_shed")
	yard = world.get("container_yard")
	compound = world.get("compound")
	await kit.seconds(1.5)
	await kit.key(KEY_ENTER)
	await kit.seconds(1.0)
	var order := ["opening", "shed", "dock", "load", "seal", "yard", "compound", "door", "escape",
		"getaway"]
	await _set_up(part)
	for index in range(order.find(part), order.size()):
		_log("part %s" % order[index])
		match String(order[index]):
			"opening":
				await _opening()
			"shed":
				await _shed()
			"dock":
				await _dock()
			"load":
				await _load()
			"seal":
				await _seal()
			"yard":
				await _yard()
			"compound":
				await _compound()
			"door":
				await _door()
			"escape":
				await _escape()
			"getaway":
				await _getaway()
	_log("done")
	quit(0)


## Working on one part alone: the van put where the part begins.
func _set_up(part: String) -> void:
	match part:
		"shed":
			van.call("recover", Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-52.0, 0.1,
				72.2)))
		"dock":
			van.call("recover", Transform3D(Basis.IDENTITY, Vector3(LANE_X, 0.1, 48.0)))
		"load":
			van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
			van.set("rear_doors_open", true)
			await kit.seconds(1.5)
			(shed.get("bay_nine") as Node).call("chock_wheel")
		"compound":
			van.call("recover", Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(150.0, 0.1,
				171.4)))
		"door":
			van.call("recover", Transform3D(Basis.IDENTITY, Vector3(199.0, 0.1, 140.0)))
	await kit.seconds(1.0)


func _objective() -> String:
	return (hud.get("_objective") as Label).text if hud != null else ""


func _hint() -> String:
	return (hud.get("_hint") as Label).text


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _waiting_for(title: String, limit: float) -> bool:
	return await kit.until(func() -> bool: return _objective().begins_with(title), limit)


## The opening (Mission 2's own, from Mission 1's end) and out of the depot.
func _opening() -> void:
	await kit.until(func() -> bool: return kit.cutscene_playing(), 8.0)
	await kit.until(func() -> bool: return not kit.cutscene_playing(), 240.0)
	await kit.until(func() -> bool: return bool(van.get("occupied")) and bool(van.get(
		"engine_on")), 20.0)
	await kit.seconds(2.0)
	_log("opening over")
	await _gear(-1)
	var start := van.global_position
	Input.action_press("accelerate", 0.5)
	await kit.until(func() -> bool: return van.global_position.distance_to(start) > 5.0, 12.0)
	await _gear(1)
	await _turn_until(Vector3.FORWARD, false, 0.5)
	_log("turned at %s" % van.global_position.snapped(Vector3.ONE * 0.1))
	await kit.drive_points([Vector3(van.global_position.x, 0.0, 78.0), Vector3(-50.0, 0.0,
		72.5)] as Array[Vector3], 5.0, false)
	_log("on the road")


## Up the spur to the shed's gate, stopped level with the guard's window, the sheet handed over.
func _shed() -> void:
	await kit.drive_points([Vector3(-60.0, 0.0, 71.3), Vector3(-66.5, 0.0, 70.0),
		Vector3(LANE_X + 0.3, 0.0, 66.0), Vector3(LANE_X + 0.2, 0.0, 64.5)] as Array[Vector3], 4.0,
		false)
	var tick := 0
	while not bool(shed.call("vehicle_at_window")) and tick < 1800:
		var gap: float = shed.call("window_gap")
		tick += 1
		if tick % 60 == 0:
			_log("window: van %s gap %.2f speed %.2f near %s reach %s" % [
				van.global_position.snapped(Vector3.ONE * 0.01), gap, float(van.get("speed")),
				shed.call("vehicle_near"), shed.call("window_in_reach")])
			var hit := van.get_last_slide_collision()
			_log("  held %s gear %s throttle %.2f brake? %s hit %s" % [van.get("held"),
				van.get("gear"), float(van.get("throttle")), van.get("braking"),
				(hit.get_collider() as Node).get_path() if hit != null and hit.get_collider()
				is Node else "none"])
		if absf(float(van.get("speed"))) < 0.05 and absf(gap) <= 0.4:
			break
		var aim := Vector3(LANE_X - 0.35, 0.0, van.global_position.z - 8.0)
		kit.steer_for(aim, clampf(gap * 0.8, 0.0, 3.0) if gap > 0.0 else 0.0)
		if gap <= 0.15:
			Input.action_release("accelerate")
			Input.action_press("brake")
		await physics_frame
	await kit.stop()
	await kit.seconds(1.0)
	_log("at the window (%s)" % shed.call("vehicle_at_window"))
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(shed.call("barrier_open")), 20.0)
	await kit.seconds(1.0)
	_log("barrier up")


## Round the yard to the court before bay 9, facing out, the rear doors opened, backed on, chocked.
func _dock() -> void:
	await kit.drive_points([Vector3(LANE_X, 0.0, 44.0), Vector3(-69.0, 0.0, 33.0),
		Vector3(-62.0, 0.0, 27.0), Vector3(-55.0, 0.0, 26.5), Vector3(-50.5, 0.0, 28.5),
		Vector3(BAY, 0.0, 33.0), Vector3(BAY, 0.0, 36.0)] as Array[Vector3], 3.5, true)
	_log("in the court at %s heading %.0f" % [van.global_position.snapped(Vector3.ONE * 0.1),
		rad_to_deg(van.global_rotation.y)])
	await kit.get_out()
	await _walk_van(TO_THE_REAR)
	await kit.press("interact")
	await kit.until(func() -> bool: return not bool(van.call("rear_doors_busy")), 30.0)
	await kit.seconds(0.4)
	await _walk_van([BESIDE])
	await kit.get_in()
	_log("doors open (%s)" % van.get("rear_doors_open"))
	await _back_onto(BAY, BUMPERS)
	await kit.seconds(1.0)
	_log("backed on: %s" % (shed.get("bay_nine") as Node).get("verdict"))
	await kit.get_out()
	await _walk_van([BY_THE_WHEEL])
	await kit.press("interact")
	await kit.seconds(1.5)
	_log("chocked")


## In by the side door and up the stair; the pallet onto the lift, down, into the hold, strapped;
## the jack out; the lift up.
func _load() -> void:
	if bool(van.get("occupied")):
		await kit.get_out()
	await _walk_keys(TO_THE_SIDE_DOOR)
	await kit.press("interact")
	await kit.seconds(1.5)
	await _walk_keys(INTO_THE_DOCK)
	_log("on the dock")
	await _walk_keys(ROUND_THE_LOAD)
	await kit.press("interact")
	await kit.seconds(0.5)
	await _pump()
	await _push_to(PAST_THE_GUARD, 25.0, 2.0)
	await kit.press("interact")
	await kit.seconds(LOWERED)
	await kit.press("interact")
	await kit.seconds(0.5)
	_log("pallet on the lift")
	await _to_the_pendant()
	await _hold_key(KEY_E, TRAVEL)
	await _walk_keys([_behind_the_handle()])
	await kit.press("interact")
	await kit.seconds(0.5)
	await _pump()
	await _push_to(TO_THE_BULKHEAD, 25.0, 0.8)
	await kit.press("interact")
	await kit.seconds(LOWERED)
	_log("in the hold")
	var presses := 0
	while _hint().begins_with("E  ") and _hint() != "E  Let go of the jack" \
			and _hint() != "E  Pull the jack out first" and presses < 20:
		await kit.press("interact")
		presses += 1
		await kit.seconds(0.45)
	_log("strapped (%d presses)" % presses)
	await _pull_back(PULL_OUT)
	await kit.press("interact")
	await kit.seconds(2.0)
	await _to_the_pendant()
	await _hold_key(KEY_E, TRAVEL)
	_log("lift up")


## Out of the shed, the chock out, forward, the doors shut, the seal checked, the bill read.
func _seal() -> void:
	await _walk_keys(OUT_OF_THE_DOCK)
	await _walk_van([BY_THE_WHEEL])
	await kit.press("interact")
	await kit.seconds(1.0)
	_log("chock out")
	await _walk_van([AT_THE_DOOR])
	await kit.get_in()
	var bay := shed.get("bay_nine") as Node
	Input.action_press("accelerate", 0.4)
	await kit.until(func() -> bool: return float(bay.call("clearance")) > 2.9, 10.0)
	await kit.stop()
	_log("pulled forward")
	await kit.get_out()
	await _walk_van(TO_THE_REAR)
	await kit.press("interact")
	await kit.until(func() -> bool: return not bool(van.call("rear_doors_busy")), 30.0)
	await _walk_van([Vector3(-1.6, 0.0, 6.0)])
	await kit.until(func() -> bool: return bool(van.get("sealed")), 60.0)
	await kit.seconds(1.0)
	await _walk_van([Vector3(0.0, 0.0, 4.3)])
	await kit.press("interact")
	await kit.seconds(4.0)
	await kit.press("interact")
	_log("seal checked")
	await _walk_van([Vector3(-1.7, 0.0, 1.5), BESIDE])
	await kit.get_in()
	await kit.seconds(0.6)
	await kit.press("interact")
	await kit.seconds(4.5)
	await kit.press("interact")
	_log("bill read")


## Out of the shed, down the spur and round to the container yard; the code; the bay; the swap.
func _yard() -> void:
	await kit.drive_points([Vector3(BAY, 0.0, 36.0), Vector3(-55.0, 0.0, 42.0),
		Vector3(LANE_X, 0.0, 46.0), Vector3(LANE_X, 0.0, 62.0), Vector3(-73.0, 0.0, 70.0)]
		as Array[Vector3], 4.0, false)
	kit.set("_last_index", kit.nearest_anywhere(van.global_position))
	await kit.drive_road(1195, 12.0, 5.0, 300.0)
	_log("on the valley road")
	await kit.drive_points([Vector3(92.0, 0.0, 171.5), Vector3(99.0, 0.0, 169.0),
		Vector3(100.0, 0.0, 166.5)] as Array[Vector3], 4.0, false)
	await _stop_when(func() -> bool: return bool(yard.call("vehicle_at_stop")),
		Vector3(100.0, 0.0, 150.0), 2.0)
	_log("at the keypad")
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(yard.call("gate_open")), 20.0)
	await kit.drive_points([Vector3(100.0, 0.0, 154.0), Vector3(97.5, 0.0, 148.0),
		Vector3(95.0, 0.0, 142.5), Vector3(95.0, 0.0, 138.2)] as Array[Vector3], 3.0, true)
	await kit.seconds(0.8)
	_log("in the bay (%s)" % yard.call("in_bay"))
	await kit.get_out()
	var door := Vector3(105.6, 0.0, 141.3)
	await _walk_keys([Vector3(93.0, 0.0, 143.5), Vector3(100.0, 0.0, 144.0), door])
	await kit.press("interact")
	await kit.seconds(2.0)
	await kit.until(func() -> bool: return bool(van.get("occupied")), 10.0)
	_log("the dark van taken")


## Out of the yard, east to the warehouse compound, the run sheet through the booth's window.
func _compound() -> void:
	if van.global_position.z < 160.0:
		await kit.drive_points([Vector3(104.5, 0.0, 150.0), Vector3(101.0, 0.0, 155.0),
			Vector3(100.0, 0.0, 158.0)] as Array[Vector3], 3.0, true)
		await kit.until(func() -> bool: return bool(yard.call("gate_open")), 20.0)
		await kit.drive_points([Vector3(100.0, 0.0, 166.0), Vector3(104.0, 0.0, 171.0),
			Vector3(112.0, 0.0, 172.0)] as Array[Vector3], 4.0, false)
	kit.set("_last_index", kit.nearest_anywhere(van.global_position))
	await kit.drive_road(1257, 12.0, 5.0, 200.0)
	_log("at the compound's turn")
	await kit.drive_points([Vector3(193.0, 0.0, 172.0), Vector3(199.0, 0.0, 167.0),
		Vector3(199.4, 0.0, 160.0)] as Array[Vector3], 4.0, false)
	while not bool(compound.call("vehicle_at_window")):
		var gap: float = compound.call("window_gap")
		if absf(float(van.get("speed"))) < 0.05 and absf(gap) <= 0.4:
			break
		kit.steer_for(Vector3(199.4, 0.0, van.global_position.z - 8.0),
			clampf(gap * 0.8, 0.0, 3.0) if gap > 0.0 else 0.0)
		if gap <= 0.15:
			Input.action_release("accelerate")
			Input.action_press("brake")
		await physics_frame
	await kit.stop()
	await kit.seconds(1.0)
	_log("at the booth (%s)" % compound.call("vehicle_at_window"))
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(compound.call("gate_open")), 25.0)
	await kit.seconds(1.0)


## In, past door 3, the rear doors opened, backed on to door 3.
func _door() -> void:
	await kit.drive_points([Vector3(199.5, 0.0, 142.0), Vector3(206.0, 0.0, 139.0),
		Vector3(225.0, 0.0, 139.5), Vector3(250.0, 0.0, 140.0), Vector3(256.0, 0.0, 140.0)]
		as Array[Vector3], 4.0, true)
	_log("past door 3")
	await kit.get_out()
	await _walk_van(TO_THE_REAR)
	await kit.press("interact")
	await kit.until(func() -> bool: return not bool(van.call("rear_doors_busy")), 30.0)
	await _walk_van([BESIDE])
	await kit.get_in()
	var judge := compound.get("judge") as Node
	var centre := float(judge.get("centre_x"))
	var bumpers := float(judge.get("bumpers_z"))
	_log("door 3's line x %.2f, bumpers z %.2f" % [centre, bumpers])
	await _swing_back(centre, bumpers)
	await _back_onto(centre, bumpers)
	await kit.seconds(1.5)
	_log("at door 3: %s" % (compound.get("judge") as Node).get("verdict"))


## Out and round the back of the warehouses past the patrols to the cut, to the yard's keypad, the
## code, his van taken back.
func _escape() -> void:
	var escape := cargo.get("escape") as Node
	await kit.seconds(1.0)
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(driver.get("active")) and not bool(app.get(
		"_boarding")), 8.0)
	var tries := 0
	while tries < 4:
		tries += 1
		var caught: int = escape.get("caught_count")
		var round_ok := await _run_to(ROUND, escape, caught)
		if round_ok:
			var by_the_cut: Node3D = (escape.get("guards") as Array)[1]
			await kit.until(func() -> bool: return by_the_cut.global_position.x > 160.0 and (
				by_the_cut.call("facing") as Vector3).x > 0.7, 90.0)
			if await _run_to(TO_THE_CUT, escape, caught):
				break
		_log("caught (%d): again" % escape.get("caught_count"))
		await kit.seconds(4.0)
		await kit.press("interact")
		await kit.until(func() -> bool: return bool(driver.get("active")), 8.0)
	_log("through the cut (outside %s)" % escape.get("outside"))
	await kit.seconds(1.0)
	await _walk_keys(TO_THE_KEYPAD, true)
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(yard.call("gate_open")), 15.0)
	var left := yard.call("left_van") as Node3D
	var door := _flat(left.to_global(Vector3(-1.6, 0.0, -1.3)))
	await _walk_keys([Vector3(100.0, 0.0, 156.0), Vector3(92.8, 0.0, 145.0), door], true)
	await kit.press("interact")
	await kit.until(func() -> bool: return bool(van.get("occupied")), 10.0)
	_log("his van back")


## Out of the yard and west along the valley road past the depot to where the hill road begins.
func _getaway() -> void:
	await kit.seconds(1.0)
	await _gear(-1)
	await kit.drive_points([Vector3(95.5, 0.0, 145.0)] as Array[Vector3], -2.5, true)
	await _gear(1)
	await kit.drive_points([Vector3(99.0, 0.0, 152.0), Vector3(100.0, 0.0, 158.0)]
		as Array[Vector3], 3.0, true)
	await kit.until(func() -> bool: return bool(yard.call("gate_open")), 20.0)
	await kit.drive_points([Vector3(100.0, 0.0, 166.0), Vector3(96.0, 0.0, 169.5),
		Vector3(88.0, 0.0, 169.8)] as Array[Vector3], 4.0, false)
	await _drive_road_back(END_SAMPLE + 12, 12.0)
	_log("near the hill road")
	var road: PackedVector3Array = kit.road
	var end := road[END_SAMPLE]
	await kit.drive_points([_lane_back(END_SAMPLE + 4), _lane_back(END_SAMPLE)] as Array[Vector3],
		4.0, true)
	await kit.until(func() -> bool: return bool(app.get("_on_title")), 60.0)
	await kit.seconds(4.0)
	_log("the title (end %s)" % end)


## Drives with the wheel hard over (left, or right) until the van faces `facing`.
func _turn_until(facing: Vector3, left: bool, pedal: float) -> void:
	var time := 0.0
	while time < 20.0 and (-van.global_basis.z).dot(facing) < 0.95:
		kit.release()
		Input.action_press("steer_left" if left else "steer_right", 1.0)
		Input.action_press("accelerate", pedal)
		if absf(float(van.get("speed"))) > 3.0:
			Input.action_release("accelerate")
		await physics_frame
		time += 1.0 / 60.0
	kit.release()


## Into gear `want` (1 forward, -1 reverse) by Q, stopped.
func _gear(want: int) -> void:
	await kit.stop()
	if signi(int(van.get("gear"))) != want:
		await kit.press("change_gear")
		await kit.seconds(0.3)


## The road's right-hand lane driving it backward (falling sample numbers) at sample `index`.
func _lane_back(index: int) -> Vector3:
	var road: PackedVector3Array = kit.road
	var ahead := road[index - 1] - road[index]
	var right := Vector3(-ahead.z, 0.0, ahead.x).normalized()
	return road[index] + right * Kit.LANE


## The loop road driven backward (west from the yard, round past the depot) to sample `to`.
func _drive_road_back(to: int, cruise: float) -> void:
	var road: PackedVector3Array = kit.road
	var here := kit.nearest_anywhere(van.global_position)
	var mark := van.global_position
	var since := 0.0
	var waited := 0.0
	while here > to and waited < 400.0:
		await physics_frame
		waited += 1.0 / 60.0
		here = kit.nearest(van.global_position, here, 12)
		var speed := float(van.get("speed"))
		var look := clampi(int(3 + absf(speed) * 0.55), 3, 10)
		var a := maxi(here - 1, 2)
		var b := maxi(here - 18, 2)
		var first := road[a - 1] - road[a]
		var last := road[b - 1] - road[b]
		var bend := absf(Vector2(first.x, first.z).angle_to(Vector2(last.x, last.z)))
		var wanted := clampf(cruise / (1.0 + bend * 2.6), 4.5, cruise)
		var aim := _lane_back(maxi(here - look, 1))
		since += 1.0 / 60.0
		if since >= 1.5:
			if van.global_position.distance_to(mark) < 0.4:
				await kit._back_off(aim)
			mark = van.global_position
			since = 0.0
		kit.steer_for(aim, wanted)
	kit.release()


## Creeps toward `aim` until `done` holds, then stops.
func _stop_when(done: Callable, aim: Vector3, speed: float) -> void:
	var waited := 0.0
	while not bool(done.call()) and waited < 30.0:
		kit.steer_for(aim, speed)
		await physics_frame
		waited += 1.0 / 60.0
	await kit.stop()


## Walks Ethan by the keys through points given in the van's frame.
func _walk_van(points: Array[Vector3]) -> void:
	var world: Array[Vector3] = []
	for point in points:
		world.append(van.to_global(point))
	await _walk_keys(world)


## Walks Ethan by the keys (the camera turned to the next point, W held; Shift to run).
func _walk_keys(points: Array[Vector3], run := false, limit: float = 20.0) -> void:
	if run:
		Input.action_press("sprint")
	for point in points:
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(point - driver.global_position).length() > 0.3 and time < limit:
			driver.call("look_toward", _flat(point - driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	Input.action_release("sprint")
	await kit.seconds(0.4)


## Runs Ethan through `points`; false if he is caught on the way.
func _run_to(points: Array[Vector3], escape: Node, caught: int) -> bool:
	Input.action_press("sprint")
	Input.action_press("accelerate")
	var ok := true
	for point in points:
		var spent := 0.0
		while ok:
			var to := _flat(point - driver.global_position)
			if to.length() < 0.6:
				break
			driver.call("look_toward", to.normalized())
			await physics_frame
			spent += 1.0 / 60.0
			if int(escape.get("caught_count")) > caught or spent > 40.0:
				ok = false
	Input.action_release("accelerate")
	Input.action_release("sprint")
	return ok


## E held for `seconds`, as a hand on a hold-to-run button.
func _hold_key(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await kit.seconds(seconds)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _pump() -> void:
	var strokes := 0
	while _hint() == "E  Pump the handle" and strokes < 10:
		await kit.press("interact")
		await kit.seconds(STROKE + 0.25)
		strokes += 1
	await kit.seconds(1.0)


## Pushes the jack (W, steered with A and D) until its load is at `goal`.
func _push_to(goal: Vector2, limit: float, lead := INF) -> void:
	var rig: Node = shed.get("pallet_jack")
	var jack := shed.find_child("PalletJack", true, false) as Node3D
	var time := 0.0
	var still := 0.0
	var last := Vector2.INF
	var last_turn := INF
	while time < limit and still < 1.0:
		var centre: Vector2 = rig.call("load_centre")
		var ahead: Vector2 = rig.call("heading")
		if (goal - centre).length() < 0.05 or centre.y >= goal.y:
			break
		var to := Vector2(goal.x, minf(centre.y + lead, goal.y)) - centre
		var turn := ahead.angle_to(to)
		var closing := (turn - last_turn) * 60.0 if last_turn != INF else 0.0
		last_turn = turn
		var want := clampf(turn * STEER_GAIN + closing * STEER_EASE, -STEER_MOST, STEER_MOST) \
			if absf(turn) > 0.03 else 0.0
		var swung := (jack.get_node("Steering") as Node3D).rotation.y
		_hold("steer_left", swung > want + STEER_HOLD)
		_hold("steer_right", want != 0.0 and swung < want - STEER_HOLD)
		Input.action_press("accelerate")
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if centre.distance_to(last) < 0.001 else 0.0
		last = centre
	for action: String in ["steer_left", "steer_right", "accelerate"]:
		Input.action_release(action)
	await kit.seconds(0.3)


## Pulls the jack back out of the hold (S), keeping it square to the van.
func _pull_back(metres: float) -> void:
	var jack := shed.find_child("PalletJack", true, false) as Node3D
	var start := driver.global_position
	var time := 0.0
	var last_turn := INF
	Input.action_press("brake")
	while _flat(driver.global_position - start).length() < metres and time < 25.0:
		var rig: Node = shed.get("pallet_jack")
		var ahead: Vector2 = rig.call("heading")
		var axis := van.global_basis * Vector3.FORWARD
		var turn := ahead.angle_to(Vector2(axis.x, axis.z))
		var closing := (turn - last_turn) * 60.0 if last_turn != INF else 0.0
		last_turn = turn
		var want := -clampf(turn * STEER_GAIN + closing * STEER_EASE, -STEER_MOST, STEER_MOST) \
			if absf(turn) > 0.03 else 0.0
		var swung := (jack.get_node("Steering") as Node3D).rotation.y
		_hold("steer_left", swung > want + STEER_HOLD)
		_hold("steer_right", want != 0.0 and swung < want - STEER_HOLD)
		await physics_frame
		time += 1.0 / 60.0
	for action: String in ["brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	await kit.seconds(0.3)


func _hold(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _to_the_pendant() -> void:
	var pendant: Vector3 = shed.get_node("Building/DockLift9").call("pendant")
	var from := _flat(driver.global_position - pendant)
	var spot := pendant + (from.normalized() if from.length() > 0.01 else Vector3.LEFT) * 0.35
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(spot - driver.global_position).length() > 0.08 and time < 4.0:
		driver.call("look_toward", _flat(spot - driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	await kit.seconds(0.4)


func _behind_the_handle() -> Vector3:
	var rig: Node = shed.get("pallet_jack")
	var grip: Vector3 = rig.call("handle")
	var ahead: Vector2 = rig.call("heading")
	return Vector3(grip.x - ahead.x * BEHIND_THE_HANDLE, 0.0, grip.z - ahead.y * BEHIND_THE_HANDLE)


## Backs the van (Q, slowly) square onto a dock whose centre line is `centre_x` and bumpers at
## `bumpers` (the van facing +z, its rear to the dock), easing the last metre and a half.
func _back_onto(centre_x: float, bumpers: float) -> void:
	await _gear(-1)
	var still := 0.0
	var time := 0.0
	while time < 60.0 and still < 1.2:
		var rear := van.to_global(VAN_REAR)
		var gap := rear.z - bumpers
		var speed := absf(float(van.get("actual_speed")))
		var wanted := 1.0 if gap > 1.5 else 0.6
		_hold("accelerate", speed < wanted - 0.15)
		_hold("brake", speed > wanted + 0.4)
		var ahead := -van.global_basis.z
		var heading := atan2(ahead.x, ahead.z)
		var want := clampf((rear.x - centre_x) * 0.6, -0.3, 0.3)
		var command := clampf((heading - want) * 3.0, -1.0, 1.0)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if command > 0.02:
			Input.action_press("steer_left", command)
		elif command < -0.02:
			Input.action_press("steer_right", -command)
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if speed < 0.03 and gap < 1.0 else 0.0
	kit.release()
	await kit.seconds(0.8)


## From past door 3 heading east, backs round (left lock) until the van faces out from the door,
## then pulls forward to straighten in line with it.
func _swing_back(centre_x: float, bumpers: float) -> void:
	await _gear(-1)
	var time := 0.0
	while time < 20.0:
		var ahead := -van.global_basis.z
		if ahead.z > 0.94:
			break
		Input.action_press("steer_left", 1.0)
		Input.action_press("accelerate", 0.45)
		await physics_frame
		time += 1.0 / 60.0
	kit.release()
	await kit.stop()
	await _gear(1)
	var line := Vector3(centre_x, 0.0, van.global_position.z + 6.0)
	await kit.drive_points([line] as Array[Vector3], 2.0, true)
	_log("lined up at %s" % van.global_position.snapped(Vector3.ONE * 0.1))
