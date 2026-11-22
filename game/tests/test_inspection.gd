extends SceneTree
## Mission 2's step 3, the inspection (docs/PHASE_BRIEF.md's Mission 2 brief: "the seal number,
## the manifest and how low the van sits do not agree; the first trace of Vale Freight appears
## (S4); the seal stays unbroken"; S4 decided by Claude Code at the author's word, #358, a draft),
## on Mission 2's stage 1 save with the seal just checked (that check by real keys is
## `test_sealing.gd`'s): READ THE BILL OF LADING; in the cab the key prompt offers it; E shows the
## bill with the dock scale's ticket stapled to it, 410 kg declared against 1,180 kg weighed, a
## correction label over the shipper with VALE FREIGHT showing at its edge, and "do not inspect";
## the seal stays whole; then DRIVE TO THE CONTAINER YARD. A reload at stage 1 does not ask again.

const STAGE_ONE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const SEAL := "4182260"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _hud: CanvasLayer
var _cargo: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-inspection-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_ONE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_cargo = _app.get("cargo") as Node
	_app.call("_begin")
	await _frames(20)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_check(_objective() == "DRIVE TO THE CONTAINER YARD", ("I1: a reload at stage 1 goes on to "
		+ "the container yard, the bill already read (%s)") % _objective())
	_cargo.call("_check_seal")
	_app.call("_close_run_sheet")
	await _frames(20)
	var offered := (_hud.get("_hint") as Label).text
	_check(_objective() == "READ THE BILL OF LADING" and offered == "E  Read the bill of lading",
		("I2: the seal checked, READ THE BILL OF LADING (%s), the prompt in the cab (%s)")
		% [_objective(), offered])
	await _press("interact")
	await _frames(10)
	var words := String(_hud.call("document_text"))
	var told := (_hud.get("_notice") as Label).text
	_check(words.contains("410 KG") and words.contains("1,180 KG") and words.contains("VALE "
		+ "FREIGHT") and words.contains("DO NOT INSPECT") and words.contains(SEAL),
		"I3: E shows the bill: 410 kg declared, 1,180 kg on the dock's scale, VALE FREIGHT at the "
		+ "label's edge, do not inspect, the seal's number (%s)" % words.replace("\n", " | "))
	_check(bool(_van.get("sealed")) and str(_van.get("seal_number")) == SEAL
		and told.contains("1,180"), ("I4: the seal stays whole (%s), and Ethan notes the weight "
		+ "(%s)") % [_van.get("sealed"), told])
	await _press("interact")
	await _frames(20)
	_check(not bool(_hud.call("document_visible")) and _objective()
		== "DRIVE TO THE CONTAINER YARD", ("I5: E puts it away; DRIVE TO THE CONTAINER YARD (%s)")
		% _objective())
	_finish()


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


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("INSPECTION RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
