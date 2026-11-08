extends Node3D

const HEAD := 0.13
const END_CAP := 0.026
const BLADE_BODY: Array[Vector2] = [Vector2(-0.0095, -0.0045), Vector2(0.0095, -0.0045),
	Vector2(0.01, -0.008), Vector2(0.0085, -0.011), Vector2(0.004, -0.016),
	Vector2(0.0005, -0.0185), Vector2(-0.0025, -0.0175), Vector2(-0.0065, -0.013),
	Vector2(-0.0095, -0.0095), Vector2(-0.01, -0.008)]
const RUBBER: Array[Vector2] = [Vector2(-0.0006, -0.0003), Vector2(0.0006, -0.0003),
	Vector2(0.002, -0.0047), Vector2(-0.002, -0.0047)]
const BLADE_BASE := Vector2(0.0, -0.0045)

var blade: Node3D


func build(arm_length: float, blade_length: float) -> void:
	var paint := _finish(Color("0b0c0d"), 0.42, 0.35)
	var plastic := _finish(Color("111315"), 0.32, 0.0)
	var rubber := _finish(Color("060606"), 0.85, 0.0)
	_pivot_cap(paint)
	_part(self, "SpringCover", _loft(_box(0.036, -0.02, -0.046), _box(0.026, -0.022, -0.04),
		-0.025, HEAD), paint)
	_part(self, "Arm", _loft(_box(0.016, -0.026, -0.035), _box(0.012, -0.024, -0.031),
		HEAD, arm_length - 0.02), paint)
	_part(self, "Hook", _loft(_box(0.012, -0.024, -0.031), _box(0.012, -0.018, -0.026),
		arm_length - 0.02, arm_length + 0.015), paint)
	blade = Node3D.new()
	blade.name = "Blade"
	add_child(blade)
	blade.position = Vector3(0.0, arm_length, 0.0)
	var half := blade_length * 0.5
	_part(blade, "Spoiler", _loft(BLADE_BODY, BLADE_BODY, END_CAP - half, half - END_CAP),
		plastic)
	var tip := _shrunk(BLADE_BODY, 0.45)
	_part(blade, "EndCapInner", _loft(BLADE_BODY, tip, END_CAP - half, -half), plastic)
	_part(blade, "EndCapOuter", _loft(BLADE_BODY, tip, half - END_CAP, half), plastic)
	_part(blade, "Rubber", _loft(RUBBER, RUBBER, -half, half), rubber)
	var adapter := _box(0.026, -0.008, -0.022)
	_part(blade, "Adapter", _loft(adapter, adapter, -0.03, 0.03), plastic)


func _pivot_cap(surface: Material) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.014
	cylinder.bottom_radius = 0.019
	cylinder.height = 0.026
	cylinder.radial_segments = 16
	var cap := _part(self, "PivotCap", cylinder, surface)
	cap.rotation.x = -PI / 2
	cap.position = Vector3(0.0, 0.0, -0.033)


func _part(parent: Node3D, label: String, mesh: Mesh, surface: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = surface
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _finish(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = roughness
	surface.metallic = metallic
	return surface


func _box(width: float, near: float, far: float) -> Array[Vector2]:
	return [Vector2(-width * 0.5, near), Vector2(width * 0.5, near), Vector2(width * 0.5, far),
		Vector2(-width * 0.5, far)]


func _shrunk(profile: Array[Vector2], scale: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in profile:
		result.append(BLADE_BASE + (point - BLADE_BASE) * scale)
	return result


func _loft(start: Array[Vector2], end: Array[Vector2], from_y: float, to_y: float) -> ArrayMesh:
	if to_y < from_y:
		return _loft(end, start, to_y, from_y)
	var near := _counter_clockwise(start)
	var far := _counter_clockwise(end)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	var count := near.size()
	for index in range(count):
		var next := (index + 1) % count
		var a := Vector3(near[index].x, from_y, near[index].y)
		var b := Vector3(near[next].x, from_y, near[next].y)
		var c := Vector3(far[index].x, to_y, far[index].y)
		var d := Vector3(far[next].x, to_y, far[next].y)
		for corner: Vector3 in [a, b, c, c, b, d]:
			tool.add_vertex(corner)
	for index in range(1, count - 1):
		for corner: Vector2 in [far[0], far[index], far[index + 1]]:
			tool.add_vertex(Vector3(corner.x, to_y, corner.y))
		for corner: Vector2 in [near[0], near[index + 1], near[index]]:
			tool.add_vertex(Vector3(corner.x, from_y, corner.y))
	tool.generate_normals()
	return tool.commit()


func _counter_clockwise(profile: Array[Vector2]) -> Array[Vector2]:
	var area := 0.0
	for index in range(profile.size()):
		var a := profile[index]
		var b := profile[(index + 1) % profile.size()]
		area += a.x * b.y - b.x * a.y
	var result := profile.duplicate()
	if area < 0.0:
		result.reverse()
	return result
