extends SceneTree

const CARGO := "res://features/missions/the_wrong_cargo/the_wrong_cargo.gd"
const AT_THE_YARD := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const LOADED := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _cargo: Dictionary = {}
var _app: Node3D
var _hud: CanvasLayer
var _route: Node
var _van: CharacterBody3D
var _menu: Control


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(110.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-mission-two-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	if not ResourceLoader.exists(CARGO):
		_check(false, "Mission 2, The Wrong Cargo, has its own mission script (%s)" % CARGO)
		_finish()
		return
	_cargo = (load(CARGO) as Script).get_script_constant_map()
	await _check_mission_one_hands_on()
	await _check_title()
	await _check_continue()
	await _check_new_game()
	_remove()
	_finish()


func _check_mission_one_hands_on() -> void:
	await _build()
	_route.call("_save_finished")
	var saved := ConfigFile.new()
	_check(saved.load(_scratch) == OK and saved.get_value("save", "version", 0) == 2
		and saved.get_value("save", "mission", "") == "the_wrong_cargo"
		and saved.get_value("cargo", "stage", -1) == 0 and not saved.has_section("drive"),
		"Finishing Mission 1 saves Mission 2's start: version 2, the_wrong_cargo, checkpoint 0, "
		+ "and no Mission 1 section")
	await _free_app()


func _check_title() -> void:
	await _build()
	var start: Transform3D = _cargo.get("START", Transform3D())
	var eye: Vector3 = start * (_cargo.get("TITLE_EYE", Vector3.INF) as Vector3)
	var camera: Camera3D = _app.get("title_camera")
	var at := _van.global_position.distance_to(start.origin)
	_check(paused and _screen() == "title" and camera != null and root.get_camera_3d() == camera
		and camera.global_position.distance_to(eye) < 0.01 and at < 0.05,
		("Launched with that save, the title shows Mission 2's own scene: the van parked in the "
		+ "depot bay where Mission 1 ended, through the title camera (%.2f m from its spot)") % at)
	var named := _text_of("ContinuePlace")
	_check(_focus() == "Continue" and named == "The Wrong Cargo · The freight depot",
		"Continue comes first and names it (%s)" % named)
	_check(bool(_route.get("complete")) and _route.get("handed_on") != null
		and int(_route.get("stage")) == 0,
		"Mission 1 stays finished while the save is on Mission 2: no call, no encounter, no "
		+ "checkpoint of its own")
	await _free_app()


func _check_continue() -> void:
	_store(AT_THE_YARD)
	await _build()
	var named := _text_of("ContinuePlace")
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var start: Transform3D = _cargo.get("START", Transform3D())
	var off := Vector2(_van.global_position.x - start.origin.x,
		_van.global_position.z - start.origin.z).length()
	_check(named == "The Wrong Cargo · The container yard" and not paused
		and bool(_van.get("occupied")) and off < 0.5 and _eyebrow() == "THE WRONG CARGO",
		("Continue from Mission 2's third checkpoint names it (%s) and starts Mission 2 where its "
		+ "places stand today: Ethan in his van at the depot bay (%.2f m off), the screen headed "
		+ "The Wrong Cargo") % [named, off])
	await _key(KEY_ESCAPE)
	_check(paused and _screen() == "pause" and _text_of("Mission") == "THE WRONG CARGO"
		and _text_of("NextCheckpoint") == "The warehouse compound"
		and _text_of("LastSaved") == "The container yard",
		"Paused, Mission 2 names itself, its next checkpoint and its last save (%s; %s)"
		% [_text_of("NextCheckpoint"), _text_of("LastSaved")])
	await _key(KEY_ESCAPE)
	await _free_app()


func _check_new_game() -> void:
	_store(LOADED)
	await _build()
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	var asked := _screen() == "confirm" and _focus() == "ConfirmNo"
	await _key(KEY_LEFT)
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var saved := ConfigFile.new()
	_check(asked and saved.load(_scratch) == OK and saved.get_value("save", "version", 0) == 2
		and saved.get_value("save", "mission", "") == "night_freight"
		and saved.get_value("drive", "stage", -1) == 0 and not saved.has_section("cargo")
		and _objective() == "SIGN THE RUN SHEET" and _eyebrow() == "NIGHT FREIGHT",
		"New game, asked first, goes back to Mission 1's start at the office, saved as version 2")
	await _free_app()


func _screen() -> String:
	return String(_menu.call("screen"))


func _focus() -> String:
	var owner := root.gui_get_focus_owner()
	return String(owner.name) if owner != null else "(nothing)"


func _text_of(name: String) -> String:
	var node := _menu.find_child(name, true, false)
	return (node as Label).text if node is Label else ""


func _eyebrow() -> String:
	var label: Variant = _hud.get("_eyebrow")
	return (label as Label).text if label is Label else "(no mission name on the screen)"


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _build() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_hud = _app.get_node("DrivingHud")
	_route = _app.get_node("DrivingTrial")
	_van = _app.get_node("FreightVan")
	_menu = _hud.get("menu")
	await process_frame
	await process_frame


func _free_app() -> void:
	_app.queue_free()
	paused = false
	await process_frame
	await process_frame


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The Mission 2 checks finish within 110 s")
	_finish()


func _finish() -> void:
	print("MISSION TWO RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
