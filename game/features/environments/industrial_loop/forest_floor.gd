extends Node3D

const MODELS := "res://features/environments/industrial_loop/polyhaven/models/%s/%s.gltf"
const SHADOW_RANGE := 30.0
const PROPS: Array[Dictionary] = [
	{"model": "fern_02", "count": 9500, "near": 3.5, "far": 22.0, "scale": Vector2(1.6, 2.4),
		"visible": 55.0, "tile": 24.0, "shadows": false},
	{"model": "dry_branches_medium_01", "count": 1500, "near": 3.6, "far": 24.0,
		"scale": Vector2(0.8, 1.3), "visible": 45.0, "tile": 24.0, "shadows": false},
	{"model": "tree_stump_01", "count": 140, "near": 4.6, "far": 60.0, "scale": Vector2(0.8, 1.2),
		"visible": 90.0, "tile": 24.0, "shadows": true},
	{"model": "rock_moss_set_02", "count": 160, "near": 4.6, "far": 60.0,
		"scale": Vector2(0.6, 1.4), "visible": 90.0, "tile": 24.0, "shadows": true},
	{"model": "dead_tree_trunk", "count": 30, "near": 6.5, "far": 60.0, "scale": Vector2(0.9, 1.1),
		"visible": 110.0, "tile": 24.0, "shadows": true},
	{"model": "fern_02", "count": 2600, "near": 22.0, "far": 70.0, "scale": Vector2(1.4, 2.2),
		"visible": 55.0, "tile": 24.0, "shadows": false, "clump": true},
	{"model": "dry_branches_medium_01", "count": 500, "near": 22.0, "far": 70.0,
		"scale": Vector2(0.8, 1.3), "visible": 40.0, "tile": 24.0, "shadows": false,
		"clump": true},
]
const PATCH_SEED := 77
const PROP_SCALE := 1.4
const VERGE_REACH := 3.4

var prop_count: int = 0
var _segments: Array[PackedVector2Array] = []
var _cumulative := PackedFloat32Array()
var _terrain: Node3D


func build(road_points: PackedVector3Array, clearings: Array[Rect2], seed_value: int,
		terrain: Node3D) -> void:
	_terrain = terrain
	for index in range(road_points.size()):
		var a := road_points[index]
		var b := road_points[(index + 1) % road_points.size()]
		_segments.append(PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z)]))
		var length := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
		var total := 0.0 if _cumulative.is_empty() else _cumulative[_cumulative.size() - 1]
		_cumulative.append(total + length)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var patches := FastNoiseLite.new()
	patches.seed = seed_value + PATCH_SEED
	patches.frequency = 0.035
	for prop in PROPS:
		var parts := _meshes(prop["model"])
		var tile_size: float = prop["tile"]
		var tiles := {}
		var placed := 0
		var wanted := int(prop["count"] * PROP_SCALE)
		for attempt in range(wanted * 3):
			if placed >= wanted:
				break
			var point := _candidate(rng, prop["near"], prop["far"])
			if _blocked(point, prop["near"], clearings):
				continue
			if prop.get("clump", false) and patches.get_noise_2d(point.x, point.y) < 0.0:
				continue
			var part := rng.randi_range(0, parts.size() - 1)
			var size := rng.randf_range(prop["scale"].x, prop["scale"].y)
			var key := Vector3i(floori(point.x / tile_size), floori(point.y / tile_size), part)
			if not tiles.has(key):
				tiles[key] = []
			var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			var centre := _tile_centre(key, tile_size)
			var ground: float = _terrain.height_at(point.x, point.y)
			tiles[key].append(Transform3D(turn, Vector3(point.x - centre.x, ground,
				point.y - centre.y)) * parts[part][1])
			placed += 1
		prop_count += placed
		for key: Vector3i in tiles:
			_add(parts[key.z][0], tiles[key], _tile_centre(key, tile_size), prop["visible"],
				prop["shadows"])


func _candidate(rng: RandomNumberGenerator, near: float, far: float) -> Vector2:
	var distance := rng.randf() * _cumulative[_cumulative.size() - 1]
	var segment := _segments[mini(_cumulative.bsearch(distance), _segments.size() - 1)]
	var along := segment[0].lerp(segment[1], rng.randf())
	var direction := (segment[1] - segment[0]).normalized()
	var side := Vector2(-direction.y, direction.x) * (1.0 if rng.randf() < 0.5 else -1.0)
	return along + side * lerpf(near, far, pow(rng.randf(), 1.6))


func _blocked(point: Vector2, near: float, clearings: Array[Rect2]) -> bool:
	for rect in clearings:
		if rect.has_point(point):
			return true
	return _terrain.road_clearance(point.x, point.y) < near - VERGE_REACH


func _meshes(model: String) -> Array:
	var scene := load(MODELS % [model, model]) as PackedScene
	var root := scene.instantiate()
	var result := []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var offset := Transform3D.IDENTITY
		var walk: Node = node
		while walk != root:
			offset = (walk as Node3D).transform * offset
			walk = walk.get_parent()
		offset.origin = Vector3(0.0, offset.origin.y, 0.0)
		result.append([(node as MeshInstance3D).mesh, offset])
	root.free()
	return result


func _add(mesh: Mesh, transforms: Array, centre: Vector2, visible_range: float,
		shadows: bool) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	if shadows:
		_instance(multimesh, centre, 0.0, SHADOW_RANGE, true)
		_instance(multimesh, centre, SHADOW_RANGE, visible_range, false)
	else:
		_instance(multimesh, centre, 0.0, visible_range, false)


func _instance(multimesh: MultiMesh, centre: Vector2, begin: float, end: float,
		shadows: bool) -> void:
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.position = Vector3(centre.x, 0.0, centre.y)
	instance.visibility_range_begin = begin
	instance.visibility_range_begin_margin = 5.0 if begin > 0.0 else 0.0
	instance.visibility_range_end = end
	instance.visibility_range_end_margin = 5.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _tile_centre(key: Vector3i, tile_size: float) -> Vector2:
	return (Vector2(key.x, key.y) + Vector2(0.5, 0.5)) * tile_size
