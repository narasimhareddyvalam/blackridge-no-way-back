extends "res://previews/preview_fixture.gd"
## EnterVan's frame strip (Assignment 7, CHANGE-BRIEF.md §4, §9 and its Step 7 revision): Mission 1's
## start at the depot at night, the van where it stands, the run sheet treated as signed, Ethan
## placed at the driver's door (BOARD_SPOT) facing it and seen from his own camera; E pressed as a
## key event on TRIGGER_FRAME, so the app's own boarding plays EnterVan and seats him. Every frame
## from the trigger reports EnterVan's frame, the door's opening, boarding and seated. EnterVan's
## frame N falls on movie frame TRIGGER_FRAME + 2 + N (one frame for the walk to BOARD_SPOT, one for
## the clip's first tick): read the trigger and 12, 34, 44, 60, 65, 70, 74 and 82. The driving HUD
## stays shown, unlike Assignment 6's previews: boarding's fade to black is drawn by it. Capture with
## --quit-after 100.

const BOARD_SPOT := Vector3(-2.02, 0.0, -0.51)
const TRIGGER_FRAME := 10
const LAST_FRAME := 95

var _driver: CharacterBody3D
var _ours: InputEventAction


func set_up() -> void:
	app.call("_new_drive")
	app.set("_signed", true)
	(app.get_node("DrivingHud") as CanvasLayer).visible = true
	_driver = app.get("driver")
	_driver.global_position = app.call("_on_ground", van.to_global(BOARD_SPOT))
	_driver.velocity = Vector3.ZERO
	_driver.call("face", van.global_basis.x)
	_driver.call("look_toward", van.global_basis.x)


func on_frame(number: int) -> void:
	if number == 0:
		report("EnterVan at the depot, Ethan at the driver's door; E on frame %d" % TRIGGER_FRAME)
	if number == TRIGGER_FRAME:
		_send(true)
		report("E pressed")
	elif number == TRIGGER_FRAME + 1:
		_send(false)
	if number >= TRIGGER_FRAME and number <= LAST_FRAME:
		report("EnterVan frame %.1f, door %.3f, boarding %s, seated %s" % [
			float(_driver.call("clip_time")) * 30.0, float(van.get("driver_door")),
			app.get("_boarding"), van.get("occupied")])


## The preview's own key event, let through to the game as a player's E would be.
func _input(event: InputEvent) -> void:
	if event == _ours:
		return
	super(event)


func _send(down: bool) -> void:
	_ours = InputEventAction.new()
	_ours.action = &"interact"
	_ours.pressed = down
	get_viewport().push_input(_ours)
