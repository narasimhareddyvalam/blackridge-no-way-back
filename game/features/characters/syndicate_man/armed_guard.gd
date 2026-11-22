extends Node3D
## One of Adrian's men at the airfield (Mission 3's step 6, docs/PHASE_BRIEF.md, 2026-11-22,
## #359-#360; GAME_DESIGN §8's one guard archetype, "patrol/alert/chase/attack"): a stand-in, as
## the compound's patrols are (D6), whose behaviour Assignment 9 replaces, not his places. The
## model is bumstrum's "guard" (CC BY 4.0, `syndicate_man.glb`) with Ethan's own Mixamo walk, run
## and idle, and Mixamo's fall when he is put down.
##
## patrol: he walks his `route` at a patrol's pace, waiting at each end. alert: he has caught
## sight of Ethan and stops, turning to him, for NOTICE seconds. chase: he runs to where Ethan was
## last seen or heard, and searches there a while before he walks back. attack: Ethan in sight and
## in range, he stands, both hands on his pistol, and fires every FIRE_EVERY seconds, hitting more
## often the nearer Ethan is and the stiller he stands. He sees SIGHT metres ahead, HALF_ANGLE
## either side, where nothing solid stands between (`sees`); he hears a shot within HEARING. A
## round to the body takes BODY of his health, to the head all of it (`shot`); at nothing he falls
## and lies there (`down`), and no round stops at him again. The node faces its -Z.

signal fired_at(hit: bool, from: Vector3)

const MODEL = preload("syndicate_man.glb")
const AimArms = preload("res://features/weapons/pistol/aim_arms.gd")
const SHOT = preload("res://features/audio/last_run/pistol_shot.wav")
## The layer a round stops at him on (`handgun.gd`'s STOPS).
const TARGETS := 16
const SOLID := 1 | 2
const EYE := 1.62
const SHOULDERS := 1.42
const HEAD_FROM := 1.5
const HEALTH := 100.0
const BODY := 50.0
const SIGHT := 25.0
const HALF_ANGLE := deg_to_rad(60.0)
## A pistol shot carries over the whole airfield, as it does outdoors.
const HEARING := 150.0
const NOTICE := 0.5
const WALK_SPEED := 1.4
const RUN_SPEED := 3.6
const WALK_CLIP := 1.738
const RUN_CLIP := 4.943
const FIRE_RANGE := 18.0
const FIRE_EVERY := 1.1
const FIRST_SHOT := 0.7
const LOST_AFTER := 1.2
const SEARCH := 5.0
const TURN_RATE := deg_to_rad(240.0)
const BLEND := 0.2
const WAIT := 2.5

var model_path := MODEL.resource_path
var start := Transform3D.IDENTITY
var route: Array[Vector3] = []
var state := "patrol"
var health := HEALTH
## Who he looks for: Ethan on foot (`target_active` says whether he is out where he can be seen).
var target: Node3D
var target_active: Callable
var last_known := Vector3.INF
var shots_fired := 0
var _leg := 0
var _step := 1
var _wait := 0.0
var _timer := 0.0
var _unseen := 0.0
var _yaw := 0.0
var _model: Node3D
var _player: AnimationPlayer
var _body: AnimatableBody3D
var _aim: Node3D
var _sound: AudioStreamPlayer3D
var _flash: OmniLight3D
var _flash_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Model"
	_model.rotation.y = PI
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_aim = AimArms.new()
	_aim.name = "Aim"
	_model.add_child(_aim)
	_aim.call("setup", skeleton, SHOULDERS)
	_body = AnimatableBody3D.new()
	_body.name = "Hit"
	_body.sync_to_physics = false
	_body.collision_layer = TARGETS
	_body.collision_mask = 0
	_body.set_meta("guard", self)
	add_child(_body)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	_body.add_child(shape)
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = SHOT
	_sound.unit_size = 30.0
	add_child(_sound)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.78, 0.45)
	_flash.light_energy = 0.0
	_flash.omni_range = 4.0
	add_child(_flash)


## Where he starts and the points he walks between.
func setup(at: Transform3D, points: Array[Vector3]) -> void:
	start = at
	route = points.duplicate()
	reset()


## Back at his post, whole, on his round.
func reset() -> void:
	global_transform = start
	_yaw = start.basis.get_euler().y
	health = HEALTH
	state = "patrol"
	last_known = Vector3.INF
	_leg = 0
	_step = 1
	_wait = WAIT
	_timer = 0.0
	_unseen = 0.0
	shots_fired = 0
	_rng.seed = hash(String(name))
	_aim.set("wanted", 0.0)
	_aim.set("influence", 0.0)
	(_body.get_child(0) as CollisionShape3D).set_deferred("disabled", false)
	_play("Idle")


func facing() -> Vector3:
	return -global_basis.z


## Whether he sees `point`: near enough, inside his cone, nothing solid between.
func sees(point: Vector3) -> bool:
	if state == "down":
		return false
	var eye := global_position + Vector3.UP * EYE
	var to := point - eye
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() > SIGHT or flat.length() < 0.01:
		return false
	if facing().angle_to(flat.normalized()) > HALF_ANGLE:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, point, SOLID)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## A round from `from` stopped at him at `point`: the head or the body.
func shot(point: Vector3, from: Vector3) -> void:
	if state == "down":
		return
	health -= HEALTH if point.y > global_position.y + HEAD_FROM else BODY
	if health <= 0.0:
		_fall()
		return
	last_known = target.global_position if target != null else from
	state = "attack" if _can_shoot() else "chase"
	_timer = FIRST_SHOT


## A shot heard from `at`.
func heard(at: Vector3) -> void:
	if state in ["down", "attack"]:
		return
	if Vector2(at.x - global_position.x, at.z - global_position.z).length() > HEARING:
		return
	last_known = at
	state = "chase"
	_timer = 0.0


func _fall() -> void:
	health = 0.0
	state = "down"
	_aim.set("wanted", 0.0)
	_aim.set("influence", 0.0)
	(_body.get_child(0) as CollisionShape3D).set_deferred("disabled", true)
	_player.speed_scale = 1.0
	_player.play("Fall", BLEND)


func _physics_process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash.light_energy = 0.0
	if state == "down":
		return
	var seen := _sees_target()
	if seen:
		last_known = target.global_position
		_unseen = 0.0
	else:
		_unseen += delta
	match state:
		"patrol":
			_patrol(delta)
			if seen:
				state = "alert"
				_timer = NOTICE
		"alert":
			_play("Idle")
			_turn_toward(last_known, delta)
			_timer -= delta
			if not seen:
				state = "chase"
			elif _timer <= 0.0:
				state = "attack" if _can_shoot() else "chase"
				_timer = FIRST_SHOT
		"chase":
			_chase(delta, seen)
		"attack":
			_attack(delta, seen)
	_aim.set("wanted", 1.0 if state == "attack" else 0.0)
	if state == "attack" and target != null:
		var to := target.global_position + Vector3.UP * 1.2 - (global_position
			+ Vector3.UP * SHOULDERS)
		_aim.set("pitch", atan2(to.y, Vector2(to.x, to.z).length()))


func _sees_target() -> bool:
	if target == null or (target_active.is_valid() and not bool(target_active.call())):
		return false
	return sees(target.global_position + Vector3.UP * 1.2)


func _can_shoot() -> bool:
	return target != null and _flat_to(target.global_position) <= FIRE_RANGE \
		and _sees_target()


func _patrol(delta: float) -> void:
	if route.is_empty():
		_play("Idle")
		return
	if _wait > 0.0:
		_wait -= delta
		_play("Idle")
		return
	var point := route[_leg]
	if _flat_to(point) < 0.3:
		_wait = WAIT
		if _leg + _step < 0 or _leg + _step >= route.size():
			_step = -_step
		_leg += _step
		return
	_move_toward(point, WALK_SPEED, delta)
	_play("Walk", WALK_SPEED / WALK_CLIP)


func _chase(delta: float, seen: bool) -> void:
	if seen and _can_shoot():
		state = "attack"
		_timer = FIRST_SHOT
		return
	if last_known == Vector3.INF:
		state = "patrol"
		return
	if _flat_to(last_known) > 1.0:
		_move_toward(last_known, RUN_SPEED, delta)
		_play("Run", RUN_SPEED / RUN_CLIP)
		_timer = 0.0
		return
	_play("Idle")
	_timer += delta
	_yaw += delta * 0.8
	rotation.y = _yaw
	if _timer > SEARCH:
		last_known = Vector3.INF
		state = "patrol"
		_leg = 0
		_step = 1


func _attack(delta: float, seen: bool) -> void:
	_play("Idle")
	if not seen and _unseen > LOST_AFTER:
		state = "chase"
		return
	if target == null or _flat_to(target.global_position) > FIRE_RANGE + 3.0:
		state = "chase"
		return
	_turn_toward(target.global_position, delta)
	_timer -= delta
	if _timer <= 0.0 and seen:
		_timer = FIRE_EVERY
		_fire()


## One round at Ethan: the nearer and stiller he is, the likelier it hits.
func _fire() -> void:
	shots_fired += 1
	var muzzle: Vector3 = _aim.call("muzzle")
	_flash.global_position = muzzle
	_flash.light_energy = 3.0
	_flash_left = 0.05
	_sound.global_position = muzzle
	_sound.play()
	var distance := _flat_to(target.global_position)
	var chance := clampf(0.6 - distance * 0.025, 0.15, 0.55)
	var moving := target is CharacterBody3D and Vector2((target as CharacterBody3D).velocity.x,
		(target as CharacterBody3D).velocity.z).length() > 2.5
	if moving:
		chance -= 0.15
	fired_at.emit(_rng.randf() < chance, muzzle)


func _move_toward(point: Vector3, speed: float, delta: float) -> void:
	_turn_toward(point, delta)
	var to := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	global_position += to.normalized() * minf(speed * delta, to.length())


func _turn_toward(point: Vector3, delta: float) -> void:
	var to := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if to.length() < 0.01:
		return
	var wanted := atan2(-to.x, -to.z)
	_yaw += clampf(angle_difference(_yaw, wanted), -TURN_RATE * delta, TURN_RATE * delta)
	rotation.y = _yaw


func _flat_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _play(clip: String, rate: float = 1.0) -> void:
	if _player.current_animation != clip:
		_player.play(clip, BLEND)
	_player.speed_scale = rate
