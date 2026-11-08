extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const ASPHALT = preload("wet_asphalt.gdshader")
const WALL = preload("industrial_wall.gdshader")
const DepotDetail = preload("depot_detail.gd")
const CONCRETE_COLOR = preload("art/concrete_albedo.png")
const CONCRETE_NORMAL = preload("art/concrete_normal.png")
const ASPHALT_COLOR = preload("art/asphalt_albedo.png")
const ASPHALT_NORMAL = preload("art/asphalt_normal.png")
const RoadsideForest = preload("roadside_forest.gd")
const ForestFloor = preload("forest_floor.gd")
const RoadsideGrass = preload("roadside_grass.gd")
const GhatRoad = preload("ghat_road.gd")
const HillTerrain = preload("hill_terrain.gd")
const GhatDressing = preload("ghat_dressing.gd")
const BusStop = preload("bus_stop.gd")
const LampRain = preload("lamp_rain.gd")
const SiteOffice = preload("art/office/site_office.glb")
const Streetlight = preload("art/streetlight/streetlight.glb")
const GROUND = preload("hill_ground.gdshader")
const MIST = preload("lamp_mist.gdshader")
const POLYHAVEN := "res://features/environments/industrial_loop/polyhaven/textures/"
const FOREST_CLEARANCE := 2.5
const TERRAIN_AREA := Rect2(-160, -320, 820, 650)
const PLAYABLE_AREA := Rect2(-140, -290, 780, 510)
const WAREHOUSES: Array[Vector3] = [Vector3(60, 0, 115), Vector3(150, 0, 112),
	Vector3(250, 0, 120), Vector3(-71, 0, 26)]
const CONTAINER_ROW := Vector3(100, 0, 145)
const SILOS: Array[float] = [466.0, 482.0]
const SILO_Z := 62.0
const DEPOT_PLOT := Rect2(-62, 72, 68, 58)
const DEPOT_YARD := Rect2(-58, 74, 60, 42)
const DRIVEWAY := Vector2(-37, -19)
const YARD_HEIGHT := 0.02
const YARD_GAP := 0.4
const DRIVEWAY_RAMP := 1.5
const FENCE_Z := 158.0
const FENCE_FROM := -40
const FENCE_TO := 130
const FENCE_PLOT := Rect2(FENCE_FROM - 2, FENCE_Z - 1.5, FENCE_TO - FENCE_FROM + 4, 3)
const LUMBER_YARD := Rect2(520, 72, 80, 40)
const SHOULDER := Vector2(0.6, 0.3)
const FORECOURT := Rect2(544.0, 120.8, 36.0, 5.4)
const MOON_LAYER := 4
const VAN_PARKING := Vector3(568.0, -0.02, 123.5)
const SITE_OFFICE := Vector3(552.0, -0.12, 117.5)
const OFFICE_PLOT := Rect2(SITE_OFFICE.x - 5.0, SITE_OFFICE.z - 3.5, 10.0, 7.5)
const SHEET_STAND := 0.7
const OFFICE_TEXTURES := {
	"siding": ["weathered_plank_siding", 1.57, "2k"],
	"roof": ["corrugated_iron", 1.12, "1k"],
	"door": ["rough_pine_door", 2.0, "1k"],
	"deck": ["stair_planks", 1.2, "1k"],
	"concrete": ["brushed_concrete_03", 2.0, "1k"],
}
const OFFICE_PAINT := {
	"trim": Color("8e897d"), "sign": Color("0b3321"), "letters": Color("ddd6c0"),
	"paper": Color("e8e3d4"), "clipboard": Color("6b4a2e"),
}
const LAMP_COLOR := Color("ffd7a0")
const FLOODLIGHT_COLOR := Color("e4ebf2")
const STREET_LIGHT_COLOR := Color("ffa040")
const WALL_LIGHT_COLOR := Color("ffd1a0")
const POLE_STEEL := Color("5c6163")
const LUMINAIRE_PAINT := Color("8a8f92")
const POST_ENERGY := 90.0
const POST_REACH := 15.0
const POST_SPREAD := 55.0
const POST_SHADOWS_TO := 45.0
const HALO_SIZE := 2.4
const HALO_STRENGTH := 0.8
const MIST_BELOW := 0.6
const SECURITY_LIGHT := "res://features/environments/depot_yard/polyhaven/models/security_light/" \
	+ "security_light.gltf"
const DEPOT_FRONT := 112.5
const WALL_LIGHT_HEIGHT := 5.45
const WALL_LIGHT_ENERGY := 60.0
const WALL_LIGHT_REACH := 9.0
const WALL_LIGHT_SPREAD := 40.0
const WALL_LIGHT_TILT := 10.0
const WALL_HALO_SIZE := 1.2
const WALL_RAIN_OUT := 4.0
const VIEW_CLEARINGS: Array[Rect2] = [Rect2(420, -140, 75, 55), Rect2(395, -112, 70, 50),
	Rect2(368, -82, 70, 50), Rect2(340, -52, 72, 50), Rect2(312, -22, 74, 50)]
const SKYLINE_Z := 207.0
const SKYLINE_PLOT := Rect2(-112, 197, 556, 44)
const GLOW_SIZE := 16.0
const GLOW_FROM := 150.0
const LANDSLIDE_AT := Vector2(330, 166)
const CROSSING_AT := Vector2(64.0, -79.0)
const CURVE_RAILS: Array[Vector2] = [Vector2(55.0, 44.0), Vector2(6.0, 68.0),
	Vector2(-50.0, 72.0), Vector2(-64.0, 168.0)]
const WEST_BEND_LAMPS: Array[Vector2] = [Vector2(-45.0, 71.5), Vector2(-64.0, 168.0)]
const BEND_LAMP_SPACING := 38.0
const BEND_LAMP_SETBACK := 1.3
const SIGN_SETBACK := 3.0
const GUIDE_GREEN := Color("0a4128")
const TOWN_LAMPS: Array[Vector3] = [Vector3(-45, 0, 64.5), Vector3(-15, 0, 63.8),
	Vector3(8, 0, 62.5)]

var road_points := PackedVector3Array()
var road: RefCounted
var terrain: Node3D
var dressing: Node3D
var crossing: Node3D
var playable_area := PLAYABLE_AREA
var depot_position := Vector3(-28.0, 0.0, 91.0)
var clearings: Array[Rect2] = []
var run_sheet_at := Vector3.ZERO
var run_sheet_spot := Vector3.ZERO
var office_transform := Transform3D.IDENTITY
var forest: Node3D
var forest_floor: Node3D
var grass: Node3D
var _ground: ShaderMaterial
var lamp_rain := LampRain.new()
var _metal := Build.material(Color("343d43"), 0.48)
var _concrete := Build.material(Color("4b5254"))
var _lamp := Build.luminous(Color("ffd7a0"), 1.5)
var _lens := Build.luminous(Color(6.0, 5.06, 3.76))
var _street_lens := Build.luminous(Color(6.0, 3.76, 1.5))
var _streetlight_paints := {}
var _halo_falloff: GradientTexture2D
var _halo_materials := {}
var _halo_meshes := {}
var _line := Build.material(Color("bdab72"), 0.65)
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = 42019
	_environment()
	_ground_and_roads()
	_buildings()
	_depot()
	_lumber_yard()
	add_child(DepotDetail.new())
	_street_furniture()
	_boundary()
	_reflections()
	_forest()
	lamp_rain.name = "LampRain"
	add_child(lamp_rain)


func _environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("070e19")
	sky_material.sky_horizon_color = Color("344755")
	sky_material.ground_bottom_color = Color("10151b")
	sky_material.ground_horizon_color = Color("344755")
	sky_material.sky_curve = 0.18
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("758b9c")
	environment.ambient_light_energy = 0.08
	environment.ssr_enabled = true
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.3
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled = true
	environment.fog_light_color = Color("1f2b34")
	environment.fog_density = 0.0045
	environment.fog_sky_affect = 0.65
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35.0, -28.0, 0.0)
	moon.light_color = Color("9bb8d4")
	moon.light_energy = 0.2
	moon.light_specular = 0.0
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.layers = MOON_LAYER
	add_child(moon)
	_concrete.albedo_texture = CONCRETE_COLOR
	_concrete.normal_enabled = true
	_concrete.normal_texture = CONCRETE_NORMAL
	_concrete.uv1_triplanar = true
	_concrete.uv1_scale = Vector3.ONE * 0.6
	_concrete.albedo_color = Color("a4a9a7")


func _ground_and_roads() -> void:
	road = GhatRoad.new()
	road_points = road.points
	terrain = HillTerrain.new()
	terrain.name = "HillTerrain"
	add_child(terrain)
	_ground = _hill_material()
	terrain.build(road, TERRAIN_AREA, _flat_plots(), _ground, 42021)
	var asphalt := ShaderMaterial.new()
	asphalt.shader = ASPHALT
	asphalt.set_shader_parameter("aggregate_color", _texture("tarred_gravel", "diff"))
	asphalt.set_shader_parameter("aggregate_normal", _texture("tarred_gravel", "nor_gl"))
	asphalt.set_shader_parameter("aggregate_arm", _texture("tarred_gravel", "arm"))
	asphalt.set_shader_parameter("arm_roughness", 1.0)
	asphalt.set_shader_parameter("damp_gloss", 1.0)
	asphalt.set_shader_parameter("texture_scale", 1.0 / 2.2)
	asphalt.set_shader_parameter("crack_amount", 0.0)
	asphalt.set_shader_parameter("dry_color", Vector3(0.85, 0.85, 0.85))
	_road_strip(0.0, 0.0, asphalt, false)
	_road_strip(GhatRoad.VERGE, -0.012, _surface("leaf_scattered_gravel", 1.8, false), true)
	crossing = BusStop.new()
	crossing.name = "BusStop"
	add_child(crossing)
	crossing.build(road, terrain, CROSSING_AT, _concrete,
		_surface("leaf_scattered_gravel", 1.8, false))
	crossing.paint(asphalt)
	clearings.append_array(crossing.clearings)
	dressing = GhatDressing.new()
	dressing.name = "GhatDressing"
	add_child(dressing)
	dressing.build(road, terrain, _concrete, LANDSLIDE_AT, crossing.index, CURVE_RAILS)
	var yard := ShaderMaterial.new()
	yard.shader = ASPHALT
	yard.set_shader_parameter("aggregate_color", ASPHALT_COLOR)
	yard.set_shader_parameter("aggregate_normal", ASPHALT_NORMAL)
	yard.set_shader_parameter("dry_color", Vector3(0.48, 0.49, 0.50))
	_depot_ground(yard)


func _flat_plots() -> Array[Rect2]:
	var plots: Array[Rect2] = [DEPOT_PLOT, FENCE_PLOT, LUMBER_YARD, SKYLINE_PLOT]
	for item in WAREHOUSES:
		plots.append(Rect2(item.x - 23, item.z - 15.5, 46, 33.4))
	plots.append(Rect2(CONTAINER_ROW.x - 7, CONTAINER_ROW.z - 4, 110, 8))
	plots.append(Rect2(SILOS[0] - 8, SILO_Z - 8, SILOS[1] - SILOS[0] + 16, 16))
	return plots


func _road_strip(extra: float, height: float, surface: Material, solid: bool) -> void:
	var points: PackedVector3Array = road.points
	var widths: PackedFloat32Array = road.half_widths
	var count := points.size()
	var lefts := PackedVector3Array()
	var rights := PackedVector3Array()
	var normals := PackedVector3Array()
	var across := PackedVector3Array()
	for index in range(count):
		var along := points[(index + 1) % count] - points[(index - 1 + count) % count]
		var right := Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)
		var centre := points[index] + Vector3.UP * height
		lefts.append(centre - right * (widths[index] + extra))
		rights.append(centre + right * (widths[index] + extra))
		normals.append(right.cross(along).normalized())
		across.append(right)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(count):
		var next := (index + 1) % count
		_road_vertex(tool, lefts[index], normals[index])
		_road_vertex(tool, lefts[next], normals[next])
		_road_vertex(tool, rights[index], normals[index])
		_road_vertex(tool, rights[index], normals[index])
		_road_vertex(tool, lefts[next], normals[next])
		_road_vertex(tool, rights[next], normals[next])
	if solid:
		_shoulder(tool, rights, across, 1.0)
		_shoulder(tool, lefts, across, -1.0)
	tool.generate_tangents()
	Build.instance(self, Vector3.ZERO, tool.commit(), surface, solid)


func _shoulder(tool: SurfaceTool, edge: PackedVector3Array, across: PackedVector3Array,
		side: float) -> void:
	var count := edge.size()
	var drop := Vector3.DOWN * SHOULDER.y
	for index in range(count):
		var next := (index + 1) % count
		var outer := edge[index] + across[index] * side * SHOULDER.x + drop
		var outer_next := edge[next] + across[next] * side * SHOULDER.x + drop
		var normal := (Vector3.UP * SHOULDER.x + across[index] * side * SHOULDER.y).normalized()
		var normal_next := (Vector3.UP * SHOULDER.x + across[next] * side * SHOULDER.y).normalized()
		var inner_first := side > 0.0
		var a := edge[index] if inner_first else outer
		var b := edge[next] if inner_first else outer_next
		var c := outer if inner_first else edge[index]
		var d := outer_next if inner_first else edge[next]
		_road_vertex(tool, a, normal)
		_road_vertex(tool, b, normal_next)
		_road_vertex(tool, c, normal)
		_road_vertex(tool, c, normal)
		_road_vertex(tool, b, normal_next)
		_road_vertex(tool, d, normal_next)


func _road_vertex(tool: SurfaceTool, vertex: Vector3, normal: Vector3) -> void:
	tool.set_normal(normal)
	tool.set_uv(Vector2(vertex.x, vertex.z))
	tool.add_vertex(vertex)


func _depot_ground(surface: Material) -> void:
	var asphalt := _road_edge(0.0)
	var verge := _road_edge(GhatRoad.VERGE + YARD_GAP)
	var near_road := DEPOT_YARD.grow(8.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := int(DEPOT_YARD.size.x)
	for step in range(columns + 1):
		var x := DEPOT_YARD.position.x + step
		var drive := x >= DRIVEWAY.x and x <= DRIVEWAY.y
		var edge := _edge_at(asphalt if drive else verge, x, near_road)
		var north := DEPOT_YARD.position.y
		var lip := YARD_HEIGHT
		if drive and is_finite(edge.z):
			north = edge.z
			lip = edge.y + 0.002
		elif is_finite(edge.z):
			north = maxf(north, edge.z)
		for corner: Vector3 in [Vector3(x, lip, north),
				Vector3(x, YARD_HEIGHT, north + DRIVEWAY_RAMP),
				Vector3(x, YARD_HEIGHT, DEPOT_YARD.end.y)]:
			_road_vertex(tool, corner, Vector3.UP)
	for step in range(columns):
		for row in range(2):
			var top := step * 3 + row
			var next := top + 3
			for index: int in [top, next, top + 1, top + 1, next, next + 1]:
				tool.add_index(index)
	tool.generate_tangents()
	var ground := Build.instance(self, Vector3.ZERO, tool.commit(), surface)
	ground.name = "DepotYard"
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _road_edge(extra: float) -> PackedVector3Array:
	var points: PackedVector3Array = road.points
	var count := points.size()
	var edge := PackedVector3Array()
	for index in range(count):
		var along := points[(index + 1) % count] - points[(index - 1 + count) % count]
		var right := Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)
		var reach: Vector3 = right * (road.half_widths[index] + extra)
		var south := points[index] + reach
		if (points[index] - reach).z > south.z:
			south = points[index] - reach
		edge.append(south)
	return edge


func _edge_at(line: PackedVector3Array, x: float, area: Rect2) -> Vector3:
	var best := Vector3(x, 0.0, -INF)
	for index in range(line.size()):
		var a := line[index]
		var b := line[(index + 1) % line.size()]
		if (a.x - x) * (b.x - x) > 0.0 or is_equal_approx(a.x, b.x):
			continue
		var at := a.lerp(b, (x - a.x) / (b.x - a.x))
		if area.has_point(Vector2(at.x, at.z)) and at.z > best.z:
			best = at
	return best


func _hill_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND
	for pair: Array in [["ground", "forest_leaves_04"], ["rock", "rock_wall_02"]]:
		material.set_shader_parameter(pair[0] + "_color", _texture(pair[1], "diff"))
		material.set_shader_parameter(pair[0] + "_normal", _texture(pair[1], "nor_gl"))
		material.set_shader_parameter(pair[0] + "_arm", _texture(pair[1], "arm"))
	material.set_shader_parameter("turf_color", _texture("leafy_grass", "diff", "1k"))
	material.set_shader_parameter("turf_normal", _texture("leafy_grass", "nor_gl", "1k"))
	material.set_shader_parameter("turf_arm", _texture("leafy_grass", "arm", "1k"))
	return material


func _wall_material(color: Color, brick: bool = false) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = WALL
	result.set_shader_parameter("base_color", color)
	result.set_shader_parameter("brick", brick)
	return result


func _buildings() -> void:
	var masonry := _wall_material(Color("57483f"), true)
	var siding := _wall_material(Color("4d5c61"))
	var window := Build.luminous(Color("bfad80") * 0.55)
	for item: Vector3 in WAREHOUSES:
		var size := Vector3(_random.randf_range(24, 38), _random.randf_range(9, 15), 23)
		clearings.append(Rect2(item.x - size.x / 2 - 4, item.z - 15.5, size.x + 8, 33.4))
		Build.box(self, item + Vector3.UP * size.y / 2, size, masonry, true)
		Build.box(self, item + Vector3.UP * (size.y + 0.18),
			size * Vector3(1.025, 0, 1.025) + Vector3.UP * 0.36, _metal)
		for x in range(-8, 9, 4):
			Build.box(self, item + Vector3(x, 6.5, 11.53), Vector3(2.5, 1.4, 0.08), window)
			Build.box(self, item + Vector3(x, 6.5, 11.6), Vector3(0.08, 1.4, 0.08), _metal)
		for x in [-7, 1, 9]:
			Build.box(self, item + Vector3(x, 2.6, 11.58), Vector3(5.8, 5.2, 0.1), siding)
			Build.box(self, item + Vector3(x, 0.65, 12.8), Vector3(6.5, 1.3, 2.2), _concrete)
		Build.box(self, item + Vector3(0, size.y + 0.7, 0), Vector3(6, 1.4, 4), _metal)
	for index in range(9):
		var at := CONTAINER_ROW + Vector3(index * 12, 1.4, 0)
		var surface := _wall_material(Color.from_hsv(0.5 + index * 0.015, 0.3, 0.25))
		Build.box(self, at, Vector3(10, 2.8, 3.2), surface, true)
		for rib in range(13):
			Build.box(self, at + Vector3(-4.8 + rib * 0.8, 0, 1.62),
				Vector3(0.055, 2.7, 0.035), _metal)
	clearings.append(Rect2(CONTAINER_ROW.x - 7, CONTAINER_ROW.z - 4, 110, 8))
	for x in SILOS:
		Build.cylinder(self, Vector3(x, 9, SILO_Z), 5.8, 18, siding)
		Build.cylinder(self, Vector3(x, 18.4, SILO_Z), 5.8, 0.8, _metal, 4.5)
		Build.box(self, Vector3(x + 4.0, 10, SILO_Z), Vector3(0.5, 20, 0.5), _metal)
	clearings.append(Rect2(SILOS[0] - 10, SILO_Z - 8, SILOS[1] - SILOS[0] + 20, 16))
	var windows: Array[Transform3D] = []
	var tints: Array[Color] = []
	clearings.append(SKYLINE_PLOT)
	for index in range(14):
		var x := -90.0 + index * 38.0
		var height := _random.randf_range(10, 28)
		var z := SKYLINE_Z + _random.randf_range(0.0, 14.0)
		Build.box(self, Vector3(x, height / 2, z), Vector3(22, height, 18), siding)
		for floor_y in range(3, int(height) - 1, 3):
			for column in range(-9, 10, 3):
				if _random.randf() < 0.38:
					windows.append(Transform3D(Basis(Vector3.UP, PI).scaled(
						Vector3(1.4, 1.6, 1.0)), Vector3(x + column, floor_y, z - 9.05)))
					var warmth := _random.randf_range(0.0, 1.0)
					tints.append(Color(1.0, 0.78, 0.5).lerp(Color(0.7, 0.85, 1.0),
						warmth * warmth) * _random.randf_range(3.5, 6.0))
	_town_windows(windows, tints)


func _town_windows(windows: Array[Transform3D], tints: Array[Color]) -> void:
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.material = glass
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = windows.size()
	for index in range(windows.size()):
		multimesh.set_instance_transform(index, windows[index])
		multimesh.set_instance_color(index, tints[index])
	var lights := MultiMeshInstance3D.new()
	lights.name = "TownWindows"
	lights.multimesh = multimesh
	lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lights)
	_town_glows()


func _town_glows() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.86, 0.62, 1.0))
	gradient.set_color(1, Color(1.0, 0.7, 0.4, 0.0))
	var halo := GradientTexture2D.new()
	halo.gradient = gradient
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(0.5, 0.0)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow.albedo_texture = halo
	glow.albedo_color = Color(3.0, 2.4, 1.7)
	glow.disable_fog = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * GLOW_SIZE
	quad.material = glow
	var spots: Array[Transform3D] = []
	for index in range(24):
		var x := SKYLINE_PLOT.position.x + 12.0 + index * 22.5 + _random.randf_range(-4.0, 4.0)
		spots.append(Transform3D(Basis.IDENTITY, Vector3(x, _random.randf_range(16.0, 24.0),
			SKYLINE_PLOT.position.y + 12.0)))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = spots.size()
	for index in range(spots.size()):
		multimesh.set_instance_transform(index, spots[index])
	var glows := MultiMeshInstance3D.new()
	glows.name = "TownGlows"
	glows.multimesh = multimesh
	glows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glows.visibility_range_begin = GLOW_FROM
	add_child(glows)


func _depot() -> void:
	clearings.append(Rect2(-62, 72, 68, 58))
	var siding := _wall_material(Color("586167"))
	Build.box(self, Vector3(-29, 5, 119), Vector3(49, 10, 13), siding, true)
	Build.box(self, Vector3(-29, 10.2, 119), Vector3(51, 0.4, 15), _metal)
	Build.box(self, Vector3(-29, 6.8, 112.4), Vector3(20, 2.2, 0.15), _metal)
	var sign := Build.text(self, "BLACKRIDGE  /  FREIGHT DEPOT",
		Vector3(-29, 6.8, 112.25), 60, Color("e3d5af"))
	sign.rotation.y = PI
	for x in [-45, -30, -15]:
		Build.box(self, Vector3(x, 2.4, 112.45), Vector3(9, 4.8, 0.15), _metal)
		for y in range(1, 10):
			Build.box(self, Vector3(x, y * 0.48, 112.30), Vector3(8.8, 0.025, 0.04), _concrete)
		_wall_light(Vector3(x, WALL_LIGHT_HEIGHT, DEPOT_FRONT))
	for x in [-34, -22]:
		Build.box(self, Vector3(x, 0.04, 93), Vector3(0.12, 0.02, 12), _line)
	Build.box(self, Vector3(-28, 0.04, 99), Vector3(12, 0.02, 0.15), _line)
	_direction_sign(Vector2(515, 128), "BLACKRIDGE  /  HILL ROAD", "VALLEY ROAD CLOSED")
	_direction_sign(Vector2(470, 128), "BLACKRIDGE PASS  3/4 MI", "SWITCHBACKS  /  9% GRADE")
	_direction_sign(Vector2(205, -199), "BLACKRIDGE PASS", "ELEV 1,200 FT")
	_direction_sign(Vector2(40, 68), "FREIGHT DEPOT", "NEXT LEFT")
	for at in TOWN_LAMPS:
		_lamp_post(at, PI / 2)
	_bend_lamps(WEST_BEND_LAMPS[0], WEST_BEND_LAMPS[1])


func _bend_lamps(from: Vector2, to: Vector2) -> void:
	var first := _nearest_road(from)
	var last := _nearest_road(to)
	var outside := 1.0 if angle_difference(road.heading_at(first), road.heading_at(last)) > 0.0 \
		else -1.0
	var travelled := 0.0
	for index in range(first, last):
		var here := road_points[index]
		var ahead := road_points[index + 1]
		travelled += Vector2(here.x, here.z).distance_to(Vector2(ahead.x, ahead.z))
		if travelled < BEND_LAMP_SPACING:
			continue
		travelled = 0.0
		var right := Vector3(ahead.x - here.x, 0.0, ahead.z - here.z).normalized().cross(Vector3.UP)
		var reach: float = road.half_widths[index] + GhatRoad.VERGE + BEND_LAMP_SETBACK
		var at := here + right * outside * reach
		at.y = terrain.height_at(at.x, at.z)
		var toward := -right * outside
		_lamp_post(at, atan2(toward.z, -toward.x))


func _direction_sign(near: Vector2, title: String, detail: String) -> void:
	var index := _nearest_road(near)
	var ahead := road_points[(index + 1) % road_points.size()] - road_points[index]
	var right := Vector3(ahead.x, 0.0, ahead.z).normalized().cross(Vector3.UP)
	var reach: float = road.half_widths[index] + GhatRoad.VERGE + SIGN_SETBACK
	var at := road_points[index] + right * reach
	clearings.append(Rect2(at.x - 5, at.z - 5, 10, 10))
	var sign := Node3D.new()
	add_child(sign)
	sign.position = Vector3(at.x, terrain.height_at(at.x, at.z), at.z)
	sign.rotation.y = road.heading_at(index)
	Build.box(sign, Vector3(0, 1.6, 0), Vector3(0.12, 3.2, 0.12), _metal)
	Build.box(sign, Vector3(0, 3.3, 0), Vector3(6.6, 1.5, 0.12),
		Build.material(GUIDE_GREEN))
	Build.text(sign, title + "\n" + detail, Vector3(0, 3.3, 0.07), 33, Color("e0dbc0"))


func _nearest_road(near: Vector2) -> int:
	var best := 0
	for index in range(road_points.size()):
		var here := Vector2(road_points[index].x, road_points[index].z)
		if here.distance_squared_to(near) < Vector2(road_points[best].x,
				road_points[best].z).distance_squared_to(near):
			best = index
	return best


func _lumber_yard() -> void:
	clearings.append(LUMBER_YARD)
	clearings.append(FORECOURT)
	clearings.append_array(VIEW_CLEARINGS)
	var yard := LUMBER_YARD
	Build.box(self, Vector3(yard.get_center().x, 0.01, yard.get_center().y),
		Vector3(yard.size.x, 0.02, yard.size.y), _surface("leaf_scattered_gravel", 1.8, true))
	var court := FORECOURT.get_center()
	Build.box(self, Vector3(court.x, SITE_OFFICE.y + 0.005, court.y),
		Vector3(FORECOURT.size.x, 0.02, FORECOURT.size.y),
		_surface("leaf_scattered_gravel", 1.8, true))
	var bark := ORMMaterial3D.new()
	bark.albedo_texture = _texture("pine_bark", "diff")
	bark.normal_enabled = true
	bark.normal_texture = _texture("pine_bark", "nor_gl")
	bark.orm_texture = _texture("pine_bark", "arm")
	bark.uv1_triplanar = true
	bark.albedo_color = Color(0.7, 0.66, 0.62)
	var random := RandomNumberGenerator.new()
	random.seed = 5521
	for pile in range(3):
		var corner := Vector3(yard.position.x + 10 + pile * 22, 0, yard.position.y + 9)
		for row in range(3):
			for piece in range(4 - row):
				var radius := random.randf_range(0.26, 0.34)
				var at := corner + Vector3(random.randf_range(-0.2, 0.2), 0.3 + row * 0.52,
					(piece + row * 0.5) * 0.62)
				var trunk := Build.cylinder(self, at, radius, random.randf_range(8.5, 10.5), bark)
				trunk.rotation.z = PI / 2
		var bounds := Rect2(corner.x - 6, corner.z - 1, 12, 4)
		var body := StaticBody3D.new()
		add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(bounds.size.x, 1.6, bounds.size.y)
		shape.shape = box
		shape.position = Vector3(bounds.get_center().x, 0.8, bounds.get_center().y)
		body.add_child(shape)
	var shed := _wall_material(Color("5a4a3c"))
	Build.box(self, Vector3(yard.end.x - 9, 2, yard.position.y + 30), Vector3(10, 4, 7), shed,
		true)
	Build.box(self, Vector3(yard.end.x - 9, 4.2, yard.position.y + 30), Vector3(11, 0.3, 8),
		_metal)
	_lamp_post(Vector3(yard.position.x + 6, 0, yard.end.y - 3), PI / 2)
	_site_office()


func _site_office() -> void:
	var at := SITE_OFFICE
	clearings.append(OFFICE_PLOT)
	var office := SiteOffice.instantiate() as Node3D
	office.name = "SiteOffice"
	office.position = at
	add_child(office)
	office_transform = office.transform
	var shell := office.get_node("SiteOffice") as MeshInstance3D
	for surface in range(shell.mesh.get_surface_count()):
		var part := shell.mesh.surface_get_material(surface).resource_name
		shell.set_surface_override_material(surface, _office_material(part))
	_office_lights(office)
	var sheet := office.get_node("RunSheet") as Node3D
	run_sheet_at = office.transform * sheet.position
	run_sheet_spot = office.transform * Vector3(sheet.position.x, 0.0,
		sheet.position.z + SHEET_STAND)


func _office_material(part: String) -> Material:
	if OFFICE_TEXTURES.has(part):
		var source: Array = OFFICE_TEXTURES[part]
		var tile: float = source[1]
		var material := _surface(source[0], tile, false, source[2])
		material.uv1_offset.y = 1.0 - 1.0 / tile
		return material
	match part:
		"metal":
			return _metal
		"glass":
			var glass := Build.material(Color(0.1, 0.12, 0.13, 0.3), 0.05)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			return glass
		"blinds":
			var blinds := Build.material(Color("cfc6b0"), 0.8)
			blinds.emission_enabled = true
			blinds.emission = Color("ffcf94")
			blinds.emission_energy_multiplier = 0.3
			return blinds
		"window_glow":
			return Build.luminous(Color("ffd9a6"), 0.8)
		"lamp_glow":
			return _lamp
	return Build.material(OFFICE_PAINT[part], 0.8)


func _office_lights(office: Node3D) -> void:
	var lamp := SpotLight3D.new()
	lamp.name = "NoticeLight"
	lamp.transform = (office.get_node("NoticeLamp") as Node3D).transform
	lamp.light_color = LAMP_COLOR
	lamp.light_energy = 4.0
	lamp.spot_range = 8.0
	lamp.spot_angle = 55.0
	lamp.shadow_enabled = true
	office.add_child(lamp)
	_mist(lamp, lamp.position.y + MIST_BELOW)
	var flood := SpotLight3D.new()
	flood.name = "FloodLight"
	flood.transform = (office.get_node("Floodlight") as Node3D).transform
	flood.transform = flood.transform.looking_at(office.transform.affine_inverse()
		* (VAN_PARKING + Vector3.UP * 1.0), Vector3.UP)
	flood.light_color = FLOODLIGHT_COLOR
	flood.light_energy = 9.0
	flood.spot_range = 32.0
	flood.spot_angle = 30.0
	flood.shadow_enabled = true
	office.add_child(flood)
	_mist(flood, (office.transform * flood.position).distance_to(VAN_PARKING) + 3.0)
	var glow := OmniLight3D.new()
	glow.name = "WindowGlow"
	glow.position = (office.get_node("WindowLight") as Node3D).position
	glow.light_color = Color("ffcf94")
	glow.light_energy = 0.8
	glow.omni_range = 4.0
	office.add_child(glow)
	var beam_from := office.transform * flood.position
	var beam_to := VAN_PARKING + Vector3.UP
	var beam := Vector2(beam_to.x - beam_from.x, beam_to.z - beam_from.z)
	var middle := Vector3((beam_from.x + beam_to.x) * 0.5, VAN_PARKING.y + LampRain.FLOOD_HEIGHT,
		(beam_from.z + beam_to.z) * 0.5)
	lamp_rain.add_volume(LampRain.FLOODLIGHT, Transform3D(Basis(Vector3.UP, atan2(beam.x, beam.y)),
		middle))
	var notice := office.get_node("NoticeLamp") as Node3D
	var sheet := office.get_node("RunSheet") as Node3D
	lamp_rain.add_volume(LampRain.DOOR, Transform3D(Basis.IDENTITY, office.transform * Vector3(
		notice.position.x, LampRain.DOOR_HEIGHT, sheet.position.z + LampRain.DOOR_OUT)))


func _street_furniture() -> void:
	clearings.append(FENCE_PLOT)
	for x in range(FENCE_FROM, FENCE_TO, 10):
		Build.box(self, Vector3(x, 1.1, FENCE_Z), Vector3(0.08, 2.2, 0.08), _metal)
		Build.box(self, Vector3(x + 5, 1.8, FENCE_Z), Vector3(10, 0.04, 0.04), _metal)
		Build.box(self, Vector3(x + 5, 0.7, FENCE_Z), Vector3(10, 0.04, 0.04), _metal)
		for bar in range(10):
			Build.box(self, Vector3(x + bar, 1.1, FENCE_Z), Vector3(0.025, 2.2, 0.025), _metal)


func _lamp_post(at: Vector3, heading: float) -> void:
	var post := Streetlight.instantiate() as Node3D
	post.position = at
	post.rotation.y = heading
	add_child(post)
	var body := post.get_node("Streetlight") as MeshInstance3D
	for surface in range(body.mesh.get_surface_count()):
		var part := body.mesh.surface_get_material(surface).resource_name
		body.set_surface_override_material(surface, _streetlight_material(part))
	var lens := (post.get_node("Lens") as Node3D).position
	var light := SpotLight3D.new()
	light.position = lens
	light.rotation.x = -PI / 2.0
	light.light_color = STREET_LIGHT_COLOR
	light.light_energy = POST_ENERGY
	light.spot_range = POST_REACH
	light.spot_angle = POST_SPREAD
	light.spot_angle_attenuation = 1.5
	light.spot_attenuation = 2.0
	light.shadow_enabled = true
	light.distance_fade_enabled = true
	light.distance_fade_begin = 65.0
	light.distance_fade_length = 25.0
	light.distance_fade_shadow = POST_SHADOWS_TO
	post.add_child(light)
	_mist(light, lens.y + MIST_BELOW)
	var halo := _halo(HALO_SIZE, STREET_LIGHT_COLOR)
	halo.position = lens + Vector3(0, -0.2, 0)
	post.add_child(halo)
	lamp_rain.add_volume(LampRain.STREET, Transform3D(Basis.IDENTITY,
		post.transform * LampRain.POST_HEAD))


func _streetlight_material(part: String) -> Material:
	match part:
		"lens":
			return _street_lens
		"footing":
			return _concrete
		"steel":
			return _metal
	if not _streetlight_paints.has(part):
		var paint := StandardMaterial3D.new()
		paint.albedo_color = POLE_STEEL if part == "pole" else LUMINAIRE_PAINT
		paint.metallic = 0.6 if part == "pole" else 0.3
		paint.roughness_texture = _texture("green_metal_rust", "arm", "1k")
		paint.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		paint.normal_enabled = true
		paint.normal_texture = _texture("green_metal_rust", "nor_gl", "1k")
		paint.normal_scale = 0.7 if part == "pole" else 0.3
		paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_streetlight_paints[part] = paint
	return _streetlight_paints[part]


func _wall_light(at: Vector3) -> void:
	var fixture := (load(SECURITY_LIGHT) as PackedScene).instantiate() as Node3D
	fixture.position = at
	fixture.rotation.y = PI
	add_child(fixture)
	for mesh: Node in fixture.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name == "security_light_glass":
			(mesh as MeshInstance3D).material_override = _lens
	var light := SpotLight3D.new()
	light.position = at + Vector3(0, -0.32, -0.22)
	light.rotation_degrees.x = WALL_LIGHT_TILT - 90.0
	light.light_color = WALL_LIGHT_COLOR
	light.light_energy = WALL_LIGHT_ENERGY
	light.spot_range = WALL_LIGHT_REACH
	light.spot_angle = WALL_LIGHT_SPREAD
	light.spot_angle_attenuation = 1.5
	light.spot_attenuation = 2.0
	light.shadow_enabled = true
	light.distance_fade_enabled = true
	light.distance_fade_begin = 65.0
	light.distance_fade_length = 25.0
	light.distance_fade_shadow = POST_SHADOWS_TO
	add_child(light)
	_mist(light, light.position.y + MIST_BELOW)
	var halo := _halo(WALL_HALO_SIZE, WALL_LIGHT_COLOR)
	halo.position = at + Vector3(0, -0.3, -0.35)
	add_child(halo)
	lamp_rain.add_volume(LampRain.POST, Transform3D(Basis.IDENTITY,
		Vector3(at.x, at.y - 0.45, at.z - WALL_RAIN_OUT)))


func _mist(light: SpotLight3D, depth: float) -> void:
	var colour := light.light_color.srgb_to_linear() * light.light_energy
	var radius := depth * tan(deg_to_rad(light.spot_angle))
	var air := ShaderMaterial.new()
	air.shader = MIST
	air.set_shader_parameter("light_colour", Vector3(colour.r, colour.g, colour.b))
	air.set_shader_parameter("half_size", Vector3(radius, radius, depth * 0.5))
	air.set_shader_parameter("spot_cutoff", cos(deg_to_rad(light.spot_angle)))
	air.set_shader_parameter("spot_falloff", light.spot_angle_attenuation)
	air.set_shader_parameter("light_range", light.spot_range)
	air.set_shader_parameter("light_decay", light.spot_attenuation)
	air.set_shader_parameter("fade_begin", light.distance_fade_begin
		if light.distance_fade_enabled else 1.0e6)
	air.set_shader_parameter("fade_length", light.distance_fade_length)
	var box := BoxMesh.new()
	box.size = Vector3(radius * 2.0, radius * 2.0, depth)
	var volume := MeshInstance3D.new()
	volume.name = "Mist"
	volume.mesh = box
	volume.material_override = air
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	volume.position = Vector3(0.0, 0.0, -depth * 0.5)
	light.add_child(volume)


func _halo(size: float, color: Color) -> MeshInstance3D:
	if _halo_falloff == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.06, 0.2, 0.5, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45),
			Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.03), Color(1, 1, 1, 0)])
		_halo_falloff = GradientTexture2D.new()
		_halo_falloff.gradient = gradient
		_halo_falloff.fill = GradientTexture2D.FILL_RADIAL
		_halo_falloff.fill_from = Vector2(0.5, 0.5)
		_halo_falloff.fill_to = Vector2(0.5, 0.0)
	if not _halo_materials.has(color):
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		glow.albedo_texture = _halo_falloff
		glow.albedo_color = Color(color.r * HALO_STRENGTH, color.g * HALO_STRENGTH,
			color.b * HALO_STRENGTH)
		glow.proximity_fade_enabled = true
		glow.proximity_fade_distance = 0.5
		_halo_materials[color] = glow
	var key := "%.2f %s" % [size, color]
	if not _halo_meshes.has(key):
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * size
		quad.material = _halo_materials[color]
		_halo_meshes[key] = quad
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = _halo_meshes[key]
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return halo


func _reflections() -> void:
	var probe := ReflectionProbe.new()
	probe.name = "DepotReflections"
	probe.position = Vector3(-28, 4.5, 94)
	probe.size = Vector3(74, 18, 62)
	probe.origin_offset = Vector3(0, 2, 0)
	probe.max_distance = 95.0
	probe.box_projection = true
	probe.cull_mask = 1 | MOON_LAYER
	probe.intensity = 0.8
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)


func _boundary() -> void:
	var walls := StaticBody3D.new()
	walls.name = "Boundary"
	add_child(walls)
	var area := PLAYABLE_AREA
	for wall: Array in [
		[Vector3(area.get_center().x, 60, area.position.y), Vector3(area.size.x, 200, 2)],
		[Vector3(area.get_center().x, 60, area.end.y), Vector3(area.size.x, 200, 2)],
		[Vector3(area.position.x, 60, area.get_center().y), Vector3(2, 200, area.size.y)],
		[Vector3(area.end.x, 60, area.get_center().y), Vector3(2, 200, area.size.y)],
	]:
		var shape := BoxShape3D.new()
		shape.size = wall[1]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = wall[0]
		walls.add_child(collision)


func _forest() -> void:
	forest = RoadsideForest.new()
	forest.name = "RoadsideForest"
	add_child(forest)
	forest.build(road_points, FOREST_CLEARANCE, clearings, TERRAIN_AREA.grow(-4.0),
		PLAYABLE_AREA, 42019, terrain)
	forest_floor = ForestFloor.new()
	forest_floor.name = "ForestFloor"
	add_child(forest_floor)
	var mowed := PackedFloat32Array()
	for index in range(road_points.size()):
		mowed.append(RoadsideGrass.MOWED if road.sections[index] == GhatRoad.Section.VALLEY
			else 0.0)
	forest_floor.build(road_points, clearings, 42020, terrain, mowed)
	grass = RoadsideGrass.new()
	grass.name = "RoadsideGrass"
	add_child(grass)
	var built := _flat_plots()
	built.append_array([FORECOURT, OFFICE_PLOT])
	grass.build(road, built, 42022, terrain)
	grass.paint(_ground)


func _surface(asset: String, tile_size: float, triplanar: bool,
		resolution: String = "2k") -> ORMMaterial3D:
	var material := ORMMaterial3D.new()
	material.albedo_texture = _texture(asset, "diff", resolution)
	material.normal_enabled = true
	material.normal_texture = _texture(asset, "nor_gl", resolution)
	material.orm_texture = _texture(asset, "arm", resolution)
	material.uv1_scale = Vector3.ONE / tile_size
	material.uv1_triplanar = triplanar
	material.uv1_world_triplanar = triplanar
	material.albedo_color = Color(0.58, 0.58, 0.58)
	return material


func _texture(asset: String, map: String, resolution: String = "2k") -> Texture2D:
	return load(POLYHAVEN + "%s/%s_%s_%s.jpg" % [asset, asset, map, resolution])
