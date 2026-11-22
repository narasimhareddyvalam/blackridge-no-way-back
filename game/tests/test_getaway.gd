extends SceneTree
## Mission 2's step 7, the getaway and the ending (docs/PHASE_BRIEF.md's Mission 2 brief: "out of
## the container yard, west past the depot and up the hill road. The mission ends near road sample
## 990. Ending: a quiet beat in the cab, with no title (C04)"; #358), on Mission 2's stage 4 save
## (his van taken back in the yard's bay): DRIVE OUT, marked at the hill road; near it PULL OVER;
## passing it at speed does not end the mission; stopped there it ends as Mission 1 does, the cab
## quiet, the screen fading to black with no title, and the save holds Mission 3's start (#359).

const STAGE_FOUR := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=4\n"
const SAMPLE := 990
const STOP_WITHIN := 12.0

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
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-getaway-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_FOUR)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(20)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	var points: PackedVector3Array = _app.get_node("IndustrialLoop").get("road_points")
	var end := points[SAMPLE]
	var target: Vector3 = _hud.get("target")
	var white := (_van.get_node("VanPresentation").call("paint") as Color).is_equal_approx(
		Color.WHITE)
	_check(_objective().begins_with("DRIVE OUT") and Vector2(target.x - end.x, target.z - end.z)
		.length() < 1.0 and bool(_van.get("occupied")) and white and bool(_van.get("sealed")),
		("G1: his van taken back, in it, white and sealed: DRIVE OUT (%s), marked at road sample "
		+ "990 (%.1f m off)") % [_objective(), Vector2(target.x - end.x, target.z - end.z)
		.length()])
	var along := (points[SAMPLE - 4] - points[SAMPLE + 4]).normalized()
	var approach := points[SAMPLE + 30]
	_van.call("recover", Transform3D(Basis.looking_at(along, Vector3.UP), approach
		+ Vector3.UP * 0.1))
	await _frames(20)
	_check(_objective().begins_with("PULL OVER"), "G2: near the hill road, PULL OVER (%s)"
		% _objective())
	var run_up := points[SAMPLE + 8]
	var aim := Vector3(end.x - run_up.x, 0.0, end.z - run_up.z).normalized()
	_van.call("recover", Transform3D(Basis.looking_at(aim, Vector3.UP), run_up + Vector3.UP
		* 0.1))
	await _frames(10)
	Input.action_press("accelerate")
	var passed := false
	var ended_at_speed := false
	var waited := 0.0
	while waited < 25.0:
		await physics_frame
		waited += 1.0 / 60.0
		var at := _van.global_position
		if Vector2(at.x - end.x, at.z - end.z).length() < STOP_WITHIN \
				and absf(float(_van.get("speed"))) > 3.0:
			passed = true
		ended_at_speed = ended_at_speed or bool(_app.get("_ending"))
		if passed and Vector2(at.x - end.x, at.z - end.z).length() > STOP_WITHIN + 3.0:
			break
	Input.action_release("accelerate")
	_check(passed and not ended_at_speed, ("G3: driving past it at speed does not end the "
		+ "mission (passed %s, ended %s)") % [passed, ended_at_speed])
	_van.call("recover", Transform3D(Basis.looking_at(along, Vector3.UP), end + Vector3.UP * 0.1
		- along * 4.0))
	await _frames(30)
	var ending := false
	var cinematic := false
	waited = 0.0
	while waited < 5.0 and not ending:
		await physics_frame
		waited += 1.0 / 60.0
		ending = bool(_app.get("_ending"))
	await _frames(5)
	cinematic = not (_hud.get("_objective") as Label).is_visible_in_tree()
	var quiet := not bool(_van.get("engine_on"))
	var saved := ConfigFile.new()
	saved.load(_scratch)
	var stage: int = saved.get_value("run", "stage", -1)
	var mission: String = saved.get_value("save", "mission", "")
	_check(ending and cinematic and quiet and mission == "last_run" and stage == 0,
		("G4: stopped there, the mission ends as Mission 1's: the HUD gone (%s), the engine off "
		+ "(%s); the save holds Mission 3's start (%s, stage %d)") % [cinematic, quiet,
		mission, stage])
	var titled := false
	waited = 0.0
	while waited < 20.0 and not titled:
		await process_frame
		waited += 1.0 / 60.0
		titled = bool(_app.get("_on_title"))
	var said := ""
	var cutscene := _app.get("cutscene") as Node
	if cutscene != null:
		said = " ".join(cutscene.call("all_texts"))
	_check(titled and not said.contains("BLACKRIDGE: NO WAY BACK"), ("G5: then black, and back "
		+ "to the title screen, with no title card on the way (title %s)") % titled)
	_finish()


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("GETAWAY RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
