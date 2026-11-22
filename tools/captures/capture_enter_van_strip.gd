extends SceneTree
## Assignment 7, Step 7: the frame strip of the committing action, EnterVan (CHANGE-BRIEF.md §9).
## A fixture capture in the running game: Mission 1's start at the depot at night, the van where it
## stands, the run sheet taken, Ethan on foot at the driver's door (BOARD_SPOT) facing it, seen
## from his own camera; E pressed by real input (`interact`). A Movie Maker run (`--write-movie`,
## `--fixed-fps 30`); the trigger falls on movie frame TRIGGER_AT plus the setup's frames, and each
## frame from 10 before it is logged: the capture frame (0 = 10 frames before E), the movie
## frame, EnterVan's frame, the door's opening, the boarding flag, the van occupied. Run from the
## repository root (see logs/animation/step7/README.md).

const BEFORE := 10
const AFTER := 80
const SETTLE := 45

var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _first_drawn := -1
var _trigger_drawn := -1


func _initialize() -> void:
	call_deferred("_run")


func _process(_delta: float) -> bool:
	if _first_drawn < 0:
		_first_drawn = Engine.get_frames_drawn()
	if _trigger_drawn >= 0 and _driver != null:
		var capture := Engine.get_frames_drawn() - _trigger_drawn + BEFORE
		if capture <= BEFORE + AFTER:
			print("STRIP capture %d movie %d clip %.2f door %.3f boarding %s occupied %s" % [
				capture, Engine.get_frames_drawn() - _first_drawn,
				float(_driver.call("clip_time")) * 30.0, float(_van.get("driver_door")),
				_app.get("_boarding"), _van.get("occupied")])
	return false


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-strip-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	_app.call("_new_drive")
	_app.set("_signed", true)
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	var spot: Vector3 = _app.call("_on_ground", _van.to_global(Vector3(-2.02, 0.0, -0.51)))
	_driver.global_position = spot
	_driver.velocity = Vector3.ZERO
	var door := _van.global_basis.x
	_driver.call("face", door)
	_driver.call("look_toward", door)
	for frame in range(SETTLE - BEFORE):
		await process_frame
	_trigger_drawn = Engine.get_frames_drawn() + BEFORE
	for frame in range(BEFORE):
		await process_frame
	print("STRIP E pressed at movie frame %d" % (Engine.get_frames_drawn() - _first_drawn))
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	for frame in range(AFTER):
		await process_frame
	quit(0)
