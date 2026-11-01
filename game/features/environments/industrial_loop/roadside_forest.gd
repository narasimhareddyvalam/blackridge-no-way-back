extends Node3D

const Conifer = preload("conifer_builder.gd")
const NEEDLES = preload("conifer_needles.gdshader")
const BRANCH_ALBEDO = preload("art/conifer/conifer_branch_diff.png")
const BRANCH_NORMAL = preload("art/conifer/conifer_branch_nor_gl.png")
const DEADWOOD_ALBEDO = preload("art/conifer/conifer_deadwood_diff.png")
const DEADWOOD_NORMAL = preload("art/conifer/conifer_deadwood_nor_gl.png")
const BARK_ALBEDO = preload("polyhaven/textures/pine_bark/pine_bark_diff_2k.jpg")
const BARK_NORMAL = preload("polyhaven/textures/pine_bark/pine_bark_nor_gl_2k.jpg")
const BARK_ORM = preload("polyhaven/textures/pine_bark/pine_bark_arm_2k.jpg")
const VARIANTS: Array[Vector2] = [Vector2(15.0, 2.4), Vector2(19.0, 2.9), Vector2(23.0, 3.4)]
const SAPLINGS: Array[Vector2] = [Vector2(1.6, 0.7), Vector2(2.6, 1.0), Vector2(3.8, 1.3)]
const SAPLING_CROWN := Vector2(0.03, 0.1)
const SAPLING_CHANCE := 0.12
const SAPLING_RANGE := 55.0
const SAPLING_SHADOW_RANGE := 25.0
const SAPLING_SEED := 500
const EDGE_DEPTH := 18.0
const YOUNG_BARK_SHADE := Color(0.5, 0.47, 0.44)
const EDGE_BOOST := 1.5
const FAR_SAPLINGS := 0.3
const ROADSIDE_BAND := 19.0
const FAR_KEEP := 0.25
const CELL := 3.4
const TILE := 48.0
const NEAR_RANGE := 60.0
const SHADOW_RANGE := 50.0
const CASTS_NONE := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
const CASTS_ONLY := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
const FAR_RANGE := 280.0
const DEADWOOD_RANGE := 40.0
const GRID := 1.0
const TRUNK_HEIGHT := 6.0
const SLOPE_SINK := 0.6
const MAX_SINK := 0.9

var tree_count: int = 0
var sapling_count: int = 0
var collider_count: int = 0
var _blocked := PackedByteArray()
var _area: Rect2
var _columns: int = 0
var _rows: int = 0
var _trunk_shapes: Array[CylinderShape3D] = []
var _terrain: Node3D
var _clearance: float = 0.0


func build(_road_points: PackedVector3Array, clearance: float, clearings: Array[Rect2],
		area: Rect2, collision_area: Rect2, seed_value: int, terrain: Node3D) -> void:
	_area = area
	_terrain = terrain
	_clearance = clearance
	_columns = int(area.size.x / GRID)
	_rows = int(area.size.y / GRID)
	_blocked.resize(_columns * _rows)
	for rect in clearings:
		_block_rect(rect)
	var bark := _bark_material()
	var needles := _needle_material()
	var deadwood := _deadwood_material()
	var near_meshes: Array[ArrayMesh] = []
	var far_meshes: Array[ArrayMesh] = []
	var dead_meshes: Array[ArrayMesh] = []
	for index in range(VARIANTS.size()):
		var variant := VARIANTS[index]
		near_meshes.append(Conifer.build(variant.x, variant.y, seed_value + index, 1.0, bark,
			needles))
		far_meshes.append(Conifer.build(variant.x, variant.y, seed_value + index, 0.4, bark,
			needles))
		dead_meshes.append(Conifer.build_deadwood(variant.x, seed_value + index, deadwood))
		var shape := CylinderShape3D.new()
		shape.radius = Conifer.trunk_radius(variant.x)
		shape.height = TRUNK_HEIGHT
		_trunk_shapes.append(shape)
	var tiles := _scatter(seed_value, collision_area)
	for tile: Vector2i in tiles:
		var data: Dictionary = tiles[tile]
		var centre := _tile_centre(tile)
		for variant in range(VARIANTS.size()):
			var transforms: Array = data["transforms"][variant]
			if transforms.is_empty():
				continue
			var colours: Array = data["colours"][variant]
			var far := _multimesh(far_meshes[variant], transforms, colours)
			_add_instance(_multimesh(near_meshes[variant], transforms, colours), centre, 0.0,
				NEAR_RANGE, CASTS_NONE)
			_add_instance(far, centre, 0.0, SHADOW_RANGE, CASTS_ONLY)
			_add_instance(far, centre, NEAR_RANGE, FAR_RANGE, CASTS_NONE)
			_add_instance(_multimesh(dead_meshes[variant], transforms, colours), centre, 0.0,
				DEADWOOD_RANGE, CASTS_NONE)
		_add_trunks(data["trunks"])
	var young_bark := _bark_material()
	young_bark.albedo_color = YOUNG_BARK_SHADE
	_build_saplings(seed_value + SAPLING_SEED, young_bark, needles)


func _build_saplings(seed_value: int, bark: Material, needles: Material) -> void:
	var near_meshes: Array[ArrayMesh] = []
	var light_meshes: Array[ArrayMesh] = []
	for index in range(SAPLINGS.size()):
		var sapling := SAPLINGS[index]
		near_meshes.append(Conifer.build(sapling.x, sapling.y, seed_value + index, 1.0, bark,
			needles, SAPLING_CROWN))
		light_meshes.append(Conifer.build(sapling.x, sapling.y, seed_value + index, 0.4, bark,
			needles, SAPLING_CROWN))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var patches := FastNoiseLite.new()
	patches.seed = seed_value
	patches.frequency = 0.035
	var tiles := {}
	var x := _area.position.x + CELL
	while x < _area.end.x:
		var z := _area.position.y + CELL
		while z < _area.end.y:
			var px := x + rng.randf_range(-0.5, 0.5) * CELL
			var pz := z + rng.randf_range(-0.5, 0.5) * CELL
			var patch := patches.get_noise_2d(px, pz)
			var chance := SAPLING_CHANCE * (1.0 + 2.0 * patch) * (EDGE_BOOST if _is_edge(px, pz)
				else FAR_SAPLINGS)
			if rng.randf() < chance and not _is_blocked(px, pz):
				var tile := Vector2i(floori((px - _area.position.x) / TILE),
					floori((pz - _area.position.y) / TILE))
				if not tiles.has(tile):
					tiles[tile] = {"transforms": [[], [], []], "colours": [[], [], []]}
				var variant := rng.randi_range(0, SAPLINGS.size() - 1)
				var centre := _tile_centre(tile)
				var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(
					Vector3.ONE * rng.randf_range(0.8, 1.25))
				var ground := _ground(px, pz) + 0.02
				tiles[tile]["transforms"][variant].append(
					Transform3D(turn, Vector3(px - centre.x, ground, pz - centre.y)))
				var shade := rng.randf_range(0.85, 1.1)
				tiles[tile]["colours"][variant].append(Color(shade, shade, shade, 1.0))
				sapling_count += 1
			z += CELL
		x += CELL
	for tile: Vector2i in tiles:
		var centre := _tile_centre(tile)
		for variant in range(SAPLINGS.size()):
			var transforms: Array = tiles[tile]["transforms"][variant]
			if transforms.is_empty():
				continue
			var colours: Array = tiles[tile]["colours"][variant]
			_add_instance(_multimesh(near_meshes[variant], transforms, colours), centre, 0.0,
				SAPLING_RANGE, CASTS_NONE)
			_add_instance(_multimesh(light_meshes[variant], transforms, colours), centre, 0.0,
				SAPLING_SHADOW_RANGE, CASTS_ONLY)


func _scatter(seed_value: int, collision_area: Rect2) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var density := FastNoiseLite.new()
	density.seed = seed_value
	density.frequency = 0.02
	var tiles := {}
	var x := _area.position.x + CELL * 0.5
	while x < _area.end.x:
		var z := _area.position.y + CELL * 0.5
		while z < _area.end.y:
			var px := x + rng.randf_range(-0.45, 0.45) * CELL
			var pz := z + rng.randf_range(-0.45, 0.45) * CELL
			var keep := 0.8 + 0.2 * density.get_noise_2d(px, pz)
			if _terrain.road_clearance(px, pz) > ROADSIDE_BAND:
				keep *= FAR_KEEP
			if rng.randf() < keep and not _is_blocked(px, pz):
				_place(tiles, px, pz, rng, collision_area)
			z += CELL
		x += CELL
	return tiles


func _place(tiles: Dictionary, x: float, z: float, rng: RandomNumberGenerator,
		collision_area: Rect2) -> void:
	var variant := rng.randi_range(0, VARIANTS.size() - 1)
	var size := rng.randf_range(0.82, 1.18)
	var tile := Vector2i(floori((x - _area.position.x) / TILE), floori((z - _area.position.y) / TILE))
	if not tiles.has(tile):
		tiles[tile] = {"transforms": [[], [], []], "colours": [[], [], []], "trunks": []}
	var centre := _tile_centre(tile)
	var heading := rng.randf() * TAU
	var lean := Basis(Vector3(cos(heading), 0.0, sin(heading)), deg_to_rad(rng.randf_range(0.0, 2.5)))
	var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
	var ground := _ground(x, z)
	tiles[tile]["transforms"][variant].append(
		Transform3D(lean * turn, Vector3(x - centre.x, ground, z - centre.y)))
	var shade := rng.randf_range(0.78, 1.05)
	tiles[tile]["colours"][variant].append(
		Color(shade, shade * rng.randf_range(0.96, 1.04), shade, 1.0))
	if collision_area.has_point(Vector2(x, z)):
		tiles[tile]["trunks"].append([Vector3(x, ground + TRUNK_HEIGHT * 0.5, z), variant])
	tree_count += 1


func _multimesh(mesh: ArrayMesh, transforms: Array, colours: Array) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, colours[index])
	return multimesh


func _add_instance(multimesh: MultiMesh, centre: Vector2, begin: float, end: float,
		shadow: GeometryInstance3D.ShadowCastingSetting) -> void:
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.position = Vector3(centre.x, 0.0, centre.y)
	instance.visibility_range_begin = begin
	instance.visibility_range_begin_margin = 6.0 if begin > 0.0 else 0.0
	instance.visibility_range_end = end
	instance.visibility_range_end_margin = 6.0
	instance.cast_shadow = shadow
	add_child(instance)


func _add_trunks(trunks: Array) -> void:
	if trunks.is_empty():
		return
	var body := StaticBody3D.new()
	add_child(body)
	for trunk: Array in trunks:
		var shape := CollisionShape3D.new()
		shape.shape = _trunk_shapes[trunk[1]]
		shape.position = trunk[0]
		body.add_child(shape)
		collider_count += 1


func _is_edge(x: float, z: float) -> bool:
	var beyond: float = _terrain.road_clearance(x, z)
	return beyond >= _clearance and beyond < _clearance + EDGE_DEPTH


func _ground(x: float, z: float) -> float:
	var height: float = _terrain.height_at(x, z)
	var slope := Vector2(_terrain.height_at(x + 1.0, z) - _terrain.height_at(x - 1.0, z),
		_terrain.height_at(x, z + 1.0) - _terrain.height_at(x, z - 1.0)).length() * 0.5
	return height - 0.05 - minf(slope * SLOPE_SINK, MAX_SINK)


func _block_rect(rect: Rect2) -> void:
	for column in range(_column(rect.position.x), _column(rect.end.x) + 1):
		for row in range(_row(rect.position.y), _row(rect.end.y) + 1):
			_blocked[row * _columns + column] = 1


func _is_blocked(x: float, z: float) -> bool:
	return _blocked[_row(z) * _columns + _column(x)] == 1 \
		or _terrain.road_clearance(x, z) < _clearance


func _column(x: float) -> int:
	return clampi(int((x - _area.position.x) / GRID), 0, _columns - 1)


func _row(z: float) -> int:
	return clampi(int((z - _area.position.y) / GRID), 0, _rows - 1)


func _tile_centre(tile: Vector2i) -> Vector2:
	return Vector2(_area.position.x + (tile.x + 0.5) * TILE, _area.position.y + (tile.y + 0.5) * TILE)


func _bark_material() -> ORMMaterial3D:
	var material := ORMMaterial3D.new()
	material.albedo_texture = BARK_ALBEDO
	material.normal_enabled = true
	material.normal_texture = BARK_NORMAL
	material.orm_texture = BARK_ORM
	return material


func _needle_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = NEEDLES
	material.set_shader_parameter("albedo_texture", BRANCH_ALBEDO)
	material.set_shader_parameter("normal_texture", BRANCH_NORMAL)
	return material


func _deadwood_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = NEEDLES
	material.set_shader_parameter("albedo_texture", DEADWOOD_ALBEDO)
	material.set_shader_parameter("normal_texture", DEADWOOD_NORMAL)
	material.set_shader_parameter("backlight_colour", Color.BLACK)
	return material
