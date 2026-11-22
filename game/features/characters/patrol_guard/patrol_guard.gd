extends Node3D
## A patrol guard at the warehouse compound (Mission 2's step 6, the escape, #358): a stand-in
## (D6), labelled so; Assignment 9's patrol, alert, search and chase replace its behaviour, not
## its places. The model is "Security Guard - Rigged 3D Model" by qsardor57913 (CC BY 4.0,
## `patrol_guard.glb`, `tools/art/convert_patrol_guard.py`): a contract security officer in a
## grey uniform shirt, tie and duty belt, with Ethan's own Mixamo walk and idle. A torch clipped
## to his left epaulette lights the way he faces, as patrol officers carry them.
##
## He walks his `route` at a patrol's pace, pausing at each end and turning there; standing, he
## looks side to side (`scan`). He sees ahead in a cone, SIGHT metres and HALF_ANGLE either side
## of the way he faces, where nothing solid stands between his eyes and the point (`sees`). The
## node faces its -Z, as Godot's nodes do.

const MODEL = preload("patrol_guard.glb")
const WALK_SPEED := 1.4
## The walk clip's own ground speed (convert_patrol_guard.py), so his feet do not slide.
const CLIP_SPEED := 1.738
const EYE := 1.62
const SIGHT := 15.0
const HALF_ANGLE := deg_to_rad(50.0)
const SOLID := 1 | 2
const TURN_RATE := deg_to_rad(120.0)
const BLEND := 0.25
const SCAN_PERIOD := 8.0
const TORCH_AT := Vector3(0.14, 1.42, -0.09)
const TORCH_DOWN := deg_to_rad(14.0)

var model_path := MODEL.resource_path
var start := Transform3D.IDENTITY
var route: Array[Vector3] = []
var pause := 3.0
var scan := 0.0
var torch: SpotLight3D
## How long he has seen the player without a break (the escape reads and resets it).
var sight := 0.0
## Which point of the route he walks toward; past the last he turns back along it.
var leg := 0
var arrived_first := false
var _step := 1
var _wait := 0.0
var _held := false
var _scan_time := 0.0
var _yaw := 0.0
var _model: Node3D
var _player: AnimationPlayer


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Model"
	_model.rotation.y = PI
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var holder := Node3D.new()
	holder.name = "Torch"
	add_child(holder)
	holder.position = TORCH_AT
	holder.rotation.x = -TORCH_DOWN
	var body := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.016
	tube.bottom_radius = 0.016
	tube.height = 0.13
	body.mesh = tube
	body.rotation.x = PI / 2.0
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.05, 0.05, 0.055)
	black.roughness = 0.5
	body.material_override = black
	holder.add_child(body)
	var lens := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.017
	disc.bottom_radius = 0.017
	disc.height = 0.004
	lens.mesh = disc
	lens.rotation.x = PI / 2.0
	lens.position = Vector3(0.0, 0.0, -0.066)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.97, 0.9)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.97, 0.9)
	glow.emission_energy_multiplier = 8.0
	lens.material_override = glow
	holder.add_child(lens)
	torch = SpotLight3D.new()
	torch.name = "Beam"
	torch.light_color = Color(1.0, 0.97, 0.9)
	torch.light_energy = 6.0
	torch.spot_range = 20.0
	torch.spot_angle = 22.0
	torch.spot_attenuation = 0.8
	torch.position = Vector3(0.0, 0.0, -0.07)
	holder.add_child(torch)


## Where he starts, the points he walks between, how long he waits at each end, and how far he
## looks to either side while he stands (radians).
func setup(at: Transform3D, points: Array[Vector3], wait: float, look: float) -> void:
	start = at
	route = points
	pause = wait
	scan = look
	reset()


func reset() -> void:
	global_transform = start
	_yaw = start.basis.get_euler().y
	leg = 0
	_step = 1
	_wait = 0.0
	_held = false
	_scan_time = 0.0
	sight = 0.0
	arrived_first = route.is_empty()
	_play("Idle")


## Holds him still at `at` (a test's or a cutscene's).
func hold(at: Transform3D) -> void:
	_held = true
	global_transform = at
	_yaw = at.basis.get_euler().y
	sight = 0.0
	_play("Idle")


func clip() -> String:
	return _player.current_animation


func facing() -> Vector3:
	return -global_basis.z


## Whether he sees `point`: within SIGHT, within HALF_ANGLE of the way he faces, and nothing solid
## between his eyes and it (the world, layer 1, or a van, layer 2) but what `exclude` lists.
func sees(point: Vector3, exclude: Array[RID] = []) -> bool:
	var eye := global_position + Vector3.UP * EYE
	var flat := Vector3(point.x - eye.x, 0.0, point.z - eye.z)
	if flat.length() > SIGHT:
		return false
	var ahead := facing()
	ahead.y = 0.0
	if flat.length() > 0.01 and ahead.normalized().angle_to(flat.normalized()) > HALF_ANGLE:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, point, SOLID, exclude)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if _held:
		return
	if route.is_empty():
		_stand(delta)
		return
	if _wait > 0.0:
		_wait -= delta
		_turn_toward(_next_point() - global_position, delta)
		_play("Idle")
		return
	var target := route[leg]
	var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to.length() < 0.15:
		_arrive()
		return
	var turned := _turn_toward(to, delta)
	if turned > deg_to_rad(35.0):
		_play("Idle")
		return
	var step := minf(WALK_SPEED * delta, to.length())
	global_position += to.normalized() * step
	_play("Walk", WALK_SPEED / CLIP_SPEED)


func _arrive() -> void:
	if leg == 0:
		arrived_first = true
	if route.size() == 1:
		route.clear()
		start = global_transform
		return
	if leg + _step >= route.size() or leg + _step < 1:
		_step = -_step
		_wait = pause
	leg += _step


func _next_point() -> Vector3:
	return route[clampi(leg, 0, route.size() - 1)]


func _stand(delta: float) -> void:
	_play("Idle")
	if is_zero_approx(scan):
		return
	_scan_time += delta
	var base := start.basis.get_euler().y
	_set_yaw(base + scan * sin(TAU * _scan_time / SCAN_PERIOD))


## Turns him toward `to` at TURN_RATE; returns how far he still has to turn.
func _turn_toward(to: Vector3, delta: float) -> float:
	if to.length() < 0.01:
		return 0.0
	var wanted := atan2(-to.x, -to.z)
	var gap := wrapf(wanted - _yaw, -PI, PI)
	_set_yaw(_yaw + clampf(gap, -TURN_RATE * delta, TURN_RATE * delta))
	return absf(wrapf(wanted - _yaw, -PI, PI))


func _set_yaw(value: float) -> void:
	_yaw = value
	global_basis = Basis(Vector3.UP, _yaw)


func _play(name: String, rate: float = 1.0) -> void:
	if _player.current_animation != name:
		_player.play(name, BLEND)
	_player.speed_scale = rate
