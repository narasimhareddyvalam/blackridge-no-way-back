extends Node
## The in-play take of the Assignment 6 film. It runs the real main scene, started in the van as
## the tests and previews start it, and drives it only with the game's own actions: the switches
## as input events, the way a player's keys send them (InputEventAction), and the held driving
## actions the van polls. Real keys and clicks are swallowed, so a stray touch cannot leak into the
## take. This node keeps running while the game is paused, to count frames and resume it; the game
## under it is pausable, as under the real main scene's root. Run on an isolated copy of game/ with
## Movie Maker at 30 fps; frames count rendered frames from 0, and every input and the state it
## changes is printed with its frame.

const GAME = preload("res://app/first_drive.tscn")
const PRESSES := {
	45: "wipers",
	255: "pause",
	315: "pause",
	345: "change_gear",
}
const HOLD_FROM := 360
const HOLD_TO := 450

var app: Node3D
var van: CharacterBody3D
var effects: Node3D
var frame := -1


func _ready() -> void:
	app = GAME.instantiate() as Node3D
	app.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(app)
	van = app.get_node("FreightVan")
	effects = van.get_node("VanPresentation").get("particles")
	app.call("_resume")
	_report("start, in the van")


func _input(event: InputEvent) -> void:
	if event is InputEventAction:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	frame += 1
	if PRESSES.has(frame):
		_send(PRESSES[frame])
	if frame == HOLD_FROM:
		Input.action_press("handbrake")
		Input.action_press("accelerate")
		_report("handbrake and accelerate held")
	if frame == HOLD_TO:
		Input.action_release("accelerate")
		Input.action_release("handbrake")
		_report("both let go")
	if frame % 15 == 0 or PRESSES.has(frame - 1):
		_report("state")


func _send(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	_report("%s pressed and released" % action)


func _report(text: String) -> void:
	print("TAKE frame %d: %s | paused %s, wipers %d, gear %d, speed %.2f, flicks %d, exhaust %.2f" % [
		frame, text, get_tree().paused, van.wiper_setting, van.gear, van.actual_speed,
		effects.flicks_fired, effects.exhaust.amount_ratio])
