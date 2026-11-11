extends Node
## Step 2b's gate strips: the real main scene on Mission 2's start save, the van set on the spur
## 26 m before the gate, then driven only with the game's own actions (held driving actions and
## InputEventAction presses). Real keys and clicks are swallowed. Every event prints its frame.
## For r1's strip, once stopped the driver looks left at the booth, as a driver handing over a
## run sheet would, and ahead again when the barrier starts to rise.

const GAME = preload("res://app/first_drive.tscn")
const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const APPROACH := 26.0
const CRUISE := 3.5
const LOOK_AT_BOOTH := Vector2(-0.12, 1.3)

var app: Node3D
var van: CharacterBody3D
var shed: Node3D
var frame := -1
var phase := "settle"
var stopped_at := -1
var looked_ahead := false
var _path := ""


func _ready() -> void:
	_path = OS.get_user_data_dir().path_join("gate_take_progress.cfg")
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	app = GAME.instantiate() as Node3D
	app.process_mode = Node.PROCESS_MODE_PAUSABLE
	app.get_node("DrivingTrial").checkpoint_path = _path
	add_child(app)
	van = app.get_node("FreightVan")
	shed = app.get_node("IndustrialLoop").get("transfer_shed")


func _input(event: InputEvent) -> void:
	if event is InputEventAction:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	frame += 1
	var gate_z: float = shed.get("GATE_Z")
	var line_z: float = gate_z + float(shed.get("STOP_LINE_OUT"))
	var front := van.to_global(Vector3(0, 1, -2.52))
	match phase:
		"settle":
			if frame == 2:
				app.call("_begin")
			if frame == 12:
				van.call("recover", Transform3D(Basis.IDENTITY,
					Vector3(float(shed.get("LANE_X")), 0.1, gate_z + APPROACH)))
				if not bool(van.get("headlights_on")):
					_send("headlights")
				_send("wipers")
				_report("on the spur, %.0f m before the gate" % APPROACH)
				phase = "approach"
		"approach":
			_cruise(front.z > line_z + 0.9)
			if front.z <= line_z + 0.9:
				Input.action_release("accelerate")
				Input.action_press("brake")
				phase = "stopping"
				_report("braking for the line")
		"stopping":
			if absf(float(van.get("speed"))) < 0.05:
				Input.action_release("brake")
				stopped_at = frame
				phase = "stopped"
				_report("stopped, front %.2f m before the arm" % (front.z - gate_z))
		"stopped":
			if frame == stopped_at + 8:
				_look(LOOK_AT_BOOTH)
				_report("looking left at the booth")
			if frame == stopped_at + 20:
				_send("interact")
			if not looked_ahead and float(shed.call("barrier_angle")) > 0.0:
				looked_ahead = true
				_look(Vector2.ZERO)
				_report("looking ahead again")
			if bool(shed.call("barrier_open")):
				phase = "through"
				_report("barrier up")
		"through":
			_cruise(true)
			if front.z < gate_z - 12.0:
				Input.action_release("accelerate")
				Input.action_press("brake")
				phase = "done"
				_report("inside the yard")
	if frame % 15 == 0:
		_report("state")


func _cruise(go: bool) -> void:
	if go and absf(float(van.get("speed"))) < CRUISE:
		Input.action_press("accelerate")
	else:
		Input.action_release("accelerate")


func _look(target: Vector2) -> void:
	van.get_node("VanPresentation").set("_look_target", target)


func _send(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	_report("%s pressed and released" % action)


func _report(text: String) -> void:
	print(("TAKE frame %d: %s | phase %s, speed %.2f, front z %.2f, barrier %.0f deg, checking %s, "
		+ "window %.2f") % [frame, text, phase, float(van.get("speed")),
		van.to_global(Vector3(0, 1, -2.52)).z, float(shed.call("barrier_angle")),
		shed.call("checking"), float(van.get("left_window"))])
