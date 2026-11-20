extends CharacterBody3D

const ETHAN = preload("res://features/characters/ethan/ethan.glb")
const PushGait = preload("res://features/characters/driver/push_gait.gd")
const StairSteps = preload("res://features/characters/driver/stair_steps.gd")
const FeetFlat = preload("res://features/characters/driver/feet_flat.gd")
const AnkleWatch = preload("res://features/characters/driver/ankle_watch.gd")
const HandleClear = preload("res://features/characters/driver/handle_clear.gd")
const Stance = preload("res://features/characters/driver/stance.gd")
const HandGrip = preload("res://features/characters/driver/hand_grip.gd")
const WALK_SPEED := 1.705
const RUN_SPEED := 4.535
const BLEND := 0.2
const TURN_RATE := 10.0
const ARRIVE := 0.06
const STUCK_SECONDS := 1.0
const FACE_SECONDS := 0.25
const GRIP_REACH := 0.17
const STEP_HEIGHT := 0.3
const STEP_PROBE := 0.1
const STEP_REACH := 0.35
const STEP_HOLD := 0.6
const STANDING := 1.8
const STOOPED := 1.3
const EYE := 1.55
const STOOPED_EYE := 1.05
const EYE_RATE := 2.0
const HANDS_RATE := 4.0
const ELBOW_OUT := 0.5
const ELBOW_UP := 0.75
const ELBOW_BACK := 0.1
const UNDER_PALM := 0.03
const CROUCH_MOST := 0.25
const CROUCH_RATE := 0.6
const CROUCH_ROOM := 0.005
const GLIDE := 16.0
const SNAP_DOWN := 0.03
const ARM_LENGTH := 3.5
const ARM_TILT := -0.14
const BOOM_EASE := 6.0
const BOOM_IN := 7.0
## Walls only his camera meets, such as across the shed's open dock doors (#257).
const CAMERA_WALLS := 8
const LOOK_AHEAD := 0.6
const ARM_MARGIN := 0.2
const KNEE_AHEAD := 1.0
const KNEE_UP := 0.5
const STILL := 0.12
const FACE_RATE := 8.0
const RATE_MOST := 2.0
const DOOR_ELBOW_OUT := 0.45
const DOOR_ELBOW_UP := 0.95
const DOOR_ELBOW_BACK := 0.15
const REACH_EASY := 0.45
const LEAN_MOST := 0.22
const LEAN_RATE := 0.6

var active: bool = false
## The stairs he walks by his stair steps (`stair_steps.gd`), each as `dock_access.gd`'s
## `stair()` describes it; the app gives them.
var stairs: Array[Dictionary] = []
## Held through a cutscene (#333): the player's keys do not move him; a way he is sent along
## (`walk_to()`) he still walks.
var held := false
## Behind something he pushes and pulls, such as the depot's pallet jack (step 2e), Ethan walks
## by his push gait (`push_gait.gd`), his hands held to its handle, at the same pace up and down a
## slope, such as the lift's bridge plate.
var pushing: bool = false:
	set(value):
		pushing = value
		floor_constant_speed = value
		if _gait == null:
			return
		if value:
			_end_stair()
			_gait.take()
		else:
			_let_go_handle()
## While he works something by hand that moves him, such as the van's rear doors (part B, #247),
## his own walking is off: `door_step()` walks him and `door_hand()` holds a hand to it.
var handling: bool = false:
	set(value):
		handling = value
		if _gait == null:
			return
		_end_stair()
		_route.clear()
		velocity = Vector3.ZERO
		if not value:
			for side in range(2):
				door_hand(side, Vector3.ZERO, 0.0)
			_lean = 0.0
			_model.rotation.x = 0.0
			_player.speed_scale = 1.0
			_play("Idle")
## Under a low roof, such as the van's hold behind the pallet jack (step 2e), Ethan stoops: his
## collision is shorter and his eyes lower, his push keeping its lean.
var stooping: bool = false:
	set(value):
		if value == stooping:
			return
		stooping = value
		var capsule := _collision.shape as CapsuleShape3D
		capsule.height = STOOPED if value else STANDING
		_collision.position.y = capsule.height / 2.0
var _pivot: Node3D
var _camera: Camera3D
var _arm: SpringArm3D
var _passing: Array[RID] = []
var _model: Node3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _collision: CollisionShape3D
var _route: Array[Vector3] = []
var _scripted: bool = false
var _best_gap: float = INF
var _stuck: float = 0.0
var _grip := TwoBoneIK3D.new()
var _grip_target := Node3D.new()
var _grip_pole := Node3D.new()
var _grip_seen := Vector3.ZERO
var _hand := -1
var _step_top := INF
var _step_time: float = 0.0
var _gait: PushGait
var _hold := TwoBoneIK3D.new()
var _hold_targets: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _hold_poles: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _wrists: Array[int] = []
var _knuckles: Array[int] = []
var _palm_reach: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _steps: StairSteps
var _legs := TwoBoneIK3D.new()
var _leg_targets: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _leg_poles: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _ankles: Array[int] = []
var _soles: FeetFlat
var _watch: AnkleWatch
var _handle_clear: HandleClear
var _stance: Stance
var _crouch := 0.0
var _fingers: HandGrip
var _glide := 0.0
var _glide_speed := 0.0
var _eye := EYE
var _boom: Node3D
var _door_hands: Array[TwoBoneIK3D] = [TwoBoneIK3D.new(), TwoBoneIK3D.new()]
var _door_targets: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _door_poles: Array[Node3D] = [Node3D.new(), Node3D.new()]
var _shoulders: Array[int] = []
var _lean := 0.0
var _shown := ARM_LENGTH
var _shown_speed := 0.0
var _pivot_was := Vector3.INF
var _pivot_speed := Vector3.ZERO


func _ready() -> void:
	var collision := CollisionShape3D.new()
	_collision = collision
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = STANDING
	collision.shape = capsule
	collision.position.y = STANDING / 2.0
	add_child(collision)
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = STEP_HEIGHT
	_model = ETHAN.instantiate() as Node3D
	_model.name = "Ethan"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_player.play("Idle")
	_stance = Stance.new()
	_stance.name = "FeetOnOwnSides"
	_stance.player = _player
	_skeleton.add_child(_stance)
	_handle_clear = HandleClear.new()
	_handle_clear.name = "BackClearOfHandle"
	_skeleton.add_child(_handle_clear)
	_grip_hand()
	_hold_hands()
	_fingers = HandGrip.new()
	_fingers.name = "FingersRoundHandle"
	_skeleton.add_child(_fingers)
	_hands_on_doors()
	_legs_on_steps()
	_gait = PushGait.new(_player)
	_steps = StairSteps.new()
	_pivot = Node3D.new()
	_pivot.position.y = EYE
	add_child(_pivot)
	var arm := SpringArm3D.new()
	_arm = arm
	arm.spring_length = ARM_LENGTH
	arm.margin = ARM_MARGIN
	arm.collision_mask = 3 | CAMERA_WALLS
	arm.add_excluded_object(get_rid())
	arm.rotation.x = ARM_TILT
	_pivot.add_child(arm)
	_boom = Node3D.new()
	_boom.name = "CameraBoom"
	_boom.rotation.x = ARM_TILT
	_pivot.add_child(_boom)
	_camera = Camera3D.new()
	_camera.fov = 70
	_camera.position = Vector3(0.0, 0.0, ARM_LENGTH)
	_boom.add_child(_camera)
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value
	set_physics_process(value)
	set_process(value)
	_collision.set_deferred("disabled", not value)
	stooping = false
	_eye = EYE
	_glide = 0.0
	_glide_speed = 0.0
	_pivot.position.y = EYE
	_shown = ARM_LENGTH
	_shown_speed = 0.0
	_pivot_was = Vector3.INF
	_pivot_speed = Vector3.ZERO
	_camera.position = Vector3(0.0, 0.0, ARM_LENGTH)
	_player.speed_scale = 1.0
	_route.clear()
	_scripted = false
	_model.position = Vector3.ZERO
	_hold.influence = 0.0
	_hold.active = false
	_fingers.amount = 0.0
	handling = false
	_end_stair()
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


func grip(at: Vector3, elbow: Vector3, amount: float) -> void:
	_grip_target.global_position = at
	_grip_pole.global_position = elbow
	_grip.influence = clampf(amount, 0.0, 1.0)
	_grip.active = amount > 0.0


func grip_point() -> Vector3:
	return _grip_seen


func _remember_grip() -> void:
	var hand := _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand)
	_grip_seen = hand.origin + hand.basis.y.normalized() * GRIP_REACH
	for index in range(_wrists.size()):
		var wrist := _skeleton.global_transform * _skeleton.get_bone_global_pose(_wrists[index])
		var knuckle := _skeleton.global_transform * _skeleton.get_bone_global_pose(_knuckles[index])
		_palm_reach[index] = (knuckle.origin - wrist.origin) / 2.0


func _grip_hand() -> void:
	for point: Node3D in [_grip_target, _grip_pole]:
		point.top_level = true
		add_child(point)
	_grip.name = "LeftHandGrip"
	_grip.set_setting_count(1)
	_grip.set_root_bone_name(0, "mixamorig_LeftArm")
	_grip.set_middle_bone_name(0, "mixamorig_LeftForeArm")
	_grip.set_end_bone_name(0, "mixamorig_LeftHand")
	_grip.set_extend_end_bone(0, true)
	_grip.set_end_bone_direction(0, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
	_grip.set_end_bone_length(0, GRIP_REACH / _skeleton.global_basis.get_scale().y)
	_grip.active = false
	_skeleton.add_child(_grip)
	_grip.set_target_node(0, _grip.get_path_to(_grip_target))
	_grip.set_pole_node(0, _grip.get_path_to(_grip_pole))
	_hand = _skeleton.find_bone("mixamorig_LeftHand")
	_skeleton.skeleton_updated.connect(_remember_grip)


## Both hands to the handle of what he pushes, each palm on its side of the loop: the wrist is
## held where the hand, turned as his clip and the handle turn it, puts the palm there; his elbows
## out and down.
func _hold_hands() -> void:
	_hold.name = "HandsOnHandle"
	_hold.set_setting_count(2)
	for index in range(2):
		var side: String = ["Left", "Right"][index]
		for point: Node3D in [_hold_targets[index], _hold_poles[index]]:
			point.top_level = true
			add_child(point)
		_hold.set_root_bone_name(index, "mixamorig_%sArm" % side)
		_hold.set_middle_bone_name(index, "mixamorig_%sForeArm" % side)
		_hold.set_end_bone_name(index, "mixamorig_%sHand" % side)
		_hold.set_extend_end_bone(index, false)
		_wrists.append(_skeleton.find_bone("mixamorig_%sHand" % side))
		_knuckles.append(_skeleton.find_bone("mixamorig_%sHandMiddle1" % side))
	_hold.active = false
	_hold.influence = 0.0
	_skeleton.add_child(_hold)
	for index in range(2):
		_hold.set_target_node(index, _hold.get_path_to(_hold_targets[index]))
		_hold.set_pole_node(index, _hold.get_path_to(_hold_poles[index]))


## The handle he holds, as straight pieces in the world in pairs of ends `thick` round, for his
## back to straighten clear of (`handle_clear.gd`), and the van whose roof and rear doorway are
## over his head when it is in its hold (`roof`, as `handle_clear.gd` reads it); none once he
## lets go.
func keep_clear_of(pieces: PackedVector3Array, thick: float, roof := {}) -> void:
	_handle_clear.pieces = pieces
	_handle_clear.thick = thick
	_handle_clear.roof = roof
	_handle_clear.facing = _facing()


## Where his left and right palms hold the handle this frame, in the world; each wrist goes where
## its hand, as it was last posed, puts the palm there, the handle's bar just under the palm as
## his fingers close round it (`hand_grip.gd`; `bars`, the bar's way up at each hand).
func hold_handle(left: Vector3, right: Vector3, bars: Array[Vector3] = []) -> void:
	var facing := Vector3(sin(_model.rotation.y), 0.0, cos(_model.rotation.y))
	var out := Vector3.UP.cross(facing)
	if bars.size() == 2:
		_fingers.bars = bars
	for index in range(2):
		_hold_targets[index].global_position = [left, right][index] - _palm_reach[index] \
			- _fingers.palms[index] * UNDER_PALM * _fingers.amount
		_hold_poles[index].global_position = global_position + out * (ELBOW_OUT if index == 0
			else -ELBOW_OUT) + Vector3.UP * ELBOW_UP - facing * ELBOW_BACK


## One physics frame of his walk behind the thing he pushes (`push_gait.gd`): `drive` is W less
## S, `lead` how much faster than his feet it may go while it runs out to arm's length, `slack`
## how much nearer its handle he may still step. Plays his clip, brings his hands to the handle
## or off it, and returns how far his feet carry him along his facing and how far it goes with
## him.
func push_gait(drive: float, lead: float, slack: float, delta: float) -> Vector2:
	var moved := _gait.step(drive, lead, slack, stooping, delta)
	_hold.influence = move_toward(_hold.influence, _gait.hands, HANDS_RATE * delta)
	_hold.active = _hold.influence > 0.0
	_fingers.amount = _hold.influence
	return moved


## One physics frame of his walk between his stances while he works something by hand: his body
## goes toward `at` across the floor, with his collision and his step up a kerb as ever, turning
## to face `facing`; he plays his walk forward or back at the pace he really goes, or stands.
func door_step(at: Vector3, facing: Vector3, delta: float) -> void:
	var before := global_position
	var grounded := is_on_floor()
	velocity = Vector3(at.x - before.x, 0.0, at.z - before.z) / maxf(delta, 0.0001)
	if _step_top < INF:
		velocity.y = 0.0
	else:
		velocity.y = -0.5 if grounded else -18.0 * delta
		_step_up(Vector3(velocity.x, 0.0, velocity.z))
	move_and_slide()
	_hold_step(delta)
	if grounded and is_on_floor() and get_floor_normal().y > 0.99 \
			and global_position.y - before.y < -SNAP_DOWN:
		_glide -= global_position.y - before.y
	var went := Vector3(global_position.x - before.x, 0.0, global_position.z - before.z)
	var flat := Vector3(facing.x, 0.0, facing.z)
	if flat.length_squared() > 0.0001:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(flat.x, flat.z),
			1.0 - exp(-delta * FACE_RATE))
	var speed := went.length() / maxf(delta, 0.0001)
	if speed < STILL:
		_play("Idle")
		_player.speed_scale = 1.0
	else:
		var ahead := went.dot(_facing())
		var back := ahead < -0.3 * went.length() or (_player.current_animation == "WalkBack"
			and ahead < 0.3 * went.length())
		_play("WalkBack" if back else "Walk")
		_player.speed_scale = minf(speed / (PushGait.WALK_BACK_SPEED if back else WALK_SPEED),
			RATE_MOST)
	var leaning := 0.0
	for side in range(2):
		if _door_hands[side].active:
			leaning = maxf(leaning, _lean_for(side) * _door_hands[side].influence)
	_model.rotation.x = move_toward(_model.rotation.x, leaning, LEAN_RATE * delta)
	_eye = move_toward(_eye, EYE, EYE_RATE * delta)
	_glide_steps(delta)
	_model.position.y = _glide


## How far forward from his ankles he leans for his hand `side` to reach its palm's place: none
## while his arm reaches it easily, as a man leans in over a van's bumper to its door's handle.
func _lean_for(side: int) -> float:
	var shoulder := (_skeleton.global_transform * _skeleton.get_bone_global_pose(
		_shoulders[side])).origin
	var from := _model.global_position
	var upright := Basis(_model.global_basis.x.normalized(), -_model.rotation.x) * (shoulder - from)
	var palm := _door_targets[side].global_position + _palm_reach[side]
	var short := (from + upright).distance_to(palm) - REACH_EASY
	return clampf(short / maxf(upright.length(), 0.5), 0.0, LEAN_MOST)


## His hand `side` (0 left, 1 right) on what he works, its palm at `palm` in the world, as much as
## `amount` (0 lets it go): the wrist set where his hand, as last posed, puts the palm there, his
## elbow out and down.
func door_hand(side: int, palm: Vector3, amount: float) -> void:
	var reach := _door_hands[side]
	reach.influence = clampf(amount, 0.0, 1.0)
	reach.active = reach.influence > 0.0
	if not reach.active:
		return
	var facing := _facing()
	var out := Vector3.UP.cross(facing) * (1.0 if side == 0 else -1.0)
	_door_targets[side].global_position = palm - _palm_reach[side]
	_door_poles[side].global_position = global_position + out * DOOR_ELBOW_OUT \
		+ Vector3.UP * DOOR_ELBOW_UP - facing * DOOR_ELBOW_BACK


## A hand each for what he works by hand, each its own IK so that one can hold while the other
## hangs as his clip has it.
func _hands_on_doors() -> void:
	for index in range(2):
		var side: String = ["Left", "Right"][index]
		var reach := _door_hands[index]
		reach.name = "%sHandOnDoor" % side
		reach.set_setting_count(1)
		for point: Node3D in [_door_targets[index], _door_poles[index]]:
			point.top_level = true
			add_child(point)
		reach.set_root_bone_name(0, "mixamorig_%sArm" % side)
		reach.set_middle_bone_name(0, "mixamorig_%sForeArm" % side)
		reach.set_end_bone_name(0, "mixamorig_%sHand" % side)
		reach.set_extend_end_bone(0, false)
		_shoulders.append(_skeleton.find_bone("mixamorig_%sArm" % side))
		reach.active = false
		reach.influence = 0.0
		_skeleton.add_child(reach)
		reach.set_target_node(0, reach.get_path_to(_door_targets[index]))
		reach.set_pole_node(0, reach.get_path_to(_door_poles[index]))


## What he pushes could not go where his feet were taking it.
func push_blocked() -> void:
	_gait.blocked()


## Where his hands are in the clip he plays behind what he pushes: how far ahead of his feet's
## middle and how high (`push_gait.gd`).
func push_grip() -> Vector2:
	return _gait.grip()


## How fully his hands hold what he pushes, 0 to 1.
## Up to the handle he stood back from to pump the jack (#286).
func push_step_in() -> void:
	_gait.step_in()


func hands_on_handle() -> float:
	return _hold.influence


func _let_go_handle() -> void:
	_crouch = 0.0
	_feet_free()
	_hold.influence = 0.0
	_hold.active = false
	_fingers.amount = 0.0
	_player.speed_scale = 1.0


func walking() -> bool:
	return not _route.is_empty()


func play_clip(clip: String, facing: Vector3, from: float = 0.0,
		shift := Vector3.ZERO) -> void:
	_scripted = true
	_route.clear()
	velocity = Vector3.ZERO
	_end_stair()
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


## While Ethan holds something he pushes, such as the depot's pallet jack (step 2e), that thing
## moves him where his push gait's feet took him: by `motion` this physics frame, facing
## `facing`, with his own collision and the ground as ever, his eyes lowered under a low roof,
## and never farther across the floor than his feet went, as off an edge he would slide.
## Returns how far he really went.
func push_step(motion: Vector3, facing: Vector3, delta: float) -> Vector3:
	var before := global_position
	var flat := Vector3(motion.x, 0.0, motion.z)
	var fall := velocity.y
	velocity = flat / maxf(delta, 0.0001)
	if _step_top < INF:
		velocity.y = 0.0
	else:
		velocity.y = 0.0 if is_on_floor() else fall - 18 * delta
		_step_up(Vector3(velocity.x, 0.0, velocity.z))
	move_and_slide()
	var went := Vector2(global_position.x - before.x, global_position.z - before.z)
	if went.length() > Vector2(flat.x, flat.z).length():
		went = went.limit_length(Vector2(flat.x, flat.z).length())
		global_position = Vector3(before.x + went.x, global_position.y, before.z + went.y)
	_hold_step(delta)
	if facing.length_squared() > 0.01:
		_model.rotation.y = atan2(facing.x, facing.z)
	_eye = move_toward(_eye, STOOPED_EYE if stooping else EYE, EYE_RATE * delta)
	_glide_steps(delta)
	_crouch_under_roof(delta)
	return global_position - before


## Lets Ethan pass into `body`'s own shape, or stops him again, with the camera's arm passing
## too: the van's hold (step 2e), whose walls, floor and roof then hold him.
func pass_through(body: CollisionObject3D, on: bool) -> void:
	if not is_instance_valid(body) or on == (body.get_rid() in _passing):
		return
	if on:
		add_collision_exception_with(body)
		_arm.add_excluded_object(body.get_rid())
		_passing.append(body.get_rid())
	else:
		remove_collision_exception_with(body)
		_arm.remove_excluded_object(body.get_rid())
		_passing.erase(body.get_rid())


func _physics_process(delta: float) -> void:
	if _scripted or pushing or handling:
		return
	var direction := Vector3.ZERO
	var pace := WALK_SPEED
	if not _route.is_empty():
		direction = _route_direction(delta)
	else:
		var movement := Vector2.ZERO if held else Input.get_vector("steer_left", "steer_right",
			"accelerate", "brake")
		direction = _pivot.global_basis * Vector3(movement.x, 0, movement.y)
		direction.y = 0
		direction = direction.normalized()
		if Input.is_action_pressed("sprint"):
			pace = RUN_SPEED
	var moving := direction.length_squared() > 0.1
	var climbing := _find_stair(direction, moving)
	_steps.hurry = pace > WALK_SPEED
	if climbing:
		pace = lerpf(pace, _steps.kept_pace(global_position, _walk_frame()),
			_steps.pace_weight(global_position))
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	var before := global_position.y
	var grounded := is_on_floor()
	if _step_top < INF:
		velocity.y = 0.0
	elif climbing and _steps.on_incline(global_position):
		velocity.y = _steps.climb(global_position, velocity, delta)
	else:
		velocity.y = -0.5 if grounded else velocity.y - 18 * delta
		if not climbing:
			_step_up(Vector3(velocity.x, 0.0, velocity.z))
	move_and_slide()
	_hold_step(delta)
	if grounded and is_on_floor() and not climbing and get_floor_normal().y > 0.99 \
			and global_position.y - before < -SNAP_DOWN:
		_glide -= global_position.y - before
	if moving:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(direction.x, direction.z),
			1.0 - exp(-delta * TURN_RATE))
	if climbing and moving and _player.current_animation != _steps.clip():
		_player.play(_steps.clip(), BLEND)
		var start := _steps.entry if _steps.entry >= 0.0 else _steps.start_frame(direction)
		_steps.entry = -1.0
		if start >= 0.0:
			_player.seek(start / StairSteps.FPS, false)
	else:
		_play(("Run" if pace > WALK_SPEED and not climbing else _steps.clip() if climbing
			else "Walk") if moving else "Idle")
	_player.speed_scale = lerpf(1.0, _steps.rate(), _steps.influence) if climbing and moving \
		else 1.0
	_glide_steps(delta)
	_place_feet(direction, moving, delta)


func _process(delta: float) -> void:
	_ease_camera(delta)


## His camera comes in at once when something stands between it and him, and eases back out,
## smoothly, once it no longer does, as a studio's third-person camera does; and where his walk is
## taking him behind something, half a second on, it eases in before he gets there.
func _ease_camera(delta: float) -> void:
	var at := _pivot.global_position
	if _pivot_was != Vector3.INF and delta > 0.0:
		_pivot_speed = _pivot_speed.lerp((at - _pivot_was) / delta, 0.3)
	_pivot_was = at
	var reach := _arm.get_hit_length()
	if reach < _shown - 0.001:
		_shown = reach
		_shown_speed = 0.0
	else:
		var wanted := minf(reach, _reach_ahead(at, at + _pivot_speed * LOOK_AHEAD))
		var rate := BOOM_EASE if wanted >= _shown else BOOM_IN
		_shown_speed += (rate * rate * (wanted - _shown) - 2.0 * rate * _shown_speed) * delta
		_shown = minf(_shown + _shown_speed * delta, reach)
	_camera.position = Vector3(0.0, 0.0, _shown)


## How far out on its arm from `at` his camera may be, so as to stay this side of what his arm
## would meet from `ahead`, where his head will soon be.
func _reach_ahead(at: Vector3, ahead: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	var out := _boom.global_basis.z.normalized()
	var query := PhysicsRayQueryParameters3D.create(ahead, ahead + out * ARM_LENGTH,
		_arm.collision_mask)
	var skip: Array[RID] = [get_rid()]
	skip.append_array(_passing)
	query.exclude = skip
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return ARM_LENGTH
	return clampf(((hit["position"] as Vector3) - at).dot(out) - ARM_MARGIN, 0.0, ARM_LENGTH)


## Up a step his body rises at once, as ever, but his model and camera glide up after it, and
## down a kerb they glide down: each the step's height behind, eased out over a quarter second.
func _glide_steps(delta: float) -> void:
	_glide_speed += (-GLIDE * GLIDE * _glide - 2.0 * GLIDE * _glide_speed) * delta
	_glide += _glide_speed * delta
	_pivot.position.y = _eye + _glide


## Near a stair he is given, his feet take its treads (`stair_steps.gd`) from where they are.
func _find_stair(direction: Vector3, moving: bool) -> bool:
	if not _steps.active():
		for stair in stairs:
			if _steps.near(stair, global_position):
				_steps.begin(stair, _ankle_points(), direction if moving else _facing(),
					_facing(), global_position, _walk_frame() if moving else -1.0)
				break
	return _steps.active()


func _walk_frame() -> float:
	if _player.current_animation != _steps.clip():
		return -1.0
	return _player.current_animation_position * StairSteps.FPS


## His legs' IK and his soles set where his stair steps put them, his hips lowered with them.
func _place_feet(direction: Vector3, moving: bool, delta: float) -> void:
	if not _steps.active():
		_feet_free()
		return
	var frame := _walk_frame()
	var animated := _watch.ankles if _watch.seen else _ankle_points()
	_steps.step(global_position, _facing(), frame, moving and frame >= 0.0, direction, animated,
		_watch.hips if _watch.seen else animated,
		_watch.ground if _watch.seen else _model.global_position.y, delta)
	var facing := _facing()
	var left := Vector3.UP.cross(facing)
	for side in range(2):
		_leg_targets[side].global_position = _steps.targets[side]
		_leg_poles[side].global_position = global_position + facing * KNEE_AHEAD \
			+ Vector3.UP * KNEE_UP + left * StairSteps.SIDES[side]
		_soles.weights[side] = 1.0
		_soles.falls[side] = _steps.falls[side]
	_soles.facing = facing
	_legs.influence = _steps.influence
	_legs.active = _steps.influence > 0.0
	_soles.influence = _steps.influence
	_soles.active = _legs.active
	_watch.active = true
	_model.position.y = _glide - _steps.drop - _steps.riding_above(global_position)


## Under a low roof, as much lower as his bent back still leaves his head too high
## (`handle_clear.gd`'s `crouch_wanted`), by bending his knees: his body lowered, his legs' IK
## keeping his feet where his clip has them on the floor; up again as the roof allows.
func _crouch_under_roof(delta: float) -> void:
	var wanted := 0.0
	if _handle_clear.crouch_wanted > -INF:
		wanted = clampf(_crouch + _handle_clear.crouch_wanted + CROUCH_ROOM, 0.0, CROUCH_MOST)
	_crouch = move_toward(_crouch, wanted, CROUCH_RATE * delta)
	_model.position.y = _glide - _crouch
	_watch.active = _crouch > 0.0
	if not _watch.active:
		_watch.seen = false
	if _crouch <= 0.0 or not _watch.seen:
		_legs.active = false
		_legs.influence = 0.0
		return
	var facing := _facing()
	var left := Vector3.UP.cross(facing)
	for side in range(2):
		_leg_targets[side].global_position = _watch.ankles[side] + Vector3.UP * _crouch
		_leg_poles[side].global_position = global_position + facing * KNEE_AHEAD \
			+ Vector3.UP * KNEE_UP + left * StairSteps.SIDES[side]
	_legs.active = true
	_legs.influence = 1.0


func _end_stair() -> void:
	_steps.reset()
	_feet_free()


func _feet_free() -> void:
	_legs.influence = 0.0
	_legs.active = false
	_soles.influence = 0.0
	_soles.active = false
	_watch.active = false
	_watch.seen = false
	_model.position.y = _glide


func _facing() -> Vector3:
	return Vector3(sin(_model.rotation.y), 0.0, cos(_model.rotation.y))


func _ankle_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for bone in _ankles:
		points.append((_skeleton.global_transform * _skeleton.get_bone_global_pose(bone)).origin)
	return points


## His legs' IK, ankle on target, knee out ahead, and after it the modifier that levels his soles:
## both idle until a stair (`stair_steps.gd`).
func _legs_on_steps() -> void:
	_legs.name = "FeetOnSteps"
	_legs.set_setting_count(2)
	for index in range(2):
		var side: String = ["Left", "Right"][index]
		for point: Node3D in [_leg_targets[index], _leg_poles[index]]:
			point.top_level = true
			add_child(point)
		_legs.set_root_bone_name(index, "mixamorig_%sUpLeg" % side)
		_legs.set_middle_bone_name(index, "mixamorig_%sLeg" % side)
		_legs.set_end_bone_name(index, "mixamorig_%sFoot" % side)
		_legs.set_extend_end_bone(index, false)
		_ankles.append(_skeleton.find_bone("mixamorig_%sFoot" % side))
	_legs.active = false
	_legs.influence = 0.0
	_watch = AnkleWatch.new()
	_watch.name = "AnklesAsWalked"
	_watch.active = false
	_skeleton.add_child(_watch)
	_skeleton.add_child(_legs)
	for index in range(2):
		_legs.set_target_node(index, _legs.get_path_to(_leg_targets[index]))
		_legs.set_pole_node(index, _legs.get_path_to(_leg_poles[index]))
	_soles = FeetFlat.new()
	_soles.name = "SolesLevel"
	_soles.active = false
	_soles.influence = 0.0
	_skeleton.add_child(_soles)


## Up a step or kerb ahead: tried at the full step height, then at half of it, for a low roof
## such as the van's hold, where there is no room to rise the full height.
func _step_up(heading: Vector3) -> void:
	if not is_on_floor() or heading.length_squared() < 0.01:
		return
	var forward := heading.normalized()
	var ahead := KinematicCollision3D.new()
	if not test_move(global_transform, forward * STEP_PROBE, ahead):
		return
	if ahead.get_normal().y >= cos(floor_max_angle):
		return
	for height: float in [STEP_HEIGHT, STEP_HEIGHT / 2.0]:
		if _try_step(forward, height):
			return


func _try_step(forward: Vector3, height: float) -> bool:
	var lift := Vector3.UP * height
	var raised := global_transform.translated(lift)
	var over := forward * STEP_REACH
	if test_move(global_transform, lift) or test_move(raised, over):
		return false
	var landing := KinematicCollision3D.new()
	if not test_move(raised.translated(over), -lift, landing) \
			or landing.get_normal().y < cos(floor_max_angle):
		return false
	var rise := height - landing.get_travel().length()
	if rise < 0.02:
		return false
	_step_top = global_position.y + rise + 0.01
	_step_time = 0.0
	_glide -= _step_top - global_position.y
	global_position.y = _step_top
	floor_snap_length = 0.0
	return true


func _hold_step(delta: float) -> void:
	if _step_top == INF:
		return
	_step_time += delta
	global_position.y = maxf(global_position.y, _step_top)
	var below := KinematicCollision3D.new()
	var landed := test_move(global_transform, Vector3.DOWN * 0.03, below) \
		and below.get_normal().y >= cos(floor_max_angle)
	if landed or _step_time > STEP_HOLD:
		_step_top = INF
		floor_snap_length = STEP_HEIGHT


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
