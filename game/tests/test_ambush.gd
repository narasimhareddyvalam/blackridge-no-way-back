extends SceneTree
## Mission 3's step 3, part B: the ambush at berth 2 (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360):
## stopped in berth 2, the trap closes in a cutscene: two black SUVs light up between the stacks,
## three men in dark jackets with pistols, shots into the van, its windshield cracked, a phone falls
## into the cab; then GET OUT OF THE TERMINAL: an SUV races to block the gate; caught if it gets
## there first (and back at the berth, the cutscene not played again); out through the gate first,
## GET AWAY; well away, CHECK THE PHONE: E shows its messages from "M", whose number is Maya's, and
## stage 1 is saved.

const STAGE_ZERO := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\n"
const SUV_MODEL := "res://features/environments/harbour_flats/art/suburban/suburban.glb"
const MAN_MODEL := "res://features/characters/syndicate_man/syndicate_man.glb"
const GATE := Vector3(840.0, 0.0, 200.0)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _hud: CanvasLayer
var _run_mission: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-ambush-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_ZERO)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_run_mission = _app.get("run") as Node
	var front := _app.get_node("IndustrialLoop").get("harbour_flats").get("waterfront") as Node3D
	var berth: Vector3 = front.get("berth")
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), berth + Vector3.UP * 0.1))
	await _frames(40)
	var ambush := _run_mission.get("ambush") as Node
	if ambush == null:
		_check(false, "A1: stopped in berth 2 the trap closes (no ambush)")
		_finish()
		return
	await _check_trap(ambush)
	await _check_caught(ambush, berth)
	await _check_escape(ambush)
	await _check_phone()
	_finish()


## A1: stopped in berth 2, the cutscene plays: the SUVs' headlights on, the three men out with
## pistols in hand, the models the black Suburban and the man in the dark jacket.
func _check_trap(ambush: Node) -> void:
	var director := _app.get("cutscene") as Node
	var playing := false
	var lit := false
	var men_out := false
	var waited := 0.0
	while waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0
		playing = playing or bool(director.get("playing"))
		var suvs: Array = ambush.get("suvs")
		lit = lit or (suvs.size() == 2 and suvs.all(func(s: Node3D) -> bool:
			return bool(s.get("lights_on"))))
		var men: Array = ambush.get("men")
		men_out = men_out or (men.size() == 3 and men.all(func(m: Node3D) -> bool:
			return m.visible and m.find_child("Pistol", true, false) != null))
		if playing and not bool(director.get("playing")):
			break
	var suvs_right := (ambush.get("suvs") as Array).all(func(s: Node3D) -> bool:
		return String(s.get("model_path")) == SUV_MODEL)
	var men_right := (ambush.get("men") as Array).all(func(m: Node3D) -> bool:
		return String(m.get_meta("model", "")) == MAN_MODEL)
	var glass := _van.get_node("VanPresentation").call("crack_state") as Dictionary
	_check(playing and lit and men_out and suvs_right and men_right
		and float(glass["amount"]) > 0.0 and bool(ambush.get("phone_in_cab")), ("A1: at berth 2 "
		+ "the trap closes in a cutscene (%s): two black Suburbans light up (%s, %s), three men "
		+ "with pistols (%s, %s), shots crack the windshield (%.2f), a phone falls into the cab "
		+ "(%s)") % [playing, lit, suvs_right, men_out, men_right, float(glass["amount"]),
		ambush.get("phone_in_cab")])


## A2: staying put, the SUV blocks the gate and he is caught; back at the berth the escape starts
## again without the cutscene.
func _check_caught(ambush: Node, berth: Vector3) -> void:
	_check(_objective() == "GET OUT OF THE TERMINAL", "A2a: after it, GET OUT OF THE TERMINAL (%s)"
		% _objective())
	var caught_before: int = ambush.get("caught_count")
	var waited := 0.0
	var blocked := false
	while int(ambush.get("caught_count")) == caught_before and waited < 40.0:
		await physics_frame
		waited += 1.0 / 60.0
		blocked = blocked or bool(ambush.call("gate_blocked"))
	await _seconds(2.5)
	var director := _app.get("cutscene") as Node
	var back := _van.global_position.distance_to(berth) < 3.0 and bool(_van.get("occupied"))
	_check(int(ambush.get("caught_count")) == caught_before + 1 and blocked and waited > 8.0
		and back and not bool(director.get("playing")) and _objective()
		== "GET OUT OF THE TERMINAL", ("A2: staying, the SUV blocks the gate (%s) and he is caught "
		+ "(%.1f s); back at the berth (%s), no cutscene again, the escape on (%s)") % [blocked,
		waited, back, _objective()])


## A3: out through the gate before the SUV, by the accelerator, and he gets away.
func _check_escape(ambush: Node) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI / 2.0), GATE + Vector3(14.0, 0.1, 0.0)))
	await _frames(5)
	Input.action_press("accelerate")
	var waited := 0.0
	while _van.global_position.x > GATE.x - 30.0 and waited < 15.0:
		await physics_frame
		waited += 1.0 / 60.0
	Input.action_release("accelerate")
	await _frames(30)
	_check(bool(ambush.get("escaped")) and not bool(ambush.call("gate_blocked"))
		and _objective() == "GET AWAY", ("A3: through the gate before the SUV, he gets away "
		+ "(%s), GET AWAY (%s)") % [ambush.get("escaped"), _objective()])


## A4: well away and stopped, CHECK THE PHONE; E shows the messages from "M", Maya's number; stage 1
## saved.
func _check_phone() -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, 0.0), Vector3(726.0, 0.1, 60.0)))
	await _frames(40)
	var offered := (_hud.get("_hint") as Label).text
	var asked := _objective()
	await _press("interact")
	await _frames(10)
	var words := String(_hud.call("document_text"))
	var saved := ConfigFile.new()
	saved.load(_scratch)
	_check(asked == "CHECK THE PHONE" and offered == "E  Check the phone" and words.contains("M")
		and words.contains("BR 048") and words.to_lower().contains("maya")
		and int(saved.get_value("run", "stage", -1)) == 1, ("A4: away, CHECK THE PHONE (%s, %s); E "
		+ "shows the messages from M, Maya's number (%s); stage %s saved") % [asked, offered,
		words.replace("\n", " | "), saved.get_value("run", "stage", -1)])


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


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


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("AMBUSH RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
