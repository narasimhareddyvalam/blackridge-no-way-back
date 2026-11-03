extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const Instruments = preload("instruments.gd")
const Navigation = preload("navigation_display.gd")
const NightDimming = preload("night_dimming.gd")
const ParkingGuides = preload("parking_guides.gd")
const GLASS = preload("windshield.gdshader")
const EXTERIOR_ART = preload("art/iveco/iveco_exterior.glb")
const CAB_ART = preload("art/iveco/iveco_cab.glb")
const SCREEN = preload("cockpit_screen.gdshader")
const IVECO_PLACE := Vector3(0.0, 0.16, 0.5)
const SCREEN_GAP := 0.0015
const CLUSTER_SCREEN := Vector3(-0.4844, 1.4665, -1.3466)
const CLUSTER_SIZE := Vector2(0.432, 0.139)
const CLUSTER_TURN := Vector3(-19.77, -7.95, 0.0)
const MAP_SCREEN := Vector3(0.0, 1.5201, -1.2871)
const MAP_SIZE := Vector2(0.1361, 0.0708)
const MAP_TURN := Vector3(-23.68, 0.0, 0.0)
const MAP_PIXELS := Vector2i(768, 400)
const REVERSE_PIXELS := Vector2i(576, 300)
const SCREEN_PICTURE := Rect2(0.069, 0.744, 0.106, 0.05)
const SCREEN_COVER := 0.0005
const SCREEN_GLASS := 0.0045
const SCREEN_BORDER := Vector2(0.022, 0.042)
const SCREEN_BLACK := 0.012
const SCREEN_ANGLE := 0.25
const SCREEN_GLOW := 0.06
const BOOT_SECONDS := 1.2
const MIRROR_CAMERA := Vector3(1.2, 1.63, -1.2)
const MIRROR_GLASS := Vector3(1.142, 1.61, -1.272)
const MIRROR_GLASS_SIZE := Vector2(0.15, 0.19)
const WIDE_GLASS := Vector3(1.142, 1.43, -1.272)
const WIDE_GLASS_SIZE := Vector2(0.15, 0.11)
const TYRES: Array[String] = ["WheelFrontLeft", "WheelRearLeft", "WheelFrontRight",
	"WheelRearRight"]
const TYRE_RADIUS := 0.359
const WHEEL_SPOTS: Array[Vector3] = [Vector3(-0.872, 0, -1.507), Vector3(0.872, 0, -1.507),
	Vector3(-0.872, 0, 1.997), Vector3(0.872, 0, 1.997)]
const HEADLIGHT := Vector3(0.64, 1.15, -2.31)
const INDICATORS: Array[String] = ["FrontIndicatorLeft", "RearIndicatorLeft",
	"FrontIndicatorRight", "RearIndicatorRight"]
const TILT_RATE := 10.0
const BLADE_FLIP := 0.14
const LIGHT_FOG = preload("res://materials/windshield/light_fog.tres")
const SIDE_RAIN = preload("side_window_rain.gdshader")
const SIDE_GLASS = preload("side_glass.gdshader")
const RainPhysics = preload("rain_physics.gd")
const WINDSHIELD_RAKE := 0.7967
const WINDSHIELD_CENTRE := Vector3(0.0, 1.8493, -1.3888)
const PANE_SPLIT := 0.52
const HANDLE := Vector3(-0.042, -0.04, 1.026)
const DOME := Vector3(0.0, 2.184, -0.94)
const DOME_LENS := Vector3(0.18, 0.012, 0.08)
const DOME_BEZEL := Vector3(0.21, 0.01, 0.1)
const DOME_COLOR := Color("ffe2b8")
const DOME_ENERGY := 1.1
const DOME_RANGE := 2.6
const DOME_GLOW := 2.5
const DOME_ON := 0.12
const DOME_FADE := 2.0
const SILL_SAMPLES := 32
const DROP_MARGIN := 0.02
const DUMP_SECONDS := 0.7
const MOON_ROOF := Rect2(-0.52, -0.8, 1.04, 0.44)
const MOON_ROOF_HEIGHT := 2.226
const ROOF_TOP := 2.231
const ROOF_FRAME := Vector3(0.05, 2.18, 2.228)
const ROOF_SEAL := 0.02
const ROOF_SLOPE := Vector2(0.0, -0.05)
const ROOF_AIR := 0.8
const LOOK_UP := 1.05
const BEAM_RAIN = preload("beam_rain.gdshader")
const RAIN_LAYERS: Array[float] = [3.0, 4.5, 6.5, 9.0, 12.5, 17.0, 23.0, 31.0]
const LAMP_FRONT := -2.31
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
const DOOR_SWING := 0.541
const GLARE_FALLOFF := 40.0
const GLARE_RATE := 12.0
const OFF_GLASS := Vector2(9.0, 9.0)
const ONCOMING_RAIN_REACH := 70.0
const BACKLIT_RAIN := 2.5
const EYE := Vector3(-0.45, 1.88, -0.72)
const JOLT_FADE := 2.5
const ROCK_STIFFNESS := 38.0
const ROCK_DAMPING := 3.0
const ROCK_KICK := 0.12
const LEAN := Vector3(0.0, 0.05, -0.42)
const LEAN_RATE := 1.5
const LOOK_DOWN := -0.55
const CAMERA_TILT := 0.15
const CRACK_GROWTH := 6.0
const CRACK_AREA := Rect2(-0.7, -0.42, 1.2, 0.82)
const DAZZLE := 1.2
const ADAPT_ATTACK := 3.0
const ADAPT_RELEASE := 0.5
const FRONT_LAYER := 16
const FRONT_PROFILE: Array[Vector3] = [Vector3(0.99, 0.41, -2.5), Vector3(0.99, 0.96, -2.5),
	Vector3(0.95, 1.16, -2.42), Vector3(0.92, 1.41, -2.33), Vector3(0.9, 1.56, -1.79),
	Vector3(0.9, 1.5, -1.0), Vector3(0.99, 0.41, -1.0)]
const GLASS_PROFILE: Array[Vector3] = [Vector3(0.92, 1.45, -1.8), Vector3(0.92, 2.2, -1.03),
	Vector3(0.92, 2.23, -0.5), Vector3(0.92, 1.45, -0.5)]
const BONNET_FRICTION := 0.3
const HEAD_REACH := 0.16
const COWL := 0.1
const HEAD_WATCH := 1.0

var driving_camera: Camera3D
var navigation: Control
var night_dimming: Node
var mirrors: Array[SubViewport] = []
var reverse_view: SubViewport
var reverse_screen: MeshInstance3D
var vehicle: CharacterBody3D
var oncoming: Node3D
var look_target_node: Node3D
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
var _window_drop: Array[float] = []
var cabin_lamp: OmniLight3D
var _dome_lens := StandardMaterial3D.new()
var _dome_level := 0.0
var _window_glass: Array[ShaderMaterial] = []
var _window_lowered: Array[float] = [0.0, 0.0]
var _headlights: Array[SpotLight3D] = []
var _front_lenses: Array[MeshInstance3D] = []
var _rear_lamps: Array[MeshInstance3D] = []
var _indicators: Array[MeshInstance3D] = []
var _tires: Array[Node3D] = []
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
var _door: Node3D
var _door_glass := Node3D.new()
var _powered_screens: Array[MeshInstance3D] = []
var _dark_screens: Array[MeshInstance3D] = []
var _powered_views: Array[SubViewport] = []
var _screens_on: bool = true
var _screen_power: float = 0.0
var _map_screen: MeshInstance3D
var _screen_light: OmniLight3D
var _windshield: MeshInstance3D
var _glare := Vector2.ZERO
var _jolt: float = 0.0
var _adapt: float = 0.0
var _jolt_time: float = 0.0
var _rock: float = 0.0
var _rock_speed: float = 0.0
var _lean: float = 0.0
var _leaning: bool = false
var _crack: float = 0.0
var _crack_target: float = 0.0
var _front := AnimatableBody3D.new()
var _head: Node3D
var _head_watch: float = -1.0
var _head_strength: float = 0.0
var _glare_ray := PhysicsRayQueryParameters3D.new()
var _trim := Build.material(Color("141c22"), 0.86)
var _seal := Build.material(Color("0b0d0f"), 0.55)
var _amber := Build.luminous(Color("ff9e30"), 1.2)
var _red := Build.luminous(Color("e1442e"))
var _tail := Build.luminous(Color("68251e"))
var _lens_on := Build.luminous(Color("e9ebdc"), 2.0)


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_last_wiper = van.wiper_angle
	var box := van.get_node("CollisionShape3D") as CollisionShape3D
	_ground_rest = box.position.y - (box.shape as BoxShape3D).size.y * 0.5
	_ground_ray.exclude = [van.get_rid()]
	_ground_ray.collision_mask = van.collision_mask
	_glare_ray.collision_mask = 1
	add_child(_body)
	add_child(_cabin)
	_exterior()
	_beam_rain()
	_interior()
	_camera()
	_displays()
	_windows_and_wipers()
	_front_shell()
	_mark_layer(_body, 2)
	_mark_layer(_cabin, 4)


func _front_shell() -> void:
	_front.name = "FrontShell"
	_front.top_level = true
	_front.collision_layer = FRONT_LAYER
	_front.collision_mask = 0
	_front.physics_material_override = PhysicsMaterial.new()
	_front.physics_material_override.friction = BONNET_FRICTION
	for profile: Array[Vector3] in [FRONT_PROFILE, GLASS_PROFILE]:
		var points := PackedVector3Array()
		for point in profile:
			points.append(point)
			points.append(Vector3(-point.x, point.y, point.z))
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.shape = shape
		_front.add_child(collision)
	add_child(_front)
	_front.global_transform = global_transform


func _exterior() -> void:
	var outside := EXTERIOR_ART.instantiate() as Node3D
	outside.name = "Iveco"
	outside.position = IVECO_PLACE
	_body.add_child(outside)
	_door = outside.get_node("DriverDoor") as Node3D
	var headlights := outside.get_node("Headlights") as MeshInstance3D
	var tail_lamps := outside.get_node("TailLamps") as MeshInstance3D
	_front_lenses.append(headlights)
	_rear_lamps.append(tail_lamps)
	for label in INDICATORS:
		_indicators.append(outside.get_node(label) as MeshInstance3D)
	for lens: MeshInstance3D in _indicators + [headlights, tail_lamps,
			outside.get_node("BodyGlass")]:
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1, 1]:
		var headlight := SpotLight3D.new()
		headlight.position = Vector3(side * HEADLIGHT.x, HEADLIGHT.y, HEADLIGHT.z)
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
	for label in TYRES:
		_tires.append(outside.get_node(label) as Node3D)


func _interior() -> void:
	var cab := CAB_ART.instantiate() as Node3D
	cab.name = "IvecoCab"
	cab.position = IVECO_PLACE
	_cabin.add_child(cab)
	for mesh: GeometryInstance3D in cab.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wheel = cab.get_node("SteeringWheel") as Node3D
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.75, -0.85)
	light.light_color = Color("b7c2c9")
	light.light_energy = 0.45
	light.omni_range = 2.5
	light.light_cull_mask = 4
	_cabin.add_child(light)
	_dome_lamp()
	_cover_screen(cab)


func _dome_lamp() -> void:
	Build.box(_cabin, DOME + Vector3.UP * 0.003, DOME_BEZEL, Build.material(Color("3a3b3c"), 0.6))
	_dome_lens.albedo_color = Color("d9d2c4")
	_dome_lens.roughness = 0.4
	_dome_lens.emission_enabled = true
	_dome_lens.emission = DOME_COLOR
	_dome_lens.emission_energy_multiplier = 0.0
	Build.box(_cabin, DOME, DOME_LENS, _dome_lens)
	cabin_lamp = OmniLight3D.new()
	cabin_lamp.name = "CabinLamp"
	cabin_lamp.position = DOME + Vector3.DOWN * 0.05
	cabin_lamp.light_color = DOME_COLOR
	cabin_lamp.light_energy = 0.0
	cabin_lamp.omni_range = DOME_RANGE
	cabin_lamp.light_cull_mask = 6
	cabin_lamp.visible = false
	_cabin.add_child(cabin_lamp)


func _camera() -> void:
	_look = Node3D.new()
	_look.position = EYE
	add_child(_look)
	driving_camera = Camera3D.new()
	driving_camera.fov = 74.0
	driving_camera.rotation.x = -0.15
	driving_camera.near = 0.045
	driving_camera.far = 350.0
	driving_camera.cull_mask = 7
	driving_camera.attributes = CameraAttributesPractical.new()
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
	_powered_screens.append(_dash_screen(instruments, CLUSTER_SCREEN, CLUSTER_SIZE, CLUSTER_TURN))
	_dark_screens.append(_blank_screen(CLUSTER_SCREEN, CLUSTER_SIZE, CLUSTER_TURN))
	navigation = Navigation.new()
	navigation.vehicle = vehicle
	var gps := _display_viewport(MAP_PIXELS, navigation)
	_map_screen = _dash_screen(gps, MAP_SCREEN, MAP_SIZE, MAP_TURN)
	_lcd(_map_screen)
	_powered_screens.append(_map_screen)
	_dark_screens.append(_blank_screen(MAP_SCREEN, MAP_SIZE, MAP_TURN))
	_powered_views.append_array([instruments, gps])
	for side in [-1, 1]:
		mirrors.append(_camera_view(Vector3(side * MIRROR_CAMERA.x, MIRROR_CAMERA.y,
			MIRROR_CAMERA.z), Vector3(0, PI + side * 0.13, 0), Vector2i(256, 320), 62.0))
	reverse_view = _camera_view(Vector3(0, 2.15, 3.0), Vector3(-0.28, PI, 0), REVERSE_PIXELS,
		85.0)
	reverse_view.add_child(ParkingGuides.new())
	reverse_screen = _dash_screen(reverse_view, MAP_SCREEN, MAP_SIZE, MAP_TURN, false,
		2.0 * SCREEN_GAP)
	_lcd(reverse_screen)
	reverse_screen.visible = false
	_screen_glass()


func _lcd(screen: MeshInstance3D) -> void:
	var surface := screen.material_override as ShaderMaterial
	surface.set_shader_parameter("border", SCREEN_BORDER)
	surface.set_shader_parameter("black_level", SCREEN_BLACK)
	surface.set_shader_parameter("view_falloff", SCREEN_ANGLE)
	surface.set_shader_parameter("power", _screen_power)


func _screen_glass() -> void:
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.02, 0.025, 0.03, 0.12)
	glass.roughness = 0.06
	glass.metallic_specular = 0.6
	var pane := QuadMesh.new()
	pane.size = MAP_SIZE + Vector2(0.004, 0.004)
	var front := Build.instance(_cabin, MAP_SCREEN - _cabin.position, pane, glass)
	front.name = "ScreenGlass"
	front.rotation_degrees = MAP_TURN
	front.position += front.basis.z * SCREEN_GLASS
	front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_screen_light = OmniLight3D.new()
	_screen_light.name = "ScreenGlow"
	_screen_light.position = MAP_SCREEN - _cabin.position + front.basis.z * 0.06
	_screen_light.light_color = Color("8fb2ff")
	_screen_light.light_energy = 0.0
	_screen_light.omni_range = 0.45
	_screen_light.light_cull_mask = 4
	_cabin.add_child(_screen_light)


func _cover_screen(cab: Node3D) -> void:
	var faces := PackedVector3Array()
	var lift := Basis.from_euler(MAP_TURN * PI / 180.0).z * SCREEN_COVER
	for mesh: MeshInstance3D in cab.find_children("*", "MeshInstance3D", true, false):
		var to_cab := cab.global_transform.affine_inverse() * mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.mesh.surface_get_material(surface)
			if material == null or material.resource_name != "Dashboard":
				continue
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for corner in range(0, order.size(), 3):
				var inside := true
				for k in range(3):
					inside = inside and SCREEN_PICTURE.has_point(uvs[order[corner + k]])
				if inside:
					for k in range(3):
						faces.append(to_cab * points[order[corner + k]] + lift)
	var cover_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	cover_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var cover := Build.instance(_cabin, cab.position, cover_mesh, Build.material(Color("050607"),
		0.6))
	cover.name = "ScreenCover"
	cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _power_screens(on: bool) -> void:
	_screens_on = on
	for screen in _powered_screens:
		screen.visible = on
	for screen in _dark_screens:
		screen.visible = not on
	for view in _powered_views:
		view.render_target_update_mode = (SubViewport.UPDATE_ALWAYS if on
			else SubViewport.UPDATE_DISABLED)


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


func _dash_screen(
	viewport: SubViewport, at: Vector3, dimensions: Vector2, turn: Vector3 = Vector3.ZERO,
	mirror: bool = false, gap: float = SCREEN_GAP, holder: Node3D = null
) -> MeshInstance3D:
	var parent := holder if holder != null else _cabin
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
	var screen := Build.instance(parent, at - parent.position, quad, surface)
	screen.rotation_degrees = turn
	screen.position += screen.basis.z * gap
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return screen


func _blank_screen(at: Vector3, dimensions: Vector2, turn: Vector3) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = dimensions
	var screen := Build.instance(_cabin, at, quad, Build.material(Color("050607"), 0.18))
	screen.rotation_degrees = turn
	screen.position += screen.basis.z * SCREEN_GAP
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.visible = false
	return screen


func _mirror_glass() -> void:
	for index in range(mirrors.size()):
		var side := -1.0 if index == 0 else 1.0
		var holder: Node3D = _door_glass if index == 0 else _cabin
		for spot: Array in [[MIRROR_GLASS, MIRROR_GLASS_SIZE], [WIDE_GLASS, WIDE_GLASS_SIZE]]:
			var at: Vector3 = spot[0]
			_dash_screen(mirrors[index], Vector3(side * at.x, at.y, at.z), spot[1], Vector3.ZERO,
				true, SCREEN_GAP, holder)


func _windows_and_wipers() -> void:
	var outside := _body.get_node("Iveco") as Node3D
	_door_glass.name = "DriverDoorGlass"
	_door_glass.position = outside.position + _door.position
	_cabin.add_child(_door_glass)
	var driver_window := _door.get_node("DriverWindow") as MeshInstance3D
	driver_window.reparent(_door_glass)
	var passenger_window := outside.get_node("PassengerDoor/PassengerWindow") as MeshInstance3D
	passenger_window.reparent(_cabin)
	_windows.assign([driver_window, passenger_window])
	for window in _windows:
		var pane := ShaderMaterial.new()
		pane.shader = SIDE_GLASS
		_window_drop.append(_slide_into_door(pane, window.mesh))
		_window_glass.append(pane)
		window.material_override = pane
		window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glass = ShaderMaterial.new()
	_glass.shader = GLASS
	_glass.set_shader_parameter("glass_size", WipeMap.GLASS_SIZE)
	_glass.set_shader_parameter("wipe_mask", _wipe_map())
	_glass.set_shader_parameter("drop_radii", RainPhysics.RADII)
	_wiper_uniforms()
	_windshield = _glass_pane(outside.get_node("Windshield") as MeshInstance3D)
	fog_overlays.append(_fog_overlay(_windshield, _windshield.mesh, Vector3(0, 0, 0.012),
		LIGHT_FOG))
	for index in range(_windows.size()):
		var shape := _side_glass(_windows[index])
		var rain := ShaderMaterial.new()
		rain.shader = SIDE_RAIN
		rain.set_shader_parameter("seed", 13.0 * index)
		rain.set_shader_parameter("glass_size", shape[1])
		rain.set_shader_parameter("drop_radii", RainPhysics.RADII)
		_slide_into_door(rain, _windows[index].mesh)
		var outward := -0.012 if index == 0 else 0.012
		var overlay := _fog_overlay(_windows[index], shape[0], Vector3(outward, 0, 0), rain)
		overlay.sorting_offset = -0.05
		side_rain_overlays.append(overlay)
	_moon_roof()
	_mirror_glass()
	for index in range(WipeMap.PIVOTS.size()):
		var wiper := Wiper.new()
		wiper.name = "Wiper%d" % index
		_cabin.add_child(wiper)
		wiper.transform = _on_glass(WipeMap.PIVOTS[index])
		wiper.build(WipeMap.ARMS[index], WipeMap.BLADES[index])
		_wipers.append(wiper)
		_blades.append(wiper.blade)


func _glass_pane(source: MeshInstance3D) -> MeshInstance3D:
	var frame := Transform3D(Basis(Vector3.RIGHT, WINDSHIELD_RAKE), WINDSHIELD_CENTRE)
	var size := WipeMap.GLASS_SIZE
	var pane := MeshInstance3D.new()
	pane.name = "Windshield"
	pane.mesh = _projected(source.mesh, frame.affine_inverse() * _local(source),
		func(at: Vector3) -> Vector2: return Vector2(at.x / size.x + 0.5, 0.5 - at.y / size.y))
	pane.transform = frame
	pane.material_override = _glass
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cabin.add_child(pane)
	source.queue_free()
	return pane


func _slide_into_door(material: ShaderMaterial, mesh: Mesh) -> float:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var corners: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var span := Vector2(INF, -INF)
	for at in vertices:
		if at.z > PANE_SPLIT:
			span = Vector2(minf(span.x, at.z), maxf(span.y, at.z))
	var sill := PackedFloat32Array()
	sill.resize(SILL_SAMPLES)
	sill.fill(INF)
	for first in range(0, corners.size(), 3):
		var triangle: Array[Vector3] = [vertices[corners[first]], vertices[corners[first + 1]],
			vertices[corners[first + 2]]]
		if triangle[0].z <= PANE_SPLIT:
			continue
		for sample in range(SILL_SAMPLES):
			var z := lerpf(span.x, span.y, float(sample) / (SILL_SAMPLES - 1))
			for edge in range(3):
				var from := triangle[edge]
				var to := triangle[(edge + 1) % 3]
				if (from.z - z) * (to.z - z) > 0.0:
					continue
				var y := minf(from.y, to.y) if is_equal_approx(from.z, to.z) \
					else lerpf(from.y, to.y, (z - from.z) / (to.z - from.z))
				sill[sample] = minf(sill[sample], y)
	var height := 0.0
	for at in vertices:
		if at.z > PANE_SPLIT:
			var along := (at.z - span.x) / (span.y - span.x) * (SILL_SAMPLES - 1)
			var below := mini(floori(along), SILL_SAMPLES - 2)
			height = maxf(height, at.y - lerpf(sill[below], sill[below + 1], along - below))
	material.set_shader_parameter("slides", true)
	material.set_shader_parameter("pane_split", PANE_SPLIT)
	material.set_shader_parameter("sill", sill)
	material.set_shader_parameter("sill_span", span)
	return height + DROP_MARGIN


func door_handle() -> Vector3:
	return _door.global_transform * HANDLE


func door_opening_toward(point: Vector3) -> float:
	var hinge := vehicle.to_local(_door.global_position)
	var at := vehicle.to_local(point)
	return atan2(hinge.x - at.x, at.z - hinge.z) / DOOR_SWING


func _light_the_cab(delta: float) -> void:
	var wanted := 1.0 if vehicle.cabin_light or vehicle.driver_door > 0.001 else 0.0
	_dome_level = move_toward(_dome_level, wanted,
		delta / (DOME_ON if wanted > _dome_level else DOME_FADE))
	cabin_lamp.visible = _dome_level > 0.0
	cabin_lamp.light_energy = DOME_ENERGY * _dome_level
	_dome_lens.emission_energy_multiplier = DOME_GLOW * _dome_level


func _side_glass(window: MeshInstance3D) -> Array:
	var box := window.mesh.get_aabb()
	var middle := box.get_center()
	var size := Vector2(box.size.z, box.size.y)
	var mesh := _projected(window.mesh, Transform3D.IDENTITY,
		func(at: Vector3) -> Vector2: return Vector2((middle.z - at.z) / size.x + 0.5,
			0.5 - (at.y - middle.y) / size.y))
	return [mesh, size]


func _projected(mesh: Mesh, into: Transform3D, uv_of: Callable) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for corner in index:
			var at := into * vertices[corner]
			tool.set_normal((into.basis * normals[corner]).normalized())
			tool.set_uv(uv_of.call(at))
			tool.add_vertex(at)
	tool.generate_tangents()
	return tool.commit()


func _local(node: Node3D) -> Transform3D:
	return global_transform.affine_inverse() * node.global_transform


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
	var backlit := _oncoming_rain()
	for layer in _rain_layers:
		layer.visible = lit or backlit > 0.0
	if not lit and backlit <= 0.0:
		return
	_beam_rain_material.set_shader_parameter("beams", 1.0 if lit else 0.0)
	_beam_rain_material.set_shader_parameter("oncoming", backlit)
	if backlit > 0.0:
		var lamps: Array = oncoming.get("lamps")
		_beam_rain_material.set_shader_parameter("oncoming_pattern", lamps[0].light_projector)
		_beam_rain_material.set_shader_parameter("oncoming_reach", lamps[0].spot_range)
		_beam_rain_material.set_shader_parameter("oncoming_left",
			Projection(lamps[0].global_transform.affine_inverse()))
		_beam_rain_material.set_shader_parameter("oncoming_right",
			Projection(lamps[1].global_transform.affine_inverse()))
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


func _oncoming_rain() -> float:
	if not is_instance_valid(oncoming):
		return 0.0
	var toward := global_position - oncoming.global_position
	if toward.length() > ONCOMING_RAIN_REACH or (-oncoming.global_basis.z).dot(toward) <= 0.0:
		return 0.0
	return float(oncoming.call("beam_power")) * BACKLIT_RAIN


func _update_glare(delta: float) -> void:
	var points := Vector4(OFF_GLASS.x, OFF_GLASS.y, OFF_GLASS.x, OFF_GLASS.y)
	var target := Vector2.ZERO
	if is_instance_valid(oncoming):
		var lamps: Array = oncoming.get("lamps")
		var eye := driving_camera.global_position
		for index in range(2):
			var lamp: Node3D = lamps[index]
			var on_glass := _on_windshield(eye, lamp.global_position)
			var to_eye := eye - lamp.global_position
			var facing := maxf(0.0, (-lamp.global_basis.z).dot(to_eye.normalized()))
			var power := float(oncoming.call("beam_power")) * pow(facing, 3.0) / (
				1.0 + pow(to_eye.length() / GLARE_FALLOFF, 2.0))
			if on_glass == OFF_GLASS or power < 0.005 or _hidden(eye, lamp.global_position):
				power = 0.0
			target[index] = power
			points[index * 2] = on_glass.x
			points[index * 2 + 1] = on_glass.y
	_glare = _glare.lerp(target, 1.0 - exp(-delta * GLARE_RATE))
	var peak := maxf(target.x, target.y)
	var rate := ADAPT_ATTACK if peak > _adapt else ADAPT_RELEASE
	_adapt = lerpf(_adapt, peak, 1.0 - exp(-delta * rate))
	driving_camera.attributes.exposure_multiplier = 1.0 / (1.0 + DAZZLE * _adapt)
	_glass.set_shader_parameter("glare_points", points)
	_glass.set_shader_parameter("glare_power", _glare)


func _on_windshield(eye: Vector3, target: Vector3) -> Vector2:
	var pane := _windshield.global_transform
	var normal := pane.basis.z.normalized()
	var ray := (target - eye).normalized()
	var facing := ray.dot(normal)
	if absf(facing) < 0.0001:
		return OFF_GLASS
	var reach := (pane.origin - eye).dot(normal) / facing
	if reach <= 0.0:
		return OFF_GLASS
	var local := pane.affine_inverse() * (eye + ray * reach)
	var half := WipeMap.GLASS_SIZE * 0.5
	if absf(local.x) > half.x or absf(local.y) > half.y:
		return OFF_GLASS
	return Vector2(local.x, local.y)


func _hidden(eye: Vector3, target: Vector3) -> bool:
	_glare_ray.from = eye
	_glare_ray.to = target
	_glare_ray.exclude = [vehicle.get_rid(), (oncoming as CollisionObject3D).get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(_glare_ray).is_empty()


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
	roof_rain = _fog_overlay(glass, pane, Vector3(0, 0, 0.012), rain)
	roof_rain.name = "MoonRoofRain"
	roof_rain.sorting_offset = -0.05
	var half := MOON_ROOF.size * 0.5
	var width := ROOF_FRAME.x
	var frame_middle := (ROOF_FRAME.y + ROOF_FRAME.z) * 0.5
	var frame_height := ROOF_FRAME.z - ROOF_FRAME.y
	for side in [-1, 1]:
		Build.box(_cabin, Vector3(centre.x + side * (half.x + width * 0.5), frame_middle,
			centre.y), Vector3(width, frame_height, MOON_ROOF.size.y + 2.0 * width), _trim)
		Build.box(_cabin, Vector3(centre.x, frame_middle, centre.y + side * (half.y + width * 0.5)),
			Vector3(MOON_ROOF.size.x, frame_height, width), _trim)
		Build.box(_body, Vector3(centre.x + side * (half.x + ROOF_SEAL * 0.5), ROOF_TOP + 0.003,
			centre.y), Vector3(ROOF_SEAL, 0.008, MOON_ROOF.size.y + 2.0 * ROOF_SEAL), _seal)
		Build.box(_body, Vector3(centre.x, ROOF_TOP + 0.003,
			centre.y + side * (half.y + ROOF_SEAL * 0.5)),
			Vector3(MOON_ROOF.size.x, 0.008, ROOF_SEAL), _seal)


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


func _fog_overlay(glass: Node3D, mesh: Mesh, offset: Vector3, material: Material) -> MeshInstance3D:
	var overlay := MeshInstance3D.new()
	overlay.mesh = mesh
	overlay.material_override = material
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.position = offset
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
	transform = Transform3D(Basis.from_euler(Vector3(_tilt.x + _rock, 0.0, _tilt.z)),
		Vector3(0.0, _tilt.y, 0.0))


func _lean_to_look(delta: float) -> void:
	var leaning: bool = vehicle.held and absf(vehicle.speed) < 0.3 \
		and is_instance_valid(look_target_node)
	_lean = move_toward(_lean, 1.0 if leaning else 0.0, delta * LEAN_RATE)
	if leaning:
		var to := to_local(look_target_node.global_position) - _look.position
		_look_target = Vector2(clampf(atan2(to.y, Vector2(to.x, to.z).length()) + CAMERA_TILT,
			LOOK_DOWN, LOOK_UP), atan2(-to.x, -to.z))
	elif _leaning:
		_look_target = Vector2.ZERO
	_leaning = leaning


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


func jolt(strength: float) -> void:
	_jolt = maxf(_jolt, strength)
	_rock_speed -= strength * ROCK_KICK


func crack_at(point: Vector3, strength: float) -> void:
	var local := _windshield.global_transform.affine_inverse() * point
	var spot := Vector2(clampf(local.x, CRACK_AREA.position.x, CRACK_AREA.end.x),
		clampf(local.y, CRACK_AREA.position.y, CRACK_AREA.end.y))
	_glass.set_shader_parameter("crack_point", spot)
	_glass.set_shader_parameter("crack_seed", fmod(absf(point.x * 13.7 + point.z * 7.3), 97.0))
	_crack_target = clampf(strength, 0.0, 1.0)


func watch_head(head: Node3D, strength: float) -> void:
	_head = head
	_head_strength = strength
	_head_watch = 0.0


func _watch_head(delta: float) -> void:
	if _head_watch < 0.0:
		return
	_head_watch += delta
	if not is_instance_valid(_head) or _head_watch > HEAD_WATCH:
		_head_watch = -1.0
		return
	var local := _windshield.global_transform.affine_inverse() * _head.global_position
	var half := WipeMap.GLASS_SIZE * 0.5
	if -local.z < HEAD_REACH and absf(local.x) < half.x and local.y > -half.y - COWL \
			and local.y < half.y:
		_head_watch = -1.0
		crack_at(_head.global_position, _head_strength)


func crack_state() -> Dictionary:
	return {"point": _glass.get_shader_parameter("crack_point"),
		"seed": _glass.get_shader_parameter("crack_seed"), "amount": _crack_target}


func restore_crack(state: Dictionary) -> void:
	if float(state.get("amount", 0.0)) <= 0.0:
		return
	_glass.set_shader_parameter("crack_point", state["point"])
	_glass.set_shader_parameter("crack_seed", state["seed"])
	_crack_target = float(state["amount"])
	_crack = _crack_target
	_glass.set_shader_parameter("crack_amount", _crack)


func clear_crack() -> void:
	_head_watch = -1.0
	_crack = 0.0
	_crack_target = 0.0
	_glass.set_shader_parameter("crack_amount", 0.0)


func update_vehicle(delta: float) -> void:
	_rock_speed += (-ROCK_STIFFNESS * _rock - ROCK_DAMPING * _rock_speed) * delta
	_rock += _rock_speed * delta
	_follow_ground(delta)
	_front.global_transform = global_transform
	_watch_head(delta)
	_jolt_time += delta
	_jolt = move_toward(_jolt, 0.0, delta * JOLT_FADE)
	_lean_to_look(delta)
	_look.position = EYE + LEAN * smoothstep(0.0, 1.0, _lean) + Vector3(
		sin(_jolt_time * 37.0) * 0.02, sin(_jolt_time * 53.0) * 0.03, 0.0) * _jolt
	if _crack != _crack_target:
		_crack = move_toward(_crack, _crack_target, delta * CRACK_GROWTH)
		_glass.set_shader_parameter("crack_amount", _crack)
	_wheel.rotation.z = vehicle.steering * 2.2
	_look.rotation.x = lerp_angle(_look.rotation.x, _look_target.x, 1.0 - exp(-delta * 14))
	_look.rotation.y = lerp_angle(_look.rotation.y, _look_target.y, 1.0 - exp(-delta * 14))
	_look.rotation.z = lerp_angle(_look.rotation.z,
		-vehicle.steering * vehicle.speed * 0.0015, 1.0 - exp(-delta * 5))
	for index in range(_windows.size()):
		var openness: float = vehicle.left_window if index == 0 else vehicle.right_window
		var lowered := openness * _window_drop[index]
		if not is_equal_approx(_window_lowered[index], lowered):
			_window_lowered[index] = lowered
			_window_glass[index].set_shader_parameter("lowered", lowered)
			(side_rain_overlays[index].material_override as ShaderMaterial).set_shader_parameter(
				"lowered", lowered)
	_door.rotation.y = -vehicle.driver_door * DOOR_SWING
	_door_glass.rotation.y = _door.rotation.y
	_light_the_cab(delta)
	if vehicle.engine_on != _screens_on:
		_power_screens(vehicle.engine_on)
	_screen_power = move_toward(_screen_power, 1.0 if _screens_on else 0.0, delta / BOOT_SECONDS)
	for screen: MeshInstance3D in [_map_screen, reverse_screen]:
		(screen.material_override as ShaderMaterial).set_shader_parameter("power", _screen_power)
	_screen_light.light_energy = SCREEN_GLOW * _screen_power
	for headlight in _headlights:
		headlight.visible = vehicle.headlights_on
	if vehicle.high_beams != _high_beams_shown:
		_high_beams_shown = vehicle.high_beams
		for headlight in _headlights:
			_aim_beam(headlight, _high_beams_shown)
	_light_the_rain()
	for lens in _front_lenses:
		lens.material_override = _lens_on if vehicle.headlights_on else null
	for lamp in _rear_lamps:
		lamp.material_override = (_red if vehicle.braking else _tail) if vehicle.engine_on else null
	for index in range(_indicators.size()):
		var side := -1 if index < 2 else 1
		var lit: bool = vehicle.indicator_lit and (
			vehicle.hazards_on or vehicle.indicator == side)
		_indicators[index].material_override = _amber if lit else null
	for index in range(_tires.size()):
		_tires[index].rotation.y = vehicle.steering * 0.4 if index % 2 == 0 else 0.0
		_tires[index].rotation.x -= vehicle.actual_speed * delta / TYRE_RADIUS
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
	_update_glare(delta)
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
	reverse_screen.visible = vehicle.gear < 0 and _screens_on
	for index in range(mirror_cameras.size()):
		mirror_cameras[index].global_transform = global_transform * mirror_poses[index]
	_mirror_timer += delta
	if _mirror_timer >= 1.0 / MIRROR_UPDATES_PER_SECOND and vehicle.occupied:
		_mirror_timer = 0.0
		mirrors[_mirror_turn].render_target_update_mode = SubViewport.UPDATE_ONCE
		_mirror_turn = (_mirror_turn + 1) % mirrors.size()
		if vehicle.gear < 0 and _mirror_turn == 0:
			reverse_view.render_target_update_mode = SubViewport.UPDATE_ONCE
