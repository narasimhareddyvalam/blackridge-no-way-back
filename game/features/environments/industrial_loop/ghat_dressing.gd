extends Node3D

const GhatRoad = preload("ghat_road.gd")
const SIGNS = preload("art/road_signs.png")
const ROCKS := "res://features/environments/industrial_loop/polyhaven/models/rock_moss_set_02/" \
	+ "rock_moss_set_02.gltf"
const STONE := "res://features/environments/industrial_loop/polyhaven/textures/" \
	+ "rustic_stone_wall/rustic_stone_wall_%s_1k.jpg"
const CELLS := {"hairpin_left": 0, "hairpin_right": 1, "curve_left": 2, "curve_right": 3,
	"chevron_left": 4, "chevron_right": 5, "speed_15": 6, "speed_20": 7, "speed_25": 8,
	"steep_grade": 9, "grade_9": 10, "road_closed": 11, "landslide": 12, "scenic_view": 13,
	"low_gear": 14}
const FACE_SIZE := {"diamond": 1.15, "plate": 0.62, "chevron": 0.75, "board": 1.25}
const DROP := 1.2
const DEEP_DROP := 3.0
const DROP_PROBE := 6.5
const RAIL_INSET := 0.35
const RAIL_CENTRE := 0.62
const POST := Vector3(0.15, 0.95, 0.1)
const WALL := Vector2(0.48, 0.62)
const CAP := Vector2(0.62, 0.1)
const SHOULDER_POST := 0.9
const DELINEATOR_STEP := 13
const WARNING_LEAD := 30
const CURVE_RADIUS := 45.0
const LANDSLIDE_LENGTH := 9
const RUN_EXTENSION := 2
const RUN_GAP := 6

var guardrail_segments: int = 0
var wall_segments: int = 0
var delineator_count: int = 0
var mirror_count: int = 0
var signs: Array[Dictionary] = []

var _road: RefCounted
var _terrain: Node3D
var _points := PackedVector3Array()
var _faces := {}
var _shapes := {}
var _posts: Array[Transform3D] = []
var _steel := StandardMaterial3D.new()
var _concrete: Material
var _flashers: Array[MeshInstance3D] = []


func build(road: RefCounted, terrain: Node3D, concrete: Material, landslide_at: Vector2) -> void:
	_road = road
	_terrain = terrain
	_points = road.points
	_concrete = concrete
	_steel.albedo_color = Color("70777b")
	_steel.metallic = 0.7
	_steel.roughness = 0.58
	_steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var landslide := _nearest(landslide_at)
	var drops := _drops(landslide)
	_barriers(drops)
	_delineators(drops)
	_hairpin_signs()
	_curve_signs()
	_grade_signs()
	_landslide(landslide)
	_mirrors()
	_build_signs()


func _drops(landslide: int) -> Array[PackedByteArray]:
	var left := PackedByteArray()
	var right := PackedByteArray()
	left.resize(_points.size())
	right.resize(_points.size())
	for index in range(_points.size()):
		if absi(index - landslide) < LANDSLIDE_LENGTH * 3:
			continue
		var frame := _frame(index)
		var reach: float = _road.half_widths[index] + GhatRoad.VERGE - RAIL_INSET
		var depth := PackedFloat32Array()
		for side: float in [-1.0, 1.0]:
			var probe: Vector3 = frame["here"] + frame["right"] * side * (reach + DROP_PROBE)
			depth.append(_points[index].y - _terrain.height_at(probe.x, probe.z))
		var both := depth[0] >= DROP and depth[1] >= DROP
		for side_index in range(2):
			var dropped := depth[side_index] >= DROP and (not both or depth[side_index]
				>= depth[1 - side_index] or depth[1 - side_index] >= DEEP_DROP)
			var side := -1.0 if side_index == 0 else 1.0
			if dropped or (_road.is_layby(index) and side == _outer_side(index)):
				(left if side_index == 0 else right)[index] = 1
	return [_continuous(left, landslide), _continuous(right, landslide)]


func _continuous(flags: PackedByteArray, landslide: int) -> PackedByteArray:
	var count := flags.size()
	var grown := flags.duplicate()
	for index in range(count):
		if flags[index] == 0:
			continue
		for offset in range(-RUN_EXTENSION, RUN_EXTENSION + 1):
			grown[posmod(index + offset, count)] = 1
	var filled := grown.duplicate()
	for index in range(count):
		if grown[index] != 0 or grown[posmod(index - 1, count)] == 0:
			continue
		for gap in range(1, RUN_GAP + 1):
			if grown[posmod(index + gap, count)] != 0:
				for fill in range(gap):
					filled[posmod(index + fill, count)] = 1
				break
	for index in range(count):
		if absi(index - landslide) < LANDSLIDE_LENGTH * 3:
			filled[index] = 0
	return filled


func _barriers(drops: Array[PackedByteArray]) -> void:
	var rails: Array[Transform3D] = []
	var walls: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var shapes: Array = []
	var count := _points.size()
	for index in range(count):
		var next := (index + 1) % count
		for side_index in range(2):
			if drops[side_index][index] == 0 or drops[side_index][next] == 0:
				continue
			var side := -1.0 if side_index == 0 else 1.0
			var start := _edge(index, side, RAIL_INSET)
			var end := _edge(next, side, RAIL_INSET)
			var along := end - start
			var outward := (_frame(index)["right"] as Vector3) * side
			var basis := Basis(outward, along.normalized().cross(outward).normalized(),
				along.normalized())
			var middle := (start + end) * 0.5
			var length := along.length()
			if _stone_here(index):
				walls.append(Transform3D(basis.scaled_local(Vector3(WALL.x, WALL.y, length)),
					middle + Vector3.UP * (WALL.y * 0.5 - 0.05)))
				caps.append(Transform3D(basis.scaled_local(Vector3(CAP.x, CAP.y, length + 0.02)),
					middle + Vector3.UP * (WALL.y - 0.05 + CAP.y * 0.5)))
				wall_segments += 1
			else:
				rails.append(Transform3D(basis.scaled_local(Vector3(1.0, 1.0, along.length())),
					middle + Vector3.UP * RAIL_CENTRE))
				_posts.append(Transform3D(basis.scaled_local(POST), start + outward * 0.12
					+ Vector3.UP * (POST.y * 0.5 - 0.1)))
				guardrail_segments += 1
			shapes.append([Transform3D(basis, middle + Vector3.UP * 0.42),
				Vector3(0.3, 0.85, along.length())])
	_multimesh(_rail_mesh(), rails, _steel, "Guardrails")
	_multimesh(_box(), walls, _stone(), "StoneWalls")
	_multimesh(_box(), caps, _stone(), "StoneWallCaps")
	var body := StaticBody3D.new()
	body.name = "Barriers"
	add_child(body)
	for item: Array in shapes:
		var shape := BoxShape3D.new()
		shape.size = item[1]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = item[0]
		body.add_child(collision)


func _delineators(drops: Array[PackedByteArray]) -> void:
	var posts: Array[Transform3D] = []
	var lenses: Array[Transform3D] = []
	for index in range(0, _points.size(), DELINEATOR_STEP):
		if _road.sections[index] == GhatRoad.Section.VALLEY:
			continue
		var facing := Basis(Vector3.UP, _road.heading_at(index))
		for side_index in range(2):
			if drops[side_index][index] != 0:
				continue
			var at := _edge(index, -1.0 if side_index == 0 else 1.0, -0.3)
			at.y = _terrain.height_at(at.x, at.z)
			posts.append(Transform3D(facing.scaled_local(Vector3(0.1, 1.1, 0.08)),
				at + Vector3.UP * 0.5))
			lenses.append(Transform3D(facing.scaled_local(Vector3(0.07, 0.16, 0.012)),
				at + Vector3(0, 0.92, 0) + facing.z * 0.045))
			delineator_count += 1
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("e8e8e2")
	white.roughness = 0.6
	var lens := StandardMaterial3D.new()
	lens.albedo_color = Color("f4f1e6")
	lens.metallic = 0.6
	lens.roughness = 0.12
	_multimesh(_box(), posts, white, "Delineators")
	_multimesh(_box(), lenses, lens, "DelineatorReflectors")


func _hairpin_signs() -> void:
	for run: Vector2i in _runs(func(index: int) -> bool: return _road.is_hairpin(index)):
		var turn := _turn(run)
		var radius := (run.y - run.x) * GhatRoad.SPACING / maxf(absf(turn), 0.1)
		var left := turn > 0.0
		var warn := posmod(run.x - WARNING_LEAD, _points.size())
		if _road.is_layby(run.x):
			_sign("scenic_view", posmod(warn - 10, _points.size()), 1.0, 2.2, "board")
		_sign("hairpin_left" if left else "hairpin_right", warn, 1.0, 2.15, "diamond")
		_sign("speed_15" if radius < 12.0 else "speed_20", warn, 1.0, 1.35, "plate")
		var outside := -1.0 if left else 1.0
		for index in range(run.x, run.y + 1, 4):
			_sign("chevron_left" if left else "chevron_right", index, outside, 1.3, "chevron",
				_road.heading_at(posmod(index - 8, _points.size())))


func _curve_signs() -> void:
	var sharp := func(index: int) -> bool:
		if _road.sections[index] == GhatRoad.Section.VALLEY or _near_hairpin(index, 25):
			return false
		var turn := angle_difference(_road.heading_at(posmod(index - 5, _points.size())),
			_road.heading_at((index + 5) % _points.size()))
		return absf(turn) > 10.0 * GhatRoad.SPACING / CURVE_RADIUS
	for run: Vector2i in _runs(sharp):
		var turn := _turn(run)
		var warn := posmod(run.x - WARNING_LEAD + 5, _points.size())
		if _near_hairpin(warn, 12):
			continue
		_sign("curve_left" if turn > 0.0 else "curve_right", warn, 1.0, 2.15, "diamond")
		_sign("speed_25", warn, 1.0, 1.35, "plate")


func _grade_signs() -> void:
	var first: int = _road.sections.find(GhatRoad.Section.DESCENT)
	_sign("steep_grade", first + 4, 1.0, 2.15, "diamond")
	_sign("grade_9", first + 4, 1.0, 1.35, "plate")
	_sign("low_gear", first + 22, 1.0, 1.7, "board")


func _landslide(index: int) -> void:
	var frame := _frame(index)
	var rocks := (load(ROCKS) as PackedScene).instantiate()
	var parts := rocks.find_children("*", "MeshInstance3D", true, false)
	var random := RandomNumberGenerator.new()
	random.seed = 9071
	var body := StaticBody3D.new()
	body.name = "Landslide"
	add_child(body)
	for step in range(-LANDSLIDE_LENGTH, LANDSLIDE_LENGTH + 1, 2):
		for lateral: float in [-2.6, -0.4, 1.9]:
			var at: Vector3 = _points[posmod(index + step, _points.size())] \
				+ (frame["right"] as Vector3) * (lateral + random.randf_range(-0.8, 0.8))
			var size := random.randf_range(1.6, 3.4) * (1.0 - absf(step) / 14.0)
			var rock := MeshInstance3D.new()
			rock.mesh = (parts[random.randi() % parts.size()] as MeshInstance3D).mesh
			rock.position = at + Vector3.UP * size * 0.15
			rock.rotation = Vector3(random.randf() * TAU, random.randf() * TAU, 0)
			rock.scale = Vector3.ONE * size * 1.6
			body.add_child(rock)
			var shape := CollisionShape3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = size * 0.55
			shape.shape = sphere
			shape.position = rock.position
			body.add_child(shape)
	rocks.free()
	var amber := StandardMaterial3D.new()
	amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amber.albedo_color = Color("ffae2b")
	for direction: int in [-1, 1]:
		var stop := posmod(index + direction * (LANDSLIDE_LENGTH + 8), _points.size())
		var heading: float = _road.heading_at(stop) + (PI if direction > 0 else 0.0)
		var facing := Basis(Vector3.UP, heading)
		for lateral: float in [-2.0, 0.0, 2.0]:
			var at := _points[stop] + (_frame(stop)["right"] as Vector3) * lateral
			var block := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(1.9, 0.8, 0.5)
			block.mesh = mesh
			block.material_override = _concrete
			block.transform = Transform3D(facing, at + Vector3.UP * 0.4)
			body.add_child(block)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = mesh.size
			shape.shape = box
			shape.transform = block.transform
			body.add_child(shape)
			var lamp := MeshInstance3D.new()
			var bulb := SphereMesh.new()
			bulb.radius = 0.09
			bulb.height = 0.18
			lamp.mesh = bulb
			lamp.material_override = amber
			lamp.transform = Transform3D(facing, at + Vector3.UP * 0.9)
			body.add_child(lamp)
			_flashers.append(lamp)
		_sign("road_closed", stop, 0.0, 1.35, "board", heading, 0.0)
		var warn := posmod(index + direction * 35, _points.size())
		var side := 1.0 if direction < 0 else -1.0
		_sign("landslide", warn, side, 2.15, "diamond", heading)
	var timer := Timer.new()
	timer.wait_time = 0.55
	timer.autostart = true
	timer.timeout.connect(_flash)
	add_child(timer)


func _flash() -> void:
	for lamp in _flashers:
		lamp.visible = not lamp.visible


func _mirrors() -> void:
	var tightest := {}
	for run: Vector2i in _runs(func(index: int) -> bool: return _road.is_hairpin(index)):
		var turn := _turn(run)
		var radius := (run.y - run.x) * GhatRoad.SPACING / maxf(absf(turn), 0.1)
		var key: int = _road.sections[run.x]
		if not tightest.has(key) or radius < tightest[key][1]:
			tightest[key] = [run, radius, turn]
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color("e8601c")
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("c9cfd2")
	glass.metallic = 1.0
	glass.roughness = 0.04
	for key in tightest:
		var run: Vector2i = tightest[key][0]
		var apex := (run.x + run.y) / 2
		var outside := -1.0 if tightest[key][2] > 0.0 else 1.0
		var at := _edge(apex, outside, -1.2)
		at.y = _terrain.height_at(at.x, at.z)
		var holder := Node3D.new()
		holder.name = "ConvexMirror"
		add_child(holder)
		holder.transform = Transform3D(Basis(Vector3.UP, _road.heading_at(run.x)), at)
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.04
		pole_mesh.bottom_radius = 0.04
		pole_mesh.height = 2.7
		pole.mesh = pole_mesh
		pole.material_override = _steel
		pole.position = Vector3(0, 1.35, 0)
		holder.add_child(pole)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.40
		torus.outer_radius = 0.47
		ring.mesh = torus
		ring.material_override = orange
		ring.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 2.75, 0.04))
		holder.add_child(ring)
		var dome := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.42
		sphere.height = 0.84
		dome.mesh = sphere
		dome.material_override = glass
		dome.transform = Transform3D(Basis.IDENTITY.scaled_local(Vector3(1.0, 1.0, 0.22)),
			Vector3(0, 2.75, 0.02))
		holder.add_child(dome)
		mirror_count += 1


func _sign(kind: String, index: int, side: float, height: float, shape: String,
		heading: float = NAN, offset: float = SHOULDER_POST) -> void:
	var at := _edge(index, side, -offset) if side != 0.0 else _points[index]
	at.y = _terrain.height_at(at.x, at.z) if side != 0.0 else _points[index].y
	var facing := Basis(Vector3.UP, _road.heading_at(index) if is_nan(heading) else heading)
	var size: float = FACE_SIZE[shape]
	if not _faces.has(kind):
		var poses: Array[Transform3D] = []
		_faces[kind] = poses
		_shapes[kind] = shape
	_faces[kind].append(Transform3D(facing.scaled_local(Vector3(size, size, 1.0)),
		at + Vector3.UP * height + facing.z * 0.05))
	if side != 0.0 and shape != "plate":
		_posts.append(Transform3D(facing.scaled_local(Vector3(0.07, height + 0.3, 0.07)),
			at + Vector3.UP * (height + 0.3) * 0.5))
	signs.append({"kind": kind, "at": at, "index": index})


func _build_signs() -> void:
	for kind: String in _faces:
		var face := StandardMaterial3D.new()
		face.albedo_texture = SIGNS
		face.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		face.alpha_scissor_threshold = 0.5
		face.albedo_color = Color(0.55, 0.55, 0.55)
		face.roughness = 0.6
		var cell: int = CELLS[kind]
		face.uv1_scale = Vector3(0.25, 0.25, 1.0)
		face.uv1_offset = Vector3((cell % 4) * 0.25, (cell / 4) * 0.25, 0.0)
		var quad := QuadMesh.new()
		var back := StandardMaterial3D.new()
		back.albedo_color = Color("50565a")
		back.metallic = 0.3
		back.roughness = 0.75
		quad.material = face
		_multimesh(quad, _faces[kind], null, "Sign_" + kind)
		var diamond: bool = _shapes[kind] == "diamond"
		var backs: Array[Transform3D] = []
		for pose: Transform3D in _faces[kind]:
			var turned := pose.basis.rotated(pose.basis.y.normalized(), PI)
			if diamond:
				turned = turned.rotated(turned.z.normalized(), PI / 4)
			backs.append(Transform3D(turned, pose.origin - pose.basis.z.normalized() * 0.012))
		var back_quad := QuadMesh.new()
		back_quad.material = back
		back_quad.size = Vector2(0.67, 0.67) if diamond else Vector2(0.9, 0.56)
		_multimesh(back_quad, backs, null, "SignBack_" + kind)
	_multimesh(_box(), _posts, _steel, "Posts")


func _rail_mesh() -> ArrayMesh:
	var profile := [Vector2(0.0, -0.155), Vector2(-0.045, -0.12), Vector2(-0.045, -0.075),
		Vector2(0.0, -0.035), Vector2(0.0, 0.035), Vector2(-0.045, 0.075),
		Vector2(-0.045, 0.12), Vector2(0.0, 0.155)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(profile.size() - 1):
		var a: Vector2 = profile[index]
		var b: Vector2 = profile[index + 1]
		var normal := Vector3(-(b.y - a.y), b.x - a.x, 0.0).normalized()
		for corner: Vector3 in [Vector3(a.x, a.y, -0.5), Vector3(b.x, b.y, -0.5),
				Vector3(a.x, a.y, 0.5), Vector3(a.x, a.y, 0.5), Vector3(b.x, b.y, -0.5),
				Vector3(b.x, b.y, 0.5)]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(corner.z, corner.y))
			tool.add_vertex(corner)
	return tool.commit()


func _box() -> BoxMesh:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	return box


func _stone() -> StandardMaterial3D:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load(STONE % "diff")
	stone.normal_enabled = true
	stone.normal_texture = load(STONE % "nor_gl")
	stone.roughness_texture = load(STONE % "arm")
	stone.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	stone.albedo_color = Color(0.42, 0.42, 0.4)
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE * 0.8
	return stone


func _multimesh(mesh: Mesh, poses: Array[Transform3D], surface: Material, label: String) -> void:
	if poses.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = poses.size()
	for index in range(poses.size()):
		multimesh.set_instance_transform(index, poses[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	if surface:
		instance.material_override = surface
	add_child(instance)


func _frame(index: int) -> Dictionary:
	var here := _points[index]
	var ahead := _points[(index + 1) % _points.size()] - here
	var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
	return {"here": here, "forward": forward, "right": forward.cross(Vector3.UP)}


func _edge(index: int, side: float, inset: float) -> Vector3:
	var reach: float = _road.half_widths[index] + GhatRoad.VERGE - inset
	return _points[index] + (_frame(index)["right"] as Vector3) * side * reach


func _stone_here(index: int) -> bool:
	return _near_hairpin(index, 4) or _road.is_layby(index)


func _near_hairpin(index: int, reach: int) -> bool:
	for offset in range(-reach, reach + 1):
		if _road.is_hairpin(posmod(index + offset, _points.size())):
			return true
	return false


func _outer_side(index: int) -> float:
	var turn := angle_difference(_road.heading_at(posmod(index - 6, _points.size())),
		_road.heading_at((index + 6) % _points.size()))
	return -1.0 if turn > 0.0 else 1.0


func _turn(run: Vector2i) -> float:
	var total := 0.0
	for index in range(run.x, run.y):
		total += angle_difference(_road.heading_at(index), _road.heading_at(index + 1))
	return total


func _runs(test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for index in range(_points.size()):
		var inside: bool = test.call(index)
		if inside and start < 0:
			start = index
		elif not inside and start >= 0:
			runs.append(Vector2i(start, index - 1))
			start = -1
	if start >= 0:
		runs.append(Vector2i(start, _points.size() - 1))
	return runs


func _nearest(at: Vector2) -> int:
	var best := 0
	for index in range(_points.size()):
		if Vector2(_points[index].x, _points[index].z).distance_squared_to(at) \
				< Vector2(_points[best].x, _points[best].z).distance_squared_to(at):
			best = index
	return best
