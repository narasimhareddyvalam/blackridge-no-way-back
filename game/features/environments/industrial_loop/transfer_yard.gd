extends Node3D
## The bigger depot's yard (docs/PHASE_BRIEF.md, Phase 2 step 2c revised, part 1): the platform
## paved round the shed, the concrete apron along the docks and its drain, the bay lines and
## numbers, the arrows from the gate, the railed walkway from the gate to the office, the staff car
## bays behind their kerb, the trailer bays beside the shed's east wall, the bollards and the
## signs. The shed owns the fence and the gate; the world builds the five yard lights at LAMPS.
## Step 2d adds bay 9's two wheel guides, low steel rails that centre a van backing in, and its
## wheel chock on a holder on the dock face.

const Build = preload("res://shared/components/mesh_builder.gd")
const PLATFORM := Rect2(-92.0, -13.0, 66.0, 68.0)
const SHED := Rect2(-90.0, -10.0, 50.0, 30.0)
const APRON := Rect2(-90.0, 20.0, 50.0, 15.0)
const SURFACE := 0.02
const PAINT := 0.006
const BAY_LINES: Array[float] = [-82.0, -78.0, -74.0, -70.0, -66.0, -62.0, -58.0, -54.0, -50.0,
	-45.5]
const BAYS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0, -47.75]
const BAY_LENGTH := 12.0
const KEEP_CLEAR := Rect2(-49.6, 26.0, 3.7, 6.0)
const WALKWAY := Rect2(-91.8, 20.3, 1.4, 34.4)
const LANDING := Rect2(-90.4, 20.3, 2.2, 1.2)
const RAIL_X := -90.2
const RAIL_FROM := 21.5
const RAIL_TO := 42.0
const RAIL_HEIGHT := 1.1
const TRAILER_BAYS: Array[float] = [-37.4, -33.6, -29.8]
const TRAILER_BAY := Vector2(2.6, 14.0)
const TRAILER_BACK_Z := 4.0
const CAR_BAYS := Rect2(-88.4, 42.4, 5.0, 12.5)
const CAR_BAY_WIDTH := 2.5
const KERB_X := -89.0
const BOLLARDS: Array[Vector2] = [Vector2(-44.95, 20.35), Vector2(-40.55, 20.35)]
const BOLLARD_RADIUS := 0.075
const BOLLARD_HEIGHT := 1.07
const LAMPS: Array[Vector3] = [Vector3(-79.0, 0.0, 53.8), Vector3(-58.0, 0.0, 53.8),
	Vector3(-36.0, 0.0, 53.8), Vector3(-89.6, 0.0, 30.0), Vector3(-27.4, 0.0, 30.0)]
const LAMP_HEADINGS: Array[float] = [-PI / 2.0, -PI / 2.0, -PI / 2.0, PI, 0.0]
const SAFETY := Color(0.86, 0.66, 0.08)
const GUIDES := Vector2(-47.75, 1.25)
const GUIDE := Vector3(0.15, 0.2, 3.5)
const GUIDE_FROM := 20.5
const GUIDE_FLARE := Vector2(0.3, 1.0)
const GUIDE_STOP := 0.35
const CHOCK_HOLDER := Vector3(-45.8, 0.6, 20.0)
const CHOCK := Vector3(0.22, 0.2, 0.3)

var _white := Build.material(Color("d8d5cb"), 0.45)
var _yellow := Build.material(SAFETY, 0.45)
var _steel := Build.material(Color(0.6, 0.62, 0.62), 0.5)


func build(asphalt: Material) -> void:
	var slab := Build.material(Color(0.46, 0.46, 0.44), 0.6)
	_ground("DockApron", APRON, slab)
	_ground("YardAsphaltSouth", Rect2(PLATFORM.position.x, APRON.end.y, PLATFORM.size.x,
		PLATFORM.end.y - APRON.end.y), asphalt)
	_ground("YardAsphaltEast", Rect2(SHED.end.x, PLATFORM.position.y, PLATFORM.end.x - SHED.end.x,
		APRON.end.y - PLATFORM.position.y), asphalt)
	_ground("YardAsphaltWest", Rect2(PLATFORM.position.x, PLATFORM.position.y,
		SHED.position.x - PLATFORM.position.x, APRON.end.y - PLATFORM.position.y), asphalt)
	_ground("YardAsphaltBack", Rect2(SHED.position.x, PLATFORM.position.y, SHED.size.x,
		SHED.position.y - PLATFORM.position.y), asphalt)
	Build.box(self, Vector3(APRON.get_center().x, SURFACE + 0.003, APRON.end.y),
		Vector3(APRON.size.x, 0.006, 0.12), Build.material(Color(0.05, 0.05, 0.055), 0.35)) \
		.name = "SlotDrain"
	_bay_markings()
	_keep_clear()
	_arrow(Vector3(-70.0, 0.0, 54.9), PI / 2.0, 2.9)
	_arrow(Vector3(-65.0, 0.0, 53.8), 0.0)
	_arrow(Vector3(-65.9, 0.0, 52.6), PI)
	_walkway()
	_trailer_bays()
	_car_park(slab)
	for spot in BOLLARDS:
		_bollard(Vector3(spot.x, SURFACE, spot.y))
	_wheel_guides()
	_chock()
	_sign("5 MPH", Vector3(-66.9, 0.0, 56.2), 0.0, Color("f2f1ea"), Color("141414"), 0.6)
	_sign("HI-VIS BEYOND THIS POINT", Vector3(-80.0, 0.0, 55.25), 0.0, Color("1f4f9c"),
		Color("f2f1ea"), 1.7)
	_sign("STAFF PARKING ONLY", Vector3(-83.2, 0.0, 41.9), PI / 2.0, Color("f2f1ea"),
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


func _bay_markings() -> void:
	for x in BAY_LINES:
		_paint("BayLine", Vector2(x, SHED.end.y), Vector2(x, SHED.end.y + BAY_LENGTH), 0.1, _yellow)
	for index in range(BAYS.size()):
		var at := Vector3(BAYS[index], 0.0, SHED.end.y + BAY_LENGTH - 1.4)
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
	_ground_text("NO PARKING", Vector3(box.get_center().x, 0.0, box.position.y + 1.2), 110,
		SAFETY).name = "NoParking"


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
	for row: float in [LANDING.position.y + 0.25, LANDING.position.y + 0.95]:
		_paint("Walkway", Vector2(LANDING.position.x, row), Vector2(LANDING.end.x, row), 0.5,
			_white)
	var length := RAIL_TO - RAIL_FROM
	var centre := (RAIL_FROM + RAIL_TO) / 2.0
	Build.box(self, Vector3(RAIL_X, RAIL_HEIGHT, centre), Vector3(0.05, 0.05, length), _yellow,
		true).name = "WalkwayRail"
	Build.box(self, Vector3(RAIL_X, RAIL_HEIGHT / 2.0, centre), Vector3(0.04, 0.04, length),
		_yellow).name = "WalkwayMidRail"
	var post := RAIL_FROM
	while post <= RAIL_TO + 0.01:
		Build.cylinder(self, Vector3(RAIL_X, RAIL_HEIGHT / 2.0, post), 0.025, RAIL_HEIGHT, _yellow)
		post += 2.0


func _trailer_bays() -> void:
	var back := TRAILER_BACK_Z
	var front := TRAILER_BACK_Z + TRAILER_BAY.y
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
	var middle := Vector3(KERB_X, 0.0, CAR_BAYS.get_center().y)
	Build.box(self, middle + Vector3.UP * 0.085, Vector3(0.2, 0.15, CAR_BAYS.size.y), slab) \
		.name = "Kerb"
	var stop := StaticBody3D.new()
	add_child(stop)
	stop.name = "KerbStop"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 0.6, CAR_BAYS.size.y)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = middle + Vector3.UP * 0.3
	stop.add_child(collision)


func _wheel_guides() -> void:
	var stops := StaticBody3D.new()
	stops.name = "WheelGuideStops"
	add_child(stops)
	var end := GUIDE_FROM + GUIDE.z
	for side: float in [-1.0, 1.0]:
		var x := GUIDES.x + side * (GUIDES.y + GUIDE.x / 2.0)
		var straight := Vector3(x, 0.0, GUIDE_FROM + GUIDE.z / 2.0)
		_guide_piece(stops, straight, GUIDE.z, 0.0, "WheelGuide")
		var reach := Vector2(side * GUIDE_FLARE.x, GUIDE_FLARE.y)
		_guide_piece(stops, Vector3(x + reach.x / 2.0, 0.0, end + reach.y / 2.0), reach.length(),
			atan2(reach.x, reach.y), "WheelGuideFlare")


func _guide_piece(stops: StaticBody3D, at: Vector3, length: float, yaw: float,
		label: String) -> void:
	var rail := Build.box(self, at + Vector3.UP * (SURFACE + GUIDE.y / 2.0), Vector3(GUIDE.x,
		GUIDE.y, length), _yellow)
	rail.rotation.y = yaw
	rail.name = label
	var shape := BoxShape3D.new()
	shape.size = Vector3(GUIDE.x, GUIDE_STOP, length)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at + Vector3.UP * GUIDE_STOP / 2.0
	collision.rotation.y = yaw
	stops.add_child(collision)


func _chock() -> void:
	Build.box(self, CHOCK_HOLDER + Vector3(0.0, -0.02, 0.05), Vector3(CHOCK.x + 0.06, 0.04, 0.1),
		_steel).name = "ChockHolder"
	var chock := Node3D.new()
	chock.name = "WheelChock"
	chock.position = CHOCK_HOLDER + Vector3(0.0, 0.0, CHOCK.z / 2.0 + 0.01)
	add_child(chock)
	var rubber := Build.material(Color(0.95, 0.72, 0.08), 0.65)
	Build.instance(chock, Vector3.ZERO, _wedge(), rubber).name = "Wedge"


func _wedge() -> ArrayMesh:
	var half := CHOCK / 2.0
	var corners: Array[Vector3] = []
	for x: float in [-half.x, half.x]:
		corners.append_array([Vector3(x, 0.0, -half.z), Vector3(x, 0.0, half.z),
			Vector3(x, CHOCK.y, -half.z)])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in [[0, 2, 1], [3, 4, 5], [0, 1, 4, 3], [0, 3, 5, 2], [1, 2, 5, 4]]:
		var points: Array[Vector3] = []
		for index: int in face:
			points.append(corners[index])
		var normal := (points[2] - points[0]).cross(points[1] - points[0]).normalized()
		var fan: Array[int] = [0, 1, 2]
		if points.size() == 4:
			fan = [0, 1, 2, 0, 2, 3]
		for index in fan:
			tool.set_normal(normal)
			tool.add_vertex(points[index])
	return tool.commit()


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
