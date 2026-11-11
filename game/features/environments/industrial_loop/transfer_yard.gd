extends Node3D
## The transfer depot's yard (docs/PHASE_BRIEF.md, Phase 2 step 2c-1, layout B): the paving, the
## concrete strip along the docks and its drain, the side yard cut level behind its retaining wall,
## the markings, the car park's kerb, the bollards, the walkway and its rail, and the signs. The
## shed owns the fence, the gate and the booth; the world builds the two pole lights at `LAMPS`.

const Build = preload("res://shared/components/mesh_builder.gd")
const FRONT := Rect2(-89.0, 37.5, 36.0, 17.5)
const SIDE := Rect2(-53.0, 30.0, 26.0, 25.0)
const FLAT := Rect2(-53.0, 32.0, 25.0, 25.0)
const CLEARING := Rect2(-56.0, 27.0, 32.0, 32.0)
const APRON_END_Z := 45.0
const SURFACE := 0.02
const PAINT := 0.006
const WALL_THICKNESS := 0.3
const WALL_STEP := 2.0
const WALL_CAP := 0.15
const EAST_WALL_OUT := 1.15
const NATURAL_OUT := 3.0
const BAY_LINES: Array[float] = [-82.0, -74.0, -66.0, -58.0]
const BAYS: Array[float] = [-78.0, -70.0, -62.0]
const BAY_LENGTH := 12.0
const KEEP_CLEAR := Rect2(-65.6, 45.6, 7.2, 6.0)
const WALKWAY := Rect2(-88.6, 40.2, 1.8, 14.3)
const RAIL_X := -86.6
const RAIL_HEIGHT := 1.1
const TRAILER_BAYS: Array[float] = [-46.0, -41.0, -36.0]
const TRAILER_BAY := Vector2(2.6, 14.0)
const TRAILER_FRONT_Z := 31.5
const CAR_BAYS := Rect2(-33.0, 44.8, 5.0, 10.0)
const CAR_BAY_WIDTH := 2.5
const KERB_Z := 44.4
const BOLLARDS: Array[Vector2] = [Vector2(-88.5, 38.3), Vector2(-53.5, 38.3),
	Vector2(-74.0, 38.6), Vector2(-66.0, 38.6)]
const BOLLARD_RADIUS := 0.075
const BOLLARD_HEIGHT := 1.07
const LAMPS: Array[Vector3] = [Vector3(-46.0, 0.0, 54.0), Vector3(-29.0, 0.0, 40.0)]
const LAMP_HEADINGS: Array[float] = [-PI / 2.0, 0.0]
const SAFETY := Color(0.86, 0.66, 0.08)

var wall_top: float = 0.0
var _white := Build.material(Color("d8d5cb"), 0.45)
var _yellow := Build.material(SAFETY, 0.45)
var _steel := Build.material(Color(0.6, 0.62, 0.62), 0.5)


func build(dock_front_z: float, asphalt: Material, terrain: Node3D) -> void:
	var slab := Build.material(Color(0.46, 0.46, 0.44), 0.6)
	_ground("DockApron", Rect2(FRONT.position.x, FRONT.position.y, FRONT.size.x,
		APRON_END_Z - FRONT.position.y), slab)
	_ground("YardAsphalt", Rect2(FRONT.position.x, APRON_END_Z, FRONT.size.x,
		FRONT.end.y - APRON_END_Z), asphalt)
	_ground("YardAsphaltSide", SIDE, asphalt)
	Build.box(self, Vector3(FRONT.get_center().x, SURFACE + 0.003, APRON_END_Z),
		Vector3(FRONT.size.x, 0.006, 0.12), Build.material(Color(0.05, 0.05, 0.055), 0.35)) \
		.name = "SlotDrain"
	_retaining_wall(terrain, slab)
	_bay_markings(dock_front_z)
	_keep_clear()
	_arrow(Vector3(-70.0, 0.0, 54.9), PI / 2.0, 2.9)
	_arrow(Vector3(-65.0, 0.0, 53.8), 0.0)
	_arrow(Vector3(-65.9, 0.0, 52.6), PI)
	_walkway()
	_trailer_bays()
	_car_park(slab)
	for spot in BOLLARDS:
		_bollard(Vector3(spot.x, SURFACE, spot.y))
	_sign("5 MPH", Vector3(-66.9, 0.0, 56.2), 0.0, Color("f2f1ea"), Color("141414"), 0.6)
	_sign("HI-VIS BEYOND THIS POINT", Vector3(-80.0, 0.0, 55.25), 0.0, Color("1f4f9c"),
		Color("f2f1ea"), 1.7)
	_sign("STAFF PARKING ONLY", Vector3(-33.8, 0.0, 44.1), -PI / 2.0, Color("f2f1ea"),
		Color("1f4f9c"), 1.3)


func _ground(name: String, rect: Rect2, surface: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = [Vector3(rect.position.x, SURFACE, rect.position.y),
		Vector3(rect.end.x, SURFACE, rect.position.y), Vector3(rect.end.x, SURFACE, rect.end.y),
		Vector3(rect.position.x, SURFACE, rect.end.y)]
	for index: int in [0, 1, 2, 0, 2, 3]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(corners[index].x, corners[index].z))
		tool.add_vertex(corners[index])
	tool.generate_tangents()
	var piece := Build.instance(self, Vector3.ZERO, tool.commit(), surface)
	piece.name = name
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _retaining_wall(terrain: Node3D, slab: Material) -> void:
	var behind := SIDE.position.y - 2.1
	var highest := 0.0
	for x in range(int(SIDE.position.x), int(SIDE.end.x) + 1):
		highest = maxf(highest, float(terrain.call("height_at", float(x), behind)))
	wall_top = highest + WALL_CAP
	var length := SIDE.size.x + EAST_WALL_OUT + WALL_THICKNESS / 2.0
	Build.box(self, Vector3(SIDE.position.x + length / 2.0, wall_top / 2.0,
		SIDE.position.y - WALL_THICKNESS / 2.0), Vector3(length, wall_top, WALL_THICKNESS), slab,
		true).name = "RetainingWall"
	var z := SIDE.position.y
	while z < SIDE.end.y:
		var ground := maxf(float(terrain.call("height_at", SIDE.end.x + NATURAL_OUT, z)),
			float(terrain.call("height_at", SIDE.end.x + NATURAL_OUT, z + WALL_STEP)))
		if ground < 0.25:
			break
		var height := ground + WALL_CAP
		Build.box(self, Vector3(SIDE.end.x + EAST_WALL_OUT, height / 2.0, z + WALL_STEP / 2.0),
			Vector3(WALL_THICKNESS, height, WALL_STEP), slab, true).name = "RetainingWallEast"
		z += WALL_STEP


func _paint(name: String, from: Vector2, to: Vector2, width: float, colour: Material) -> void:
	var length := from.distance_to(to)
	var stripe := Build.box(self, Vector3((from.x + to.x) / 2.0, SURFACE + PAINT / 2.0,
		(from.y + to.y) / 2.0), Vector3(length, PAINT, width), colour)
	stripe.rotation.y = -atan2(to.y - from.y, to.x - from.x)
	stripe.name = name
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ground_text(words: String, at: Vector3, size: int, colour: Color) -> Label3D:
	var label := Build.text(self, words, at + Vector3.UP * (SURFACE + PAINT + 0.002), size, colour)
	label.rotation.x = -PI / 2.0
	label.shaded = true
	label.double_sided = false
	label.pixel_size = 0.004
	return label


func _bay_markings(dock_front_z: float) -> void:
	for x in BAY_LINES:
		_paint("BayLine", Vector2(x, dock_front_z), Vector2(x, dock_front_z + BAY_LENGTH), 0.1,
			_yellow)
	for index in range(BAYS.size()):
		var at := Vector3(BAYS[index], 0.0, dock_front_z + BAY_LENGTH - 1.4)
		_ground_text(str(index + 1), at, 300, SAFETY).name = "BayNumber"


func _keep_clear() -> void:
	var box := KEEP_CLEAR
	var corners: Array[Vector2] = [box.position, Vector2(box.end.x, box.position.y), box.end,
		Vector2(box.position.x, box.end.y)]
	for index in range(4):
		_paint("HatchedBox", corners[index], corners[(index + 1) % 4], 0.12, _yellow)
	var lowest := box.position.x - box.end.y
	var step := 1.2
	var offset := lowest + step
	while offset < box.end.x - box.position.y:
		var start_x := maxf(box.position.x, box.position.y + offset)
		var end_x := minf(box.end.x, box.end.y + offset)
		if end_x - start_x > 0.2:
			_paint("HatchedBox", Vector2(start_x, start_x - offset), Vector2(end_x, end_x - offset),
				0.15, _yellow)
		offset += step
	_ground_text("NO PARKING", Vector3(box.get_center().x, 0.0, box.end.y - 0.9), 130, SAFETY) \
		.name = "NoParking"


func _arrow(at: Vector3, heading: float, length: float = 3.4) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var neck := length - 1.0
	var points: Array[Vector2] = [Vector2(0.0, -0.15), Vector2(neck, -0.15),
		Vector2(neck, 0.15), Vector2(0.0, 0.15), Vector2(neck, -0.45), Vector2(length, 0.0),
		Vector2(neck, 0.45)]
	for index: int in [0, 1, 2, 0, 2, 3, 4, 5, 6]:
		tool.set_normal(Vector3.UP)
		tool.add_vertex(Vector3(points[index].x, SURFACE + PAINT, points[index].y))
	var arrow := Build.instance(self, at, tool.commit(), _white)
	arrow.rotation.y = heading
	arrow.name = "Arrow"
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _walkway() -> void:
	var z := WALKWAY.position.y + 0.25
	while z < WALKWAY.end.y:
		_paint("Walkway", Vector2(WALKWAY.position.x, z), Vector2(WALKWAY.end.x, z), 0.5, _white)
		z += 1.0
	var length := WALKWAY.size.y
	var centre := WALKWAY.get_center().y
	Build.box(self, Vector3(RAIL_X, RAIL_HEIGHT, centre), Vector3(0.05, 0.05, length), _yellow,
		true).name = "WalkwayRail"
	Build.box(self, Vector3(RAIL_X, RAIL_HEIGHT / 2.0, centre), Vector3(0.04, 0.04, length),
		_yellow).name = "WalkwayMidRail"
	var post := WALKWAY.position.y
	while post <= WALKWAY.end.y + 0.01:
		Build.cylinder(self, Vector3(RAIL_X, RAIL_HEIGHT / 2.0, post), 0.025, RAIL_HEIGHT, _yellow)
		post += 2.0


func _trailer_bays() -> void:
	var back := TRAILER_FRONT_Z
	var front := TRAILER_FRONT_Z + TRAILER_BAY.y
	for x in TRAILER_BAYS:
		var half := TRAILER_BAY.x / 2.0
		_paint("TrailerBay", Vector2(x - half, back), Vector2(x - half, front), 0.1, _white)
		_paint("TrailerBay", Vector2(x + half, back), Vector2(x + half, front), 0.1, _white)
		_paint("TrailerBay", Vector2(x - half, back), Vector2(x + half, back), 0.1, _white)


func _car_park(slab: Material) -> void:
	var z := CAR_BAYS.position.y
	while z <= CAR_BAYS.end.y + 0.01:
		_paint("CarBay", Vector2(CAR_BAYS.position.x, z), Vector2(CAR_BAYS.end.x, z), 0.1, _white)
		z += CAR_BAY_WIDTH
	var length := SIDE.end.x - (CAR_BAYS.position.x - 0.6)
	var middle := Vector3(SIDE.end.x - length / 2.0, 0.0, KERB_Z)
	Build.box(self, middle + Vector3.UP * 0.085, Vector3(length, 0.15, 0.2), slab).name = "Kerb"
	var stop := StaticBody3D.new()
	stop.name = "KerbStop"
	add_child(stop)
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, 0.6, 0.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = middle + Vector3.UP * 0.3
	stop.add_child(collision)


func _bollard(at: Vector3) -> void:
	var bollard := Build.cylinder(self, at + Vector3.UP * BOLLARD_HEIGHT / 2.0, BOLLARD_RADIUS,
		BOLLARD_HEIGHT, _yellow)
	bollard.name = "YardBollard"
	bollard.create_trimesh_collision()


func _sign(words: String, at: Vector3, heading: float, plate: Color, ink: Color,
		width: float) -> void:
	var sign := Node3D.new()
	sign.position = at
	sign.rotation.y = heading
	add_child(sign)
	sign.name = "Sign"
	var height := 2.1
	Build.cylinder(sign, Vector3(0.0, height / 2.0, -0.03), 0.03, height, _steel) \
		.create_trimesh_collision()
	var tall := 0.32 if width > 1.0 else 0.6
	Build.box(sign, Vector3(0.0, height - tall / 2.0, 0.0), Vector3(width, tall, 0.02),
		Build.material(plate, 0.5))
	var letters := minf(tall * 0.6, width * 0.9 / (words.length() * 0.6))
	var label := Build.text(sign, words, Vector3(0.0, height - tall / 2.0, 0.012),
		int(letters / 0.002), ink)
	label.shaded = true
	label.double_sided = false
	label.pixel_size = 0.002
