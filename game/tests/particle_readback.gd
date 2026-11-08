extends RefCounted
## Reads particle settings back from a loaded effect scene for the configuration tests.
##
## `expected` maps each part of an emitter to the brief's values: "node" (GPUParticles3D),
## "process" (ParticleProcessMaterial), "draw" (StandardMaterial3D, or a ShaderMaterial when it
## names a "shader" and its "params"), "mesh" (QuadMesh), "texture" (the draw material's albedo
## texture path), and "alpha_curve", "scale_curve" or "scale_over_velocity_curve" (the curve's
## points, or for a per-axis CurveXYZTexture a dictionary of each axis's points). Every value is
## checked and reported with what was found; a shader parameter must also be one of the
## shader's uniforms, because a ShaderMaterial stores an undeclared name without an error.


static func check_emitter(emitter: GPUParticles3D, expected: Dictionary, check: Callable,
		label: String) -> void:
	check.call(emitter != null, "%s is a GPUParticles3D" % label)
	if emitter == null:
		return
	var process := emitter.process_material as ParticleProcessMaterial
	check.call(process != null, "%s uses a ParticleProcessMaterial" % label)
	var mesh := emitter.draw_pass_1 as QuadMesh
	check.call(mesh != null, "%s draws a QuadMesh" % label)
	var wanted: Dictionary = expected.get("draw", {})
	var shaded: ShaderMaterial = mesh.material as ShaderMaterial if mesh else null
	var draw: StandardMaterial3D = mesh.material as StandardMaterial3D if mesh else null
	if wanted.has("shader"):
		check.call(shaded != null, "%s's quad uses a ShaderMaterial" % label)
	else:
		check.call(draw != null, "%s's quad uses a StandardMaterial3D" % label)
	_check_values(emitter, expected.get("node", {}), check, label)
	if process:
		_check_values(process, expected.get("process", {}), check, label + " process")
		for curve_name: String in ["alpha_curve", "scale_curve", "scale_over_velocity_curve"]:
			if expected.has(curve_name):
				_check_curve(process.get(curve_name), expected[curve_name], check,
					"%s %s" % [label, curve_name])
	if mesh:
		_check_values(mesh, expected.get("mesh", {}), check, label + " quad")
	if shaded and wanted.has("shader"):
		_check_shader(shaded, wanted, expected.get("texture", ""), check, label)
	elif draw:
		_check_values(draw, expected.get("draw", {}), check, label + " material")
		if expected.has("texture"):
			var texture := draw.albedo_texture
			var path := texture.resource_path if texture else "none"
			check.call(path == expected["texture"],
				"%s texture is %s (found %s)" % [label, expected["texture"], path])


static func _check_shader(material: ShaderMaterial, wanted: Dictionary, texture_path: String,
		check: Callable, label: String) -> void:
	var path := material.shader.resource_path if material.shader else "none"
	check.call(path == wanted["shader"],
		"%s material runs %s (found %s)" % [label, wanted["shader"], path])
	var declared: Array[String] = []
	if material.shader:
		for uniform in material.shader.get_shader_uniform_list():
			declared.append(uniform["name"])
	var params: Dictionary = wanted.get("params", {})
	for name: String in params:
		var found: Variant = material.get_shader_parameter(name)
		check.call(declared.has(name) and same(found, params[name]),
			"%s material %s = %s (found %s%s)" % [label, name, params[name], found,
			"" if declared.has(name) else ", not one of the shader's uniforms"])
	if texture_path != "":
		var texture := material.get_shader_parameter("albedo_texture") as Texture2D
		var found_path := texture.resource_path if texture else "none"
		check.call(found_path == texture_path,
			"%s texture is %s (found %s)" % [label, texture_path, found_path])


## The A effects leave out the features the B effects are graded on (CHANGE-BRIEF.md revision 6):
## a sub-emitter, B1's, and turbulence and a driven amount_ratio, B2's.
static func check_no_b_features(emitter: GPUParticles3D, check: Callable, label: String) -> void:
	var process := emitter.process_material as ParticleProcessMaterial
	check.call(emitter.sub_emitter.is_empty() and process != null
		and process.sub_emitter_mode == ParticleProcessMaterial.SUB_EMITTER_DISABLED,
		"%s has no sub-emitter, B1's feature" % label)
	check.call(process != null and not process.turbulence_enabled,
		"%s has no turbulence, B2's feature" % label)
	check.call(is_equal_approx(emitter.amount_ratio, 1.0),
		"%s leaves amount_ratio at 1, B2's feature to drive" % label)


static func _check_curve(texture: Texture2D, wanted: Variant, check: Callable,
		label: String) -> void:
	if wanted is Dictionary:
		var axes := texture as CurveXYZTexture
		check.call(axes != null, "%s is a per-axis curve" % label)
		for axis: String in wanted:
			var found := points_of(axes.get("curve_" + axis) as Curve if axes else null)
			check.call(same_points(found, wanted[axis]),
				"%s %s keys %s (found %s)" % [label, axis, wanted[axis], found])
		return
	var found := curve_points(texture as CurveTexture)
	check.call(same_points(found, wanted), "%s keys %s (found %s)" % [label, wanted, found])


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
	return points_of(texture.curve if texture else null)


static func points_of(curve: Curve) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if curve == null:
		return points
	for index in range(curve.point_count):
		points.append(curve.get_point_position(index))
	return points


static func same_points(found: Array[Vector2], wanted: Array) -> bool:
	if found.size() != wanted.size():
		return false
	for index in range(found.size()):
		if not found[index].is_equal_approx(wanted[index]):
			return false
	return true
