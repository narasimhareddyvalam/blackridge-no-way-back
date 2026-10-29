extends Node3D

const Build = preload("res://shared/components/mesh_builder.gd")
const Instruments = preload("instruments.gd")
const Navigation = preload("navigation_display.gd")
const NightDimming = preload("night_dimming.gd")
const GLASS = preload("windshield.gdshader")
const BODY_ART = preload("art/body.glb")
const CABIN_ART = preload("art/cabin.glb")
const STEERING_ART = preload("art/steering.glb")
const TIRE_ART = preload("art/tire.glb")

var driving_camera: Camera3D
var navigation: Control
var night_dimming: Node
var mirrors: Array[SubViewport] = []
var reverse_view: SubViewport
var reverse_screen: MeshInstance3D
var vehicle: CharacterBody3D
var mirror_cameras: Array[Camera3D] = []
var mirror_poses: Array[Transform3D] = []
var _look: Node3D
var _wheel: Node3D
var _wipers: Array[Node3D] = []
var _windows: Array[MeshInstance3D] = []
var _headlights: Array[SpotLight3D] = []
var _front_lenses: Array[MeshInstance3D] = []
var _rear_lamps: Array[MeshInstance3D] = []
var _indicators: Array[MeshInstance3D] = []
var _tires: Array[Node3D] = []
var _rolling_meshes: Array[Node3D] = []
var _glass: ShaderMaterial
var _mirror_timer: float = 0.0
var _water: float = 0.2
var _look_target := Vector2.ZERO
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
	add_child(_body)
	add_child(_cabin)
	_exterior()
	_interior()
	_camera()
	_displays()
	_windows_and_wipers()
	_mark_layer(_body, 2)
	_mark_layer(_cabin, 4)


func _exterior() -> void:
	_body.add_child(BODY_ART.instantiate())
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
		headlight.rotation_degrees.x = -7.0
		headlight.light_color = Color("fff0db")
		headlight.light_energy = 5.0
		headlight.spot_range = 62.0
		headlight.spot_angle = 36.0
		headlight.spot_attenuation = 1.3
		headlight.shadow_enabled = side < 0
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
	_cabin.add_child(CABIN_ART.instantiate())
	_wheel = Node3D.new()
	_cabin.add_child(_wheel)
	_wheel.position = Vector3(-0.53, 1.68, -0.87)
	_wheel.add_child(STEERING_ART.instantiate())
	Build.box(_cabin, Vector3(-0.79, 1.71, -0.95),
		Vector3(0.17, 0.02, 0.025), _trim)
	var light := OmniLight3D.new()
	light.position = Vector3(-0.25, 2.30, -0.55)
	light.light_color = Color("b7c2c9")
	light.light_energy = 0.45
	light.omni_range = 2.5
	light.light_cull_mask = 4
	_cabin.add_child(light)


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
	var instruments := _display_viewport(Vector2i(640, 256), cluster)
	night_dimming = NightDimming.new()
	night_dimming.name = "NightDimming"
	add_child(night_dimming)
	night_dimming.configure(vehicle, cluster)
	_screen(instruments, Vector3(-0.53, 1.74, -0.935), Vector2(0.65, 0.26))
	navigation = Navigation.new()
	navigation.vehicle = vehicle
	var gps := _display_viewport(Vector2i(384, 256), navigation)
	_screen(gps, Vector3(0.30, 1.64, -0.874), Vector2(0.43, 0.287))
	for side in [-1, 1]:
		var view := _camera_view(Vector3(side * 1.35, 2.14, -1.2),
			Vector3(0, PI + side * 0.13, 0), Vector2i(256, 320), 62.0)
		mirrors.append(view)
		_screen(view, Vector3(side * 1.3, 2.11, -1.22), Vector2(0.26, 0.35), true)
		Build.box(_cabin, Vector3(side * 1.18, 1.94, -1.22),
			Vector3(0.3, 0.04, 0.04), _trim)
	var inside := _camera_view(Vector3(0, 2.4, -1.2), Vector3(0, PI, 0),
		Vector2i(384, 128), 65.0)
	mirrors.append(inside)
	_screen(inside, Vector3(0, 2.48, -1.25), Vector2(0.38, 0.125), true)
	reverse_view = _camera_view(Vector3(0, 2.35, 3.02), Vector3(-0.28, PI, 0),
		Vector2i(384, 256), 85.0)
	reverse_screen = _screen(reverse_view, Vector3(0.30, 1.64, -0.866),
		Vector2(0.43, 0.287))
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
	add_child(viewport)
	var camera := Camera3D.new()
	camera.position = at
	camera.rotation = angles
	camera.cull_mask = 3
	camera.fov = field
	camera.near = 0.1
	camera.far = 160.0
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
	var windshield := QuadMesh.new()
	windshield.size = Vector2(2.12, 1.08)
	var pane := Build.instance(_cabin, Vector3(0, 2.17, -1.34), windshield, _glass)
	pane.rotation.x = 0.32
	for x in [-0.52, 0.48]:
		var hinge := Node3D.new()
		_cabin.add_child(hinge)
		hinge.position = Vector3(x, 1.66, -1.50)
		hinge.rotation.x = 0.32
		Build.box(hinge, Vector3(0, 0.29, 0), Vector3(0.012, 0.58, 0.015), _steel)
		Build.box(hinge, Vector3(0, 0.59, 0.008), Vector3(0.021, 0.42, 0.018), _rubber)
		_wipers.append(hinge)


func _mark_layer(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = layer
	for child in node.get_children():
		_mark_layer(child, layer)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(vehicle) or not vehicle.occupied or not vehicle.input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_target.x = clampf(_look_target.x - event.relative.y * 0.002, -0.55, 0.5)
		_look_target.y = clampf(_look_target.y - event.relative.x * 0.002, -1.3, 1.3)
	if event.is_action_pressed("center_view"):
		_look_target = Vector2.ZERO


func update_vehicle(delta: float) -> void:
	_wheel.rotation.z = -vehicle.steering * 2.2
	_look.rotation.x = lerp_angle(_look.rotation.x, _look_target.x, 1.0 - exp(-delta * 14))
	_look.rotation.y = lerp_angle(_look.rotation.y, _look_target.y, 1.0 - exp(-delta * 14))
	_look.rotation.z = lerp_angle(_look.rotation.z,
		-vehicle.steering * vehicle.speed * 0.0015, 1.0 - exp(-delta * 5))
	for index in range(_windows.size()):
		var openness: float = vehicle.left_window if index == 0 else vehicle.right_window
		_windows[index].position.y = 2.12 - openness * 0.88
	for headlight in _headlights:
		headlight.visible = vehicle.headlights_on
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
	_water = move_toward(_water, 0.18 if vehicle.wiper_setting > 0 else 1.0, delta * 0.12)
	_glass.set_shader_parameter("wetness", _water)
	_glass.set_shader_parameter("wipers_on", vehicle.wiper_setting > 0)
	_glass.set_shader_parameter("sweep_angle", vehicle.wiper_angle)
	reverse_screen.visible = vehicle.gear < 0
	for index in range(mirror_cameras.size()):
		mirror_cameras[index].global_transform = vehicle.global_transform * mirror_poses[index]
	_mirror_timer += delta
	if _mirror_timer >= 1.0 / 15.0 and vehicle.occupied:
		_mirror_timer = 0.0
		for viewport in mirrors:
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		if vehicle.gear < 0:
			reverse_view.render_target_update_mode = SubViewport.UPDATE_ONCE
