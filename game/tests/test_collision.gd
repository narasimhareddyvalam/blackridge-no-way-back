extends SceneTree

const TRIGGER_SIDE := 966
const WAIT_AT := 1000
const RUN_FROM := 1020
const PULL_OVER := 1.35
const DEPOT := Vector3(-28.0, 0.1, 93.0)

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _hud: CanvasLayer
var _thuds: int = 0
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
	_scratch = OS.get_temp_dir().path_join("blackridge-collision-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_hud = _app.get_node("DrivingHud")
	_van.connect("collided", func(_strength: float) -> void: _thuds += 1)
	await process_frame
	_app.call("_resume")
	await physics_frame
	_route.set("stage", 4)
	_place(TRIGGER_SIDE, 0.0)
	await _until(func() -> bool: return is_instance_valid(_route.get("oncoming")), 2.0)
	var oncoming: Node3D = _route.get("oncoming")
	_place(WAIT_AT, PULL_OVER)
	_hold("brake", true)
	await _until(func() -> bool: return bool(oncoming.get("_passed")), 30.0)
	_check(not is_instance_valid(_route.get("pedestrian")),
		"No one is on the road while the oncoming van passes")
	_hold("brake", false)
	_place(RUN_FROM, PULL_OVER)
	_hold("accelerate", true)
	await _until(func() -> bool: return is_instance_valid(_route.get("pedestrian")), 8.0)
	var pedestrian: Node3D = _route.get("pedestrian")
	if not is_instance_valid(pedestrian):
		_check(false, "A pedestrian steps out after the oncoming van has passed")
		_finish()
		return
	await _check_step_out(pedestrian)
	await _check_aftermath(pedestrian, oncoming)
	await _check_depot()
	_hud.restart_requested.emit()
	await _seconds(0.3)
	_check(not is_instance_valid(_route.get("pedestrian")) and not bool(_route.get("fleeing"))
		and bool((_app.get("_audio").get("_music") as AudioStreamPlayer).playing),
		"New drive clears the pedestrian and brings the music back")
	_finish()


func _check_step_out(pedestrian: Node3D) -> void:
	var local := _van.to_local(pedestrian.global_position)
	_check(float(_van.get("speed")) >= 6.9,
		"He steps out only once the van is doing 25 km/h (%.1f m/s)" % float(_van.get("speed")))
	_check(local.x > 1.0 and local.z < -3.0 and local.z > -15.0,
		"He steps out from the right verge, just ahead of the van (%s)" % str(local))
	_hold("accelerate", false)
	_hold("brake", true)
	await _until(func() -> bool: return bool(pedestrian.get("hit")), 4.0)
	_check(bool(pedestrian.get("hit")), "Braking at once cannot stop the van on the wet road")
	_check(pedestrian.call("animation") == "HitByVan", "He is struck: Hit By Car plays")
	_check(_thuds > 0, "The van's collision thud plays")
	_check(not bool((_app.get("_audio").get("_music") as AudioStreamPlayer).playing),
		"The music cuts out")


func _check_aftermath(pedestrian: Node3D, oncoming: Node3D) -> void:
	if is_instance_valid(oncoming):
		var far := _van.global_position.distance_to(oncoming.global_position)
		_check(_van.to_local(oncoming.global_position).z > 0.0 and far > 30.0,
			"The oncoming van is behind and %.0f m away: no witness" % far)
	else:
		_check(true, "The oncoming van is already gone: no witness")
	_hold("brake", false)
	_hold("accelerate", true)
	await _until(func() -> bool: return absf(float(_van.get("speed"))) < 0.05, 6.0)
	await _seconds(1.5)
	var skeleton := pedestrian.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var hips := skeleton.global_transform * skeleton.get_bone_global_pose(
		skeleton.find_bone("mixamorig_Hips"))
	var clear := -_van.to_local(hips.origin).z - 2.45
	_check(clear > 0.5, "He is thrown clear and lies %.1f m ahead of the bumper, in the beams"
		% clear)
	_check(hips.origin.y - pedestrian.global_position.y < 0.4,
		"He lies on the road (hips %.2f m up)" % (hips.origin.y - pedestrian.global_position.y))
	var held_for := 1.5
	var crept := 0.0
	while bool(_van.get("held")) and held_for < 8.0:
		await physics_frame
		held_for += 1.0 / 60.0
		crept = maxf(crept, absf(float(_van.get("speed"))))
	_check(held_for > 3.5 and crept < 0.1,
		"The van skids to a stop and holds there (%.1f s) despite the throttle" % held_for)
	await _tap("interact")
	_check(bool(_van.get("occupied")), "E does nothing: Ethan does not get out")
	_check(bool(_route.get("fleeing")) and _objective() == "DRIVE.", "The objective reads DRIVE.")
	await _seconds(1.5)
	_hold("accelerate", false)
	_check(float(_van.get("speed")) > 2.0, "Then the van drives again (%.1f m/s)"
		% float(_van.get("speed")))


func _check_depot() -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DEPOT))
	_hold("brake", true)
	await _until(func() -> bool: return bool(_route.get("complete")), 3.0)
	_hold("brake", false)
	var driver: CharacterBody3D = _app.get("driver")
	var widest := 0.0
	var saw_clip := false
	var waited := 0.0
	while waited < 12.0 and (bool(_app.get("_boarding")) or waited < 1.0):
		await physics_frame
		waited += 1.0 / 60.0
		widest = maxf(widest, float(_van.get("driver_door")))
		var ethan := driver.get_node("Ethan")
		var player := ethan.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		saw_clip = saw_clip or player.current_animation == "ExitVan"
	_check(bool(_route.get("complete")) and not bool(_van.get("occupied")) and driver.visible,
		"Parked at the depot, Ethan gets out (%.1f s)" % waited)
	_check(saw_clip and widest > 0.9 and is_zero_approx(float(_van.get("driver_door"))),
		"He plays Exiting Car through the open door and shuts it")
	_check(_van.to_local(driver.global_position).x < -1.4,
		"He stands clear of the van afterwards (%s)" % str(_van.to_local(driver.global_position)))


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _until(condition: Callable, limit: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await physics_frame
		waited += 1.0 / 60.0


func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


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


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("COLLISION RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Collision test finished within 150 s of game time")
	quit(1)
