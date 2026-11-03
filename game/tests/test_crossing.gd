extends SceneTree

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const ASPHALT := "res://features/environments/industrial_loop/wet_asphalt.gdshader"
const TRIGGER_SIDE := 729
const LEAD := 15
const NEAR := 2
const DARK_REACH := 25.0
const APPROACH := 672
const SLOW_SPEED := 5.6
const LANE := 1.0
const BUMPER := 2.45
const Mission = preload("res://features/missions/night_freight/first_drive.gd")

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _world: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _crossing: Node3D
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
	_scratch = OS.get_temp_dir().path_join("blackridge-crossing-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_world = _app.get_node("IndustrialLoop")
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _world.get("road")
	_crossing = _world.get("crossing")
	await process_frame
	_app.call("_resume")
	await physics_frame
	if _crossing == null:
		_check(false, "The world builds a bus stop with a crossing")
		_finish()
		return
	_check(_route.get("crossing") == _crossing, "The mission is given the crossing")
	_check_shelter()
	_check_paint()
	_check_signs()
	_check_path_and_clearing()
	_check_dark()
	await _check_parked()
	await _check_crawl()
	_finish()


func _check_shelter() -> void:
	var shelter := _crossing.get_node_or_null("Shelter") as Node3D
	if shelter == null:
		_check(false, "A bus shelter stands by the crossing")
		return
	var offset := shelter.global_position - (_crossing.centre as Vector3)
	var side: float = offset.dot(_crossing.right)
	var along: float = offset.dot(_crossing.forward)
	_check(side > float(_crossing.half_width) + 1.0 and along < 0.0 and offset.length() < 15.0,
		"A bus shelter stands on the right, %.1f m before the crossing and %.1f m off the road's "
		% [-along, side] + "centre")
	var glass := 0
	var timetable := false
	for node in shelter.find_children("*", "", true, false):
		if node is MeshInstance3D:
			var surface := (node as MeshInstance3D).material_override as BaseMaterial3D
			if surface and surface.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
				glass += 1
		elif node is Label3D:
			timetable = timetable or (node as Label3D).text.begins_with("BLACKRIDGE TRANSIT")
	var bin := shelter.find_child("*trash*", true, false) != null \
		or shelter.find_children("*", "Node3D", false, false).any(
			func(child: Node) -> bool: return child.scene_file_path.ends_with(".gltf"))
	_check(glass >= 3 and timetable and bin,
		"It has glass sides, a timetable and a litter bin (%d glass panes)" % glass)


func _check_paint() -> void:
	var paint: ShaderMaterial = null
	for node in _world.find_children("*", "MeshInstance3D", false, false):
		var surface := (node as MeshInstance3D).material_override as ShaderMaterial
		if surface and surface.shader and surface.shader.resource_path == ASPHALT \
				and surface.get_shader_parameter("crossing_size") != null:
			paint = surface
	if paint == null:
		_check(false, "The zebra crossing is painted on the road")
		return
	var size: Vector2 = paint.get_shader_parameter("crossing_size")
	var at: Vector2 = paint.get_shader_parameter("crossing_centre")
	var along: Vector2 = paint.get_shader_parameter("crossing_along")
	var centre: Vector3 = _crossing.centre
	var forward: Vector3 = _crossing.forward
	_check(is_equal_approx(size.x, 3.0) and is_equal_approx(size.y, float(_crossing.half_width) * 2.0)
		and at.distance_to(Vector2(centre.x, centre.z)) < 0.01
		and along.dot(Vector2(forward.x, forward.z)) > 0.999,
		"The zebra crossing is painted across the road (%.1f m by %.1f m)" % [size.x, size.y])


func _check_signs() -> void:
	var signs: Array = (_world.get("dressing") as Node).get("signs")
	var index: int = _crossing.index
	var count: int = _road.points.size()
	var wanted := {
		"westbound warning": [posmod(index - LEAD, count), "ahead", 1.0],
		"westbound crossing": [posmod(index - NEAR, count), "arrow_down_left", 1.0],
		"eastbound warning": [(index + LEAD) % count, "ahead", -1.0],
		"eastbound crossing": [(index + NEAR) % count, "arrow_down_left", -1.0],
	}
	var found := 0
	for label: String in wanted:
		var spot: Array = wanted[label]
		var diamond := false
		var plate := false
		for sign: Dictionary in signs:
			if sign["index"] != spot[0]:
				continue
			var side := _side_of(sign["at"], spot[0])
			if signf(side) != spot[2]:
				continue
			diamond = diamond or sign["kind"] == "pedestrian"
			plate = plate or sign["kind"] == spot[1]
		found += 1 if diamond and plate else 0
	_check(found == 4, "Pedestrian-crossing signs warn both ways: AHEAD 30 m out, and an arrow "
		+ "at the crossing (%d of 4)" % found)
	var shelter := _crossing.get_node("Shelter") as Node3D
	var flag := signs.any(func(sign: Dictionary) -> bool:
		return sign["kind"] == "bus_stop" \
			and (sign["at"] as Vector3).distance_to(shelter.global_position) < 10.0)
	_check(flag, "A BUS STOP flag marks the shelter")


func _check_path_and_clearing() -> void:
	var path := _crossing.get_node_or_null("Footpath") as MeshInstance3D
	if path == null:
		_check(false, "A footpath leads from the crossing toward the town")
		return
	var vertices: PackedVector3Array = path.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var centre: Vector3 = _crossing.centre
	var farthest := centre
	for vertex in vertices:
		if (vertex - centre).length() > (farthest - centre).length():
			farthest = vertex
	var away := farthest - centre
	_check(away.length() > 20.0 and away.normalized().dot(-(_crossing.right as Vector3)) > 0.85,
		"A footpath leads %.0f m from the far side of the crossing toward the town" % away.length())
	var clearings: Array = _crossing.get("clearings")
	var outside := 0
	for vertex in vertices:
		var inside := false
		for rect: Rect2 in clearings:
			inside = inside or rect.has_point(Vector2(vertex.x, vertex.z))
		outside += 0 if inside else 1
	var standing := 0
	for owner in [_world.get("forest"), _world.get("forest_floor")]:
		for node in (owner as Node).find_children("*", "MultiMeshInstance3D", true, false):
			standing += _inside(node as MultiMeshInstance3D, clearings)
	_check(outside == 0 and standing == 0,
		"No tree or plant grows in the shelter or on the path (%d inside; %d path points uncleared)"
		% [standing, outside])


func _check_dark() -> void:
	var nearest := INF
	for light in _world.find_children("*", "Light3D", true, false):
		if light is DirectionalLight3D:
			continue
		nearest = minf(nearest, (light as Node3D).global_position.distance_to(_crossing.centre))
	_check(nearest > DARK_REACH,
		"It is a dark stretch: the nearest lamp is %.0f m away" % nearest)


func _check_parked() -> void:
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	_place(TRIGGER_SIDE, LANE)
	_hold("brake", true)
	await _seconds(2.0)
	_hold("brake", false)
	_check(not is_instance_valid(_route.get("oncoming")) and not is_instance_valid(
		_route.get("pedestrian")) and not bool(_van.get("scripted")),
		"Stopped in the hairpin above the crossing, nothing starts until the van drives on")


func _check_crawl() -> void:
	_place(APPROACH, LANE)
	_van.set("speed", SLOW_SPEED)
	var keeper := LaneKeeper.new(_road, APPROACH)
	var waited := 0.0
	var at_kerb := false
	var pedestrian: Node3D = null
	while waited < 40.0:
		await physics_frame
		waited += 1.0 / 60.0
		if pedestrian == null and is_instance_valid(_route.get("pedestrian")):
			pedestrian = _route.get("pedestrian")
			at_kerb = bool(pedestrian.get("waiting")) \
				and pedestrian.global_position.distance_to(_crossing.kerb) < 0.05
		if pedestrian != null and not bool(pedestrian.get("waiting")):
			break
		keeper.steer(_van, LANE)
		var fast := float(_van.get("speed")) > SLOW_SPEED
		_hold("accelerate", not fast)
		_hold("brake", fast)
	keeper.release()
	_hold("accelerate", false)
	if pedestrian == null or bool(pedestrian.get("waiting")):
		_hold("brake", false)
		_check(false, "Crawling down, he steps out and the van skids into him on the crossing")
		return
	_check(at_kerb, "He waits at the crossing's kerb as the encounter begins")
	var stepped := float(_van.get("speed")) * 3.6
	_hold("brake", true)
	waited = 0.0
	while not bool(pedestrian.get("hit")) and waited < 6.0:
		await physics_frame
		waited += 1.0 / 60.0
	var speed := float(_van.get("speed")) * 3.6
	_hold("brake", false)
	var hit := bool(pedestrian.get("hit"))
	var at: Vector3 = pedestrian.call("hips_position") - (_crossing.centre as Vector3)
	_check(hit and absf(at.dot(_crossing.forward)) < 2.1,
		"Crawling down at %.0f km/h, braking as he steps out, the van still skids into " % stepped
		+ "him on the crossing at %.0f km/h (struck %.2f m from its centre line)"
		% [speed, absf(at.dot(_crossing.forward))])


func _inside(instances: MultiMeshInstance3D, clearings: Array) -> int:
	var multimesh := instances.multimesh
	if multimesh == null:
		return 0
	var count := 0
	for at in range(multimesh.instance_count):
		var origin := instances.global_transform * multimesh.get_instance_transform(at).origin
		for rect: Rect2 in clearings:
			if rect.grow(-0.5).has_point(Vector2(origin.x, origin.z)):
				count += 1
				break
	return count


func _side_of(at: Vector3, index: int) -> float:
	var right := Basis(Vector3.UP, _road.heading_at(index)).x
	return (at - _road.points[index]).dot(right)


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _until(condition: Callable, limit: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await physics_frame
		waited += 1.0 / 60.0


func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("CROSSING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Crossing test finished within 120 s of game time")
	quit(1)
