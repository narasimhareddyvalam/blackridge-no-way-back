extends SceneTree

const CARGO := "res://features/missions/the_wrong_cargo/the_wrong_cargo.gd"
const AT_THE_YARD := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const LOADED := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _cargo: Dictionary = {}
var _app: Node3D
var _hud: CanvasLayer
var _route: Node
var _van: CharacterBody3D
var _menu: Control
var _gate_shed: Node3D
var _gate_frames: int = 0
var _gate_hits: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(170.0, true, false, true).timeout.connect(_timeout)
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
	await _check_gate()
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


func _check_gate() -> void:
	_remove()
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	var shed: Node3D = _app.get_node("IndustrialLoop").get("transfer_shed")
	if shed == null:
		_check(false, "The world has a transfer shed with a gate (IndustrialLoop.transfer_shed)")
		await _free_app()
		return
	var gate_z: float = shed.get("GATE_Z")
	var lane_x: float = shed.get("LANE_X")
	_check(not bool(shed.call("barrier_open")) and _objective() == "DRIVE TO THE TRANSFER SHED",
		"At Mission 2's start the gate's barrier is down, and the objective is the transfer shed "
		+ "(%s)" % _objective())
	_van.call("recover", Transform3D(Basis.IDENTITY, Vector3(lane_x, 0.1, gate_z + 18.0)))
	await _seconds(0.5)
	_watch_gate(shed)
	await _hold(KEY_W, 5.0)
	await _hold(KEY_S, 1.5)
	var front := _van.to_global(VAN_FRONT).z
	_check(front > gate_z - 0.05 and not bool(shed.call("barrier_open")),
		"Driving at the closed barrier, the van stops against its arm: its front %.2f m short of "
		% (front - gate_z) + "the arm's line, and the barrier stays down")
	_check(_objective() == "STOP AT THE GATE" and _detail().contains("E"),
		"At the gate the objective asks for a stop and names E (%s: %s)" % [_objective(),
		_detail()])
	await _key(KEY_E)
	await _seconds(1.0)
	_check(bool(_van.get("occupied")) and not bool(shed.call("barrier_open")),
		"E at the gate hands the guard the run sheet instead of leaving the van; the barrier "
		+ "waits for the guard's check")
	await _seconds(8.0)
	_check(bool(shed.call("barrier_open")),
		"After the check the barrier is up within 8 s")
	await _hold(KEY_W, 4.0)
	var rear := _van.to_global(VAN_REAR).z
	_check(rear < gate_z - 1.0, "The van drives through the gate: its rear %.2f m past the arm"
		% (gate_z - rear))
	await _seconds(6.0)
	_check(not bool(shed.call("barrier_open")),
		"Once the van is clear, the barrier comes back down behind it")
	_check(_gate_hits == 0 and _gate_frames > 0,
		"Over %d physics frames the arm was never across the van while it was lower than fully up "
		% _gate_frames + "(%d frames it was)" % _gate_hits)
	_gate_shed = null
	await _free_app()


func _watch_gate(shed: Node3D) -> void:
	_gate_shed = shed
	_gate_frames = 0
	_gate_hits = 0
	while _gate_shed == shed and is_instance_valid(shed):
		await physics_frame
		if not is_instance_valid(_van):
			return
		_gate_frames += 1
		var gate_z: float = shed.get("GATE_Z")
		var front := _van.to_global(VAN_FRONT).z
		var rear := _van.to_global(VAN_REAR).z
		if front < gate_z - 0.05 and rear > gate_z + 0.05 and float(shed.call("barrier_angle")) < 80.0:
			_gate_hits += 1


func _hold(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(seconds)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _detail() -> String:
	var label: Variant = _hud.get("_detail")
	return (label as Label).text if label is Label else ""


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
	_check(false, "The Mission 2 checks finish within 170 s")
	_finish()


func _finish() -> void:
	print("MISSION TWO RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
