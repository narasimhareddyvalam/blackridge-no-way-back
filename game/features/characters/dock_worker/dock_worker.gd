extends Node3D
## Bay 9's dock worker (docs/PHASE_BRIEF.md, step 2e-3, rule H5; the author's L2 b, #230, and
## C58): Microsoft Rocketbox's Construction_Male_08, a stand-in. Called once a loaded van's rear
## doors are shut, he comes out of the shed's side door, walks the way he is given to the doors,
## puts the bolt seal through their hasp and walks back in. He waits rather than walk into
## anyone: Ethan is the only one about. He reads the van and changes it only by sealing it.

signal sealed

const Model = preload("res://features/characters/dock_worker/dock_worker.glb")
const WALK := 1.35
const TURN_RATE := 8.0
const ARRIVE := 0.05
const KEEP_CLEAR := 0.75
const SEAL_AT := 3.1
const FROM_DOORS := 0.42
const BLEND := 0.25
const PEOPLE := 4

var home := true

var _model: Node3D
var _player: AnimationPlayer
var _inside := Vector3.ZERO
var _way: Array[Vector3] = []
var _route: Array[Vector3] = []
var _state := "home"
var _van: Node3D
var _number := ""
var _sealing := 0.0
var _query := PhysicsShapeQueryParameters3D.new()
var _ray := PhysicsRayQueryParameters3D.new()


## `inside` is where he waits inside the shed; `way` the points from there to the van's back.
func setup(inside: Vector3, way: Array[Vector3]) -> void:
	_inside = inside
	_way = way
	_model = Model.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var body := SphereShape3D.new()
	body.radius = KEEP_CLEAR
	_query.shape = body
	_query.collision_mask = PEOPLE
	_ray.collision_mask = 1
	reset()


func reset() -> void:
	_state = "home"
	home = true
	_van = null
	_route.clear()
	visible = false
	global_position = _inside
	_player.play("Idle")


## Out to `van`'s rear doors to seal them with the seal numbered `number`.
func go_seal(van: Node3D, number: String) -> void:
	if _state != "home":
		return
	_van = van
	_number = number
	_route = _way.duplicate()
	_route.append(van.call("seal_point") + van.global_basis.z.normalized() * FROM_DOORS)
	_state = "out"
	home = false
	visible = true
	_player.play("Walk", BLEND)


func _physics_process(delta: float) -> void:
	match _state:
		"out", "back":
			_walk(delta)
		"sealing":
			_seal(delta)


func _walk(delta: float) -> void:
	if _route.is_empty():
		_arrived()
		return
	var target := _route[0]
	var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to.length() < ARRIVE:
		_route.pop_front()
		return
	var step := to.normalized() * minf(WALK * delta, to.length())
	if _crowded(global_position + step):
		_play("Idle")
		return
	_face(to, delta)
	global_position += step
	global_position.y = _ground(global_position)
	_play("Walk")


func _arrived() -> void:
	if _state == "out":
		_state = "sealing"
		_sealing = 0.0
		var doors: Vector3 = _van.call("seal_point") if is_instance_valid(_van) else global_position
		_model.rotation.y = atan2(doors.x - global_position.x, doors.z - global_position.z)
		_player.play("Seal", BLEND)
	else:
		reset()


func _seal(delta: float) -> void:
	var before := _sealing
	_sealing += delta
	if before < SEAL_AT and _sealing >= SEAL_AT and is_instance_valid(_van) \
			and not bool(_van.get("rear_doors_open")):
		_van.call("put_seal", _number)
		sealed.emit()
	if _sealing >= _player.current_animation_length or _player.current_animation != "Seal":
		_state = "back"
		_route = _way.duplicate()
		_route.reverse()
		_route.append(_inside)
		_play("Walk")


func _face(direction: Vector3, delta: float) -> void:
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(direction.x, direction.z),
		1.0 - exp(-delta * TURN_RATE))


## Whether someone stands where he would step: he waits for them instead of walking through.
func _crowded(at: Vector3) -> bool:
	_query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.9)
	return not get_world_3d().direct_space_state.intersect_shape(_query, 1).is_empty()


func _ground(at: Vector3) -> float:
	_ray.from = at + Vector3.UP * 1.0
	_ray.to = at + Vector3.DOWN * 1.0
	var hit := get_world_3d().direct_space_state.intersect_ray(_ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else at.y


func _play(clip: String) -> void:
	if _player.current_animation != clip:
		_player.play(clip, BLEND)
