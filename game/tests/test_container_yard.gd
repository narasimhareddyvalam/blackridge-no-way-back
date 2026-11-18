extends SceneTree
## Mission 2's step 4 (docs/PHASE_BRIEF.md, "the container yard and the swap"; the author's
## choices, #311-#312), on Mission 2's stage 1 save (loaded and sealed), by real key presses where
## the player acts: the yard fenced round but at its gate; ISO 668 containers stacked squarely, no
## stack over three high, the lane 16 m wide and nothing in the van's way; the gate shut until E
## at the keypad from the stop line, Ethan's window down and a beep a key, then sliding open and
## shutting behind the van; the bay and the dark van; the swap: one drivable van, the dark one, in
## its paint, empty, the copy of his van within 1 cm of where it stood with its load and its seal,
## the mirror cameras as before, stage 2 saved and its objective; and a reload at stage 2.

const STAGE_ONE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const STAGE_TWO := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const YARD := Rect2(64.0, 132.0, 72.0, 26.0)
const GATE := Vector2(97.0, 103.0)
const FENCE_HEIGHT := 2.4
const SIZES := {"Container20": Vector3(6.058, 2.591, 2.438),
	"Container40": Vector3(12.192, 2.591, 2.438), "Container40HC": Vector3(12.192, 2.896, 2.438)}
const CORNER := 0.05
const MOST_HIGH := 3
const LANE := Vector2(92.0, 108.0)
## The van's way: in through the gate's width down to the bay, and across to the dark van.
const VAN_WAY: Array[Rect2] = [Rect2(97.0, 142.0, 6.0, 16.0), Rect2(93.0, 134.0, 14.0, 8.5)]
const BEFORE_LINE := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.1, 165.3))
const FAR_FROM_LINE := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.1, 176.0))
const INSIDE := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.1, 150.0))
const BAY_POSE := Transform3D(Basis.IDENTITY, Vector3(95.0, 0.1, 138.0))
const OFF_BAY := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.1, 146.0))
const DARK_VAN := Transform3D(Basis(Vector3.UP, PI), Vector3(104.5, 0.1, 140.0))
const DRIVER_DOOR := Vector3(-1.1, 0.0, -1.3)
const DARK := Color(0.2, 0.21, 0.22)
const SEAL_NUMBER := "4182260"
const COPY_WITHIN := 0.01
const CODE_KEYS := 4

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _yard: Node3D
var _cargo: Node
var _beeps := 0
var _saved: Array[ConfigFile] = []
var _objective := ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-container-yard-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start(STAGE_ONE)
	_check(_yard != null and _yard.has_method("placements"),
		"C0: the world has its container yard (IndustrialLoop/ContainerYard)")
	if _yard == null or not _yard.has_method("placements"):
		_finish()
		return
	_check_fence()
	_check_stacks()
	await _check_solid()
	await _check_gate()
	await _check_swap()
	await _check_reload()
	_finish()


func _start(save: String, leave: String = "_resume") -> void:
	if _app != null:
		_app.queue_free()
		await process_frame
	_store(save)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call(leave)
	await physics_frame
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_yard = _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	_cargo = _app.get("cargo") as Node
	if _cargo != null:
		_cargo.connect("checkpoint_reached", func(config: ConfigFile) -> void:
			_saved.append(config))
		_cargo.connect("objective_changed", func(title: String, detail: String) -> void:
			_objective = title + " / " + detail)
	if _yard != null and _yard.has_signal("key_beeped"):
		_yard.connect("key_beeped", func() -> void: _beeps += 1)


func _check_fence() -> void:
	var runs: Array = _yard.call("fence_runs")
	var length := 0.0
	for run: Dictionary in runs:
		length += (run["from"] as Vector2).distance_to(run["to"])
	var perimeter := 2.0 * (YARD.size.x + YARD.size.y)
	var gap := GATE.y - GATE.x
	var posts := _yard.find_children("FencePost*", "MeshInstance3D", true, false)
	var tall := not posts.is_empty()
	for post in posts:
		tall = tall and absf((post as MeshInstance3D).get_aabb().size.y - (FENCE_HEIGHT + 0.05)) \
			< 0.02
	var barbs := _yard.find_children("BarbStrand*", "MeshInstance3D", true, false).size()
	_check(absf(length + gap - perimeter) < 0.01 and tall and barbs == runs.size() * 3,
		"C1: the yard fenced round in 2.4 m chain-link with barbed wire but for its 6 m gate "
		+ "(%.1f m of %.1f m, %d strands)" % [length, perimeter, barbs])


func _check_stacks() -> void:
	var placed: Array = _yard.call("placements", "Containers")
	var kinds: Array = _yard.call("container_kinds")
	var sized := placed.size() == kinds.size() and placed.size() > 20
	var stacked := sized
	var highest := 0
	var columns := {}
	for index in range(placed.size()):
		var at: Transform3D = placed[index]
		var key := "%.2f,%.2f" % [at.origin.x, at.origin.z]
		if not columns.has(key):
			columns[key] = []
		(columns[key] as Array).append(index)
	for key: String in columns:
		var column: Array = columns[key]
		highest = maxi(highest, column.size())
		var y := 0.02
		for index: int in column:
			var at: Transform3D = placed[index]
			var kind: String = kinds[index]
			sized = sized and SIZES.has(kind)
			stacked = stacked and absf(at.origin.y - y) < 0.005 and kind.substr(0, 11) \
				== String(kinds[column[0]]).substr(0, 11) and at.basis.is_equal_approx(
				(placed[column[0]] as Transform3D).basis)
			y += (SIZES[kind] as Vector3).y if SIZES.has(kind) else 0.0
	_check(sized, "C2: %d ISO 668 containers, 20 ft, 40 ft and 40 ft high cube" % placed.size())
	_check(stacked and highest <= MOST_HIGH and highest >= 2, "C2: each on the one below or the "
		+ "paving, corner on corner, of one length, at most %d high (highest %d)" % [MOST_HIGH,
		highest])
	var blocked := []
	var lane_clear := true
	for rect: Rect2 in _yard.call("footprints"):
		for way in VAN_WAY:
			if rect.intersects(way):
				blocked.append(rect)
		lane_clear = lane_clear and (rect.end.x <= LANE.x or rect.position.x >= LANE.y
			or rect.position.y > 156.0)
	_check(blocked.is_empty() and lane_clear and LANE.y - LANE.x >= 12.0, "C2: the lane 16 m wide "
		+ "between the blocks and nothing in the van's way (%d in it)" % blocked.size())


func _check_solid() -> void:
	await physics_frame
	var space := _app.get_world_3d().direct_space_state
	var missed: Array[String] = []
	for rect: Rect2 in _yard.call("footprints"):
		var probe := PhysicsPointQueryParameters3D.new()
		probe.position = Vector3(rect.get_center().x, 0.5, rect.get_center().y)
		if space.intersect_point(probe, 1).is_empty():
			missed.append("stack at %s" % rect.get_center())
	var walls := {"west": [Vector3(65.0, 1.0, 145.0), Vector3(63.0, 1.0, 145.0)],
		"north": [Vector3(100.0, 1.0, 133.0), Vector3(100.0, 1.0, 131.0)],
		"east": [Vector3(135.0, 1.0, 145.0), Vector3(137.0, 1.0, 145.0)],
		"south": [Vector3(80.0, 1.0, 157.0), Vector3(80.0, 1.0, 159.0)],
		"gate": [Vector3(100.0, 1.0, 157.0), Vector3(100.0, 1.0, 159.0)]}
	for wall: String in walls:
		var ray := PhysicsRayQueryParameters3D.create(walls[wall][0], walls[wall][1])
		if space.intersect_ray(ray).is_empty():
			missed.append(wall)
	var own := Vector3.ZERO
	for child in _van.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			own = ((child as CollisionShape3D).shape as BoxShape3D).size
			break
	var parked := _yard.get_node("DarkVan/DarkVanBody").get_child(0) as CollisionShape3D
	var fitted := (parked.shape as BoxShape3D).size
	if not fitted.is_equal_approx(own):
		missed.append("the dark van %s, not %s" % [fitted, own])
	_check(missed.is_empty(), "C2: every stack solid, the fence round, the shut gate and the "
		+ "dark van as big as his (not: %s)" % ", ".join(missed))


func _check_gate() -> void:
	_van.call("recover", FAR_FROM_LINE)
	await _frames(20)
	_check(not bool(_cargo.call("wants_interact")), "C3: away from the line, E at the keypad is "
		+ "not offered")
	_van.call("recover", BEFORE_LINE)
	await _frames(20)
	_check(bool(_yard.call("gate_shut")) and bool(_cargo.call("wants_interact")),
		"C3: the gate shut, and E offered at the stop line")
	_tap("interact")
	await _frames(5)
	var window_down := float(_van.get("left_window_target")) > 0.5
	var waited := 0.0
	while not bool(_yard.call("gate_open")) and waited < 20.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(window_down and _beeps == CODE_KEYS and bool(_yard.call("gate_open")),
		"C3: E keys the code in, his window down, a beep a key (%d), and the gate slides open "
		% _beeps + "(%.1f s)" % waited)
	_van.call("recover", INSIDE)
	await _frames(10)
	_van.call("recover", OFF_BAY)
	waited = 0.0
	while not bool(_yard.call("gate_shut")) and waited < 20.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(bool(_yard.call("gate_shut")) and float(_van.get("left_window_target")) < 0.5,
		"C3: and shuts behind the van, the window up again (%.1f s)" % waited)


func _check_swap() -> void:
	var driver := _app.get("driver") as Node3D
	var door := DARK_VAN * DRIVER_DOOR
	_van.call("recover", OFF_BAY)
	await _frames(10)
	_tap("interact")
	await _seconds(3.0)
	driver.global_position = door + Vector3.UP * 0.05
	await _frames(10)
	var refused := String(_cargo.call("foot_action", driver.global_position))
	_check(refused == "Leave your van in the marked bay first", "C4: out of the bay, the dark van "
		+ "is not his yet (\"%s\")" % refused)
	await _board()
	_van.call("recover", BAY_POSE)
	await _frames(20)
	var stood: Transform3D = _van.global_transform
	_tap("interact")
	await _seconds(3.0)
	driver.global_position = door + Vector3.UP * 0.05
	await _frames(10)
	var offered := String(_cargo.call("foot_action", driver.global_position))
	var mirrors := _mirrors()
	_tap("interact")
	await _frames(10)
	var copy := _yard.call("left_van") as Node3D
	var vans := _app.find_children("*", "CharacterBody3D", true, false).filter(
		func(node: Node) -> bool: return node.has_method("recover"))
	var paint: Color = _van.get_node("VanPresentation").call("paint")
	var carried := (_van.call("body") as Node3D).get_children().filter(func(node: Node) -> bool:
		return node.has_meta("strapped")).size()
	_check(offered == "Take the dark van" and copy != null and vans.size() == 1 and carried == 0
		and paint.is_equal_approx(DARK) and _van.global_position.distance_to(DARK_VAN.origin) < 0.3
		and not bool(_van.get("sealed")), "C5: in the bay, E at the dark van's door: one drivable "
		+ "van, the dark one, in its place and paint, empty (%d carried)" % carried)
	var where := copy.global_position.distance_to(stood.origin) if copy != null else INF
	var load := copy.find_children("*", "Node3D", false, false).filter(func(node: Node) -> bool:
		return node.has_meta("strapped")).size() if copy != null else 0
	_check(where <= COPY_WITHIN and copy != null and str(copy.get_meta("seal_number", ""))
		== SEAL_NUMBER and bool(copy.get_meta("sealed", false)) and load >= 1, "C5: his van left "
		+ "where it stood (%.4f m) with its load (%d), shut and sealed" % [where, load])
	_check(_mirrors() == mirrors
		and mirrors > 0, "C5: the mirror cameras as before (%d)" % mirrors)
	var saved := not _saved.is_empty() and int(_saved[_saved.size() - 1].get_value("cargo",
		"stage", -1)) == 2
	_check(saved and String(_cargo.call("place_reached")) == "The container yard"
		and _objective.to_lower().contains("the warehouse compound"),
		"C6: stage 2 saved, the container yard reached, the objective the next place (%s)"
		% _objective)
	await _board()
	_check(bool(_van.get("occupied")), "C6: and Ethan gets in the dark van by E")


func _check_reload() -> void:
	await _start(STAGE_TWO, "_begin")
	await _frames(20)
	var copy := _yard.call("left_van") as Node3D
	var paint: Color = _van.get_node("VanPresentation").call("paint")
	var parked := copy.global_position.distance_to(BAY_POSE.origin) if copy != null else INF
	var seal := str(copy.get_meta("seal_number", "")) if copy != null else ""
	var driven := _van.global_position.distance_to(DARK_VAN.origin)
	_check(parked < 0.3 and seal == SEAL_NUMBER and paint.is_equal_approx(DARK) and driven < 0.3
		and not _yard.get_node("DarkVan").visible, "C7: reloaded at stage 2: the dark van his "
		+ "(%.2f m, %s), his own in the bay (%.2f m), sealed (%s)" % [driven, paint, parked, seal])


func _mirrors() -> int:
	var cameras: Array = _van.get_node("VanPresentation").get("mirror_cameras")
	var count := 0
	for camera in cameras:
		if is_instance_valid(camera) and (camera as Camera3D).is_inside_tree():
			count += 1
	return count


func _board() -> void:
	var waited := 0.0
	var driver := _app.get("driver") as Node3D
	if bool(_van.get("occupied")):
		return
	driver.global_position = _van.to_global(Vector3(-1.4, 0.0, -1.0)) + Vector3.UP * 0.05
	await _frames(5)
	_tap("interact")
	while not bool(_van.get("occupied")) and waited < 10.0:
		await physics_frame
		waited += 1.0 / 60.0


func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The container yard's checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("CONTAINER YARD RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_remove()
	quit(1 if _failures > 0 else 0)
