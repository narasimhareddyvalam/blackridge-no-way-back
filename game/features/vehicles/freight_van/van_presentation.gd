extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const Instruments = preload("instruments.gd")
const Navigation = preload("navigation_display.gd")
const NightDimming = preload("night_dimming.gd")
const GLASS = preload("windshield.gdshader")
const BODY_ART = preload("art/body.glb")
const TIRE_ART = preload("art/tire.glb")
const COCKPIT_FRONT = preload("art/cockpit/cockpit_front.gltf")
const COCKPIT_BACK = preload("art/cockpit/cockpit_back.gltf")
const COCKPIT_ROOF = preload("art/cockpit/cockpit_roof.gltf")
const COCKPIT_WHEEL = preload("art/cockpit/cockpit_wheel.gltf")
const COCKPIT_SHADOW = preload("art/cockpit/cockpit_shadow.glb")
const WHEEL_SHADOW = preload("art/cockpit/cockpit_wheel_shadow.glb")
const SCREEN = preload("cockpit_screen.gdshader")
const WHEEL_HUB := Vector3(-0.57, 1.7328, -0.8167)
const WHEEL_TILT := -18.49
const SCREEN_GAP := 0.0015
const CLUSTER_SCREEN := Vector3(-0.5563, 1.8007, -1.0219)
const CLUSTER_SIZE := Vector2(0.162, 0.0648)
const MAP_SCREEN := Vector3(-0.2369, 1.7879, -1.0219)
const MAP_SIZE := Vector2(0.15525, 0.1035)
const MIRROR_SCREENS := {-1: Vector3(-1.027, 1.7889, -1.0356), 1: Vector3(1.031, 1.7889, -1.0356)}
const MIRROR_SCREEN_SIZE := Vector2(0.1294, 0.076)
const MIRROR_SCREEN_YAW := 33.77
const MIRROR_SCREEN_ROLL := 1.4
const CENTRE_MIRROR := Vector3(-0.0072, 2.5935, -1.1004)
const CENTRE_MIRROR_SIZE := Vector2(0.185, 0.044)
const CENTRE_MIRROR_TURN := Vector3(11.4, -8.9, 0.0)
const WHEEL_SPOTS: Array[Vector3] = [Vector3(-1.15, 0, -1.52), Vector3(1.15, 0, -1.52),
	Vector3(-1.15, 0, 1.85), Vector3(1.15, 0, 1.85)]
const TILT_RATE := 10.0
const BLADE_FLIP := 0.14
const LIGHT_FOG = preload("res://materials/windshield/light_fog.tres")
const SIDE_RAIN = preload("side_window_rain.gdshader")
const RainPhysics = preload("rain_physics.gd")
const WINDSHIELD_RAKE := 0.32
const WINDSHIELD_CENTRE := Vector3(0, 2.17, -1.34)
const DUMP_SECONDS := 0.7
const MOON_ROOF := Rect2(-0.692, -0.944, 1.39, 0.433)
const MOON_ROOF_HEIGHT := 2.79
const ROOF_SLOPE := Vector2(0.0, -0.05)
const ROOF_AIR := 0.8
const LOOK_UP := 1.05
const BODY_ROOF := 2.995
const BEAM_RAIN = preload("beam_rain.gdshader")
const RAIN_LAYERS: Array[float] = [3.0, 4.5, 6.5, 9.0, 12.5, 17.0, 23.0, 31.0]
const LAMP_FRONT := -2.44
const RAIN_SLANT := 0.08
const LOW_BEAM_RAIN := Vector2(5.0, 0.65)
const HIGH_BEAM_RAIN := Vector2(16.0, 0.9)
const WINDSHIELD_AIR := 0.85
const SIDE_AIR := 0.9
const SIDE_AIR_DIRECTION := Vector2(-0.989, 0.148)
const MIRROR_UPDATES_PER_SECOND := 45.0
const MIRROR_DISTANCE := 80.0
const MIRROR_LOD_THRESHOLD := 4.0
const LOW_BEAM = preload("art/low_beam_pattern.png")
const HIGH_BEAM = preload("art/high_beam_pattern.png")
const LOW_BEAM_RANGE := 120.0
const HIGH_BEAM_RANGE := 220.0
const WipeMap = preload("windshield_wipe_map.gd")
const Wiper = preload("wiper.gd")
const WIPE_MAP_SIZE := Vector2i(512, 256)

var driving_camera: Camera3D
var navigation: Control
var night_dimming: Node
var mirrors: Array[SubViewport] = []
var reverse_view: SubViewport
var reverse_screen: MeshInstance3D
var vehicle: CharacterBody3D
var mirror_cameras: Array[Camera3D] = []
var fog_overlays: Array[MeshInstance3D] = []
var side_rain_overlays: Array[MeshInstance3D] = []
var roof_rain: MeshInstance3D
var mirror_poses: Array[Transform3D] = []
var _look: Node3D
var _wheel: Node3D
var _wipers: Array[Node3D] = []
var _blades: Array[Node3D] = []
var _last_wiper: float = 0.0
var _last_swing: float = 0.0
var _dump: float = 0.0
var _windows: Array[MeshInstance3D] = []
var _headlights: Array[SpotLight3D] = []
var _front_lenses: Array[MeshInstance3D] = []
var _rear_lamps: Array[MeshInstance3D] = []
var _indicators: Array[MeshInstance3D] = []
var _tires: Array[Node3D] = []
var _rolling_meshes: Array[Node3D] = []
var _glass: ShaderMaterial
var _high_beams_shown: bool = false
var _rain_layers: Array[MeshInstance3D] = []
var _beam_rain_material: ShaderMaterial
var _mirror_timer: float = 0.0
var _mirror_turn: int = 0
var _water: float = 0.6
var _windshield_water := RainPhysics.new()
var _side_water := RainPhysics.new()
var _roof_water := RainPhysics.new()
var _look_target := Vector2.ZERO
var _ground_ray := PhysicsRayQueryParameters3D.new()
var _ground_rest: float = 0.0
var _tilt := Vector3.ZERO
var _body := Node3D.new()
var _cabin := Node3D.new()
var _trim := Build.material(Color("141c22"), 0.86)
var _paint := Build.material(Color("536369"), 0.34)
var _rubber := Build.material(Color("0b1115"), 0.96)
var _steel := Build.material(Color("5d696d"), 0.3)
var _amber := Build.luminous(Color("ff9e30"), 1.2)
var _amber_off := Build.material(Color("623b19"))
var _red := Build.luminous(Color("e1442e"))
var _tail := Build.luminous(Color("68251e"))
var _lens_on := Build.luminous(Color("e9ebdc"))
var _lens_off := Build.material(Color("78838b"), 0.12)


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_last_wiper = van.wiper_angle
	var box := van.get_node("CollisionShape3D") as CollisionShape3D
	_ground_rest = box.position.y - (box.shape as BoxShape3D).size.y * 0.5
	_ground_ray.exclude = [van.get_rid()]
	_ground_ray.collision_mask = van.collision_mask
	add_child(_body)
	add_child(_cabin)
	_exterior()
	_beam_rain()
	_interior()
	_camera()
	_displays()
	_windows_and_wipers()
	_mark_layer(_body, 2)
	_mark_layer(_cabin, 4)


func _exterior() -> void:
	_body.add_child(BODY_ART.instantiate())
	var sky_glass := Build.material(Color("070a0c"), 0.05)
	var centre := MOON_ROOF.get_center()
	var top := Build.box(_body, Vector3(centre.x, BODY_ROOF + 0.004, centre.y),
		Vector3(MOON_ROOF.size.x + 0.05, 0.008, MOON_ROOF.size.y + 0.05), sky_glass)
	top.name = "MoonRoofOutside"
	for side in [-1, 1]:
		var lens := Build.box(_body, Vector3(side * 0.88, 1.20, -2.36),
			Vector3(0.38, 0.20, 0.065), _steel)
		lens.rotation_degrees.z = side * 8.0
		for offset in [-0.10, 0.10]:
			_front_lenses.append(Build.box(_body,
				Vector3(side * 0.88 + offset, 1.22, -2.405),
				Vector3(0.12, 0.065, 0.018), _lens_on))
		var headlight := SpotLight3D.new()
		headlight.position = Vector3(side * 0.86, 1.18, -2.44)
		headlight.rotation_degrees.x = -2.0
		headlight.light_color = Color("fff0db")
		headlight.light_energy = 650.0
		headlight.spot_angle = 35.0
		headlight.spot_angle_attenuation = 0.2
		headlight.spot_attenuation = 1.0
		headlight.shadow_enabled = true
		_aim_beam(headlight, false)
		headlight.light_cull_mask = 1
		_body.add_child(headlight)
		_headlights.append(headlight)
		_rear_lamps.append(Build.box(_body, Vector3(side * 1.03, 1.35, 2.91),
			Vector3(0.18, 0.36, 0.06), _tail))
		for z in [-2.37, 2.91]:
			_indicators.append(Build.box(_body, Vector3(side * 1.05, 1.1, z),
				Vector3(0.19, 0.09, 0.055), _amber_off))
		for z in [-1.52, 1.85]:
			var pivot := Node3D.new()
			_body.add_child(pivot)
			pivot.position = Vector3(side * 1.15, 0.48, z)
			var rolling := TIRE_ART.instantiate() as Node3D
			pivot.add_child(rolling)
			_tires.append(pivot)
			_rolling_meshes.append(rolling)
	var plate := Build.text(_body, "BR  048", Vector3(0, 0.76, 2.98), 13,
		Color("e7dfc3"))
	plate.pixel_size = 0.003


func _interior() -> void:
	for art: PackedScene in [COCKPIT_FRONT, COCKPIT_BACK, COCKPIT_ROOF]:
		_cockpit_part(art, _cabin)
	_wheel = Node3D.new()
	_cabin.add_child(_wheel)
	_wheel.position = WHEEL_HUB
	_wheel.rotation.x = deg_to_rad(WHEEL_TILT)
	_cockpit_part(COCKPIT_WHEEL, _wheel)
	var both_sides := StandardMaterial3D.new()
	both_sides.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shadow_stand_in(COCKPIT_SHADOW, _cabin, both_sides)
	_shadow_stand_in(WHEEL_SHADOW, _wheel, both_sides)
	var light := OmniLight3D.new()
	light.position = Vector3(-0.25, 2.30, -0.55)
	light.light_color = Color("b7c2c9")
	light.light_energy = 0.45
	light.omni_range = 2.5
	light.light_cull_mask = 4
	_cabin.add_child(light)


func _cockpit_part(art: PackedScene, parent: Node3D) -> void:
	var part := art.instantiate()
	parent.add_child(part)
	for mesh: GeometryInstance3D in part.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _shadow_stand_in(art: PackedScene, parent: Node3D, surface: Material) -> void:
	var stand_in := art.instantiate()
	parent.add_child(stand_in)
	for mesh: GeometryInstance3D in stand_in.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		mesh.material_override = surface


func _camera() -> void:
	_look = Node3D.new()
	_look.position = Vector3(-0.52, 2.03, -0.32)
	add_child(_look)
	driving_camera = Camera3D.new()
	driving_camera.fov = 74.0
	driving_camera.rotation.x = -0.15
	driving_camera.near = 0.045
	driving_camera.far = 350.0
	driving_camera.cull_mask = 5
	_look.add_child(driving_camera)
	driving_camera.make_current()


func _displays() -> void:
	var cluster := Instruments.new()
	cluster.vehicle = vehicle
	cluster.render_scale = 2.0
	var instruments := _display_viewport(Vector2i(1280, 512), cluster)
	night_dimming = NightDimming.new()
	night_dimming.name = "NightDimming"
	add_child(night_dimming)
	night_dimming.configure(vehicle, cluster)
	_dash_screen(instruments, CLUSTER_SCREEN, CLUSTER_SIZE)
	navigation = Navigation.new()
	navigation.vehicle = vehicle
	var gps := _display_viewport(Vector2i(384, 256), navigation)
	_dash_screen(gps, MAP_SCREEN, MAP_SIZE)
	for side in [-1, 1]:
		var view := _camera_view(Vector3(side * 1.35, 2.14, -1.2),
			Vector3(0, PI + side * 0.13, 0), Vector2i(256, 320), 62.0)
		mirrors.append(view)
		_screen(view, Vector3(side * 1.3, 2.11, -1.22), Vector2(0.26, 0.35), true)
		Build.box(_cabin, Vector3(side * 1.23, 1.94, -1.22),
			Vector3(0.2, 0.04, 0.04), _trim)
		_dash_screen(view, MIRROR_SCREENS[side], MIRROR_SCREEN_SIZE,
			Vector3(0, -side * MIRROR_SCREEN_YAW, -side * MIRROR_SCREEN_ROLL), true)
	var inside := _camera_view(Vector3(0, 2.4, -1.2), Vector3(0, PI, 0),
		Vector2i(384, 128), 65.0)
	mirrors.append(inside)
	_dash_screen(inside, CENTRE_MIRROR, CENTRE_MIRROR_SIZE, CENTRE_MIRROR_TURN, true)
	reverse_view = _camera_view(Vector3(0, 2.35, 3.02), Vector3(-0.28, PI, 0),
		Vector2i(384, 256), 85.0)
	reverse_screen = _dash_screen(reverse_view, MAP_SCREEN, MAP_SIZE, Vector3.ZERO, false,
		2.0 * SCREEN_GAP)
	reverse_screen.visible = false


func _display_viewport(resolution: Vector2i, control: Control) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	viewport.add_child(control)
	return viewport


func _camera_view(
	at: Vector3, angles: Vector3, resolution: Vector2i, field: float
) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.positional_shadow_atlas_size = 0
	viewport.mesh_lod_threshold = MIRROR_LOD_THRESHOLD
	add_child(viewport)
	var camera := Camera3D.new()
	camera.position = at
	camera.rotation = angles
	camera.cull_mask = 3
	camera.fov = field
	camera.near = 0.1
	camera.far = MIRROR_DISTANCE
	viewport.add_child(camera)
	camera.make_current()
	mirror_cameras.append(camera)
	mirror_poses.append(camera.transform)
	return viewport


func _screen(
	viewport: SubViewport, at: Vector3, dimensions: Vector2, mirror: bool = false
) -> MeshInstance3D:
	Build.box(_cabin, at - Vector3(0, 0, 0.014),
		Vector3(dimensions.x + 0.035, dimensions.y + 0.035, 0.025), _trim)
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.albedo_texture = viewport.get_texture()
	if mirror:
		surface.uv1_scale.x = -1.0
		surface.uv1_offset.x = 1.0
	var quad := QuadMesh.new()
	quad.size = dimensions
	return Build.instance(_cabin, at, quad, surface)


func _dash_screen(
	viewport: SubViewport, at: Vector3, dimensions: Vector2, turn: Vector3 = Vector3.ZERO,
	mirror: bool = false, gap: float = SCREEN_GAP
) -> MeshInstance3D:
	var picture := float(viewport.size.x) / viewport.size.y
	var glass := dimensions.x / dimensions.y
	var surface := ShaderMaterial.new()
	surface.shader = SCREEN
	surface.set_shader_parameter("display", viewport.get_texture())
	surface.set_shader_parameter("mirrored", mirror)
	surface.set_shader_parameter("crop", Vector2(minf(1.0, glass / picture),
		minf(1.0, picture / glass)))
	var quad := QuadMesh.new()
	quad.size = dimensions
	var screen := Build.instance(_cabin, at, quad, surface)
	screen.rotation_degrees = turn
	screen.position += screen.basis.z * gap
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return screen


func _windows_and_wipers() -> void:
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.33, 0.50, 0.57, 0.14)
	glass.roughness = 0.09
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1, 1]:
		_windows.append(Build.box(_cabin, Vector3(side * 1.13, 2.12, -0.69),
			Vector3(0.015, 0.9, 1.48), glass))
	_glass = ShaderMaterial.new()
	_glass.shader = GLASS
	_glass.set_shader_parameter("wipe_mask", _wipe_map())
	_glass.set_shader_parameter("drop_radii", RainPhysics.RADII)
	_wiper_uniforms()
	var windshield := QuadMesh.new()
	windshield.size = Vector2(2.12, 1.08)
	var pane := Build.instance(_cabin, WINDSHIELD_CENTRE, windshield, _glass)
	pane.rotation.x = WINDSHIELD_RAKE
	fog_overlays.append(_fog_overlay(pane, windshield.size, Vector3(0, 0, 0.012), 0.0,
		LIGHT_FOG))
	for index in range(_windows.size()):
		var rain := ShaderMaterial.new()
		rain.shader = SIDE_RAIN
		rain.set_shader_parameter("seed", 13.0 * index)
		rain.set_shader_parameter("drop_radii", RainPhysics.RADII)
		var outward := -0.012 if index == 0 else 0.012
		var overlay := _fog_overlay(_windows[index], Vector2(1.48, 0.9),
			Vector3(outward, 0, 0), PI / 2, rain)
		overlay.sorting_offset = -0.05
		side_rain_overlays.append(overlay)
	_moon_roof()
	for index in range(WipeMap.PIVOTS.size()):
		var wiper := Wiper.new()
		wiper.name = "Wiper%d" % index
		_cabin.add_child(wiper)
		wiper.transform = _on_glass(WipeMap.PIVOTS[index])
		wiper.build(WipeMap.ARMS[index], WipeMap.BLADES[index])
		_wipers.append(wiper)
		_blades.append(wiper.blade)


func _beam_rain() -> void:
	_beam_rain_material = ShaderMaterial.new()
	_beam_rain_material.shader = BEAM_RAIN
	_beam_rain_material.set_shader_parameter("slant", RAIN_SLANT)
	var holder := Node3D.new()
	holder.name = "BeamRain"
	add_child(holder)
	var spread := tan(deg_to_rad(_headlights[0].spot_angle))
	for index in range(RAIN_LAYERS.size()):
		var ahead: float = RAIN_LAYERS[index]
		var quad := QuadMesh.new()
		quad.size = Vector2(2.0 * (ahead + 0.5) * spread + 1.8, minf(2.6 + ahead * 0.3, 9.0))
		var layer := Build.instance(holder, Vector3(0.0, quad.size.y * 0.5 - 0.2,
			LAMP_FRONT - ahead), quad, _beam_rain_material)
		layer.layers = 4
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.set_instance_shader_parameter("seed", 11.0 * index + 3.0)
		_rain_layers.append(layer)


func _light_the_rain() -> void:
	var lit: bool = vehicle.headlights_on
	for layer in _rain_layers:
		layer.visible = lit
	if not lit:
		return
	var lamp := _headlights[0]
	var strength := HIGH_BEAM_RAIN if vehicle.high_beams else LOW_BEAM_RAIN
	_beam_rain_material.set_shader_parameter("glow", strength.x)
	_beam_rain_material.set_shader_parameter("density", strength.y)
	_beam_rain_material.set_shader_parameter("pattern", lamp.light_projector)
	_beam_rain_material.set_shader_parameter("reach", lamp.spot_range)
	_beam_rain_material.set_shader_parameter("tan_half", tan(deg_to_rad(lamp.spot_angle)))
	_beam_rain_material.set_shader_parameter("lamp_left",
		Projection(_headlights[0].global_transform.affine_inverse()))
	_beam_rain_material.set_shader_parameter("lamp_right",
		Projection(_headlights[1].global_transform.affine_inverse()))


func _aim_beam(headlight: SpotLight3D, high: bool) -> void:
	headlight.light_projector = HIGH_BEAM if high else LOW_BEAM
	headlight.spot_range = HIGH_BEAM_RANGE if high else LOW_BEAM_RANGE


func _moon_roof() -> void:
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.albedo_color = Color(0.2, 0.27, 0.3, 0.25)
	tint.roughness = 0.08
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pane := QuadMesh.new()
	pane.size = MOON_ROOF.size
	var centre := MOON_ROOF.get_center()
	var glass := Build.instance(_cabin, Vector3(centre.x, MOON_ROOF_HEIGHT, centre.y), pane, tint)
	glass.name = "MoonRoofGlass"
	glass.rotation.x = -PI / 2
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rain := ShaderMaterial.new()
	rain.shader = SIDE_RAIN
	rain.set_shader_parameter("seed", 29.0)
	rain.set_shader_parameter("glass_size", MOON_ROOF.size)
	rain.set_shader_parameter("drop_radii", RainPhysics.RADII)
	roof_rain = _fog_overlay(glass, MOON_ROOF.size, Vector3(0, 0, 0.012), 0.0, rain)
	roof_rain.name = "MoonRoofRain"
	roof_rain.sorting_offset = -0.05


func _on_glass(at: Vector2) -> Transform3D:
	var tilt := Basis(Vector3.RIGHT, WINDSHIELD_RAKE)
	return Transform3D(tilt, WINDSHIELD_CENTRE + tilt * Vector3(at.x, at.y, 0.0))


func _wiper_uniforms() -> void:
	var first: Vector2 = WipeMap.PIVOTS[0]
	var second: Vector2 = WipeMap.PIVOTS[1]
	var near := WipeMap.span(0)
	var far := WipeMap.span(1)
	_glass.set_shader_parameter("wiper_pivots", Vector4(first.x, first.y, second.x, second.y))
	_glass.set_shader_parameter("wiper_spans", Vector4(near.x, near.y, far.x, far.y))
	_glass.set_shader_parameter("wiper_park", vehicle.WIPER_PARK)
	_glass.set_shader_parameter("wiper_sweep", vehicle.WIPER_SWEEP)


func _blade_water(swing: float, delta: float) -> void:
	var reach: float = (vehicle.wiper_angle - vehicle.WIPER_PARK) / vehicle.WIPER_SWEEP
	if _last_swing > 0.0 and swing <= 0.0 and reach > 0.8:
		_dump = 1.0
	_dump *= exp(-delta / DUMP_SECONDS)
	_last_swing = swing
	_glass.set_shader_parameter("blade_speed", swing)
	_glass.set_shader_parameter("stroke_progress", clampf(reach if swing > 0.0 else 1.0 - reach,
		0.0, 1.0))
	_glass.set_shader_parameter("dump", _dump)
	_glass.set_shader_parameter("wiper_cycles", vehicle.wiper_cycles())


func _wipe_map() -> Texture2D:
	var viewport := SubViewport.new()
	viewport.name = "WindshieldWipeMap"
	viewport.size = WIPE_MAP_SIZE
	viewport.disable_3d = true
	viewport.use_hdr_2d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var painter := WipeMap.new()
	painter.vehicle = vehicle
	painter.map_size = Vector2(WIPE_MAP_SIZE)
	viewport.add_child(painter)
	return viewport.get_texture()


func _fog_overlay(
	glass: Node3D, dimensions: Vector2, offset: Vector3, turn: float, material: Material
) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = dimensions
	var overlay := MeshInstance3D.new()
	overlay.mesh = quad
	overlay.material_override = material
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.position = offset
	overlay.rotation.y = turn
	glass.add_child(overlay)
	return overlay


func _follow_ground(delta: float) -> void:
	var space := vehicle.get_world_3d().direct_space_state
	var ground := PackedFloat32Array()
	for spot in WHEEL_SPOTS:
		_ground_ray.from = vehicle.to_global(spot + Vector3.UP * 1.5)
		_ground_ray.to = vehicle.to_global(spot + Vector3.DOWN * 2.0)
		var hit := space.intersect_ray(_ground_ray)
		ground.append(vehicle.to_local(hit.position).y if not hit.is_empty() else _ground_rest)
	var front := (ground[0] + ground[1]) * 0.5
	var rear := (ground[2] + ground[3]) * 0.5
	var target := Vector3(atan2(front - rear, WHEEL_SPOTS[2].z - WHEEL_SPOTS[0].z),
		(front + rear) * 0.5 - _ground_rest,
		atan2((ground[1] + ground[3]) * 0.5 - (ground[0] + ground[2]) * 0.5,
		WHEEL_SPOTS[1].x - WHEEL_SPOTS[0].x))
	_tilt = _tilt.lerp(target, 1.0 - exp(-delta * TILT_RATE))
	transform = Transform3D(Basis.from_euler(Vector3(_tilt.x, 0.0, _tilt.z)),
		Vector3(0.0, _tilt.y, 0.0))


func _mark_layer(node: Node, layer: int) -> void:
	if node is GeometryInstance3D:
		node.layers = layer
	for child in node.get_children():
		_mark_layer(child, layer)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(vehicle) or not vehicle.occupied or not vehicle.input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_target.x = clampf(_look_target.x - event.relative.y * 0.002, -0.55, LOOK_UP)
		_look_target.y = clampf(_look_target.y - event.relative.x * 0.002, -1.3, 1.3)
	if event.is_action_pressed("center_view"):
		_look_target = Vector2.ZERO


func update_vehicle(delta: float) -> void:
	_follow_ground(delta)
	_wheel.rotation.z = vehicle.steering * 2.2
	_look.rotation.x = lerp_angle(_look.rotation.x, _look_target.x, 1.0 - exp(-delta * 14))
	_look.rotation.y = lerp_angle(_look.rotation.y, _look_target.y, 1.0 - exp(-delta * 14))
	_look.rotation.z = lerp_angle(_look.rotation.z,
		-vehicle.steering * vehicle.speed * 0.0015, 1.0 - exp(-delta * 5))
	for index in range(_windows.size()):
		var openness: float = vehicle.left_window if index == 0 else vehicle.right_window
		_windows[index].position.y = 2.12 - openness * 0.88
	for headlight in _headlights:
		headlight.visible = vehicle.headlights_on
	if vehicle.high_beams != _high_beams_shown:
		_high_beams_shown = vehicle.high_beams
		for headlight in _headlights:
			_aim_beam(headlight, _high_beams_shown)
	_light_the_rain()
	for lens in _front_lenses:
		lens.material_override = _lens_on if vehicle.headlights_on else _lens_off
	for lamp in _rear_lamps:
		lamp.material_override = _red if vehicle.braking else _tail
	for index in range(_indicators.size()):
		var side := -1 if index < 2 else 1
		var lit: bool = vehicle.indicator_lit and (
			vehicle.hazards_on or vehicle.indicator == side)
		_indicators[index].material_override = _amber if lit else _amber_off
	for index in range(_tires.size()):
		_tires[index].rotation.y = vehicle.steering * 0.4 if index % 2 == 0 else 0.0
		_rolling_meshes[index].rotation.x -= vehicle.actual_speed * delta / 0.46
	for wiper in _wipers:
		wiper.rotation.z = vehicle.wiper_angle
	var stroke: float = vehicle.wiper_angle - _last_wiper
	_last_wiper = vehicle.wiper_angle
	for blade in _blades:
		blade.rotation.y = lerpf(blade.rotation.y, clampf(stroke * 60.0, -BLADE_FLIP, BLADE_FLIP),
			1.0 - exp(-delta * 25.0))
	_blade_water(stroke / maxf(delta, 0.0001), delta)
	_water = move_toward(_water, 0.6 if vehicle.wiper_setting > 0 else 1.0, delta * 0.12)
	_glass.set_shader_parameter("wetness", _water)
	_glass.set_shader_parameter("wipers_on", vehicle.wiper_setting > 0)
	_glass.set_shader_parameter("sweep_angle", vehicle.wiper_angle)
	var moving := absf(vehicle.actual_speed)
	_windshield_water.step(delta, Vector2(0.0, -cos(WINDSHIELD_RAKE)),
		Vector2(0.0, WINDSHIELD_AIR * moving), Vector2(0.0, 1.0))
	_side_water.step(delta, Vector2(0.0, -1.0), SIDE_AIR_DIRECTION * SIDE_AIR * moving,
		Vector2.ZERO)
	_roof_water.step(delta, ROOF_SLOPE, Vector2(0.0, -ROOF_AIR * moving), Vector2.ZERO)
	_glass.set_shader_parameter("speed", moving)
	_glass.set_shader_parameter("drop_travel", _windshield_water.travel)
	_glass.set_shader_parameter("drop_speed", _windshield_water.speed)
	_glass.set_shader_parameter("runner_speed", _windshield_water.runner_speed)
	_glass.set_shader_parameter("runner_down", _windshield_water.runner_down)
	_glass.set_shader_parameter("runner_up", _windshield_water.runner_up)
	_glass.set_shader_parameter("film_travel", _windshield_water.film_travel)
	for overlay in side_rain_overlays:
		var rain := overlay.material_override as ShaderMaterial
		rain.set_shader_parameter("speed", moving)
		rain.set_shader_parameter("flow_dir", _side_water.direction)
		rain.set_shader_parameter("travel_x", _side_water.travel_x)
		rain.set_shader_parameter("travel_y", _side_water.travel_y)
		rain.set_shader_parameter("runner_travel", _side_water.runner_travel)
		rain.set_shader_parameter("runner_speed", _side_water.runner_speed)
	var roof := roof_rain.material_override as ShaderMaterial
	roof.set_shader_parameter("speed", moving)
	roof.set_shader_parameter("flow_dir", _roof_water.direction)
	roof.set_shader_parameter("travel_x", _roof_water.travel_x)
	roof.set_shader_parameter("travel_y", _roof_water.travel_y)
	roof.set_shader_parameter("runner_travel", _roof_water.runner_travel)
	roof.set_shader_parameter("runner_speed", _roof_water.runner_speed)
	reverse_screen.visible = vehicle.gear < 0
	for index in range(mirror_cameras.size()):
		mirror_cameras[index].global_transform = global_transform * mirror_poses[index]
	_mirror_timer += delta
	if _mirror_timer >= 1.0 / MIRROR_UPDATES_PER_SECOND and vehicle.occupied:
		_mirror_timer = 0.0
		mirrors[_mirror_turn].render_target_update_mode = SubViewport.UPDATE_ONCE
		_mirror_turn = (_mirror_turn + 1) % mirrors.size()
		if vehicle.gear < 0 and _mirror_turn == 0:
			reverse_view.render_target_update_mode = SubViewport.UPDATE_ONCE
