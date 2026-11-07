extends Node3D
## The van's particle effects (CHANGE-BRIEF.md §2, §3, §5): the wiper flick, the roof spill and
## the exhaust vapour. This node places, starts and stops them from what the van does and never
## writes the van's state. Each effect's look lives in its scene in game/effects/.

const WiperFlick = preload("res://effects/wiper_flick.tscn")
const RoofSpill = preload("res://effects/roof_spill.tscn")
const ExhaustVapour = preload("res://effects/exhaust_vapour.tscn")
const FLICK_POOL := 2
const FLICK_LIFE := 1.35
const SPILL_SPEED := 8.0
const SPILL_DECELERATION := 6.0
const SPILL_TICKS := 2
const ROOF_REFILL := 20.0
const ROOF_LIP := Vector3(0.0, 2.206, -1.038)
## No tailpipe is modelled; this place is an assumption (CHANGE-BRIEF.md revision 2).
const TAILPIPE := Vector3(-0.6, 0.46, 2.85)
const IDLE_RATIO := 0.15
const THROTTLE_RATIO := 0.65
const IGNITION_DELAY := 0.4
const IGNITION_RAMP := 0.6
const THROTTLE_FOLLOW := 0.6

var vehicle: CharacterBody3D
var flicks: Array[Node3D] = []
var flicks_fired: int = 0
var flicks_missed: int = 0
var last_flick: Node3D
var spill: Node3D
var spills_fired: int = 0
var spills_ignored: int = 0
var roof_refill: float = 0.0
var exhaust: GPUParticles3D

var _wiper: Node3D
var _tip_reach: float = 0.0
var _top_turn: float = 0.0
var _flick_alive: Array[bool] = []
var _spill_alive: bool = false
var _was_braking: bool = false
var _brake_pending: bool = false
var _hard_ticks: int = 0
var _last_speed: float = 0.0
var _engine_time: float = 0.0
var _ramp: float = 0.0
var _throttle: float = 0.0


func setup(van: CharacterBody3D, wiper: Node3D, tip_reach: float, body: Node3D) -> void:
	vehicle = van
	_wiper = wiper
	_tip_reach = tip_reach
	var constants := (van.get_script() as GDScript).get_script_constant_map()
	_top_turn = float(constants["WIPER_PARK"]) + float(constants["WIPER_SWEEP"]) * 0.5
	van.wiper_swept.connect(_on_wiper_swept)
	for index in range(FLICK_POOL):
		var flick := WiperFlick.instantiate() as Node3D
		flick.name = "WiperFlick%d" % index
		van.get_parent().add_child.call_deferred(flick)
		flicks.append(flick)
		_flick_alive.append(false)
		var spray := flick.get_node("FineSpray") as GPUParticles3D
		spray.finished.connect(_flick_finished.bind(index))
	spill = RoofSpill.instantiate() as Node3D
	spill.position = ROOF_LIP
	body.add_child(spill)
	(spill.get_node("RoofBeads") as GPUParticles3D).finished.connect(_spill_finished)
	var vapour := ExhaustVapour.instantiate() as Node3D
	vapour.position = TAILPIPE
	body.add_child(vapour)
	exhaust = vapour.get_node("ExhaustPlume") as GPUParticles3D
	_last_speed = absf(van.actual_speed)


func tip() -> Vector3:
	return _wiper.global_transform * Vector3(0.0, _tip_reach, 0.0)


func flicks_alive() -> int:
	return _flick_alive.count(true)


func spill_alive() -> bool:
	return _spill_alive


func roof_water_ready() -> bool:
	return roof_refill <= 0.0 and not _spill_alive


func _physics_process(delta: float) -> void:
	if vehicle == null:
		return
	_watch_brakes(delta)
	_drive_exhaust(delta)


func _exit_tree() -> void:
	for flick in flicks:
		if is_instance_valid(flick) and flick.is_inside_tree():
			get_tree().create_timer(FLICK_LIFE, false).timeout.connect(flick.queue_free)


func _on_wiper_swept() -> void:
	if not is_instance_valid(_wiper) or vehicle.wiper_setting == 0 \
			or vehicle.wiper_angle < _top_turn:
		return
	var index := _flick_alive.find(false)
	if index < 0:
		flicks_missed += 1
		push_warning("Wiper flick missed: both bursts are still alive")
		return
	var flick := flicks[index]
	if not flick.is_inside_tree():
		return
	flick.global_transform = Transform3D(global_basis, tip())
	for emitter: GPUParticles3D in [flick.get_node("BigDrops"), flick.get_node("FineSpray")]:
		emitter.restart()
	_flick_alive[index] = true
	last_flick = flick
	flicks_fired += 1


func _flick_finished(index: int) -> void:
	_flick_alive[index] = false


func _spill_finished() -> void:
	_spill_alive = false


func _watch_brakes(delta: float) -> void:
	roof_refill = maxf(roof_refill - delta, 0.0)
	var speed := absf(vehicle.actual_speed)
	var slowing := (_last_speed - speed) / delta
	var braking: bool = vehicle.braking
	if braking and not _was_braking:
		_brake_pending = _last_speed >= SPILL_SPEED
		_hard_ticks = 0
	if _brake_pending and braking:
		_hard_ticks = _hard_ticks + 1 if slowing >= SPILL_DECELERATION else 0
		_brake_pending = _hard_ticks > 0
		if _hard_ticks >= SPILL_TICKS:
			_brake_pending = false
			_hard_brake()
	_was_braking = braking
	_last_speed = speed


func _hard_brake() -> void:
	if not roof_water_ready():
		spills_ignored += 1
		return
	for emitter: GPUParticles3D in [spill.get_node("RoofStreams"), spill.get_node("RoofBeads")]:
		emitter.restart()
	_spill_alive = true
	roof_refill = ROOF_REFILL
	spills_fired += 1


func _drive_exhaust(delta: float) -> void:
	if not vehicle.engine_on or not exhaust.is_visible_in_tree():
		exhaust.emitting = false
		exhaust.amount_ratio = 0.0
		_ramp = 0.0
		_engine_time = IGNITION_DELAY if vehicle.engine_on else 0.0
		return
	_engine_time += delta
	if _engine_time < IGNITION_DELAY:
		return
	_ramp = move_toward(_ramp, 1.0, delta / IGNITION_RAMP)
	_throttle = move_toward(_throttle, clampf(vehicle.throttle, 0.0, 1.0), delta / THROTTLE_FOLLOW)
	exhaust.amount_ratio = (IDLE_RATIO + THROTTLE_RATIO * _throttle) * _ramp
	exhaust.emitting = true
