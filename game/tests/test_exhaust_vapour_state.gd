extends SceneTree
## B2, the exhaust vapour, in the running game (CHANGE-BRIEF.md §5). Its condition is the engine
## running and its game value the throttle. The test starts a drive the player's way, on foot:
## the run sheet signed and the van boarded with real E presses, so the ignition starts the
## engine; it presses the real accelerate action, pauses with real Esc presses, and ends the
## engine with "New drive". It never calls the effect's start or stop. It checks the start (a
## 0.4 s delay, then a 0.6 s ramp to idle), the mapping (amount_ratio 0.15 at idle and 0.80 at
## full throttle; amount never changes), pause, hidden, and the stop. A headless run draws
## nothing, so how the vapour looks is not checked here.

const NEAR_DOOR := Vector3(-3.4, 0.0, 0.6)
const AMOUNT := 96

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _fx: Node3D
var _plume: GPUParticles3D
var _hud: CanvasLayer
var _driver: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-exhaust-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_fx = _van.get_node("VanPresentation").get("particles")
	_plume = _fx.exhaust
	_hud = _app.get_node("DrivingHud")
	_driver = _app.get("driver")
	await process_frame
	_hud.resume_requested.emit()
	await _seconds(0.5)
	_check(not _van.engine_on and not _plume.emitting and is_zero_approx(_plume.amount_ratio),
		"On foot at the office, with the engine off, there is no exhaust")
	await _check_ignition()
	await _check_throttle()
	await _check_pause()
	await _check_hidden()
	await _check_switch_off()
	_finish()


func _check_ignition() -> void:
	await _tap("interact")
	await _seconds(1.4)
	await _tap("interact")
	await _seconds(0.3)
	_driver.global_position = _van.to_global(NEAR_DOOR)
	await _seconds(0.3)
	await _tap("interact")
	await _until(func() -> bool: return _van.engine_on, 15.0)
	var started: float = _van.clock
	var quiet := true
	while _van.clock - started < 0.35:
		quiet = quiet and not _plume.emitting
		await physics_frame
	_check(_van.engine_on and quiet,
		"Signing the run sheet and boarding with E starts the engine; the plume waits 0.4 s")
	await _until(func() -> bool: return _plume.emitting, 0.3)
	await _seconds(0.25)
	var rising := _plume.amount_ratio
	await _seconds(0.6)
	_check(rising > 0.0 and rising < 0.15 and is_equal_approx(_plume.amount_ratio, 0.15),
		"then ramps up over 0.6 s to idle (%.2f on the way, %.2f at idle)" % [rising,
		_plume.amount_ratio])


func _check_throttle() -> void:
	Input.action_press("accelerate")
	await _seconds(0.8)
	var full := _plume.amount_ratio
	Input.action_release("accelerate")
	Input.action_press("brake")
	await _seconds(0.8)
	Input.action_release("brake")
	var idle := _plume.amount_ratio
	_check(is_equal_approx(full, 0.8) and is_equal_approx(idle, 0.15),
		"The real accelerate key drives amount_ratio from 0.15 at idle to 0.80 at full throttle " +
		"and back (%.2f, %.2f)" % [full, idle])
	_check(_plume.amount == AMOUNT and _plume.emitting,
		"amount stays %d throughout, so the plume never reallocates or restarts" % AMOUNT)


func _check_pause() -> void:
	var before := _plume.amount_ratio
	await _key(KEY_ESCAPE)
	Input.action_press("accelerate")
	await _seconds(1.0)
	var held := paused and not _plume.can_process() \
		and is_equal_approx(_plume.amount_ratio, before)
	Input.action_release("accelerate")
	_check(held, "Esc pauses it: the plume freezes, and the throttle cannot change it")
	await _key(KEY_ESCAPE)
	await _seconds(0.2)
	_check(not paused and _plume.can_process() and _plume.emitting,
		"Esc again resumes it from where it was, not from a new ignition")


func _check_hidden() -> void:
	var vapour := _plume.get_parent() as Node3D
	vapour.visible = false
	await _seconds(0.2)
	_check(not _plume.emitting and is_zero_approx(_plume.amount_ratio),
		"Hidden, the plume stops emitting")
	vapour.visible = true
	await _seconds(0.15)
	var rising := _plume.amount_ratio
	await _seconds(0.7)
	_check(_plume.emitting and rising > 0.0 and rising < 0.15
		and is_equal_approx(_plume.amount_ratio, 0.15),
		"Shown again with the engine running, it ramps back up (%.2f, then %.2f)" % [rising,
		_plume.amount_ratio])


func _check_switch_off() -> void:
	_hud.restart_requested.emit()
	await _seconds(0.2)
	_check(not _van.engine_on and not _plume.emitting and is_zero_approx(_plume.amount_ratio)
		and _plume.amount == AMOUNT,
		"New drive switches the engine off and the plume stops at once")


func _seconds(duration: float) -> void:
	for frame in range(roundi(duration * 60.0)):
		await physics_frame


func _until(condition: Callable, limit: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await physics_frame
		waited += 1.0 / 60.0


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _finish() -> void:
	print("EXHAUST VAPOUR STATE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The exhaust vapour state test finished within 120 s of game time")
	quit(1)
