extends SceneTree
## Mission 2's step 6, the escape (docs/PHASE_BRIEF.md, 2026-11-18; the author's choices, #319;
## #358), parts A and B, on Mission 2's stage 3 save (docked at the compound's door 3), by real
## key presses where the player acts: the turn (two guards out of the east warehouse toward the
## van's rear, one at the gate, all in the patrol guard's uniform with a torch); staying in the
## van is caught; out of it the escape; a guard sees him in its cone in the open within 15 m and
## catches him in 1.0 s, not behind something solid, and at once within 1.5 m; caught, all is as
## at the escape's start; the anonymous warning once he is out, naming the cut; the cut lets
## Ethan through and never the van, the rest of the fence closed. The guards are stand-ins (D6).

const STAGE_THREE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=3\n"
const AT_DOOR_THREE := Vector3(248.0, 0.1, 134.67)
const PATROL_MODEL := "res://features/characters/patrol_guard/patrol_guard.glb"
const GAP := Vector3(138.0, 0.0, 140.0)
const SIGHT := 15.0
const CATCH_AFTER := 1.0
const NEAR := 1.5
const AT_KEYPAD := Vector3(98.4, 0.02, 163.0)
const SEAL := "4182260"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _cargo: Node
var _hud: CanvasLayer
var _driver: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-escape-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start()
	var escape := _cargo.get("escape") as Node
	if escape == null:
		_check(false, "E1: docked at door 3, the escape begins (no escape)")
		_finish()
		return
	await _check_turn(escape)
	await _check_stay_in_van(escape)
	await _check_get_out(escape)
	await _check_sight(escape)
	await _check_seen_mark(escape)
	await _check_cover(escape)
	await _check_near(escape)
	await _check_caught_resets(escape)
	await _check_gap()
	await _check_outside(escape)
	await _check_keypad()
	await _check_take_back()
	_finish()


func _start() -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_THREE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_cargo = _app.get("cargo") as Node
	_hud = _app.get("hud") as CanvasLayer
	_driver = _app.get("driver") as CharacterBody3D
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D


## E1: docked, two guards walk out of the east warehouse toward the van's rear, a third stands at
## the gate, each the patrol guard (not a Rocketbox man) with its torch lit; GET OUT AND RUN.
func _check_turn(escape: Node) -> void:
	await _frames(30)
	var guards: Array = escape.get("guards")
	var models := guards.all(func(g: Node3D) -> bool:
		return String(g.get("model_path")) == PATROL_MODEL)
	var torches := guards.all(func(g: Node3D) -> bool:
		var torch := g.get("torch") as SpotLight3D
		return torch != null and torch.visible and torch.light_energy > 0.0)
	var rear := _van.to_global(Vector3(0.0, 0.0, 4.0))
	var closing := 0
	var before: Array = guards.map(func(g: Node3D) -> float: return _flat(g.global_position
		.distance_to(rear)))
	await _seconds(1.5)
	for index in range(guards.size()):
		var guard := guards[index] as Node3D
		if _flat(guard.global_position.distance_to(rear)) < float(before[index]) - 0.5 \
				and String(guard.call("clip")) == "Walk":
			closing += 1
	var at_gate := guards.any(func(g: Node3D) -> bool:
		return Vector2(g.global_position.x - 200.0, g.global_position.z - 142.0).length() < 3.0)
	_check(guards.size() == 3 and models and torches and closing == 2 and at_gate
		and _objective().begins_with("GET OUT AND RUN") and bool(_van.get("occupied")),
		("E1: docked, the turn: two guards walk toward the van's rear (%d), one at the gate (%s), "
		+ "all the patrol guard (%s) with a lit torch (%s); GET OUT AND RUN (%s)") % [closing,
		at_gate, models, torches, _objective()])


## E2: staying in the van, he is caught when they reach the cab, and all starts again: Ethan in
## the van at door 3, the guards back where they came from.
func _check_stay_in_van(escape: Node) -> void:
	var caught_before: int = escape.get("caught_count")
	var waited := 0.0
	while int(escape.get("caught_count")) == caught_before and waited < 30.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(2.5)
	var back := bool(_van.get("occupied")) and _flat(_van.global_position.distance_to(
		AT_DOOR_THREE)) < 0.5
	_check(int(escape.get("caught_count")) == caught_before + 1 and waited > 5.0 and back,
		("E2: staying in the van he is caught when they reach the cab (%.1f s), then he is in "
		+ "the van at door 3 again (%s)") % [waited, back])


## E3: E gets him out; the objective sends him past the patrols; no one sees him behind the van.
func _check_get_out(escape: Node) -> void:
	await _press("interact")
	await _seconds(2.5)
	_check(not bool(_van.get("occupied")) and bool(_driver.get("active"))
		and _objective().begins_with("GET PAST THE PATROLS"), ("E3: E gets him out, the "
		+ "objective GET PAST THE PATROLS (%s)") % _objective())


## E4: a guard held facing west sees him 10 m ahead in the open and catches him after 1.0 s, not
## sooner; he is not seen beyond 15 m.
func _check_sight(escape: Node) -> void:
	var guard := (escape.get("guards") as Array)[0] as Node3D
	guard.call("hold", Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(215.0, 0.02, 120.0)))
	var far := Vector3(215.0 - SIGHT - 1.0, 0.02, 120.0)
	var near := Vector3(205.0, 0.02, 120.0)
	var far_seen := bool(guard.call("sees", far + Vector3.UP * 1.2))
	var caught_before: int = escape.get("caught_count")
	_place(near)
	var seconds := 0.0
	var early := false
	while int(escape.get("caught_count")) == caught_before and seconds < 3.0:
		await physics_frame
		seconds += 1.0 / 60.0
		_place(near)
		if seconds < CATCH_AFTER - 0.1 and int(escape.get("caught_count")) != caught_before:
			early = true
	_check(not far_seen and not early and seconds >= CATCH_AFTER - 0.05 and seconds
		< CATCH_AFTER + 0.35, ("E4: in a guard's cone 10 m off in the open he is caught after "
		+ "%.2f s (1.0 s), not seen at 16 m (%s)") % [seconds, far_seen])
	await _seconds(2.5)
	await _out_of_van()


## E14: while a guard sees him, a mark over that guard fills toward red with how near he is to
## being caught; out of sight it empties and goes.
func _check_seen_mark(escape: Node) -> void:
	var guard := (escape.get("guards") as Array)[0] as Node3D
	guard.call("hold", Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(218.0, 0.02, 124.0)))
	var open := Vector3(229.0, 0.02, 128.5)
	for frame in range(30):
		_place(open)
		await physics_frame
	await process_frame
	var marks := _hud.get("seen_marks") as Control
	var shares: Array = marks.call("shares") if marks != null else []
	var filling := shares.size() == 1 and float(shares[0]) > 0.3 and float(shares[0]) < 0.75
	_place(Vector3(233.0, 0.02, 124.0))
	for frame in range(120):
		_place(Vector3(233.0, 0.02, 124.0))
		await physics_frame
	await process_frame
	var gone: bool = marks != null and (marks.call("shares") as Array).is_empty()
	_check(filling and gone, ("E14: seen by a guard for half a second, a mark over him half full "
		+ "(%s); hidden again, it empties and goes (%s)") % [shares, gone])


## E5: behind the parked forklift, a held guard 11 m off does not see him; out from behind it at
## the same distance, he does.
func _check_cover(escape: Node) -> void:
	var guard := (escape.get("guards") as Array)[0] as Node3D
	guard.call("hold", Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(218.0, 0.02, 124.0)))
	var hidden := Vector3(233.0, 0.02, 124.0)
	var open := Vector3(231.0, 0.02, 128.5)
	var caught_before: int = escape.get("caught_count")
	_place(hidden)
	for frame in range(120):
		await physics_frame
		_place(hidden)
	var stayed := int(escape.get("caught_count")) == caught_before
	var sees_open := bool(guard.call("sees", open + Vector3.UP * 1.2))
	_check(stayed and sees_open, ("E5: behind the forklift a guard 15 m off does not catch him "
		+ "in 2 s (%s); in the open beside it he is seen (%s)") % [stayed, sees_open])


## E6: within 1.5 m he is caught at once, even behind the guard.
func _check_near(escape: Node) -> void:
	var guard := (escape.get("guards") as Array)[0] as Node3D
	guard.call("hold", Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(215.0, 0.02, 120.0)))
	var caught_before: int = escape.get("caught_count")
	var behind := Vector3(216.2, 0.02, 120.0)
	_place(behind)
	var frames := 0
	while int(escape.get("caught_count")) == caught_before and frames < 60:
		await physics_frame
		_place(behind)
		frames += 1
	_check(frames < 15, "E6: within 1.5 m he is caught at once, even behind a guard (%d frames)"
		% frames)
	var waited := 0.0
	while not bool(_van.get("occupied")) and waited < 3.0:
		await physics_frame
		waited += 1.0 / 60.0


## E7: caught, all is as at the escape's start: Ethan in the van at door 3, each guard where it
## started, the gate shut, the warning unsent.
func _check_caught_resets(escape: Node) -> void:
	var guards: Array = escape.get("guards")
	var home := guards.all(func(g: Node3D) -> bool:
		return _flat(g.global_position.distance_to((g.get("start") as Transform3D).origin)) < 1.5)
	var compound := _app.get_node("IndustrialLoop").get("compound") as Node3D
	_check(bool(_van.get("occupied")) and _flat(_van.global_position.distance_to(AT_DOOR_THREE))
		< 0.5 and home and bool(compound.call("gate_shut")) and not bool(escape.get("warned")),
		("E7: caught, all is as at the escape's start: in the van at door 3, the guards at their "
		+ "starts (%s), the gate shut, the warning unsent (%s)") % [home, escape.get("warned")])
	var sent_before: int = escape.get("warnings_sent")
	await _seconds(2.5)
	await _out_of_van()
	var waited := 0.0
	while not bool(escape.get("warned")) and waited < 20.0:
		await physics_frame
		waited += 1.0 / 60.0
	var words := _hud.call("text_message") as String if _hud.has_method("text_message") else ""
	await _seconds(1.0)
	var count: int = int(escape.get("warnings_sent")) - sent_before
	_check(bool(escape.get("warned")) and words.to_lower().contains("fence")
		and words.to_lower().contains("cut") and count == 1 and _objective().begins_with(
		"REACH THE CUT"), ("E8: once he is out, one text from an unknown number names the cut in "
		+ "the fence (%.1f s, %d sent: %s); the objective REACH THE CUT IN THE FENCE (%s)")
		% [waited, count, words, _objective()])


## E9: the cut lets Ethan through, by the walk key, and never the van; the rest of the fence
## stays closed.
func _check_gap() -> void:
	var space := _app.get_world_3d().direct_space_state
	var across := PhysicsRayQueryParameters3D.create(GAP + Vector3(1.0, 0.6, 0.0),
		GAP + Vector3(-1.0, 0.6, 0.0), 1)
	var open := space.intersect_ray(across).is_empty()
	var beside := PhysicsRayQueryParameters3D.create(GAP + Vector3(1.0, 0.6, -5.0),
		GAP + Vector3(-1.0, 0.6, -5.0), 1)
	var closed := not space.intersect_ray(beside).is_empty()
	var van_box := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 1.0, 2.0)
	van_box.shape = box
	van_box.transform = Transform3D(Basis.IDENTITY, GAP + Vector3(0.0, 0.8, 0.0))
	van_box.collision_mask = 1
	var stops_van := not space.intersect_shape(van_box, 1).is_empty()
	_place(GAP + Vector3(1.4, 0.02, 0.0))
	_driver.call("look_toward", Vector3.LEFT)
	_driver.call("face", Vector3.LEFT)
	await _frames(5)
	Input.action_press("accelerate")
	var waited := 0.0
	while _driver.global_position.x > GAP.x - 1.0 and waited < 6.0:
		await physics_frame
		waited += 1.0 / 60.0
	Input.action_release("accelerate")
	var through := _driver.global_position.x < GAP.x - 0.8
	_check(open and closed and stops_van and through, ("E9: the cut at x 138, z 140 lets him "
		+ "through on foot (%s, at x %.2f), is too narrow for the van (%s); the fence beside it "
		+ "closed (%s)") % [through, _driver.global_position.x, stops_van, closed])


## E10: through the cut he is out of the compound: the guards no longer catch him, and the
## objective sends him round to the yard's gate, its keypad marked.
func _check_outside(escape: Node) -> void:
	var caught_before: int = escape.get("caught_count")
	await _seconds(1.5)
	var keypad: Vector3 = (_app.get_node("IndustrialLoop").get("container_yard") as Node3D) \
		.find_child("Keypad", true, false).global_position
	var target: Vector3 = _hud.get("target")
	_check(int(escape.get("caught_count")) == caught_before and bool(escape.get("outside"))
		and _objective().begins_with("GET BACK TO YOUR VAN") and target.distance_to(keypad)
		< 0.5, ("E10: through the cut he is out (%s), not caught, and sent to the yard's keypad: "
		+ "GET BACK TO YOUR VAN (%s)") % [escape.get("outside"), _objective()])


## E11: on foot at the yard's keypad the prompt offers the code; E keys it in, the gate opens
## and stays open long enough to walk in; TAKE YOUR VAN BACK.
func _check_keypad() -> void:
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	_place(AT_KEYPAD)
	await _seconds(0.6)
	var offered := (_hud.get("_hint") as Label).text
	await _press("interact")
	var waited := 0.0
	while not bool(yard.call("gate_open")) and waited < 15.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(8.0)
	var still_open := bool(yard.call("gate_open"))
	_check(offered == "E  Key in the gate code" and still_open and _objective().begins_with(
		"TAKE YOUR VAN BACK"), ("E11: at the keypad on foot E keys the code in (offered %s), the "
		+ "gate opens and is still open 8 s on (%s): TAKE YOUR VAN BACK (%s)") % [offered,
		still_open, _objective()])


## E12: at his van's driver's door E takes it back: one drivable van, his, white, loaded and
## sealed, in the bay; the dark van parked at door 3; stage 4 saved; DRIVE OUT.
func _check_take_back() -> void:
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	var left := yard.call("left_van") as Node3D
	if left == null:
		_check(false, "E12: his van waits in the bay (no van left there)")
		return
	_place(left.to_global(Vector3(-1.6, 0.0, -1.3)) * Vector3(1.0, 0.0, 1.0)
		+ Vector3.UP * 0.02)
	await _seconds(0.6)
	var offered := (_hud.get("_hint") as Label).text
	await _press("interact")
	await _seconds(1.0)
	var presentation := _van.get_node("VanPresentation")
	var white := (presentation.call("paint") as Color).is_equal_approx(Color.WHITE)
	var in_bay := _van.global_position.distance_to(Vector3(95.0, 0.1, 138.0)) < 0.6
	var loaded := false
	for child in (_van.call("body") as Node3D).get_children():
		loaded = loaded or child.has_meta("strapped")
	var sealed := bool(_van.get("sealed")) and str(_van.get("seal_number")) == SEAL
	var dark := yard.call("dark_left") as Node3D if yard.has_method("dark_left") else null
	var docked := dark != null and dark.global_position.distance_to(AT_DOOR_THREE) < 0.6
	var saved := ConfigFile.new()
	saved.load(_scratch)
	var stage: int = saved.get_value("cargo", "stage", -1)
	_check(offered == "E  Take your van back" and white and in_bay and loaded and sealed
		and docked and yard.call("left_van") == null and stage == 4
		and _objective().begins_with("DRIVE OUT"), ("E12: E at his van's door (offered %s): his "
		+ "van drivable in the bay (%s), white (%s), loaded (%s), sealed %s (%s); the dark van at "
		+ "door 3 (%s); stage %d saved; DRIVE OUT (%s)") % [offered, in_bay, white, loaded, SEAL,
		sealed, docked, stage, _objective()])


func _out_of_van() -> void:
	if bool(_van.get("occupied")):
		await _press("interact")
		await _seconds(2.5)


func _place(at: Vector3) -> void:
	_driver.global_position = at
	_driver.velocity = Vector3.ZERO


func _flat(distance: float) -> float:
	return distance


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


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("ESCAPE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
