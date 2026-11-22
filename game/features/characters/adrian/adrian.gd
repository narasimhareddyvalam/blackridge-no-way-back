extends Node3D
## Adrian Vale (Mission 3's step 7, docs/PHASE_BRIEF.md, 2026-11-22, #359-#360): Rocketbox's
## Business_Male_03 (MIT, `adrian.glb`), a man in his forties in a charcoal suit, with Rocketbox's
## angry idle, an agitated talk and a walk. He walks where he is sent (`walk_to`), talks (`talk`),
## draws his pistol one-handed at a man (`draw_at`: his right arm up by IK, the pistol, the men's
## own, in his hand pointing at him), and, shot, lies on his back where he stood, the pistol fallen
## ahead of his feet, where his arm pointed (`fall`; no gore: the scene shows only the pistol and
## his shoes).
## The node faces its +Z, as the Rocketbox models do.

const MODEL = preload("adrian.glb")
const PISTOL = preload("res://features/weapons/pistol/pistol.glb")
const AimArms = preload("res://features/weapons/pistol/aim_arms.gd")
const WALK_SPEED := 1.25
const SHOULDER := Vector3(-0.19, 1.45, 0.0)
const REACH := 0.58
const DRAW_SECONDS := 0.45
const BLEND := 0.3
const LYING := 0.11

var drawn := false
var down := false
var _model: Node3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _arm := TwoBoneIK3D.new()
var _target := Node3D.new()
var _pole := Node3D.new()
var _pistol: Node3D
var _to := Vector3.INF
var _aim_at := Vector3.INF
var _raise := 0.0


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for point: Node3D in [_target, _pole]:
		point.top_level = true
		add_child(point)
	_arm.name = "DrawnArm"
	_arm.set_setting_count(1)
	_arm.set_root_bone_name(0, "Bip01 R UpperArm")
	_arm.set_middle_bone_name(0, "Bip01 R Forearm")
	_arm.set_end_bone_name(0, "Bip01 R Hand")
	_arm.set_extend_end_bone(0, false)
	_arm.active = false
	_arm.influence = 0.0
	_skeleton.add_child(_arm)
	_arm.set_target_node(0, _arm.get_path_to(_target))
	_arm.set_pole_node(0, _arm.get_path_to(_pole))
	_pistol = Node3D.new()
	_pistol.name = "Pistol"
	_pistol.top_level = true
	add_child(_pistol)
	var gun := PISTOL.instantiate() as Node3D
	_pistol.add_child(gun)
	var turn := Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
	gun.transform = Transform3D(turn, -(turn * AimArms.GRIP_IN_MODEL))
	_pistol.visible = false
	reset()


## Standing at `at` facing `face`, as before the scene: no pistol out, on his feet.
func place(at: Vector3, face: Vector3) -> void:
	reset()
	global_position = at
	_face(face)


func reset() -> void:
	drawn = false
	down = false
	_to = Vector3.INF
	_aim_at = Vector3.INF
	_raise = 0.0
	_model.rotation = Vector3.ZERO
	_model.position = Vector3.ZERO
	_pistol.visible = false
	_player.play("Idle", BLEND)
	_player.speed_scale = 1.0


func walk_to(at: Vector3) -> void:
	_to = at


func talk(on: bool) -> void:
	if not down and _to == Vector3.INF:
		_player.play("Talk" if on else "Idle", BLEND)


## His pistol out at `point`, his arm straight to it.
func draw_at(point: Vector3) -> void:
	drawn = true
	_aim_at = point
	_face(point)
	_player.play("Idle", BLEND)


## Shot: on his back where he stood, the pistol on the ground by his right hand.
func fall() -> void:
	down = true
	drawn = false
	_raise = 0.0
	_arm.influence = 0.0
	_arm.active = false
	_to = Vector3.INF
	_player.pause()
	_model.rotation.x = -PI / 2.0
	_model.position = Vector3(0.0, LYING, 0.0)
	var right := -global_basis.x
	_pistol.visible = true
	_pistol.global_transform = Transform3D(Basis(Vector3.UP, rotation.y + 2.2)
		* Basis(Vector3.RIGHT, PI / 2.0), global_position + right * 0.35 + global_basis.z * 0.45
		+ Vector3.UP * 0.02)


func _face(point: Vector3) -> void:
	var to := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if to.length() > 0.01:
		rotation.y = atan2(to.x, to.z)


func _physics_process(delta: float) -> void:
	if down:
		return
	if _to != Vector3.INF:
		var to := Vector3(_to.x - global_position.x, 0.0, _to.z - global_position.z)
		if to.length() < 0.05:
			_to = Vector3.INF
			_player.play("Idle", BLEND)
			_player.speed_scale = 1.0
		else:
			_face(_to)
			global_position += to.normalized() * minf(to.length(), WALK_SPEED * delta)
			if _player.current_animation != "Walk":
				_player.play("Walk", BLEND)
	_raise = move_toward(_raise, 1.0 if drawn else 0.0, delta / DRAW_SECONDS)
	_arm.influence = _raise
	_arm.active = _raise > 0.0
	_pistol.visible = _raise > 0.5 or down
	if drawn and _aim_at != Vector3.INF:
		var shoulder := global_transform * SHOULDER
		var ahead := (_aim_at - shoulder).normalized()
		_target.global_position = shoulder + ahead * REACH
		_pole.global_position = global_transform * Vector3(-0.55, 1.0, -0.1)
		_pistol.global_transform = Transform3D(Basis.looking_at(-ahead, Vector3.UP),
			_target.global_position + ahead * 0.07)
