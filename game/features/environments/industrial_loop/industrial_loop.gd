extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const ASPHALT = preload("wet_asphalt.gdshader")
const WALL = preload("industrial_wall.gdshader")
const DepotDetail = preload("depot_detail.gd")
const CONCRETE_COLOR = preload("art/concrete_albedo.png")
const CONCRETE_NORMAL = preload("art/concrete_normal.png")
const ASPHALT_COLOR = preload("art/asphalt_albedo.png")
const ASPHALT_NORMAL = preload("art/asphalt_normal.png")

var road_points := PackedVector3Array()
var depot_position := Vector3(-28.0, 0.0, 91.0)
var _metal := Build.material(Color("343d43"), 0.48)
var _concrete := Build.material(Color("4b5254"))
var _lamp := Build.luminous(Color("ffd7a0"), 1.5)
var _line := Build.material(Color("bdab72"), 0.65)
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = 42019
	_environment()
	_ground_and_roads()
	_buildings()
	_depot()
	add_child(DepotDetail.new())
	_street_furniture()
	_boundary()
	_reflections()


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
	environment.ambient_light_energy = 0.30
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled = true
	environment.fog_light_color = Color("334653")
	environment.fog_density = 0.0038
	environment.fog_sky_affect = 0.65
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35.0, -28.0, 0.0)
	moon.light_color = Color("9bb8d4")
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 85.0
	add_child(moon)
	_concrete.albedo_texture = CONCRETE_COLOR
	_concrete.normal_enabled = true
	_concrete.normal_texture = CONCRETE_NORMAL
	_concrete.uv1_triplanar = true
	_concrete.uv1_scale = Vector3.ONE * 0.6
	_concrete.albedo_color = Color("a4a9a7")


func _ground_and_roads() -> void:
	var grass := Build.material(Color("192927"))
	Build.box(self, Vector3(0, -0.3, 0), Vector3(400, 0.6, 310), grass, true)
	for corner: Vector3 in [
		Vector3(89, 0, 44), Vector3(89, 0, -44),
		Vector3(-89, 0, -44), Vector3(-89, 0, 44)
	]:
		var start: float = [PI / 2.0, 0.0, -PI / 2.0, -PI][road_points.size() / 13]
		for index in range(13):
			var angle := start - float(index) / 12.0 * PI / 2.0
			road_points.append(corner + Vector3(cos(angle) * 26.0, 0.025, sin(angle) * 26.0))
	var asphalt := ShaderMaterial.new()
	asphalt.shader = ASPHALT
	asphalt.set_shader_parameter("aggregate_color", ASPHALT_COLOR)
	asphalt.set_shader_parameter("aggregate_normal", ASPHALT_NORMAL)
	_road_strip(road_points, 7.0, asphalt)
	_road_strip(road_points, 8.2, _concrete, -0.012)
	for index in range(road_points.size()):
		var a := road_points[index]
		var b := road_points[(index + 1) % road_points.size()]
		var length := a.distance_to(b)
		var direction := a.direction_to(b)
		for distance in range(0, int(length), 8):
			var dash := Build.box(self, a + direction * (distance + 1.8),
				Vector3(0.10, 0.014, minf(3.5, length)), _line)
			dash.rotation.y = atan2(-direction.x, -direction.z)
	var yard := ShaderMaterial.new()
	yard.shader = ASPHALT
	yard.set_shader_parameter("aggregate_color", ASPHALT_COLOR)
	yard.set_shader_parameter("aggregate_normal", ASPHALT_NORMAL)
	yard.set_shader_parameter("dry_color", Vector3(0.48, 0.49, 0.50))
	Build.box(self, Vector3(-28, 0.012, 95), Vector3(60, 0.02, 42), yard)
	Build.box(self, Vector3(-28, 0.017, 78), Vector3(18, 0.025, 18), yard)


func _road_strip(
	points: PackedVector3Array, half_width: float, surface: Material, height: float = 0.0
) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(points.size()):
		var a := points[index] + Vector3.UP * height
		var b := points[(index + 1) % points.size()] + Vector3.UP * height
		var previous := points[(index - 1 + points.size()) % points.size()]
		var following := points[(index + 2) % points.size()]
		var right_a := (b - previous).normalized().cross(Vector3.UP) * half_width
		var right_b := (following - a).normalized().cross(Vector3.UP) * half_width
		for vertex: Vector3 in [a - right_a, b - right_b, a + right_a,
				a + right_a, b - right_b, b + right_b]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(Vector2(vertex.x, vertex.z))
			tool.add_vertex(vertex)
	tool.generate_tangents()
	Build.instance(self, Vector3.ZERO, tool.commit(), surface)


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
	for item: Vector3 in [Vector3(35, 0, 34), Vector3(70, 0, -28),
		Vector3(-30, 0, -35), Vector3(-71, 0, 26)]:
		var size := Vector3(_random.randf_range(24, 38), _random.randf_range(9, 15), 23)
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
		var at := Vector3(-50 + index * 12, 1.4, -7)
		var surface := _wall_material(Color.from_hsv(0.5 + index * 0.015, 0.3, 0.25))
		Build.box(self, at, Vector3(10, 2.8, 3.2), surface, true)
		for rib in range(13):
			Build.box(self, at + Vector3(-4.8 + rib * 0.8, 0, 1.62),
				Vector3(0.055, 2.7, 0.035), _metal)
	for x in [-64, -48]:
		Build.cylinder(self, Vector3(x, 9, -109), 5.8, 18, siding)
		Build.cylinder(self, Vector3(x, 18.4, -109), 5.8, 0.8, _metal, 4.5)
		Build.box(self, Vector3(x + 4.0, 10, -109), Vector3(0.5, 20, 0.5), _metal)
	for index in range(14):
		var x := -165.0 + index * 26.0
		var height := _random.randf_range(10, 35)
		Build.box(self, Vector3(x, height / 2, -143), Vector3(20, height, 17), siding)


func _depot() -> void:
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
		_lamp_post(Vector3(x, 0, 109), PI)
	for x in [-34, -22]:
		Build.box(self, Vector3(x, 0.04, 93), Vector3(0.12, 0.02, 12), _line)
	Build.box(self, Vector3(-28, 0.04, 99), Vector3(12, 0.02, 0.15), _line)
	_direction_sign(Vector3(67, 0, 60), -PI / 2, "DEPOT  /  FREIGHT LOOP", "KEEP RIGHT")
	_direction_sign(Vector3(104, 0, -30), 0, "INDUSTRIAL ROAD", "DEPOT  /  CONTINUE")
	_direction_sign(Vector3(-66, 0, -60), PI / 2, "WEST ROAD", "DEPOT  /  CONTINUE")
	_direction_sign(Vector3(-65, 0, 60), -PI / 2, "FREIGHT DEPOT", "NEXT RIGHT")


func _direction_sign(at: Vector3, heading: float, title: String, detail: String) -> void:
	var sign := Node3D.new()
	add_child(sign)
	sign.position = at
	sign.rotation.y = heading
	Build.box(sign, Vector3(0, 1.6, 0), Vector3(0.12, 3.2, 0.12), _metal)
	Build.box(sign, Vector3(0, 3.3, 0), Vector3(6.6, 1.5, 0.12),
		Build.material(Color("203d3f")))
	Build.text(sign, title + "\n" + detail, Vector3(0, 3.3, 0.07), 33, Color("e0dbc0"))


func _street_furniture() -> void:
	for index in range(0, road_points.size(), 4):
		var point := road_points[index]
		var direction := point.direction_to(road_points[(index + 1) % road_points.size()])
		var right := direction.cross(Vector3.UP)
		_lamp_post(point + right * 9.3, atan2(-direction.x, -direction.z))
	for x in range(-80, 90, 10):
		Build.box(self, Vector3(x, 1.1, 52), Vector3(0.08, 2.2, 0.08), _metal)
		Build.box(self, Vector3(x + 5, 1.8, 52), Vector3(10, 0.04, 0.04), _metal)
		Build.box(self, Vector3(x + 5, 0.7, 52), Vector3(10, 0.04, 0.04), _metal)
		for bar in range(10):
			Build.box(self, Vector3(x + bar, 1.1, 52), Vector3(0.025, 2.2, 0.025), _metal)
	for side in [-1, 1]:
		for z in range(-110, 110, 7):
			var at := Vector3(side * _random.randf_range(142, 178), 0, z)
			Build.cylinder(self, at + Vector3.UP * 2.5, 0.3, 5, _metal)
			Build.cylinder(self, at + Vector3.UP * 5.5, 3.2, 9,
				Build.material(Color("142624")), 0.05)


func _lamp_post(at: Vector3, heading: float) -> void:
	var post := Node3D.new()
	add_child(post)
	post.position = at
	post.rotation.y = heading
	Build.cylinder(post, Vector3(0, 3.7, 0), 0.09, 7.4, _metal)
	Build.box(post, Vector3(-1, 7.25, 0), Vector3(2.1, 0.09, 0.10), _metal)
	Build.box(post, Vector3(-1.9, 7.1, 0), Vector3(0.8, 0.12, 0.45), _lamp)
	var light := OmniLight3D.new()
	light.position = Vector3(-1.9, 6.7, 0)
	light.light_color = Color("ffd1a0")
	light.light_energy = 3.0
	light.omni_range = 18.0
	light.omni_attenuation = 1.6
	light.distance_fade_enabled = true
	light.distance_fade_begin = 65.0
	light.distance_fade_length = 25.0
	post.add_child(light)
	if at.z > 100.0:
		light.shadow_enabled = true
		light.light_energy = 4.0
		light.omni_range = 16.0


func _reflections() -> void:
	var probe := ReflectionProbe.new()
	probe.name = "DepotReflections"
	probe.position = Vector3(-28, 4.5, 94)
	probe.size = Vector3(74, 18, 62)
	probe.origin_offset = Vector3(0, 2, 0)
	probe.max_distance = 95.0
	probe.box_projection = true
	probe.cull_mask = 1
	probe.intensity = 0.8
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)


func _boundary() -> void:
	var barrier := Build.material(Color("50565a"))
	for side in [-1, 1]:
		Build.box(self, Vector3(side * 132, 0.65, 0), Vector3(1, 1.3, 180), barrier, true)
		Build.box(self, Vector3(0, 0.65, side * 132), Vector3(264, 1.3, 1), barrier, true)
