extends SceneTree
## Part B of #267 (docs/PHASE_BRIEF.md, "step 5 brought forward"): the forest highway's roadside,
## read from the running game's ghat dressing: delineators along the valley at the MUTCD's
## spacings, never in a driveway or the shed's spur; a weathered, leaning SPEED LIMIT 45 at the
## loop's start and a clean one after the descent; deer crossings; mile markers at the start and a
## mile on; dry branches on the verge, none into a lane; litter on the verges, none on the
## asphalt; a solid bin at the viewpoint's lay-by; nothing standing in a rail or wall. A headless
## run draws nothing.

const GhatRoad = preload("res://features/environments/industrial_loop/ghat_road.gd")
const FT := 0.3048
const TANGENT := 200 * FT
const MILE := 1609.344
const INTO_LANE := 0.3
const SPUR := Vector3(-71.0, 71.0, 10.5)

var _checks: int = 0
var _failures: int = 0
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	var world := _app.get_node("IndustrialLoop") as Node3D
	var road: RefCounted = world.get("road")
	var dressing: Node3D = world.get("dressing")
	var valley: Array = dressing.get("valley_delineators")
	var points: PackedVector3Array = road.points
	var widths: PackedFloat32Array = road.half_widths
	var gaps: Array[float] = []
	var off_verge := 0
	var in_mouth := 0
	for at: Vector3 in valley:
		var index := _nearest(points, at)
		var out := Vector2(at.x - points[index].x, at.z - points[index].z).length() - widths[index]
		if out < 0.5 or out > 2.0:
			off_verge += 1
		if Vector2(at.x, at.z).distance_to(Vector2(SPUR.x, SPUR.y)) < SPUR.z:
			in_mouth += 1
	var sides := [[], []]
	for at: Vector3 in valley:
		var index := _nearest(points, at)
		var right := (points[(index + 1) % points.size()] - points[index]).cross(Vector3.UP)
		sides[0 if (at - points[index]).dot(right) < 0.0 else 1].append(index)
	var widest := 0.0
	for side: Array in sides:
		side.sort()
		for k in range(side.size() - 1):
			var gap := float(side[k + 1] - side[k]) * GhatRoad.SPACING
			if gap < 40.0 * GhatRoad.SPACING:
				widest = maxf(widest, gap)
	_check(valley.size() > 40 and widest <= TANGENT + GhatRoad.SPACING and off_verge == 0
		and in_mouth == 0, ("K1: delineators stand along the valley too (%d), at most 200 ft "
		+ "apart (%.1f m at the widest), on the verge 0.5-2 m beyond the asphalt (%d not), none "
		+ "in the shed's spur (%d)") % [valley.size(), widest, off_verge, in_mouth])
	var signs: Array = dressing.get("signs")
	var by_kind := {}
	for sign: Dictionary in signs:
		if not by_kind.has(sign["kind"]):
			by_kind[sign["kind"]] = []
		by_kind[sign["kind"]].append(sign)
	var weathered: Array = by_kind.get("limit_45_weathered", [])
	var clean: Array = by_kind.get("limit_45", [])
	var leaning := false
	var face := dressing.get_node_or_null("Sign_limit_45_weathered") as MultiMeshInstance3D
	if face != null:
		var tilt := absf(rad_to_deg(face.multimesh.get_instance_transform(0).basis.y.normalized()
			.angle_to(Vector3.UP))) if face.multimesh.instance_count > 0 else 0.0
		leaning = tilt > 2.0 and tilt < 8.0 or weathered.size() == 1
	_check(weathered.size() == 1 and int(weathered[0]["index"]) < 20 and clean.size() == 1
		and leaning, ("K2: a weathered SPEED LIMIT 45 at the loop's start (%d) and a clean one "
		+ "where the valley begins after the descent (%d)") % [weathered.size(), clean.size()])
	var miles := []
	for kind in ["mile_0", "mile_1"]:
		for sign: Dictionary in by_kind.get(kind, []):
			miles.append(float(sign["index"]) * GhatRoad.SPACING)
	var deer: Array = by_kind.get("deer_crossing", [])
	_check(deer.size() == 2 and miles.size() == 2 and miles[0] < 10.0
		and absf(miles[1] - MILE) <= GhatRoad.SPACING, ("K3: two deer crossings (%d), mile 0 at "
		+ "the start and mile 1 a mile on (%s m along)") % [deer.size(), ", ".join(miles.map(
		func(m: float) -> String: return "%.0f" % m))])
	var space := _app.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var block := BoxShape3D.new()
	query.shape = block
	query.collision_mask = 1
	var barrier_bodies := {}
	for found in dressing.find_children("*", "StaticBody3D", true, false):
		barrier_bodies[found] = true
	var roadside: Array = dressing.get("roadside")
	var branches := 0
	var faults: Array[String] = []
	var litter := 0
	var bin_solid := false
	for item: Dictionary in roadside:
		var node := item["node"] as Node3D
		var box := _box(node)
		var index := int(item["index"])
		var centre := points[index]
		var right := (points[(index + 1) % points.size()] - centre).cross(Vector3.UP).normalized()
		var near_edge := INF
		for corner in _corners(box):
			near_edge = minf(near_edge, absf((corner - centre).dot(right)))
		var into := widths[index] - near_edge
		block.size = (box.size - Vector3(0.04, 0.08, 0.04)).max(Vector3.ONE * 0.01)
		query.transform = Transform3D(Basis.IDENTITY, box.get_center() + Vector3.UP * 0.04)
		var own := node.find_children("*", "StaticBody3D", true, false)
		query.exclude = own.map(func(body: Node) -> RID: return (body as StaticBody3D).get_rid())
		for hit: Dictionary in space.intersect_shape(query, 8):
			if barrier_bodies.has(hit["collider"]):
				faults.append("%s in a rail or wall" % item.get("asset", item["kind"]))
				break
		match String(item["kind"]):
			"branch":
				branches += 1
				if into > INTO_LANE:
					faults.append("a branch %.2f m onto the asphalt" % into)
			"litter":
				litter += 1
				if into > 0.0:
					faults.append("%s %.2f m onto the asphalt" % [item["asset"], into])
			"bin":
				bin_solid = not node.find_children("*", "StaticBody3D", true, false).is_empty()
	_check(branches == 3 and litter >= 5 and bin_solid and faults.is_empty(), ("K4: dry "
		+ "branches on the verge, none more than %.1f m onto the asphalt (%d), litter on the "
		+ "verges and none on the asphalt (%d), a solid bin at the lay-by (%s)%s") % [INTO_LANE,
		branches, litter, bin_solid, "" if faults.is_empty() else ": " + "; ".join(faults)])
	_finish()


func _nearest(points: PackedVector3Array, at: Vector3) -> int:
	var best := 0
	var best_distance := INF
	for index in range(points.size()):
		var distance := Vector2(points[index].x - at.x, points[index].z - at.z).length_squared()
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for found in node.find_children("*", "MeshInstance3D", true, false):
		if found.is_queued_for_deletion():
			continue
		var mesh := found as MeshInstance3D
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _corners(box: AABB) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x: float in [box.position.x, box.end.x]:
		for z: float in [box.position.z, box.end.z]:
			corners.append(Vector3(x, box.position.y, z))
	return corners


func _timeout() -> void:
	_check(false, "The roadside's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("ROADSIDE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
