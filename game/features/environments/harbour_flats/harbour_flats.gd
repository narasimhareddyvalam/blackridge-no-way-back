extends Node3D
## The harbour flats (Mission 3's step 2, docs/PHASE_BRIEF.md, 2026-11-21, #359), after Port
## Angeles, a small Pacific Northwest harbour (Commons: its waterfront, its airfield's fence and
## treeline): east of the loop, past the rim, a coastal strip at road level behind concrete quay
## walls, the sea 2.6 m below their edge out to the horizon. The east road leaves the loop at its
## east end and runs through the rim in a cut (`hill_terrain.gd`'s `_cut`) to the coastal road,
## which runs north and south along the flats; both are the loop road's asphalt and markings, lit by
## the valley road's lamps. The rim comes down to the flats in an embankment from the terrain's own
## heights at its edge, so no gap shows. Later steps build the waterfront and the airfield on it.

const Build = preload("res://shared/components/mesh_builder.gd")
const Waterfront = preload("waterfront.gd")
const Airfield = preload("airfield.gd")
const ROAD_PLACE_SCALE := 8.0
## The east road, from the loop's east end to the coastal road, and the coastal road.
const EAST_ROAD: Array[Vector3] = [Vector3(609.0, 0.0, 151.7), Vector3(726.0, 0.0, 151.7)]
const COASTAL: Array[Vector3] = [Vector3(726.0, 0.0, 312.0), Vector3(726.0, 0.0, -282.0)]
const ROAD_HALF := 3.3
## The land's outline (x, z), clockwise from its north-west corner; its west side meets the rim.
const OUTLINE: Array[Vector2] = [Vector2(660.0, -300.0), Vector2(1300.0, -300.0),
	Vector2(1300.0, 60.0), Vector2(1000.0, 60.0), Vector2(1000.0, 320.0), Vector2(660.0, 320.0)]
const LAND_TOP := -0.12
const SEA_LEVEL := -2.6
const SEA_REACH := 4000.0
const WALL_DEEP := 1.5
const KERB := Vector2(0.4, 0.25)
## The embankment from the terrain's edge at x 660 down to the flats at RIM_TOE, its z extent.
const RIM_EDGE := 659.9
const RIM_TOE := 718.0
const RIM_FROM := -318.0
const RIM_TO := 328.0
const RIM_STEP := 4.0
const RIM_ROWS := 8
## The road's cut through the rim is flat this far either side of the east road (industrial_loop.gd's
## EAST_CUT half width): the embankment gets a column on the terrain's last flat grid line at each
## edge (TERRAIN_SPACING, hill_terrain.gd's SPACING: z 148 and 156), so across the road it lies flat
## at the road's height. On the RIM_STEP grid alone, its columns either side of the road reached up
## the cut's banks, and the slope between them stood up to 13 cm above the road at the embankment's
## edge, where a van driving east caught and stopped at x 657 (found filming Mission 3, #448).
const CUT_FLOOR_HALF := 5.0
const TERRAIN_SPACING := 2.0
## The bluff's trees (the forest's own Pacific Northwest kinds), every BANK_STEP along it.
const BANK_KINDS: Array[String] = ["mountain_hemlock", "western_red_cedar", "young_fir",
	"red_alder"]
const BANK_STEP := 5.0
const BANK_DEPTH := 3
## The cut's banks outside the forest's own area, wooded as the rim is.
const CUT_BANKS := Rect2(636.0, 151.7 - 36.0, 30.0, 72.0)
const BANK_SINK := 0.5
const BANK_CLEAR := 14.0
const BANK_RANGE := 420.0
## The harbour mouth's pile beacons, as charted: red to the right coming in from sea ("red right
## returning", IALA B), green to the left; each flashing once every BEACON_PERIOD seconds.
const BEACONS: Array = [[Vector3(1085.0, 0.0, 250.0), Color(1.0, 0.1, 0.06)],
	[Vector3(1085.0, 0.0, 170.0), Color(0.1, 1.0, 0.3)]]
const BEACON_PERIOD := 4.0
const BEACON_FLASH := 0.5
const LAMP_EVERY := 40.0
const LAMP_OUT := ROAD_HALF + 1.6
## Where the flats count as playable, the cut through the rim with them.
const AREA := Rect2(630.0, -300.0, 670.0, 620.0)

var sea: MeshInstance3D
## The container terminal on the flats (Mission 3's step 3).
var waterfront: Node3D
## The airfield on the flats (Mission 3's step 5).
var airfield: Node3D
var sea_reach := SEA_REACH
var lamps: Array[Node3D] = []
var area := AREA
var _body: StaticBody3D
var _water: StandardMaterial3D
var _drift := Vector2.ZERO
var _beacons: Array[OmniLight3D] = []
var _beacon_glass: Array[StandardMaterial3D] = []
var _clock := 0.0


## Builds the flats: `terrain` for the rim's heights, `asphalt` the loop road's material, `ground`
## the hills', `concrete` the quay walls'; `lamp_post` places one of the valley road's lamps
## (`(at: Vector3, heading: float) -> Node3D`).
func build(terrain: Node3D, asphalt: Material, ground: Material, concrete: Material,
		lamp_post: Callable) -> void:
	_body = StaticBody3D.new()
	_body.name = "FlatsBody"
	add_child(_body)
	_land(ground)
	_embankment(terrain, ground)
	_quay_walls(concrete)
	_road(EAST_ROAD, asphalt, "EastRoad")
	_road(COASTAL, asphalt, "CoastalRoad")
	_lamps(lamp_post)
	_sea()
	_beacon_piles(concrete)


func _land(ground: Material) -> void:
	var polygon := PackedVector2Array(OUTLINE)
	polygon[0].x = RIM_TOE - 2.0
	polygon[polygon.size() - 1].x = RIM_TOE - 2.0
	var triangles := Geometry2D.triangulate_polygon(polygon)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for index in triangles:
		var at := Vector3(polygon[index].x, LAND_TOP, polygon[index].y)
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(at.x, at.z))
		tool.add_vertex(at)
		faces.append(at)
	var land := MeshInstance3D.new()
	land.name = "Land"
	land.mesh = tool.commit()
	land.material_override = ground
	add_child(land)
	_solid(faces, true)


## From the terrain's last heights at x 660 down to the flats, in a curve as a hill's foot is.
func _embankment(terrain: Node3D, ground: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var edges: Array[float] = [ceilf((EAST_ROAD[0].z - CUT_FLOOR_HALF) / TERRAIN_SPACING)
		* TERRAIN_SPACING, floorf((EAST_ROAD[0].z + CUT_FLOOR_HALF) / TERRAIN_SPACING) * TERRAIN_SPACING]
	var lines: Array[float] = []
	for step in range(int((RIM_TO - RIM_FROM) / RIM_STEP) + 1):
		var along := RIM_FROM + step * RIM_STEP
		if absf(along - edges[0]) > 0.5 and absf(along - edges[1]) > 0.5:
			lines.append(along)
	lines.append_array(edges)
	lines.sort()
	var columns := lines.size() - 1
	var grid: Array[PackedVector3Array] = []
	for column in range(columns + 1):
		var z := lines[column]
		var top: float = terrain.call("height_at", RIM_EDGE, z)
		var line := PackedVector3Array()
		for row in range(RIM_ROWS + 1):
			var share := float(row) / RIM_ROWS
			var x := lerpf(RIM_EDGE - 0.4, RIM_TOE, share)
			var y := lerpf(top, LAND_TOP, smoothstep(0.0, 1.0, share))
			line.append(Vector3(x, y, z))
		grid.append(line)
	for column in range(columns):
		for row in range(RIM_ROWS):
			var a := grid[column][row]
			var b := grid[column][row + 1]
			var c := grid[column + 1][row]
			var d := grid[column + 1][row + 1]
			for at in [a, c, b, b, c, d]:
				tool.set_uv(Vector2(at.x, at.z))
				tool.add_vertex(at)
				faces.append(at)
	tool.generate_normals()
	var bank := MeshInstance3D.new()
	bank.name = "RimEmbankment"
	bank.mesh = tool.commit()
	bank.material_override = ground
	add_child(bank)
	_solid(faces, true)


## Concrete walls from the land's edge down into the sea along every side but the rim's, a kerb
## along their top.
func _quay_walls(concrete: Material) -> void:
	for index in range(1, OUTLINE.size() - 1):
		var a := OUTLINE[index]
		var b := OUTLINE[(index + 1) % OUTLINE.size()]
		_wall(a, b, concrete)
	_wall(OUTLINE[0], OUTLINE[1], concrete)


func _wall(a: Vector2, b: Vector2, concrete: Material) -> void:
	var middle := (a + b) / 2.0
	var length := a.distance_to(b)
	var along := Vector3(b.x - a.x, 0.0, b.y - a.y).normalized()
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	var tall := LAND_TOP - SEA_LEVEL + WALL_DEEP
	var face := Build.box(self, Vector3(middle.x, LAND_TOP - tall / 2.0, middle.y),
		Vector3(length, tall, 0.6), concrete)
	face.basis = basis
	face.name = "QuayWall"
	var kerb := Build.box(self, Vector3(middle.x, LAND_TOP + KERB.y / 2.0, middle.y),
		Vector3(length, KERB.y, KERB.x), concrete)
	kerb.basis = basis
	kerb.name = "QuayKerb"
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, KERB.y + 0.4, KERB.x)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(basis, Vector3(middle.x, LAND_TOP + (KERB.y + 0.4) / 2.0,
		middle.y))
	_body.add_child(collision)


## A road strip along `points`, ROAD_HALF either side, the loop road's material and markings.
func _road(points: Array[Vector3], asphalt: Material, label: String) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var place := ROAD_HALF / ROAD_PLACE_SCALE
	for leg in range(points.size() - 1):
		var a := points[leg]
		var b := points[leg + 1]
		var right := (b - a).normalized().cross(Vector3.UP)
		var corners := [a - right * ROAD_HALF, b - right * ROAD_HALF, a + right * ROAD_HALF,
			b + right * ROAD_HALF]
		var across := [0.0, 0.0, 1.0, 1.0]
		for index in [0, 1, 2, 2, 1, 3]:
			tool.set_color(Color(across[index], place, 0.0))
			tool.set_normal(Vector3.UP)
			var at: Vector3 = corners[index]
			tool.set_uv(Vector2(at.x, at.z))
			tool.add_vertex(at)
	var strip := MeshInstance3D.new()
	strip.name = label
	strip.mesh = tool.commit()
	strip.material_override = asphalt
	add_child(strip)


func _lamps(lamp_post: Callable) -> void:
	for road: Array[Vector3] in [EAST_ROAD, COASTAL]:
		var a := road[0]
		var b := road[1]
		var along := (b - a).normalized()
		var right := along.cross(Vector3.UP)
		var length := a.distance_to(b)
		var count := ceili(length / LAMP_EVERY)
		for index in range(count + 1):
			var at := a + along * (length * index / count) + right * LAMP_OUT
			if at.x < 616.0:
				continue
			var lamp: Node3D = lamp_post.call(Vector3(at.x, 0.0, at.z), atan2(-right.x, -right.z))
			lamps.append(lamp)


func _sea() -> void:
	_water = StandardMaterial3D.new()
	_water.albedo_color = Color(0.015, 0.03, 0.04)
	_water.roughness = 0.05
	_water.metallic_specular = 0.7
	var ripples := NoiseTexture2D.new()
	ripples.seamless = true
	ripples.as_normal_map = true
	ripples.bump_strength = 2.5
	var noise := FastNoiseLite.new()
	noise.frequency = 0.04
	ripples.noise = noise
	_water.normal_enabled = true
	_water.normal_texture = ripples
	_water.normal_scale = 0.35
	_water.uv1_scale = Vector3(SEA_REACH / 6.0, SEA_REACH / 6.0, 1.0)
	var plane := PlaneMesh.new()
	plane.size = Vector2(SEA_REACH * 2.0, SEA_REACH * 2.0)
	sea = MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	sea.material_override = _water
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	sea.position = Vector3(OUTLINE[1].x, SEA_LEVEL, 0.0)


## The waterfront's container terminal (`waterfront.gd`), built once the world's yards are.
func build_waterfront(slab: Material, asphalt: Material, concrete: Material, metal: Material,
		yard: Node3D, rain: Node, lamp_post: Callable) -> void:
	waterfront = Waterfront.new()
	waterfront.name = "Waterfront"
	add_child(waterfront)
	waterfront.build(slab, asphalt, concrete, metal, yard, rain, lamp_post)


## The airfield (`airfield.gd`), its hangar and its PC-12.
func build_airfield(asphalt: Material, slab: Material, cladding: Material, metal: Material,
		concrete: Material, lamp_post: Callable) -> void:
	airfield = Airfield.new()
	airfield.name = "Airfield"
	add_child(airfield)
	airfield.build(asphalt, slab, cladding, metal, concrete, lamp_post)


## The bluff wooded as the rim above it, from the forest's own kinds (`forest.meshes_of`): every
## BANK_STEP along it, a tree at a random height on its slope, sunk a little, clear of the roads.
func plant(forest: Node3D, terrain: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 35901
	var placed := {}
	var z := RIM_FROM + 2.0
	while z < RIM_TO - 2.0:
		var top: float = terrain.call("height_at", RIM_EDGE, z)
		for tree in range(BANK_DEPTH):
			var share := rng.randf_range(0.04, 0.88)
			var x := lerpf(RIM_EDGE - 0.4, RIM_TOE, share)
			var y := lerpf(top, LAND_TOP, smoothstep(0.0, 1.0, share)) - BANK_SINK
			if absf(z - EAST_ROAD[0].z) > BANK_CLEAR and x < RIM_TOE - 6.0 and top - y > 1.5:
				_place_tree(forest, rng, placed, Vector3(x, y, z + rng.randf_range(-2.0, 2.0)))
		z += BANK_STEP * rng.randf_range(0.6, 1.4)
	var x := CUT_BANKS.position.x
	while x < CUT_BANKS.end.x:
		for side in [-1.0, 1.0]:
			var out := rng.randf_range(BANK_CLEAR - 4.0, CUT_BANKS.size.y / 2.0)
			var at := Vector2(x + rng.randf_range(-2.0, 2.0), EAST_ROAD[0].z + side * out)
			var y: float = float(terrain.call("height_at", at.x, at.y)) - BANK_SINK
			if y > 0.8:
				_place_tree(forest, rng, placed, Vector3(at.x, y, at.y))
		x += BANK_STEP * 0.5 * rng.randf_range(0.6, 1.4)
	for key: String in placed:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = placed[key][0]
		var spots: Array = placed[key][1]
		multimesh.instance_count = spots.size()
		for index in range(spots.size()):
			multimesh.set_instance_transform(index, spots[index])
			multimesh.set_instance_color(index, Color.WHITE)
		var trees := MultiMeshInstance3D.new()
		trees.name = "BluffTrees"
		trees.multimesh = multimesh
		trees.visibility_range_end = BANK_RANGE
		add_child(trees)


func _place_tree(forest: Node3D, rng: RandomNumberGenerator, placed: Dictionary,
		at: Vector3) -> void:
	var kind := BANK_KINDS[rng.randi() % BANK_KINDS.size()]
	var meshes: Array = forest.call("meshes_of", kind)
	if meshes.is_empty():
		return
	var model := rng.randi() % meshes.size()
	var size := rng.randf_range(0.8, 1.2)
	var key := "%s/%d" % [kind, model]
	if not placed.has(key):
		placed[key] = [meshes[model], []]
	(placed[key][1] as Array).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(
		Vector3.ONE * size), at))


func _beacon_piles(concrete: Material) -> void:
	for beacon: Array in BEACONS:
		var at: Vector3 = beacon[0]
		var colour: Color = beacon[1]
		var top := Vector3(at.x, SEA_LEVEL + 4.2, at.z)
		Build.cylinder(self, Vector3(at.x, SEA_LEVEL + 1.0, at.z), 0.6, 4.0, concrete).name = \
			"BeaconPile"
		var glass := StandardMaterial3D.new()
		glass.albedo_color = colour.darkened(0.6)
		glass.emission_enabled = true
		glass.emission = colour
		glass.emission_energy_multiplier = 0.0
		Build.cylinder(self, top + Vector3.UP * 0.2, 0.15, 0.3, glass).name = "BeaconLantern"
		var light := OmniLight3D.new()
		light.light_color = colour
		light.omni_range = 18.0
		light.light_energy = 0.0
		add_child(light)
		light.position = top + Vector3.UP * 0.3
		_beacons.append(light)
		_beacon_glass.append(glass)


func _process(delta: float) -> void:
	if _water == null:
		return
	_drift += Vector2(0.004, 0.0025) * delta
	_water.uv1_offset = Vector3(_drift.x, _drift.y, 0.0)
	_clock = fmod(_clock + delta, BEACON_PERIOD)
	var on := _clock < BEACON_FLASH
	for index in range(_beacons.size()):
		_beacons[index].light_energy = 2.5 if on else 0.0
		_beacon_glass[index].emission_energy_multiplier = 6.0 if on else 0.2


## A solid of `faces`; `both_ways` makes it solid from either side, whatever their winding.
func _solid(faces: PackedVector3Array, both_ways: bool = false) -> void:
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = both_ways
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_body.add_child(collision)
