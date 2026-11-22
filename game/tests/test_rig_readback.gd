extends SceneTree
## Assignment 7's read-back of the committing action, EnterVan (CHANGE-BRIEF.md §4), on Ethan's
## imported rig (`ethan.glb`, Mixamo's "Entering Car"): its tracks resolve to real bones, its
## length is the 164 frames measured at the importer's 30 fps, its step is one frame period, and it
## plays once, LOOP_NONE, set in the importer's per-animation settings (`ethan.glb.import`,
## `_subresources` -> `animations` -> `EnterVan` -> `settings/loop_mode`), never in a scene, so it
## survives a reimport. Run it from an empty import cache to prove that. Times compare with a
## tolerance of half a frame period, never ==.

const Readback = preload("res://tests/animation_readback.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const FPS := 30.0
const FRAMES := 164
const CLIP := "EnterVan"
const APP := "res://app/first_drive.gd"
## The phase table's frames the boarding sequence reads (CHANGE-BRIEF.md §4), at 30 fps.
const MOMENTS := {"REACH_FROM": 22, "DOOR_GRAB": 32, "DOOR_OPENED": 48, "CUT": 62}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	await process_frame
	var players := model.find_children("*", "AnimationPlayer", true, false)
	check("E1 the rig has one AnimationPlayer (%d)" % players.size(), players.size() == 1)
	if players.size() != 1:
		_finish()
		return
	var player := players[0] as AnimationPlayer
	var problems := Readback.track_problems(player)
	check("E2 every track of every clip resolves (node, bone) %s" % [problems.slice(0, 5)],
		problems.is_empty())
	check("E3 the clip '%s' exists" % CLIP, player.has_animation(CLIP))
	var clip := player.get_animation(CLIP)
	var tol := 0.5 / FPS
	var bones := 0
	for t in clip.get_track_count():
		if clip.track_get_type(t) in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D,
				Animation.TYPE_SCALE_3D]:
			bones += 1
	check("E4 its tracks are bone tracks on the skeleton (%d of %d)" % [bones,
		clip.get_track_count()], bones > 0 and bones == clip.get_track_count())
	check("E5 length %.4f s is %d frames at %d fps" % [clip.length, FRAMES, FPS],
		absf(clip.length - FRAMES / FPS) < tol)
	check("E6 step is one frame period (%.5f, 1/30 = %.5f)" % [clip.step, 1.0 / FPS],
		absf(clip.step - 1.0 / FPS) < 0.0001)
	check("E7 it plays once (loop_mode %d, LOOP_NONE)" % clip.loop_mode,
		clip.loop_mode == Animation.LOOP_NONE)
	var settings := ConfigFile.new()
	var opened := settings.load(RIG + ".import")
	var subresources: Dictionary = settings.get_value("params", "_subresources", {})
	var animations: Dictionary = subresources.get("animations", {})
	var own: Dictionary = animations.get(CLIP, {})
	var fps := float(settings.get_value("params", "animation/fps", 0.0))
	check("E8 its loop mode is set in the importer: %s _subresources animations %s %s" % [
		RIG.get_file() + ".import", CLIP, own], opened == OK
		and own.has("settings/loop_mode") and int(own["settings/loop_mode"]) == Animation.LOOP_NONE)
	check("E9 the importer samples at %d fps (%.0f)" % [FPS, fps], is_equal_approx(fps, FPS))
	var constants := (load(APP) as GDScript).get_script_constant_map()
	for moment in MOMENTS:
		var seconds := float(constants.get(moment, -1.0))
		check("E10 the app's %s is frame %d of the phase table (%.4f s = frame %.2f)" % [moment,
			MOMENTS[moment], seconds, seconds * FPS], absf(seconds * FPS - MOMENTS[moment]) < 0.01
			and MOMENTS[moment] < FRAMES)
	check("E11 the moments come in the phase table's order (reach, grab, open, cut)",
		float(constants.get("REACH_FROM", 0.0)) < float(constants.get("DOOR_GRAB", 0.0))
		and float(constants.get("DOOR_GRAB", 0.0)) < float(constants.get("DOOR_OPENED", 0.0))
		and float(constants.get("DOOR_OPENED", 0.0)) < float(constants.get("CUT", 0.0)))
	var loops: Array[String] = []
	for clip_name in player.get_animation_list():
		loops.append("%s %d" % [clip_name, player.get_animation(clip_name).loop_mode])
	print("INFO: the rig's clips and loop modes: %s" % [loops])
	_finish()


func _finish() -> void:
	print("RIG READBACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
