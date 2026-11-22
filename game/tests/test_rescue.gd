extends SceneTree
## Mission 3's step 7: Lily and Adrian (docs/PHASE_BRIEF.md, 2026-11-22, #359-#360; GAME_STORY's
## Act V: "Ethan reaches Lily and ensures she is moved to safety. Adrian confronts Ethan ... Adrian
## attacks or draws a weapon; Ethan kills him while defending himself and protecting Lily"; N04's
## draft: Lily out to Maya first). On Last Run's stage 4 save Lily waits in the hangar's office;
## FIND LILY. E by her takes her hand: TAKE LILY TO MAYA. She walks at his left side, her hand in
## his, and he walks at her pace (no running). At Maya by the service gate, Lily goes to her, and
## Adrian comes through the gate: a scene, his lines and theirs; he draws; Ethan fires once. No
## gore: black, then his pistol on the wet ground. After it the story goes home (step 8).

const STAGE_FOUR := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=4\n"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _hud: CanvasLayer
var _run_mission: Node
var _field: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-rescue-%d-%d.cfg" % [
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
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_driver = _app.get("driver") as CharacterBody3D
	_run_mission = _app.get("run") as Node
	_field = _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var lily := _run_mission.get("lily") as Node3D
	if lily == null:
		_check(false, "R1: Lily is in the hangar's office at stage 4 (none)")
		_finish()
		return
	_check_office(lily)
	await _check_hand(lily)
	await _check_lead(lily)
	await _check_scene(lily)
	_finish()


## R1: at stage 4, Lily in the office, the men gone; the van at the service gate, Maya there.
func _check_office(lily: Node3D) -> void:
	var office := _field.get("office") as Node3D
	var inside := office != null and lily.visible and _flat(lily.global_position,
		office.global_position) < 2.5
	var men := 0
	var encounter := _run_mission.get("encounter") as Node
	if encounter != null:
		for guard: Node3D in encounter.get("guards"):
			if guard.is_visible_in_tree():
				men += 1
	var gate: Vector3 = _field.get("service_gate")
	var maya := _run_mission.get("maya") as Node3D
	_check(inside and men == 0 and _flat(_van.global_position, gate) < 16.0 and maya.visible
		and _objective() == "FIND LILY", ("R1: stage 4: Lily in the office (%s), no man about (%d), "
		+ "the van at the service gate (%.1f m), Maya there (%s), FIND LILY (%s)") % [inside, men,
		_flat(_van.global_position, gate), maya.visible, _objective()])


## R2: by her, E takes her hand: she follows; TAKE LILY TO MAYA.
func _check_hand(lily: Node3D) -> void:
	_app.call("_stand_ethan", lily.global_position + Vector3(0.0, 0.0, -1.2), lily.global_position)
	await _frames(30)
	var offered := (_hud.get("_hint") as Label).text
	await _press("interact")
	await _frames(10)
	_check(offered == "E  Take Lily's hand" and bool(lily.get("following"))
		and _objective() == "TAKE LILY TO MAYA", ("R2: by her (%s) E takes her hand: she follows "
		+ "(%s); %s") % [offered, lily.get("following"), _objective()])


## R3: walking out with her, sprint held: he keeps to her pace; she keeps at his left side, her
## hand in his.
func _check_lead(lily: Node3D) -> void:
	var door: Vector3 = _field.get("office_door")
	_app.call("_stand_ethan", door + Vector3(0.0, 0.0, -4.0), door + Vector3(0.0, 0.0, -10.0))
	await _frames(5)
	lily.global_position = _driver.global_position + Vector3(-0.45, 0.0, 0.45)
	lily.call("lead", _driver)
	await _frames(20)
	_driver.call("look_toward", Vector3.FORWARD)
	Input.action_press("accelerate")
	Input.action_press("sprint")
	var fastest := 0.0
	var widest := 0.0
	var hands := 0.0
	var start := _driver.global_position
	for frame in range(240):
		await physics_frame
		if frame > 60:
			fastest = maxf(fastest, Vector2(_driver.velocity.x, _driver.velocity.z).length())
			widest = maxf(widest, _flat(lily.global_position, _driver.global_position))
			hands = maxf(hands, (lily.call("hand") as Vector3).distance_to(_driver.call(
				"left_hand") as Vector3))
	Input.action_release("sprint")
	Input.action_release("accelerate")
	var moved := _flat(_driver.global_position, start)
	_check(moved > 2.0 and fastest < 1.25 and widest < 1.2 and hands < 0.15, ("R3: led out (%.1f "
		+ "m), sprint held he walks at her pace (%.2f m/s), she at his side (%.2f m), her hand in "
		+ "his (%.2f m apart)") % [moved, fastest, widest, hands])


## R4: at Maya, Lily goes to her and Adrian comes: his scene; he draws; Ethan fires once; black;
## after it Adrian is down, Lily with Maya, and the story goes home.
func _check_scene(lily: Node3D) -> void:
	var maya := _run_mission.get("maya") as Node3D
	var gun := (_run_mission.get("encounter") as Node).get("handgun") as Node
	var shots_before: int = gun.get("shots")
	_app.call("_stand_ethan", maya.global_position + Vector3(1.0, 0.0, -3.5), maya.global_position)
	var waited := 0.0
	var played := false
	var adrian_seen := false
	var drew := false
	var black := false
	while waited < 60.0:
		await physics_frame
		waited += 1.0 / 60.0
		var cutscene := _app.get("cutscene") as Node
		played = played or bool(cutscene.get("playing"))
		var adrian := _run_mission.get("adrian") as Node3D
		adrian_seen = adrian_seen or (adrian != null and adrian.visible)
		drew = drew or (adrian != null and bool(adrian.get("drawn"))
			and float(adrian.get("_raise")) > 0.95)
		var film := cutscene.get("film") as Node
		black = black or (bool(cutscene.get("playing")) and (film.get("_black") as Control).visible)
		if played and not bool(cutscene.get("playing")):
			break
	await _frames(10)
	var adrian := _run_mission.get("adrian") as Node3D
	var with_maya := _flat(lily.global_position, maya.global_position) < 1.6
	_check(played and adrian_seen and drew and black and adrian != null and bool(adrian.get("down"))
		and int(gun.get("shots")) == shots_before + 1 and with_maya
		and String(_run_mission.get("story")) == "home", ("R4: at Maya the scene plays (%s), "
		+ "Adrian comes (%s), draws (%s), one shot (%d), black (%s), he is down (%s), Lily with "
		+ "Maya (%s), home (%s)") % [played, adrian_seen, drew, int(gun.get("shots"))
		- shots_before, black, adrian.get("down") if adrian != null else false, with_maya,
		_run_mission.get("story")])


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


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
	print("RESCUE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
