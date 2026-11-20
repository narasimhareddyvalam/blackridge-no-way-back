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
## The Iveco's painted panels, by their materials' names in `iveco_exterior.glb`.
const PAINTED: Array[String] = ["Body_exterior_1", "Body_exterior_2", "Lateral_door", "Front_door",
	"Back_door"]
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
const MIRROR_GLASS: Array[Mesh] = [preload("art/iveco/mirror_glass_left.tres"),
	preload("art/iveco/mirror_glass_right.tres")]
const MIRROR_SHADER = preload("mirror_glass.gdshader")
const MIRROR_LAYER := 8
const MIRROR_LIFT := 0.002
const MIRROR_PIXELS := 640
const MIRROR_RATES: Array[float] = [30.0, 15.0]
const MIRROR_HEADROOM := 8.0
const MIRROR_REFLECTANCE := 0.6
const MIRROR_FILL := 0.05
const MIRROR_FAR := 100.0
const REFLECTION_LOD_THRESHOLD := 12.0
const GLASS_RADII := Vector2(1.6, 0.4)
const INNER_EDGE := Vector2(4.5, 8.0)
const WIDE_DOWN := 16.0
const REVERSE_RATE := 22.5
const MIRROR_HEAD := AABB(Vector3(1.0, 1.33, -1.42), Vector3(0.3, 0.42, 0.2))
const MIRROR_ARM := 0.04
const MIRROR_TURN := 25.0
const TYRES: Array[String] = ["WheelFrontLeft", "WheelRearLeft", "WheelFrontRight",
	"WheelRearRight"]
const TYRE_RADIUS := 0.359
const WHEEL_SPOTS: Array[Vector3] = [Vector3(-0.872, 0, -1.507), Vector3(0.872, 0, -1.507),
	Vector3(-0.872, 0, 1.997), Vector3(0.872, 0, 1.997)]
const HEADLIGHT := Vector3(0.64, 1.15, -2.31)
const REVERSE_LAMP := Vector3(0.86, 1.0, 2.84)
const REVERSE_ENERGY := 6.0
const REVERSE_RANGE := 14.0
const REVERSE_GAIN := 3.0
## The reversing camera on the roof's rear edge, where the Daily's sits in its third brake
## light, tilted 45° down so its bumper shows along the picture's bottom (#287).
const REVERSE_CAMERA := Vector3(0, 2.22, 2.84)
const REVERSE_TURN := Vector3(-PI / 4.0, PI, 0)
const REVERSE_FIELD := 85.0
## The tail lamps (#343, #344), drawn as a real van's by `tail_lamp.gdshader` with the lens's own
## texture and its masks (`tools/art/make_tail_lamp_mask.py`): a clear glossy cover over a red
## prism lens and a clear section with a chrome reflector; the red lens glowing a lamp's deep red
## (near 630 nm) through its prisms, the stop five times the tail, as UN Regulation 7 asks of a
## stop lamp over a rear position lamp (at least 5:1), and the red they throw on the road behind in
## the same ratio; the indicator amber and the reversing lamp white in the clear section. The two
## pieces the converter once cut from the top of the red lens by height (`RearIndicatorLeft`,
## `...Right`) wear the same lamp, so it is whole.
const TAIL_LAMP := preload("res://features/vehicles/freight_van/tail_lamp.gdshader")
const TAIL_MASKS := preload("res://features/vehicles/freight_van/art/iveco/tail_lamp_masks.png")
const TAIL_LENS := 0.35
const STOP_LENS := 1.75
const REAR_INDICATORS: Array[String] = ["RearIndicatorLeft", "RearIndicatorRight"]
const TAIL_GLOW := Vector2(0.2, 1.0)
const TAIL_GLOW_RANGE := 5.0
const INDICATORS: Array[String] = ["FrontIndicatorLeft", "FrontIndicatorRight"]
const TILT_RATE := 10.0
const SETTLE := 60.0
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
## The lamps' rain lands on the moon roof's glass (#330): a collider under it, its top face just
## over the glass and deep enough that no drop passes it in a tick, as the windshield's are.
const MOON_ROOF_SKIN := 0.003
const MOON_ROOF_STOP_DEPTH := 0.3
const MOON_ROOF_STOP_MARGIN := 0.02
const ROOF_TOP := 2.231
const ROOF_FRAME := Vector3(0.05, 2.18, 2.228)
const ROOF_SEAL := 0.02
const ROOF_SLOPE := Vector2(0.0, -0.05)
const ROOF_AIR := 0.8
const LOOK_UP := 1.05
const BEAM_RAIN = preload("beam_rain.gdshader")
const BEAM_MIST = preload("beam_mist.gdshader")
const HEADLAMP_LENS = preload("headlamp_lens.gdshader")
const RAIN_LAYERS: Array[float] = [3.0, 4.5, 6.5, 9.0, 12.5, 17.0, 23.0, 31.0]
const LAMP_FRONT := -2.31
const RAIN_SLANT := 0.08
const LOW_BEAM_RAIN := Vector2(5.0, 0.65)
const HIGH_BEAM_RAIN := Vector2(16.0, 0.9)
const WINDSHIELD_AIR := 0.85
const SIDE_AIR := 0.9
const SIDE_AIR_DIRECTION := Vector2(-0.989, 0.148)
const MIRROR_DISTANCE := 80.0
const MIRROR_LOD_THRESHOLD := 4.0
const LOW_BEAM = preload("art/low_beam_pattern.png")
const HIGH_BEAM = preload("art/high_beam_pattern.png")
const LOW_BEAM_RANGE := 70.0
const HIGH_BEAM_RANGE := 260.0
const LOW_BEAM_ENERGY := 650.0
const HIGH_BEAM_ENERGY := 1147.0
const LOW_BEAM_TILT := -1.25
const HIGH_BEAM_TILT := 0.0
const BEAM_MIST_DEPTH := 40.0
const BEAM_MIST_SCATTERING := 0.016
const WipeMap = preload("windshield_wipe_map.gd")
const Wiper = preload("wiper.gd")
const VanParticles = preload("van_particles.gd")
const WIPE_MAP_SIZE := Vector2i(512, 256)
const DOOR_SWING := 0.541
const REAR_SWING := PI * 1.5
const REAR_DOOR_SECONDS := 2.4
const HINGE_HEIGHTS: Array[float] = [0.52, 1.65]
## The rear doors' strap hinges, built in Blender by `tools/art/build_van_hinges.py` (#259).
const HINGES = preload("art/van_hinges.glb")
const SWING_SAMPLES := 9
const SINK_PER_KG := 0.00005
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
const NO_CRACK := Vector2(9.0, 9.0)
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
var rear_camera: Camera3D
var _rear_guides: CanvasLayer
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
var mirror_updates: Array[int] = [0, 0]
var _mirror_frames: Array[Node3D] = []
var _mirror_clock: Array[float] = [0.0, 0.0]
var _reverse_clock: float = 0.0
var _tail_glow: Array[SpotLight3D] = []
var _mirror_glasses: Array[MeshInstance3D] = []
var _passenger_turn := Transform3D.IDENTITY
var _look: Node3D
var _wheel: Node3D
var _wipers: Array[Node3D] = []
var particles := VanParticles.new()
var _blades: Array[Node3D] = []
var _last_wiper: float = 0.0
var _last_swing: float = 0.0
var _dump: float = 0.0
var _windows: Array[MeshInstance3D] = []
var _window_drop: Array[float] = []
var cabin_lamp: OmniLight3D
var _dome_lens := StandardMaterial3D.new()
var _paint := Color.WHITE
var _dome_level := 0.0
var _window_glass: Array[ShaderMaterial] = []
var _window_lowered: Array[float] = [0.0, 0.0]
var _headlights: Array[SpotLight3D] = []
var _front_lenses: Array[MeshInstance3D] = []
var _reverse_lights: Array[SpotLight3D] = []
var _indicators: Array[MeshInstance3D] = []
var _tires: Array[Node3D] = []
var _glass: ShaderMaterial
var _high_beams_shown: bool = false
var _rain_layers: Array[MeshInstance3D] = []
var _beam_rain_material: ShaderMaterial
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
var _rear_doors: Array[Node3D] = []
var _bolt_seal: Node3D
var _rear_open: float = 0.0
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
var _lamp: ShaderMaterial
var _lens_on := ShaderMaterial.new()


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
	particles.name = "VanParticles"
	add_child(particles)
	particles.setup(van, _wipers[0], WipeMap.ARMS[0] + WipeMap.BLADES[0] * 0.5, _body, _windshield)
	particles.wipe_with(_wipers[1], WipeMap.ARMS[1], _wipers[0].blade, WipeMap.BLADES[0])
	_mirrors()


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


## The van's paint (Mission 2's dark van, step 4, #312): `colour` multiplied into its painted
## panels' materials, white as delivered.
func set_paint(colour: Color) -> void:
	_paint = colour
	paint_model(_body.get_node("Iveco") as Node3D, colour)


func paint() -> Color:
	return _paint


## The exterior model as drawn, where a parked copy of the van stands.
func exterior() -> Node3D:
	return _body.get_node("Iveco") as Node3D


## `colour` multiplied into the painted panels of an Iveco exterior `model` (`iveco_exterior.glb`).
static func paint_model(model: Node3D, colour: Color) -> void:
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		for index in range(mesh.mesh.get_surface_count()):
			var made := mesh.mesh.surface_get_material(index) as BaseMaterial3D
			if made == null or not PAINTED.has(made.resource_name):
				continue
			var paint := made.duplicate() as BaseMaterial3D
			paint.albedo_color = made.albedo_color * colour
			mesh.set_surface_override_material(index, paint)


func _exterior() -> void:
	var outside := EXTERIOR_ART.instantiate() as Node3D
	outside.name = "Iveco"
	outside.position = IVECO_PLACE
	_body.add_child(outside)
	_door = outside.get_node("DriverDoor") as Node3D
	_rear_doors.assign([outside.get_node("RearDoorLeft"), outside.get_node("RearDoorRight")])
	_hasp()
	_rear_hinges(outside)
	_turn_passenger_mirror(outside)
	var headlights := outside.get_node("Headlights") as MeshInstance3D
	var tail_lamps := outside.get_node("TailLamps") as MeshInstance3D
	_front_lenses.append(headlights)
	_lamp = _tail_lamp(tail_lamps)
	tail_lamps.material_override = _lamp
	for label in REAR_INDICATORS:
		var piece := outside.get_node(label) as MeshInstance3D
		piece.material_override = _lamp
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for label in INDICATORS:
		_indicators.append(outside.get_node(label) as MeshInstance3D)
	for lens: MeshInstance3D in _indicators + [headlights, tail_lamps,
			outside.get_node("BodyGlass")]:
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1, 1]:
		var headlight := SpotLight3D.new()
		headlight.position = Vector3(side * HEADLIGHT.x, HEADLIGHT.y, HEADLIGHT.z)
		headlight.light_color = Color("fff0db")
		headlight.spot_angle = 35.0
		headlight.spot_angle_attenuation = 0.2
		headlight.spot_attenuation = 1.0
		headlight.shadow_enabled = true
		_beam_mist(headlight)
		_aim_beam(headlight, false)
		headlight.light_cull_mask = 1
		_body.add_child(headlight)
		_headlights.append(headlight)
	_reversing_lamps()
	_tail_glow_lights()
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
	driving_camera.cull_mask = 7 | MIRROR_LAYER
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
	reverse_view = _camera_view(REVERSE_CAMERA, REVERSE_TURN, REVERSE_PIXELS, REVERSE_FIELD)
	reverse_view.get_camera_3d().cull_mask = 7
	reverse_view.add_child(_parking_guides())
	var low_light := CameraAttributesPractical.new()
	low_light.exposure_multiplier = REVERSE_GAIN
	mirror_cameras[mirror_cameras.size() - 1].attributes = low_light
	_rear_view(low_light)
	reverse_screen = _dash_screen(reverse_view, MAP_SCREEN, MAP_SIZE, MAP_TURN, false,
		2.0 * SCREEN_GAP)
	_lcd(reverse_screen)
	reverse_screen.visible = false
	_screen_glass()


## The reversing camera as the game's own view while the van is in reverse (#252): the same
## camera, high on the van's back looking back and down past the bumper, with the same lens and
## low-light gain, its parking guides drawn over the picture, as a driver watches it reversing.
func _rear_view(low_light: CameraAttributes) -> void:
	rear_camera = Camera3D.new()
	rear_camera.name = "RearCamera"
	rear_camera.position = REVERSE_CAMERA
	rear_camera.rotation = REVERSE_TURN
	rear_camera.fov = REVERSE_FIELD
	rear_camera.cull_mask = 7
	rear_camera.near = 0.1
	rear_camera.far = driving_camera.far
	rear_camera.attributes = low_light
	add_child(rear_camera)
	_rear_guides = CanvasLayer.new()
	_rear_guides.name = "RearCameraGuides"
	_rear_guides.layer = -1
	_rear_guides.add_child(_parking_guides())
	_rear_guides.visible = false
	add_child(_rear_guides)


func _parking_guides() -> Control:
	var guides := ParkingGuides.new()
	guides.van = vehicle
	return guides


## In reverse, with the driver at the wheel, the game's view is the rear camera; out of it, his
## own view again. Out of the van his own camera is someone else's to choose.
func _follow_gear() -> void:
	var reversing: bool = vehicle.gear < 0 and vehicle.occupied
	if reversing and driving_camera.current:
		rear_camera.make_current()
	elif not reversing and rear_camera.current and vehicle.occupied:
		driving_camera.make_current()
	_rear_guides.visible = rear_camera.current


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
	_mirror_frames.append(self)
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
	_glass.set_shader_parameter("crack_point", NO_CRACK)
	_glass.set_shader_parameter("crack_seed", 0.0)
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


## The tail lamps' lamp: the lens's own texture and its masks, drawn by `tail_lamp.gdshader`.
func _tail_lamp(lamps: MeshInstance3D) -> ShaderMaterial:
	var lamp := ShaderMaterial.new()
	lamp.shader = TAIL_LAMP
	lamp.set_shader_parameter("lens",
		(lamps.mesh.surface_get_material(0) as BaseMaterial3D).albedo_texture)
	lamp.set_shader_parameter("masks", TAIL_MASKS)
	return lamp


## The reversing lamps' light on the ground behind; they shine in the tail lamps' clear sections.
func _reversing_lamps() -> void:
	for side in [-1, 1]:
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(side * REVERSE_LAMP.x, REVERSE_LAMP.y, REVERSE_LAMP.z)
		lamp.rotation_degrees = Vector3(-12.0, 180.0, 0.0)
		lamp.light_color = Color("fff4e6")
		lamp.light_energy = REVERSE_ENERGY
		lamp.spot_range = REVERSE_RANGE
		lamp.spot_angle = 55.0
		lamp.light_cull_mask = 1
		lamp.visible = false
		_body.add_child(lamp)
		_reverse_lights.append(lamp)


func _tail_glow_lights() -> void:
	for side in [-1, 1]:
		var glow := SpotLight3D.new()
		glow.name = "TailGlowLeft" if side < 0 else "TailGlowRight"
		glow.position = Vector3(side * REVERSE_LAMP.x, REVERSE_LAMP.y, REVERSE_LAMP.z + 0.02)
		glow.rotation_degrees = Vector3(-20.0, 180.0, 0.0)
		glow.light_color = Color(1.0, 0.07, 0.03)
		glow.spot_range = TAIL_GLOW_RANGE
		glow.spot_angle = 85.0
		glow.spot_angle_attenuation = 3.0
		glow.light_cull_mask = 1
		glow.visible = false
		_body.add_child(glow)
		_tail_glow.append(glow)


func _turn_passenger_mirror(outside: Node3D) -> void:
	var door := outside.get_node("PassengerDoor") as MeshInstance3D
	var frame := outside.transform * door.transform
	var arrays := door.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var corners: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	var head := PackedInt32Array()
	var pivot := Vector3.ZERO
	var rooted := 0
	for first in range(0, corners.size(), 3):
		var centre := frame * ((vertices[corners[first]] + vertices[corners[first + 1]]
			+ vertices[corners[first + 2]]) / 3.0)
		var turned := MIRROR_HEAD.has_point(centre)
		(head if turned else kept).append_array([corners[first], corners[first + 1],
			corners[first + 2]])
		if turned and centre.x < MIRROR_HEAD.position.x + MIRROR_ARM:
			pivot += centre
			rooted += 1
	pivot /= maxi(rooted, 1)
	var split := ArrayMesh.new()
	var body := arrays.duplicate()
	body[Mesh.ARRAY_INDEX] = kept
	split.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, body)
	split.surface_set_material(0, door.get_active_material(0))
	for surface in range(1, door.mesh.get_surface_count()):
		split.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, door.mesh.surface_get_arrays(surface))
		split.surface_set_material(surface, door.get_active_material(surface))
	var held := ArrayMesh.new()
	var housing := arrays.duplicate()
	housing[Mesh.ARRAY_INDEX] = head
	held.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, housing)
	held.surface_set_material(0, door.get_active_material(0))
	door.mesh = split
	_passenger_turn = Transform3D.IDENTITY.translated(pivot) * Transform3D(Basis(Vector3.UP,
		deg_to_rad(-MIRROR_TURN)), Vector3.ZERO) * Transform3D.IDENTITY.translated(-pivot)
	var swivelled := MeshInstance3D.new()
	swivelled.name = "PassengerMirrorHead"
	swivelled.mesh = held
	outside.add_child(swivelled)
	swivelled.transform = outside.transform.affine_inverse() * _passenger_turn * frame


func _mirrors() -> void:
	var outside := _body.get_node("Iveco") as Node3D
	var passenger := Node3D.new()
	passenger.name = "PassengerMirror"
	passenger.transform = _passenger_turn * Transform3D(Basis(),
		outside.position + (outside.get_node("PassengerDoor") as Node3D).position)
	_cabin.add_child(passenger)
	var holders: Array[Node3D] = [_door_glass, passenger]
	for index in range(holders.size()):
		_mirror(index, holders[index])


func _mirror(index: int, holder: Node3D) -> void:
	var side := -1.0 if index == 0 else 1.0
	var pieces: Array[Dictionary] = []
	for surface in range(MIRROR_GLASS[index].get_surface_count()):
		pieces.append(_glass_piece(MIRROR_GLASS[index], surface, holder))
	var regions: Array[Rect2] = []
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for piece in range(pieces.size()):
		var wide := piece == 1
		var field := _field(pieces[piece], wide)
		var down := deg_to_rad(WIDE_DOWN) if wide else field.y / 6.0
		var region := Rect2(-deg_to_rad(INNER_EDGE.y if wide else INNER_EDGE.x),
			down - field.y / 2.0, field.x, field.y)
		regions.append(region)
		low = low.min(region.position)
		high = high.max(region.end)
	var aim := (low + high) / 2.0
	var half := Vector2.ZERO
	for region in regions:
		for corner: Vector2 in [region.position, region.end]:
			half = half.max(Vector2(tan(corner.x - aim.x), tan(corner.y - aim.y)).abs())
	var view := SubViewport.new()
	view.name = "DriverMirror" if index == 0 else "PassengerMirrorView"
	view.size = Vector2i(roundi(MIRROR_PIXELS * half.x / half.y), MIRROR_PIXELS) \
		if half.x < half.y else Vector2i(MIRROR_PIXELS, roundi(MIRROR_PIXELS * half.y / half.x))
	view.use_hdr_2d = true
	view.positional_shadow_atlas_size = 0
	view.mesh_lod_threshold = REFLECTION_LOD_THRESHOLD
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var camera := Camera3D.new()
	camera.cull_mask = 3
	camera.near = 0.05
	camera.far = MIRROR_FAR
	camera.fov = rad_to_deg(2.0 * atan(half.y))
	camera.environment = _reflected_light(index == 0)
	view.add_child(camera)
	camera.make_current()
	var look := Vector3(side * sin(aim.x) * cos(aim.y), -sin(aim.y), cos(aim.x) * cos(aim.y))
	mirrors.append(view)
	mirror_cameras.append(camera)
	var turn := holder.transform.basis.inverse()
	mirror_poses.append(Transform3D(Basis.looking_at(turn * look, turn * Vector3.UP),
		pieces[0].centre))
	_mirror_frames.append(holder)
	for piece in range(pieces.size()):
		var surface := ShaderMaterial.new()
		surface.shader = MIRROR_SHADER
		surface.set_shader_parameter("reflection", view.get_texture())
		surface.set_shader_parameter("gain", MIRROR_HEADROOM * MIRROR_REFLECTANCE)
		var glass := MeshInstance3D.new()
		glass.name = "MainGlass" if piece == 0 else "WideGlass"
		glass.mesh = _reflection(pieces[piece], regions[piece], aim, half, side)
		glass.material_override = surface
		glass.layers = MIRROR_LAYER
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(glass)
		_mirror_glasses.append(glass)


func _glass_piece(glass: Mesh, surface: int, holder: Node3D) -> Dictionary:
	var points: PackedVector3Array = glass.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
	var normal := Vector3.ZERO
	var centre := Vector3.ZERO
	var area := 0.0
	for first in range(0, points.size(), 3):
		var face := -(points[first + 1] - points[first]).cross(points[first + 2] - points[first])
		normal += face
		centre += (points[first] + points[first + 1] + points[first + 2]) / 3.0 * face.length()
		area += face.length()
	normal = normal.normalized()
	centre /= area
	var up := (Vector3.UP - normal * normal.dot(Vector3.UP)).normalized()
	var right := up.cross(normal)
	var box := Rect2((points[0] - centre).dot(right), (points[0] - centre).dot(up), 0.0, 0.0)
	for point in points:
		box = box.expand(Vector2((point - centre).dot(right), (point - centre).dot(up)))
	return {"points": points, "normal": normal, "right": right, "up": up,
		"centre": centre + right * box.get_center().x + up * box.get_center().y,
		"size": box.size, "place": holder.transform}


func _field(piece: Dictionary, wide: bool) -> Vector2:
	var place: Transform3D = piece.place
	var to_eye: Vector3 = EYE - place * (piece.centre as Vector3)
	var normal: Vector3 = (place.basis * (piece.normal as Vector3)).normalized()
	var up: Vector3 = (place.basis * (piece.up as Vector3)).normalized()
	var size: Vector2 = piece.size
	var seen := Vector2(size.x * absf(to_eye.normalized().dot(normal)),
		size.y * sqrt(1.0 - pow(to_eye.normalized().dot(up), 2.0))) / to_eye.length()
	return seen + 2.0 * size / (GLASS_RADII.y if wide else GLASS_RADII.x)


func _reflection(piece: Dictionary, region: Rect2, aim: Vector2, half: Vector2,
		side: float) -> ArrayMesh:
	var centre: Vector3 = piece.centre
	var right: Vector3 = piece.right
	var up: Vector3 = piece.up
	var normal: Vector3 = piece.normal
	var size: Vector2 = piece.size
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in piece.points:
		var across := (point - centre).dot(right) / size.x + 0.5
		var rise := (point - centre).dot(up) / size.y + 0.5
		var x := lerpf(tan(region.position.x - aim.x), tan(region.end.x - aim.x),
			across if side > 0.0 else 1.0 - across)
		var y := lerpf(tan(region.end.y - aim.y), tan(region.position.y - aim.y), rise)
		tool.set_normal(normal)
		tool.set_uv(Vector2(0.5 - side * x / (2.0 * half.x), 0.5 + y / (2.0 * half.y)))
		tool.add_vertex(point + normal * MIRROR_LIFT)
	return tool.commit()


func _reflected_light(driver: bool) -> Environment:
	var world: Environment = get_world_3d().environment if get_world_3d() != null else null
	var light := world.duplicate() as Environment if world != null else Environment.new()
	light.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	light.tonemap_exposure = 1.0 / MIRROR_HEADROOM
	light.ambient_light_energy += MIRROR_FILL
	light.ssr_enabled = driver and light.ssr_enabled
	return light


func _aim_beam(headlight: SpotLight3D, high: bool) -> void:
	headlight.light_projector = HIGH_BEAM if high else LOW_BEAM
	headlight.spot_range = HIGH_BEAM_RANGE if high else LOW_BEAM_RANGE
	headlight.light_energy = HIGH_BEAM_ENERGY if high else LOW_BEAM_ENERGY
	headlight.rotation_degrees.x = HIGH_BEAM_TILT if high else LOW_BEAM_TILT
	var air := (headlight.get_node("Mist") as MeshInstance3D).material_override as ShaderMaterial
	var colour := headlight.light_color.srgb_to_linear() * headlight.light_energy
	air.set_shader_parameter("light_colour", Vector3(colour.r, colour.g, colour.b))
	air.set_shader_parameter("pattern", headlight.light_projector)
	air.set_shader_parameter("light_range", headlight.spot_range)


static func lit_lens(lens: MeshInstance3D) -> ShaderMaterial:
	var glass := lens.mesh.surface_get_material(0) as BaseMaterial3D
	var lit := ShaderMaterial.new()
	lit.shader = HEADLAMP_LENS
	if glass != null:
		lit.set_shader_parameter("glass_texture", glass.albedo_texture)
		lit.set_shader_parameter("glass_colour", glass.albedo_color)
		lit.set_shader_parameter("glass_metallic", glass.metallic)
		lit.set_shader_parameter("glass_roughness", glass.roughness)
	lens.material_override = lit
	return lit


static func light_lens(lit: ShaderMaterial, low: bool, high: bool) -> void:
	lit.set_shader_parameter("low_lit", 1.0 if low else 0.0)
	lit.set_shader_parameter("high_lit", 1.0 if high else 0.0)


func _light_lens(lens: MeshInstance3D, low: bool, high: bool) -> void:
	if lens.material_override != _lens_on:
		_lens_on = lit_lens(lens)
	light_lens(_lens_on, low, high)


func _beam_mist(headlight: SpotLight3D) -> void:
	var radius := BEAM_MIST_DEPTH * tan(deg_to_rad(headlight.spot_angle))
	var air := ShaderMaterial.new()
	air.shader = BEAM_MIST
	air.set_shader_parameter("half_size", Vector3(radius, radius, BEAM_MIST_DEPTH * 0.5))
	air.set_shader_parameter("tan_half", tan(deg_to_rad(headlight.spot_angle)))
	air.set_shader_parameter("light_decay", headlight.spot_attenuation)
	air.set_shader_parameter("scattering", BEAM_MIST_SCATTERING)
	air.set_shader_parameter("fade_begin", 1.0e6)
	var box := BoxMesh.new()
	box.size = Vector3(radius * 2.0, radius * 2.0, BEAM_MIST_DEPTH)
	var mist := MeshInstance3D.new()
	mist.name = "Mist"
	mist.mesh = box
	mist.material_override = air
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mist.position = Vector3(0.0, 0.0, -BEAM_MIST_DEPTH * 0.5)
	headlight.add_child(mist)


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
	var stop := GPUParticlesCollisionBox3D.new()
	stop.name = "MoonRoofCollider"
	stop.size = Vector3(MOON_ROOF.size.x + MOON_ROOF_STOP_MARGIN, MOON_ROOF_STOP_DEPTH,
		MOON_ROOF.size.y + MOON_ROOF_STOP_MARGIN)
	stop.position = Vector3(centre.x, MOON_ROOF_HEIGHT + MOON_ROOF_SKIN
		- MOON_ROOF_STOP_DEPTH * 0.5, centre.y)
	stop.cull_mask = 0xFFFFFFFF ^ VanParticles.PASSENGER_LAYER
	_cabin.add_child(stop)
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
	var sink := float(vehicle.load_kg) * SINK_PER_KG
	var share := _rear_share()
	var front := (ground[0] + ground[1]) * 0.5 - sink * (1.0 - share)
	var rear: float = (ground[2] + ground[3]) * 0.5 - sink * share
	var target := Vector3(atan2(front - rear, WHEEL_SPOTS[2].z - WHEEL_SPOTS[0].z),
		(front + rear) * 0.5 - _ground_rest,
		atan2((ground[1] + ground[3]) * 0.5 - (ground[0] + ground[2]) * 0.5,
		WHEEL_SPOTS[1].x - WHEEL_SPOTS[0].x))
	_tilt = _tilt.lerp(target, 1.0 - exp(-delta * TILT_RATE))
	transform = Transform3D(Basis.from_euler(Vector3(_tilt.x + _rock, 0.0, _tilt.z)),
		Vector3(0.0, _tilt.y, 0.0))
	var hold := vehicle.get_node_or_null("Hold") as Node3D
	if hold != null:
		hold.transform = transform


## How much of the load's weight the rear axle carries, by where the load stands between the
## axles (step 2e): all of it over the rear axle, none over the front.
func _rear_share() -> float:
	return (float(vehicle.load_z) - WHEEL_SPOTS[0].z) / (WHEEL_SPOTS[2].z - WHEEL_SPOTS[0].z)


func settle() -> void:
	_follow_ground(SETTLE)
	update_vehicle(0.0)


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


## A steel hasp across the rear doors where they meet, just under the handle, each half on its
## own door, and the shipper's bolt seal through it once the van is sealed (step 2e-3): a yellow
## coated steel bolt and its barrel cap, as ISO 17712 high-security seals are made.
func _hasp() -> void:
	var steel := Build.material(Color(0.42, 0.43, 0.45), 0.4)
	steel.metallic = 0.8
	var point: Vector3 = vehicle.call("seal_point")
	var across := vehicle.global_basis.x.normalized()
	var back := vehicle.global_basis.z.normalized()
	for index in range(2):
		var door := _rear_doors[index]
		var side := -1.0 if index == 0 else 1.0
		var at := door.to_local(point + across * side * 0.03 - back * 0.012)
		Build.box(door, at, Vector3(0.05, 0.07, 0.008), steel).name = "Hasp"
	_bolt_seal = Node3D.new()
	_bolt_seal.name = "BoltSeal"
	_rear_doors[1].add_child(_bolt_seal)
	_bolt_seal.position = _rear_doors[1].to_local(point)
	var yellow := Build.material(Color(0.95, 0.78, 0.05), 0.45)
	var bolt := Build.cylinder(_bolt_seal, Vector3.ZERO, 0.004, 0.085, yellow)
	bolt.rotation.z = PI / 2.0
	var cap := Build.cylinder(_bolt_seal, Vector3(0.05, 0.0, 0.0), 0.0095, 0.03, yellow)
	cap.rotation.z = PI / 2.0
	Build.box(_bolt_seal, Vector3(-0.045, -0.018, 0.0), Vector3(0.008, 0.035, 0.026), yellow)
	_bolt_seal.visible = false


## The rear doors' hinges, two a door above and below its tail lamp, as a Daily's 270-degree
## doors hang (#252): each door turns about a pin out beyond its own edge, so that it can fold
## flat against the side, and a compact arm on the door runs from its edge round to the pin,
## where a bracket on the body's rear corner holds the pin's barrel; each in the finish of the
## door where it sits, the white paint above, the black trim below (#261, `build_van_hinges.py`).
func _rear_hinges(art: Node3D) -> void:
	var made := HINGES.instantiate() as Node3D
	for index in range(_rear_doors.size()):
		var door := _rear_doors[index]
		var side := "L" if index == 0 else "R"
		for hinge in range(HINGE_HEIGHTS.size()):
			var height := HINGE_HEIGHTS[hinge]
			var level := "Upper" if hinge > 0 else ""
			var bracket_mesh := (made.get_node("HingeBracket%s%s" % [level, side])
				as MeshInstance3D).mesh
			var arm := MeshInstance3D.new()
			arm.mesh = (made.get_node("HingeArm%s%s" % [level, side]) as MeshInstance3D).mesh
			arm.name = "HingeArm%d" % hinge
			arm.position = Vector3(0.0, height - door.position.y, 0.0)
			door.add_child(arm)
			var bracket := MeshInstance3D.new()
			bracket.mesh = bracket_mesh
			bracket.name = "HingeBracket%d_%d" % [index, hinge]
			bracket.position = Vector3(door.position.x, height, door.position.z)
			art.add_child(bracket)
	made.free()


## Whether both rear doors have room to swing their 270 degrees round to the van's sides,
## sampled every 30 degrees along each one's arc: nothing of the world's in the way, such as a
## wall, a post or the dock, the van's own bodies left out.
func rear_swing_clear() -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	query.shape = box
	query.collision_mask = 1
	var own: Array[RID] = [vehicle.get_rid()]
	for body in vehicle.find_children("*", "CollisionObject3D", true, false):
		own.append((body as CollisionObject3D).get_rid())
	query.exclude = own
	for index in range(_rear_doors.size()):
		var door := _rear_doors[index]
		var extent := _door_extent(door)
		box.size = (extent.size - Vector3(0.04, 0.04, 0.0)).max(Vector3.ONE * 0.01)
		var way := 1.0 if index == 1 else -1.0
		for step in range(1, SWING_SAMPLES + 1):
			var angle := way * REAR_SWING * step / SWING_SAMPLES
			query.transform = door.get_parent().global_transform * Transform3D(
				Basis(Vector3.UP, angle), door.position) * Transform3D(Basis.IDENTITY,
				extent.get_center())
			if not space.intersect_shape(query, 1).is_empty():
				return false
	return true


## Rear door `index` (0 left, 1 right), hinged at its origin, for Ethan's hands on it.
func rear_door(index: int) -> Node3D:
	return _rear_doors[index]


## Rear door `index`'s extent in its own frame.
func rear_door_extent(index: int) -> AABB:
	return _door_extent(_rear_doors[index])


func _door_extent(door: Node3D) -> AABB:
	var into := door.global_transform.affine_inverse()
	var extent := AABB()
	var first := true
	var meshes := door.find_children("*", "MeshInstance3D", true, false)
	if door is MeshInstance3D:
		meshes.append(door)
	for found in meshes:
		var mesh := found as MeshInstance3D
		if mesh.name.begins_with("Hinge"):
			continue
		var part: AABB = into * mesh.global_transform * mesh.get_aabb()
		extent = part if first else extent.merge(part)
		first = false
	return extent


## The rear doors swing round to lie against the sides, the right one first, then the left,
## as a driver opens a Daily's: each about 270 degrees on its long hinges.
func _swing_rear_doors(delta: float) -> void:
	_bolt_seal.visible = bool(vehicle.get("sealed"))
	var by_hand: Array[float] = vehicle.call("rear_door_angles")
	if not by_hand.is_empty():
		_rear_doors[0].rotation.y = -by_hand[0]
		_rear_doors[1].rotation.y = by_hand[1]
		_rear_open = 1.0 if by_hand[0] >= REAR_SWING - 0.01 and by_hand[1] >= REAR_SWING - 0.01 \
			else 0.0
		return
	_rear_open = move_toward(_rear_open, 1.0 if vehicle.rear_doors_open else 0.0,
		delta / REAR_DOOR_SECONDS)
	_rear_doors[1].rotation.y = REAR_SWING * smoothstep(0.0, 1.0, clampf(_rear_open * 2.0, 0.0,
		1.0))
	_rear_doors[0].rotation.y = -REAR_SWING * smoothstep(0.0, 1.0, clampf(_rear_open * 2.0 - 1.0,
		0.0, 1.0))


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
	_swing_rear_doors(delta)
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
		_light_lens(lens, vehicle.headlights_on, vehicle.headlights_on and vehicle.high_beams)
	var reversing: bool = vehicle.gear < 0 and vehicle.engine_on
	_lamp.set_shader_parameter("reverse", 1.0 if reversing else 0.0)
	for lamp in _reverse_lights:
		lamp.visible = reversing
	_lamp.set_shader_parameter("red", (STOP_LENS if vehicle.braking else TAIL_LENS)
		if vehicle.engine_on else 0.0)
	for glow in _tail_glow:
		glow.visible = vehicle.engine_on
		glow.light_energy = TAIL_GLOW.y if vehicle.braking else TAIL_GLOW.x
	for index in range(_indicators.size()):
		var side := -1 if index == 0 else 1
		var lit: bool = vehicle.indicator_lit and (
			vehicle.hazards_on or vehicle.indicator == side)
		_indicators[index].material_override = _amber if lit else null
		_lamp.set_shader_parameter("amber_left" if side < 0 else "amber_right", 1.0 if lit else 0.0)
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
	_follow_gear()
	for index in range(mirror_cameras.size()):
		mirror_cameras[index].global_transform = _mirror_frames[index].global_transform \
			* mirror_poses[index]
	for glass in _mirror_glasses:
		glass.visible = vehicle.occupied
	if not vehicle.occupied:
		return
	for index in range(mirrors.size()):
		_mirror_clock[index] += delta
		if _mirror_clock[index] >= 1.0 / MIRROR_RATES[index] - 0.0001:
			_mirror_clock[index] = maxf(_mirror_clock[index] - 1.0 / MIRROR_RATES[index], 0.0)
			mirrors[index].render_target_update_mode = SubViewport.UPDATE_ONCE
			mirror_updates[index] += 1
	if vehicle.gear >= 0 or rear_camera.current:
		_reverse_clock = 0.0
		return
	_reverse_clock += delta
	if _reverse_clock >= 1.0 / REVERSE_RATE - 0.0001:
		_reverse_clock = maxf(_reverse_clock - 1.0 / REVERSE_RATE, 0.0)
		reverse_view.render_target_update_mode = SubViewport.UPDATE_ONCE
