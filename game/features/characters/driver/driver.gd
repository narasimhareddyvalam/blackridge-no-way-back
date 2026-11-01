extends CharacterBody3D

const ETHAN = preload("res://features/characters/ethan/ethan.glb")
const WALK_SPEED := 1.705
const RUN_SPEED := 4.535
const BLEND := 0.2
const TURN_RATE := 10.0
const ARRIVE := 0.06
const STUCK_SECONDS := 1.0
const FACE_SECONDS := 0.25

var active: bool = false
var _pivot: Node3D
var _camera: Camera3D
var _model: Node3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _collision: CollisionShape3D
var _route: Array[Vector3] = []
var _scripted: bool = false
var _best_gap: float = INF
var _stuck: float = 0.0


func _ready() -> void:
	var collision := CollisionShape3D.new()
	_collision = collision
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	collision_layer = 4
	collision_mask = 3
	_model = ETHAN.instantiate() as Node3D
	_model.name = "Ethan"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_player.play("Idle")
	_pivot = Node3D.new()
	_pivot.position.y = 1.55
	add_child(_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 3.5
	arm.margin = 0.2
	arm.collision_mask = 3
	arm.add_excluded_object(get_rid())
	arm.rotation.x = -0.14
	_pivot.add_child(arm)
	_camera = Camera3D.new()
	_camera.fov = 70
	arm.add_child(_camera)
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value
	set_physics_process(value)
	_collision.set_deferred("disabled", not value)
	_route.clear()
	_scripted = false
	_model.position = Vector3.ZERO
	_play("Idle")
	if value:
		_camera.make_current()


func face(direction: Vector3) -> void:
	_model.rotation.y = atan2(direction.x, direction.z)


func look_toward(direction: Vector3) -> void:
	_pivot.rotation.y = atan2(-direction.x, -direction.z)


func walk_to(points: Array[Vector3]) -> void:
	_route = points.duplicate()
	_scripted = false
	_best_gap = INF
	_stuck = 0.0


func walking() -> bool:
	return not _route.is_empty()


func play_clip(clip: String, facing: Vector3, from: float = 0.0,
		shift := Vector3.ZERO) -> void:
	_scripted = true
	_route.clear()
	velocity = Vector3.ZERO
	var yaw := atan2(facing.x, facing.z)
	_model.position = shift
	if from > 0.0:
		_model.rotation.y = yaw
		_player.play(clip)
		_player.seek(from, true)
		return
	var turn := create_tween()
	turn.tween_property(_model, "rotation:y",
		_model.rotation.y + angle_difference(_model.rotation.y, yaw), FACE_SECONDS)
	_player.play(clip, BLEND)


func clip_finished() -> bool:
	return _player.current_animation == "" or (_player.current_animation_position
		>= _player.current_animation_length - 0.001)


func finish_clip() -> void:
	var hips := _skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone("mixamorig_Hips"))
	var left := _skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone("mixamorig_LeftUpLeg"))
	var right := _skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone("mixamorig_RightUpLeg"))
	var across := right.origin - left.origin
	global_position = Vector3(hips.origin.x, global_position.y, hips.origin.z)
	_model.position = Vector3.ZERO
	_model.rotation.y = atan2(across.x, across.z) + PI / 2.0
	_scripted = false
	_player.play("Idle", BLEND)


func clip_time() -> float:
	return _player.current_animation_position


func _physics_process(delta: float) -> void:
	if _scripted:
		return
	var direction := Vector3.ZERO
	var pace := WALK_SPEED
	if not _route.is_empty():
		direction = _route_direction(delta)
	else:
		var movement := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
		direction = _pivot.global_basis * Vector3(movement.x, 0, movement.y)
		direction.y = 0
		direction = direction.normalized()
		if Input.is_action_pressed("sprint"):
			pace = RUN_SPEED
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18 * delta
	move_and_slide()
	var moving := direction.length_squared() > 0.1
	if moving:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(direction.x, direction.z),
			1.0 - exp(-delta * TURN_RATE))
	_play(("Run" if pace > WALK_SPEED else "Walk") if moving else "Idle")


func _route_direction(delta: float) -> Vector3:
	var target := _route[0]
	var gap := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if gap.length() < ARRIVE:
		_arrive(target)
		return Vector3.ZERO if _route.is_empty() else _route_direction(delta)
	if gap.length() < _best_gap - 0.05:
		_best_gap = gap.length()
		_stuck = 0.0
	else:
		_stuck += delta
		if _stuck > STUCK_SECONDS:
			_arrive(target)
			return Vector3.ZERO
	return gap.normalized()


func _arrive(target: Vector3) -> void:
	_route.pop_front()
	_best_gap = INF
	_stuck = 0.0
	if _route.is_empty():
		global_position = Vector3(target.x, global_position.y, target.z)
		velocity = Vector3.ZERO


func _play(clip: String) -> void:
	if _player.current_animation != clip:
		_player.play(clip, BLEND)


func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pivot.rotation.y -= event.relative.x * 0.002
		_pivot.rotation.x = clampf(_pivot.rotation.x - event.relative.y * 0.002, -0.5, 0.6)


func get_camera() -> Camera3D:
	return _camera
