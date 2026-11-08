extends SceneTree
## A1, the wiper flick, in the running game (CHANGE-BRIEF.md §2). The wipers are switched with
## real presses of the wipers key and the flick follows the van's own wiper_swept signal; the
## test never calls the effect's trigger. It checks when the flick fires (every top turn, never on
## load, never with the wipers off, never at park), where (the driver's blade tip, in the
## windshield's frame, with the bow wave's sheet laid along the blade), the overlap rule (two
## bursts alive at once on fast wipers, neither cut short), the colliders fitted to the curved
## glass, and, as the van is driven with real throttle and brake: the air's push up the glass
## and back along the side (none parked or reversing), the run-off thrown back along the side
## window only at speed, the extra water of a roof spill thrown once by the next top turn, and
## freeing the van in the middle of a burst. A headless run draws nothing, so how the flick
## looks is not checked here.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const VAN_SCENE := "res://features/vehicles/freight_van/freight_van.tscn"
const FLICK_LIFE := 1.2
const STRAIGHT := 960
const LANE := 1.25
const GRAVITY := 9.8
const STILL_AIR := {"WaterSheet": Vector3(0.0, -9.8, 0.0), "BigDrops": Vector3(0.0, -9.8, 0.0),
	"HeavyDrops": Vector3(0.0, -9.8, 0.0), "FineSpray": Vector3(0.0, -1.0, 0.0),
	"PillarRunoff": Vector3(0.0, -2.5, 0.0)}
const HEAVY_TERMINAL := 12.0
const BIG_TERMINAL := 8.0
const BIG_MOST := 40.0
const SPRAY_MOST := 80.0
const RUNOFF_TERMINAL := 5.0
const RUNOFF_MOST := 60.0
const GLASS_PANELS: Array[String] = ["GlassLeft", "GlassMiddle", "GlassRight"]
const WATER_ON_GLASS := 2

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
var _road: RefCounted
var _keeper: RefCounted
var _glass_frame := Basis.IDENTITY
var _tip_gap: float = INF
var _passenger_ahead: float = INF
var _passenger_lift: float = INF
var _line_along: float = 0.0
var _sheet_along: float = 0.0


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
	var presentation := _van.get_node("VanPresentation")
	_glass_frame = Basis(Vector3.RIGHT, float((presentation.get_script() as GDScript)
		.get_script_constant_map()["WINDSHIELD_RAKE"]))
	_check_glass()
	_van.wiper_swept.connect(_on_swept)
	for flick: Node3D in _fx.flicks:
		var spray := flick.get_node("FineSpray") as GPUParticles3D
		spray.finished.connect(_on_spray_finished.bind(flick))
	await _check_off()
	await _check_fast()
	await _check_air()
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
	var passenger_before: int = _fx.passenger_flicks
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
	_check(_tip_gap > 0.005 and _tip_gap < 0.15,
		"At the top turn the blade tip is %.0f mm in front of the glass's left collider, " % [
		_tip_gap * 1000.0] + "so the flick starts outside it")
	_check(_sheet_along > 0.999,
		"At the top turn the bow wave leaves as a sheet laid along the blade (%.4f)"
		% _sheet_along)
	_check(_fx.runoffs_thrown == 0 and _fx.spill_water_thrown == 0,
		"Parked, no top turn throws water back along the side window or a spill's water")
	_check(_fx.passenger_flicks - passenger_before == fired,
		"Each top turn also leaves the passenger blade's water on the glass (%d of %d)" % [
		_fx.passenger_flicks - passenger_before, fired])
	_check(_passenger_ahead > 0.005 and _passenger_ahead < 0.03
		and _passenger_lift > 0.005 and _passenger_lift < 0.02,
		"It starts just ahead of the passenger blade's middle, on the side it was moving to " +
		"(%.0f mm), and on the outside of the glass (%.0f mm)" % [_passenger_ahead * 1000.0,
		_passenger_lift * 1000.0])
	_check(_line_along > 0.99,
		"Its line of water lies along the passenger blade (%.4f)" % _line_along)


func _check_glass() -> void:
	var names: Array[String] = []
	for collider: GPUParticlesCollisionBox3D in _fx.glass_colliders:
		names.append(String(collider.name))
	_check(names == GLASS_PANELS and _fx.glass_colliders.all(
		func(collider: Node) -> bool: return _van.is_ancestor_of(collider)),
		"Three thin colliders move with the van, one per third of the windshield (%s)" % [names])
	var pane := _van.find_child("Windshield", true, false) as MeshInstance3D
	var worst := 0.0
	var middles: Array[float] = []
	for collider: GPUParticlesCollisionBox3D in _fx.glass_colliders:
		var into := collider.global_transform.affine_inverse() * pane.global_transform
		var half := collider.size * 0.5
		var outside: Array[float] = []
		for point in pane.mesh.get_faces():
			var at := into * point
			if absf(at.x) <= half.x and absf(at.y) <= half.y:
				outside.append(at.z + half.z)
		outside.sort()
		worst = maxf(worst, maxf(absf(outside[0]), absf(outside[outside.size() - 1])))
		middles.append(outside[outside.size() / 2])
	_check(worst < 0.035 and middles.all(func(gap: float) -> bool: return absf(gap) < 0.01),
		"Each collider's face follows the curved glass: within %.0f mm of it everywhere, " % [
		worst * 1000.0] + "and its middle within 10 mm (%s mm)" % [middles.map(
		func(gap: float) -> String: return "%.1f" % (gap * 1000.0))])
	_check(_fx.flicks.all(func(flick: Node3D) -> bool: return flick.basis.is_equal_approx(
		_glass_frame)), "Each burst is turned to the windshield's frame, in which it is set")
	var wipe := _fx.wipe_collider as GPUParticlesCollisionBox3D
	var blade := (_fx.get("_wiper") as Node3D).get("blade") as Node3D
	_check(wipe != null and wipe.get_parent() == blade and is_equal_approx(wipe.size.y, 0.65)
		and wipe.cull_mask == WATER_ON_GLASS,
		"The driver's blade carries a collider as long as the blade, which touches only the " +
		"water left on the glass (layer %d)" % WATER_ON_GLASS)
	_check(_fx.glass_colliders.all(func(collider: GPUParticlesCollisionBox3D) -> bool:
		return collider.cull_mask & WATER_ON_GLASS == 0),
		"The glass's own colliders leave that water alone, so only a blade clears it")


func _check_air() -> void:
	_road = _app.get_node("IndustrialLoop").get("road")
	_place(STRAIGHT)
	Input.action_press("brake")
	await _seconds(0.5)
	await process_frame
	var still: float = _van.actual_speed
	var parked := 0.0
	for emitter_name: String in STILL_AIR:
		parked += _push(emitter_name).length()
	Input.action_release("brake")
	_check(absf(still) < 0.05 and parked < 0.01,
		"Standing on the brake (%.2f m/s), no air pushes the flick's drops (%.2f m/s²)" % [
		still, parked])
	await _drive_to(12.0)
	await process_frame
	var speed: float = _van.actual_speed
	var big := _push("BigDrops")
	var spray := _push("FineSpray")
	var runoff := _push("PillarRunoff")
	var body := (_fx.flicks[0] as Node3D).get_parent() as Node3D
	var up_glass := (body.global_basis * _glass_frame.y).normalized()
	var back := body.global_basis.z.normalized()
	var wanted := minf(GRAVITY * pow(speed / BIG_TERMINAL, 2.0), BIG_MOST)
	_check(absf(big.length() - wanted) < wanted * 0.01 and big.normalized().dot(up_glass) > 0.999,
		"At %.1f m/s the air pushes the big drops back up the glass at %.1f m/s² " % [speed,
		big.length()] + "(g × (v / 8 m/s)² is %.1f m/s²)" % wanted)
	_check(absf(spray.length() - SPRAY_MOST) < SPRAY_MOST * 0.01
		and spray.normalized().dot(up_glass) > 0.999,
		"and the fine spray at %.1f m/s², its most" % spray.length())
	var heavy := _push("HeavyDrops")
	var heavier := minf(GRAVITY * pow(speed / HEAVY_TERMINAL, 2.0), BIG_MOST)
	_check(absf(heavy.length() - heavier) < heavier * 0.01
		and heavy.normalized().dot(up_glass) > 0.999,
		"and the heavy drops, which need more wind, at %.1f m/s² " % heavy.length()
		+ "(g × (v / 12 m/s)² is %.1f)" % heavier)
	var along_side := minf(GRAVITY * pow(speed / RUNOFF_TERMINAL, 2.0), RUNOFF_MOST)
	_check(absf(runoff.length() - along_side) < along_side * 0.01
		and runoff.normalized().dot(back) > 0.999,
		"and the run-off back along the side window at %.1f m/s² (g × (v / 5 m/s)² is %.1f)" % [
		runoff.length(), along_side])
	var fired: int = _fx.flicks_fired
	var thrown: int = _fx.runoffs_thrown
	await _cruise(1.2)
	_check(_fx.flicks_fired > fired and _fx.runoffs_thrown - thrown == _fx.flicks_fired - fired,
		"Driving at %.0f km/h, every top turn also throws water back along the side " % [
		_van.actual_speed * 3.6] + "window (%d of %d)" % [_fx.runoffs_thrown - thrown,
		_fx.flicks_fired - fired])
	await _stop()
	await _tap("change_gear")
	Input.action_press("accelerate")
	await _seconds(2.0)
	await process_frame
	var backward: float = _van.actual_speed
	var shielded := 0.0
	for emitter_name: String in STILL_AIR:
		shielded += _push(emitter_name).length()
	Input.action_release("accelerate")
	_check(backward < -1.0 and shielded < 0.01,
		"Reversing at %.1f m/s, the cab shields the glass and nothing is pushed (%.2f m/s²)" % [
		-backward, shielded])
	_check(_fx.spills_fired == 1 and _fx.spill_water_thrown == 1
		and not _fx.spill_water_on_glass(),
		"The hard stop spilled the roof's water, and the next top turn threw it off the glass, " +
		"once (%d spill, %d throw)" % [_fx.spills_fired, _fx.spill_water_thrown])


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
	_check(alive > 0 and kept.is_empty() and not is_instance_valid(fx),
		"Freeing the van in the middle of a flick frees its bursts with it, as they move in its " +
		"frame, without errors (%d of %d left)" % [kept.size(), flicks.size()])


func _on_swept() -> void:
	if _van.wiper_setting == 0:
		return
	if _van.wiper_angle < _top_turn:
		_parks += 1
		return
	_tops += 1
	var flick: Node3D = _fx.last_flick
	if flick and _tip_gap == INF:
		var left := _fx.glass_colliders[0] as GPUParticlesCollisionBox3D
		var at: Vector3 = left.global_transform.affine_inverse() * _fx.tip()
		_tip_gap = -left.size.z * 0.5 - at.z
		var sheet := flick.get_node("WaterSheet") as Node3D
		var blade := (_fx.get("_wiper") as Node3D).global_basis.y.normalized()
		_sheet_along = sheet.global_basis.y.normalized().dot(blade)
		var passenger := _fx.get("_passenger") as Node3D
		var middle := passenger.global_transform * Vector3(0.0, float(_fx.get("_passenger_arm")),
			0.0)
		var water := flick.get_node("PassengerWater") as Node3D
		_passenger_ahead = (water.global_position - middle).dot(
			-passenger.global_basis.x.normalized())
		var glass := _fx.glass_colliders[1] as GPUParticlesCollisionBox3D
		var on_glass: Vector3 = glass.global_transform.affine_inverse() * water.global_position
		_passenger_lift = -glass.size.z * 0.5 - on_glass.z
		var line := flick.get_node("PassengerLine") as Node3D
		_line_along = line.global_basis.y.normalized().dot(passenger.global_basis.y.normalized())
	if flick:
		_worst_place = maxf(_worst_place, flick.global_position.distance_to(_fx.tip()))
		_started[flick] = _van.clock


func _on_spray_finished(flick: Node3D) -> void:
	if _started.has(flick):
		_shortest_life = minf(_shortest_life, _van.clock - float(_started[flick]))


## The air's push on an emitter's water, in the world: its gravity, turned out of its frame, less
## the still air's. Read after the physics tick that set it, before the frame moves the body.
func _push(emitter_name: String) -> Vector3:
	var emitter := (_fx.flicks[0] as Node3D).get_node(emitter_name) as GPUParticles3D
	var process := emitter.process_material as ParticleProcessMaterial
	return emitter.global_basis * process.gravity - Vector3(STILL_AIR[emitter_name])


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


func _cruise(duration: float) -> void:
	Input.action_press("accelerate")
	await _steer_for(duration)
	Input.action_release("accelerate")


func _steer_for(duration: float) -> void:
	for frame in range(roundi(duration * 60.0)):
		_keeper.steer(_van, LANE)
		await physics_frame
	_keeper.release()


func _stop() -> void:
	Input.action_press("brake")
	var waited := 0.0
	while absf(_van.actual_speed) > 0.1 and waited < 8.0:
		_keeper.steer(_van, LANE)
		await physics_frame
		waited += 1.0 / 60.0
	_keeper.release()
	Input.action_release("brake")
	await _seconds(0.2)


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
