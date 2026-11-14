extends SceneTree
## The south valley road's gas station and main street (#267, part C, the author's choice of
## place #268): a level plot south of the road, a canopy over two pump islands, the store, three
## shops behind closed shutters and the street furniture of a small American town at night.
## N1 the plot is level and kept clear of the forest; it stands back from the road's asphalt.
## N2 nothing built stands on the road, or within 1 m of its asphalt but the driveways: every
##    corner of every body measured from the asphalt's edge (the terrain's distance beyond the
##    verge, plus the verge).
## N3 the van fits: the canopy is at least 14 ft 6 in (4.42 m) up, as US canopies are built,
##    the lane between the islands at least 3.5 m wide, and a box the van's size (2.3 m with its
##    mirrors, 2.2 m tall, 5.6 m long) drives in by the west driveway, between the islands and
##    out by the east one without touching anything built.
## N4 the props: four dispensers, the price sign with its three grades, the ice chest, the
##    propane cage with its cylinders, the newspaper box, the payphone, a bench, a bin, the air
##    machine, three shops with their shutters down over their whole openings, two parked cars.
## N5 lit as a station is at night: at least six downlights under the canopy, inside it,
##    pointing down, without shadows; the price sign, the store's fascia and its windows glow.
## N6 no real brand on any sign.
## N7 everything a van or a man could walk into is solid: each of the town's pieces has a body.

const TownStation = preload("res://features/environments/industrial_loop/town_station.gd")
const CANOPY_LEAST := 4.42
const LANE_LEAST := 3.5
const VAN_BOX := Vector3(2.3, 2.2, 5.6)
const ROAD_GAP := 1.0
const LEVEL := 0.03
const BRANDS: Array[String] = ["SHELL", "EXXON", "MOBIL", "CHEVRON", "TEXACO", "ARCO", "BP ",
	"SUNOCO", "VALERO", "CITGO", "MARATHON", "PHILLIPS", "CONOCO", "SINCLAIR", "7-ELEVEN",
	"CIRCLE K", "WAWA", "SPEEDWAY", "CASEY", "KWIK"]
const PROPS := {"Dispenser": 4, "PriceSign": 1, "IceChest": 1, "PropaneCage": 1,
	"NewspaperBox": 1, "Payphone": 1, "Bench": 1, "Bin": 1, "AirWater": 1, "Shutter": 3,
	"ParkedCar": 2}
const SOLID: Array[String] = ["Dispenser", "PriceSign", "IceChest", "PropaneCage",
	"NewspaperBox", "Payphone", "Bench", "Bin", "AirWater", "ParkedCar", "Island", "Column",
	"Bollard", "Store", "Shop"]

var _checks: int = 0
var _failures: int = 0
var _app: Node
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
	_scratch = OS.get_temp_dir().path_join("blackridge-town-%d.cfg" % OS.get_process_id())
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await physics_frame
	var world := _app.get_node("IndustrialLoop") as Node3D
	var town := world.find_child("TownStation", true, false) as Node3D
	_check(town != null, "The town is built (TownStation)")
	if town == null:
		_finish()
		return
	_check_plot(world)
	_check_road(world, town)
	await _check_van(world, town)
	_check_props(town)
	_check_lights(town)
	_check_brands()
	_check_solid(town)
	_finish()


func _check_plot(world: Node3D) -> void:
	var terrain: Node3D = world.get("terrain")
	var plot: Rect2 = TownStation.PLOT
	var heights: Array[float] = []
	var x := plot.position.x + 1.0
	while x < plot.end.x:
		var z := plot.position.y + 1.0
		while z < plot.end.y:
			heights.append(terrain.height_at(x, z))
			z += 2.0
		x += 2.0
	var spread: float = heights.max() - heights.min()
	var listed := false
	for rect: Rect2 in world.call("_flat_plots"):
		listed = listed or rect.encloses(plot)
	var forest := world.get_node("RoadsideForest")
	var inside := 0
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape: CollisionShape3D in body.get_children():
				if plot.has_point(Vector2(shape.global_position.x, shape.global_position.z)):
					inside += 1
	_check(spread <= LEVEL and listed and inside == 0, "N1 the plot is level (%.3f m across it), "
		% spread + "one of the world's flat plots, with no tree on it (%d trunks)" % inside)


func _check_road(world: Node3D, town: Node3D) -> void:
	var terrain: Node3D = world.get("terrain")
	var verge: float = (world.get("road") as RefCounted).get("VERGE")
	var worst := INF
	var where := ""
	for node in town.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if String(shape.get_parent().name).begins_with("Driveway"):
			continue
		for corner in _footprint(shape):
			var gap: float = terrain.road_clearance(corner.x, corner.z) + verge
			if gap < worst:
				worst = gap
				where = String(shape.get_parent().name)
	_check(worst >= ROAD_GAP, "N2 nothing built within %.0f m of the road's asphalt "
		% ROAD_GAP + "(nearest %s, %.2f m from it)" % [where, worst])


func _footprint(shape: CollisionShape3D) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	if shape.shape is BoxShape3D:
		var half := (shape.shape as BoxShape3D).size / 2.0
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				corners.append(shape.global_transform * Vector3(x * half.x, 0.0, z * half.z))
	elif shape.shape is CylinderShape3D:
		var radius := (shape.shape as CylinderShape3D).radius
		for angle in range(8):
			corners.append(shape.global_position + Vector3(cos(angle * TAU / 8.0), 0.0,
				sin(angle * TAU / 8.0)) * radius)
	else:
		corners.append(shape.global_position)
	return corners


func _check_van(world: Node3D, town: Node3D) -> void:
	var canopy: float = TownStation.CANOPY_UNDER
	var lane: float = TownStation.ISLANDS[1].position.y - TownStation.ISLANDS[0].end.y
	var space := town.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = VAN_BOX
	var touched := {}
	var path: Array = TownStation.DRIVE_PATH
	var terrain: Node3D = world.get("terrain")
	for leg in range(path.size() - 1):
		var from: Vector2 = path[leg]
		var to: Vector2 = path[leg + 1]
		var steps := int(from.distance_to(to) / 0.5) + 1
		for step in range(steps + 1):
			var at := from.lerp(to, float(step) / steps)
			var ground: float = terrain.height_at(at.x, at.y)
			var heading := (to - from).normalized()
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = box
			query.transform = Transform3D(Basis.looking_at(Vector3(heading.x, 0.0, heading.y),
				Vector3.UP), Vector3(at.x, ground + 0.25 + VAN_BOX.y / 2.0, at.y))
			for hit in space.intersect_shape(query, 16):
				var collider: Object = hit["collider"]
				if collider is Node and town.is_ancestor_of(collider as Node):
					touched[(collider as Node).name] = true
	_check(canopy >= CANOPY_LEAST and lane >= LANE_LEAST and touched.is_empty(),
		"N3 the van fits: canopy %.2f m up, the lane between the islands %.1f m, and its box " % [
		canopy, lane] + "drives in, between the islands and out touching %s" % [touched.keys()])


func _count(town: Node3D, label: String) -> int:
	var count := 0
	var found: Array = town.find_children(label + "*", "Node3D", true, false) if label \
		== "Shutter" else town.get_children()
	for node: Node in found:
		if String(node.name).begins_with(label) and not String(node.name).ends_with("Body"):
			count += 1
	return count


func _check_props(town: Node3D) -> void:
	var counts := {}
	var right := true
	for label: String in PROPS:
		counts[label] = _count(town, label)
		right = right and counts[label] == PROPS[label]
	var cylinders := 0
	var cage := town.find_child("PropaneCage", true, false)
	if cage != null:
		cylinders = cage.find_children("Cylinder*", "Node3D", true, false).size()
	var shut := true
	for node in town.find_children("Shutter*", "Node3D", true, false):
		var shutter := node as Node3D
		shut = shut and float(shutter.get_meta("covers", 0.0)) >= 0.99
	var grades: Array = TownStation.PRICES
	_check(right and cylinders >= 6 and shut and grades.size() == 3,
		"N4 the props are there: %s, %d cylinders in the cage, every shutter down over its "
		% [counts, cylinders] + "opening, the sign's grades %s" % [grades])


func _check_lights(town: Node3D) -> void:
	var canopy: Rect2 = TownStation.CANOPY
	var downlights := 0
	var wrong := 0
	for node in town.find_children("Downlight*", "SpotLight3D", true, false):
		var light := node as SpotLight3D
		downlights += 1
		var at := light.global_position
		var down := -light.global_basis.z
		if not canopy.has_point(Vector2(at.x, at.z)) or down.dot(Vector3.DOWN) < 0.98 \
				or light.shadow_enabled:
			wrong += 1
	var glowing := 0
	for label in ["PriceSign", "StoreFascia", "StoreWindow"]:
		var found := town.find_child(label + "*", true, false)
		if found == null:
			continue
		for mesh in [found] + found.find_children("*", "MeshInstance3D", true, false):
			if mesh is GeometryInstance3D and (mesh as GeometryInstance3D).material_override \
					is BaseMaterial3D and ((mesh as GeometryInstance3D).material_override
					as BaseMaterial3D).emission_enabled:
				glowing += 1
				break
	_check(downlights >= 6 and wrong == 0 and glowing == 3, "N5 lit as a station at night: "
		+ "%d downlights under the canopy (%d out of place, pointing elsewhere or " % [downlights,
		wrong] + "shadowed), %d of the price sign, fascia and windows glowing" % glowing)


func _check_brands() -> void:
	var found: Array[String] = []
	for text: String in TownStation.SIGN_WORDS:
		for brand in BRANDS:
			if (text.to_upper() + " ").contains(brand):
				found.append(text)
	_check(found.is_empty() and not TownStation.SIGN_WORDS.is_empty(),
		"N6 no real brand on any sign (%s)" % ", ".join(TownStation.SIGN_WORDS))


func _check_solid(town: Node3D) -> void:
	var missing: Array[String] = []
	for label in SOLID:
		for node in town.get_children():
			if not String(node.name).begins_with(label) or String(node.name).ends_with("Body"):
				continue
			var solid := node is CollisionObject3D \
				or not node.find_children("*", "CollisionObject3D", true, false).is_empty()
			if not solid:
				missing.append(String(node.name))
	_check(missing.is_empty(), "N7 everything one could walk or drive into is solid (not: %s)"
		% [missing])


func _finish() -> void:
	print("TOWN RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Town test finished within 120 s of game time")
	quit(1)
