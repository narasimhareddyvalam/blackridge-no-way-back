extends Node3D

const GhatRoad = preload("ghat_road.gd")
const GRASS = preload("verge_grass.gdshader")
const MOWED := 2.5
const EDGE := 4.0
const MOWN_DENSITY := 6.0
const EDGE_DENSITY := 3.0
const MOWN_HEIGHT := Vector2(0.16, 0.3)
const EDGE_HEIGHT := Vector2(0.3, 0.6)
const STEEP := 0.6
const TILE := 16.0
const NEAR_RANGE := 18.0
const FAR_RANGE := 45.0
const NEAR_BLADES := 28
const FAR_BLADES := 10
const CLUMP_RADIUS := 0.09
const BLADE_WIDTH := Vector2(0.004, 0.0075)
const GREENS: Array[Color] = [Color("34491c"), Color("3f5722"), Color("4b5f28"),
	Color("666935"), Color("776d49")]
const GREEN_WEIGHTS: Array[float] = [0.3, 0.3, 0.2, 0.12, 0.08]
const MAP_STEP := 1.0
const MAP_RANGE := 8.0

var clump_count: int = 0
var verge_map: ImageTexture
var _terrain: Node3D
var _map_area: Rect2


func build(road: RefCounted, clearings: Array[Rect2], seed_value: int, terrain: Node3D) -> void:
	_terrain = terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tiles := {}
	var points: PackedVector3Array = road.points
	for index in range(points.size()):
		if road.sections[index] != GhatRoad.Section.VALLEY:
			continue
		var here := points[index]
		var ahead := points[(index + 1) % points.size()]
		var forward := Vector3(ahead.x - here.x, 0.0, ahead.z - here.z)
		var length := forward.length()
		var right := forward.normalized().cross(Vector3.UP)
		var verge: float = road.half_widths[index] + GhatRoad.VERGE
		for side: float in [-1.0, 1.0]:
			var wanted := length * (MOWED * MOWN_DENSITY + (EDGE - MOWED) * EDGE_DENSITY)
			for attempt in range(int(wanted) + (1 if rng.randf() < fmod(wanted, 1.0) else 0)):
				var out := _distance_out(rng)
				var at := here.lerp(ahead, rng.randf()) + right * side * (verge + out)
				var point := Vector2(at.x, at.z)
				var height := rng.randf_range(MOWN_HEIGHT.x, MOWN_HEIGHT.y) if out < MOWED \
					else rng.randf_range(EDGE_HEIGHT.x, EDGE_HEIGHT.y)
				var turn := rng.randf() * TAU
				var spread := rng.randf_range(0.8, 1.25)
				if _blocked(point, here.y, clearings):
					continue
				var key := Vector2i(floori(point.x / TILE), floori(point.y / TILE))
				if not tiles.has(key):
					tiles[key] = []
				var centre := (Vector2(key) + Vector2(0.5, 0.5)) * TILE
				tiles[key].append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3(spread,
					height, spread)), Vector3(point.x - centre.x, _terrain.height_at(point.x,
					point.y), point.y - centre.y)))
				clump_count += 1
	_draw_map(road, clearings)
	var material := ShaderMaterial.new()
	material.shader = GRASS
	var near := _clump(NEAR_BLADES, seed_value, 1.0, material)
	var far := _clump(FAR_BLADES, seed_value + 1, 1.6, material)
	for key: Vector2i in tiles:
		var centre := (Vector2(key) + Vector2(0.5, 0.5)) * TILE
		_add(near, tiles[key], centre, 0.0, NEAR_RANGE)
		_add(far, tiles[key], centre, NEAR_RANGE, FAR_RANGE)


func paint(ground: ShaderMaterial) -> void:
	ground.set_shader_parameter("verge_map", verge_map)
	ground.set_shader_parameter("verge_area", Vector4(_map_area.position.x, _map_area.position.y,
		_map_area.size.x, _map_area.size.y))
	ground.set_shader_parameter("verge_range", MAP_RANGE)
	ground.set_shader_parameter("verge_mowed", MOWED)
	ground.set_shader_parameter("verge_edge", EDGE)


func _draw_map(road: RefCounted, clearings: Array[Rect2]) -> void:
	_map_area = _terrain.get("area")
	var columns := int(_map_area.size.x / MAP_STEP)
	var rows := int(_map_area.size.y / MAP_STEP)
	var cells := PackedByteArray()
	cells.resize(columns * rows)
	cells.fill(255)
	var points: PackedVector3Array = road.points
	for index in range(points.size()):
		if road.sections[index] != GhatRoad.Section.VALLEY:
			continue
		var a := Vector2(points[index].x, points[index].z)
		var next := points[(index + 1) % points.size()]
		var b := Vector2(next.x, next.z)
		var verge: float = road.half_widths[index] + GhatRoad.VERGE
		var box := Rect2(a, Vector2.ZERO).expand(b).grow(verge + MAP_RANGE)
		var first := ((box.position - _map_area.position) / MAP_STEP).floor()
		var last := ((box.end - _map_area.position) / MAP_STEP).ceil()
		for row in range(maxi(int(first.y), 0), mini(int(last.y), rows)):
			for column in range(maxi(int(first.x), 0), mini(int(last.x), columns)):
				var at := _map_area.position + (Vector2(column, row) + Vector2(0.5, 0.5)) \
					* MAP_STEP
				var reach := at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b))
				var value := clampi(int((reach - verge) / MAP_RANGE * 255.0), 0, 255)
				var cell := row * columns + column
				if value < cells[cell] and not _inside(at, clearings):
					cells[cell] = value
	verge_map = ImageTexture.create_from_image(Image.create_from_data(columns, rows, false,
		Image.FORMAT_R8, cells))


func _inside(point: Vector2, clearings: Array[Rect2]) -> bool:
	for rect in clearings:
		if rect.has_point(point):
			return true
	return false


func _distance_out(rng: RandomNumberGenerator) -> float:
	var mown := MOWED * MOWN_DENSITY
	var edge := (EDGE - MOWED) * EDGE_DENSITY
	if rng.randf() * (mown + edge) < mown:
		return rng.randf() * MOWED
	return MOWED + (EDGE - MOWED) * (1.0 - sqrt(rng.randf()))


func _blocked(point: Vector2, road_height: float, clearings: Array[Rect2]) -> bool:
	if _inside(point, clearings) or _terrain.road_clearance(point.x, point.y) < 0.0:
		return true
	return absf(_terrain.height_at(point.x, point.y) - road_height) > STEEP


func _clump(blades: int, seed_value: int, width_scale: float, material: Material) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	for blade in range(blades):
		var angle := rng.randf() * TAU
		var base := Vector3(cos(angle), 0.0, sin(angle)) * sqrt(rng.randf()) * CLUMP_RADIUS
		var lean := Vector3(cos(angle + rng.randf_range(-0.8, 0.8)), 0.0,
			sin(angle + rng.randf_range(-0.8, 0.8))).normalized()
		var across := lean.cross(Vector3.UP).normalized()
		var height := rng.randf_range(0.55, 1.0)
		var droop := rng.randf_range(0.15, 0.5)
		var width := rng.randf_range(BLADE_WIDTH.x, BLADE_WIDTH.y) * width_scale
		var colour := _blade_colour(rng)
		var spine: Array[Vector3] = []
		var normals: Array[Vector3] = []
		for step in range(4):
			var t := step / 3.0
			spine.append(base + lean * droop * height * t * t
				+ Vector3.UP * height * (t - droop * 0.6 * t * t))
			var tangent := lean * 2.0 * droop * height * t + Vector3.UP * height * (1.0
				- 1.2 * droop * t)
			normals.append(tangent.cross(across).normalized())
		for step in range(3):
			var low := step / 3.0
			var high := (step + 1) / 3.0
			var low_half := width * 0.5 * (1.0 - pow(low, 1.5))
			var high_half := width * 0.5 * (1.0 - pow(high, 1.5))
			var corners := [[spine[step] - across * low_half, normals[step], low, 0.0],
				[spine[step] + across * low_half, normals[step], low, 1.0],
				[spine[step + 1] - across * high_half, normals[step + 1], high, 0.0],
				[spine[step + 1] + across * high_half, normals[step + 1], high, 1.0]]
			var order := [0, 1, 2, 2, 1, 3] if step < 2 else [0, 1, 2]
			if step == 2:
				corners[2] = [spine[3], normals[3], 1.0, 0.5]
			for corner: int in order:
				var item: Array = corners[corner]
				var shade := lerpf(0.35, 1.0, item[2])
				tool.set_color(Color(colour.r * shade, colour.g * shade, colour.b * shade))
				tool.set_normal(item[1])
				tool.set_uv(Vector2(item[3], item[2]))
				tool.add_vertex(item[0])
	return tool.commit()


func _blade_colour(rng: RandomNumberGenerator) -> Color:
	var pick := rng.randf()
	for index in range(GREENS.size()):
		pick -= GREEN_WEIGHTS[index]
		if pick <= 0.0:
			return GREENS[index].srgb_to_linear()
	return GREENS[GREENS.size() - 1].srgb_to_linear()


func _add(mesh: Mesh, transforms: Array, centre: Vector2, begin: float, end: float) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.position = Vector3(centre.x, 0.0, centre.y)
	instance.visibility_range_begin = begin
	instance.visibility_range_begin_margin = 2.0 if begin > 0.0 else 0.0
	instance.visibility_range_end = end
	instance.visibility_range_end_margin = 2.0 if end < FAR_RANGE else 5.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
