extends Node3D
## The bigger depot's transfer shed (docs/PHASE_BRIEF.md, Phase 2 step 2c revised, part 1): a
## 50 x 30 m metal building in grey box-profile sheeting over a 1.3 m concrete dock face, under a
## 5 degree gable roof of corrugated iron; along its front the office's two lit storeys, eight
## truck docks, the van bay and a drive-in door. Part 2 puts the docks to work: seals, bumpers,
## levellers, dock lights and signals; docks 5 and 9 stand open, their doors raised into their
## tracks with an arm light inside, and the lit floor behind them holds the staged loads.

const Build = preload("res://shared/components/mesh_builder.gd")
const Staging = preload("dock_staging.gd")
const DockDoor = preload("res://features/environments/industrial_loop/art/depot/dock_door.glb")
const SHUTTERS := "res://features/environments/depot_yard/polyhaven/models/rollershutter_door/"
const BUILDING := Rect2(-90.0, -10.0, 50.0, 30.0)
const EAVES := 9.0
const PITCH_DEGREES := 5.0
const DOCK_FLOOR := 1.3
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0]
const VAN_BAY := -47.75
const DRIVE_IN := -42.75
const DOCK_OPENING := Vector2(2.74, 3.05)
const DRIVE_IN_OPENING := Vector2(3.7, 2.9)
const OFFICE := Rect2(-90.0, 12.0, 8.0, 8.0)
const OFFICE_STOREY := 3.5
const OFFICE_DOOR := Rect2(-89.3, 0.0, 0.95, 2.15)
const OFFICE_WINDOWS: Array[Rect2] = [Rect2(-87.4, 1.0, 1.5, 1.2), Rect2(-84.6, 1.0, 1.5, 1.2),
	Rect2(-89.2, 4.4, 1.5, 1.2), Rect2(-86.75, 4.4, 1.5, 1.2), Rect2(-84.3, 4.4, 1.5, 1.2)]
const WALL := 0.25
const PLINTH := 1.0
const OVERHANG := 0.4
const ROOF_THICKNESS := 0.15
const DOWNPIPES: Array[float] = [-89.6, -74.0, -62.0, -54.0, -40.4]
const OFFICE_GLOW := Color(1.0, 0.93, 0.82)
const SHUTTER_SCALE := 1.2
const DOOR_SET_BACK := 0.06
const SEAL_BASE := 1.15
const BUMPER := Vector3(0.25, 0.45, 0.13)
const BUMPER_OFF := 1.1
const LEVELLER_IN := 1.22
const LEVELLER_RAISE := 0.01
const OPEN_DOCKS: Array[int] = [4, 8]
const LIGHT_ABOVE := 0.6
const DOCK_LIGHT := Color(1.0, 0.96, 0.9)
const SIGNAL_OFF := 2.0
const SIGNAL_HEIGHT := 2.4
const RAISED := 0.35
const TRACK_INSIDE := 0.34
const ARM_HEIGHT := 2.1
const ARM_LIGHT := Color(1.0, 0.97, 0.92)
const BAY_ROWS: Array[float] = [15.0, 5.0]
const BAY_XS: Array[float] = [-78.0, -70.0, -62.0, -54.0, -46.0]
const BAY_HEIGHT := 8.4
const BAY_LIGHT := Color(0.94, 0.97, 1.0)
const AISLE: Array[float] = [14.0, 10.0]
const LANE := Color(0.95, 0.75, 0.05)
const DEPOT_TEXTURES := "res://features/environments/depot_yard/polyhaven/textures/"
const LOOP_TEXTURES := "res://features/environments/industrial_loop/polyhaven/textures/"
const ART := "res://features/environments/industrial_loop/art/depot/"

var _body: StaticBody3D
var _cladding: ORMMaterial3D
var _concrete: ORMMaterial3D
var _iron: ORMMaterial3D
var _interior := Build.material(Color("d6d1c4"), 0.85)
var _glass := StandardMaterial3D.new()


func build(metal: Material) -> void:
	_cladding = _surface(DEPOT_TEXTURES, "box_profile_metal_sheet", "2k", 2.0)
	_cladding.albedo_texture = load(ART + "cladding_grey_diff_2k.jpg")
	_concrete = _surface(DEPOT_TEXTURES, "concrete_wall_006", "2k", 2.5)
	_iron = _surface(LOOP_TEXTURES, "corrugated_iron", "1k", 1.12)
	_glass.albedo_color = Color(0.55, 0.64, 0.68, 0.3)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.roughness = 0.06
	_body = StaticBody3D.new()
	_body.name = "ShedBody"
	add_child(_body)
	_front()
	_back_and_sides()
	_roof(metal)
	_office(metal)
	_markers()
	_doors()
	_fittings()
	_lights()
	_signals()
	_arm_lights()
	_bay_lights()
	_lanes()
	Staging.build(self, DOCK_FLOOR)


func _front() -> void:
	var face := BUILDING.end.y - WALL / 2.0
	var office_end := OFFICE.end.x
	var holes: Array[Rect2] = [OFFICE_DOOR]
	holes.append_array(OFFICE_WINDOWS)
	_wall(BUILDING.position.x, office_end, 0.0, PLINTH, face, holes, _concrete)
	_wall(BUILDING.position.x, office_end, PLINTH, EAVES, face, holes, _cladding)
	var docks: Array[Rect2] = []
	var centres: Array[float] = DOCKS.duplicate()
	centres.append(VAN_BAY)
	for x in centres:
		docks.append(Rect2(x - DOCK_OPENING.x / 2.0, DOCK_FLOOR, DOCK_OPENING.x, DOCK_OPENING.y))
	docks.append(Rect2(DRIVE_IN - DRIVE_IN_OPENING.x / 2.0, 0.0, DRIVE_IN_OPENING.x,
		DRIVE_IN_OPENING.y))
	_wall(office_end, BUILDING.end.x, 0.0, DOCK_FLOOR, face, docks, _concrete)
	_wall(office_end, BUILDING.end.x, DOCK_FLOOR, EAVES, face, docks, _cladding)
	var slab_end := DRIVE_IN - DRIVE_IN_OPENING.x / 2.0 - 0.1
	_piece(Vector3((office_end + slab_end) / 2.0, DOCK_FLOOR / 2.0, BUILDING.get_center().y),
		Vector3(slab_end - office_end, DOCK_FLOOR, BUILDING.size.y - WALL * 2.0), _concrete)


func _back_and_sides() -> void:
	var back := BUILDING.position.y + WALL / 2.0
	var none: Array[Rect2] = []
	_wall(BUILDING.position.x, BUILDING.end.x, 0.0, PLINTH, back, none, _concrete)
	_wall(BUILDING.position.x, BUILDING.end.x, PLINTH, EAVES, back, none, _cladding)
	for x: float in [BUILDING.position.x + WALL / 2.0, BUILDING.end.x - WALL / 2.0]:
		var depth := BUILDING.size.y - WALL * 2.0
		_piece(Vector3(x, PLINTH / 2.0, BUILDING.get_center().y), Vector3(WALL, PLINTH, depth),
			_concrete)
		_piece(Vector3(x, (PLINTH + EAVES) / 2.0, BUILDING.get_center().y), Vector3(WALL,
			EAVES - PLINTH, depth), _cladding)
		_gable(x)


func _wall(x0: float, x1: float, y0: float, y1: float, z: float, holes: Array[Rect2],
		surface: Material) -> void:
	var cuts: Array[float] = [x0, x1]
	for hole in holes:
		cuts.append(clampf(hole.position.x, x0, x1))
		cuts.append(clampf(hole.end.x, x0, x1))
	cuts.sort()
	for index in range(cuts.size() - 1):
		var a := cuts[index]
		var b := cuts[index + 1]
		if b - a < 0.001:
			continue
		var middle := (a + b) / 2.0
		var spans: Array[Vector2] = [Vector2(y0, y1)]
		for hole in holes:
			if middle > hole.position.x and middle < hole.end.x:
				spans = _without(spans, hole.position.y, hole.end.y)
		for span in spans:
			if span.y - span.x > 0.001:
				_piece(Vector3(middle, (span.x + span.y) / 2.0, z), Vector3(b - a, span.y - span.x,
					WALL), surface)


func _without(spans: Array[Vector2], low: float, high: float) -> Array[Vector2]:
	var kept: Array[Vector2] = []
	for span in spans:
		if high <= span.x or low >= span.y:
			kept.append(span)
			continue
		if low > span.x:
			kept.append(Vector2(span.x, low))
		if high < span.y:
			kept.append(Vector2(high, span.y))
	return kept


func _piece(at: Vector3, size: Vector3, surface: Material) -> void:
	Build.box(self, at, size, surface)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	_body.add_child(collision)


func _gable(x: float) -> void:
	var rise := BUILDING.size.y / 2.0 * tan(deg_to_rad(PITCH_DEGREES))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = [Vector3(x, EAVES, BUILDING.position.y),
		Vector3(x, EAVES, BUILDING.end.y), Vector3(x, EAVES + rise, BUILDING.get_center().y)]
	for order: Array in [[0, 1, 2], [0, 2, 1]]:
		var normal := Vector3.RIGHT if order[1] == 1 else Vector3.LEFT
		for index: int in order:
			tool.set_normal(normal)
			tool.add_vertex(points[index])
	var gable := Build.instance(self, Vector3.ZERO, tool.commit(), _cladding)
	gable.name = "Gable"


func _roof(metal: Material) -> void:
	var pitch := deg_to_rad(PITCH_DEGREES)
	var half := BUILDING.size.y / 2.0
	var ridge := EAVES + half * tan(pitch)
	var low := EAVES - OVERHANG * tan(pitch)
	var length := (half + OVERHANG) / cos(pitch)
	var width := BUILDING.size.x + OVERHANG * 2.0
	var ridge_z := BUILDING.get_center().y
	for side: float in [1.0, -1.0]:
		var eave_z := ridge_z + side * (half + OVERHANG)
		var centre := Vector3(BUILDING.get_center().x, (low + ridge) / 2.0 + ROOF_THICKNESS / 2.0,
			(eave_z + ridge_z) / 2.0)
		var slope := Build.box(self, centre, Vector3(width, ROOF_THICKNESS, length), _iron)
		slope.rotation.x = pitch * side
		slope.name = "Roof"
		var gutter := Build.box(self, Vector3(centre.x, low - 0.08, eave_z + side * 0.06),
			Vector3(width, 0.15, 0.15), metal)
		gutter.name = "Gutter"
	for x in DOWNPIPES:
		var pipe := Build.cylinder(self, Vector3(x, (low - 0.1) / 2.0 + 0.15, BUILDING.end.y + 0.08),
			0.05, low - 0.4, metal)
		pipe.name = "Downpipe"


func _office(metal: Material) -> void:
	var inner_z := BUILDING.end.y - WALL
	var depth := inner_z - OFFICE.position.y
	var middle_z := OFFICE.position.y + depth / 2.0
	var width := OFFICE.size.x - WALL
	var middle_x := OFFICE.position.x + WALL + width / 2.0
	for floor_y: float in [0.0, OFFICE_STOREY]:
		Build.box(self, Vector3(middle_x, floor_y + 0.01, middle_z), Vector3(width, 0.02, depth),
			_interior).name = "OfficeFloor"
		Build.box(self, Vector3(middle_x, floor_y + 3.3, middle_z), Vector3(width, 0.2, depth),
			_interior).name = "OfficeCeiling"
		Build.box(self, Vector3(middle_x, floor_y + 3.18, middle_z - 0.5), Vector3(1.2, 0.03, 0.6),
			Build.luminous(OFFICE_GLOW, 2.0)).name = "OfficePanel"
		Build.box(self, Vector3(middle_x - 1.0, floor_y + 0.38, inner_z - 1.2), Vector3(1.6, 0.75,
			0.8), Build.material(Color("5c5348"), 0.7)).name = "OfficeDesk"
		var light := OmniLight3D.new()
		light.name = "OfficeLight" if floor_y == 0.0 else "OfficeLightUpper"
		light.light_color = OFFICE_GLOW
		light.light_energy = 1.2
		light.omni_range = 7.0
		light.position = Vector3(middle_x, floor_y + 2.9, middle_z)
		add_child(light)
	Build.box(self, Vector3(middle_x, EAVES / 2.0, OFFICE.position.y + 0.05), Vector3(width,
		EAVES, 0.1), _interior).name = "OfficeBackWall"
	Build.box(self, Vector3(OFFICE.end.x - 0.05, EAVES / 2.0, middle_z), Vector3(0.1, EAVES,
		depth), _interior).name = "OfficeSideWall"
	for window in OFFICE_WINDOWS:
		var centre := Vector3(window.get_center().x, window.get_center().y, BUILDING.end.y - 0.12)
		Build.box(self, centre, Vector3(window.size.x, window.size.y, 0.02), _glass).name = \
			"OfficeWindow"
		for edge: Vector4 in [Vector4(0.0, window.size.y / 2.0, window.size.x, 0.05),
				Vector4(0.0, -window.size.y / 2.0, window.size.x, 0.05),
				Vector4(window.size.x / 2.0, 0.0, 0.05, window.size.y),
				Vector4(-window.size.x / 2.0, 0.0, 0.05, window.size.y)]:
			Build.box(self, centre + Vector3(edge.x, edge.y, 0.03), Vector3(edge.z, edge.w, 0.06),
				metal)
	var door := Build.box(self, Vector3(OFFICE_DOOR.get_center().x, OFFICE_DOOR.size.y / 2.0,
		BUILDING.end.y - 0.03), Vector3(OFFICE_DOOR.size.x, OFFICE_DOOR.size.y, 0.06),
		Build.material(Color("3d4447"), 0.5))
	door.name = "OfficeDoor"
	var shape := BoxShape3D.new()
	shape.size = Vector3(OFFICE_DOOR.size.x, OFFICE_DOOR.size.y, WALL)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(OFFICE_DOOR.get_center().x, OFFICE_DOOR.size.y / 2.0,
		BUILDING.end.y - WALL / 2.0)
	_body.add_child(collision)


func _markers() -> void:
	var names: Array[String] = []
	var spots: Array[Vector3] = []
	for index in range(DOCKS.size()):
		names.append("DockOpening%d" % (index + 1))
		spots.append(Vector3(DOCKS[index], DOCK_FLOOR, BUILDING.end.y))
	names.append("DockOpening9")
	spots.append(Vector3(VAN_BAY, DOCK_FLOOR, BUILDING.end.y))
	names.append("DriveInOpening")
	spots.append(Vector3(DRIVE_IN, 0.0, BUILDING.end.y))
	for index in range(names.size()):
		var marker := Marker3D.new()
		marker.name = names[index]
		marker.position = spots[index]
		add_child(marker)


func _fittings() -> void:
	var seal := load(ART + "dock_seal.glb") as PackedScene
	var leveller := load(ART + "dock_leveller.glb") as PackedScene
	var rubber := Build.material(Color(0.05, 0.05, 0.05), 0.9)
	var centres: Array[float] = DOCKS.duplicate()
	centres.append(VAN_BAY)
	for index in range(centres.size()):
		var x := centres[index]
		var pads := seal.instantiate() as Node3D
		pads.name = "DockSeal%d" % (index + 1)
		pads.position = Vector3(x, SEAL_BASE, BUILDING.end.y)
		add_child(pads)
		for side: float in [-1.0, 1.0]:
			Build.box(self, Vector3(x + side * BUMPER_OFF, DOCK_FLOOR - BUMPER.y / 2.0,
				BUILDING.end.y + BUMPER.z / 2.0), BUMPER, rubber, true).name = "DockBumper"
		if index < DOCKS.size():
			var deck := leveller.instantiate() as Node3D
			deck.name = "DockLeveller%d" % (index + 1)
			deck.position = Vector3(x, DOCK_FLOOR + LEVELLER_RAISE,
				BUILDING.end.y - WALL - LEVELLER_IN)
			add_child(deck)
			deck.position.z += BUILDING.end.y - WALL - 0.01 - _box_in(deck).end.z
	var west := OFFICE.end.x
	var east := DRIVE_IN - DRIVE_IN_OPENING.x / 2.0
	Build.box(self, Vector3((west + east) / 2.0, DOCK_FLOOR - 0.03, BUILDING.end.y + 0.01),
		Vector3(east - west, 0.06, 0.02), Build.material(Color(0.86, 0.66, 0.08), 0.5)) \
		.name = "DockEdge"


func _lights() -> void:
	var housing := Build.material(Color(0.12, 0.12, 0.12), 0.6)
	var lens := Build.luminous(DOCK_LIGHT, 2.5)
	var tops: Array[Vector2] = []
	var centres: Array[float] = DOCKS.duplicate()
	centres.append(VAN_BAY)
	for x in centres:
		tops.append(Vector2(x, DOCK_FLOOR + DOCK_OPENING.y))
	tops.append(Vector2(DRIVE_IN, DRIVE_IN_OPENING.y))
	for index in range(tops.size()):
		var top := tops[index]
		var height := top.y + LIGHT_ABOVE
		Build.box(self, Vector3(top.x, height + 0.05, BUILDING.end.y + 0.14), Vector3(0.42, 0.16,
			0.28), housing).name = "DockLightFixture"
		Build.box(self, Vector3(top.x, height - 0.035, BUILDING.end.y + 0.2), Vector3(0.34, 0.01,
			0.18), lens).name = "DockLightLens"
		var light := SpotLight3D.new()
		light.name = "DockLight%d" % (index + 1)
		add_child(light)
		light.position = Vector3(top.x, height, BUILDING.end.y + 0.3)
		light.look_at(Vector3(top.x, 0.0, BUILDING.end.y + 3.2), Vector3.UP)
		light.light_color = DOCK_LIGHT
		light.light_energy = 3.0
		light.spot_angle = 55.0
		light.spot_range = 10.0
		light.shadow_enabled = false


func _signals() -> void:
	var body := Build.material(Color(0.08, 0.08, 0.08), 0.6)
	var centres: Array[float] = DOCKS.duplicate()
	centres.append(VAN_BAY)
	for index in range(centres.size()):
		var open := OPEN_DOCKS.has(index)
		var housing := Node3D.new()
		housing.name = "DockSignal%d" % (index + 1)
		housing.position = Vector3(centres[index] + SIGNAL_OFF, SIGNAL_HEIGHT, BUILDING.end.y + 0.05)
		add_child(housing)
		Build.box(housing, Vector3.ZERO, Vector3(0.16, 0.4, 0.1), body).name = "Housing"
		var red := Build.luminous(Color(1.0, 0.08, 0.04), 3.0) if not open \
			else Build.material(Color(0.22, 0.04, 0.03), 0.4)
		var green := Build.luminous(Color(0.1, 1.0, 0.35), 3.0) if open \
			else Build.material(Color(0.03, 0.18, 0.06), 0.4)
		Build.box(housing, Vector3(0.0, 0.09, 0.055), Vector3(0.1, 0.1, 0.02), red).name = "Red"
		Build.box(housing, Vector3(0.0, -0.09, 0.055), Vector3(0.1, 0.1, 0.02), green).name = \
			"Green"


func _box_in(node: Node3D) -> AABB:
	var seen := AABB()
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		var box: AABB = global_transform.affine_inverse() * part.global_transform * part.get_aabb()
		seen = box if not seen.has_volume() else seen.merge(box)
	return seen


func _doors() -> void:
	var face := BUILDING.end.y - DOOR_SET_BACK
	for index in range(DOCKS.size() + 1):
		var open := OPEN_DOCKS.has(index)
		var door := _door("DockDoor%d" % (index + 1), DockDoor.instantiate() as Node3D,
			Vector3(_dock_x(index), DOCK_FLOOR, face), DOCK_OPENING, not open)
		if open:
			_raise(door)
	var shutter := (load(SHUTTERS + "rollershutter_door.gltf") as PackedScene).instantiate() as Node3D
	shutter.scale = Vector3.ONE * SHUTTER_SCALE
	var holder := _door("DriveInDoor", shutter, Vector3(DRIVE_IN, 0.0, face), DRIVE_IN_OPENING)
	var fitted := AABB()
	for found in shutter.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		var box: AABB = holder.global_transform.affine_inverse() * part.global_transform \
			* part.get_aabb()
		fitted = box if not fitted.has_volume() else fitted.merge(box)
	shutter.position -= Vector3(fitted.get_center().x, fitted.position.y,
		fitted.end.z - DOOR_SET_BACK - 0.01)


func _door(name: String, model: Node3D, at: Vector3, opening: Vector2,
		shut: bool = true) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	holder.position = at
	add_child(holder)
	holder.add_child(model)
	if not shut:
		return holder
	var shape := BoxShape3D.new()
	shape.size = Vector3(opening.x, opening.y, 0.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, opening.y / 2.0, BUILDING.end.y - 0.1 - at.z)
	var body := StaticBody3D.new()
	body.name = "DoorBody"
	body.add_child(collision)
	holder.add_child(body)
	return holder


func _dock_x(index: int) -> float:
	return DOCKS[index] if index < DOCKS.size() else VAN_BAY


func _raise(holder: Node3D) -> void:
	var head := DOCK_OPENING.y + RAISED
	var panel := holder.get_child(0) as Node3D
	panel.rotation.x = -PI / 2.0
	panel.position = Vector3(0.0, head, -TRACK_INSIDE)
	var steel := Build.material(Color(0.62, 0.64, 0.66), 0.45)
	var x := holder.position.x
	var inside := BUILDING.end.y - WALL - 0.06
	for side: float in [-1.0, 1.0]:
		var edge := x + side * (DOCK_OPENING.x / 2.0 + 0.05)
		Build.box(self, Vector3(edge, DOCK_FLOOR + head / 2.0, inside), Vector3(0.05, head, 0.08),
			steel).name = "DoorTrack"
		var length := DOCK_OPENING.y + TRACK_INSIDE
		Build.box(self, Vector3(edge, DOCK_FLOOR + head, inside - length / 2.0), Vector3(0.05,
			0.08, length), steel).name = "DoorTrack"
	Build.box(self, Vector3(x, DOCK_FLOOR + head + 0.25, inside), Vector3(DOCK_OPENING.x + 0.3,
		0.06, 0.06), steel).name = "DoorSpringShaft"


func _arm_lights() -> void:
	var steel := Build.material(Color(0.16, 0.16, 0.17), 0.5)
	var lens := Build.luminous(ARM_LIGHT, 2.5)
	var inside := BUILDING.end.y - WALL
	for index in OPEN_DOCKS:
		var x := _dock_x(index)
		var mount := Vector3(x + DOCK_OPENING.x / 2.0 + 0.35, DOCK_FLOOR + ARM_HEIGHT, inside - 0.05)
		var head := Vector3(x + DOCK_OPENING.x / 2.0 - 0.15, DOCK_FLOOR + ARM_HEIGHT, inside - 0.45)
		Build.box(self, mount, Vector3(0.12, 0.2, 0.1), steel).name = "DockArmBracket"
		var arm := Build.box(self, (mount + head) / 2.0, Vector3(0.04, 0.04, mount.distance_to(head)),
			steel)
		arm.look_at(head, Vector3.UP)
		arm.name = "DockArm"
		var light := SpotLight3D.new()
		light.name = "DockArmLight%d" % (index + 1)
		add_child(light)
		light.position = head
		light.look_at(Vector3(x - 0.4, DOCK_FLOOR + 0.4, BUILDING.end.y + 6.0), Vector3.UP)
		var lamp := Build.box(light, Vector3(0.0, 0.0, 0.1), Vector3(0.24, 0.18, 0.22), steel)
		lamp.name = "DockArmLamp"
		Build.box(light, Vector3(0.0, 0.0, -0.015), Vector3(0.2, 0.14, 0.01), lens).name = \
			"DockArmLens"
		light.light_color = ARM_LIGHT
		light.light_energy = 2.0
		light.spot_angle = 28.0
		light.spot_range = 14.0
		light.shadow_enabled = false


func _bay_lights() -> void:
	var housing := Build.material(Color(0.55, 0.57, 0.6), 0.4)
	var lens := Build.luminous(BAY_LIGHT, 3.0)
	var count := 0
	for z in BAY_ROWS:
		var roof := EAVES + (BUILDING.end.y - z) * tan(deg_to_rad(PITCH_DEGREES))
		for x in BAY_XS:
			count += 1
			var at := Vector3(x, BAY_HEIGHT, z)
			Build.cylinder(self, at + Vector3(0.0, 0.08, 0.0), 0.22, 0.16, housing, 0.12).name = \
				"BayLightFixture"
			Build.cylinder(self, at, 0.2, 0.01, lens).name = "BayLightLens"
			var cord := roof - BAY_HEIGHT - 0.16
			Build.cylinder(self, at + Vector3(0.0, 0.16 + cord / 2.0, 0.0), 0.008, cord, housing) \
				.name = "BayLightCord"
			var light := SpotLight3D.new()
			light.name = "BayLight%d" % count
			light.position = at - Vector3(0.0, 0.02, 0.0)
			light.rotation.x = -PI / 2.0
			light.light_color = BAY_LIGHT
			light.light_energy = 4.5
			light.spot_angle = 60.0
			light.spot_range = 10.5
			light.shadow_enabled = false
			add_child(light)


func _lanes() -> void:
	var paint := Build.material(LANE, 0.6)
	var west := OFFICE.end.x + 0.2
	var east := DRIVE_IN - DRIVE_IN_OPENING.x / 2.0 - 0.4
	for z in AISLE:
		Build.box(self, Vector3((west + east) / 2.0, DOCK_FLOOR + 0.003, z), Vector3(east - west,
			0.004, 0.1), paint).name = "LaneLine"
	var back := BUILDING.end.y - WALL - 0.15
	for index in range(DOCKS.size()):
		var x := (_dock_x(index) + _dock_x(index + 1)) / 2.0
		Build.box(self, Vector3(x, DOCK_FLOOR + 0.003, (AISLE[0] + back) / 2.0), Vector3(0.1, 0.004,
			back - AISLE[0]), paint).name = "LaneLine"


func _surface(root: String, asset: String, resolution: String, tile: float) -> ORMMaterial3D:
	var material := ORMMaterial3D.new()
	var path := root + "%s/%s_%s_%s.jpg"
	material.albedo_texture = load(path % [asset, asset, "diff", resolution])
	material.normal_enabled = true
	material.normal_texture = load(path % [asset, asset, "nor_gl", resolution])
	material.orm_texture = load(path % [asset, asset, "arm", resolution])
	material.uv1_scale = Vector3.ONE / tile
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	return material
