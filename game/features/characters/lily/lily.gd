extends Node3D
## Lily, Maya's daughter, five (Mission 3's step 7, docs/PHASE_BRIEF.md, 2026-11-22, #359-#360):
## Rocketbox's Female_Child_01 (MIT, `lily.glb`, 1.12 m), with its breathing idle and its walk.
## Led by the hand (`lead`), she walks on the leader's own trail half a step behind him, out at his
## left side where there is room for her (not through a narrow door way, where she comes behind
## him), her right arm up and her hand in his (`hold_point`, where both hands meet, a little under her shoulder's
## height), quickening her steps to keep up as a child does; sent somewhere (`go_to`) she walks
## there and stands facing the way she is told. The node faces its +Z, as the Rocketbox models do.

const MODEL = preload("lily.glb")
## Her walk clip's ground speed at her height, and how fast she may go to catch up.
const WALK_CLIP := 0.65
const CATCH_UP := 1.6
const SIDE := 0.45
const BEHIND := 0.3
const TRAIL_STEP := 0.08
const ROOM := 0.3
const HOLD_HEIGHT := 0.86
const PALM := 0.05
const TURN_RATE := 6.0
const BLEND := 0.25

var following := false
var leader: Node3D
var _destination := Vector3.INF
var _trail: Array[Vector3] = []
var _face_to := Vector3.ZERO
var _model: Node3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _arm := TwoBoneIK3D.new()
var _hand_target := Node3D.new()
var _elbow := Node3D.new()
var _hand_bone := -1
var _hand_seen := Vector3.ZERO


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_hand_bone = _skeleton.find_bone("Bip01 R Hand")
	for point: Node3D in [_hand_target, _elbow]:
		point.top_level = true
		add_child(point)
	_arm.name = "HandInHis"
	_arm.set_setting_count(1)
	_arm.set_root_bone_name(0, "Bip01 R UpperArm")
	_arm.set_middle_bone_name(0, "Bip01 R Forearm")
	_arm.set_end_bone_name(0, "Bip01 R Hand")
	_arm.set_extend_end_bone(0, false)
	_arm.active = false
	_arm.influence = 0.0
	_skeleton.add_child(_arm)
	_arm.set_target_node(0, _arm.get_path_to(_hand_target))
	_arm.set_pole_node(0, _arm.get_path_to(_elbow))
	_skeleton.skeleton_updated.connect(_remember_hand)
	_play("Idle")


## Her hand in `by`'s: she follows.
func lead(by: Node3D) -> void:
	leader = by
	following = true
	_destination = Vector3.INF
	_trail = [global_position, by.global_position]


## To `at`, then standing facing `face`; her hand let go.
func go_to(at: Vector3, face: Vector3) -> void:
	following = false
	_destination = at
	_face_to = face


## Where her palm is, in the world, as last drawn (after her arm's IK).
func hand() -> Vector3:
	return _hand_seen


func _remember_hand() -> void:
	var pose := _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand_bone)
	_hand_seen = pose.origin + pose.basis.y.normalized() * PALM


## Her place: BEHIND along the leader's trail, then out to his left as far as there is room.
func _slot() -> Vector3:
	var at := leader.global_position
	if _trail.is_empty() or _trail[-1].distance_to(at) > TRAIL_STEP:
		_trail.append(at)
		if _trail.size() > 200:
			_trail.remove_at(0)
	var back := BEHIND
	var point := at
	for index in range(_trail.size() - 1, 0, -1):
		var gap := _trail[index].distance_to(_trail[index - 1])
		if gap >= back:
			point = _trail[index].lerp(_trail[index - 1], back / gap)
			back = 0.0
			break
		back -= gap
		point = _trail[index - 1]
	var left := Vector3.UP.cross(_leader_facing()).normalized()
	var space := get_world_3d().direct_space_state
	var from := point + Vector3.UP * 0.6
	var query := PhysicsRayQueryParameters3D.create(from, from + left * (SIDE + ROOM), 1)
	var hit := space.intersect_ray(query)
	var out := SIDE
	if not hit.is_empty():
		out = clampf(from.distance_to(hit["position"]) - ROOM, 0.0, SIDE)
	return point + left * out


## Where her hand meets the leader's: between them, a little under her shoulder's height.
func hold_point() -> Vector3:
	if leader == null:
		return hand()
	var middle := global_position.lerp(leader.global_position, 0.5)
	return Vector3(middle.x, global_position.y + HOLD_HEIGHT, middle.z)


func _physics_process(delta: float) -> void:
	var target := Vector3.INF
	var facing := Vector3.ZERO
	if following and leader != null:
		var ahead := _leader_facing()
		target = _slot()
		facing = ahead
	elif _destination != Vector3.INF:
		target = _destination
		facing = _face_to
	var speed := 0.0
	if target != Vector3.INF:
		var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
		var step := minf(to.length(), CATCH_UP * delta)
		if to.length() > 0.03:
			global_position += to.normalized() * step
			speed = step / delta
			if not following:
				facing = to.normalized()
		elif not following:
			_destination = Vector3.INF if _face_to == Vector3.ZERO else _destination
		if following and leader != null:
			global_position.y = leader.global_position.y
	if facing.length_squared() > 0.0:
		var wanted := atan2(facing.x, facing.z)
		rotation.y = lerp_angle(rotation.y, wanted, 1.0 - exp(-TURN_RATE * delta))
	if speed > 0.15:
		_play("Walk", clampf(speed / WALK_CLIP, 0.6, 2.4))
	else:
		_play("Idle")
	_hold(delta)


func _hold(delta: float) -> void:
	var holding := following and leader != null
	_arm.influence = move_toward(_arm.influence, 1.0 if holding else 0.0, 4.0 * delta)
	_arm.active = _arm.influence > 0.0
	if not holding:
		return
	var right := -Vector3.UP.cross(_leader_facing()).normalized()
	_hand_target.global_position = hold_point() - right * PALM
	_elbow.global_position = global_position + right * 0.35 + Vector3.UP * 0.55 \
		- _leader_facing() * 0.25


func _leader_facing() -> Vector3:
	if leader != null and leader.has_method("facing_yaw"):
		var yaw: float = leader.call("facing_yaw")
		return Vector3(sin(yaw), 0.0, cos(yaw))
	return global_basis.z


func _play(clip: String, rate: float = 1.0) -> void:
	if _player.current_animation != clip:
		_player.play(clip, BLEND)
	_player.speed_scale = rate
