extends SceneTree
## Assignment 7: EnterVan interrupted in one phase, for the film (CHANGE-BRIEF.md §4, "Interrupts").
## A fixture capture in the running game, set up as capture_enter_van_strip.gd is (Mission 1's start
## at the depot at night, Ethan placed at the driver's door, the run sheet treated as signed), then
## real input: E, and when EnterVan reaches the phase's frame, the interrupt.
##   startup  (frame 16)  W held for half a second: ignored; he does not move, the clip runs on
##   active   (frame 40)  Esc: the pause menu; the clip and the door hold; Esc again resumes
##   recovery (frame 56)  R: recovers; boarding cancelled, seated in the van, the door shut
## The phase comes after `--`: startup, active or recovery. Each event is printed with its movie
## frame, EnterVan's frame and the door. A Movie Maker run (`--write-movie`, `--fixed-fps 30`).

const PHASES := {"startup": [16.0, "accelerate"], "active": [40.0, "pause"],
	"recovery": [56.0, "recover"]}
const SETTLE := 45
const AFTER := 75

var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _first_drawn := -1


func _initialize() -> void:
	call_deferred("_run")


func _process(_delta: float) -> bool:
	if _first_drawn < 0:
		_first_drawn = Engine.get_frames_drawn()
	return false


func _say(event: String) -> void:
	print("TAKE movie %d clip %.1f door %.3f boarding %s occupied %s paused %s: %s" % [
		Engine.get_frames_drawn() - _first_drawn, float(_driver.call("clip_time")) * 30.0,
		float(_van.get("driver_door")), _app.get("_boarding"), _van.get("occupied"), paused,
		event])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := args[0] if args.size() > 0 else "startup"
	var at: float = PHASES[phase][0]
	var action: String = PHASES[phase][1]
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-interrupt-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	_app.call("_new_drive")
	_app.set("_signed", true)
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	_driver.global_position = _app.call("_on_ground", _van.to_global(Vector3(-2.02, 0.0, -0.51)))
	_driver.velocity = Vector3.ZERO
	_driver.call("face", _van.global_basis.x)
	_driver.call("look_toward", _van.global_basis.x)
	for frame in range(SETTLE):
		await process_frame
	_say("E pressed (%s phase take)" % phase)
	await _press("interact")
	while float(_driver.call("clip_time")) * 30.0 < at or not bool(_app.get("_boarding")):
		await process_frame
	var before := _driver.global_position
	match action:
		"accelerate":
			_say("W held")
			_hold("accelerate", true)
			for frame in range(15):
				await process_frame
			_hold("accelerate", false)
			_say("W released; moved %.3f m" % _driver.global_position.distance_to(before))
		"pause":
			_say("Esc pressed")
			await _press("pause")
			for frame in range(3):
				await process_frame
			_say("paused")
			for frame in range(40):
				await process_frame
			_say("after 40 frames paused")
			await _press("pause")
			_say("Esc again: resumed")
		"recover":
			_say("R pressed")
			await _press("recover")
			for frame in range(3):
				await process_frame
			_say("after R")
	for frame in range(AFTER):
		await process_frame
	_say("end of take")
	quit(0)


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
	await process_frame


func _hold(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	event.strength = 1.0 if down else 0.0
	Input.parse_input_event(event)
