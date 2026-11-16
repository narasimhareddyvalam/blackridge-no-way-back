extends Node3D
## The transfer shed's safety and work kit (docs/PHASE_BRIEF.md, step 5 of #253, part F; the
## author's choices, #300), as a working dock's: a second exit for people in the west wall (IBC
## 1006.2.1: 32 people need two), its steel door with a push bar, its landing and stair down
## outside; a lit EXIT sign over each exit and hung over the cross-aisle pointing the nearer way
## (OSHA 1910.37(b): 6 in letters); battery emergency lights by the exits and over the dock; eight
## Class A extinguishers on their hangers, tops 1.45 m up, each with its sign, so that no point of
## the floor lies more than 75 ft of travel from one (1910.157(d)(2), NFPA 10); the electric
## forklift's charger on the office's back wall in a hatched bay, NO SMOKING, an eyewash 5 m off in
## a clear line (ANSI Z358.1: 10 s) and a spill kit; a convex mirror at every aisle's mouth; the
## first-aid cabinet by the side door; a baler, its bales, bins and hand trucks in the strip, a
## stretch-wrap stand by dock 5's loads; the walkway's crossing over the cross-aisle and the
## speed-limit and forklift-traffic signs. Parts by `tools/art/build_shed_kit.py`, signs by
## `tools/art/make_shed_signs.py`. `placements()`, `exits()`, `signs()` and `solids()` hand out
## what was placed, since a headless run keeps no multi-mesh transforms.

const Build = preload("res://shared/components/mesh_builder.gd")
const Racking := preload("racking.gd")
const Parts := preload("res://features/environments/industrial_loop/art/fitout/shed_kit.glb")
const ART := "res://features/environments/industrial_loop/art/fitout/"
const HAZARD := "res://features/environments/industrial_loop/art/depot/hazard_stripes.png"
const FLOOR := 1.3
const LANE_FLOOR := 0.02
const WEST_WALL := -89.75
const OUTER_WEST := -90.0
const EAST_WALL := -40.25
const FACE := 19.75
const OFFICE_BACK := 12.0
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0, -47.75]
## The exits: the side door (`dock_access.gd`) and the west exit (`transfer_building.gd`).
const SIDE_DOOR := Vector3(-40.0, LANE_FLOOR, 17.475)
const WEST_EXIT := Vector3(WEST_WALL, FLOOR, 3.975)
const DOOR_TALL := 2.13
const DOOR_WIDE := 0.95
const EXIT_LETTERS := 6 * 0.0254
const EXIT_FACE := Vector2(0.33, 0.2)
const SIGN_ABOVE := 0.24
## Extinguishers: 0.5 m tall, their middles 1.2 m up (tops 1.45 m, bottoms 0.95 m).
const EXTINGUISHER_TALL := 0.5
const EXTINGUISHER_UP := 1.2
const OFF_WALL := 0.08
const SIGN_SIZE := Vector2(0.2, 0.25)
const MIRROR_DIAMETER := 24 * 0.0254
const MIRROR_UP := 2.9
const MIRROR_OUT := 0.35
const RACK_END := 8.24
const CHARGER := Vector3(-86.5, FLOOR + 1.1, OFFICE_BACK)
const CHARGING_BAY := Rect2(-88.5, 8.6, 4.0, 3.38)
const EYEWASH := Vector3(WEST_WALL, FLOOR + 1.0, 7.8)
const SPILL_KIT := Vector2(-88.9, 9.4)
const FIRST_AID := Vector3(EAST_WALL, LANE_FLOOR + 1.4, 13.3)
const BALER := Vector2(-89.3, -6.0)
const BALES: Array[Vector2] = [Vector2(-88.9, -3.6), Vector2(-87.6, -3.6)]
const BINS: Array[Vector2] = [Vector2(-89.3, -8.5), Vector2(-88.6, -8.6)]
const HAND_TRUCKS: Array[Vector2] = [Vector2(-89.55, -1.6), Vector2(-89.55, -2.2)]
const WRAP_STAND := Vector2(-66.3, 15.8)
const CROSSING_X := -46.0
const CROSSING_ZS: Array[float] = [10.4, 11.2, 12.0, 12.8, 13.6]
const CROSSING_BAR := Vector2(1.2, 0.4)
## The strip's lights, as the aisles' (`racking.gd`): three linear high-bays down its middle.
const STRIP_LIGHTS: Array[Vector2] = [Vector2(-86.0, -5.5), Vector2(-86.0, 1.5),
	Vector2(-86.0, 8.5)]
const EXTERIOR := {"landing": Rect2(-91.25, 3.2, 1.25, 1.55), "risers": 6, "tread": 0.28,
	"width": 1.0}

var _meshes := {}
var _placed := {}
var _signs := []
var _solids: Array[Rect2] = []
var _body: StaticBody3D
var _steel: StandardMaterial3D


func build() -> void:
	var parts := Parts.instantiate() as Node3D
	for found in parts.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	parts.free()
	_body = StaticBody3D.new()
	_body.name = "KitBody"
	add_child(_body)
	_steel = Build.material(Color(0.6, 0.61, 0.62), 0.4)
	_steel.metallic = 0.8
	_strip_lights()
	_west_exit()
	_exit_signs()
	_emergency_lights()
	_extinguishers()
	_charging()
	_mirrors()
	_side_door()
	_floor_kit()
	_crossing()


func placements(label: String) -> Array:
	return (_placed.get(label, []) as Array).duplicate()


## Each exit for people: the middle of its doorway at its floor, and its sign's middle.
func exits() -> Array:
	return [{"door": SIDE_DOOR, "sign": SIDE_DOOR + Vector3(-0.31, DOOR_TALL + SIGN_ABOVE, 0.0)},
		{"door": WEST_EXIT, "sign": WEST_EXIT + Vector3(0.06, DOOR_TALL + SIGN_ABOVE, 0.0)}]


## Each sign: its `kind` and its `centre`.
func signs() -> Array:
	return _signs.duplicate()


## The floor the kit stands on, as rectangles (x, z).
func solids() -> Array[Rect2]:
	return _solids.duplicate()


func _strip_lights() -> void:
	var services := Racking.Services.instantiate() as Node3D
	for found in services.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	services.free()
	var lens := StandardMaterial3D.new()
	lens.albedo_color = Racking.LIGHT_COLOUR
	lens.emission_enabled = true
	lens.emission = Racking.LIGHT_COLOUR
	lens.emission_energy_multiplier = 3.0
	var fixture := (_meshes["LinearHighBay"] as Mesh).duplicate() as ArrayMesh
	if fixture != null and fixture.get_surface_count() > 1:
		fixture.surface_set_material(1, lens)
		_meshes["LinearHighBay"] = fixture
	var fixtures: Array[Transform3D] = []
	var chains: Array[Transform3D] = []
	for index in range(STRIP_LIGHTS.size()):
		var at := Vector3(STRIP_LIGHTS[index].x, Racking.LIGHT_AT, STRIP_LIGHTS[index].y)
		fixtures.append(Transform3D(Basis.IDENTITY, at))
		var hang := Racking.underside(at.z) - (at.y + 0.08)
		for end: float in [-0.5, 0.5]:
			chains.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, hang, 1.0)),
				at + Vector3(0.0, 0.08, end)))
		var light := SpotLight3D.new()
		light.name = "StripLight%d" % (index + 1)
		add_child(light)
		light.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), at
			- Vector3(0.0, 0.02, 0.0))
		light.light_color = Racking.LIGHT_COLOUR
		light.light_energy = 4.5
		light.spot_angle = 60.0
		light.spot_range = Racking.LIGHT_REACH
		light.shadow_enabled = false
	_many("StripFixtures", "LinearHighBay", fixtures)
	_many("StripChains", "FixtureChain", chains)


func _west_exit() -> void:
	var door := Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(WEST_WALL - 0.1, FLOOR,
		WEST_EXIT.z))
	_many("ExitDoors", "ExitDoor", [door] as Array[Transform3D])
	_solid(Vector3(WEST_WALL - 0.1, FLOOR + DOOR_TALL / 2.0, WEST_EXIT.z), Vector3(0.05,
		DOOR_TALL, DOOR_WIDE))
	var landing: Rect2 = EXTERIOR["landing"]
	var top := FLOOR - 0.02
	_box(Vector3(landing.get_center().x, top - 0.03, landing.get_center().y), Vector3(
		landing.size.x, 0.06, landing.size.y), true)
	var risers: int = EXTERIOR["risers"]
	var rise := top / risers
	var tread: float = EXTERIOR["tread"]
	var x := OUTER_WEST - 0.1 - float(EXTERIOR["width"]) / 2.0
	for step in range(risers - 1):
		var y := top - rise * (step + 1)
		var z := landing.position.y - tread * (step + 0.5)
		_box(Vector3(x, y - 0.02, z), Vector3(EXTERIOR["width"], 0.04, tread), true)
	var run := tread * (risers - 1)
	for side: float in [-1.0, 1.0]:
		var rail_x := x + side * float(EXTERIOR["width"]) / 2.0
		var low := Vector3(rail_x, 0.9 + rise, landing.position.y - run)
		var high := Vector3(rail_x, top + 0.9, landing.position.y)
		var rail := Build.box(self, (low + high) / 2.0, Vector3(0.04, 0.04, low.distance_to(high)),
			_steel)
		rail.look_at_from_position((low + high) / 2.0, high, Vector3.UP)
		rail.name = "ExitStairRail"
	_box(Vector3(landing.position.x, top + 0.45, landing.get_center().y), Vector3(0.04, 0.9,
		landing.size.y), false)


func _exit_signs() -> void:
	var housings: Array[Transform3D] = []
	var to_west := Basis(Vector3.UP, -PI / 2.0)
	var to_east := Basis(Vector3.UP, PI / 2.0)
	var faces: Array[Array] = [
		[Transform3D(to_east, Vector3(EAST_WALL, SIDE_DOOR.y + DOOR_TALL + SIGN_ABOVE,
			SIDE_DOOR.z)), "exit"],
		[Transform3D(to_west, Vector3(WEST_WALL, WEST_EXIT.y + DOOR_TALL + SIGN_ABOVE,
			WEST_EXIT.z)), "exit"]]
	for hung: Array in [[-70.0, "exit_left", "exit_right"], [-58.0, "exit_right", "exit_left"]]:
		var at := Vector3(hung[0], FLOOR + 3.0, 12.0)
		faces.append([Transform3D(Basis(Vector3.UP, PI), at), hung[1]])
		faces.append([Transform3D(Basis.IDENTITY, at), hung[2]])
		var chord := Racking.underside(at.z) - 1.25
		var rod := Build.box(self, Vector3(at.x, (at.y + 0.18 + chord) / 2.0, at.z), Vector3(0.01,
			chord - at.y - 0.18, 0.01), _steel)
		rod.name = "SignRod"
	var lit := 1
	for face: Array in faces:
		var placed: Transform3D = face[0]
		housings.append(placed)
		var plate := MeshInstance3D.new()
		plate.name = "ExitSign%d" % lit
		lit += 1
		var quad := QuadMesh.new()
		quad.size = EXIT_FACE
		plate.mesh = quad
		var paint := StandardMaterial3D.new()
		paint.albedo_texture = load(ART + "%s.png" % face[1]) as Texture2D
		paint.emission_enabled = true
		paint.emission_texture = paint.albedo_texture
		paint.emission_energy_multiplier = 1.4
		plate.material_override = paint
		add_child(plate)
		plate.global_transform = Transform3D(placed.basis * Basis(Vector3.UP, PI),
			placed.origin + placed.basis * Vector3(0.0, 0.0, -0.061))
	_many("ExitSigns", "ExitSign", housings)


func _emergency_lights() -> void:
	var lights: Array[Transform3D] = [
		Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(EAST_WALL, 2.85, 16.8)),
		Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(WEST_WALL, FLOOR + 2.7, 4.9)),
		Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(OUTER_WEST, FLOOR + 2.5, WEST_EXIT.z)),
		Transform3D(Basis.IDENTITY, Vector3(-66.0, FLOOR + 3.4, FACE)),
		Transform3D(Basis.IDENTITY, Vector3(-54.0, FLOOR + 3.4, FACE)),
		Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(EAST_WALL, 3.0, 4.0)),
		Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(WEST_WALL, FLOOR + 2.7, -4.0))]
	_many("EmergencyLights", "EmergencyLight", lights)


func _extinguishers() -> void:
	var found: Array[Transform3D] = []
	var to_east := Basis(Vector3.UP, -PI / 2.0)
	var to_west := Basis(Vector3.UP, PI / 2.0)
	found.append(Transform3D(to_east, Vector3(WEST_WALL + OFF_WALL, FLOOR + EXTINGUISHER_UP, 6.6)))
	var rows := Racking.rows(Racking.frame_lines())
	for index: int in [1, 3, 5]:
		var row: Vector2 = rows[index]
		found.append(Transform3D(Basis(Vector3.UP, PI), Vector3((row.x + row.y) / 2.0,
			FLOOR + EXTINGUISHER_UP, RACK_END + OFF_WALL)))
	for dock: float in [DOCKS[1], DOCKS[5]]:
		found.append(Transform3D(Basis.IDENTITY, Vector3(dock + 2.35, FLOOR + EXTINGUISHER_UP,
			FACE - OFF_WALL)))
	for z: float in [18.6, 0.0]:
		found.append(Transform3D(to_west, Vector3(EAST_WALL - OFF_WALL, LANE_FLOOR
			+ EXTINGUISHER_UP, z)))
	_many("Extinguishers", "Extinguisher", found)
	var sheet := load(ART + "extinguisher_sign.png") as Texture2D
	for placed in found:
		var front := placed.basis * Vector3(0.0, 0.0, -1.0)
		var at := placed.origin + Vector3.UP * (EXTINGUISHER_TALL / 2.0 + 0.3) - front * 0.07
		_sign("extinguisher", sheet, SIGN_SIZE, Transform3D(placed.basis * Basis(Vector3.UP, PI),
			at))


func _charging() -> void:
	var facing := Basis.IDENTITY
	_many("Chargers", "Charger", [Transform3D(facing, CHARGER)] as Array[Transform3D])
	_many("Eyewash", "Eyewash", [Transform3D(Basis(Vector3.UP, -PI / 2.0), EYEWASH)]
		as Array[Transform3D])
	_many("SpillKits", "SpillKit", [Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(
		SPILL_KIT.x, FLOOR, SPILL_KIT.y))] as Array[Transform3D])
	_solids.append(Rect2(SPILL_KIT - Vector2(0.32, 0.32), Vector2(0.64, 0.64)))
	var hatch := StandardMaterial3D.new()
	hatch.albedo_texture = load(HAZARD) as Texture2D
	hatch.roughness = 0.7
	hatch.uv1_scale = Vector3(8.0, 1.0, 1.0)
	var marks: Array[Transform3D] = []
	var bay := CHARGING_BAY
	for edge: Array in [[Vector2(bay.get_center().x, bay.position.y), Vector2(bay.size.x, 0.1)],
			[Vector2(bay.position.x, bay.get_center().y), Vector2(0.1, bay.size.y)],
			[Vector2(bay.end.x, bay.get_center().y), Vector2(0.1, bay.size.y)]]:
		var at: Vector2 = edge[0]
		var size: Vector2 = edge[1]
		var strip := Build.box(self, Vector3(at.x, FLOOR + 0.003, at.y), Vector3(size.x, 0.004,
			size.y), hatch)
		strip.name = "ChargingMark"
		marks.append(strip.global_transform)
	_placed["ChargingMarks"] = marks
	_sign("no_smoking", load(ART + "no_smoking.png") as Texture2D, Vector2(0.3, 0.375),
		Transform3D(Basis(Vector3.UP, PI), Vector3(-84.9, FLOOR + 1.9, OFFICE_BACK - 0.005)))
	_sign("eyewash", load(ART + "eyewash_sign.png") as Texture2D, SIGN_SIZE,
		Transform3D(Basis(Vector3.UP, PI / 2.0), EYEWASH + Vector3(0.005, 0.9, 0.0)))


func _mirrors() -> void:
	var rows := Racking.rows(Racking.frame_lines())
	var found: Array[Transform3D] = []
	for index in range(rows.size()):
		var last := index == rows.size() - 1
		var post := rows[index].y - Racking.POST / 2.0 if last else rows[index + 1].x \
			+ Racking.POST / 2.0
		var facing := Vector3(1.0 if last else -1.0, 0.0, 1.0).normalized()
		var at := Vector3(post, FLOOR + (2.95 if last else MIRROR_UP), RACK_END) + facing \
			* MIRROR_OUT
		found.append(Transform3D(Basis.looking_at(-facing), at))
	_many("Mirrors", "Mirror", found)


func _side_door() -> void:
	var to_west := Basis(Vector3.UP, PI / 2.0)
	_many("FirstAid", "FirstAidCabinet", [Transform3D(to_west, FIRST_AID)] as Array[Transform3D])
	_sign("first_aid", load(ART + "first_aid_sign.png") as Texture2D, SIGN_SIZE,
		Transform3D(Basis(Vector3.UP, -PI / 2.0), FIRST_AID + Vector3(-0.005, 0.42, 0.0)))


func _floor_kit() -> void:
	var west := Basis(Vector3.UP, -PI / 2.0)
	_many("Balers", "Baler", [Transform3D(Basis.IDENTITY, Vector3(BALER.x, FLOOR, BALER.y))]
		as Array[Transform3D])
	_solids.append(Rect2(BALER - Vector2(0.45, 0.75), Vector2(0.9, 1.5)))
	var bales: Array[Transform3D] = []
	for at in BALES:
		bales.append(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(at.x, FLOOR, at.y)))
		_solids.append(Rect2(at - Vector2(0.38, 0.6), Vector2(0.76, 1.2)))
	_many("Bales", "Bale", bales)
	var bins: Array[Transform3D] = []
	for at in BINS:
		bins.append(Transform3D(Basis.IDENTITY, Vector3(at.x, FLOOR, at.y)))
		_solids.append(Rect2(at - Vector2(0.3, 0.3), Vector2(0.6, 0.6)))
	_many("Bins", "Bin", bins)
	var trucks: Array[Transform3D] = []
	for at in HAND_TRUCKS:
		trucks.append(Transform3D(west * Basis(Vector3.RIGHT, -0.12), Vector3(at.x, FLOOR, at.y)))
		_solids.append(Rect2(at - Vector2(0.2, 0.25), Vector2(0.4, 0.5)))
	_many("HandTrucks", "HandTruck", trucks)
	_many("WrapStands", "WrapStand", [Transform3D(Basis.IDENTITY, Vector3(WRAP_STAND.x, FLOOR,
		WRAP_STAND.y))] as Array[Transform3D])
	_solids.append(Rect2(WRAP_STAND - Vector2(0.25, 0.25), Vector2(0.5, 0.5)))
	for rect in _solids:
		_solid(Vector3(rect.get_center().x, FLOOR + 0.6, rect.get_center().y), Vector3(rect.size.x,
			1.2, rect.size.y))


func _crossing() -> void:
	var white := Build.material(Color(0.95, 0.95, 0.95), 0.6)
	var bars: Array[Transform3D] = []
	for z in CROSSING_ZS:
		var bar := Build.box(self, Vector3(CROSSING_X, FLOOR + 0.0035, z), Vector3(CROSSING_BAR.x,
			0.004, CROSSING_BAR.y), white)
		bar.name = "CrossingBar"
		bars.append(bar.global_transform)
	_placed["CrossingBars"] = bars
	var post := Vector3(-45.1, FLOOR, 9.6)
	_box(post + Vector3(0.0, 0.8, 0.0), Vector3(0.05, 1.6, 0.05), false)
	_sign("forklifts", load(ART + "forklift_sign.png") as Texture2D, Vector2(0.3, 0.375),
		Transform3D(Basis.IDENTITY, post + Vector3(0.0, 1.85, 0.03)))
	_sign("speed", load(ART + "speed_limit.png") as Texture2D, Vector2(0.3, 0.375),
		Transform3D(Basis.IDENTITY, Vector3(-81.3, FLOOR + 2.4, RACK_END + 0.03)))
	_sign("speed", load(ART + "speed_limit.png") as Texture2D, Vector2(0.3, 0.375),
		Transform3D(Basis(Vector3.UP, PI), Vector3(-72.0, FLOOR + 3.9, FACE - 0.005)))


func _sign(kind: String, texture: Texture2D, size: Vector2, at: Transform3D) -> void:
	var plate := MeshInstance3D.new()
	plate.name = "Sign_" + kind
	var quad := QuadMesh.new()
	quad.size = size
	plate.mesh = quad
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = texture
	paint.roughness = 0.7
	plate.material_override = paint
	add_child(plate)
	plate.global_transform = at
	_signs.append({"kind": kind, "centre": at.origin})


func _box(at: Vector3, size: Vector3, solid: bool) -> void:
	Build.box(self, at, size, _steel).name = "ExitStair"
	if solid:
		_solid(at, size)


func _solid(at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_body.add_child(collision)
	collision.global_position = at


func _many(label: String, part: String, placed: Array[Transform3D]) -> void:
	_placed[label] = placed
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _meshes[part]
	multi.instance_count = placed.size()
	for index in range(placed.size()):
		multi.set_instance_transform(index, global_transform.affine_inverse() * placed[index])
	var many := MultiMeshInstance3D.new()
	many.name = label
	many.multimesh = multi
	add_child(many)
