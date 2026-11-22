extends SceneTree
## Assignment 7: the frame strip of the third clip, the rifle reload, in Mission 3 (CHANGE-BRIEF.md,
## the rifle's revision; C68). A fixture capture in the running game: a checkpoint at the run's
## stage 3 loaded, Ethan out of the van by real input (E), placed by Maya and armed by the
## encounter's own arm() (the handover's cutscene skipped: a fixture), 3 m from Maya and facing
## away from her, the encounter reset,
## the magazine at 12; he aims (right mouse held) and R starts the reload. Seen from his own aim
## camera over his shoulder. A Movie Maker run (`--write-movie`, `--fixed-fps 30`); every frame
## from R to the reload's end is logged: the capture frame (0 = R), the movie frame, RifleReload's
## frame on UpperBody, the gun's reloading flag and magazine.

const STAGE_THREE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=3\n"
const TICK := 1.0 / 60.0

var _app: Node3D
var _driver: CharacterBody3D
var _first_drawn := -1
var _r_drawn := -1
var _gun: Node
var _upper: AnimationPlayer


func _initialize() -> void:
	call_deferred("_run")


func _process(_delta: float) -> bool:
	if _first_drawn < 0:
		_first_drawn = Engine.get_frames_drawn()
	if _r_drawn >= 0 and _gun != null:
		var playing := _upper.is_playing() and String(_upper.current_animation) == "RifleReload"
		print("STRIP capture %d movie %d clip %.2f reloading %s magazine %d" % [
			Engine.get_frames_drawn() - _r_drawn, Engine.get_frames_drawn() - _first_drawn,
			_upper.current_animation_position * 30.0 if playing else -1.0, _gun.get("reloading"),
			_gun.get("magazine")])
	return false


func _run() -> void:
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
	var spot := maya.global_position + maya.global_basis.z * 3.0
	_place_ethan(spot, spot + maya.global_basis.z * 5.0)
	await _frames(20)
	encounter.call("arm")
	var gun := encounter.get("handgun") as Node
	await _frames(10)
	encounter.call("reset")
	gun.set("magazine", 12)
	_gun = gun
	_upper = (_driver.get("_rifle") as Node).get("upper") as AnimationPlayer
	Input.action_press("aim")
	waited = 0.0
	while not bool(_driver.call("can_fire")) and waited < 8.0:
		await physics_frame
		waited += TICK
	await _frames(30)
	_r_drawn = Engine.get_frames_drawn()
	print("STRIP R pressed at movie frame %d" % (_r_drawn - _first_drawn))
	await _press("reload")
	while bool(gun.get("reloading")):
		await process_frame
	await _frames(40)
	Input.action_release("aim")
	quit(0)


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


