extends Node3D
## The bigger depot's transfer shed (docs/PHASE_BRIEF.md, Phase 2 step 2c revised, part 1): a
## 50 x 30 m metal building in grey box-profile sheeting over a 1.3 m concrete dock face, under a
## 5 degree gable roof of corrugated iron; along its front the office's two lit storeys, eight
## truck docks, the van bay and a drive-in door. Doors fill the openings (Task 3); the docks'
## seals, lights and inside come in part 2.

const Build = preload("res://shared/components/mesh_builder.gd")
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


func _doors() -> void:
	var face := BUILDING.end.y - DOOR_SET_BACK
	for index in range(DOCKS.size() + 1):
		var x := DOCKS[index] if index < DOCKS.size() else VAN_BAY
		_door("DockDoor%d" % (index + 1), DockDoor.instantiate() as Node3D,
			Vector3(x, DOCK_FLOOR, face), DOCK_OPENING)
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


func _door(name: String, model: Node3D, at: Vector3, opening: Vector2) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	holder.position = at
	add_child(holder)
	holder.add_child(model)
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
