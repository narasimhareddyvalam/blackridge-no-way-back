extends SceneTree
## Mission 3's step 8: home, the watcher, black, the title (docs/PHASE_BRIEF.md, 2026-11-22,
## #359-#360; GAME_STORY's "Resolution" and "Final cinematic"; C04: the hopeful family ending,
## the watcher, the cut to black and the title, in that order; C42: the title only after the black
## hold). After the gate scene: Maya and Lily together, Ethan and Maya speak about the past, police
## lights coming; a card: that night he told the police everything, the hill road included (N05's
## draft); SIX MONTHS LATER. Then the family home on a late afternoon in sunlight, its own world
## (no rain): Maya and Ethan's exchange word for word, Lily's "Uncle Ethan! You promised we'd go
## for a drive!", the van leaving; the empty driveway held; the black sedan across the street, the
## man photographing the house; the phone's four messages word for word; he drives away; absolute
## black held two beats; only then BLACKRIDGE: NO WAY BACK; then the title screen.

const STAGE_FOUR := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=4\n"
const FAMILY := "This time, it's not about looking after you. It's about being a family."
const PROMISE := "Uncle Ethan! You promised we'd go for a drive!"
const PHONE: Array[String] = ["Found them.", "All three?", "Yes.", "Don't approach them. Not yet."]
const TITLE := "BLACKRIDGE: NO WAY BACK"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _driver: CharacterBody3D
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
	create_timer(900.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-ending-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_FOUR)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(30)
	_driver = _app.get("driver") as CharacterBody3D
	_run_mission = _app.get("run") as Node
	await _to_the_gate_scene()
	await _check_night()
	await _check_home()
	_finish()


## Lily's hand taken, at Maya: the gate scene plays to its end.
func _to_the_gate_scene() -> void:
	var lily := _run_mission.get("lily") as Node3D
	_app.call("_stand_ethan", lily.global_position + Vector3(0.0, 0.0, -1.2), lily.global_position)
	await _frames(20)
	await _press("interact")
	var maya := _run_mission.get("maya") as Node3D
	_app.call("_stand_ethan", maya.global_position + Vector3(1.0, 0.0, -3.5), maya.global_position)
	await _frames(2)
	lily.global_position = _driver.global_position + Vector3(-0.45, 0.0, 0.3)
	var waited := 0.0
	while String(_run_mission.get("story")) != "home" and waited < 80.0:
		await physics_frame
		waited += 1.0 / 60.0


## E1: after it, the reunion: their words, police lights coming, the statement card, SIX MONTHS
## LATER.
func _check_night() -> void:
	var cutscene := _app.get("cutscene") as Node
	var heard: Array[String] = []
	var lights := false
	var played := false
	var waited := 0.0
	while waited < 60.0:
		await physics_frame
		waited += 1.0 / 60.0
		played = played or bool(cutscene.get("playing"))
		var said := String(_hud.call("subtitle"))
		if said != "" and (heard.is_empty() or heard[-1] != said):
			heard.append(said)
		lights = lights or (_run_mission.get("police") != null
			and (_run_mission.get("police") as Node3D).is_visible_in_tree())
		if _run_mission.get("epilogue") != null and bool((_run_mission.get("epilogue") as Node)
				.get("playing")):
			break
	var texts: Array = cutscene.call("all_texts")
	var statement := texts.any(func(text: String) -> bool: return "EVERYTHING" in text)
	var later := texts.has("SIX MONTHS LATER")
	var hill := texts.any(func(text: String) -> bool: return "HILL ROAD" in text)
	var spoke := heard.any(func(line: String) -> bool: return line.begins_with("MAYA:")) \
		and heard.any(func(line: String) -> bool: return "hill road" in line)
	_check(played and spoke and lights and statement and hill and later, ("E1: the reunion plays "
		+ "(%s), they speak, the hill road named (%s), police lights coming (%s), the statement "
		+ "card (%s, the hill road %s), SIX MONTHS LATER (%s)") % [played, spoke, lights, statement,
		hill, later])


## E2-E5: the home in sunlight, its own world without rain; the story's words; the phone's four
## messages in order; black held two beats before the title; then the title screen, the sound back.
func _check_home() -> void:
	var epilogue := _run_mission.get("epilogue") as Node
	if epilogue == null:
		_check(false, "E2: the epilogue plays (none)")
		return
	var world := epilogue.get("world") as Node
	var sun := world.find_children("*", "DirectionalLight3D", true, false)
	var rain := world.find_children("*", "GPUParticles3D", true, false)
	var lit := not sun.is_empty() and (sun[0] as DirectionalLight3D).light_energy > 1.0
	var muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience"))
	var shown: Array[String] = []
	var black_at := -1.0
	var title_at := -1.0
	var title_before_black := false
	var clock := 0.0
	while bool(epilogue.get("playing")) and clock < 140.0:
		await physics_frame
		clock += 1.0 / 60.0
		for text: String in epilogue.call("texts_now"):
			if not shown.has(text):
				shown.append(text)
		if bool(epilogue.call("is_black")) and black_at < 0.0:
			black_at = clock
		if bool(epilogue.call("title_shown")) and title_at < 0.0:
			title_at = clock
			title_before_black = black_at < 0.0
	var words := " ".join(shown)
	_check(lit and rain.is_empty() and muted, ("E2: the home in sunlight (%s), its world without "
		+ "rain (%d emitters), the night's rain and engines muted (%s)") % [lit, rain.size(),
		muted])
	_check(FAMILY in words.replace("ETHAN: ", "") and PROMISE in words, ("E3: Maya and Ethan's "
		+ "words (%s) and Lily's promise (%s), as written") % [FAMILY in words.replace("ETHAN: ",
		""), PROMISE in words])
	var order: Array[int] = []
	for message in PHONE:
		order.append(shown.find(message))
	var in_order := not order.has(-1) and order[0] < order[1] and order[1] < order[2] \
		and order[2] < order[3]
	_check(in_order, "E4: the phone's four messages, word for word, in order (%s)" % [order])
	await _frames(120)
	var titled := bool(_app.get("_on_title"))
	_check(black_at > 0.0 and title_at - black_at >= 1.6 and not title_before_black
		and not shown.slice(0, maxi(shown.find(TITLE), 0)).has(TITLE) and shown.has(TITLE)
		and titled and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")),
		("E5: absolute black at %.1f s, the title %.1f s after it and never before, then the title "
		+ "screen (%s), the sound back") % [black_at, title_at - black_at, titled])


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
	print("ENDING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
