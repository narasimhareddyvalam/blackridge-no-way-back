extends Node3D
## One of the warehouse compound's two warehouses (Mission 2's step 5, part B, #315): a tilt-up
## concrete warehouse where a Phase 1 box stood, as tall: 0.2 m panels painted light grey over a
## darker 1.22 m dock face, two reveal lines, sealed vertical joints at the piers between its
## docks (never across a door; no panel over 9 m), a parapet 1.0 m over the roof deck with metal
## coping, rooftop units and a hatch; on its north face its docks at a 1.22 m floor, 4 m apart,
## each with an overhead door shut in its opening (the shed's model), a foam seal, two bumpers at
## the floor's height, a signal and its number; LED wall packs over every other pier; a steel man
## door with its landing, stair and rails (IBC 1011.5.2: risers 4-7 in, treads 11 in or more;
## 1014: handrails 34-38 in on both sides; 1015: a 42 in guard where the landing drops more than
## 30 in), the fire department connection and key box beside it; scuppers through the parapet with
## downpipes to splash blocks. Its walls, dock face, doors, landing and steps are solid.

const Build = preload("res://shared/components/mesh_builder.gd")
const DockDoor = preload("res://features/environments/industrial_loop/art/depot/dock_door.glb")
const ART := "res://features/environments/industrial_loop/art/depot/"
const TEXTURES := "res://features/environments/depot_yard/polyhaven/textures/"
const DOCK_FLOOR := 1.22
const DOCK_OPENING := Vector2(2.74, 3.05)
const WALL := 0.2
const PARAPET := 1.0
const DECK := 0.25
const PANEL := 9.0
const JOINT_CLEAR := 0.3
const REVEALS: Array[float] = [5.0, 1.7]
const DOOR_SET_BACK := 0.06
const SEAL_BASE := DOCK_FLOOR - 0.15
const BUMPER := Vector3(0.25, 0.45, 0.13)
const BUMPER_OFF := 1.1
const SIGNAL_OFF := 2.0
const SIGNAL_HEIGHT := 2.4
const NUMBER_ABOVE := 0.35
const PACK_HEIGHT := 6.5
const PACK_LIGHT := Color(0.95, 0.97, 1.0)
## Each dock's light over its door, as the shed's (`transfer_building.gd`'s `_lights`).
const LIGHT_ABOVE := 0.6
const DOCK_LIGHT := Color(1.0, 0.96, 0.9)
const MAN_DOOR := Vector2(0.95, 2.13)
const LANDING := Vector2(1.5, 1.5)
const RISERS := 7
const TREAD := 0.28
const STAIR_WIDTH := 1.12
const HANDRAIL := 0.9
const GUARD := 1.1
const PIPE_RADIUS := 0.06

var rect: Rect2
var height := 10.0
var docks: Array[float] = []
var _openings: Array[Rect2] = []
var _joints := {}
var _rails: Array[Node3D] = []
var _rail_line: Callable
var _body: StaticBody3D
var _paint: ORMMaterial3D
var _base: ORMMaterial3D
var _seam := Build.material(Color(0.16, 0.16, 0.16), 0.7)
var _steel := Build.material(Color(0.36, 0.38, 0.39), 0.45)
var _red_off := Build.material(Color(0.22, 0.04, 0.03), 0.4)
var _green_on := Build.luminous(Color(0.1, 1.0, 0.35), 3.0)


## Builds the warehouse on `footprint` (x, z), `tall` high, its docks at `dock_xs` on its north
## face and its man door at `man_x`, its stair going down toward `stair_side` (-1 west, 1 east).
func build(footprint: Rect2, tall: float, dock_xs: Array[float], man_x: float,
		stair_side: float, metal: Material) -> void:
	rect = footprint
	height = tall
	docks = dock_xs
	_paint = _surface(Color(0.74, 0.73, 0.7))
	_base = _surface(Color(0.46, 0.46, 0.45))
	_body = StaticBody3D.new()
	_body.name = "WarehouseBody"
	add_child(_body)
	for x in docks:
		_openings.append(Rect2(x - DOCK_OPENING.x / 2.0, DOCK_FLOOR, DOCK_OPENING.x,
			DOCK_OPENING.y))
	var door := Rect2(man_x - MAN_DOOR.x / 2.0, DOCK_FLOOR, MAN_DOOR.x, MAN_DOOR.y)
	_north(door)
	_sides()
	_roof(metal)
	_docks()
	_wall_packs()
	_man_door(door, stair_side)
	_drains()


## Each dock's opening in the north face, as Rect2(x, y, width, height), west to east.
func dock_openings() -> Array[Rect2]:
	return _openings.duplicate()


## Each face's panel joints along it, its ends included: x for north and south, z for the sides.
func panel_joints() -> Dictionary:
	return _joints.duplicate(true)


## How high each of the stair's handrails stands over the line of its nosings, at its middle.
func handrail_heights() -> Array[float]:
	var heights: Array[float] = []
	for rail in _rails:
		var at := rail.global_position
		heights.append(at.y + 0.025 - float(_rail_line.call(at.x)))
	return heights


func _north(door: Rect2) -> void:
	var z := rect.end.y - WALL / 2.0
	var holes: Array[Rect2] = _openings.duplicate()
	holes.append(door)
	var edges: Array[float] = [rect.position.x, rect.end.x]
	for hole in holes:
		edges.append(hole.position.x)
		edges.append(hole.end.x)
	edges.sort()
	for index in range(edges.size() - 1):
		var x0 := edges[index]
		var x1 := edges[index + 1]
		if x1 - x0 < 0.001:
			continue
		var middle := (x0 + x1) / 2.0
		var hole := Rect2()
		for found in holes:
			if middle > found.position.x and middle < found.end.x:
				hole = found
		var low := DOCK_FLOOR if hole.size == Vector2.ZERO else hole.position.y
		_wall(Vector3(middle, low / 2.0, z), Vector3(x1 - x0, low, WALL), _base)
		var from := DOCK_FLOOR if hole.size == Vector2.ZERO else hole.end.y
		_wall(Vector3(middle, (from + height) / 2.0, z), Vector3(x1 - x0, height - from, WALL),
			_paint)
	_joints["north"] = _jointed(rect.position.x, rect.end.x, holes)
	_dress_face(Vector3(0, 0, 1), rect.end.y, rect.position.x, rect.end.x, _joints["north"])


func _sides() -> void:
	var south := rect.position.y + WALL / 2.0
	var spans := {"south": [Vector3(rect.get_center().x, 0.0, south), Vector3(rect.size.x, 0.0,
		WALL)], "west": [Vector3(rect.position.x + WALL / 2.0, 0.0, rect.get_center().y),
		Vector3(WALL, 0.0, rect.size.y - WALL * 2.0)], "east": [Vector3(rect.end.x - WALL / 2.0,
		0.0, rect.get_center().y), Vector3(WALL, 0.0, rect.size.y - WALL * 2.0)]}
	for face: String in spans:
		var at: Vector3 = spans[face][0]
		var size: Vector3 = spans[face][1]
		_wall(Vector3(at.x, DOCK_FLOOR / 2.0, at.z), Vector3(size.x, DOCK_FLOOR, size.z), _base)
		_wall(Vector3(at.x, (DOCK_FLOOR + height) / 2.0, at.z), Vector3(size.x,
			height - DOCK_FLOOR, size.z), _paint)
	var none: Array[Rect2] = []
	_joints["south"] = _jointed(rect.position.x, rect.end.x, none)
	_joints["west"] = _jointed(rect.position.y, rect.end.y, none)
	_joints["east"] = _jointed(rect.position.y, rect.end.y, none)
	_dress_face(Vector3(0, 0, -1), rect.position.y, rect.position.x, rect.end.x, _joints["south"])
	_dress_face(Vector3(-1, 0, 0), rect.position.x, rect.position.y, rect.end.y, _joints["west"])
	_dress_face(Vector3(1, 0, 0), rect.end.x, rect.position.y, rect.end.y, _joints["east"])


## The joints along a face from `from` to `to`: each panel as wide as it may be up to 9 m, its
## joint clear of every hole by 0.3 m, the face's ends included.
func _jointed(from: float, to: float, holes: Array[Rect2]) -> Array[float]:
	var joints: Array[float] = [from]
	var at := from
	while to - at > PANEL:
		var best := at
		var step := 0.05
		var x := at + PANEL
		while x > at + 2.0:
			var clear := true
			for hole in holes:
				clear = clear and (x < hole.position.x - JOINT_CLEAR or x > hole.end.x + JOINT_CLEAR)
			if clear:
				best = x
				break
			x -= step
		if best == at:
			break
		joints.append(snappedf(best, 0.01))
		at = best
	joints.append(to)
	return joints


## A face's sealed joints and reveal lines, on its outside at `plane` (its normal `outward`),
## from `from` to `to` along it.
func _dress_face(outward: Vector3, plane: float, from: float, to: float, joints: Array) -> void:
	var along_x := outward.z != 0.0
	var proud := 0.004
	for index in range(1, joints.size() - 1):
		var at: float = joints[index]
		var place := Vector3(at, height / 2.0, plane + outward.z * proud) if along_x \
			else Vector3(plane + outward.x * proud, height / 2.0, at)
		var size := Vector3(0.02, height, 0.01) if along_x else Vector3(0.01, height, 0.02)
		Build.box(self, place, size, _seam).name = "PanelJoint"
	for drop in REVEALS:
		var y := drop if drop > 2.0 else height - drop
		var middle := (from + to) / 2.0
		var place := Vector3(middle, y, plane + outward.z * proud) if along_x \
			else Vector3(plane + outward.x * proud, y, middle)
		var size := Vector3(to - from, 0.03, 0.01) if along_x else Vector3(0.01, 0.03, to - from)
		var line := Build.box(self, place, size, _seam)
		line.name = "Reveal"
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _roof(metal: Material) -> void:
	var membrane := Build.material(Color(0.62, 0.63, 0.62), 0.9)
	var top := height - PARAPET
	Build.box(self, Vector3(rect.get_center().x, top - DECK / 2.0, rect.get_center().y),
		Vector3(rect.size.x - WALL * 2.0, DECK, rect.size.y - WALL * 2.0), membrane).name = \
		"RoofDeck"
	for along_x: bool in [true, false]:
		for edge: float in ([rect.position.y, rect.end.y] if along_x else [rect.position.x,
				rect.end.x]):
			var inward := WALL / 2.0 * (1.0 if edge == rect.position.y or edge == rect.position.x
				else -1.0)
			var place := Vector3(rect.get_center().x, height + 0.03, edge + inward) if along_x \
				else Vector3(edge + inward, height + 0.03, rect.get_center().y)
			var size := Vector3(rect.size.x + 0.1, 0.06, WALL + 0.1) if along_x \
				else Vector3(WALL + 0.1, 0.06, rect.size.y + 0.1)
			Build.box(self, place, size, metal).name = "Coping"
	var units := Build.material(Color(0.7, 0.7, 0.68), 0.5)
	var grille := Build.material(Color(0.2, 0.2, 0.2), 0.7)
	for share: float in [0.25, 0.55, 0.8]:
		var at := Vector3(rect.position.x + rect.size.x * share, top, rect.get_center().y
			- 3.0 + share * 4.0)
		Build.box(self, at + Vector3.UP * 0.8, Vector3(2.4, 1.6, 1.5), units).name = \
			"RooftopUnit"
		Build.box(self, at + Vector3(0.0, 0.8, 0.76), Vector3(1.8, 1.0, 0.02), grille).name = \
			"RooftopGrille"
		Build.box(self, at + Vector3(0.0, 0.08, 0.0), Vector3(2.6, 0.16, 1.7), _steel).name = \
			"RooftopCurb"
	Build.box(self, Vector3(rect.position.x + 3.0, top + 0.12, rect.position.y + 3.0),
		Vector3(0.9, 0.24, 0.9), _steel).name = "RoofHatch"


func _docks() -> void:
	var seal := load(ART + "dock_seal.glb") as PackedScene
	var rubber := Build.material(Color(0.05, 0.05, 0.05), 0.9)
	var housing := Build.material(Color(0.08, 0.08, 0.08), 0.6)
	var face := rect.end.y - DOOR_SET_BACK
	for index in range(docks.size()):
		var x := docks[index]
		var holder := Node3D.new()
		holder.name = "DockDoor%d" % (index + 1)
		holder.position = Vector3(x, DOCK_FLOOR, face)
		add_child(holder)
		holder.add_child(DockDoor.instantiate())
		var shape := BoxShape3D.new()
		shape.size = Vector3(DOCK_OPENING.x, DOCK_OPENING.y, 0.2)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = Vector3(0.0, DOCK_OPENING.y / 2.0, rect.end.y - 0.1 - face)
		var body := StaticBody3D.new()
		body.name = "DoorBody"
		body.add_child(collision)
		holder.add_child(body)
		var pads := seal.instantiate() as Node3D
		pads.name = "DockSeal%d" % (index + 1)
		pads.position = Vector3(x, SEAL_BASE, rect.end.y)
		add_child(pads)
		for side: float in [-1.0, 1.0]:
			var at := Vector3(x + side * BUMPER_OFF, DOCK_FLOOR - BUMPER.y / 2.0,
				rect.end.y + BUMPER.z / 2.0)
			Build.box(self, at, BUMPER, rubber).name = "DockBumper"
			_solid(at, BUMPER)
		var lamp := Node3D.new()
		lamp.name = "DockSignal%d" % (index + 1)
		lamp.position = Vector3(x + SIGNAL_OFF, SIGNAL_HEIGHT, rect.end.y + 0.05)
		add_child(lamp)
		Build.box(lamp, Vector3.ZERO, Vector3(0.16, 0.4, 0.1), housing).name = "Housing"
		Build.box(lamp, Vector3(0.0, 0.09, 0.055), Vector3(0.1, 0.1, 0.02), _red_off).name = \
			"Red"
		Build.box(lamp, Vector3(0.0, -0.09, 0.055), Vector3(0.1, 0.1, 0.02), _green_on).name = \
			"Green"
		var number := Build.text(self, "%d" % (index + 1), Vector3(x, DOCK_FLOOR
			+ DOCK_OPENING.y + NUMBER_ABOVE, rect.end.y + 0.02), 64, Color(0.93, 0.93, 0.9))
		number.name = "DoorNumber"
		number.shaded = true
		number.double_sided = false
		_dock_light(index, x, housing)


func _dock_light(index: int, x: float, housing: Material) -> void:
	var height := DOCK_FLOOR + DOCK_OPENING.y + LIGHT_ABOVE
	Build.box(self, Vector3(x, height + 0.05, rect.end.y + 0.14), Vector3(0.42, 0.16, 0.28),
		housing).name = "DockLightFixture"
	Build.box(self, Vector3(x, height - 0.035, rect.end.y + 0.2), Vector3(0.34, 0.01, 0.18),
		Build.luminous(DOCK_LIGHT, 2.5)).name = "DockLightLens"
	var light := SpotLight3D.new()
	light.name = "DockLight%d" % (index + 1)
	add_child(light)
	light.position = Vector3(x, height, rect.end.y + 0.3)
	light.look_at(Vector3(x, 0.0, rect.end.y + 3.2), Vector3.UP)
	light.light_color = DOCK_LIGHT
	light.light_energy = 3.0
	light.spot_angle = 55.0
	light.spot_range = 10.0
	light.shadow_enabled = false


func _wall_packs() -> void:
	var housing := Build.material(Color(0.14, 0.15, 0.15), 0.5)
	var lens := Build.luminous(PACK_LIGHT, 2.5)
	var index := 0
	for dock in range(0, docks.size(), 2):
		var x := docks[dock] + SIGNAL_OFF
		var at := Vector3(x, PACK_HEIGHT, rect.end.y)
		Build.box(self, at + Vector3(0.0, 0.0, 0.13), Vector3(0.36, 0.3, 0.26), housing).name = \
			"PackHousing"
		Build.box(self, at + Vector3(0.0, -0.155, 0.17), Vector3(0.3, 0.01, 0.16), lens).name = \
			"PackLens"
		index += 1
		var light := SpotLight3D.new()
		light.name = "WallPack%d" % index
		add_child(light)
		light.position = at + Vector3(0.0, -0.17, 0.25)
		light.look_at(Vector3(x, 0.0, rect.end.y + 7.0), Vector3.UP)
		light.light_color = PACK_LIGHT
		light.light_energy = 4.0
		light.spot_angle = 60.0
		light.spot_range = 18.0
		light.shadow_enabled = false


## The steel man door at the dock floor, its landing out from it and its stair down along the
## wall toward `side`, railed both sides, the landing's open edges guarded; the fire department
## connection and the key box on the wall beside it, away from the stair.
func _man_door(door: Rect2, side: float) -> void:
	var leaf := Build.material(Color(0.42, 0.45, 0.47), 0.45)
	var x := door.get_center().x
	var face := rect.end.y
	Build.box(self, Vector3(x, DOCK_FLOOR + MAN_DOOR.y / 2.0, face - 0.06), Vector3(MAN_DOOR.x
		- 0.03, MAN_DOOR.y - 0.02, 0.045), leaf).name = "ManDoor"
	_solid(Vector3(x, DOCK_FLOOR + MAN_DOOR.y / 2.0, face - 0.06), Vector3(MAN_DOOR.x, MAN_DOOR.y,
		0.05))
	Build.box(self, Vector3(x + side * -0.36, DOCK_FLOOR + 1.0, face - 0.02), Vector3(0.12,
		0.025, 0.05), _steel).name = "DoorLever"
	for edge: float in [-1.0, 1.0]:
		Build.box(self, Vector3(x + edge * (MAN_DOOR.x / 2.0 + 0.03), DOCK_FLOOR + MAN_DOOR.y
			/ 2.0, face + 0.01), Vector3(0.06, MAN_DOOR.y + 0.06, 0.04), _steel).name = "DoorFrame"
	Build.box(self, Vector3(x, DOCK_FLOOR + MAN_DOOR.y + 0.03, face + 0.01), Vector3(MAN_DOOR.x
		+ 0.12, 0.06, 0.04), _steel).name = "DoorFrame"
	var concrete := _surface(Color(0.6, 0.6, 0.58))
	var pad := Vector3(x, DOCK_FLOOR / 2.0, face + LANDING.y / 2.0)
	Build.box(self, pad, Vector3(LANDING.x, DOCK_FLOOR, LANDING.y), concrete).name = "Landing"
	_solid(pad, Vector3(LANDING.x, DOCK_FLOOR, LANDING.y))
	var rise := DOCK_FLOOR / RISERS
	var start := x + side * LANDING.x / 2.0
	var depth := Vector2(face, face + STAIR_WIDTH)
	for step in range(1, RISERS):
		var top := DOCK_FLOOR - rise * step
		var near := start + side * TREAD * (step - 1)
		var centre := Vector3(near + side * TREAD / 2.0, top / 2.0, (depth.x + depth.y) / 2.0)
		var size := Vector3(TREAD, top, STAIR_WIDTH)
		Build.box(self, centre, size, concrete).name = "Step"
		_solid(centre, size)
	var run := TREAD * (RISERS - 1)
	var foot := start + side * run
	_rail_line = func(at_x: float) -> float:
		var along := clampf((at_x - start) * side, 0.0, run)
		return DOCK_FLOOR - along / run * (DOCK_FLOOR - rise)
	var slope := atan2(DOCK_FLOOR - rise, run)
	for z: float in [depth.x + 0.06, depth.y - 0.04]:
		var middle := Vector3((start + foot) / 2.0, (float(_rail_line.call(start))
			+ float(_rail_line.call(foot))) / 2.0 + HANDRAIL - 0.025, z)
		var rail := Build.box(self, middle, Vector3(run / cos(slope) + 0.3, 0.05, 0.05), _steel)
		rail.rotation.z = -slope * side
		rail.name = "Handrail"
		_rails.append(rail)
		for at_x: float in [start, foot]:
			var post_top := float(_rail_line.call(at_x)) + HANDRAIL
			var floor_y := DOCK_FLOOR if at_x == start else rise
			Build.box(self, Vector3(at_x, (floor_y + post_top) / 2.0, z), Vector3(0.04,
				post_top - floor_y, 0.04), _steel).name = "RailPost"
	var open_end := x - side * LANDING.x / 2.0
	var outer := face + LANDING.y
	var beyond := LANDING.y - STAIR_WIDTH
	for run_piece: Array in [[Vector3(x, 0.0, outer - 0.03), Vector3(LANDING.x, 0.0, 0.04)],
			[Vector3(open_end + side * 0.03, 0.0, face + LANDING.y / 2.0), Vector3(0.04, 0.0,
			LANDING.y)], [Vector3(start - side * 0.03, 0.0, outer - beyond / 2.0), Vector3(0.04,
			0.0, beyond)]]:
		var at: Vector3 = run_piece[0]
		var size: Vector3 = run_piece[1]
		for y: float in [DOCK_FLOOR + GUARD - 0.025, DOCK_FLOOR + GUARD / 2.0]:
			Build.box(self, Vector3(at.x, y, at.z), Vector3(size.x, 0.05, size.z), _steel).name = \
				"Guard"
	for post: Vector2 in [Vector2(open_end + side * 0.03, outer - 0.03), Vector2(x + side
			* (LANDING.x / 2.0 - 0.03), outer - 0.03), Vector2(open_end + side * 0.03, face
			+ 0.03)]:
		Build.box(self, Vector3(post.x, DOCK_FLOOR + GUARD / 2.0, post.y), Vector3(0.05, GUARD,
			0.05), _steel).name = "GuardPost"
	var red := Build.material(Color(0.62, 0.06, 0.05), 0.5)
	var brass := Build.material(Color(0.7, 0.55, 0.25), 0.35)
	brass.metallic = 0.8
	var beside := open_end - side * 0.7
	Build.box(self, Vector3(beside, 0.9, face + 0.02), Vector3(0.5, 0.3, 0.04), red).name = \
		"FireConnectionPlate"
	for offset: float in [-0.12, 0.12]:
		var inlet := Build.cylinder(self, Vector3(beside + offset, 0.9, face + 0.1), 0.045, 0.14,
			brass)
		inlet.rotation.x = PI / 2.0
		inlet.name = "FireConnectionInlet"
	Build.box(self, Vector3(beside, 1.35, face + 0.012), Vector3(0.3, 0.2, 0.012),
		Build.material(Color(0.9, 0.9, 0.87), 0.6)).name = "FireConnectionSignPlate"
	var sign := Build.text(self, "FDC", Vector3(beside, 1.35, face + 0.02), 22, red.albedo_color)
	sign.name = "FireConnectionSign"
	sign.shaded = true
	sign.double_sided = false
	Build.box(self, Vector3(beside, 1.75, face + 0.05), Vector3(0.18, 0.2, 0.1), Build.material(
		Color(0.08, 0.08, 0.08), 0.5)).name = "KeyBox"


## Scuppers through the parapet at the roof's level, each with its downpipe to a splash block:
## two on the back wall, one on each side near the back.
func _drains() -> void:
	var top := height - PARAPET
	var places: Array[Array] = [
		[Vector3(rect.position.x + rect.size.x * 0.25, 0.0, rect.position.y), Vector3.FORWARD],
		[Vector3(rect.position.x + rect.size.x * 0.75, 0.0, rect.position.y), Vector3.FORWARD],
		[Vector3(rect.position.x, 0.0, rect.position.y + 4.0), Vector3.LEFT],
		[Vector3(rect.end.x, 0.0, rect.position.y + 4.0), Vector3.RIGHT]]
	var block := Build.material(Color(0.5, 0.5, 0.48), 0.9)
	for place in places:
		var at: Vector3 = place[0]
		var out: Vector3 = place[1]
		var head := at + out * 0.15 + Vector3.UP * (top - 0.1)
		Build.box(self, head, Vector3(0.4, 0.35, 0.4), _steel).name = "Scupper"
		var low := 0.15
		var high := top - 0.27
		Build.cylinder(self, at + out * 0.15 + Vector3.UP * (low + high) / 2.0, PIPE_RADIUS,
			high - low, _steel).name = "Downpipe"
		Build.box(self, at + out * 0.55 + Vector3.UP * 0.03, Vector3(0.35, 0.06, 0.7)
			if out.z != 0.0 else Vector3(0.7, 0.06, 0.35), block).name = "SplashBlock"


func _wall(centre: Vector3, size: Vector3, surface: Material) -> void:
	Build.box(self, centre, size, surface).name = "Wall"
	_solid(centre, size)


func _solid(centre: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = centre
	_body.add_child(collision)


func _surface(tint: Color) -> ORMMaterial3D:
	var material := ORMMaterial3D.new()
	var path := TEXTURES + "concrete_wall_006/concrete_wall_006_%s_2k.jpg"
	material.albedo_texture = load(path % "diff")
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(path % "nor_gl")
	material.orm_texture = load(path % "arm")
	material.uv1_scale = Vector3.ONE / 2.5
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	return material
