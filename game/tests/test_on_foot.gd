extends SceneTree

const Driver = preload("res://features/characters/driver/driver.gd")
const BOARD_SPOT := Vector3(-2.25, 0.0, -0.35)
const DOOR_SWING := 0.541

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _driver: CharacterBody3D
var _hud: CanvasLayer
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-on-foot-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_driver = _app.get("driver")
	_hud = _app.get_node("DrivingHud")
	await process_frame
	_hud.resume_requested.emit()
	await _seconds(0.5)
	_check_start()
	await _check_walking()
	await _check_boarding()
	await _check_ignition()
	await _check_driving()
	await _check_reentry()
	await _check_new_drive()
	_finish()


func _check_start() -> void:
	_check(not _van.occupied and not _van.engine_on and not _van.headlights_on
		and _van.wiper_setting == 0,
		"The drive begins on foot: the van is empty, its engine off, lights off, wipers parked")
	var local := _van.to_local(_driver.global_position)
	_check(local.x < -1.5 and Vector2(local.x - BOARD_SPOT.x, local.z - BOARD_SPOT.z).length() < 2.0,
		"Ethan starts on the van's left, within 2 m of the driver's door (%s)" % str(local))
	_check(root.get_viewport().get_camera_3d() == _driver.call("get_camera"),
		"The player sees Ethan through his own camera")
	var player := _ethan_player()
	_check(player != null and player.current_animation == "Idle",
		"Ethan is the Mixamo character, standing in his Idle clip")
	_check(_objective().begins_with("GET IN THE VAN"), "The objective says to get in the van")
	_check(_hint().begins_with("E  Get in the van"), "Near the van the hint says E gets him in")
	var screens: Array = _presentation.get("_powered_screens")
	var dark := screens.size() == 5
	for screen: MeshInstance3D in screens:
		dark = dark and not screen.visible
	_check(dark, "The cluster, map and camera-mirror screens are off with the engine")


func _check_walking() -> void:
	var start := _driver.global_position
	Input.action_press("accelerate")
	await _seconds(0.5)
	var walk_pace := _flat(_driver.velocity).length()
	var walked := _flat(_driver.global_position - start).length()
	var walk_clip := _ethan_player().current_animation
	Input.action_press("sprint")
	await _seconds(0.1)
	var run_pace := _flat(_driver.velocity).length()
	var run_clip := _ethan_player().current_animation
	Input.action_release("sprint")
	Input.action_release("accelerate")
	await _seconds(0.4)
	_check(walk_clip == "Walk" and absf(walk_pace - Driver.WALK_SPEED) < 0.05,
		"W walks Ethan at the Walk clip's own pace (%s, %.2f m/s)" % [walk_clip, walk_pace])
	_check(walked > 0.6 and walked < 1.0, "He covers %.2f m in half a second" % walked)
	_check(run_clip == "Run" and absf(run_pace - Driver.RUN_SPEED) < 0.05,
		"SHIFT runs at the Run clip's pace (%s, %.2f m/s)" % [run_clip, run_pace])
	_check(_ethan_player().current_animation == "Idle", "Letting go returns him to Idle")


func _check_boarding() -> void:
	await _tap("interact")
	_check(bool(_app.get("_boarding")) and _hint() == "",
		"E near the van starts boarding and clears the hint")
	var saw_clip := false
	var widest := 0.0
	var glass_follows := true
	var door: Node3D = _presentation.get("_door")
	var glass: Node3D = _presentation.get("_door_glass")
	var waited := 0.0
	while not _van.occupied and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
		saw_clip = saw_clip or _ethan_player().current_animation == "EnterVan"
		widest = minf(widest, door.rotation.y)
		glass_follows = glass_follows and is_equal_approx(glass.rotation.y, door.rotation.y)
	_check(saw_clip, "Ethan walks to the door and plays Entering Car")
	_check(widest < -0.9 * DOOR_SWING,
		"The driver's door swings outward about 31 degrees as he pulls it (%.1f)" % rad_to_deg(
			widest))
	_check(glass_follows, "The door glass swings with the door")
	await process_frame
	_check(_van.occupied and not _driver.visible
		and root.get_viewport().get_camera_3d() == _van.call("get_camera"),
		"After the cut the player sits in the driver's seat (%.1f s)" % waited)
	_check(is_zero_approx(float(_van.driver_door)) and is_zero_approx(door.rotation.y),
		"The door is shut behind him")
	_check(not _objective().begins_with("GET IN THE VAN"),
		"The route's objective returns (%s)" % _objective())


func _check_ignition() -> void:
	var swept := 0.0
	var waited := 0.0
	while not _van.headlights_on and waited < 4.0:
		await physics_frame
		waited += 1.0 / 60.0
		swept = maxf(swept, float(_van.call("ignition_sweep")))
	_check(_van.engine_on and swept > 0.95,
		"The engine starts and the gauge needles sweep to the top (%.2f)" % swept)
	_check(_van.headlights_on and not _van.high_beams and _van.wiper_setting == 1,
		"After the sweep the low beams and the wipers come on (%.1f s after the cut)" % waited)
	await physics_frame
	var screens: Array = _presentation.get("_powered_screens")
	var lit := true
	for screen: MeshInstance3D in screens:
		lit = lit and screen.visible
	_check(lit, "The dash screens come on with the engine")


func _check_driving() -> void:
	Input.action_press("accelerate")
	await _seconds(1.5)
	Input.action_release("accelerate")
	_check(_van.speed > 3.0, "The van drives after Ethan gets in (%.1f m/s)" % _van.speed)
	Input.action_press("brake")
	await _seconds(1.5)
	Input.action_release("brake")


func _check_reentry() -> void:
	await _tap("interact")
	_check(not _van.occupied and _driver.visible, "E at a stop lets Ethan out")
	await _tap("interact")
	var waited := 0.0
	var restarted := false
	while not _van.occupied and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
		restarted = restarted or not _van.engine_on
	await _seconds(0.5)
	_check(_van.occupied and not restarted and is_zero_approx(float(_van.call("ignition_sweep"))),
		"Getting back into the running van needs no second ignition (%.1f s)" % waited)


func _check_new_drive() -> void:
	_hud.restart_requested.emit()
	await _seconds(0.3)
	_check(not _van.occupied and not _van.engine_on and _driver.visible
		and _objective().begins_with("GET IN THE VAN"),
		"New drive starts on foot beside the dark van again")


func _ethan_player() -> AnimationPlayer:
	var ethan := _driver.get_node_or_null("Ethan")
	if ethan == null:
		return null
	return ethan.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


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
	var frames := int(duration * 60.0)
	for frame in range(frames):
		await physics_frame


func _finish() -> void:
	print("ON FOOT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "On-foot test finished within 100 s of game time")
	quit(1)
