extends CharacterBody3D

signal switch_operated
signal indicator_clicked(high: bool)
signal wiper_swept
signal collided(strength: float)
signal window_operated
signal engine_started

const TURN_FLOOR_CLEARANCE: float = 0.1
const SLOPE_GRAVITY: float = 9.8
const WIPER_PARK: float = -1.55
const WIPER_SWEEP: float = 1.72
const WIPER_CYCLES: Array[float] = [0.0, 0.75, 1.1]
const IGNITION_SECONDS: float = 1.4

@export var maximum_speed: float = 19.0
@export var reverse_speed: float = 5.0
@export var acceleration: float = 3.2
@export var brake_deceleration: float = 9.0
@export var wheelbase: float = 3.3
@export var maximum_steering: float = 0.52

var occupied: bool = true
var engine_on: bool = true
var held: bool = false
var driver_door: float = 0.0
var speed: float = 0.0
var actual_speed: float = 0.0
var steering: float = 0.0
var gear: int = 1
var headlights_on: bool = true
var high_beams: bool = false
var wiper_setting: int = 1
var wiper_angle: float = WIPER_PARK
var left_window: float = 0.0
var right_window: float = 0.0
var left_window_target: float = 0.0
var right_window_target: float = 0.0
var indicator: int = 0
var hazards_on: bool = false
var indicator_lit: bool = false
var braking: bool = false
var horn_on: bool = false
var input_enabled: bool = false

var _blink_time: float = 0.0
var _wiper_time: float = 0.0
var _ignition: float = -1.0
var _wiper_half: int = 0
var _turn_started: bool = false
var _collision_cooldown: float = 0.0
var _visual: Node3D
var _turn_query := PhysicsShapeQueryParameters3D.new()
var _turn_shape_pose: Transform3D


func _ready() -> void:
	_visual = $VanPresentation
	_visual.configure(self)
	floor_snap_length = 0.4
	var collision: CollisionShape3D = $CollisionShape3D
	var physical_shape := collision.shape as BoxShape3D
	var clearance_shape := BoxShape3D.new()
	clearance_shape.size = physical_shape.size - Vector3.UP * TURN_FLOOR_CLEARANCE
	_turn_shape_pose = collision.transform
	_turn_shape_pose.origin.y += TURN_FLOOR_CLEARANCE * 0.5
	_turn_query.shape = clearance_shape
	_turn_query.exclude = [get_rid()]
	_turn_query.collision_mask = collision_mask
	_turn_query.margin = 0.005


func _physics_process(delta: float) -> void:
	_collision_cooldown = maxf(0.0, _collision_cooldown - delta)
	var active := occupied and input_enabled and not held
	var throttle := Input.get_action_strength("accelerate") if active and engine_on else 0.0
	var brake := Input.get_action_strength("brake") if active else 0.0
	var handbrake := Input.is_action_pressed("handbrake") if active else true
	braking = brake > 0.0 or handbrake
	horn_on = active and Input.is_action_pressed("horn")
	var requested_steer := Input.get_axis("steer_right", "steer_left") if active else 0.0
	steering = move_toward(steering, requested_steer, delta * 2.0)
	var speed_limit := maximum_speed if gear > 0 else reverse_speed
	var pull := slope_pull() * delta
	if braking:
		speed = move_toward(speed + pull, 0.0, brake_deceleration * delta)
	else:
		var drive_force := throttle * acceleration * gear
		var drag := 0.28 + absf(speed) * 0.035 + speed * speed * 0.001
		speed = move_toward(speed, 0.0, drag * delta)
		speed = clampf(speed + drive_force * delta + pull, -reverse_speed, speed_limit)
	var steering_limit := maximum_steering / (1.0 + absf(speed) * 0.045)
	var yaw := speed / wheelbase * tan(steering * steering_limit) * delta
	if not _rotation_blocked(yaw):
		rotate_y(yaw)
	velocity.x = -global_basis.z.x * speed
	velocity.z = -global_basis.z.z * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18.0 * delta
	var before := velocity
	move_and_slide()
	actual_speed = get_real_velocity().dot(-global_basis.z)
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if absf(collision.get_normal().y) < 0.6:
			var impact := absf(before.dot(collision.get_normal()))
			if impact > 1.0 and _collision_cooldown <= 0.0:
				collided.emit(impact)
				_collision_cooldown = 0.6
			speed *= clampf(1.0 - impact / maxf(absf(speed), 0.1), 0.0, 0.9)
	_update_accessories(delta)
	_visual.update_vehicle(delta)


func slope_pull() -> float:
	if not is_on_floor():
		return 0.0
	return SLOPE_GRAVITY * get_floor_normal().dot(-global_basis.z)


func _rotation_blocked(yaw: float) -> bool:
	if is_zero_approx(yaw):
		return false
	var next_pose := global_transform.rotated_local(Vector3.UP, yaw)
	_turn_query.transform = next_pose * _turn_shape_pose
	return not get_world_3d().direct_space_state.intersect_shape(_turn_query, 1).is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not occupied or not input_enabled or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("change_gear") and absf(speed) < 0.4:
		gear *= -1
		switch_operated.emit()
	elif event.is_action_pressed("headlights"):
		_cycle_headlights()
		switch_operated.emit()
	elif event.is_action_pressed("wipers"):
		wiper_setting = (wiper_setting + 1) % 3
		switch_operated.emit()
	elif event.is_action_pressed("indicator_left"):
		_set_indicator(-1)
	elif event.is_action_pressed("indicator_right"):
		_set_indicator(1)
	elif event.is_action_pressed("hazards"):
		hazards_on = not hazards_on
		_restart_blink()
	elif event.is_action_pressed("window_left"):
		left_window_target = 1.0 - left_window_target
		window_operated.emit()
	elif event.is_action_pressed("window_right"):
		right_window_target = 1.0 - right_window_target
		window_operated.emit()


func _cycle_headlights() -> void:
	if not headlights_on:
		headlights_on = true
	elif not high_beams:
		high_beams = true
	else:
		headlights_on = false
		high_beams = false


func _set_indicator(direction: int) -> void:
	indicator = 0 if indicator == direction else direction
	hazards_on = false
	_turn_started = false
	_restart_blink()


func _restart_blink() -> void:
	_blink_time = 0.0
	indicator_lit = indicator != 0 or hazards_on
	if indicator_lit:
		indicator_clicked.emit(true)


func switch_off() -> void:
	engine_on = false
	_ignition = -1.0
	headlights_on = false
	high_beams = false
	wiper_setting = 0


func start_engine() -> void:
	if engine_on:
		return
	engine_on = true
	_ignition = 0.0
	engine_started.emit()


func ignition_sweep() -> float:
	if _ignition < 0.0:
		return 0.0
	return sin(PI * clampf(_ignition / IGNITION_SECONDS, 0.0, 1.0))


func _update_ignition(delta: float) -> void:
	if _ignition < 0.0:
		return
	_ignition += delta
	if _ignition >= IGNITION_SECONDS:
		_ignition = -1.0
		headlights_on = true
		wiper_setting = 1


func _update_accessories(delta: float) -> void:
	_update_ignition(delta)
	left_window = move_toward(left_window, left_window_target, delta / 2.0)
	right_window = move_toward(right_window, right_window_target, delta / 2.0)
	if indicator != 0 or hazards_on:
		_blink_time += delta
		if _blink_time >= 0.45:
			_blink_time -= 0.45
			indicator_lit = not indicator_lit
			indicator_clicked.emit(indicator_lit)
	else:
		indicator_lit = false
	if indicator != 0 and not hazards_on:
		if steering * -indicator > 0.4 and absf(speed) > 1.0:
			_turn_started = true
		if _turn_started and absf(steering) < 0.12:
			indicator = 0
			_turn_started = false
	if wiper_setting > 0:
		_wiper_time += delta * WIPER_CYCLES[wiper_setting]
		var half_cycle := int(_wiper_time * 2.0)
		if half_cycle != _wiper_half:
			_wiper_half = half_cycle
			wiper_swept.emit()
		wiper_angle = WIPER_PARK + WIPER_SWEEP * (1.0 - cos(_wiper_time * TAU)) * 0.5
	else:
		wiper_angle = move_toward(wiper_angle, WIPER_PARK, delta * 2.4)


func wiper_cycles() -> float:
	return _wiper_time


func recover(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	speed = 0.0
	actual_speed = 0.0
	steering = 0.0
	gear = 1
	indicator = 0
	hazards_on = false
	_turn_started = false
	reset_physics_interpolation()


func get_camera() -> Camera3D:
	return _visual.driving_camera


func get_window_openness() -> float:
	return maxf(left_window, right_window)
