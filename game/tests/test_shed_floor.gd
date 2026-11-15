extends SceneTree
## Part D of step 5 of #253 (docs/PHASE_BRIEF.md, "the depot dressed, the rest"): the transfer
## shed's floor as a working dock's, read from the shed as the running game builds it on Mission
## 2's start save. The floor is drawn in its own material over a map its script paints (#294), so
## the marks are read from what the floor hands out (`marks()`, `joints()`): sawn joints at ACI's
## spacing, epoxy patches only on joints, tyre marks only on the forklift's ways, oil only under the
## parked forklift, scuffs only by the levellers and the lift, water only near an open door and
## drying inward, nothing under a load, the desk or the stair; the slab's height and collision
## unchanged; the same map every build. A headless run draws nothing, so the look is not checked.

const SHED_FLOOR := "res://features/environments/industrial_loop/shed_floor.gd"
const Racking = preload("res://features/environments/industrial_loop/racking.gd")
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCK_FLOOR := 1.3
const LANE_TOP := 0.02
## The dock floor's slab (`transfer_building.gd`, office's end to the drive-in lane) and the lane's.
const DOCK := Rect2(-82.0, -9.75, 37.3, 29.5)
const LANE := Rect2(-44.7, -9.75, 4.45, 29.5)
const PIT := Rect2(-48.685, 17.29, 1.87, 2.46)
## ACI 302.1R / 360R: joints 24-36 times a 6 in slab's thickness apart, panels at most 1.5:1.
const JOINT_LEAST := 3.7
const JOINT_MOST := 5.5
const PANEL_MOST := 1.5
const PATCH_ON_JOINT := 0.1
const CROSS_AISLE := Vector2(10.0, 14.0)
const WALKWAY := Rect2(-46.6, -9.75, 1.2, 19.75)
const LOAD_SIZE := Vector2(1.016, 1.219)
const LOADS: Array[Vector2] = [Vector2(-64.55, 16.45), Vector2(-63.45, 16.45),
	Vector2(-64.55, 15.15), Vector2(-63.45, 15.15), Vector2(-52.0, 16.6), Vector2(-47.2, 16.6),
	Vector2(-49.9, 18.95)]
const DESK := Rect2(-45.8, 17.5, 1.0, 2.1)
const CHAIR := Rect2(-46.5, 18.1, 0.7, 0.9)
const STAIR := Rect2(-44.7, 12.92, 1.0, 2.25)
const FORKLIFT_SIZE := Vector2(1.12, 3.3)
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0]
const FACE := 19.75
const LEVELLER := Vector2(2.0, 1.22)
const SCUFF_REACH := 1.5
## The open doors, as segments across their openings: dock 5, bay 9 (the lift's passage) and the
## side door in the east wall.
const DOORS: Array[Array] = [[Vector2(-65.37, 19.75), Vector2(-62.63, 19.75)],
	[Vector2(-48.685, 19.75), Vector2(-46.815, 19.75)], [Vector2(-40.0, 17.0), Vector2(-40.0, 17.95)]]
const WET_REACH := 6.0
const WET_BANDS: Array[float] = [2.0, 4.0, 6.0]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _shed: Node3D
var _floor: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-shed-floor-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_floor = _shed.get_node_or_null("Building/ShedFloor") if _shed != null else null
	_check(_floor != null and _floor.has_method("marks") and _floor.has_method("joints"),
		"F0: the shed has its floor (Building/ShedFloor) handing out its marks and joints")
	if _floor != null and _floor.has_method("marks"):
		_check_slab()
		_check_joints()
		_check_tyres()
		_check_oil()
		_check_scuffs()
		_check_wet()
		_check_clear()
		_check_same()
	_finish()


func _check_slab() -> void:
	var material: Material = _floor.get("material")
	var pieces := _shed.find_children("DockFloor*", "MeshInstance3D", true, false)
	pieces.append_array(_shed.find_children("LaneFloor*", "MeshInstance3D", true, false))
	var drawn := material is ShaderMaterial and pieces.size() == 4
	for found in pieces:
		drawn = drawn and (found as MeshInstance3D).get_active_material(0) == material
	_check(drawn, "F1: the dock floor's three pieces round the pit and the lane are drawn in "
		+ "the floor's own material (%d pieces)" % pieces.size())
	var body := _shed.get_node_or_null("Building/ShedBody") as StaticBody3D
	var tops := {}
	if body != null:
		for child in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or not (shape.shape is BoxShape3D):
				continue
			var size := (shape.shape as BoxShape3D).size
			var top := snappedf(shape.position.y + size.y / 2.0, 0.001)
			var at := Vector2(shape.position.x, shape.position.z)
			if DOCK.grow(0.01).has_point(at) and absf(top - DOCK_FLOOR) < 0.001 and size.y > 1.0:
				tops["dock"] = tops.get("dock", 0.0) + size.x * size.z
			elif LANE.grow(0.3).has_point(at) and absf(top - LANE_TOP) < 0.001:
				tops["lane"] = tops.get("lane", 0.0) + size.x * size.z
	var dock_area := DOCK.get_area() - PIT.get_area()
	_check(absf(tops.get("dock", 0.0) - dock_area) < 0.5 and tops.get("lane", 0.0) > 120.0,
		"F1: the slab stays solid at 1.3 m over the dock floor (%.1f of %.1f m²) and the lane at "
		% [tops.get("dock", 0.0), dock_area] + "0.02 m (%.1f m²)" % tops.get("lane", 0.0))


func _check_joints() -> void:
	var joints: Array = _floor.call("joints")
	var xs: Array[float] = []
	var zs: Array[float] = []
	var lane_zs: Array[float] = []
	var inside := not joints.is_empty()
	var crosses_pit := false
	for joint: Dictionary in joints:
		var from: Vector2 = joint["from"]
		var to: Vector2 = joint["to"]
		var on_dock := DOCK.grow(0.01).has_point(from) and DOCK.grow(0.01).has_point(to)
		var on_lane := LANE.grow(0.01).has_point(from) and LANE.grow(0.01).has_point(to)
		inside = inside and (on_dock or on_lane)
		var box := Rect2(from, Vector2.ZERO).expand(to).grow(0.003)
		crosses_pit = crosses_pit or box.intersects(PIT)
		if is_equal_approx(from.x, to.x):
			xs.append(from.x)
		elif on_lane:
			lane_zs.append(from.y)
		else:
			zs.append(from.y)
	_check(inside and not crosses_pit, "F2: %d joints, every one on the dock floor or the lane, "
		% joints.size() + "none across the lift's pit")
	var across := _gaps(xs, DOCK.position.x, DOCK.end.x)
	var along := _gaps(zs, DOCK.position.y, DOCK.end.y)
	var lane_along := _gaps(lane_zs, LANE.position.y, LANE.end.y)
	var spaced := not across.is_empty() and not along.is_empty() and not lane_along.is_empty()
	for gap in across + along + lane_along + [LANE.size.x]:
		spaced = spaced and gap >= JOINT_LEAST - 0.001 and gap <= JOINT_MOST + 0.001
	_check(spaced, "F2: joints %.1f-%.1f m apart both ways (across %s, along %s, the lane %s)"
		% [JOINT_LEAST, JOINT_MOST, _list(across), _list(along), _list(lane_along)])
	var worst := 0.0
	for a in across:
		for b in along:
			worst = maxf(worst, maxf(a, b) / minf(a, b))
	for b in lane_along:
		worst = maxf(worst, maxf(LANE.size.x, b) / minf(LANE.size.x, b))
	_check(worst > 0.0 and worst <= PANEL_MOST, "F2: every panel at most %.1f:1 (worst %.2f)"
		% [PANEL_MOST, worst])
	var material := _floor.get("material") as ShaderMaterial
	var drawn_xs = material.get_shader_parameter("joint_x") if material != null else []
	var drawn_zs = material.get_shader_parameter("joint_z") if material != null else []
	var matches := material != null and int(material.get_shader_parameter("joint_x_count")) \
		== xs.size() and int(material.get_shader_parameter("joint_z_count")) == zs.size()
	xs.sort()
	zs.sort()
	for index in range(xs.size()):
		matches = matches and index < drawn_xs.size() and absf(drawn_xs[index] - xs[index]) < 0.001
	for index in range(zs.size()):
		matches = matches and index < drawn_zs.size() and absf(drawn_zs[index] - zs[index]) < 0.001
	_check(matches, "F2: the material draws the joints the floor hands out")
	var patches := _of("patch")
	var on_joint := not patches.is_empty()
	for mark: Dictionary in patches:
		var centre: Vector2 = mark["centre"]
		var near := INF
		for joint: Dictionary in joints:
			near = minf(near, _to_segment(centre, joint["from"], joint["to"]))
		on_joint = on_joint and near <= PATCH_ON_JOINT
	_check(on_joint, "F2: %d epoxy patches, each on a joint (within %.2f m)" % [patches.size(),
		PATCH_ON_JOINT])


func _check_tyres() -> void:
	var marks := _of("tyre")
	var aisles := _aisles()
	var seen := {}
	var kept := not marks.is_empty()
	var strays: Array[String] = []
	for mark: Dictionary in marks:
		var centre: Vector2 = mark["centre"]
		var radius: float = mark["radius"]
		var way := -1
		if centre.y >= CROSS_AISLE.x and centre.y <= CROSS_AISLE.y and DOCK.has_point(centre):
			way = 0
		for index in range(aisles.size()):
			if aisles[index].has_point(centre):
				way = index + 1
		var touches := _disk_in(centre, radius, WALKWAY) or _disk_in(centre, radius,
			Rect2(-82.0, CROSS_AISLE.y, 37.3, 6.0))
		for row in _rows():
			touches = touches or _disk_in(centre, radius, row)
		if way < 0 or touches:
			kept = false
			if strays.size() < 3:
				strays.append(str(centre.snapped(Vector2.ONE * 0.01)))
		else:
			seen[way] = true
	_check(kept, "F3: %d tyre marks, all on the forklift's ways, none on the walkway, the "
		% marks.size() + "staging lanes or a rack row %s" % (str(strays) if not strays.is_empty() else ""))
	_check(seen.size() == aisles.size() + 1, "F3: tyre marks along the cross-aisle and down each "
		+ "of the %d aisles (%d ways marked)" % [aisles.size(), seen.size()])


func _check_oil() -> void:
	var forklift := _shed.get_node_or_null("Building/Forklift") as Node3D
	var marks := _of("oil")
	var under := forklift != null and not marks.is_empty()
	for mark: Dictionary in marks:
		var centre: Vector2 = mark["centre"]
		var local := forklift.global_basis.inverse() * (Vector3(centre.x, 0.0, centre.y)
			- forklift.global_position) if forklift != null else Vector3.INF
		var radius: float = mark["radius"]
		under = under and absf(local.x) + radius <= FORKLIFT_SIZE.x / 2.0 \
			and absf(local.z) + radius <= FORKLIFT_SIZE.y / 2.0
	_check(under, "F4: %d oil drips, all under the parked forklift" % marks.size())


func _check_scuffs() -> void:
	var marks := _of("scuff")
	var zones: Array[Rect2] = [PIT]
	for x in DOCKS:
		zones.append(Rect2(x - LEVELLER.x / 2.0, FACE - LEVELLER.y, LEVELLER.x, LEVELLER.y))
	var counts: Array[int] = []
	counts.resize(zones.size())
	var near := not marks.is_empty()
	for mark: Dictionary in marks:
		var centre: Vector2 = mark["centre"]
		var best := -1
		for index in range(zones.size()):
			if _to_rect(centre, zones[index]) <= SCUFF_REACH:
				best = index
		near = near and best >= 0 and DOCK.has_point(centre)
		if best >= 0:
			counts[best] += 1
	_check(near, "F5: %d scuffs, each within %.1f m of a leveller or the lift's deck"
		% [marks.size(), SCUFF_REACH])
	_check(counts.min() > 0, "F5: scuffs before every leveller and the lift (fewest %d)"
		% counts.min())


func _check_wet() -> void:
	var marks := _of("wet")
	var near := not marks.is_empty()
	var by_door: Array[int] = [0, 0, 0]
	var sums: Array[float] = [0.0, 0.0, 0.0]
	var counts: Array[int] = [0, 0, 0]
	for mark: Dictionary in marks:
		var centre: Vector2 = mark["centre"]
		var nearest := INF
		var door := -1
		for index in range(DOORS.size()):
			var reach := _to_segment(centre, DOORS[index][0], DOORS[index][1])
			if reach < nearest:
				nearest = reach
				door = index
		near = near and nearest <= WET_REACH
		if nearest <= WET_REACH:
			by_door[door] += 1
			var band := 0 if nearest < WET_BANDS[0] else (1 if nearest < WET_BANDS[1] else 2)
			sums[band] += float(mark["strength"])
			counts[band] += 1
	_check(near and by_door.min() > 0, "F6: %d wet marks, all within %.0f m of an open door, "
		% [marks.size(), WET_REACH] + "at each of them (dock 5, bay 9, side door: %s)" % [by_door])
	var means: Array[float] = []
	for band in range(3):
		means.append(sums[band] / counts[band] if counts[band] > 0 else 0.0)
	_check(counts.min() > 0 and means[0] > means[1] and means[1] > means[2],
		"F6: the floor dries inward: mean wetness 0-2 m %.2f, 2-4 m %.2f, 4-6 m %.2f"
		% [means[0], means[1], means[2]])


func _check_clear() -> void:
	var keep: Array[Rect2] = [DESK, CHAIR, STAIR, PIT]
	for at in LOADS:
		keep.append(Rect2(at - LOAD_SIZE / 2.0, LOAD_SIZE))
	var on_floor := true
	var under := 0
	for mark: Dictionary in _floor.call("marks"):
		var centre: Vector2 = mark["centre"]
		on_floor = on_floor and (DOCK.has_point(centre) or LANE.has_point(centre))
		for rect in keep:
			if rect.has_point(centre):
				under += 1
	_check(on_floor and under == 0, "F8: every mark on the floor, none under a load, the empty "
		+ "pallets, the desk, its chair, the stair or in the lift's pit (%d under)" % under)


func _check_same() -> void:
	if not ResourceLoader.exists(SHED_FLOOR):
		_check(false, "F7: the floor's script exists to paint again")
		return
	var again: Node = (load(SHED_FLOOR) as GDScript).new()
	again.call("paint")
	var maps: Array = _floor.get("maps")
	var maps_again: Array = again.get("maps")
	var same := maps.size() == 4 and maps_again.size() == 4
	var mipmapped := same
	for index in range(mini(maps.size(), maps_again.size())):
		var image := (maps[index] as Texture2D).get_image()
		same = same and image.get_data() == (maps_again[index] as Texture2D).get_image().get_data()
		mipmapped = mipmapped and image.has_mipmaps()
	same = same and str(_floor.call("marks")) == str(again.call("marks"))
	again.free()
	_check(same, "F7: painted again, the floor's four maps and its marks come out the same")
	_check(mipmapped, "F7: each map carries its mipmaps, so the marks do not shimmer far off")


func _of(kind: String) -> Array:
	var found := []
	for mark: Dictionary in _floor.call("marks"):
		if mark["kind"] == kind:
			found.append(mark)
	return found


func _rows() -> Array[Rect2]:
	var found: Array[Rect2] = []
	var z0 := Racking.FIRST_Z - Racking.POST
	var z1 := Racking.FIRST_Z + Racking.BAYS * Racking.BAY
	for row in Racking.rows(Racking.frame_lines()):
		found.append(Rect2(row.x - Racking.OVERHANG, z0, row.y - row.x + Racking.OVERHANG * 2.0,
			z1 - z0))
	return found


func _aisles() -> Array[Rect2]:
	var rows := Racking.rows(Racking.frame_lines())
	var found: Array[Rect2] = []
	for index in range(rows.size()):
		var x0 := rows[index].y + Racking.OVERHANG
		var x1 := rows[index + 1].x - Racking.OVERHANG if index + 1 < rows.size() \
			else WALKWAY.position.x
		found.append(Rect2(x0, DOCK.position.y, x1 - x0, CROSS_AISLE.x - DOCK.position.y))
	return found


func _gaps(lines: Array[float], low: float, high: float) -> Array[float]:
	var points: Array[float] = [low, high]
	points.append_array(lines)
	points.sort()
	var gaps: Array[float] = []
	for index in range(points.size() - 1):
		gaps.append(points[index + 1] - points[index])
	return gaps if not lines.is_empty() else ([] as Array[float])


func _list(values: Array[float]) -> String:
	var parts := PackedStringArray()
	for value in values:
		parts.append("%.2f" % value)
	return "[" + ", ".join(parts) + "]"


func _disk_in(centre: Vector2, radius: float, rect: Rect2) -> bool:
	return _to_rect(centre, rect) < radius


func _to_rect(point: Vector2, rect: Rect2) -> float:
	var dx := maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
	var dz := maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
	return Vector2(dx, dz).length()


func _to_segment(point: Vector2, from: Vector2, to: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, from, to))


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The floor's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("SHED FLOOR RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
