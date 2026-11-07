extends SceneTree
## A1, the wiper flick, in the running game (CHANGE-BRIEF.md §2). The wipers are switched with
## real presses of the wipers key and the flick follows the van's own wiper_swept signal; the
## test never calls the effect's trigger. It checks when the flick fires (every top turn, never on
## load, never with the wipers off, never at park), where (the driver's blade tip), the overlap
## rule (two bursts alive at once on fast wipers, neither cut short), and freeing the van in the
## middle of a burst. A headless run draws nothing, so how the flick looks is not checked here.

const VAN_SCENE := "res://features/vehicles/freight_van/freight_van.tscn"
const FLICK_LIFE := 1.2

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _fx: Node3D
var _scratch: String
var _top_turn: float = 0.0
var _tops: int = 0
var _parks: int = 0
var _worst_place: float = 0.0
var _started: Dictionary = {}
var _shortest_life: float = INF


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-flick-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_fx = _van.get_node("VanPresentation").get("particles")
	var constants := (_van.get_script() as GDScript).get_script_constant_map()
	_top_turn = float(constants["WIPER_PARK"]) + float(constants["WIPER_SWEEP"]) * 0.5
	await process_frame
	_app.call("_resume")
	await _seconds(0.15)
	_check(_fx.flicks_fired == 0 and _fx.flicks.size() == 2,
		"Nothing fires as the scene loads (%d flicks in 0.15 s), and a pool of two bursts waits"
		% _fx.flicks_fired)
	_van.wiper_swept.connect(_on_swept)
	for flick: Node3D in _fx.flicks:
		var spray := flick.get_node("FineSpray") as GPUParticles3D
		spray.finished.connect(_on_spray_finished.bind(flick))
	await _check_off()
	await _check_fast()
	_app.queue_free()
	await process_frame
	await _check_freed()
	_finish()


func _check_off() -> void:
	await _tap("wipers")
	await _tap("wipers")
	var before: int = _fx.flicks_fired
	await _seconds(3.0)
	_check(_van.wiper_setting == 0 and _fx.flicks_fired == before,
		"With the wipers switched off by two presses of the wipers key, nothing fires in 3 s")


func _check_fast() -> void:
	await _tap("wipers")
	await _tap("wipers")
	_tops = 0
	_parks = 0
	_worst_place = 0.0
	var before: int = _fx.flicks_fired
	var most_alive := 0
	for frame in range(360):
		await physics_frame
		most_alive = maxi(most_alive, _fx.flicks_alive())
	var fired: int = _fx.flicks_fired - before
	_check(_van.wiper_setting == 2 and _tops >= 5 and fired == _tops,
		"On fast wipers every top turn fires one flick (%d top turns, %d flicks in 6 s)" % [
		_tops, fired])
	_check(_parks >= 5 and fired == _tops,
		"The turns at park fire nothing (%d park turns)" % _parks)
	_check(_worst_place < 0.01,
		"Each flick starts at the driver's blade tip (worst %.1f mm away)"
		% (_worst_place * 1000.0))
	_check(most_alive == 2 and _fx.flicks_missed == 0,
		"Overlap: the next top turn, 0.91 s later, starts a second burst while the first is " +
		"still alive; at most two are alive and none is missed (%d alive at most)" % most_alive)
	_check(_shortest_life >= FLICK_LIFE - 0.05 and _shortest_life < INF,
		"No burst is cut short: each one's spray lives its full %.1f s (shortest %.2f s)" % [
		FLICK_LIFE, _shortest_life])


func _check_freed() -> void:
	var van := (load(VAN_SCENE) as PackedScene).instantiate() as CharacterBody3D
	root.add_child(van)
	var fx: Node3D = van.get_node("VanPresentation").get("particles")
	await _until(func() -> bool: return fx.flicks_alive() > 0, 3.0)
	var flicks: Array = fx.flicks.duplicate()
	var alive: int = fx.flicks_alive()
	van.queue_free()
	await _seconds(0.3)
	var kept := flicks.filter(func(flick: Variant) -> bool: return is_instance_valid(flick))
	_check(alive > 0 and kept.size() == flicks.size(),
		"Freeing the van in the middle of a flick leaves its bursts in the world to finish " +
		"(%d of %d still there 0.3 s later)" % [kept.size(), flicks.size()])
	await _seconds(1.5)
	var left := flicks.filter(func(flick: Variant) -> bool: return is_instance_valid(flick))
	_check(left.is_empty(),
		"and frees them once their longest life has passed (%d left)" % left.size())


func _on_swept() -> void:
	if _van.wiper_setting == 0:
		return
	if _van.wiper_angle < _top_turn:
		_parks += 1
		return
	_tops += 1
	var flick: Node3D = _fx.last_flick
	if flick:
		_worst_place = maxf(_worst_place, flick.global_position.distance_to(_fx.tip()))
		_started[flick] = _van.clock


func _on_spray_finished(flick: Node3D) -> void:
	if _started.has(flick):
		_shortest_life = minf(_shortest_life, _van.clock - float(_started[flick]))


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


func _finish() -> void:
	print("WIPER FLICK STATE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The wiper flick state test finished within 100 s of game time")
	quit(1)
