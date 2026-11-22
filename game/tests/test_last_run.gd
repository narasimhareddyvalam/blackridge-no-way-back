extends SceneTree
## Mission 3, Last Run, step 1: missions in a row (docs/PHASE_BRIEF.md, 2026-11-21, #359): Mission
## 2's end saves Mission 3's start (version 2, `last_run`, checkpoint 0, its opening to play);
## launched with that save, Continue names Last Run at the freight depot, and continuing starts
## Mission 3 there: Ethan in the van at the depot, the screen headed LAST RUN, the objective the
## waterfront; a Last Run file at a checkpoint it does not have is kept aside.

const AT_THE_END := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=4\n"
const BROKEN := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=40\n"
const DEPOT := Vector3(-28.0, 0.1, 93.0)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-last-run-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _build(AT_THE_END)
	_app.call("_begin")
	await _frames(20)
	var van := _app.get_node("FreightVan") as CharacterBody3D
	var points: PackedVector3Array = _app.get_node("IndustrialLoop").get("road_points")
	var end := points[990]
	var along := (points[986] - points[994]).normalized()
	van.call("recover", Transform3D(Basis.looking_at(along, Vector3.UP), end + Vector3.UP * 0.1))
	await _frames(40)
	var saved := ConfigFile.new()
	saved.load(_scratch)
	_check(saved.get_value("save", "version", 0) == 2 and saved.get_value("save", "mission", "")
		== "last_run" and int(saved.get_value("run", "stage", -1)) == 0
		and not saved.has_section("cargo"), ("L1: Mission 2's end saves Mission 3's start "
		+ "(%s, checkpoint %s)") % [saved.get_value("save", "mission", ""), saved.get_value("run",
		"stage", -1)])
	await _free()
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string("[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\n")
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	var named := _named("ContinuePlace")
	_app.call("_begin")
	await _frames(20)
	van = _app.get_node("FreightVan") as CharacterBody3D
	var hud := _app.get("hud") as CanvasLayer
	var eyebrow := (hud.get("_eyebrow") as Label).text
	var objective := (hud.get("_objective") as Label).text
	var off := Vector2(van.global_position.x - DEPOT.x, van.global_position.z - DEPOT.z).length()
	_check(named == "Last Run · The freight depot" and eyebrow == "LAST RUN"
		and objective == "DRIVE TO THE WATERFRONT" and bool(van.get("occupied")) and off < 0.5,
		("L2: Continue names it (%s) and starts Mission 3 at the depot (%.2f m off), headed %s, "
		+ "the objective %s") % [named, off, eyebrow, objective])
	await _free()
	file = FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(BROKEN)
	file.close()
	await _build("")
	var route := _app.get("route") as Node
	_check(route.get("handed_on") == null, "L3: a Last Run file at a checkpoint it has not got is "
		+ "kept aside")
	_finish()


func _build(save: String) -> void:
	if not save.is_empty():
		var file := FileAccess.open(_scratch, FileAccess.WRITE)
		file.store_string(save)
		file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame


func _named(node: String) -> String:
	var label := _app.find_child(node, true, false) as Label
	return label.text if label != null else ""


func _free() -> void:
	_app.queue_free()
	await process_frame
	await process_frame


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("LAST RUN RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	for kept in DirAccess.get_files_at(OS.get_temp_dir()):
		if kept.begins_with(_scratch.get_file()):
			DirAccess.remove_absolute(OS.get_temp_dir().path_join(kept))
	quit(1 if _failures > 0 else 0)
