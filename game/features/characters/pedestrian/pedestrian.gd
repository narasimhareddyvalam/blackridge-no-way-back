extends Node3D

signal struck(speed: float)

enum Shape { BOX, CAPSULE, SPHERE }

const MODEL = preload("res://features/characters/pedestrian/pedestrian.glb")
const PREFIX := "mixamorig_"
const WALK_SPEED := 1.705
const BLEND := 0.08
const STANDING := 1.6
const FREEZE_SECONDS := 0.35
const TURN_SECONDS := 0.3
const TURN_LIMIT := 1.2
const RESUME_AFTER := 1.2
const MAX_WALK := 30.0
const MIN_IMPACT := 1.0
const IN_PATH := 0.3
const BUMPER_REACH := 2.67
const VAN_HALF_WIDTH := 1.25
const RAGDOLL_LAYER := 8
const WORLD_LAYER := 1
const VAN_FRONT_LAYER := 16
const SWEEP := {"LeftLeg": 1.0, "RightLeg": 1.0, "LeftUpLeg": 0.9, "RightUpLeg": 0.9, "Hips": 0.6,
	"LeftForeArm": 0.9, "RightForeArm": 0.9, "LeftArm": 0.5, "RightArm": 0.5}
const SCOOP := {"LeftLeg": 3.0, "RightLeg": 3.0, "LeftUpLeg": 3.0, "RightUpLeg": 3.0, "Hips": 2.5}
const FRICTION := 0.7
const LINEAR_DAMP := 0.3
const ANGULAR_DAMP := 4.0
const LIMB_DAMP := 25.0
const STRAIGHT := 2.0
const LIMIT_SOFTNESS := 0.3
const LIMIT_BIAS := 0.6
const SETTLE_WINDOW := 0.5
const SETTLE_DRIFT := 0.05
const SETTLE_SECONDS := 1.0
const KNEE_AXIS := Vector3(-1.0, 0.0, 0.0)
const LEFT_ELBOW_AXIS := Vector3(0.33, 0.0, 0.94)
const RIGHT_ELBOW_AXIS := Vector3(0.18, 0.0, -0.98)
const BONES: Array[Dictionary] = [
	{"name": "Hips", "end": "Spine", "shape": Shape.BOX, "size": Vector3(0.3, 0.18, 0.2),
		"mass": 11.0},
	{"name": "Spine", "end": "Neck", "shape": Shape.CAPSULE, "radius": 0.13, "mass": 24.0,
		"swing": 40.0, "twist": 35.0},
	{"name": "Head", "end": "HeadTop_End", "shape": Shape.SPHERE, "radius": 0.11, "mass": 5.0,
		"swing": 60.0, "twist": 60.0},
	{"name": "LeftArm", "end": "LeftForeArm", "shape": Shape.CAPSULE, "radius": 0.05,
		"mass": 2.2, "swing": 80.0, "twist": 60.0, "damp": LIMB_DAMP},
	{"name": "LeftForeArm", "end": "LeftHand", "shape": Shape.CAPSULE, "radius": 0.045,
		"mass": 1.6, "hinge": LEFT_ELBOW_AXIS, "bend": 145.0, "damp": LIMB_DAMP},
	{"name": "RightArm", "end": "RightForeArm", "shape": Shape.CAPSULE, "radius": 0.05,
		"mass": 2.2, "swing": 80.0, "twist": 60.0, "damp": LIMB_DAMP},
	{"name": "RightForeArm", "end": "RightHand", "shape": Shape.CAPSULE, "radius": 0.045,
		"mass": 1.6, "hinge": RIGHT_ELBOW_AXIS, "bend": 145.0, "damp": LIMB_DAMP},
	{"name": "LeftUpLeg", "end": "LeftLeg", "shape": Shape.CAPSULE, "radius": 0.075, "mass": 8.0,
		"swing": 75.0, "twist": 40.0},
	{"name": "LeftLeg", "end": "LeftFoot", "shape": Shape.CAPSULE, "radius": 0.06, "mass": 4.2,
		"hinge": KNEE_AXIS, "bend": 140.0, "damp": LIMB_DAMP},
	{"name": "RightUpLeg", "end": "RightLeg", "shape": Shape.CAPSULE, "radius": 0.075,
		"mass": 8.0, "swing": 75.0, "twist": 40.0},
	{"name": "RightLeg", "end": "RightFoot", "shape": Shape.CAPSULE, "radius": 0.06, "mass": 4.2,
		"hinge": KNEE_AXIS, "bend": 140.0, "damp": LIMB_DAMP},
]

var vehicle: Node3D
var waiting: bool = false
var hit: bool = false
var frozen: bool = false
var settled: bool = false
var bones := {}
var _player: AnimationPlayer
var _model: Node3D
var _skeleton: Skeleton3D
var _simulator: PhysicalBoneSimulator3D
var _heading := Vector3.ZERO
var _turn: Tween
var _window: float = 0.0
var _calm: float = 0.0
var _rest_check := {}
var _walked: float = 0.0
var _stopped_for: float = 0.0
var _stop_at := Vector3.INF


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Pedestrian"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_player.play("HitByVan")
	_player.seek(STANDING, true)
	_build_ragdoll()
	_player.play("Walk")


func wait_at(spot: Vector3, facing: Vector3) -> void:
	global_position = spot
	_model.rotation.y = atan2(facing.x, facing.z)
	waiting = true
	_player.play("Idle")


func step_out(from: Vector3, toward: Vector3, van: Node3D) -> void:
	vehicle = van
	waiting = false
	global_position = from
	_heading = Vector3(toward.x - from.x, 0.0, toward.z - from.z).normalized()
	_stop_at = Vector3(toward.x, from.y, toward.z)
	_model.rotation.y = atan2(_heading.x, _heading.z)
	_player.play("Walk", BLEND * 3.0)


func animation() -> String:
	return _player.current_animation


func simulating() -> bool:
	return _simulator.is_simulating_physics()


func hips_position() -> Vector3:
	return (bones["Hips"] as Node3D).global_position


func hips_body() -> Node3D:
	return bones["Hips"] as Node3D


func head_position() -> Vector3:
	return (bones["Head"] as Node3D).global_position


func head_body() -> Node3D:
	return bones["Head"] as Node3D


func lying_pose() -> Array[Transform3D]:
	var pose: Array[Transform3D] = []
	for spec in BONES:
		pose.append((bones[spec["name"]] as Node3D).global_transform)
	return pose


func lie_as(pose: Array) -> void:
	hit = true
	settled = true
	waiting = false
	_player.pause()
	_simulator.physical_bones_start_simulation()
	for index in range(BONES.size()):
		var bone: PhysicalBone3D = bones[BONES[index]["name"]]
		bone.global_transform = pose[index]
		PhysicsServer3D.body_set_mode(bone.get_rid(), PhysicsServer3D.BODY_MODE_STATIC)


func _physics_process(delta: float) -> void:
	if hit:
		_settle(delta)
		return
	if vehicle == null:
		return
	var local := vehicle.to_local(global_position)
	var speed := absf(float(vehicle.get("speed")))
	if not frozen and (-local.z - BUMPER_REACH) / maxf(speed, 0.5) < FREEZE_SECONDS \
			and absf(local.x) < VAN_HALF_WIDTH - IN_PATH:
		_freeze()
	if frozen and (speed < 0.3 or local.z > 0.5):
		_stopped_for += delta
		if _stopped_for >= RESUME_AFTER:
			_resume()
	if not frozen and _stop_at != Vector3.INF and Vector2(global_position.x - _stop_at.x,
			global_position.z - _stop_at.z).length() <= WALK_SPEED * delta:
		global_position = Vector3(_stop_at.x, global_position.y, _stop_at.z)
		_freeze()
	if not frozen:
		global_position += _heading * WALK_SPEED * delta
		_walked += WALK_SPEED * delta
		if _walked > MAX_WALK:
			vehicle = null
			_player.play("Idle", BLEND * 3.0)
			return
	if local.z > -BUMPER_REACH and local.z < 0.5 and absf(local.x) < VAN_HALF_WIDTH \
			and speed > MIN_IMPACT:
		_go_limp(speed)


func _freeze() -> void:
	frozen = true
	_player.play("HitByVan", BLEND * 2.0)
	_player.seek(STANDING, true)
	var toward := vehicle.global_position - global_position
	var yaw := atan2(toward.x, toward.z)
	var turn := clampf(angle_difference(_model.rotation.y, yaw), -TURN_LIMIT, TURN_LIMIT)
	_turn = create_tween()
	_turn.tween_property(_model, "rotation:y", _model.rotation.y + turn, TURN_SECONDS)


func _resume() -> void:
	frozen = false
	_stopped_for = 0.0
	_stop_at = Vector3.INF
	if _turn != null:
		_turn.kill()
	_turn = create_tween()
	_turn.tween_property(_model, "rotation:y", atan2(_heading.x, _heading.z), TURN_SECONDS)
	_player.play("Walk", BLEND * 3.0)


func _go_limp(speed: float) -> void:
	hit = true
	if _turn != null:
		_turn.kill()
	_player.pause()
	_simulator.physical_bones_start_simulation()
	var forward := -vehicle.global_basis.z
	forward = Vector3(forward.x, 0.0, forward.z).normalized()
	for name: String in bones:
		var bone: PhysicalBone3D = bones[name]
		var push: Vector3 = forward * speed * float(SWEEP.get(name, 0.0)) \
			+ Vector3.UP * float(SCOOP.get(name, 0.0))
		bone.apply_central_impulse(push * bone.mass)
	struck.emit(speed)


func _settle(delta: float) -> void:
	if settled:
		return
	_window += delta
	if _window < SETTLE_WINDOW:
		return
	_window = 0.0
	var drift := 0.0
	for name: String in bones:
		var at := (bones[name] as Node3D).global_position
		if _rest_check.has(name):
			drift = maxf(drift, at.distance_to(_rest_check[name]))
		_rest_check[name] = at
	_calm = _calm + SETTLE_WINDOW if drift < SETTLE_DRIFT else 0.0
	if _calm >= SETTLE_SECONDS:
		settled = true
		for bone: PhysicalBone3D in bones.values():
			PhysicsServer3D.body_set_mode(bone.get_rid(), PhysicsServer3D.BODY_MODE_STATIC)


func _build_ragdoll() -> void:
	_simulator = PhysicalBoneSimulator3D.new()
	_simulator.name = "Ragdoll"
	_skeleton.add_child(_simulator)
	for spec in BONES:
		var index := _skeleton.find_bone(PREFIX + spec["name"])
		var rest := _skeleton.get_bone_global_rest(index)
		var end := _skeleton.get_bone_global_rest(_skeleton.find_bone(PREFIX + spec["end"]))
		var along := rest.basis.inverse() * (end.origin - rest.origin)
		var centre := along * 0.5 if spec["shape"] != Shape.BOX else Vector3.ZERO
		var bone := PhysicalBone3D.new()
		bone.name = spec["name"]
		bone.bone_name = PREFIX + spec["name"]
		bone.mass = spec["mass"]
		bone.friction = FRICTION
		bone.linear_damp = LINEAR_DAMP
		bone.angular_damp = spec.get("damp", ANGULAR_DAMP)
		bone.collision_layer = RAGDOLL_LAYER
		bone.collision_mask = WORLD_LAYER | VAN_FRONT_LAYER
		bone.body_offset = Transform3D(Basis(), centre)
		var collision := CollisionShape3D.new()
		collision.shape = _shape(spec, along.length())
		bone.add_child(collision)
		_joint(bone, spec, centre)
		_simulator.add_child(bone)
		bones[spec["name"]] = bone


func _shape(spec: Dictionary, length: float) -> Shape3D:
	match spec["shape"]:
		Shape.BOX:
			var box := BoxShape3D.new()
			box.size = spec["size"]
			return box
		Shape.SPHERE:
			var ball := SphereShape3D.new()
			ball.radius = spec["radius"]
			return ball
	var capsule := CapsuleShape3D.new()
	capsule.radius = spec["radius"]
	capsule.height = maxf(length, spec["radius"] * 2.0)
	return capsule


func _joint(bone: PhysicalBone3D, spec: Dictionary, centre: Vector3) -> void:
	if spec.has("hinge"):
		var axis: Vector3 = (spec["hinge"] as Vector3).normalized()
		var bent := _pose_bend(spec["name"], axis)
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
		bone.joint_offset = Transform3D(Basis(Vector3.UP, axis.cross(Vector3.UP), axis), -centre)
		bone.set("joint_constraints/angular_limit_enabled", true)
		bone.set("joint_constraints/angular_limit_lower", bent - spec["bend"])
		bone.set("joint_constraints/angular_limit_upper", bent + STRAIGHT)
		bone.set("joint_constraints/angular_limit_softness", LIMIT_SOFTNESS)
		bone.set("joint_constraints/angular_limit_bias", LIMIT_BIAS)
	elif spec.has("swing"):
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		bone.joint_offset = Transform3D(Basis(Vector3.UP, Vector3.LEFT, Vector3.BACK), -centre)
		for axis in ["x", "y", "z"]:
			var span: float = spec["twist"] if axis == "x" else spec["swing"]
			bone.set("joint_constraints/%s/angular_limit_enabled" % axis, true)
			bone.set("joint_constraints/%s/angular_limit_upper" % axis, span)
			bone.set("joint_constraints/%s/angular_limit_lower" % axis, -span)


func _pose_bend(name: String, axis: Vector3) -> float:
	var index := _skeleton.find_bone(PREFIX + name)
	var upper := _skeleton.get_bone_global_pose(_skeleton.get_bone_parent(index)).basis
	var u := upper.y.normalized()
	var v := _skeleton.get_bone_global_pose(index).basis.y.normalized()
	return rad_to_deg(atan2(u.cross(v).dot((upper * axis).normalized()), u.dot(v)))
