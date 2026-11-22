extends SceneTree
## Mission 2's step 8, the opening, the depot's new job and Maya's call (docs/PHASE_BRIEF.md's
## Mission 2 brief; S2, S3 and S5 decided by Claude Code at the author's word, #358, drafts): with
## the save Mission 1's end leaves (Mission 2's start, its opening still to play), continuing
## plays Mission 2's opening, titled with the mission's name (C35), never the game's (C04); the
## windshield is new (S5); E skips it into the van at the depot, the save no longer asks for it,
## and a text from the new dispatcher brings the job, sealed and not to be inspected (S2); driving
## off, Maya calls and keeps him at it (S3). A plain stage 0 save has neither.

const HANDED_ON := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n" \
	+ "opening=true\n"
const PLAIN := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DRIVE_OFF := 90.0

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _hud: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-cargo-opening-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start(HANDED_ON)
	var director := _app.get("cutscene") as Node
	var playing := director != null and bool(director.get("playing"))
	var texts := " ".join(director.call("all_texts")) if director != null else ""
	var glass := _van.get_node("VanPresentation").get("_glass") as ShaderMaterial
	var crack: Variant = glass.get_shader_parameter("crack_amount") if glass != null else null
	_check(playing and texts.contains("THE WRONG CARGO") and not texts.contains("NO WAY BACK"),
		"MO1: continuing from Mission 1's end plays Mission 2's opening, titled THE WRONG CARGO, "
		+ "not the game's title (%s)" % texts)
	_check(glass != null and (crack == null or is_zero_approx(float(crack))), ("MO2: days later the windshield is new, "
		+ "no crack (%s)") % crack)
	await _seconds(1.3)
	await _press("interact")
	await _seconds(1.5)
	var saved := ConfigFile.new()
	saved.load(_scratch)
	var words := String(_hud.call("text_message"))
	_check(not bool(director.get("playing")) and bool(_van.get("occupied"))
		and not bool(saved.get_value("cargo", "opening", false))
		and words.to_lower().contains("transfer shed") and words.to_lower().contains("do not open"),
		("MO3: E skips it into the van at the depot; the save no longer asks for it (%s); a text "
		+ "from the new dispatcher brings the job, sealed (%s)") % [saved.get_value("cargo",
		"opening", false), words])
	var route := _app.get("route") as Node
	var call := route.get("phone_call") as Node
	var rang := await _drive_off(call)
	_check(rang and String(call.get("caller")) == "MAYA", ("MO4: driving off from the depot, "
		+ "Maya calls (%s)") % rang)
	var heard := ""
	var waited := 0.0
	call.call("answer")
	while waited < 40.0 and bool(call.get("active")):
		await process_frame
		waited += 1.0 / 60.0
		var line := String(_hud.call("subtitle"))
		if not heard.contains(line):
			heard += " | " + line
	_check(heard.contains("Keep at it"), "MO5: she keeps him at the work (%s)" % heard)
	await _free()
	await _start(PLAIN)
	director = _app.get("cutscene") as Node
	var plain_opening := director != null and bool(director.get("playing"))
	call = (_app.get("route") as Node).get("phone_call") as Node
	rang = await _drive_off(call)
	_check(not plain_opening and not rang, ("MO6: a plain Mission 2 start has no opening (%s) and "
		+ "no call (%s)") % [plain_opening, rang])
	(_app.get("route") as Node).call("_save_finished")
	var handed := ConfigFile.new()
	handed.load(_scratch)
	_check(int(handed.get_value("cargo", "stage", -1)) == 0 and bool(handed.get_value("cargo",
		"opening", false)), "MO7: Mission 1's end saves Mission 2's start with its opening to play")
	_finish()


func _start(save: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(save)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D


func _free() -> void:
	_app.queue_free()
	await process_frame
	await process_frame


## Moves the van DRIVE_OFF metres from where it starts, along the depot's way out, and says whether
## the phone rang within 8 s.
func _drive_off(call: Node) -> bool:
	var from := _van.global_transform
	_van.call("recover", from.translated(-from.basis.z * DRIVE_OFF))
	var waited := 0.0
	while waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
		if bool(call.get("active")):
			return true
	return false


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
	print("CARGO OPENING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
