extends SceneTree
## Part F of step 5 of #253 (docs/PHASE_BRIEF.md, "the safety and work kit"; the author's choices,
## #300): the transfer shed's safety and work kit, read from the shed as the running game builds
## it on Mission 2's start save, through what the kit hands out (`placements()`, `exits()`,
## `signs()`, `solids()`), since a headless run draws nothing: the dock floor over the whole
## shed; two exits for people (IBC 1006.2.1: a storage space of 32 people needs two), apart by a
## third of the diagonal at least (1007.1.1, sprinklered), each with a lit EXIT sign (OSHA
## 1910.37(b): letters 6 in high) and an emergency light, every point within 250 ft of travel of
## one; Class A extinguishers within 75 ft of travel from every point (1910.157(d)(2), NFPA 10),
## measured as the shortest way round the racks, the loads, the office and the kit on a 0.5 m
## grid, each on its hanger at NFPA 10's heights with its sign; the electric forklift's charging
## area marked, with an eyewash within 10 s (about 55 ft) in a clear line (ANSI Z358.1) and a
## spill kit; a convex mirror at every aisle's mouth; the first-aid cabinet by the side door; the
## walkway's crossing over the cross-aisle and the traffic signs.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const FOOT := 0.3048
const DOCK_FLOOR := 1.3
const LANE_FLOOR := 0.02
const DOCK := Rect2(-82.0, -9.75, 37.24, 29.5)
const STRIP := Rect2(-89.75, -9.75, 7.75, 21.75)
const LANE := Rect2(-44.7, -9.75, 4.45, 29.5)
const STAIR := Rect2(-44.7, 12.92, 1.0, 2.25)
const LANDING_END := 13.92
const OFFICE := Rect2(-90.0, 12.0, 8.0, 8.0)
const SIDE_DOOR := Vector2(-40.0, 17.475)
const DIAGONAL := 58.31
const EXIT_APART := DIAGONAL / 3.0
const EXIT_TRAVEL := 250 * FOOT
const EXTINGUISHER_TRAVEL := 75 * FOOT
const EXTINGUISHER_TOP := 5 * FOOT
const EXTINGUISHER_BOTTOM := 0.1
const EXIT_LETTERS := 6 * 0.0254
const EYEWASH_REACH := 55 * FOOT
const MIRROR_SIZE := Vector2(18 * 0.0254, 36 * 0.0254)
const MIRROR_UP := Vector2(2.0, 3.0)
const FIRST_AID_NEAR := 5.0
const WALKWAY := Vector2(-46.6, -45.4)
const CROSS_AISLE := Vector2(10.0, 14.0)
const CELL := 0.5
const LOAD_SIZE := Vector2(1.016, 1.219)
const LOADS: Array[Vector2] = [Vector2(-64.55, 16.45), Vector2(-63.45, 16.45),
	Vector2(-64.55, 15.15), Vector2(-63.45, 15.15), Vector2(-52.0, 16.6), Vector2(-47.2, 16.6),
	Vector2(-49.9, 18.95)]
const DESK := Rect2(-45.8, 17.5, 1.0, 2.1)
const FORKLIFT := Rect2(-64.1, 10.6, 1.8, 3.6)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _shed: Node3D
var _kit: Node3D
var _grid := Vector2i.ZERO
var _walk: PackedByteArray
var _blocked_at := ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-shed-kit-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_kit = _shed.get_node_or_null("Building/ShedKit") as Node3D if _shed != null else null
	_check_floor()
	_check(_kit != null and _kit.has_method("placements"),
		"F0: the shed has its kit (Building/ShedKit) handing out its placements")
	if _kit != null and _kit.has_method("placements"):
		_make_grid()
		_check_exits()
		_check_extinguishers()
		_check_charging()
		_check_mirrors()
		_check_the_rest()
	_finish()


func _check_floor() -> void:
	var body := _shed.get_node_or_null("Building/ShedBody") as StaticBody3D
	var space := _app.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	var bare := 0
	var points := 0
	var x := STRIP.position.x + 0.25
	while x < STRIP.end.x:
		var z := STRIP.position.y + 0.25
		while z < STRIP.end.y:
			points += 1
			ray.from = Vector3(x, DOCK_FLOOR + 0.05, z)
			ray.to = Vector3(x, -0.5, z)
			var hit := space.intersect_ray(ray)
			if hit.is_empty() or hit["collider"] != body or absf((hit["position"] as Vector3).y
					- DOCK_FLOOR) > 0.005:
				bare += 1
			z += 1.0
		x += 1.0
	var drawn := _shed.get_node_or_null("Building/DockFloor4") as MeshInstance3D
	var floor_material: Material = _shed.get_node("Building/ShedFloor").get("material")
	_check(bare == 0 and drawn != null and drawn.get_active_material(0) == floor_material,
		"F1: the dock floor runs over the strip west of x -82 at 1.3 m, in the floor's own "
		+ "material (%d of %d points bare)" % [bare, points])


func _check_exits() -> void:
	var exits: Array = _kit.call("exits")
	var apart := exits.size() == 2 and _flat((exits[0] as Dictionary)["door"]).distance_to(
		_flat((exits[1] as Dictionary)["door"])) >= EXIT_APART
	_check(apart, "F2: two exits for people, at least a third of the shed's diagonal apart "
		+ "(%.1f m; %d exits)" % [EXIT_APART, exits.size()])
	var signed := exits.size() == 2
	var lights := _placed("EmergencyLights")
	var lit_by := exits.size() == 2
	for exit: Dictionary in exits:
		var door: Vector3 = exit["door"]
		var sign_at: Vector3 = exit["sign"]
		signed = signed and sign_at.y > door.y + 2.0 and _flat(sign_at).distance_to(_flat(door)) \
			< 1.0
		var near := false
		for light: Transform3D in lights:
			var inside := light.origin.x >= STRIP.position.x - 0.01 \
				and light.origin.x <= LANE.end.x + 0.01
			near = near or (inside and light.origin.distance_to(door) < 3.5)
		lit_by = lit_by and near
	var letters: float = _kit.get("EXIT_LETTERS")
	var glowing := _shed.find_children("ExitSign*", "MeshInstance3D", true, false)
	for found in glowing:
		var paint := (found as MeshInstance3D).get_active_material(0) as BaseMaterial3D
		signed = signed and paint != null and paint.emission_enabled
	_check(signed and letters >= EXIT_LETTERS and glowing.size() >= 2, "F2: a lit EXIT sign over "
		+ "each exit, its letters %.2f m high (at least 6 in)" % letters)
	_check(lit_by, "F2: an emergency light inside by each exit")
	var sources: Array[Vector2] = []
	for exit: Dictionary in exits:
		sources.append(_flat(exit["door"]))
	var worst := _farthest(sources)
	_check(worst <= EXIT_TRAVEL, "F2: every point of the floor within 250 ft (%.1f m) of travel "
		% EXIT_TRAVEL + "of an exit (farthest %.1f m)" % worst)


func _check_extinguishers() -> void:
	var found := _placed("Extinguishers")
	var tall: float = _kit.get("EXTINGUISHER_TALL")
	var hung := not found.is_empty()
	var signs: Array = _kit.call("signs")
	var signed := hung
	var sources: Array[Vector2] = []
	for extinguisher: Transform3D in found:
		var floor_y := LANE_FLOOR if extinguisher.origin.x > LANE.position.x else DOCK_FLOOR
		var top := extinguisher.origin.y + tall / 2.0 - floor_y
		var bottom := extinguisher.origin.y - tall / 2.0 - floor_y
		hung = hung and top <= EXTINGUISHER_TOP and bottom >= EXTINGUISHER_BOTTOM
		var marked := false
		for sign_item: Dictionary in signs:
			var at: Vector3 = sign_item["centre"]
			marked = marked or (sign_item["kind"] == "extinguisher" and at.y > extinguisher.origin.y
				and _flat(at).distance_to(_flat(extinguisher.origin)) < 0.6)
		signed = signed and marked
		sources.append(_flat(extinguisher.origin))
	_check(hung, "F3: %d extinguishers, each top at most 5 ft and bottom at least 4 in above "
		% found.size() + "its floor")
	_check(signed, "F3: a sign over each extinguisher")
	var worst := _farthest(sources)
	_check(worst <= EXTINGUISHER_TRAVEL, "F3: every point of the dock floor and the lane within "
		+ "75 ft (%.1f m) of travel of an extinguisher (farthest %.1f m)"
		% [EXTINGUISHER_TRAVEL, worst])


func _check_charging() -> void:
	var chargers := _placed("Chargers")
	var eyewash := _placed("Eyewash")
	var spill := _placed("SpillKits")
	var marks := _placed("ChargingMarks")
	var ok := chargers.size() == 1 and eyewash.size() == 1 and spill.size() == 1 \
		and not marks.is_empty()
	var reach := INF
	var clear := false
	if ok:
		var charger := _before(chargers[0])
		var wash := _before(eyewash[0])
		reach = charger.distance_to(wash)
		clear = _clear_line(charger, wash)
		ok = ok and _flat((spill[0] as Transform3D).origin).distance_to(charger) < 10.0
		reach = _flat((chargers[0] as Transform3D).origin).distance_to(_flat((eyewash[0]
			as Transform3D).origin))
	_check(ok, "F4: the forklift's charger, its marked area, an eyewash and a spill kit by it")
	_check(reach <= EYEWASH_REACH and clear, "F4: the eyewash within 55 ft (%.1f m) of the charger "
		% EYEWASH_REACH + "in a clear line (%.1f m%s)" % [reach, _blocked_at])
	var no_smoking := false
	for sign_item: Dictionary in _kit.call("signs"):
		no_smoking = no_smoking or (sign_item["kind"] == "no_smoking" and not chargers.is_empty()
			and _flat(sign_item["centre"]).distance_to(_flat((chargers[0] as Transform3D).origin))
			< 4.0)
	_check(no_smoking, "F4: NO SMOKING signed at the charging area")


func _check_mirrors() -> void:
	var mirrors := _placed("Mirrors")
	var size: float = _kit.get("MIRROR_DIAMETER")
	var racking := _shed.get_node("Building/Racking")
	var middles: Array = racking.call("aisle_middles", racking.call("frame_lines"))
	var rack_end: float = _kit.get("RACK_END")
	var covered := mirrors.size() == middles.size() and size >= MIRROR_SIZE.x \
		and size <= MIRROR_SIZE.y
	for middle: float in middles:
		var seen := false
		for mirror: Transform3D in mirrors:
			var facing := mirror.basis.z.normalized()
			var up := mirror.origin.y - DOCK_FLOOR
			seen = seen or (absf(mirror.origin.z - rack_end) < 0.6 and absf(mirror.origin.x - middle)
				< 3.0 and facing.z > 0.3 and up >= MIRROR_UP.x and up <= MIRROR_UP.y)
		covered = covered and seen
	_check(covered, "F5: a convex mirror %.2f m across at each of the %d aisles' mouths, facing "
		% [size, middles.size()] + "the cross-aisle, 2-3 m up")


func _check_the_rest() -> void:
	var aid := _placed("FirstAid")
	_check(aid.size() == 1 and _flat((aid[0] as Transform3D).origin).distance_to(SIDE_DOOR)
		<= FIRST_AID_NEAR, "F6: the first-aid cabinet within 5 m of the side door")
	var bars := _placed("CrossingBars")
	var on_walkway := bars.size() >= 4
	for bar: Transform3D in bars:
		on_walkway = on_walkway and bar.origin.x > WALKWAY.x and bar.origin.x < WALKWAY.y \
			and bar.origin.z > CROSS_AISLE.x and bar.origin.z < CROSS_AISLE.y
	_check(on_walkway, "F6: the walkway's crossing over the cross-aisle (%d bars)" % bars.size())
	var kinds := {}
	for sign_item: Dictionary in _kit.call("signs"):
		kinds[sign_item["kind"]] = true
	_check(kinds.has("speed") and kinds.has("forklifts") and kinds.has("first_aid")
		and kinds.has("eyewash"), "F6: the speed limit, forklift traffic, first-aid and eyewash "
		+ "signs (%s)" % [kinds.keys()])
	var free := true
	for rect: Rect2 in _kit.call("solids"):
		for load in LOADS:
			free = free and not rect.intersects(Rect2(load - LOAD_SIZE / 2.0, LOAD_SIZE))
		free = free and not rect.intersects(Rect2(-82.0, CROSS_AISLE.x, 37.24, CROSS_AISLE.y
			- CROSS_AISLE.x).grow(-0.01)) and not rect.intersects(STAIR.grow(0.5))
	_check(free, "F6: nothing solid of the kit on the cross-aisle, the stair or a load")


## The floor: the dock floor and the strip west of it, the lane and the stair, less the racks, the
## loads, the office, the desk, the parked forklift and the kit's solids.
func _make_grid() -> void:
	_grid = Vector2i(ceili(49.5 / CELL), ceili(29.5 / CELL))
	_walk = PackedByteArray()
	_walk.resize(_grid.x * _grid.y)
	var blocked: Array[Rect2] = [DESK, FORKLIFT]
	for load in LOADS:
		blocked.append(Rect2(load - LOAD_SIZE / 2.0, LOAD_SIZE))
	var racking := _shed.get_node("Building/Racking")
	var z0: float = -9.399 - 0.0762
	var z1: float = 8.21
	for row: Vector2 in racking.call("rows", racking.call("frame_lines")):
		blocked.append(Rect2(row.x - 0.08, z0, row.y - row.x + 0.16, z1 - z0))
	for rect: Rect2 in _kit.call("solids"):
		blocked.append(rect)
	for j in range(_grid.y):
		for i in range(_grid.x):
			var at := _centre(i, j)
			var kind := 0
			if DOCK.has_point(at) or STRIP.has_point(at):
				kind = 1
			if LANE.has_point(at):
				kind = 3 if STAIR.has_point(at) else 2
			if OFFICE.has_point(at):
				kind = 0
			for rect in blocked:
				if rect.has_point(at):
					kind = 0
			_walk[j * _grid.x + i] = kind


func _centre(i: int, j: int) -> Vector2:
	return Vector2(-89.75 + (i + 0.5) * CELL, -9.75 + (j + 0.5) * CELL)


## Whether one may step from cell a to its neighbour b: the dock floor meets the stair only at its
## landing, the stair the lane only at its foot.
func _joined(a: int, b: int, at_a: Vector2, at_b: Vector2) -> bool:
	if a == 0 or b == 0:
		return false
	if a == b:
		return true
	var pair := Vector2i(mini(a, b), maxi(a, b))
	if pair == Vector2i(1, 3):
		return at_a.y < LANDING_END and at_b.y < LANDING_END
	if pair == Vector2i(2, 3):
		return at_a.y > STAIR.end.y - CELL and at_b.y > STAIR.end.y - CELL
	return false


## The farthest any walkable cell lies from the nearest of `sources`, walking (8 neighbours).
func _farthest(sources: Array[Vector2]) -> float:
	var count := _grid.x * _grid.y
	var far := PackedFloat32Array()
	far.resize(count)
	far.fill(INF)
	for source in sources:
		var best := -1
		var best_reach := INF
		for index in range(count):
			if _walk[index] == 0:
				continue
			var reach := _centre(index % _grid.x, index / _grid.x).distance_to(source)
			if reach < best_reach:
				best_reach = reach
				best = index
		if best >= 0:
			far[best] = minf(far[best], best_reach)
	var steps: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 1),
		Vector3i(-1, 1, 1)]
	var changed := true
	var sweeps := 0
	while changed and sweeps < 200:
		changed = false
		sweeps += 1
		for pass_index in range(2):
			for n in range(count):
				var index := n if pass_index == 0 else count - 1 - n
				if _walk[index] == 0:
					continue
				var i := index % _grid.x
				var j := index / _grid.x
				for step in steps:
					var sign_of := -1 if pass_index == 0 else 1
					var ni := i + step.x * sign_of
					var nj := j + step.y * sign_of
					if ni < 0 or nj < 0 or ni >= _grid.x or nj >= _grid.y:
						continue
					var other := nj * _grid.x + ni
					if not _joined(_walk[index], _walk[other], _centre(i, j), _centre(ni, nj)):
						continue
					var cost := CELL * (1.4142 if step.z == 1 else 1.0)
					if far[other] + cost < far[index] - 0.0001:
						far[index] = far[other] + cost
						changed = true
	var worst := 0.0
	for index in range(count):
		if _walk[index] != 0:
			worst = maxf(worst, far[index])
	return worst


## Where one stands at a wall-mounted part: 0.6 m out in front of it (its -z).
func _before(part: Transform3D) -> Vector2:
	return _flat(part.origin + part.basis * Vector3(0.0, 0.0, -0.6))


func _clear_line(from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) / 0.25)
	for index in range(1, steps):
		var at := from.lerp(to, float(index) / steps)
		var i := int((at.x + 89.75) / CELL)
		var j := int((at.y + 9.75) / CELL)
		if i < 0 or j < 0 or i >= _grid.x or j >= _grid.y or _walk[j * _grid.x + i] == 0:
			_blocked_at = " blocked at %s" % at.snapped(Vector2.ONE * 0.01)
			return false
	return true


func _placed(label: String) -> Array:
	return _kit.call("placements", label)


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The kit's checks finish within 180 s")
	_finish()


func _finish() -> void:
	print("SHED KIT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
