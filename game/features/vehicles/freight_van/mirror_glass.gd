extends RefCounted

const HEAD := AABB(Vector3(-1.3, 1.14, -1.95), Vector3(2.6, 0.5, 0.25))
const OUTBOARD := 0.9
const SPLIT := 1.34
const FACING := 0.7
const METAL := 0.8
const SMOOTH := 0.15


static func select(door: MeshInstance3D, place: Transform3D, shine: Image) -> ArrayMesh:
	var arrays := door.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var corners: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var pieces: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	for first in range(0, corners.size(), 3):
		var a := vertices[corners[first]]
		var b := vertices[corners[first + 1]]
		var c := vertices[corners[first + 2]]
		var middle := place * ((a + b + c) / 3.0)
		if not HEAD.has_point(middle) or absf(middle.x) < OUTBOARD:
			continue
		var outward := place.basis * -(b - a).cross(c - a)
		if outward.length() < 2e-9 or outward.normalized().z < FACING:
			continue
		var uv := (uvs[corners[first]] + uvs[corners[first + 1]] + uvs[corners[first + 2]]) / 3.0
		var texel := shine.get_pixel(clampi(int(uv.x * shine.get_width()), 0, shine.get_width() - 1),
			clampi(int(uv.y * shine.get_height()), 0, shine.get_height() - 1))
		if texel.b < METAL or texel.g > SMOOTH:
			continue
		pieces[0 if middle.y > SPLIT else 1].append_array([a, b, c])
	var glass := ArrayMesh.new()
	for index in range(pieces.size()):
		var surface := []
		surface.resize(Mesh.ARRAY_MAX)
		surface[Mesh.ARRAY_VERTEX] = pieces[index]
		glass.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
		glass.surface_set_name(index, "main" if index == 0 else "wide")
	return glass
