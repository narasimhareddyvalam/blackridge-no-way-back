extends SceneTree
## Last Run's spoken scenes let go of their lines when they end (found recording Mission 3, #451:
## the gate scene and the reunion hand `_talk` the scripts' own constant arrays, which are
## read-only, so `_lines.clear()` failed, 982 times in one recording ("Array is in read-only
## state"), and the finished scene's lines stayed, `_talk` running on every frame after its last
## line, clearing the subtitles and setting Maya to Idle again and again).
## L1: a scene whose lines are spoken through ends with no lines left; the script is unchanged.
## L2: the end of the gate scene leaves no lines (its own clear, `_run_gate_scene`).

const Scenes = preload("res://features/missions/last_run/story_scenes.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-scene-lines-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	var run := app.get("run") as Node
	run.call("_place_maya", false)
	var size := Scenes.GATE_LINES.size()
	var last: Array = Scenes.GATE_LINES[size - 1]
	run.set("_lines", Scenes.GATE_LINES)
	run.set("_line_next", size)
	run.set("_line_clock", float(last[0]) + float(last[3]) + 1.0)
	var ended := bool(run.call("_talk", 0.0))
	_check(ended and (run.get("_lines") as Array).is_empty()
		and Scenes.GATE_LINES.size() == size, ("L1 spoken through, the gate scene's lines end "
		+ "(ended %s, left %d, the script still %d lines)") % [ended,
		(run.get("_lines") as Array).size(), Scenes.GATE_LINES.size()])
	run.set("_lines", Scenes.REUNION_LINES)
	run.set("_line_next", 0)
	run.call("_drop_lines")
	_check((run.get("_lines") as Array).is_empty() and not Scenes.REUNION_LINES.is_empty(),
		"L2 the end of a scene drops its lines and leaves the script as written")
	print("SCENE LINES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
