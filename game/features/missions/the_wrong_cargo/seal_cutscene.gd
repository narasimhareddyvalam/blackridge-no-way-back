extends Node
## The dock hand's round to seal the van, shown (the audit's fourth fix, #333): from the cab or at
## the van's back the player would see none of it. Once the shed sends him out, the player's
## control is held and the HUD hidden; Ethan, on foot by the doors he has just shut, steps clear
## to the van's far side; and a camera cuts to a new place as the hand reaches each part of his
## round, in real time (the author's choice), turning to keep him in its view: at his desk, on the
## dock stair, out of the side door, along the apron, and behind the van as he seals, checks
## and ticks the seal log as he sees it, the log up before him and his pen on its row (#337);
## then, as he walks back, close on the hasp, the bolt seal on it, before it cuts to the player's
## own camera. E, Enter or Space skips to the end; the hand carries on as he is.

## Where Ethan stands clear, in the van's frame: beside its rear quarter on the side away from
## the hand's way.
const CLEAR_SPOT := Vector3(1.5, 0.0, 2.4)
## Each shot: its name and the camera's place in the world (in the van's frame for the last).
const DESK_EYE := Vector3(-44.4, 2.9, 16.6)
const STAIR_EYE := Vector3(-41.0, 2.2, 13.4)
const DOOR_EYE := Vector3(-37.8, 1.7, 19.4)
const APRON_EYE := Vector3(-37.0, 2.4, 23.0)
const DOORS_EYE := Vector3(1.85, 1.6, 4.5)
## The seal shot, in the van's frame: 0.9 m behind its doors, a little to one side.
const SEAL_EYE := Vector3(-0.45, 1.2, 3.9)
## The paper shot as he sees it, in his frame from his feet (across to his right, up and ahead):
## beside his right eye, under his hard hat's brim, 23 degrees off the page's face held up to his
## eyes, so his shoulder is not between (#337); and its width, the page filling the picture.
const PAPER_EYE := Vector3(0.14, 1.62, 0.1)
const PAPER_FOV := 35.0
const CHEST := 1.25
## Where each shot begins: the stair's landing; in the side door's opening (the shed's east wall
## at x -40), seen from just past the parked trailer's end (z 17.85), clear of its opened leaf
## and 1.3 m off his way;
## out along the wall past the door (its opening ends at z 17.95); and this near the van's doors.
const LANDING := Vector3(-44.0, 1.3, 12.66)
const AT_LANDING := 1.6
const OUTSIDE_X := -40.2
const PAST_DOOR_Z := 18.95
const AT_VAN := 4.0
const AFTER := 3.0
## The seal shot waits until he has walked this far from the hasp: turning to go back from where
## he noted, 0.78 m out, his body is 0.5 m from its lens and in its picture.
const CLEAR_OF_SEAL := 1.0
const DOOR_OPEN := 0.95
const FOV := 50.0

var playing := false
var shot := ""
var shots: Array[String] = []
var camera: Camera3D

var _hud: CanvasLayer
var _driver: CharacterBody3D
var _van: Node3D
var _worker: Node3D
var _side_door: Node3D
var _before: Camera3D
var _back_for := 0.0
var _down := false
var _out := false
var _along := false


func setup(hud: CanvasLayer, driver: CharacterBody3D, van: Node3D, shed: Node3D) -> void:
	_hud = hud
	_driver = driver
	_van = van
	_worker = shed.get("dock_worker") as Node3D
	_side_door = shed.get("side_door") as Node3D
	camera = Camera3D.new()
	camera.name = "SealCutsceneCamera"
	camera.fov = FOV
	add_child(camera)
	shed.connect("dock_hand_called", play)


func play(van: Node3D) -> void:
	if playing or _worker == null:
		return
	_van = van
	playing = true
	shot = ""
	shots.clear()
	_back_for = 0.0
	_down = false
	_out = false
	_along = false
	_before = get_viewport().get_camera_3d()
	_hud.call("set_cinematic", true)
	_driver.set("held", true)
	if not bool(_van.get("occupied")):
		var spot := _van.to_global(CLEAR_SPOT)
		spot.y = _driver.global_position.y
		_driver.call("walk_to", [spot] as Array[Vector3])
	_frame()


## Ends the cutscene now: the player's own camera, the HUD and his control back.
func skip() -> void:
	if not playing:
		return
	playing = false
	shot = ""
	if is_instance_valid(_before):
		_before.make_current()
	_hud.call("set_cinematic", false)
	_driver.set("held", false)


func _process(delta: float) -> void:
	if not playing:
		return
	if String(_worker.get("state")) == "seated":
		skip()
		return
	if shot == "seal":
		_back_for += delta
		if _back_for >= AFTER:
			skip()
			return
	_frame()


## The shot the hand's place calls for, cut to when it changes, the camera turned to him.
func _frame() -> void:
	var at := _worker.global_position
	_down = _down or at.distance_to(LANDING) < AT_LANDING
	_out = _out or (at.x > OUTSIDE_X and (_side_door == null
		or float(_side_door.call("swung")) >= DOOR_OPEN))
	_along = _along or (_out and at.z > PAST_DOOR_Z)
	var doors: Vector3 = _van.call("seal_point")
	var near_van := Vector2(at.x - doors.x, at.z - doors.z).length() < AT_VAN \
		or String(_worker.get("state")) in ["setting_down", "to_hasp", "sealing", "checking",
		"to_log", "taking_up", "passing", "noting", "back", "turning"] and _out
	var leaving := String(_worker.get("state")) == "back" \
		and Vector2(at.x - doors.x, at.z - doors.z).length() > CLEAR_OF_SEAL
	var reading := bool(_worker.call("writing"))
	var wanted := "seal" if leaving or shot == "seal" else "paper" if reading else ("doors"
		if near_van
		else ("apron" if _along else ("door" if _out else ("stair" if _down else "desk"))))
	if wanted != shot:
		shot = wanted
		shots.append(wanted)
		match wanted:
			"desk":
				camera.global_position = DESK_EYE
			"stair":
				camera.global_position = STAIR_EYE
			"door":
				camera.global_position = DOOR_EYE
			"apron":
				camera.global_position = APRON_EYE
			"doors":
				camera.global_position = _van.to_global(DOORS_EYE)
			"seal":
				camera.global_position = _van.to_global(SEAL_EYE)
			"paper":
				var ahead := (_worker.get_node("Model") as Node3D).global_basis.z
				ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
				var right := ahead.cross(Vector3.UP)
				camera.global_position = at + right * PAPER_EYE.x + Vector3.UP * PAPER_EYE.y \
					+ ahead * PAPER_EYE.z
		camera.fov = PAPER_FOV if wanted == "paper" else FOV
		camera.make_current()
	var look := at + Vector3.UP * CHEST
	if shot == "doors":
		look = (look + doors) / 2.0
	elif shot == "seal":
		look = doors
	elif shot == "paper":
		look = _worker.call("paper_point")
	if not camera.global_position.is_equal_approx(look):
		camera.look_at(look, Vector3.UP)
