extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const GhatRoad = preload("ghat_road.gd")
const BIN := "res://features/environments/depot_yard/polyhaven/models/metal_trash_can/" \
	+ "metal_trash_can.gltf"
const LENGTH := 3.0
const SHELTER_BACK := 5
const SHELTER := Vector3(3.2, 2.35, 1.6)
const SETBACK := 1.3
const GLASS_HEIGHT := 1.75
const KERB_OUT := 0.35
const PATH_WIDTH := 1.3
const PATH_LENGTH := 26.0
const PATH_STEP := 1.0
const TIMETABLE := "BLACKRIDGE TRANSIT\nROUTE 4  HILL ROAD - TOWN\n\nWEEKDAYS\n" \
	+ "5:40  6:40  7:40  8:40\n12:10  3:10  5:10\n7:10  9:10  11:40"

var index: int = -1
var centre := Vector3.ZERO
var forward := Vector3.FORWARD
var right := Vector3.RIGHT
var half_width: float = 0.0
var kerb := Vector3.ZERO
var clearings: Array[Rect2] = []

var _steel := StandardMaterial3D.new()
var _glass := StandardMaterial3D.new()


func build(road: RefCounted, terrain: Node3D, near: Vector2, concrete: Material,
		gravel: Material) -> void:
	var points: PackedVector3Array = road.points
	index = _nearest(points, near)
	var frame := _frame(points, index)
	centre = points[index]
	forward = frame[0]
	right = frame[1]
	half_width = road.half_widths[index]
	kerb = centre + right * (half_width + KERB_OUT)
	_materials()
	_shelter(road, terrain, concrete)
	_path(terrain, gravel)


func paint(asphalt: ShaderMaterial) -> void:
	asphalt.set_shader_parameter("crossing_centre", Vector2(centre.x, centre.z))
	asphalt.set_shader_parameter("crossing_along", Vector2(forward.x, forward.z))
	asphalt.set_shader_parameter("crossing_size", Vector2(LENGTH, half_width * 2.0))


func _materials() -> void:
	_steel.albedo_color = Color("70777b")
	_steel.metallic = 0.65
	_steel.roughness = 0.5
	_glass.albedo_color = Color(0.55, 0.63, 0.64, 0.16)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.roughness = 0.06
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED


func _shelter(road: RefCounted, terrain: Node3D, concrete: Material) -> void:
	var points: PackedVector3Array = road.points
	var at_index := posmod(index - SHELTER_BACK, points.size())
	var frame := _frame(points, at_index)
	var reach: float = road.half_widths[at_index] + GhatRoad.VERGE + SETBACK + SHELTER.z * 0.5
	var at: Vector3 = points[at_index] + frame[1] * reach
	at.y = terrain.height_at(at.x, at.z)
	var shelter := Node3D.new()
	shelter.name = "Shelter"
	shelter.transform = Transform3D(Basis(-frame[0], Vector3.UP, -frame[1]), at)
	add_child(shelter)
	var length := SHELTER.x
	var depth := SHELTER.z
	var height := SHELTER.y
	Build.box(shelter, Vector3(0, 0.0, 0.35), Vector3(length + 0.6, 0.14, depth + 0.9), concrete,
		true)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			Build.box(shelter, Vector3(x * (length * 0.5 - 0.05), height * 0.5,
				z * (depth * 0.5 - 0.05)), Vector3(0.07, height, 0.07), _steel, true)
	var roof := Build.box(shelter, Vector3(0, height + 0.05, 0.05),
		Vector3(length + 0.3, 0.06, depth + 0.4), Build.material(Color("2b3033"), 0.45))
	roof.rotation.x = -0.05
	var glass_y := 0.25 + GLASS_HEIGHT * 0.5
	Build.box(shelter, Vector3(0, glass_y, -depth * 0.5 + 0.03),
		Vector3(length - 0.12, GLASS_HEIGHT, 0.012), _glass, true)
	for x: float in [-1.0, 1.0]:
		Build.box(shelter, Vector3(x * (length * 0.5 - 0.03), glass_y, -0.1),
			Vector3(0.012, GLASS_HEIGHT, depth - 0.35), _glass)
	Build.box(shelter, Vector3(0, 0.22, -depth * 0.5 + 0.03), Vector3(length - 0.1, 0.05, 0.05),
		_steel)
	Build.box(shelter, Vector3(0, 0.25 + GLASS_HEIGHT, -depth * 0.5 + 0.03),
		Vector3(length - 0.1, 0.05, 0.05), _steel)
	_bench(shelter, length, depth)
	_timetable(shelter, length)
	var bin := (load(BIN) as PackedScene).instantiate() as Node3D
	bin.position = Vector3(length * 0.5 + 0.45, 0.07, depth * 0.5 + 0.1)
	shelter.add_child(bin)
	clearings.append(_rect_around(at, 5.0))


func _bench(shelter: Node3D, length: float, depth: float) -> void:
	var wood := Build.material(Color("5a3f2a"), 0.72)
	for slat in range(3):
		Build.box(shelter, Vector3(0, 0.46, -depth * 0.5 + 0.22 + slat * 0.11),
			Vector3(length - 0.7, 0.035, 0.09), wood)
	for x: float in [-1.0, 1.0]:
		Build.box(shelter, Vector3(x * (length * 0.5 - 0.65), 0.23, -depth * 0.5 + 0.33),
			Vector3(0.05, 0.44, 0.3), _steel)


func _timetable(shelter: Node3D, length: float) -> void:
	var x := -length * 0.5 + 0.06
	Build.box(shelter, Vector3(x, 1.4, -0.25), Vector3(0.03, 0.78, 0.56),
		Build.material(Color("d9d6cc"), 0.6))
	var words := Build.text(shelter, TIMETABLE, Vector3(x + 0.02, 1.4, -0.25), 22,
		Color("1d2a3a"))
	words.pixel_size = 0.0016
	words.rotation.y = PI * 0.5


func _path(terrain: Node3D, gravel: Material) -> void:
	var start := centre - right * (half_width + GhatRoad.VERGE)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := int(PATH_LENGTH / PATH_STEP)
	var previous_left := Vector3.ZERO
	var previous_right := Vector3.ZERO
	for step in range(steps + 1):
		var along := step * PATH_STEP
		var sway := sin(along * 0.23) * 0.9 * clampf(along / 6.0, 0.0, 1.0)
		var middle := start - right * along + forward * sway
		var side := forward * PATH_WIDTH * 0.5
		var left_edge := middle - side
		var right_edge := middle + side
		left_edge.y = terrain.height_at(left_edge.x, left_edge.z) + 0.03
		right_edge.y = terrain.height_at(right_edge.x, right_edge.z) + 0.03
		if step > 0:
			for vertex in [previous_left, right_edge, previous_right, previous_left, left_edge,
					right_edge]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(vertex.x, vertex.z))
				tool.add_vertex(vertex)
		previous_left = left_edge
		previous_right = right_edge
		if step % 2 == 0 or step == steps:
			clearings.append(_rect_around(middle, 1.6))
	tool.generate_tangents()
	var path := MeshInstance3D.new()
	path.name = "Footpath"
	path.mesh = tool.commit()
	path.material_override = gravel
	path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(path)


func _rect_around(at: Vector3, reach: float) -> Rect2:
	return Rect2(at.x - reach, at.z - reach, reach * 2.0, reach * 2.0)


func _frame(points: PackedVector3Array, at: int) -> Array[Vector3]:
	var count := points.size()
	var ahead := points[(at + 1) % count] - points[posmod(at - 1, count)]
	var along := Vector3(ahead.x, 0.0, ahead.z).normalized()
	return [along, along.cross(Vector3.UP)]


func _nearest(points: PackedVector3Array, near: Vector2) -> int:
	var best := 0
	for at in range(points.size()):
		if Vector2(points[at].x, points[at].z).distance_squared_to(near) \
				< Vector2(points[best].x, points[best].z).distance_squared_to(near):
			best = at
	return best
