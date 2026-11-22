extends SceneTree
## Assignment 7's edge test for the third clip, the rifle reload (CHANGE-BRIEF.md, the rifle's
## revision: startup 0-29, active 30-47, recovery 48-99; fire and R are ignored throughout; Esc
## pauses). Driven in Mission 3 with real input, as the reload pins are: Ethan armed, aiming, the
## magazine at 12. At each phase boundary, the reload's frames 0, 30, 48 and 99 (read from
## UpperBody's RifleReload), one frame before, on and after it:
##   fire and R together: during the reload no round is fired and the reload is not restarted;
##     one frame before frame 0 (before R) the round fires and R starts the reload; on 99 (the
##     clip's last frame, where the gun's timer ends the reload, within a tick) and after it, the
##     magazine is full, R starts nothing and the round fires;
##   Esc (frames 0-98; at 99 the clip is over): the clip's frame and the gun's time left hold for
##     20 ticks paused, and go on after Esc.

const STAGE_THREE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=3\n"
const TICK := 1.0 / 60.0
const BOUNDARIES := [0, 30, 48, 99]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _driver: CharacterBody3D
var _gun: Node
var _encounter: Node
var _upper: AnimationPlayer


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(_timeout)
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
	_encounter = encounter
	_gun = gun
	_upper = (_driver.get("_rifle") as Node).get("upper") as AnimationPlayer
	Input.action_press("aim")
	for boundary: int in BOUNDARIES:
		for offset: int in [-1, 0, 1]:
			await _trial_fire(boundary, offset)
			await _trial_pause(boundary, offset)
	Input.action_release("aim")
	_finish()


## Ready to reload: the encounter reset, the magazine at 12, the rifle raised to aim.
func _ready_to_reload() -> void:
	_encounter.call("reset")
	_gun.set("magazine", 12)
	var waited := 0.0
	while not bool(_driver.call("can_fire")) and waited < 8.0:
		await physics_frame
		waited += TICK
	await _frames(5)


## The clip's frame, or -1 when the reload is not playing.
func _clip_frame() -> float:
	if not _upper.is_playing() or String(_upper.current_animation) != "RifleReload":
		return -1.0
	return _upper.current_animation_position * 30.0


## Waits until the reload's clip reaches `frame` (the first tick on or past it), or for `after`
## ticks past its end.
func _reach(frame: float) -> void:
	var waited := 0
	while _clip_frame() < frame and bool(_gun.get("reloading")) and waited < 400:
		await process_frame
		waited += 1


func _trial_fire(boundary: int, offset: int) -> void:
	await _ready_to_reload()
	var target := boundary + offset
	var shots: int = _gun.get("shots")
	var label := "frame %d (%+d of %d)" % [target, offset, boundary]
	if target < 0:
		await _press("fire")
		var fired := int(_gun.get("shots")) - shots
		await _press("reload")
		check("RELOAD EDGE fire+R at %s, before R: the round fires (%d), then R starts the reload (%s)"
			% [label, fired, _gun.get("reloading")], fired == 1 and bool(_gun.get("reloading")))
		await _drain()
		return
	await _press("reload")
	if target >= 99:
		var last := -1.0
		var waited := 0
		while bool(_gun.get("reloading")) and waited < 400:
			last = maxf(last, _clip_frame())
			await process_frame
			waited += 1
		await _frames(2 * (target - 99))
		var magazine: int = _gun.get("magazine")
		await _press("reload")
		var restarted := bool(_gun.get("reloading"))
		shots = _gun.get("shots")
		await _press("fire")
		var fired := int(_gun.get("shots")) - shots
		check(("RELOAD EDGE R then fire at %s: the reload ended at the clip's frame %.1f (its last, "
			+ "99, within a tick), the magazine full (%d); R starts nothing (%s) and the round "
			+ "fires (%d)") % [label, last, magazine, restarted, fired], last >= 98.0
			and magazine == 30 and not restarted and fired == 1)
		await _drain()
		return
	await _reach(float(target))
	var at := _clip_frame()
	var left: float = _gun.get("_reload_left")
	var during := bool(_gun.get("reloading"))
	shots = _gun.get("shots")
	await _press("fire")
	await _press("reload")
	var later: float = _gun.get("_reload_left")
	check(("RELOAD EDGE fire+R at %s (clip %.1f, reloading %s): no round (%d), the reload not "
		+ "restarted (time left %.3f then %.3f s)") % [label, at, during,
		int(_gun.get("shots")) - shots, left, later], at >= 0.0 and during
		and int(_gun.get("shots")) == shots and later <= left)
	await _drain()


func _trial_pause(boundary: int, offset: int) -> void:
	var target := boundary + offset
	if target < 0 or target >= 99:
		return
	await _ready_to_reload()
	await _press("reload")
	await _reach(float(target))
	var label := "frame %d (%+d of %d)" % [target, offset, boundary]
	await _press("pause")
	var frozen := _clip_frame()
	var left: float = _gun.get("_reload_left")
	await _frames(20)
	var held := paused and is_equal_approx(_clip_frame(), frozen) \
		and is_equal_approx(float(_gun.get("_reload_left")), left)
	await _press("pause")
	await _frames(3)
	var resumed := not paused and (float(_gun.get("_reload_left")) < left
		or int(_gun.get("magazine")) == 30)
	check(("RELOAD EDGE Esc at %s: the clip (%.1f) and the time left (%.3f s) held for 20 ticks "
		+ "paused (%s), and go on after Esc (%s)") % [label, frozen, left, held, resumed],
		held and resumed)
	if paused:
		await _press("pause")
	await _drain()


## Lets the reload finish.
func _drain() -> void:
	var waited := 0
	while bool(_gun.get("reloading")) and waited < 400:
		await process_frame
		waited += 1


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
	print("RELOAD EDGES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
