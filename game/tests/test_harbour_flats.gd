extends SceneTree
## Mission 3's step 2, the east road and the harbour flats (docs/PHASE_BRIEF.md, 2026-11-21, #359):
## the east road leaves the loop at its east end and runs through the rim in a notched cut with
## sloped banks, flat and clear, to the coastal road; the coastal road runs north and south along
## the flats; the flats are solid ground at road level and the sea lies east of the quay, its
## surface below the quay's edge and reaching the horizon; the rim comes down to the flats with no
## gap; the district counts as playable; lamps light both roads; and no tree of the forest west of
## the cut has moved (its fingerprint taken before the cut).

const FROM := Vector3(611.0, 0.0, 151.7)
const JUNCTION := Vector3(726.0, 0.0, 151.7)
const COASTAL: Array[Vector3] = [Vector3(726.0, 0.0, 300.0), Vector3(726.0, 0.0, -270.0)]
const QUAY_EDGE_X := 1000.0
const TREES := 55432
const TREE_SUM := Vector3(51045492.0, 0.0, -1398076.0)
const LAMP_EVERY := 45.0

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _space: PhysicsDirectSpaceState3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(200.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_app)
	await process_frame
	await physics_frame
	await physics_frame
	_space = _app.get_world_3d().direct_space_state
	var world := _app.get_node("IndustrialLoop")
	var flats := world.get("harbour_flats") as Node3D
	if flats == null:
		_check(false, "H1: the world has its harbour flats (none)")
		_finish()
		return
	_check_road([FROM, JUNCTION], "H1: the east road from the loop's east end to the coastal road")
	_check_road(COASTAL, "H2: the coastal road along the flats")
	_check_banks()
	_check_sea(flats)
	_check_rim()
	_check_playable(world)
	_check_lamps(flats)
	_check_trees(world)
	_finish()


## Along `points`: ground under the middle and both lanes every 4 m, its height steady (no step over
## 0.3 m in 4 m, no grade over 8%), and nothing standing on the road up to 4 m.
func _check_road(points: Array[Vector3], what: String) -> void:
	var worst_step := 0.0
	var worst_grade := 0.0
	var holes := 0
	var blocked := 0
	var last := INF
	var length := 0.0
	for leg in range(points.size() - 1):
		var a := points[leg]
		var b := points[leg + 1]
		var steps := int(a.distance_to(b) / 4.0)
		var side := (b - a).normalized().cross(Vector3.UP)
		for step in range(steps + 1):
			var at := a.lerp(b, float(step) / steps)
			for lane in [-2.5, 0.0, 2.5]:
				var hit := _down(at + side * lane)
				if hit.is_empty():
					holes += 1
					continue
				if lane == 0.0:
					var y: float = (hit["position"] as Vector3).y
					if last != INF:
						worst_step = maxf(worst_step, absf(y - last))
						worst_grade = maxf(worst_grade, absf(y - last) / 4.0)
					last = y
			var box := PhysicsShapeQueryParameters3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(5.0, 3.0, 3.0)
			box.shape = shape
			var ground := _down(at)
			var y0: float = (ground["position"] as Vector3).y if not ground.is_empty() else 0.0
			box.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), Vector3(at.x, y0 + 2.0,
				at.z))
			if not _space.intersect_shape(box, 1).is_empty():
				blocked += 1
		length += a.distance_to(b)
	_check(holes == 0 and blocked == 0 and worst_step < 0.3 and worst_grade < 0.08, ("%s: %.0f m, "
		+ "solid under every lane (%d holes), clear (%d blocked), steady (worst step %.2f m, grade "
		+ "%.1f%%)") % [what, length, holes, blocked, worst_step, worst_grade * 100.0])


## H3: the cut's banks slope; no wall: 6 m either side of the east road at x 640 the ground is
## higher than the road but not more than 1.2 m for each metre out.
func _check_banks() -> void:
	var terrain := _app.get_node("IndustrialLoop").get("terrain") as Node3D
	var road_y: float = terrain.call("height_at", 640.0, 151.7)
	var steepest := 0.0
	for out in [-14.0, -10.0, -7.0, 7.0, 10.0, 14.0]:
		var rise: float = float(terrain.call("height_at", 640.0, 151.7 + out)) - road_y
		steepest = maxf(steepest, rise / maxf(absf(out) - 4.5, 0.5))
	_check(steepest < 1.2 and road_y < 0.1, ("H3: the cut through the rim has sloped banks "
		+ "(steepest %.2f m a metre), the road's ground at %.2f m") % [steepest, road_y])


## H4: east of the quay's edge the sea: water below the quay by 1.5-4 m, out to 2 km.
func _check_sea(flats: Node3D) -> void:
	var sea := flats.get("sea") as Node3D
	var quay: float = (_down(Vector3(QUAY_EDGE_X - 3.0, 0.0, 220.0))["position"] as Vector3).y \
		if not _down(Vector3(QUAY_EDGE_X - 3.0, 0.0, 220.0)).is_empty() else INF
	var level: float = sea.global_position.y if sea != null else INF
	var reach: float = float(flats.get("sea_reach")) if sea != null else 0.0
	_check(sea != null and quay - level >= 1.5 and quay - level <= 4.0 and reach >= 2000.0,
		("H4: the sea east of the quay, %.1f m below its edge, reaching %.0f m") % [quay - level,
		reach])


## H5: along the rim's foot, x 660, the ground has no gap from z -300 to 300.
func _check_rim() -> void:
	var gaps := 0
	for z in range(-300, 301, 10):
		for x in [655.0, 662.0, 670.0]:
			if _down(Vector3(x, 0.0, z)).is_empty():
				gaps += 1
	_check(gaps == 0, "H5: the rim comes down to the flats with no gap along x 655-670 (%d gaps)"
		% gaps)


## H6: the flats are playable: a point on the coastal road counts, as does the east road.
func _check_playable(world: Node) -> void:
	var on_flats := bool(world.call("playable", Vector2(726.0, 0.0)))
	var on_cut := bool(world.call("playable", Vector2(650.0, 151.7)))
	var off := bool(world.call("playable", Vector2(1500.0, 0.0)))
	_check(on_flats and on_cut and not off, ("H6: the east road and the flats are playable (%s, %s), "
		+ "the open sea not (%s)") % [on_cut, on_flats, off])


## H7: lamps along both roads, lit, at most LAMP_EVERY apart.
func _check_lamps(flats: Node3D) -> void:
	var lamps: Array = flats.get("lamps")
	var worst := 0.0
	for road: Array in [[FROM, JUNCTION], COASTAL]:
		var a: Vector3 = road[0]
		var b: Vector3 = road[1]
		var along: Array[float] = []
		for lamp: Node3D in lamps:
			var p := lamp.global_position
			var t := (p - a).dot((b - a).normalized())
			var off := ((p - a) - (b - a).normalized() * t)
			off.y = 0.0
			if t >= -10.0 and t <= a.distance_to(b) + 10.0 and off.length() < 10.0:
				along.append(t)
		along.sort()
		along.push_front(0.0)
		along.append(a.distance_to(b))
		for index in range(along.size() - 1):
			worst = maxf(worst, along[index + 1] - along[index])
	var lit := lamps.all(func(lamp: Node3D) -> bool:
		return lamp.find_children("*", "Light3D", true, false).size() > 0)
	_check(not lamps.is_empty() and lit and worst <= LAMP_EVERY, ("H7: %d lamps light both roads, lit "
		+ "(%s), the widest gap %.0f m") % [lamps.size(), lit, worst])


## H8: the forest west of x 600 is as it was before the cut: the same trees in the same places.
func _check_trees(world: Node) -> void:
	var forest := world.get("forest") as Node3D
	var count := 0
	var sum := Vector3.ZERO
	for mmi in forest.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (mmi as MultiMeshInstance3D).multimesh
		for i in range(mm.instance_count):
			var t := (mmi as MultiMeshInstance3D).global_transform * mm.get_instance_transform(i)
			if t.origin.x < 600.0:
				count += 1
				sum += t.origin * (1.0 + float(count % 7))
	for n in forest.find_children("*", "MeshInstance3D", true, false):
		var o := (n as Node3D).global_position
		if o.x < 600.0:
			count += 1
			sum += o * (1.0 + float(count % 7))
	_check(count == TREES and Vector2(sum.x, sum.z).distance_to(Vector2(TREE_SUM.x, TREE_SUM.z))
		< 50.0, "H8: no tree west of the cut has moved (%d trees, %s)" % [count, sum])


func _down(at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 200.0, at.z),
		Vector3(at.x, -20.0, at.z), 1)
	return _space.intersect_ray(query)


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("HARBOUR FLATS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
