@tool
extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const GROUND_SHADER = preload("wet_ground.gdshader")
const SKY_IMAGE = preload("polyhaven/hdris/rooftop_night/rooftop_night_2k.hdr")
const CLADDING_GREY = preload("derived/box_profile_metal_sheet_grey_diff_2k.jpg")
const LIBRARY: String = "res://features/environments/depot_yard/polyhaven/"
const FRONT_Z: float = -20.0
const DOCK_HEIGHT: float = 1.2
const ROOF_HEIGHT: float = 11.0
const HALF_WIDTH: float = 26.0
const BUILDING_DEPTH: float = 24.0
const PLINTH_END: float = 7.5
const BAY_CENTRES: Array[float] = [-15.0, -9.0, -3.0, 3.0]
const OPEN_BAY: int = 1
const DOOR_SIZE := Vector2(3.0, 3.2)
const LAMP_COLOUR := Color("ffc489")

@export var sky_rotation_degrees: float = 200.0
@export var sky_energy: float = 0.32
@export var dock_lamp_energy: float = 16.0
@export var yard_lamp_energy: float = 22.0

var _scenes: Dictionary = {}
var _materials: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _lamp_glass := Build.luminous(LAMP_COLOUR, 9.0)
var _rubber := Build.material(Color("151617"), 0.82)


func _ready() -> void:
	_random.seed = 20261019
	_environment()
	_ground()
	_building()
	_docks()
	_open_bay_interior()
	_wall_fittings()
	_yard_lighting()
	_boundary()
	_props()
	_reflection_probe()


func _environment() -> void:
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = SKY_IMAGE
	panorama.energy_multiplier = sky_energy
	var sky := Sky.new()
	sky.sky_material = panorama
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.sky_rotation = Vector3(0.0, deg_to_rad(sky_rotation_degrees), 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.1
	environment.ssr_enabled = true
	environment.ssr_max_steps = 64
	environment.ssr_depth_tolerance = 0.25
	environment.ssao_enabled = true
	environment.ssao_radius = 1.4
	environment.ssao_intensity = 1.6
	environment.fog_enabled = true
	environment.fog_light_color = Color("6d5f78")
	environment.fog_density = 0.0045
	environment.fog_sky_affect = 0.25
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.012
	environment.volumetric_fog_albedo = Color("c9bfd6")
	environment.volumetric_fog_anisotropy = 0.55
	environment.volumetric_fog_length = 70.0
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var dusk := DirectionalLight3D.new()
	dusk.rotation_degrees = Vector3(-9.0, sky_rotation_degrees - 20.0, 0.0)
	dusk.light_color = Color("ff9f6b")
	dusk.light_energy = 0.22
	dusk.shadow_enabled = true
	dusk.directional_shadow_max_distance = 90.0
	add_child(dusk)


func _surface(
	asset: String, metres: float, tint: Color = Color.WHITE, albedo: Texture2D = null
) -> ORMMaterial3D:
	var key := "%s|%.2f|%s|%s" % [asset, metres, tint.to_html(), albedo != null]
	if _materials.has(key):
		return _materials[key]
	var stem := LIBRARY + "textures/%s/%s_" % [asset, asset]
	var size := "2k" if ResourceLoader.exists(stem + "diff_2k.jpg") else "1k"
	var material := ORMMaterial3D.new()
	material.albedo_texture = albedo if albedo else load(stem + "diff_%s.jpg" % size)
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(stem + "nor_gl_%s.jpg" % size)
	material.orm_texture = load(stem + "arm_%s.jpg" % size)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / metres
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials[key] = material
	return material


func _paint(tint: Color, metres: float) -> StandardMaterial3D:
	var key := "paint|%.2f|%s" % [metres, tint.to_html()]
	if _materials.has(key):
		return _materials[key]
	var stem := LIBRARY + "textures/painted_metal_shutter/painted_metal_shutter_"
	var arm: Texture2D = load(stem + "arm_2k.jpg")
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(stem + "diff_2k.jpg")
	material.albedo_color = tint
	material.metallic = 0.0
	material.roughness_texture = arm
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.ao_enabled = true
	material.ao_texture = arm
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = load(stem + "nor_gl_2k.jpg")
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / metres
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials[key] = material
	return material


func _ground_material(asset: String, metres: float, puddles: float) -> ShaderMaterial:
	var stem := LIBRARY + "textures/%s/%s_" % [asset, asset]
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("albedo_map", load(stem + "diff_2k.jpg"))
	material.set_shader_parameter("normal_map", load(stem + "nor_gl_2k.jpg"))
	material.set_shader_parameter("arm_map", load(stem + "arm_2k.jpg"))
	material.set_shader_parameter("texture_metres", metres)
	material.set_shader_parameter("puddle_amount", puddles)
	return material


func _plane(material: Material, centre: Vector3, size: Vector2) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = int(size.x / 4.0)
	mesh.subdivide_depth = int(size.y / 4.0)
	return Build.instance(self, centre, mesh, material)


func _block(material: Material, centre: Vector3, size: Vector3, solid := false) -> MeshInstance3D:
	return Build.box(self, centre, size, material, solid)


func _collider(centre: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = centre
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _ground() -> void:
	_plane(_ground_material("asphalt_02", 3.0, 0.42), Vector3(0, 0, 8), Vector2(96, 72))
	var apron_depth := 14.0
	_plane(_ground_material("concrete_floor_worn_001", 2.5, 0.3),
		Vector3(0, 0.004, FRONT_Z + apron_depth * 0.5), Vector2(HALF_WIDTH * 2.0, apron_depth))
	_collider(Vector3(0, -0.5, 8), Vector3(96, 1.0, 72))
	var paint := _paint(Color(0.9, 0.66, 0.14), 1.0)
	for centre: float in BAY_CENTRES:
		for side: float in [-1.0, 1.0]:
			_block(paint, Vector3(centre + side * 1.95, 0.008, FRONT_Z + 7.5),
				Vector3(0.14, 0.006, 13.0))


func _building() -> void:
	var cladding := _surface("box_profile_metal_sheet", 2.0, Color(0.6, 0.62, 0.65),
		CLADDING_GREY)
	var concrete := _surface("concrete_wall_006", 2.2)
	var steel := _surface("metal_plate_02", 2.0, Color(0.62, 0.68, 0.74))
	var wall_z := FRONT_Z - 0.15
	var door_top := DOCK_HEIGHT + DOOR_SIZE.y
	var edges: Array[float] = [-HALF_WIDTH]
	for centre: float in BAY_CENTRES:
		edges.append(centre - DOOR_SIZE.x * 0.5)
		edges.append(centre + DOOR_SIZE.x * 0.5)
	edges.append(HALF_WIDTH)
	for index in range(0, edges.size(), 2):
		var width := edges[index + 1] - edges[index]
		_block(cladding, Vector3(edges[index] + width * 0.5, (DOCK_HEIGHT + ROOF_HEIGHT) * 0.5,
			wall_z), Vector3(width, ROOF_HEIGHT - DOCK_HEIGHT, 0.3))
	for centre: float in BAY_CENTRES:
		_block(cladding, Vector3(centre, (door_top + ROOF_HEIGHT) * 0.5, wall_z),
			Vector3(DOOR_SIZE.x, ROOF_HEIGHT - door_top, 0.3))
	var dock_width := PLINTH_END + HALF_WIDTH
	_block(concrete, Vector3(PLINTH_END - dock_width * 0.5, DOCK_HEIGHT * 0.5, FRONT_Z - 0.2),
		Vector3(dock_width, DOCK_HEIGHT, 0.4))
	var side_width := HALF_WIDTH - PLINTH_END
	var side_x := PLINTH_END + side_width * 0.5
	_block(cladding, Vector3(side_x, 0.9, wall_z), Vector3(side_width, 0.6, 0.3))
	_block(concrete, Vector3(side_x, 0.3, FRONT_Z - 0.1), Vector3(side_width, 0.6, 0.4))
	var mid_z := FRONT_Z - BUILDING_DEPTH * 0.5
	for side: float in [-1.0, 1.0]:
		_block(cladding, Vector3(side * HALF_WIDTH, ROOF_HEIGHT * 0.5, mid_z),
			Vector3(0.3, ROOF_HEIGHT, BUILDING_DEPTH))
		_block(steel, Vector3(side * (HALF_WIDTH + 0.02), ROOF_HEIGHT * 0.5, FRONT_Z + 0.02),
			Vector3(0.36, ROOF_HEIGHT + 0.3, 0.36))
	_block(cladding, Vector3(0, ROOF_HEIGHT * 0.5, FRONT_Z - BUILDING_DEPTH),
		Vector3(HALF_WIDTH * 2.0, ROOF_HEIGHT, 0.3))
	_block(steel, Vector3(0, ROOF_HEIGHT, mid_z), Vector3(HALF_WIDTH * 2.0, 0.3, BUILDING_DEPTH))
	_block(steel, Vector3(0, ROOF_HEIGHT + 0.25, FRONT_Z + 0.05),
		Vector3(HALF_WIDTH * 2.0 + 0.4, 0.5, 0.5))
	_collider(Vector3(0, ROOF_HEIGHT * 0.5, mid_z + 0.15),
		Vector3(HALF_WIDTH * 2.0, ROOF_HEIGHT, BUILDING_DEPTH + 0.3))


func _docks() -> void:
	var door := _paint(Color(0.72, 0.75, 0.78), 1.6)
	var rubber := _rubber
	var guard := _paint(Color(1.0, 0.72, 0.08), 0.8)
	var glass := Build.material(Color("0f1418"), 0.08)
	var plate := Build.material(Color("e9e6dc"), 0.6)
	var door_top := DOCK_HEIGHT + DOOR_SIZE.y
	for index in range(BAY_CENTRES.size()):
		var x := BAY_CENTRES[index]
		if index == OPEN_BAY:
			_block(door, Vector3(x, door_top - 0.25, FRONT_Z - 0.22),
				Vector3(DOOR_SIZE.x, 0.5, 0.08))
		else:
			_block(door, Vector3(x, DOCK_HEIGHT + DOOR_SIZE.y * 0.5, FRONT_Z - 0.22),
				Vector3(DOOR_SIZE.x, DOOR_SIZE.y, 0.08))
			for side: float in [-1.0, 1.0]:
				_block(glass, Vector3(x + side * 0.7, DOCK_HEIGHT + 1.95, FRONT_Z - 0.175),
					Vector3(0.55, 0.2, 0.02))
		for side: float in [-1.0, 1.0]:
			_block(rubber, Vector3(x + side * (DOOR_SIZE.x * 0.5 + 0.17),
				DOCK_HEIGHT + (DOOR_SIZE.y + 0.3) * 0.5, FRONT_Z + 0.2),
				Vector3(0.34, DOOR_SIZE.y + 0.3, 0.4))
			_block(rubber, Vector3(x + side * 1.05, DOCK_HEIGHT - 0.32, FRONT_Z + 0.09),
				Vector3(0.26, 0.46, 0.18))
			Build.cylinder(self, Vector3(x + side * 2.25, 0.55, FRONT_Z + 1.3), 0.12, 1.1, guard)
			_collider(Vector3(x + side * 2.25, 0.55, FRONT_Z + 1.3), Vector3(0.24, 1.1, 0.24))
		_block(rubber, Vector3(x, door_top + 0.25, FRONT_Z + 0.2),
			Vector3(DOOR_SIZE.x + 0.68, 0.62, 0.4))
		_block(plate, Vector3(x, door_top + 1.0, FRONT_Z + 0.012), Vector3(0.5, 0.5, 0.02))
		var number := Build.text(self, str(index + 1), Vector3(x, door_top + 1.0, FRONT_Z + 0.025),
			96, Color("1b1d1f"))
		number.pixel_size = 0.004
		_wall_lamp(Vector3(x, door_top + 1.75, FRONT_Z), dock_lamp_energy, index % 2 == 0)


func _wall_lamp(at: Vector3, energy: float, shadows: bool) -> void:
	var lamp := _prop("security_light", ["security_light", "security_light_glass"], at)
	(lamp.get_child(1) as MeshInstance3D).material_override = _lamp_glass
	var light := SpotLight3D.new()
	light.position = at + Vector3(0, -0.32, 0.22)
	light.rotation_degrees = Vector3(-62.0, 180.0, 0.0)
	light.light_color = LAMP_COLOUR
	light.light_energy = energy
	light.spot_range = 16.0
	light.spot_angle = 58.0
	light.spot_attenuation = 1.4
	light.light_volumetric_fog_energy = 0.6
	light.shadow_enabled = shadows
	add_child(light)


func _open_bay_interior() -> void:
	var x := BAY_CENTRES[OPEN_BAY]
	var floor := _surface("concrete_floor_worn_001", 2.0, Color(0.95, 0.9, 0.82))
	var room := BoxMesh.new()
	room.size = Vector3(9.0, 5.0, 10.0)
	room.flip_faces = true
	Build.instance(self, Vector3(x, DOCK_HEIGHT + 2.5, FRONT_Z - 5.3), room, floor)
	var warm := OmniLight3D.new()
	warm.position = Vector3(x, DOCK_HEIGHT + 4.2, FRONT_Z - 4.5)
	warm.light_color = Color("ffd29e")
	warm.light_energy = 2.4
	warm.omni_range = 11.0
	warm.shadow_enabled = true
	add_child(warm)
	for z: float in [-2.5, -6.5]:
		_block(Build.luminous(Color("fff1d6"), 3.0),
			Vector3(x, DOCK_HEIGHT + 4.95, FRONT_Z + z), Vector3(0.18, 0.04, 1.4))
	_box_stack(Vector3(x - 3.0, DOCK_HEIGHT, FRONT_Z - 6.0), Vector3i(3, 3, 4), 0.0)
	_box_stack(Vector3(x + 2.0, DOCK_HEIGHT, FRONT_Z - 7.5), Vector3i(4, 2, 3), 0.0)
	_box_stack(Vector3(x + 2.4, DOCK_HEIGHT, FRONT_Z - 2.8), Vector3i(2, 2, 2), 0.0)


func _wall_fittings() -> void:
	_prop("rollershutter_door", ["rollershutter_door"], Vector3(12.0, 0.0, FRONT_Z))
	_wall_lamp(Vector3(12.0, 3.1, FRONT_Z), 3.5, false)
	_prop("exterior_aircon_unit", ["exterior_aircon_unit"], Vector3(16.5, 3.4, FRONT_Z + 0.22))
	_prop("exterior_aircon_unit", ["exterior_aircon_unit_rusted"],
		Vector3(18.0, 3.4, FRONT_Z + 0.22))
	_prop("utility_box_01", [], Vector3(21.0, 0.0, FRONT_Z + 0.25))
	for x: float in [-21.0, 6.0, 24.0]:
		for step in range(int(ROOF_HEIGHT - 1.0)):
			_prop("modular_metal_gutter", ["modular_metal_gutter_section"],
				Vector3(x, 0.4 + step, FRONT_Z + 0.12))
		_prop("modular_metal_gutter", ["modular_metal_gutter_outlet"],
			Vector3(x, 0.27, FRONT_Z + 0.2))


func _yard_lighting() -> void:
	var steel := _surface("metal_plate_02", 1.5, Color(0.5, 0.55, 0.6))
	for at: Vector3 in [Vector3(-19.0, 0, -1.0), Vector3(17.0, 0, 10.0)]:
		Build.cylinder(self, at + Vector3.UP * 5.0, 0.16, 10.0, steel, 0.1)
		_collider(at + Vector3.UP * 2.0, Vector3(0.36, 4.0, 0.36))
		_block(steel, at + Vector3(0, 9.9, 0), Vector3(1.8, 0.12, 0.12))
		for side: float in [-1.0, 1.0]:
			var head := at + Vector3(side * 0.75, 9.85, 0)
			_prop("security_light", ["security_light", "security_light_glass"], head,
				180.0).get_child(1).material_override = _lamp_glass
			var light := SpotLight3D.new()
			light.position = head + Vector3(0, -0.35, 0)
			light.rotation_degrees = Vector3(-90.0 + side * 22.0, 90.0, 0.0)
			light.light_color = LAMP_COLOUR
			light.light_energy = yard_lamp_energy
			light.spot_range = 26.0
			light.spot_angle = 62.0
			light.spot_attenuation = 1.2
			light.light_volumetric_fog_energy = 0.8
			light.shadow_enabled = side > 0.0
			add_child(light)


func _boundary() -> void:
	for step in range(27):
		var z := FRONT_Z + step * 2.0
		_prop("modular_chainlink_fence", ["modular_chainlink_fence_double"],
			Vector3(-32.0, 0, z), 90.0)
		_prop("modular_chainlink_fence", ["modular_chainlink_fence_post"], Vector3(-32.0, 0, z))
	for step in range(31):
		var x := -30.0 + step * 2.0
		_prop("modular_chainlink_fence", ["modular_chainlink_fence_double"], Vector3(x, 0, 34.0))
		_prop("modular_chainlink_fence", ["modular_chainlink_fence_post"], Vector3(x, 0, 34.0))
	_collider(Vector3(-32.0, 1.25, 7.0), Vector3(0.3, 2.5, 54.0))
	_collider(Vector3(-1.0, 1.25, 34.0), Vector3(62.0, 2.5, 0.3))
	for step in range(33):
		_prop("concrete_road_barrier", [], Vector3(30.0, 0, -18.0 + step * 1.6), 90.0)
	_collider(Vector3(30.0, 0.42, 7.6), Vector3(0.7, 0.84, 52.8))
	for z: float in [-12.0, 12.0, 36.0]:
		_prop("modular_electricity_poles", ["preset_01_pole"], Vector3(-34.5, 0, z), 90.0)


func _props() -> void:
	_box_stack(Vector3(-22.5, 0.0, FRONT_Z + 3.0), Vector3i(3, 2, 3), 6.0)
	_box_stack(Vector3(6.0, 0.0, FRONT_Z + 2.5), Vector3i(2, 2, 2), -4.0)
	for at: Vector3 in [Vector3(23.0, 0, -16.2), Vector3(23.7, 0, -16.6), Vector3(23.3, 0, -15.6)]:
		_prop("barrel_03", [], at, _random.randf_range(0.0, 360.0))
	_collider(Vector3(23.35, 0.45, -16.1), Vector3(1.4, 0.9, 1.6))
	var can := ["metal_trash_can", "metal_trash_can_lid",
		"metal_trash_can_handle_left", "metal_trash_can_handle_right"]
	_prop("metal_trash_can", can, Vector3(10.4, 0, FRONT_Z + 0.5), 10.0)
	var rusty := ["metal_trash_can_rust", "metal_trash_can_rust_lid",
		"metal_trash_can_rust_handle_left", "metal_trash_can_rust_handle_right"]
	_prop("metal_trash_can", rusty, Vector3(14.2, 0, FRONT_Z + 0.6), -20.0)
	for layer in range(3):
		var tyre := _prop("old_tyre", [], Vector3(-24.0, 0.08 + layer * 0.16, -11.0),
			layer * 23.0)
		tyre.rotation_degrees.x = 90.0
	_prop("covered_car", [], Vector3(-26.5, 0.0, 14.0), 6.0)
	_collider(Vector3(-26.5, 0.7, 14.0), Vector3(1.9, 1.4, 4.4))
	_prop("fire_hydrant", ["fire_hydrant_aged"], Vector3(27.5, 0.0, -14.0), 30.0)
	_prop("water_manhole_cover", [], Vector3(1.5, 0.0, -6.0))
	_prop("water_manhole_cover", [], Vector3(-12.0, 0.0, 16.0))
	for x: float in [10.0, 11.6]:
		_prop("concrete_road_barrier", [], Vector3(x, 0, 18.0), 0.0)
	_collider(Vector3(10.8, 0.42, 18.0), Vector3(3.2, 0.84, 0.7))


func _box_stack(origin: Vector3, counts: Vector3i, yaw: float) -> void:
	var holder := Node3D.new()
	holder.position = origin
	holder.rotation_degrees.y = yaw
	add_child(holder)
	for column in range(counts.x):
		for row in range(counts.z):
			var height := counts.y if _random.randf() > 0.25 else counts.y - 1
			for layer in range(height):
				var at := Vector3(column * 0.41, layer * 0.345, row * 0.54)
				var box := _prop("cardboard_box_01", [], at, _random.randf_range(-4.0, 4.0))
				box.reparent(holder, false)


func _prop(asset: String, parts: Array, at: Vector3, yaw: float = 0.0) -> Node3D:
	if not _scenes.has(asset):
		_scenes[asset] = load(LIBRARY + "models/%s/%s.gltf" % [asset, asset])
	var source: Node3D = (_scenes[asset] as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	add_child(holder)
	if parts.is_empty():
		holder.add_child(source)
		return holder
	var origin := (source.find_child(parts[0], true, false) as Node3D).position
	for part in parts:
		var node := source.find_child(part, true, false) as Node3D
		node.get_parent().remove_child(node)
		_clear_owner(node)
		node.position -= Vector3(origin.x, 0.0, origin.z)
		holder.add_child(node)
	source.free()
	return holder


func _clear_owner(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		_clear_owner(child)


func _reflection_probe() -> void:
	var probe := ReflectionProbe.new()
	probe.position = Vector3(0, 5.0, -4.0)
	probe.size = Vector3(66.0, 14.0, 44.0)
	probe.box_projection = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)
