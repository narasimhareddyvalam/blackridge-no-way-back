extends RefCounted


static func material(color: Color, roughness: float = 0.7) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result


static func luminous(color: Color, energy: float = 1.0) -> StandardMaterial3D:
	var result := material(color)
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.emission_enabled = true
	result.emission = color
	result.emission_energy_multiplier = energy
	return result


static func box(
	parent: Node3D, at: Vector3, size: Vector3, surface: Material, solid: bool = false
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return instance(parent, at, mesh, surface, solid)


static func cylinder(
	parent: Node3D, at: Vector3, radius: float, height: float, surface: Material,
	top_radius: float = -1.0
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 16
	return instance(parent, at, mesh, surface)


static func instance(
	parent: Node3D, at: Vector3, mesh: Mesh, surface: Material, solid: bool = false
) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.material_override = surface
	result.position = at
	parent.add_child(result)
	if solid:
		result.create_trimesh_collision()
	return result


static func text(
	parent: Node3D, words: String, at: Vector3, size: int, color: Color = Color.WHITE
) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = size
	label.pixel_size = 0.01
	label.modulate = color
	label.outline_size = 0
	parent.add_child(label)
	return label
