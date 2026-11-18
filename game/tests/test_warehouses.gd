extends SceneTree
## Mission 2's step 5, part B (docs/PHASE_BRIEF.md; the author's choice "Rebuild both", #315):
## the compound's two warehouses rebuilt to the realism bar where the Phase 1 boxes stood, as
## tilt-up concrete warehouses: the boxes gone; each where it stood and as high; its panels'
## joints at the piers, never across a door, no panel over 9.2 m; a parapet 0.9 m or more over
## its roof, capped; its docks on its north face at a 1.22 m floor, 4 m apart, each with its door
## shut and solid, its seal, its two bumpers at the floor's height and its signal; its man door's
## stair to IBC 1011 and its landing's guard (1015); downpipes from scuppers to the ground; its
## walls solid; wall packs over the court.

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const WAREHOUSES := {"WarehouseWest": [Rect2(133.325, 100.5, 33.35, 23.0), 9.99, 6],
	"WarehouseEast": [Rect2(232.284, 108.5, 35.432, 23.0), 10.531, 7]}
const DOCK_FLOOR := 1.22
const DOCK_OPENING := Vector2(2.74, 3.05)
const DOCK_SPACING := 4.0
const LONGEST_PANEL := 9.2
const PARAPET := 0.9
const RISE := Vector2(0.102, 0.178)
const LEAST_TREAD := 0.279
const HANDRAIL := Vector2(0.864, 0.965)
const GUARD := 1.067
const LANDING := 1.118
const DOWNPIPES := 4
const WALL_PACKS := {"WarehouseWest": 3, "WarehouseEast": 4}

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _compound: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-warehouses-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_resume")
	await physics_frame
	_compound = _app.get_node("IndustrialLoop").get("compound") as Node3D
	var found := 0
	for label: String in WAREHOUSES:
		found += 1 if _compound.has_node(label) else 0
	_check(found == WAREHOUSES.size() and _boxes_gone(), "W0: both warehouses rebuilt in the "
		+ "compound, the Phase 1 boxes gone")
	if found < WAREHOUSES.size():
		_finish()
		return
	await physics_frame
	for label: String in WAREHOUSES:
		await _check_one(label, _compound.get_node(label) as Node3D)
	_finish()


func _boxes_gone() -> bool:
	for child in _app.get_node("IndustrialLoop").get_children():
		if child is MeshInstance3D:
			var box := (child as MeshInstance3D).global_transform \
				* (child as MeshInstance3D).get_aabb()
			for label: String in WAREHOUSES:
				var rect: Rect2 = WAREHOUSES[label][0]
				if Vector2(box.get_center().x, box.get_center().z).distance_to(rect.get_center()) \
						< 1.0 and box.size.x > 20.0:
					return false
	return true


func _check_one(label: String, house: Node3D) -> void:
	var rect: Rect2 = WAREHOUSES[label][0]
	var height: float = WAREHOUSES[label][1]
	var walls := _merged(house, "Wall")
	var flat := Rect2(walls.position.x, walls.position.z, walls.size.x, walls.size.z)
	_check(flat.position.distance_to(rect.position) < 0.1 and flat.end.distance_to(rect.end) < 0.1
		and absf(walls.end.y - height) < 0.05 and absf(walls.position.y) < 0.02, "W1: %s where "
		% label + "it stood, %.2f x %.2f m and %.2f m high" % [flat.size.x, flat.size.y,
		walls.end.y])
	var openings: Array = house.call("dock_openings")
	var joints: Dictionary = house.call("panel_joints")
	var spans_ok := joints.size() == 4
	var across := false
	var widest := 0.0
	for face: String in joints:
		var points: Array = (joints[face] as Array).duplicate()
		points.sort()
		for index in range(1, points.size()):
			var span: float = points[index] - points[index - 1]
			widest = maxf(widest, span)
			spans_ok = spans_ok and span <= LONGEST_PANEL and span >= 2.0
		if face == "north":
			for x: float in points:
				for opening: Rect2 in openings:
					across = across or (x > opening.position.x - 0.05
						and x < opening.end.x + 0.05)
	var sealed := house.find_children("PanelJoint*", "MeshInstance3D", true, false).size()
	_check(spans_ok and not across and sealed > 0, "W2: %s's panels jointed at the piers, " % label
		+ "never across a door, the widest %.1f m (%d sealed joints)" % [widest, sealed])
	var roof := _merged(house, "RoofDeck")
	var coping := _merged(house, "Coping")
	_check(roof.has_volume() and height - roof.end.y >= PARAPET and coping.has_volume()
		and coping.end.y >= height and coping.size.x >= rect.size.x and coping.size.z
		>= rect.size.y, "W3: %s's parapet %.2f m over its roof, capped all round" % [label,
		height - roof.end.y])
	var expected: int = WAREHOUSES[label][2]
	var docked := openings.size() == expected
	var spaced := true
	for index in range(openings.size()):
		var opening: Rect2 = openings[index]
		docked = docked and opening.size.is_equal_approx(DOCK_OPENING) \
			and absf(opening.position.y - DOCK_FLOOR) < 0.01
		if index > 0:
			spaced = spaced and absf(opening.get_center().x - (openings[index - 1] as Rect2) \
				.get_center().x - DOCK_SPACING) < 0.01
	var seals := house.find_children("DockSeal*", "Node3D", false, false).size()
	var bumpers := house.find_children("DockBumper*", "MeshInstance3D", true, false)
	var bumped := bumpers.size() == expected * 2
	for bumper in bumpers:
		var box := (bumper as MeshInstance3D).global_transform \
			* (bumper as MeshInstance3D).get_aabb()
		bumped = bumped and absf(box.end.y - DOCK_FLOOR) < 0.01 \
			and absf(box.position.z - rect.end.y) < 0.01
	var signals := house.find_children("DockSignal*", "Node3D", false, false).size()
	var doors := house.find_children("DockDoor*", "Node3D", false, false).size()
	_check(docked and spaced and seals == expected and bumped and signals == expected
		and doors == expected, "W4: %s's %d docks on its north face, %.2f x %.2f m at a %.2f m "
		% [label, openings.size(), DOCK_OPENING.x, DOCK_OPENING.y, DOCK_FLOOR]
		+ "floor, 4 m apart, each with its door, seal, two bumpers and signal")
	_check_stair(label, house)
	var pipes := house.find_children("Downpipe*", "MeshInstance3D", true, false)
	var piped := pipes.size() >= DOWNPIPES
	for pipe in pipes:
		var box := (pipe as MeshInstance3D).global_transform * (pipe as MeshInstance3D).get_aabb()
		piped = piped and box.position.y <= 0.3 and box.end.y >= roof.end.y - 0.3
	var scuppers := house.find_children("Scupper*", "MeshInstance3D", true, false).size()
	_check(piped and scuppers == pipes.size(), "W6: %s's %d downpipes from scuppers at its " % [
		label, pipes.size()] + "roof to the ground")
	var lights := house.find_children("WallPack*", "SpotLight3D", true, false)
	var lit := lights.size() >= int(WALL_PACKS[label])
	for light in lights:
		var at := (light as SpotLight3D).global_position
		lit = lit and at.y > 5.5 and at.y < 8.0 and not (light as SpotLight3D).shadow_enabled
	_check(lit, "W8: %s's %d wall packs over its court, 5.5-8 m up, no shadows" % [label,
		lights.size()])
	var over := house.find_children("DockLight*", "SpotLight3D", true, false)
	var each := over.size() == openings.size()
	for index in range(mini(over.size(), openings.size())):
		var at := (over[index] as SpotLight3D).global_position
		var opening: Rect2 = openings[index]
		each = each and absf(at.x - opening.get_center().x) < 0.05 and at.y > opening.end.y \
			and not (over[index] as SpotLight3D).shadow_enabled
	_check(each, "W8: %s's dock light over each of its %d doors, no shadows" % [label,
		over.size()])
	await _check_solid(label, house, rect, openings)


func _check_stair(label: String, house: Node3D) -> void:
	var steps := house.find_children("Step*", "MeshInstance3D", true, false)
	var tops: Array[float] = []
	var treads := INF
	for step in steps:
		var box := (step as MeshInstance3D).global_transform * (step as MeshInstance3D).get_aabb()
		tops.append(box.end.y)
		treads = minf(treads, minf(box.size.x, box.size.z))
	tops.sort()
	var landing := _merged(house, "Landing")
	tops.append(landing.end.y)
	var rises: Array[float] = []
	var last := 0.0
	for top in tops:
		rises.append(top - last)
		last = top
	var even := not steps.is_empty()
	for rise in rises:
		even = even and rise >= RISE.x and rise <= RISE.y and absf(rise - rises[0]) < 0.005
	_check(even and treads >= LEAST_TREAD and absf(landing.end.y - DOCK_FLOOR) < 0.01
		and minf(landing.size.x, landing.size.z) >= LANDING, "W5: %s's man door: %d risers " % [
		label, rises.size()] + "of %.3f m, treads %.3f m, a landing %.2f m deep at the floor" % [
		rises[0] if not rises.is_empty() else 0.0, treads, minf(landing.size.x, landing.size.z)])
	var rails: Array = house.call("handrail_heights")
	var railed := rails.size() >= 2
	for over: float in rails:
		railed = railed and over >= HANDRAIL.x and over <= HANDRAIL.y
	var guard := _merged(house, "Guard")
	_check(railed and guard.has_volume() and guard.end.y - landing.end.y >= GUARD, "W5: %s's " % label
		+ "stair railed both sides %s m over its nosings, its landing guarded %.2f m" % [rails,
		guard.end.y - landing.end.y])


func _check_solid(label: String, house: Node3D, rect: Rect2, openings: Array) -> void:
	await physics_frame
	var space := _app.get_world_3d().direct_space_state
	var missed: Array[String] = []
	var middle := rect.get_center()
	var rays := {"south": [Vector3(middle.x, 3.0, rect.position.y - 1.0), Vector3(middle.x, 3.0,
			rect.position.y + 1.0)],
		"west": [Vector3(rect.position.x - 1.0, 3.0, middle.y), Vector3(rect.position.x + 1.0, 3.0,
			middle.y)],
		"east": [Vector3(rect.end.x + 1.0, 3.0, middle.y), Vector3(rect.end.x - 1.0, 3.0,
			middle.y)]}
	if not openings.is_empty():
		var door: Rect2 = openings[0]
		rays["the dock face"] = [Vector3(door.get_center().x, 0.6, rect.end.y + 1.0),
			Vector3(door.get_center().x, 0.6, rect.end.y - 1.0)]
		rays["a shut door"] = [Vector3(door.get_center().x, 2.6, rect.end.y + 1.0),
			Vector3(door.get_center().x, 2.6, rect.end.y - 1.0)]
		rays["a pier"] = [Vector3(door.end.x + 0.6, 6.0, rect.end.y + 1.0),
			Vector3(door.end.x + 0.6, 6.0, rect.end.y - 1.0)]
	for wall: String in rays:
		var ray := PhysicsRayQueryParameters3D.create(rays[wall][0], rays[wall][1])
		if space.intersect_ray(ray).is_empty():
			missed.append(wall)
	var landing := _merged(house, "Landing")
	var probe := PhysicsPointQueryParameters3D.new()
	probe.position = landing.get_center() - Vector3.UP * 0.05
	if space.intersect_point(probe, 1).is_empty():
		missed.append("the landing")
	_check(missed.is_empty(), "W7: %s's walls, dock face, doors and landing solid (not: %s)" % [
		label, ", ".join(missed)])


func _merged(house: Node3D, prefix: String) -> AABB:
	var merged := AABB()
	for node in house.find_children(prefix + "*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		merged = box if not merged.has_volume() else merged.merge(box)
	return merged


func _timeout() -> void:
	_check(false, "The warehouses' checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("WAREHOUSES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
