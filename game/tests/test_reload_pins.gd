extends SceneTree
## Assignment 7's pins for the reload clip (CHANGE-BRIEF.md, the revision #377-#383), written and
## committed before the clip: what the pistol does now in Mission 3, driven with real input.
##   PIN5 R reloads for RELOAD_SECONDS, then the magazine is full from the spare; while it reloads
##        a pull of the trigger fires nothing and R again does not restart it.
##   PIN6 armed, his legs: standing still his own player plays Idle, walking while he aims it
##        plays his walk.
## Re-pinned for the rifle (C68, #403), as the brief's rifle revision predicted: RELOAD_SECONDS
## 2.2 s became the reload clip's 99/30 s; the magazine 15 became 30 (from 12 it takes 18 of the
## spare 30, leaving 12); the rifle is brought out first (slung, R does nothing); and walking with
## it out his legs play the rifle's gaits, not Walk, settling to Idle once a turn on the spot ends.

const STAGE_THREE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=3\n"
const TICK := 1.0 / 60.0

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _driver: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(200.0, true, false, true).timeout.connect(_timeout)
	var scratch := OS.get_temp_dir().path_join("blackridge-a7-reload-pins-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(scratch, FileAccess.WRITE)
	file.store_string(STAGE_THREE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _frames(50)
	_driver = _app.get("driver") as CharacterBody3D
	var run_mission := _app.get("run") as Node
	var encounter := run_mission.get("encounter") as Node
	await _press("interact")
	var waited := 0.0
	while (not bool(_driver.get("active")) or bool(_app.get("_boarding"))) and waited < 10.0:
		await physics_frame
		waited += TICK
	await _frames(30)
	var maya := run_mission.get("maya") as Node3D
	_place_ethan(maya.global_position + maya.global_basis.z * 1.4, maya.global_position)
	await _frames(20)
	await _press("interact")
	var gun := encounter.get("handgun") as Node
	waited = 0.0
	while not bool(gun.get("armed")) and waited < 30.0:
		await physics_frame
		waited += TICK
	await _frames(10)
	encounter.call("reset")
	gun.set("magazine", 12)
	var spare: int = gun.get("reserve")
	Input.action_press("aim")
	waited = 0.0
	while not bool(_driver.call("can_fire")) and waited < 8.0:
		await physics_frame
		waited += TICK
	await _press("reload")
	var started := bool(gun.get("reloading"))
	var from_frame := Engine.get_process_frames()
	var shots: int = gun.get("shots")
	var fired_during := false
	var again := false
	while bool(gun.get("reloading")) and Engine.get_process_frames() - from_frame < 300:
		var seconds := (Engine.get_process_frames() - from_frame) * TICK
		if not fired_during and seconds > 0.5:
			fired_during = true
			await _press("fire")
		elif not again and seconds > 1.0:
			again = true
			await _press("reload")
		else:
			await process_frame
	var clock := (Engine.get_process_frames() - from_frame) * TICK
	Input.action_release("aim")
	var took := clock
	var full := int(gun.get("magazine")) == 30 and int(gun.get("reserve")) == spare - 18
	check(("PIN5: R reloads (%s) for %.3f s (RELOAD_SECONDS %.1f), then the magazine is full "
		+ "from the spare (%s: %d and %d)") % [started, took, float(gun.get("RELOAD_SECONDS")), full,
		gun.get("magazine"), gun.get("reserve")], started and full
		and absf(took - float(gun.get("RELOAD_SECONDS"))) <= 2.0 * TICK)
	check("PIN5: while it reloads, the trigger fires nothing (%d shots) and R again does not "
		% (int(gun.get("shots")) - shots) + "restart it (%s, %.3f s in all)" % [again, took],
		fired_during and again and int(gun.get("shots")) == shots)
	var settle := 0
	while _legs() != "Idle" and settle < 120:
		await physics_frame
		settle += 1
	await _frames(10)
	var standing := _legs()
	Input.action_press("aim")
	_hold("accelerate", true)
	await _frames(40)
	var walking := _legs()
	_hold("accelerate", false)
	Input.action_release("aim")
	await _frames(30)
	check("PIN6: armed, his own player plays %s standing and %s walking while he aims" % [
		standing, walking], standing == "Idle" and walking in ["RifleWalk", "RifleStrafeLeft",
		"RifleStrafeRight", "RifleWalkBack"])
	_finish()


func _legs() -> String:
	return String((_driver.get("_player") as AnimationPlayer).current_animation)


func _hold(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	event.strength = 1.0 if down else 0.0
	Input.parse_input_event(event)


func _place_ethan(at: Vector3, look: Vector3) -> void:
	var space := _driver.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0,
		at + Vector3.DOWN * 5.0, 1))
	_driver.global_position = (hit["position"] as Vector3) if not hit.is_empty() else at
	_driver.velocity = Vector3.ZERO
	var facing := Vector3(look.x - at.x, 0.0, look.z - at.z).normalized()
	_driver.call("face", facing)
	_driver.call("look_toward", facing)


func _press(action: String) -> void:
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


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("RELOAD PINS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
