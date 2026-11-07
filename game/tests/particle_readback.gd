extends RefCounted
## Reads particle settings back from a loaded effect scene for the configuration tests.
##
## `expected` maps each part of an emitter to the brief's values: "node" (GPUParticles3D),
## "process" (ParticleProcessMaterial), "draw" (StandardMaterial3D), "mesh" (QuadMesh),
## "texture" (the draw material's albedo texture path), and "alpha_curve" or "scale_curve"
## (the curve's points). Every value is checked and reported with what was found.


static func check_emitter(emitter: GPUParticles3D, expected: Dictionary, check: Callable,
		label: String) -> void:
	check.call(emitter != null, "%s is a GPUParticles3D" % label)
	if emitter == null:
		return
	var process := emitter.process_material as ParticleProcessMaterial
	check.call(process != null, "%s uses a ParticleProcessMaterial" % label)
	var mesh := emitter.draw_pass_1 as QuadMesh
	check.call(mesh != null, "%s draws a QuadMesh" % label)
	var draw: StandardMaterial3D = mesh.material as StandardMaterial3D if mesh else null
	check.call(draw != null, "%s's quad uses a StandardMaterial3D" % label)
	_check_values(emitter, expected.get("node", {}), check, label)
	if process:
		_check_values(process, expected.get("process", {}), check, label + " process")
		for curve_name: String in ["alpha_curve", "scale_curve"]:
			if expected.has(curve_name):
				var found := curve_points(process.get(curve_name) as CurveTexture)
				check.call(same_points(found, expected[curve_name]),
					"%s %s keys %s (found %s)" % [label, curve_name, expected[curve_name], found])
	if mesh:
		_check_values(mesh, expected.get("mesh", {}), check, label + " quad")
	if draw:
		_check_values(draw, expected.get("draw", {}), check, label + " material")
		if expected.has("texture"):
			var texture := draw.albedo_texture
			var path := texture.resource_path if texture else "none"
			check.call(path == expected["texture"],
				"%s texture is %s (found %s)" % [label, expected["texture"], path])


static func _check_values(target: Object, values: Dictionary, check: Callable,
		label: String) -> void:
	for property: String in values:
		var found: Variant = target.get(property)
		check.call(same(found, values[property]),
			"%s.%s = %s (found %s)" % [label, property, values[property], found])


static func same(found: Variant, wanted: Variant) -> bool:
	if found == null:
		return false
	match typeof(wanted):
		TYPE_FLOAT:
			return typeof(found) in [TYPE_FLOAT, TYPE_INT] and is_equal_approx(found, wanted)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR:
			return typeof(found) == typeof(wanted) and found.is_equal_approx(wanted)
		TYPE_AABB:
			return typeof(found) == TYPE_AABB and found.position.is_equal_approx(
				wanted.position) and found.size.is_equal_approx(wanted.size)
	return typeof(found) == typeof(wanted) and found == wanted


static func curve_points(texture: CurveTexture) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if texture == null or texture.curve == null:
		return points
	for index in range(texture.curve.point_count):
		points.append(texture.curve.get_point_position(index))
	return points


static func same_points(found: Array[Vector2], wanted: Array) -> bool:
	if found.size() != wanted.size():
		return false
	for index in range(found.size()):
		if not found[index].is_equal_approx(wanted[index]):
			return false
	return true
