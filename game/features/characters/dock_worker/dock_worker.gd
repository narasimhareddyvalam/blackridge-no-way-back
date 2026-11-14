extends Node3D
## Bay 9's dock worker (docs/PHASE_BRIEF.md, step 2e-3, rule H5; step 3 of #253; the author's L2 b,
## #230, and C58): Microsoft Rocketbox's Construction_Male_08, a stand-in. Between jobs he sits at
## his dock desk (dock_station.gd) by the door he works, in Rocketbox's seated idle at a table.
## Called once a loaded van's rear doors are shut, he stands up from the desk, takes the seal log
## from it in his hand, walks over the dock floor between the desk and bay 9's staged load to the
## stair's landing, down the dock stair and out by the shed's side door, round to the van's doors.
## There he seals them as C-TPAT's seal check asks, view, verify, tug, twist: the bolt through the
## hasp and its cap snapped on, tugged and twisted (Seal), the number checked against his log
## (Check) and noted (Note). Then he walks back the same way, puts the log down and sits at his
## desk again, the chair rolling back as he rises and in under him as he sits. He waits rather
## than walk into anyone: Ethan is the only one about. He reads the van and changes it only by
## sealing it.

signal sealed

const Model = preload("res://features/characters/dock_worker/dock_worker.glb")
const CLIPBOARD := "res://features/environments/industrial_loop/art/dock_station/models/" \
	+ "clipboard/clipboard.gltf"
## A steady adult walk, 1.4 m/s (the usual average walking pace).
const WALK := 1.4
const TURN_RATE := 8.0
const ARRIVE := 0.05
const KEEP_CLEAR := 0.75
const SEAL_AT := 3.1
const FROM_DOORS := 0.42
const BLEND := 0.25
const PEOPLE := 4
## A practised dock hand's look at the seal against his log and his note of it, in seconds.
const CHECK_SECONDS := 3.0
const NOTE_SECONDS := 2.5
## The desk clips' own root motion, as measured on the converted model (dock_worker.glb): seated,
## his hips 0.576 m up over the node; sitting down ends 0.126 m to his left and 0.672 m ahead of
## where it began; standing up ends 0.514 m to his right and 0.165 m ahead of the seat.
const SIT_FROM := Vector3(-0.126, 0.0, 0.672)
const STAND_TO := Vector3(-0.514, 0.0, 0.165)
## His hips sit 0.05 m behind the chair's column, over the cushion's middle.
const SEAT_BACK := 0.05
## How far the chair rolls back as he rises and is drawn in as he sits.
const CHAIR_ROLL := 0.3
## His hand's hold on the log: the clipboard in the left hand, held flat against the forearm.
const HAND := "Bip01 L Hand"
const HOLD_TURN := Vector3(PI / 2.0, 0.0, PI / 2.0)
const HOLD_AT := Vector3(0.06, 0.02, 0.0)

var home := true
var state := "seated"

var _model: Node3D
var _player: AnimationPlayer
var _inside := Vector3.ZERO
var _way: Array[Vector3] = []
var _desk_way: Array[Vector3] = []
var _stair_way: Array[Vector3] = []
var _route: Array[Vector3] = []
var _van: Node3D
var _number := ""
var _timer := 0.0
var _query := PhysicsShapeQueryParameters3D.new()
var _ray := PhysicsRayQueryParameters3D.new()
var _chair: Node3D
var _chair_home := Transform3D.IDENTITY
var _log: Node3D
var _clipboard: Node3D
var _seated := Vector3.ZERO
var _facing := Vector3.RIGHT


## `inside` is the side door's inside, `way` the points from there to the van's back; `station`
## his dock desk (its chair and seal log), `desk_way` the points from beside his chair to the
## stair's landing and `stair_way` from the landing down the stair to `inside`.
func setup(inside: Vector3, way: Array[Vector3], station: Node3D,
		desk_way: Array[Vector3], stair_way: Array[Vector3]) -> void:
	_inside = inside
	_way = way
	_desk_way = desk_way
	_stair_way = stair_way
	_chair = station.get("chair") as Node3D
	_chair_home = _chair.global_transform
	_log = station.get_node("SealLog") as Node3D
	var desk: Vector3 = station.get_node("Desk").global_position
	_facing = Vector3(desk.x - _chair_home.origin.x, 0.0, desk.z - _chair_home.origin.z) \
		.normalized()
	_seated = _chair_home.origin - _facing * SEAT_BACK
	_model = Model.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_hold_clipboard()
	var body := SphereShape3D.new()
	body.radius = KEEP_CLEAR
	_query.shape = body
	_query.collision_mask = PEOPLE
	_ray.collision_mask = 1
	reset()


func reset() -> void:
	state = "seated"
	home = true
	_van = null
	_route.clear()
	visible = true
	global_position = _seated
	_model.rotation.y = _heading(_facing)
	_chair.global_transform = _chair_home
	_carry(false)
	_player.play("SitIdle")


## Out to `van`'s rear doors to seal them with the seal numbered `number`.
func go_seal(van: Node3D, number: String) -> void:
	if state != "seated":
		return
	_van = van
	_number = number
	state = "standing"
	home = false
	_timer = 0.0
	_player.play("StandUp", BLEND)


func _physics_process(delta: float) -> void:
	match state:
		"standing":
			_stand(delta)
		"out", "back":
			_walk(delta)
		"sealing", "checking", "noting":
			_seal(delta)
		"sitting":
			_sit(delta)


func _stand(delta: float) -> void:
	_timer += delta
	var length := _player.get_animation("StandUp").length
	_roll(clampf(_timer / length, 0.0, 1.0))
	if _timer < length:
		return
	global_position = _seated + _local(STAND_TO)
	_carry(true)
	state = "out"
	_route = _desk_way.duplicate()
	_route.append_array(_stair_way)
	_route.append(_inside)
	_route.append_array(_way)
	_route.append(_van.call("seal_point") + _van.global_basis.z.normalized() * FROM_DOORS)
	_player.play("Walk", BLEND)


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
	if state == "out":
		state = "sealing"
		_timer = 0.0
		var doors: Vector3 = _van.call("seal_point") if is_instance_valid(_van) else global_position
		_model.rotation.y = atan2(doors.x - global_position.x, doors.z - global_position.z)
		_player.play("Seal", BLEND)
	else:
		state = "sitting"
		home = true
		_timer = 0.0
		global_position = _seated - _local(SIT_FROM)
		_model.rotation.y = _heading(_facing)
		_carry(false)
		_player.play("SitDown", BLEND)


func _seal(delta: float) -> void:
	var before := _timer
	_timer += delta
	if state == "sealing":
		if before < SEAL_AT and _timer >= SEAL_AT and is_instance_valid(_van) \
				and not bool(_van.get("rear_doors_open")):
			_van.call("put_seal", _number)
			sealed.emit()
		if _timer >= _player.get_animation("Seal").length:
			_next("checking", "Check")
	elif state == "checking" and _timer >= CHECK_SECONDS:
		_next("noting", "Note")
	elif state == "noting" and _timer >= NOTE_SECONDS:
		state = "back"
		_route = _way.duplicate()
		_route.reverse()
		_route.append(_inside)
		var down := _stair_way.duplicate()
		down.reverse()
		_route.append_array(down)
		var over := _desk_way.duplicate()
		over.reverse()
		_route.append_array(over)
		_route.append(_seated - _local(SIT_FROM))
		_play("Walk")


func _next(next: String, clip: String) -> void:
	state = next
	_timer = 0.0
	_player.play(clip, BLEND)


func _sit(delta: float) -> void:
	_timer += delta
	var length := _player.get_animation("SitDown").length
	_roll(1.0 - clampf(_timer / length, 0.0, 1.0))
	if _timer < length:
		return
	reset()


## The chair `share` of its roll back from the desk.
func _roll(share: float) -> void:
	_chair.global_transform = Transform3D(_chair_home.basis,
		_chair_home.origin - _facing * CHAIR_ROLL * share)


## `offset` in his own frame (facing the desk), in the world.
func _local(offset: Vector3) -> Vector3:
	return Basis(Vector3.UP, _heading(_facing)) * offset


func _heading(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)


func _carry(carrying: bool) -> void:
	if _clipboard != null:
		_clipboard.visible = carrying
	if _log != null:
		_log.visible = not carrying


func _hold_clipboard() -> void:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if skeleton.find_bone(HAND) < 0:
		return
	var hand := BoneAttachment3D.new()
	hand.name = "LeftHand"
	hand.bone_name = HAND
	skeleton.add_child(hand)
	_clipboard = (load(CLIPBOARD) as PackedScene).instantiate() as Node3D
	_clipboard.name = "Clipboard"
	hand.add_child(_clipboard)
	_clipboard.transform = Transform3D(Basis.from_euler(HOLD_TURN), HOLD_AT)


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
