extends SceneTree
## Mission 3's step 4, the confrontation and the proof (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360;
## GAME_STORY's Acts III-IV; every word a draft, N03 decided as a draft): on Last Run's stage 1
## save, DRIVE TO THE DEPOT, where Maya (Rocketbox's Female_Adult_07, MIT) waits by her car; stopped
## by her, the confrontation plays (she routed his jobs; she is married to Adrian Vale; their
## daughter Lily is five; Adrian has her) and ends days later; in the cab LISTEN TO THE RECORDING: E
## shows Adrian's offer, Maya's refusal and the records of her changed routes and warnings; then
## MEET MAYA AT THE VIEWPOINT; stopped there the reconciliation plays (she does not ask; he
## forgives; Adrian flies Lily out from the airfield tonight) and stage 2 is saved.

const STAGE_ONE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=1\n"
const MAYA := "res://features/characters/maya/maya.glb"

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
	_scratch = OS.get_temp_dir().path_join("blackridge-proof-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_ONE)
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
	var maya := _run_mission.get("maya") as Node3D
	var meet: Vector3 = _run_mission.get("depot_meeting")
	var target: Vector3 = _hud.get("target")
	_check(_objective() == "DRIVE TO THE DEPOT" and maya != null and maya.visible
		and String(maya.get_meta("model", "")) == MAYA and Vector2(target.x - meet.x,
		target.z - meet.z).length() < 3.0 and maya.global_position.distance_to(meet) < 8.0,
		("P1: DRIVE TO THE DEPOT (%s), Maya waiting there by her car (%s)") % [_objective(),
		maya != null and maya.visible])
	var heard := await _play_scene(meet, "confrontation")
	_check(heard.contains("Adrian Vale") and heard.contains("Lily") and heard.contains("five")
		and heard.to_lower().contains("routed") and not heard.contains("NO WAY BACK"),
		"P2: stopped by her, the confrontation: her routing, Adrian Vale, Lily, five (%s)" % heard)
	_check(_objective() == "LISTEN TO THE RECORDING" and (_hud.get("_hint") as Label).text
		== "E  Listen to the recording", "P3a: days later, in the cab, LISTEN TO THE RECORDING (%s)"
		% _objective())
	await _press("interact")
	await _frames(10)
	var words := String(_hud.call("document_text"))
	_check(words.contains("ADRIAN") and words.contains("No.") and words.to_lower().contains(
		"route") and words.to_lower().contains("warning"), ("P3: E plays it: Adrian's offer, "
		+ "Maya's refusal, the records of her changed routes and her warnings (%s)") % words
		.replace("\n", " | "))
	await _press("interact")
	await _frames(20)
	var view: Vector3 = _run_mission.get("viewpoint_meeting")
	target = _hud.get("target")
	_check(_objective() == "MEET MAYA AT THE VIEWPOINT" and Vector2(target.x - view.x,
		target.z - view.z).length() < 3.0 and maya.global_position.distance_to(view) < 8.0,
		("P4: MEET MAYA AT THE VIEWPOINT (%s), Maya there") % _objective())
	heard = await _play_scene(view, "reconciliation")
	var saved := ConfigFile.new()
	saved.load(_scratch)
	_check(heard.to_lower().contains("forgive") and heard.to_lower().contains("airfield")
		and int(saved.get_value("run", "stage", -1)) == 2 and _objective()
		== "INTERCEPT THE CONVOY", ("P5: at the viewpoint the reconciliation (%s); stage %s saved; "
		+ "INTERCEPT THE CONVOY (%s)") % [heard, saved.get_value("run", "stage", -1),
		_objective()])
	_finish()


## Stops the van by `place`, waits for the scene named `scene` to play through, and returns every
## subtitle heard.
func _play_scene(place: Vector3, scene: String) -> String:
	var along := (place - _van.global_position)
	along.y = 0.0
	_van.call("recover", Transform3D(Basis.looking_at(along.normalized(), Vector3.UP),
		place - along.normalized() * 6.0 + Vector3.UP * 0.1))
	var director := _app.get("cutscene") as Node
	var heard := ""
	var started := false
	var waited := 0.0
	while waited < 140.0:
		await process_frame
		waited += 1.0 / 60.0
		var playing := bool(director.get("playing"))
		if playing and not started:
			started = String((director.call("shot_names") as Array)[0]).begins_with(scene)
		var line := String(_hud.call("subtitle"))
		if not line.is_empty() and not heard.contains(line):
			heard += " | " + line
		if started and not playing:
			break
	await _frames(20)
	return heard


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
	print("PROOF RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
