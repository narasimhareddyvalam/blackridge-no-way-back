extends SceneTree
## A2, the roof spill, in the running game (CHANGE-BRIEF.md §3 and revision 3). The van is
## driven on the flat valley road with real throttle and brake input, and the lane keeper steers;
## the test never calls the effect's trigger. It checks when the spill fires (a new hard brake
## from 8 m/s or more; never on load, at rest, below 8 m/s, coasting, or while the brake stays
## held), where (the roof lip, moving with the van), the ignore rule (a second hard brake inside
## the first spill's life, or within the 20 s refill, does nothing), and freeing the van. A
## headless run draws nothing, so how the spill looks is not checked here.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const STRAIGHT := 960
const LANE := 1.25
const ROOF_LIP := Vector3(0.0, 2.206, -1.038)

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _fx: Node3D
var _road: RefCounted
var _keeper: RefCounted
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(150.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-spill-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_fx = _van.get_node("VanPresentation").get("particles")
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	await _seconds(1.0)
	_check(_fx.spills_fired == 0 and _fx.roof_water_ready(),
		"Nothing spills as the scene loads, and the roof holds water")
	_place(STRAIGHT)
	await _seconds(0.5)
	await _brake(0.5)
	_check(_fx.spills_fired == 0, "Braking at rest spills nothing")
	await _check_slow_and_coasting()
	await _check_hard_brake()
	await _check_refill()
	await _check_freed()
	_finish()


func _check_slow_and_coasting() -> void:
	await _drive_to(5.0)
	var slow := absf(_van.actual_speed)
	await _brake(1.5)
	_check(_fx.spills_fired == 0, "A hard brake below 8 m/s spills nothing (%.1f m/s)" % slow)
	await _drive_to(11.0)
	Input.action_release("accelerate")
	await _steer_for(1.0)
	_check(_fx.spills_fired == 0, "Coasting from %.1f m/s spills nothing" % absf(_van.actual_speed))


func _check_hard_brake() -> void:
	await _drive_to(12.0)
	var speed := absf(_van.actual_speed)
	Input.action_press("brake")
	await _steer_for(0.1)
	var streams := _fx.spill.get_node("RoofStreams") as GPUParticles3D
	var beads := _fx.spill.get_node("RoofBeads") as GPUParticles3D
	_check(_fx.spills_fired == 1 and streams.emitting and beads.emitting,
		"A hard brake from %.1f m/s spills the roof water within 0.1 s (%d spill)" % [speed,
		_fx.spills_fired])
	var body := _fx.spill.get_parent() as Node3D
	_check(_fx.spill.position.is_equal_approx(ROOF_LIP) and body.is_ancestor_of(_fx.spill)
		and _van.is_ancestor_of(body),
		"It pours from the roof lip, %s in the van's frame, and moves with the van" % ROOF_LIP)
	await _steer_for(0.15)
	Input.action_release("brake")
	await _steer_for(0.15)
	var again := absf(_van.actual_speed)
	Input.action_press("brake")
	await _steer_for(0.15)
	_check(_fx.spills_fired == 1 and _fx.spills_ignored == 1 and _fx.spill_alive(),
		"A second hard brake from %.1f m/s, inside the first spill's life, is ignored" % again)
	await _steer_for(1.5)
	_check(_fx.spills_fired == 1, "Holding the brake to a stop spills nothing more")
	Input.action_release("brake")


func _check_refill() -> void:
	await _drive_to(11.0)
	await _brake(1.5)
	_check(_fx.spills_fired == 1 and _fx.spills_ignored == 2 and _fx.roof_refill > 0.0,
		"Another hard brake within the 20 s refill is ignored (%.0f s of refill left)"
		% _fx.roof_refill)
	await _until(func() -> bool: return _fx.roof_water_ready(), 25.0)
	await _drive_to(11.0)
	await _brake(0.3)
	_check(_fx.spills_fired == 2, "Once the roof has refilled, the next hard brake spills again")


func _check_freed() -> void:
	var spill: Node3D = _fx.spill
	_app.queue_free()
	await _seconds(0.5)
	_check(not is_instance_valid(spill),
		"Freeing the van in the middle of a spill frees the spill with it, without errors")


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * LANE + Vector3.UP * 0.1))
	_keeper = LaneKeeper.new(_road, index)


func _drive_to(speed: float) -> void:
	Input.action_release("brake")
	Input.action_press("accelerate")
	var waited := 0.0
	while absf(_van.actual_speed) < speed and waited < 12.0:
		_keeper.steer(_van, LANE)
		await physics_frame
		waited += 1.0 / 60.0
	Input.action_release("accelerate")


func _brake(duration: float) -> void:
	Input.action_press("brake")
	await _steer_for(duration)
	Input.action_release("brake")


func _steer_for(duration: float) -> void:
	for frame in range(roundi(duration * 60.0)):
		_keeper.steer(_van, LANE)
		await physics_frame
	_keeper.release()


func _seconds(duration: float) -> void:
	for frame in range(roundi(duration * 60.0)):
		await physics_frame


func _until(condition: Callable, limit: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await physics_frame
		waited += 1.0 / 60.0


func _finish() -> void:
	print("ROOF SPILL STATE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The roof spill state test finished within 150 s of game time")
	quit(1)
