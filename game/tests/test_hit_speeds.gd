extends SceneTree

const SPEEDS: Array[float] = [30.0, 45.0, 60.0]
const LANE := 1.0
const RUN_IN := 30
const WATCH_SECONDS := 8.0
const ON_BONNET := 1.15
const ROOF_EDGE := -0.5
const BUMPER := 2.45
const WRONG_WAY := -30.0
const FOLDED := 155.0
const LONGEST_OUT := 3
const KNEE := Vector3(-1.0, 0.0, 0.0)
const LEFT_ELBOW := Vector3(0.33, 0.0, 0.94)
const RIGHT_ELBOW := Vector3(0.18, 0.0, -0.98)
const LaneKeeper = preload("res://tests/lane_keeper.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(110.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-hit-speeds-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	for kmh in SPEEDS:
		await _hit_at(kmh)
	_finish()


func _hit_at(kmh: float) -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	await physics_frame
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	_route.call("_spawn_pedestrian")
	var pedestrian: Node3D = _route.get("pedestrian")
	var crossing: Node3D = _route.get("crossing")
	var start := int(crossing.get("index")) - RUN_IN
	_place(start, LANE)
	var keeper := LaneKeeper.new(_road, start)
	var waited := 0.0
	while not bool(pedestrian.get("hit")) and waited < 10.0:
		await physics_frame
		waited += 1.0 / 60.0
		if not bool(pedestrian.get("hit")):
			_van.set("speed", kmh / 3.6)
			keeper.steer(_van, LANE)
	keeper.release()
	if not bool(pedestrian.get("hit")):
		_check(false, "At %.0f km/h the van hits him on the crossing" % kmh)
		await _close()
		return
	await _watch(kmh, pedestrian)
	await _close()


func _watch(kmh: float, pedestrian: Node3D) -> void:
	var presentation: Node3D = _van.get_node("VanPresentation")
	var bones: Dictionary = pedestrian.get("bones")
	var highest := -INF
	var furthest_back := -INF
	var wrong_way := INF
	var folded := -INF
	var crack := 0.0
	var watched := 0.0
	var run := 0
	var longest := 0
	var resting: Array[float] = []
	while watched < WATCH_SECONDS and not bool(pedestrian.get("settled")):
		await physics_frame
		watched += 1.0 / 60.0
		if watched <= 1.0:
			highest = maxf(highest, _clearance(pedestrian.call("hips_position")))
		for bone: Node3D in bones.values():
			furthest_back = maxf(furthest_back, presentation.to_local(bone.global_position).z)
		var bends: Array[float] = [_bend(bones, "LeftUpLeg", "LeftLeg", KNEE),
			_bend(bones, "RightUpLeg", "RightLeg", KNEE),
			_bend(bones, "LeftArm", "LeftForeArm", LEFT_ELBOW),
			_bend(bones, "RightArm", "RightForeArm", RIGHT_ELBOW)]
		var out := false
		for bend in bends:
			wrong_way = minf(wrong_way, bend)
			folded = maxf(folded, bend)
			out = out or bend < WRONG_WAY or bend > FOLDED
		run = run + 1 if out else 0
		longest = maxi(longest, run)
		resting = bends
		crack = maxf(crack, float(presentation.call("crack_state")["amount"]))
	var ahead := -_van.to_local(pedestrian.call("hips_position")).z - BUMPER
	_check(highest > ON_BONNET,
		"At %.0f km/h he is thrown onto the bonnet (hips %.2f m up)" % [kmh, highest])
	_check(crack > 0.5,
		"At %.0f km/h his head strikes the windshield and cracks it (%.2f)" % [kmh, crack])
	_check(furthest_back < ROOF_EDGE and ahead > 0.5,
		"At %.0f km/h he never passes over or through the cab, and lies %.1f m ahead of the "
		% [kmh, ahead] + "bumper (furthest back %.2f m)" % furthest_back)
	var rests_in_range := not resting.is_empty()
	for bend in resting:
		rests_in_range = rests_in_range and bend > WRONG_WAY and bend < FOLDED
	_check(longest <= LONGEST_OUT and rests_in_range,
		"At %.0f km/h his knees and elbows never stay bent the wrong way, and he comes to " % kmh
		+ "rest with them in range (peak %.0f and %.0f degrees, for %d tick" % [wrong_way, folded,
		longest] + ("s)" if longest != 1 else ")"))


func _close() -> void:
	_app.queue_free()
	await process_frame
	await process_frame


func _bend(bones: Dictionary, upper: String, lower: String, axis: Vector3) -> float:
	var a := (bones[upper] as Node3D).global_basis
	var u := a.y.normalized()
	var v := (bones[lower] as Node3D).global_basis.y.normalized()
	var hinge := (a * axis.normalized()).normalized()
	return rad_to_deg(atan2(u.cross(v).dot(hinge), u.dot(v)))


func _clearance(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0,
		point + Vector3.DOWN * 3.0, 1, [_van.get_rid()])
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(query)
	return point.y - (hit.position as Vector3).y if not hit.is_empty() else INF


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _finish() -> void:
	print("HIT SPEEDS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Hit-speed test finished within 110 s of game time")
	quit(1)
