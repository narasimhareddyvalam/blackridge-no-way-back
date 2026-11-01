extends Node3D

signal struck(speed: float)

const MODEL = preload("res://features/characters/pedestrian/pedestrian.glb")
const WALK_SPEED := 1.705
const IMPACT := 2.6
const BLEND := 0.08
const THROW_BASE := 0.8
const THROW_PER_SPEED_SQUARED := 0.16
const THROW_LIMITS := Vector2(1.5, 12.0)
const THROW_TIME := Vector2(0.5, 1.6)
const BUMPER := Vector2(-2.6, 0.5)
const REACH := 1.7

var vehicle: Node3D
var hit: bool = false
var _player: AnimationPlayer
var _model: Node3D
var _heading := Vector3.ZERO


func _ready() -> void:
	_model = MODEL.instantiate() as Node3D
	_model.name = "Pedestrian"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_player.play("Walk")


func step_out(from: Vector3, toward: Vector3, van: Node3D) -> void:
	vehicle = van
	global_position = from
	_heading = Vector3(toward.x - from.x, 0.0, toward.z - from.z).normalized()
	_model.rotation.y = atan2(_heading.x, _heading.z)


func animation() -> String:
	return _player.current_animation


func _physics_process(delta: float) -> void:
	if hit or vehicle == null:
		return
	global_position += _heading * WALK_SPEED * delta
	var local := vehicle.to_local(global_position)
	if local.z > BUMPER.x and local.z < BUMPER.y and absf(local.x) < REACH:
		_struck(-vehicle.global_basis.z, absf(float(vehicle.get("speed"))))


func _struck(direction: Vector3, speed: float) -> void:
	hit = true
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	var facing := Vector3.UP.cross(flat)
	_model.rotation.y = atan2(facing.x, facing.z)
	_player.play("HitByVan", BLEND)
	_player.seek(IMPACT, true)
	var throw := clampf(THROW_BASE + speed * speed * THROW_PER_SPEED_SQUARED, THROW_LIMITS.x,
		THROW_LIMITS.y)
	var seconds := clampf(throw / maxf(speed, 3.0) * 1.2, THROW_TIME.x, THROW_TIME.y)
	var fly := create_tween()
	fly.tween_property(self, "global_position", global_position + flat * throw, seconds
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	struck.emit(speed)
