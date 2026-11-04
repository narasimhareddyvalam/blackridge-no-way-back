extends SceneTree

const GhatRoad = preload("res://features/environments/industrial_loop/ghat_road.gd")
const Dressing = preload("res://features/environments/industrial_loop/ghat_dressing.gd")
const WipeMap = preload("res://features/vehicles/freight_van/windshield_wipe_map.gd")
const Van = preload("res://features/vehicles/freight_van/freight_van.gd")
const LaneKeeper = preload("res://tests/lane_keeper.gd")

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _world: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _trial: Node
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	await _start_game()
	_check_layout()
	_check_surfaces()
	_check_dressing()
	_check_mission()
	_check_wipers()
	await _check_start()
	await _check_climb()
	await _check_back_onto_road()
	_finish()


func _start_game() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-ghat-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_world = _app.get_node("IndustrialLoop")
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_trial = _app.get_node("DrivingTrial")
	await process_frame
	_app.call("_resume")
	await _wait_physics(30)


func _check_layout() -> void:
	var road: RefCounted = _world.get("road")
	var points: PackedVector3Array = road.points
	var steepest := 0.0
	var steepest_hairpin := 0.0
	var summit := 0.0
	var hairpins := 0
	var narrowest_hairpin := INF
	for index in range(points.size()):
		var grade := absf(road.grade_at(index))
		steepest = maxf(steepest, grade)
		summit = maxf(summit, points[index].y)
		if road.is_hairpin(index):
			steepest_hairpin = maxf(steepest_hairpin, grade)
			narrowest_hairpin = minf(narrowest_hairpin, road.half_widths[index])
			if not road.is_hairpin(index - 1):
				hairpins += 1
	_check(road.length > 2800.0 and road.length < 3300.0,
		"One lap is about 3 km (%.0f m)" % road.length)
	_check(summit > 60.0, "The road climbs a real hill (%.1f m)" % summit)
	_check(hairpins == 8, "Four hairpins up and four down (%d)" % hairpins)
	_check(steepest <= 0.10, "No stretch is steeper than 10%% (%.1f%%)" % (steepest * 100.0))
	_check(steepest_hairpin < steepest and steepest_hairpin <= 0.07,
		"Hairpins are flatter than the legs (%.1f%%)" % (steepest_hairpin * 100.0))
	_check(narrowest_hairpin >= 3.0,
		"Hairpins are widened to at least 6 m of asphalt (%.2f m)" % (narrowest_hairpin * 2.0))
	_check(points[0].distance_to(points[points.size() - 1]) < GhatRoad.SPACING * 1.5,
		"The road closes into one loop")
	var area: Rect2 = _world.get("playable_area")
	var inside := true
	for point in points:
		inside = inside and area.grow(-25.0).has_point(Vector2(point.x, point.z))
	_check(inside, "The whole road lies at least 25 m inside the playable area")
	var map: Control = _presentation.navigation
	var drawn: PackedVector2Array = map.get("drawn_road")
	var tracked: Vector3 = points[int(map.get("route_index"))]
	var off_road := Vector2(tracked.x - _van.global_position.x,
		tracked.z - _van.global_position.z).length()
	_check(drawn.size() > 20 and off_road < 40.0,
		"The map screen draws the real road around the van, heading-up (%d points on the map, "
		% drawn.size() + "tracked %.0f m from the van)" % off_road)


func _check_surfaces() -> void:
	var road: RefCounted = _world.get("road")
	var terrain: Node3D = _world.get("terrain")
	var points: PackedVector3Array = road.points
	var highest := -INF
	var surface_error := 0.0
	var missing_barriers := 0
	var barrier_spots := 0
	var landslide := _nearest(points, _world.LANDSLIDE_AT)
	var space := _world.get_world_3d().direct_space_state
	for index in range(points.size()):
		var right := _right(points, index)
		var reach: float = road.half_widths[index] + GhatRoad.VERGE
		for lateral in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			var at: Vector3 = points[index] + right * lateral * reach
			highest = maxf(highest, terrain.height_at(at.x, at.z) - points[index].y)
		if index % 20 == 0:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				points[index] + Vector3.UP * 3.0, points[index] + Vector3.DOWN * 3.0, 1,
				[_van.get_rid()]))
			surface_error = maxf(surface_error, INF if hit.is_empty()
				else absf(hit.position.y - points[index].y))
		if index % 5 != 0 or absi(index - landslide) < Dressing.LANDSLIDE_LENGTH * 3:
			continue
		var ahead := points[(index + 1) % points.size()] - points[index]
		var outward := Vector3(ahead.x, 0.0, ahead.z).normalized().cross(Vector3.UP)
		var depth := PackedFloat32Array()
		for side: float in [-1.0, 1.0]:
			var probe: Vector3 = points[index] + outward * side * (reach - Dressing.RAIL_INSET
				+ Dressing.DROP_PROBE)
			depth.append(points[index].y - terrain.height_at(probe.x, probe.z))
		for side_index in range(2):
			var side := -1.0 if side_index == 0 else 1.0
			var other := depth[1 - side_index]
			if depth[side_index] < Dressing.DROP or (other >= Dressing.DROP
					and other > depth[side_index] and other < Dressing.DEEP_DROP):
				continue
			barrier_spots += 1
			var from: Vector3 = points[index] + Vector3.UP * 0.4
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from,
				from + outward * side * (reach + 0.5), 1, [_van.get_rid()]))
			if hit.is_empty():
				missing_barriers += 1
	_check(highest < 0.0, "The hillside never pokes through the road (worst %.3f m)" % highest)
	_check(surface_error < 0.05,
		"The van drives on the road's own surface (worst %.3f m)" % surface_error)
	_check(barrier_spots > 40 and missing_barriers == 0,
		"A barrier stands at every drop beside the road (%d spots, %d missing)" % [
		barrier_spots, missing_barriers])


func _check_dressing() -> void:
	var dressing: Node3D = _world.get("dressing")
	_check(dressing.get("guardrail_segments") > 100 and dressing.get("wall_segments") > 50,
		"Guardrails and stone walls line the drops (%d and %d pieces)" % [
		dressing.get("guardrail_segments"), dressing.get("wall_segments")])
	var road: RefCounted = _world.get("road")
	var hairpins := 0
	var warned := 0
	var chevroned := 0
	for index in range(1, road.points.size()):
		if not road.is_hairpin(index) or road.is_hairpin(index - 1):
			continue
		hairpins += 1
		var warnings := 0
		var chevrons := 0
		for sign: Dictionary in dressing.get("signs"):
			var gap: int = posmod(index - int(sign["index"]), road.points.size())
			if String(sign["kind"]).begins_with("hairpin") and gap > 0 and gap < 60:
				warnings += 1
			var ahead: int = posmod(int(sign["index"]) - index, road.points.size())
			if String(sign["kind"]).begins_with("chevron") and ahead < 40:
				chevrons += 1
		warned += 1 if warnings > 0 else 0
		chevroned += 1 if chevrons >= 3 else 0
	_check(warned == hairpins and chevroned == hairpins,
		"Every hairpin has a warning sign before it and chevrons round it (%d of %d, %d of %d)"
		% [warned, hairpins, chevroned, hairpins])
	_check(dressing.get("mirror_count") == 2, "Convex mirrors stand at the two tightest hairpins")
	var points: PackedVector3Array = road.points
	var slide := _nearest(points, _world.LANDSLIDE_AT)
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 1.2, 2.0)
	query.shape = box
	query.transform = Transform3D(Basis(Vector3.UP, road.heading_at(slide)),
		points[slide] + Vector3.UP * 0.8)
	query.exclude = [_van.get_rid()]
	var blocked := _world.get_world_3d().direct_space_state.intersect_shape(query, 4)
	_check(not blocked.is_empty(), "The landslide blocks the valley road")
	var depot: Vector3 = _trial.TARGETS[4]
	var start: Vector3 = _trial.START.origin
	_check(start.distance_to(depot) > 400.0,
		"The drive starts far from the depot (%.0f m)" % start.distance_to(depot))


func _check_wipers() -> void:
	_check(absf(Van.WIPER_PARK + PI / 2) < deg_to_rad(5.0) and Van.WIPER_SWEEP > deg_to_rad(90.0),
		"Wipers park flat along the glass and sweep %.0f degrees" % rad_to_deg(Van.WIPER_SWEEP))
	var wipers: Array = _presentation.get("_wipers")
	var overlays: Array = _presentation.get("fog_overlays")
	var pane: Node3D = (overlays[0] as Node3D).get_parent()
	var same := wipers.size() == WipeMap.PIVOTS.size()
	for index in range(mini(wipers.size(), WipeMap.PIVOTS.size())):
		var pivot := pane.to_local((wipers[index] as Node3D).global_position)
		same = same and Vector2(pivot.x, pivot.y).distance_to(WipeMap.PIVOTS[index]) < 0.002
	_check(same, "The wiped area on the glass follows the real wiper pivots")


func _nearest(points: PackedVector3Array, at: Vector2) -> int:
	var best := 0
	for index in range(points.size()):
		if Vector2(points[index].x, points[index].z).distance_squared_to(at) \
				< Vector2(points[best].x, points[best].z).distance_squared_to(at):
			best = index
	return best


func _beyond_asphalt(road: RefCounted, at: Vector2) -> float:
	var points: PackedVector3Array = road.points
	var nearest := _nearest(points, at)
	var best := INF
	for index: int in [nearest - 1, nearest]:
		var a := points[posmod(index, points.size())]
		var b := points[posmod(index + 1, points.size())]
		var foot := Geometry2D.get_closest_point_to_segment(at, Vector2(a.x, a.z),
			Vector2(b.x, b.z))
		best = minf(best, at.distance_to(foot) - road.half_widths[posmod(index, points.size())])
	return best


func _check_mission() -> void:
	var road: RefCounted = _world.get("road")
	var points: PackedVector3Array = road.points
	for stage in range(4):
		var target: Vector3 = _trial.TARGETS[stage]
		var nearest := 0
		for index in range(points.size()):
			if Vector2(points[index].x, points[index].z).distance_to(Vector2(target.x, target.z)) \
					< Vector2(points[nearest].x, points[nearest].z).distance_to(
					Vector2(target.x, target.z)):
				nearest = index
		var flat := Vector2(points[nearest].x, points[nearest].z)
		_check(flat.distance_to(Vector2(target.x, target.z)) < 1.5
			and absf(points[nearest].y - target.y) < 0.3
			and absf(angle_difference(road.heading_at(nearest), _trial.HEADINGS[stage])) < 0.15,
			"Checkpoint %d sits on the road, facing along it" % stage)
	var terrain: Node3D = _world.get("terrain")
	var depot: Vector3 = _trial.TARGETS[4]
	_check(absf(terrain.height_at(depot.x, depot.z)) < 0.01, "The depot yard stays flat")
	var yard: MeshInstance3D = _world.get_node("DepotYard")
	var arrays := yard.mesh.surface_get_arrays(0)
	var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var spots := corners.duplicate()
	for first in range(0, order.size(), 3):
		spots.append((corners[order[first]] + corners[order[first + 1]]
			+ corners[order[first + 2]]) / 3.0)
	var closest := INF
	for spot in spots:
		var at := yard.to_global(spot)
		closest = minf(closest, _beyond_asphalt(road, Vector2(at.x, at.z)))
	_check(closest > -0.02,
		"The depot yard stops at the road's edge (closest %.2f m beyond it)" % closest)
	var boards := 0
	var green := 0
	for found in _world.find_children("*", "MeshInstance3D", true, false):
		var board := found as MeshInstance3D
		var box := board.mesh as BoxMesh
		if box == null or not box.size.is_equal_approx(Vector3(6.6, 1.5, 0.12)):
			continue
		boards += 1
		var paint := (board.material_override as BaseMaterial3D).albedo_color
		if paint.g > paint.r * 2.0 and paint.g > paint.b * 1.3:
			green += 1
	_check(boards == 4 and green == boards,
		"The guide signs are highway green (%d of %d boards)" % [green, boards])


func _check_start() -> void:
	var road: RefCounted = _world.get("road")
	var points: PackedVector3Array = road.points
	var index := _nearest_around(points, _van.global_position, 0)
	var heading: float = road.heading_at(index)
	var right := Basis(Vector3.UP, heading).x
	var edge: float = (road.half_widths as PackedFloat32Array)[index] + GhatRoad.VERGE
	var off_road := (_van.global_position - points[index]).dot(right)
	_check(_van.is_on_floor() and absf(_presentation.rotation.x) < deg_to_rad(0.5)
		and off_road > edge,
		"The van starts level, parked on the forecourt beside the road, out of the lane (%.1f m "
		% off_road + "from the road's centre)")
	var keeper := LaneKeeper.new(road, index)
	var time := 0.0
	var lateral := off_road
	Input.action_press("accelerate", 0.5)
	while time < 8.0:
		keeper.steer(_van, 1.0)
		await physics_frame
		time += 1.0 / 60.0
		index = _nearest_around(points, _van.global_position, index)
		lateral = (_van.global_position - points[index]).dot(Basis(Vector3.UP,
			road.heading_at(index)).x)
		if absf(lateral - 1.0) < 0.6 and float(_van.get("speed")) > 2.0 and time > 2.0:
			break
	Input.action_release("accelerate")
	keeper.release()
	_check(absf(lateral - 1.0) < 0.6,
		"From the forecourt the van pulls out into the road's lane (%.1f m from the centre after "
		% lateral + "%.1f s)" % time)


func _check_climb() -> void:
	var road: RefCounted = _world.get("road")
	var points: PackedVector3Array = road.points
	var steepest := -1
	for index in range(3, points.size() - 3):
		if road.sections[index - 3] == GhatRoad.Section.CLIMB \
				and road.sections[index + 3] == GhatRoad.Section.CLIMB \
				and (steepest < 0 or road.grade_at(index) > road.grade_at(steepest)):
			steepest = index
	var grade: float = road.grade_at(steepest)
	var pose := Transform3D(Basis(Vector3.UP, road.heading_at(steepest)),
		points[steepest] + Vector3.UP * 0.35)
	_van.recover(pose)
	await _wait_physics(90)
	_check(_van.get("speed") < -0.3,
		"With no brake the van rolls back down a %.1f%% grade" % (grade * 100.0))
	_van.recover(pose)
	Input.action_press("brake")
	await _wait_physics(60)
	var held := _van.global_position
	await _wait_physics(60)
	_check(_van.global_position.distance_to(held) < 0.05 and absf(_van.get("speed")) < 0.05,
		"The brake holds the van on the hill")
	_check(absf(_presentation.rotation.x - atan(grade)) < deg_to_rad(1.5),
		"The van's body pitches with the road (%.1f degrees on a %.1f degree grade)" % [
		rad_to_deg(_presentation.rotation.x), rad_to_deg(atan(grade))])
	Input.action_release("brake")
	var start := _van.global_position
	Input.action_press("accelerate")
	await _wait_physics(180)
	Input.action_release("accelerate")
	_check(_van.get("speed") > 3.0 and _van.global_position.y - start.y > 0.5,
		"From a stop the van climbs the steepest leg (%.1f m/s, %.1f m higher)" % [
		_van.get("speed"), _van.global_position.y - start.y])


func _check_back_onto_road() -> void:
	var road: RefCounted = _world.get("road")
	var points: PackedVector3Array = road.points
	var index := 40
	var heading: float = road.heading_at(index)
	var right := Basis(Vector3.UP, heading).x
	var half: float = (road.half_widths as PackedFloat32Array)[index]
	var results: Array[String] = []
	var all_back := true
	for side: float in [1.0, -1.0]:
		var start := points[index] + right * side * (half + GhatRoad.VERGE + 2.5)
		_van.recover(Transform3D(Basis(Vector3.UP, heading), _ground(start) + Vector3.UP * 0.1))
		_van.set("foot_on_brake", false)
		await _wait_physics(30)
		var steer := "steer_left" if side > 0.0 else "steer_right"
		var time := 0.0
		var lateral := INF
		Input.action_press("accelerate", 0.6)
		while time < 8.0:
			var near := _nearest_around(points, _van.global_position, index)
			lateral = (_van.global_position - points[near]).dot(right)
			if absf(lateral) < half:
				break
			var facing := absf(angle_difference(_van.global_rotation.y, heading))
			if absf(lateral) > 1.0 and facing < 0.5:
				Input.action_press(steer, 0.8)
			else:
				Input.action_release(steer)
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		var back := absf(lateral) < half
		all_back = all_back and back
		results.append("%s side %s after %.1f s" % ["right" if side > 0.0 else "left",
			"back on the asphalt" if back else "still off it", time])
	_check(all_back, "From the ground beside the road, the van drives back onto it on either side "
		+ "(%s)" % ", ".join(results))


func _nearest_around(points: PackedVector3Array, at: Vector3, around: int) -> int:
	var best := around
	for index in range(maxi(around - 30, 0), mini(around + 30, points.size())):
		if at.distance_squared_to(points[index]) < at.distance_squared_to(points[best]):
			best = index
	return best


func _ground(at: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 30.0,
		at + Vector3.DOWN * 30.0, 1, [_van.get_rid()])
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else at


func _right(points: PackedVector3Array, index: int) -> Vector3:
	var along := points[(index + 1) % points.size()] - points[(index - 1 + points.size())
		% points.size()]
	return Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)


func _wait_physics(count: int) -> void:
	for step in range(count):
		await physics_frame


func _finish() -> void:
	print("GHAT ROAD RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Ghat road test finished within 120 s of game time")
	quit(1)
