extends AnimatableBody3D
## A scripted black SUV (Mission 3, #359): "Chevrolet Suburban 2015 - Unmarked" by David_Holiday
## (CC BY 4.0), its 2015 dimensions (5.70 m long, 2.04 m wide, 1.89 m high), painted black. It
## drives the points it is given at a set speed, turning to its way as it goes, solid to the van
## (the body moves it, so the van is pushed or stopped as by a real car); its headlights (low
## beams, as the van's) and tail lamps light when `set_lights` says, their lenses glowing where a
## 2015 Suburban's are (measured from the model: the low beams' round projectors beside the
## grille, turned back with the nose; the tail lamps upright on the rear corners). The node faces its -Z, as Godot's
## vehicles do.

const MODEL = preload("res://features/environments/harbour_flats/art/suburban/suburban.glb")
const SIZE := Vector3(2.04, 1.89, 5.7)
const HEADLIGHT_AT := Vector3(0.72, 0.86, -2.78)
const TAIL_AT := Vector3(0.78, 1.0, 2.84)
const HEADLIGHT_ENERGY := 6.0
const HEADLIGHT_REACH := 45.0
const TURN_RATE := 1.6
## The lenses: each one's middle (x mirrored), size, and turn about y (mirrored).
const HEAD_LENS := Vector3(0.77, 1.07, -2.555)
const HEAD_LENS_SIZE := Vector3(0.085, 0.085, 0.02)
const HEAD_LENS_TURN := -35.0
const TAIL_LENS := Vector3(0.86, 1.12, 2.705)
const TAIL_LENS_SIZE := Vector3(0.13, 0.5, 0.03)
const TAIL_RED := Color(1.0, 0.04, 0.02)
const HEAD_WHITE := Color(1.0, 0.95, 0.86)

var model_path := MODEL.resource_path
var lights_on := false
var speed := 0.0
var route: Array[Vector3] = []
var _leg := 0
var _headlights: Array[SpotLight3D] = []
var _tails: Array[OmniLight3D] = []
var _tail_glass: StandardMaterial3D
var _head_glass: StandardMaterial3D


func _ready() -> void:
	sync_to_physics = false
	var model := MODEL.instantiate() as Node3D
	model.name = "Model"
	add_child(model)
	var shape := BoxShape3D.new()
	shape.size = SIZE
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, SIZE.y / 2.0, 0.0)
	add_child(collision)
	for side in [-1.0, 1.0]:
		var beam := SpotLight3D.new()
		beam.light_color = Color(1.0, 0.95, 0.86)
		beam.spot_range = HEADLIGHT_REACH
		beam.spot_angle = 32.0
		beam.spot_attenuation = 1.2
		add_child(beam)
		beam.position = Vector3(HEADLIGHT_AT.x * side, HEADLIGHT_AT.y, HEADLIGHT_AT.z)
		beam.rotation.x = deg_to_rad(-4.0)
		_headlights.append(beam)
		var tail := OmniLight3D.new()
		tail.light_color = Color(1.0, 0.06, 0.04)
		tail.omni_range = 2.5
		add_child(tail)
		tail.position = Vector3(TAIL_AT.x * side, TAIL_AT.y, TAIL_AT.z)
		_tails.append(tail)
	_tail_glass = _glass(Color(0.28, 0.02, 0.02))
	_head_glass = _glass(Color(0.55, 0.56, 0.58))
	for side in [-1.0, 1.0]:
		_lens("TailLens", Vector3(TAIL_LENS.x * side, TAIL_LENS.y, TAIL_LENS.z), TAIL_LENS_SIZE,
			0.0, _tail_glass, false)
		_lens("HeadLens", Vector3(HEAD_LENS.x * side, HEAD_LENS.y, HEAD_LENS.z), HEAD_LENS_SIZE,
			HEAD_LENS_TURN * side, _head_glass, true)
	set_lights(false)


func _glass(colour: Color) -> StandardMaterial3D:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = colour
	glass.roughness = 0.15
	return glass


## A lens: a flat box, or a round disc facing along z (a projector's).
func _lens(named: String, at: Vector3, size: Vector3, turn: float, glass: Material,
		round: bool) -> void:
	var lens := MeshInstance3D.new()
	lens.name = named
	if round:
		var disc := CylinderMesh.new()
		disc.top_radius = size.x / 2.0
		disc.bottom_radius = size.x / 2.0
		disc.height = size.z
		disc.radial_segments = 20
		lens.mesh = disc
	else:
		var box := BoxMesh.new()
		box.size = size
		lens.mesh = box
	lens.material_override = glass
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lens, true)
	lens.position = at
	lens.rotation = Vector3(PI / 2.0 if round else 0.0, deg_to_rad(turn), 0.0)


func set_lights(on: bool) -> void:
	lights_on = on
	for beam in _headlights:
		beam.light_energy = HEADLIGHT_ENERGY if on else 0.0
		beam.visible = on
	for tail in _tails:
		tail.light_energy = 0.6 if on else 0.0
	_tail_glass.emission_enabled = on
	_tail_glass.emission = TAIL_RED
	_tail_glass.emission_energy_multiplier = 3.0
	_head_glass.emission_enabled = on
	_head_glass.emission = HEAD_WHITE
	_head_glass.emission_energy_multiplier = 6.0


## Drives `points` at `metres_per_second`, from where it stands.
func drive(points: Array[Vector3], metres_per_second: float) -> void:
	route = points
	speed = metres_per_second
	_leg = 0


func arrived() -> bool:
	return route.is_empty() or _leg >= route.size()


## Stands it at `at` at once (a reset's).
func place(at: Transform3D) -> void:
	route.clear()
	_leg = 0
	global_transform = at


func _physics_process(delta: float) -> void:
	if arrived():
		return
	var target := route[_leg]
	var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to.length() < 0.3:
		_leg += 1
		return
	var wanted := atan2(-to.x, -to.z)
	var yaw := global_rotation.y
	yaw += clampf(wrapf(wanted - yaw, -PI, PI), -TURN_RATE * delta, TURN_RATE * delta)
	var step := minf(speed * delta, to.length())
	global_transform = Transform3D(Basis(Vector3.UP, yaw), global_position + to.normalized()
		* step)
