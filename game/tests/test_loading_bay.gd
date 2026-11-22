extends SceneTree
## Mission 2's step 5, part C (docs/PHASE_BRIEF.md; #315): the east warehouse's door 3 open, its
## door raised into its tracks, its inside one bay deep and lit (the floor at the dock's height
## over the whole of the warehouse, the leveller, pallets, the racks' ends beyond); the court
## marked (each door's number on the ground, guide lines either side of door 3); the yard dressed
## (floodlights on poles, trailers dropped square at two of the west warehouse's docks on their
## landing gear, pallet stacks, a parked forklift, dumpsters, each solid) and nothing in the van's
## way from the gate to door 3; backing onto door 3 by real key presses, judged as bay 9 is: short
## of the bumpers no docking and the objective says how far; docked, its signal red, stage 3
## saved and the objective names the hill road; and a reload at stage 3 docked there.

const STAGE_TWO := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const STAGE_THREE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=3\n"
const EAST := Rect2(232.284, 108.5, 35.432, 23.0)
const WEST := Rect2(133.325, 100.5, 33.35, 23.0)
const DOOR := 248.0
const EAST_DOCKS: Array[float] = [240.0, 244.0, 248.0, 252.0, 256.0, 260.0, 264.0]
const DOCK_FLOOR := 1.22
const BUMPERS := 131.63
const COURT_SPOT := Vector3(248.0, 0.1, 141.0)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const GENTLE := 1.2
const SLOWER := 0.6
const SHORT_OF := 0.6
const DOCKED_WITHIN := 0.10
## The van's way in: from the gate down into the court and across it to door 3.
const VAN_WAY: Array[Rect2] = [Rect2(197.0, 134.0, 6.0, 12.0), Rect2(197.0, 134.0, 56.0, 11.0),
	Rect2(245.5, 131.7, 5.0, 3.0)]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _compound: Node3D
var _cargo: Node
var _hud: CanvasLayer
var _saved: Array[ConfigFile] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-loading-bay-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start(STAGE_TWO)
	var house := _compound.get_node_or_null("WarehouseEast") as Node3D
	_check(house != null and house.has_method("open_dock"), "L0: the east warehouse has its "
		+ "open door")
	if house == null or not house.has_method("open_dock"):
		_finish()
		return
	_check_bay(house)
	_check_court(house)
	await _check_yard()
	await _check_docking(house)
	await _check_reload()
	_finish()


func _start(save: String) -> void:
	if _app != null:
		_app.queue_free()
		await process_frame
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(save)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_cargo = _app.get("cargo") as Node
	_hud = _app.get("hud") as CanvasLayer
	_cargo.connect("checkpoint_reached", func(config: ConfigFile) -> void: _saved.append(config))
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_compound = _app.get_node("IndustrialLoop").get("compound") as Node3D


func _check_bay(house: Node3D) -> void:
	var open := int(house.call("open_dock"))
	var door := house.get_node_or_null("DockDoor%d" % (open + 1)) as Node3D
	var raised := door != null and not door.has_node("DoorBody") \
		and absf((door.get_child(0) as Node3D).rotation.x + PI / 2.0) < 0.01
	var tracks := house.find_children("DoorTrack*", "MeshInstance3D", true, false).size()
	var shut := 0
	for index in range(EAST_DOCKS.size()):
		var other := house.get_node_or_null("DockDoor%d" % (index + 1))
		shut += 1 if other != null and other.has_node("DoorBody") else 0
	_check(open == 2 and raised and tracks >= 2 and shut == EAST_DOCKS.size() - 1, "L1: door 3 "
		+ "open, its door raised into its tracks, the other six shut")
	var floor_box := _merged(house, "InteriorFloor")
	var covered := floor_box.has_volume() and absf(floor_box.end.y - DOCK_FLOOR) < 0.01 \
		and floor_box.position.x <= EAST.position.x + 0.25 and floor_box.end.x >= EAST.end.x - 0.25 \
		and floor_box.position.z <= EAST.position.y + 0.25 and floor_box.end.z >= EAST.end.y - 0.25
	var leveller := house.get_node_or_null("DockLeveller3") as Node3D
	var levelled := leveller != null and absf(leveller.global_position.x - DOOR) < 0.05
	var pallets := house.find_children("BayPallet*", "Node3D", true, false).size()
	var racks := 0
	for node in house.find_children("RackEnd*", "MeshInstance3D", true, false):
		var at := (node as MeshInstance3D).global_position
		racks += 1 if EAST.end.y - at.z > 5.0 else 0
	var lit := false
	for light in house.find_children("BayLight*", "Light3D", true, false):
		var at := (light as Light3D).global_position
		lit = lit or (EAST.has_point(Vector2(at.x, at.z)) and at.y > DOCK_FLOOR + 2.0)
	_check(covered and levelled and pallets >= 2 and racks >= 2 and lit, "L1: inside door 3 the "
		+ "floor at the dock's height over the whole warehouse, the leveller, %d pallets, " % pallets
		+ "%d racks' ends beyond 5 m, lit" % racks)


func _check_court(house: Node3D) -> void:
	var numbers := 0
	for index in range(EAST_DOCKS.size()):
		var mark := house.get_node_or_null("CourtNumber%d" % (index + 1)) as Node3D
		numbers += 1 if mark != null and absf(mark.global_position.x - EAST_DOCKS[index]) < 0.05 \
			and mark.global_position.y < 0.1 and mark.global_position.z > EAST.end.y else 0
	var lines := house.find_children("GuideLine*", "MeshInstance3D", true, false)
	var sides := {}
	for line in lines:
		var box := (line as MeshInstance3D).global_transform * (line as MeshInstance3D).get_aabb()
		if absf(box.get_center().x - DOOR) < 2.5 and box.size.z >= 6.0 and box.end.y < 0.1:
			sides[signf(box.get_center().x - DOOR)] = true
	_check(numbers == EAST_DOCKS.size() and sides.size() == 2, "L2: each east door's number on "
		+ "the court (%d), guide lines either side of door 3" % numbers)


func _check_yard() -> void:
	await physics_frame
	var space := _app.get_world_3d().direct_space_state
	var poles := _compound.find_children("FloodPole*", "MeshInstance3D", true, false).size()
	var floods := _compound.find_children("Flood*", "SpotLight3D", true, false)
	var shadowed := 0
	for light in floods:
		shadowed += 1 if (light as SpotLight3D).shadow_enabled else 0
	_check(poles >= 2 and floods.size() >= poles and shadowed <= 1, "L3: %d floodlights on %d "
		% [floods.size(), poles] + "poles, shadows on at most one")
	var trailers := _compound.find_children("DroppedTrailer*", "Node3D", false, false)
	var square := trailers.size() == 2
	for trailer in trailers:
		var node := trailer as Node3D
		var yaw := rad_to_deg(absf(node.global_basis.z.normalized().signed_angle_to(Vector3.BACK,
			Vector3.UP)))
		square = square and (yaw < 1.0 or yaw > 179.0) and node.global_position.x > WEST.position.x \
			and node.global_position.x < WEST.end.x and absf(float(node.get_meta("rear_z", 0.0))
			- (WEST.end.y + 0.13)) < 0.1 and absf(float(node.get_meta("gear_down", 1.0))) < 0.05
	var missed: Array[String] = []
	for prefix: String in ["DroppedTrailer", "PalletStack", "ParkedForklift", "Dumpster"]:
		var found := _compound.find_children(prefix + "*", "Node3D", false, false)
		if found.is_empty():
			missed.append(prefix + " (none)")
		for node in found:
			var probe := PhysicsPointQueryParameters3D.new()
			probe.position = (node as Node3D).global_position + Vector3.UP * 0.6
			if space.intersect_point(probe, 1).is_empty():
				missed.append(String(node.name))
	_check(square and missed.is_empty(), "L3: two trailers dropped square at the west docks on "
		+ "their gear; pallet stacks, a forklift and dumpsters; each solid (not: %s)" % ", ".join(
		missed))
	var blocked: Array[Rect2] = []
	for rect: Rect2 in _compound.call("footprints"):
		for way in VAN_WAY:
			if rect.intersects(way):
				blocked.append(rect)
	_check(blocked.is_empty(), "L3: nothing in the van's way from the gate to door 3 (%s)"
		% str(blocked))


func _check_docking(house: Node3D) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT_SPOT))
	_van.set("rear_doors_open", true)
	await _frames(30)
	var short := await _back_onto_door(GENTLE, SHORT_OF)
	await _seconds(0.8)
	var short_said := _objective()
	await _pull_forward()
	var good := await _back_onto_door(GENTLE)
	await _seconds(1.0)
	var said := _objective()
	_check(short["gap"] > 0.3 and short_said.begins_with("BACK ONTO DOOR 3")
		and short_said.contains("short of the bumpers"), "L4: %.2f m short of door 3's bumpers, "
		% short["gap"] + "no docking, and the objective says how far (%s)" % short_said)
	var lamp := house.get_node("DockSignal3") as Node3D
	var red := (lamp.get_node("Red") as MeshInstance3D).material_override
	var red_lit := red != null and (red as StandardMaterial3D).emission_enabled
	var saved := not _saved.is_empty() and int(_saved[_saved.size() - 1].get_value("cargo",
		"stage", -1)) == 3
	_check(good["gap"] <= DOCKED_WITHIN and good["angle"] <= 3.0 and good["offset"] <= 0.1
		and red_lit and saved and said.begins_with("GET OUT AND RUN")
		and String(_cargo.call("place_reached")) == "The warehouse compound", "L4: backed onto door "
		+ "3 (%.3f m, %.1f°, %.2f m off), its signal red, stage 3 saved, the objective " % [
		good["gap"], good["angle"], good["offset"]] + "the escape's GET OUT AND RUN (%s)" % said)


func _check_reload() -> void:
	await _start(STAGE_THREE)
	await _frames(30)
	var rear := _van.to_global(VAN_REAR)
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	var copy := yard.call("left_van") as Node3D
	_check(rear.z - BUMPERS <= DOCKED_WITHIN + 0.05 and absf(rear.x - DOOR) < 0.1
		and bool(_van.get("rear_doors_open")) and copy != null
		and str(copy.get_meta("seal_number", "")) != "" and bool(_compound.call("gate_shut"))
		and _objective().begins_with("GET OUT AND RUN"), "L5: reloaded at stage 3: the dark "
		+ "van docked at door 3 (%.3f m), its doors open, his own van sealed in the " % (rear.z
		- BUMPERS) + "yard, the gate shut")


func _back_onto_door(top: float, stop_at: float = 0.0) -> Dictionary:
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
		var wanted := top if gap > 1.5 else minf(top, SLOWER)
		var stopping := gap < stop_at
		_press("accelerate", speed < wanted - 0.15 and not stopping)
		_press("brake", speed > wanted + 0.4 or stopping)
		_steer(rear)
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if speed < 0.03 and gap < 1.0 + stop_at else 0.0
	for action: String in ["accelerate", "brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	await _seconds(0.8)
	var rear := _van.to_global(VAN_REAR)
	var square := rad_to_deg(acos(clampf(-_van.global_basis.z.normalized().z, -1.0, 1.0)))
	return {"gap": rear.z - BUMPERS, "deepest": deepest, "arrived": arrived, "angle": square,
		"offset": absf(rear.x - DOOR)}


func _steer(rear: Vector3) -> void:
	var ahead := -_van.global_basis.z
	var heading := atan2(ahead.x, ahead.z)
	var wanted := clampf((rear.x - DOOR) * 0.6, -0.3, 0.3)
	var command := clampf((heading - wanted) * 3.0, -1.0, 1.0)
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


func _press(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await physics_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await physics_frame


func _objective() -> String:
	return (_hud.get("_objective") as Label).text + " / " + (_hud.get("_detail") as Label).text


func _merged(house: Node3D, prefix: String) -> AABB:
	var merged := AABB()
	for node in house.find_children(prefix + "*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		merged = box if not merged.has_volume() else merged.merge(box)
	return merged


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _timeout() -> void:
	_check(false, "The loading bay's checks finish within 400 s")
	_finish()


func _finish() -> void:
	print("LOADING BAY RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
