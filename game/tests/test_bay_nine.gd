extends SceneTree
## Step 2d, backing onto bay 9 (docs/PHASE_BRIEF.md, rules G1–G7, with the author's decisions
## U1 a, U2 a and U3 a, #228), in the running game on Mission 2's start save: bay 9's lift in its
## pit, its lights, its wheel guides and its chock. Ethan's actions use the real keys. A headless
## run draws nothing, so the look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BAY := -47.75
const DOCK_FLOOR := 1.3
const OPENING := Vector2(2.74, 3.05)
const INNER_FACE := 19.75
const COURT_SPOT := Vector3(-47.75, 0.1, 31.0)
const TO_THE_REAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 4.3),
	Vector3(0.0, 0.0, 4.3)]
const BESIDE := Vector3(-1.6, 0.0, 0.5)
const SWUNG := 250.0
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const BUMPERS := 20.13
const CHOCK_SPOT := Vector3(-0.872, 0.15, 1.48)
const BY_THE_WHEEL := Vector3(-1.5, 0.0, 1.5)
const GENTLE := 1.0
const SLOWER := 0.6
const FLAT_OUT := 5.0
const SHORT_OF := 0.7
const CROOKED := 3.5
const TURN_AT := 4.5
const OFF_CENTRE := 0.17
const AT_THE_DOOR := Vector3(-2.0, 0.0, -0.5)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _shed: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(280.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-bay-nine-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_check_lift()
	_check_lights_at_rest()
	_check_guides()
	_check_chock_at_rest()
	await _check_rear_doors()
	await _check_docking()
	_finish()


func _check_lift() -> void:
	var lift := _shed.get_node_or_null("Building/DockLift9") as Node3D
	var platform := lift.get_node_or_null("Platform") as MeshInstance3D if lift != null else null
	var box := platform.global_transform * platform.get_aabb() if platform != null else AABB()
	var door := Rect2(BAY - OPENING.x / 2.0, 0.0, OPENING.x, 0.0)
	_check(platform != null and absf(box.end.y - DOCK_FLOOR) <= 0.01
		and box.position.x >= door.position.x and box.end.x <= door.end.x
		and box.end.z <= INNER_FACE + 0.01 and box.size.z >= 2.0,
		("G1: bay 9's lift stands behind its door, its platform's top flush with the dock floor "
		+ "(%.3f m) inside the opening's width (x %.2f to %.2f) and behind the wall (to z %.2f)")
		% [box.end.y, box.position.x, box.end.x, box.end.z])
	var pit := _bodies_in(Vector3(1.6, 0.6, 2.0), Vector3(BAY, 0.85, 18.5))
	var doorway := _bodies_in(Vector3(2.4, 2.6, 0.2), Vector3(BAY, 2.8, 19.88))
	_check(pit.is_empty() and doorway.is_empty(),
		("G1: under the platform the pit is open (%d bodies there), and nothing solid stands in "
		+ "the doorway above the dock floor (%d)") % [pit.size(), doorway.size()])


func _check_lights_at_rest() -> void:
	var outside := _shed.get_node_or_null("Building/DockSignal9") as Node3D
	var inside := _shed.get_node_or_null("Building/DockSignalInside9") as Node3D
	var outside_green := outside != null and _lit(outside, "Green") and not _lit(outside, "Red")
	var faces_in := false
	if inside != null:
		var lens := inside.get_node("Red") as Node3D
		faces_in = lens.global_position.z < inside.global_position.z
	_check(outside_green and inside != null and inside.global_position.z < INNER_FACE
		and absf(inside.global_position.x - BAY) <= 3.0 and faces_in
		and _lit(inside, "Red") and not _lit(inside, "Green"),
		"G2: before the van docks, bay 9 shows green outside and red on its inside light, which "
		+ "faces into the shed beside the door")


func _check_guides() -> void:
	var held := 0
	var lane := 0
	var beyond := 0
	for side: float in [-1.0, 1.0]:
		held += 1 if not _bodies_in(Vector3(0.1, 0.1, 0.1), Vector3(BAY + side * 1.32, 0.12,
			22.5)).is_empty() else 0
		lane += _bodies_in(Vector3(0.1, 0.1, 0.1), Vector3(BAY + side * 1.15, 0.12, 22.5)).size()
		beyond += _bodies_in(Vector3(0.1, 0.1, 0.1), Vector3(BAY + side * 1.32, 0.12,
			26.0)).size()
	var guides := _shed.find_children("WheelGuide*", "MeshInstance3D", true, false)
	_check(held == 2 and lane == 0 and beyond == 0 and guides.size() >= 2,
		("Bay 9 has two solid wheel guides, their inner faces 1.25 m either side of its centre "
		+ "line, the lane between them clear and the guides ended before z 26 (%d solid, %d in "
		+ "the lane, %d beyond, %d pieces)") % [held, lane, beyond, guides.size()])


func _check_chock_at_rest() -> void:
	var chock := _shed.get_node_or_null("Yard/WheelChock") as Node3D
	var at := chock.global_position if chock != null else Vector3.INF
	_check(chock != null and absf(at.x - BAY) <= 3.0 and at.z > 20.0 and at.z < 20.5
		and at.y > 0.4 and at.y < 1.2,
		"Bay 9's wheel chock hangs on its holder on the dock face, beside the bay (%s)" % str(at))


func _check_rear_doors() -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT_SPOT))
	await _seconds(0.5)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk(TO_THE_REAR)
	var asks := _hint()
	await _key(KEY_E)
	await _seconds(2.5)
	var opened := _door_angles()
	var again := _hint()
	await _key(KEY_E)
	await _seconds(2.5)
	var closed := _door_angles()
	_check(asks == "E  Open the rear doors" and opened.x >= SWUNG and opened.y >= SWUNG
		and again == "E  Close the rear doors",
		("G3: on foot behind the stopped van the hint offers the rear doors (%s), and E swings "
		+ "both open and back against the sides (%.0f° and %.0f°)") % [asks, opened.x, opened.y])
	_check(closed.x >= 0.0 and closed.y >= 0.0 and closed.x < 1.0 and closed.y < 1.0,
		"G3: E again closes them (%.1f° and %.1f°)" % [closed.x, closed.y])
	await _walk([BESIDE])
	_check(_hint() == "E  Get in the van",
		"G3: beside the van, not behind it, E gets Ethan in rather than opening the doors (%s)"
		% _hint())


func _check_docking() -> void:
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	var short := await _back_onto_bay(GENTLE, true, NAN, SHORT_OF)
	var short_said := "%s: %s" % [_objective(), _detail()]
	var shut := await _back_onto_bay(GENTLE)
	var shut_said := "%s: %s" % [_objective(), _detail()]
	var shut_green := _bay_green()
	await _pull_forward()
	await _open_doors_and_board()
	var fast := await _back_onto_bay(FLAT_OUT, false)
	var fast_said := "%s: %s" % [_objective(), _detail()]
	var fast_green := _bay_green()
	await _pull_forward()
	var good := await _back_onto_bay(GENTLE)
	var good_said := "%s: %s" % [_objective(), _detail()]
	_check(shut["deepest"] > -0.02 and fast["deepest"] > -0.02 and good["deepest"] > -0.02,
		("G4: each time, the bumpers stop the van: its rear never passes their face (%.3f, %.3f "
		+ "and %.3f m from it at the closest)") % [shut["deepest"], fast["deepest"],
		good["deepest"]])
	_check(short["gap"] > 0.3 and short_said.begins_with("BACK ONTO BAY 9")
		and short_said.contains("short of the bumpers"),
		("G5: stopped %.2f m short of the bumpers, it is no docking, and the objective says how "
		+ "far (%s)") % [short["gap"], short_said])
	_check(shut_said.begins_with("BACK ONTO BAY 9") and shut_said.contains("doors") and shut_green,
		"G5: backed on with the rear doors shut, it is no docking; bay 9 stays green and the "
		+ "objective says why (%s)" % shut_said)
	_check(fast["arrived"] > 1.4 and fast_said.begins_with("BACK ONTO BAY 9")
		and fast_said.contains("fast") and fast_green,
		("G5: arriving at %.1f m/s, it is no docking; bay 9 stays green and the objective names "
		+ "the speed (%s)") % [fast["arrived"], fast_said])
	_check(good["gap"] <= 0.3 and good["angle"] <= 3.0 and good["offset"] <= 0.1
		and good["arrived"] <= 1.4 and good_said.begins_with("CHOCK THE WHEEL") and _bay_green(),
		("G4: backed on slowly with the doors open, the van docks: its rear %.2f m from the "
		+ "bumpers, %.1f° from square, %.2f m off the centre line, arrived at %.1f m/s; the "
		+ "objective asks for the chock (%s)") % [good["gap"], good["angle"], good["offset"],
		good["arrived"], good_said])
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk([BY_THE_WHEEL])
	var offered := _hint()
	await _key(KEY_E)
	await _seconds(1.5)
	var chock := _shed.get_node_or_null("Yard/WheelChock") as Node3D
	var under := chock.global_position.distance_to(_van.to_global(CHOCK_SPOT)) \
		if chock != null else INF
	var outside := _shed.get_node("Building/DockSignal9") as Node3D
	var inside := _shed.get_node("Building/DockSignalInside9") as Node3D
	_check(offered == "E  Chock the rear wheel" and under <= 0.25 and _lit(outside, "Red")
		and not _lit(outside, "Green") and _lit(inside, "Green") and not _lit(inside, "Red"),
		("G6 and G2: beside the rear wheel the hint offers the chock (%s); E puts it in front of "
		+ "the wheel (%.2f m off), and bay 9 turns red outside and green inside") % [offered,
		under])
	_check(_objective() == "MISSION 2 IS BEING BUILT" and _detail() == "Next: the load.",
		"Docked and chocked, the step ends and points at the load (%s: %s)" % [_objective(),
		_detail()])
	await _walk([AT_THE_DOOR])
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	var parked := _van.global_position
	await _key(KEY_Q)
	var boarded := _in_the_van() and int(_van.get("gear")) > 0
	Input.action_press("accelerate")
	await _seconds(2.0)
	Input.action_release("accelerate")
	var moved := _flat(_van.global_position - parked).length()
	_check(boarded and moved < 0.05 and (chock.global_position.distance_to(
		_van.to_global(CHOCK_SPOT)) < 0.05 if chock != null else false),
		("G6: with the chock in, Ethan at the wheel in first gear cannot drive off (%.3f m; in "
		+ "the van %s, gear %d)") % [moved, _in_the_van(), int(_van.get("gear"))])
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk([BY_THE_WHEEL])
	var take := _hint()
	await _key(KEY_E)
	await _seconds(0.5)
	var hung := chock.global_position.distance_to(_shed.get_node("Yard/ChockHolder")
		.global_position) if chock != null else INF
	_check(take == "E  Take the chock out" and hung < 0.3 and _bay_green()
		and _lit(inside, "Red") and not _lit(inside, "Green"),
		("G2: E at the wheel takes the chock out again (%s): it hangs back on its holder (%.2f m) "
		+ "and bay 9 turns green outside and red inside") % [take, hung])
	await _check_misses()


func _check_misses() -> void:
	await _walk([AT_THE_DOOR])
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	await _pull_forward()
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT_SPOT))
	await _seconds(0.5)
	var crooked := await _back_onto_bay(GENTLE, true, deg_to_rad(CROOKED), 0.0, TURN_AT)
	var crooked_said := "%s: %s" % [_objective(), _detail()]
	await _pull_forward()
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT_SPOT
		+ Vector3(OFF_CENTRE, 0.0, 0.0)))
	await _seconds(0.5)
	var off := await _back_onto_bay(GENTLE, true, 0.0)
	var off_said := "%s: %s" % [_objective(), _detail()]
	_check(crooked["angle"] > 3.0 and crooked_said.begins_with("BACK ONTO BAY 9")
		and crooked_said.contains("off square"),
		("G5: backed on %.1f° off square (its rear %.2f m from the bumpers), it is no docking, "
		+ "and the objective says so (%s)") % [crooked["angle"], crooked["gap"], crooked_said])
	_check(off["offset"] > 0.1 and off["angle"] <= 3.0 and off_said.begins_with("BACK ONTO BAY 9")
		and off_said.contains("off the bay's centre"),
		("G5: backed on square but %.2f m off the centre line (its rear %.2f m from the "
		+ "bumpers), it is no docking, and the objective says so (%s)") % [off["offset"],
		off["gap"], off_said])


func _back_onto_bay(top: float, easing: bool = true, hold: float = NAN,
		stop_at: float = 0.0, turn_at: float = INF) -> Dictionary:
	if int(_van.get("gear")) > 0:
		await _key(KEY_Q)
	var deepest := INF
	var arrived := 0.0
	var still := 0.0
	var time := 0.0
	while time < 40.0 and still < 1.2:
		var rear := _van.to_global(VAN_REAR)
		var gap := rear.z - BUMPERS
		deepest = minf(deepest, gap)
		var speed := absf(float(_van.get("actual_speed")))
		if gap < 0.4:
			arrived = maxf(arrived, speed)
		var wanted := top if gap > 1.5 or not easing else minf(top, SLOWER)
		var stopping := gap < stop_at
		_press("accelerate", speed < wanted - 0.15 and not stopping)
		_press("brake", speed > wanted + 0.4 or stopping)
		_steer_into_bay(rear, hold if gap < turn_at else NAN)
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if speed < 0.03 and gap < 1.0 else 0.0
	for action: String in ["accelerate", "brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	await _seconds(0.8)
	var rear := _van.to_global(VAN_REAR)
	var square := rad_to_deg(acos(clampf(-_van.global_basis.z.normalized().z, -1.0, 1.0)))
	return {"gap": rear.z - BUMPERS, "deepest": deepest, "arrived": arrived,
		"angle": square, "offset": absf(rear.x - BAY)}


func _steer_into_bay(rear: Vector3, hold: float) -> void:
	var ahead := -_van.global_basis.z
	var heading := atan2(ahead.x, ahead.z)
	var wanted := clampf((rear.x - BAY) * 0.6, -0.3, 0.3) if is_nan(hold) else hold
	var command := clampf((heading - wanted) * (3.0 if is_nan(hold) else 8.0), -1.0, 1.0)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if command > 0.02:
		Input.action_press("steer_left", command)
	elif command < -0.02:
		Input.action_press("steer_right", -command)


func _pull_forward() -> void:
	if int(_van.get("gear")) < 0:
		await _key(KEY_Q)
	Input.action_press("accelerate")
	await _seconds(1.5)
	Input.action_release("accelerate")
	Input.action_press("brake")
	await _seconds(1.5)
	Input.action_release("brake")


func _open_doors_and_board() -> void:
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk(TO_THE_REAR)
	await _key(KEY_E)
	await _seconds(2.5)
	await _walk([BESIDE])
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)


func _press(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _bay_green() -> bool:
	var outside := _shed.get_node("Building/DockSignal9") as Node3D
	return _lit(outside, "Green") and not _lit(outside, "Red")


func _in_the_van() -> bool:
	return bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _detail() -> String:
	return (_hud.get("_detail") as Label).text


func _door_angles() -> Vector2:
	var left := _van.find_child("RearDoorLeft", true, false) as Node3D
	var right := _van.find_child("RearDoorRight", true, false) as Node3D
	if left == null or right == null:
		return Vector2(-1.0, -1.0)
	return Vector2(absf(rad_to_deg(left.rotation.y)), absf(rad_to_deg(right.rotation.y)))


func _walk(points: Array[Vector3]) -> void:
	for point in points:
		var target := _van.to_global(point)
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(target - _driver.global_position).length() > 0.3 and time < 12.0:
			_driver.call("look_toward", _flat(target - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	await _seconds(0.4)


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _bodies_in(size: Vector3, at: Vector3) -> Array[Dictionary]:
	var box := BoxShape3D.new()
	box.size = size
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, at)
	query.exclude = [_van.get_rid()]
	return _van.get_world_3d().direct_space_state.intersect_shape(query, 8)


func _lit(signal_node: Node3D, lens: String) -> bool:
	var mesh := signal_node.get_node_or_null(lens) as MeshInstance3D
	var surface := mesh.get_active_material(0) as StandardMaterial3D if mesh != null else null
	return surface != null and surface.emission_enabled


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _build() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_hud = _app.get_node("DrivingHud")
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await process_frame
	await process_frame


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The bay 9 checks finish within 280 s")
	_finish()


func _finish() -> void:
	print("BAY NINE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
