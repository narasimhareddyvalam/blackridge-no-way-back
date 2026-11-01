extends Node3D

const SPACING := 2.0
const CHUNK := 32
const VALLEY_EDGE := 55.0
const PLATEAU_EDGE := -225.0
const PLATEAU := 70.0
const PASS_X := 150.0
const PEAKS := 34.0
const PEAK_WIDTH := 150.0
const PLATEAU_ROLL := 6.0
const VALLEY_ROLL := 1.2
const RIM := 80.0
const RIM_HEIGHT := 28.0
const UNDER_ROAD := 0.12
const SHOULDER := 2.0
const CUT := 1.6
const FILL := 1.4
const REACH := 20.0

var area: Rect2
var columns: int = 0
var rows: int = 0
var heights := PackedFloat32Array()
var edge_distance := PackedFloat32Array()


func build(road: RefCounted, bounds: Rect2, flat_areas: Array[Rect2], surface: Material,
		seed_value: int) -> void:
	area = bounds
	columns = int(bounds.size.x / SPACING) + 1
	rows = int(bounds.size.y / SPACING) + 1
	_natural(seed_value)
	_carve(road)
	_flatten(flat_areas)
	for chunk_row in range(0, rows - 1, CHUNK):
		for chunk_column in range(0, columns - 1, CHUNK):
			_chunk(chunk_column, chunk_row, surface)
	_collision()


func height_at(x: float, z: float) -> float:
	return _sample(heights, x, z)


func road_clearance(x: float, z: float) -> float:
	return _sample(edge_distance, x, z)


func _sample(values: PackedFloat32Array, x: float, z: float) -> float:
	var fx := clampf((x - area.position.x) / SPACING, 0.0, columns - 1.001)
	var fz := clampf((z - area.position.y) / SPACING, 0.0, rows - 1.001)
	var column := int(fx)
	var row := int(fz)
	var tx := fx - column
	var tz := fz - row
	var cell := row * columns + column
	var top := lerpf(values[cell], values[cell + 1], tx)
	var bottom := lerpf(values[cell + columns], values[cell + columns + 1], tx)
	return lerpf(top, bottom, tz)


func _natural(seed_value: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.011
	heights.resize(columns * rows)
	for row in range(rows):
		var z := area.position.y + row * SPACING
		var rise := smoothstep(VALLEY_EDGE, PLATEAU_EDGE, z)
		var ridge := smoothstep(PLATEAU_EDGE + 60.0, PLATEAU_EDGE - 40.0, z)
		for column in range(columns):
			var x := area.position.x + column * SPACING
			var roll := noise.get_noise_2d(x, z)
			var edge := minf(minf(x - area.position.x, area.end.x - x),
				minf(z - area.position.y, area.end.y - z))
			var rim := RIM_HEIGHT * pow(smoothstep(RIM, 0.0, edge), 2.0)
			var peaks := PEAKS * (1.0 - exp(-pow((x - PASS_X) / PEAK_WIDTH, 2.0))) * ridge
			heights[row * columns + column] = PLATEAU * rise + peaks + roll * lerpf(VALLEY_ROLL,
				PLATEAU_ROLL, rise) + rim


func _carve(road: RefCounted) -> void:
	var count := columns * rows
	var lower := PackedFloat32Array()
	lower.resize(count)
	lower.fill(-INF)
	var upper := PackedFloat32Array()
	upper.resize(count)
	upper.fill(INF)
	edge_distance.resize(count)
	edge_distance.fill(REACH)
	var nearest := PackedFloat32Array()
	nearest.resize(count)
	var lowest := PackedFloat32Array()
	lowest.resize(count)
	lowest.fill(INF)
	var weight_sum := PackedFloat32Array()
	weight_sum.resize(count)
	var height_sum := PackedFloat32Array()
	height_sum.resize(count)
	var points: PackedVector3Array = road.points
	var half_widths: PackedFloat32Array = road.half_widths
	var reach_cells := ceili((REACH + 4.5) / SPACING)
	for index in range(points.size()):
		var point := points[index]
		var verge: float = half_widths[index] + road.VERGE
		var surface := point.y - UNDER_ROAD
		var limit := (REACH + verge) * (REACH + verge)
		var centre_column := roundi((point.x - area.position.x) / SPACING)
		var centre_row := roundi((point.z - area.position.y) / SPACING)
		for row in range(maxi(centre_row - reach_cells, 0),
				mini(centre_row + reach_cells, rows - 1) + 1):
			var dz := area.position.y + row * SPACING - point.z
			for column in range(maxi(centre_column - reach_cells, 0),
					mini(centre_column + reach_cells, columns - 1) + 1):
				var dx := area.position.x + column * SPACING - point.x
				var squared := dx * dx + dz * dz
				if squared > limit:
					continue
				var beyond := sqrt(squared) - verge
				var cell := row * columns + column
				var weight := 1.0 / (squared + 16.0)
				weight_sum[cell] += weight
				height_sum[cell] += weight * surface
				if beyond < edge_distance[cell]:
					edge_distance[cell] = beyond
					nearest[cell] = surface
				if beyond <= 0.0:
					lowest[cell] = minf(lowest[cell], surface)
				var out := maxf(beyond - SHOULDER, 0.0)
				lower[cell] = maxf(lower[cell], surface - out * FILL)
				upper[cell] = minf(upper[cell], surface + out * CUT)
	for cell in range(count):
		if lower[cell] == -INF:
			continue
		var follow := smoothstep(REACH, SHOULDER, edge_distance[cell])
		heights[cell] = lerpf(heights[cell], height_sum[cell] / weight_sum[cell], follow)
		if edge_distance[cell] <= 0.0:
			heights[cell] = lowest[cell]
		elif edge_distance[cell] <= SHOULDER:
			heights[cell] = nearest[cell]
		elif lower[cell] <= upper[cell]:
			heights[cell] = clampf(heights[cell], lower[cell], upper[cell])
		else:
			heights[cell] = (lower[cell] + upper[cell]) * 0.5


func _flatten(flat_areas: Array[Rect2]) -> void:
	for rect in flat_areas:
		var grown := rect.grow(2.0)
		var first_column := maxi(ceili((grown.position.x - area.position.x) / SPACING), 0)
		var last_column := mini(floori((grown.end.x - area.position.x) / SPACING), columns - 1)
		var first_row := maxi(ceili((grown.position.y - area.position.y) / SPACING), 0)
		var last_row := mini(floori((grown.end.y - area.position.y) / SPACING), rows - 1)
		for row in range(first_row, last_row + 1):
			for column in range(first_column, last_column + 1):
				var cell := row * columns + column
				if edge_distance[cell] > 0.0:
					heights[cell] = 0.0


func _chunk(first_column: int, first_row: int, surface: Material) -> void:
	var last_column := mini(first_column + CHUNK, columns - 1)
	var last_row := mini(first_row + CHUNK, rows - 1)
	var width := last_column - first_column + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for row in range(first_row, last_row + 1):
		for column in range(first_column, last_column + 1):
			var x := area.position.x + column * SPACING
			var z := area.position.y + row * SPACING
			vertices.append(Vector3(x, heights[row * columns + column], z))
			var left := heights[row * columns + maxi(column - 1, 0)]
			var right := heights[row * columns + mini(column + 1, columns - 1)]
			var back := heights[maxi(row - 1, 0) * columns + column]
			var front := heights[mini(row + 1, rows - 1) * columns + column]
			normals.append(Vector3(left - right, 2.0 * SPACING, back - front).normalized())
			uvs.append(Vector2(x, z) * 0.5)
	var indices := PackedInt32Array()
	for row in range(last_row - first_row):
		for column in range(last_column - first_column):
			var a := row * width + column
			indices.append_array([a, a + 1, a + width, a + 1, a + width + 1, a + width])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surface
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _collision() -> void:
	var shape := HeightMapShape3D.new()
	shape.map_width = columns
	shape.map_depth = rows
	var data := PackedFloat32Array()
	data.resize(columns * rows)
	for cell in range(columns * rows):
		data[cell] = heights[cell] / SPACING
	shape.map_data = data
	var body := StaticBody3D.new()
	body.name = "HillCollision"
	add_child(body)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3.ONE * SPACING
	collision.position = Vector3(area.position.x + (columns - 1) * SPACING * 0.5, 0.0,
		area.position.y + (rows - 1) * SPACING * 0.5)
	body.add_child(collision)
