extends SceneTree
## B1, rain in every lamp's light, in the running game (CHANGE-BRIEF.md §4). Its condition is the
## active camera within 65 m of a lamp; the test changes it with the real game loop, driving away
## from the office with real throttle input, and placing the van elsewhere on the road, and never
## calls the effect's start or stop. It checks the rain starts with its condition (already full,
## at load and on arrival), stops when the camera leaves and hides once drained, what it does
## while the game is paused (freezes, no restart on resume, real Esc presses) and while hidden
## (stops; restarts when shown). A headless run draws nothing, so the look is not checked here.

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const RANGE := 65.0
const LANE := 1.25
const DEPOT_SAMPLE := 1010
const HILL_SAMPLE := 420
const COURT := Vector3(-55.0, 0.1, 30.0)
const DEPOT := Rect2(-95.0, -15.0, 72.0, 76.0)
const SHED_INSIDE := AABB(Vector3(-89.75, 0.0, -9.75), Vector3(49.5, 9.0, 29.5))

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _rain: Node3D
var _road: RefCounted
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
	_scratch = OS.get_temp_dir().path_join("blackridge-rain-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_rain = _app.get_node("IndustrialLoop").get("lamp_rain")
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	var on_title: bool = not _rain.visible and _rain.active_count() == 0
	_app.call("_resume")
	await _seconds(0.5)
	_check(on_title and _rain.visible,
		"On the title screen the lamps' rain is hidden and none of it runs, so the paused title " +
		"shows no frozen streaks; leaving the title shows it again")
	_check_start()
	await _check_driving_away()
	await _check_arrival()
	await _check_pause()
	await _check_hidden()
	await _check_court()
	await _check_far_from_lamps()
	_finish()


func _check_start() -> void:
	var near := _within_range()
	_check(_rain.volumes.size() == 50,
		"Every lamp has a rain volume: 8 street lamps, the depot's 3 wall lights, the " +
		"floodlight, the door lamp, the transfer shed's gate lamp, its yard's 5 lights, " +
		"its dock front, the compound's gate flood and 3 yard floods, the harbour " +
		"flats' 19 road lamps, the waterfront's 2 access lamps and 4 high masts, and the " +
		"airfield's access lamp (%d)"
		% _rain.volumes.size())
	var dock: Node3D = null
	for volume in _rain.volumes:
		if volume.name.begins_with("LampRainDock"):
			dock = volume
	var drops := dock.get_node("LampRain") as GPUParticles3D if dock != null else null
	var box: Vector3 = (drops.process_material as ParticleProcessMaterial).emission_box_extents \
		if drops != null else Vector3.ZERO
	var near_edge := dock.global_position.z - box.z if dock != null else -INF
	_check(dock != null and box.z * 2.0 >= 3.5 and near_edge >= 20.5 and near_edge <= 20.55,
		("The dock front's rain fills the band its door lights light, %.2f m out over the apron "
		+ "from %.2f m (clear of the seals at 20.5), not a thin sheet that looks solid end on")
		% [box.z * 2.0, near_edge])
	_check(near.size() == 3 and _states_match(near),
		"At the start, the 3 lamps within 65 m of the camera rain and the other 10 are off and " +
		"hidden (%s)" % _names(near))
	_check(_rain.activations == near.size(),
		"Each one started already falling: started once by its emitter's restart, which runs its " +
		"preprocess (%d starts)" % _rain.activations)


func _check_driving_away() -> void:
	var start := _within_range()
	var keeper := LaneKeeper.new(_road, _nearest_sample(_van.global_position))
	Input.action_press("accelerate")
	var left_at := -1.0
	var last: Array[int] = []
	var waited := 0.0
	while waited < 40.0 and left_at < 0.0:
		keeper.steer(_van, LANE)
		await physics_frame
		waited += 1.0 / 60.0
		var near := _within_range()
		if near.is_empty():
			left_at = waited
		else:
			last = near
	Input.action_release("accelerate")
	keeper.release()
	await physics_frame
	var stopped := start.all(func(index: int) -> bool:
		return not _rain.rain(index).emitting and not _rain.is_active(index))
	_check(left_at > 0.0 and stopped,
		"Driving away with the real throttle, each lamp's rain stops emitting within one tick " +
		"of the camera passing 65 m (all three by %.1f s)" % left_at)
	var settle := _emptied_after(last[0])
	await _seconds(settle - 0.1)
	var waiting := last.all(func(index: int) -> bool: return _rain.volumes[index].visible)
	await _seconds(0.2)
	var hidden := start.all(func(index: int) -> bool: return not _rain.volumes[index].visible)
	_check(not last.is_empty() and waiting and hidden,
		"and hides once its last drops and their splashes are gone: the last lamp left is still " +
		"shown 0.1 s before %.2f s (the rain's life, then the splash's) and hidden 0.1 s after"
		% settle)


func _check_arrival() -> void:
	var before: int = _rain.activations
	_place(DEPOT_SAMPLE)
	await _seconds(0.3)
	var near := _within_range()
	_check(near.size() >= 2 and _states_match(near) and _rain.activations == before + near.size(),
		"Arriving among the depot and valley lamps, each one within 65 m starts, already " +
		"falling (%s)" % _names(near))
	_check(_rain.active_count() <= 8, "No more than 8 volumes rain at once (%d)"
		% _rain.active_count())


func _check_pause() -> void:
	var before: int = _rain.activations
	var active := _within_range()
	await _key(KEY_ESCAPE)
	var frozen := paused and active.all(func(index: int) -> bool:
		return not _rain.rain(index).can_process() and _rain.rain(index).emitting)
	await _seconds(1.0)
	_check(frozen and _rain.activations == before,
		"Esc pauses the game: the rain freezes where it is and nothing restarts")
	await _key(KEY_ESCAPE)
	await _seconds(0.2)
	var running := active.all(func(index: int) -> bool:
		return _rain.rain(index).can_process() and _rain.rain(index).emitting)
	_check(not paused and running and _rain.activations == before,
		"Esc again resumes it without a restart")


func _check_hidden() -> void:
	var active := _within_range()
	var before: int = _rain.activations
	_rain.visible = false
	await _seconds(0.2)
	var stopped := active.all(func(index: int) -> bool:
		return not _rain.rain(index).emitting and not _rain.is_active(index))
	_check(stopped, "Hidden, the rain stops emitting")
	_rain.visible = true
	await _seconds(0.2)
	_check(_states_match(active) and _rain.activations == before + active.size(),
		"Shown again, each volume clears its old drops and restarts, already falling (%d starts)"
		% (_rain.activations - before))


func _check_court() -> void:
	_van.call("recover", Transform3D(Basis.IDENTITY, COURT))
	await _seconds(0.5)
	var depot: Array[int] = []
	for index in range(_rain.volumes.size()):
		var at: Vector3 = _rain.volumes[index].global_position
		if DEPOT.has_point(Vector2(at.x, at.z)):
			depot.append(index)
	var raining := depot.all(func(index: int) -> bool:
		return _rain.is_active(index) and _rain.rain(index).emitting)
	_check(depot.size() == 7 and raining and _rain.active_count() <= 8,
		("In the court before the docks, the transfer shed's 7 volumes (its gate lamp, its yard's " +
		"5 lights and its dock front) all rain at once, within B1's 8 (%s; %d active)")
		% [_names(depot), _rain.active_count()])
	var wet: Array[String] = []
	for index in range(_rain.volumes.size()):
		var drops: GPUParticles3D = _rain.rain(index)
		var half := (drops.process_material as ParticleProcessMaterial).emission_box_extents
		if (drops.global_transform * AABB(-half, half * 2.0)).intersects(SHED_INSIDE):
			wet.append(String(_rain.volumes[index].name))
	_check(wet.is_empty(), "No rain volume's box reaches inside the transfer shed (%s)"
		% ", ".join(wet))


func _check_far_from_lamps() -> void:
	_place(HILL_SAMPLE)
	await _seconds(_emptied_after(0) + 0.2)
	_check(_rain.active_count() == 0 and _rain.volumes.all(func(volume: Node3D) -> bool:
		return not volume.visible),
		"On the hill road, far from every lamp, no lamp rain runs")


## Read from the effect scene, not the controller: a drop's life, then its splash's.
func _emptied_after(index: int) -> float:
	var volume: Node3D = _rain.volumes[index]
	return (volume.get_node("LampRain") as GPUParticles3D).lifetime \
		+ (volume.get_node("LampSplash") as GPUParticles3D).lifetime


func _within_range() -> Array[int]:
	var found: Array[int] = []
	var camera := root.get_viewport().get_camera_3d()
	for index in range(_rain.volumes.size()):
		var volume: Node3D = _rain.volumes[index]
		if camera.global_position.distance_to(volume.global_position) < RANGE:
			found.append(index)
	return found


func _states_match(near: Array[int]) -> bool:
	for index in range(_rain.volumes.size()):
		var wanted := near.has(index)
		var volume: Node3D = _rain.volumes[index]
		if _rain.is_active(index) != wanted or _rain.rain(index).emitting != wanted:
			return false
		if wanted and not volume.visible:
			return false
	return true


func _names(indices: Array[int]) -> String:
	var names := PackedStringArray()
	for index in indices:
		names.append(String(_rain.volumes[index].name))
	return ", ".join(names)


func _nearest_sample(at: Vector3) -> int:
	var points: PackedVector3Array = _road.points
	var best := 0
	for index in range(points.size()):
		if at.distance_squared_to(points[index]) < at.distance_squared_to(points[best]):
			best = index
	return best


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * LANE + Vector3.UP * 0.1))


func _seconds(duration: float) -> void:
	for frame in range(roundi(duration * 60.0)):
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
	print("LAMP RAIN STATE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The lamp rain state test finished within 150 s of game time")
	quit(1)
