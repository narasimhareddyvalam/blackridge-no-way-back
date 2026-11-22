extends SceneTree
## Assignment 7's read-back of the reload (CHANGE-BRIEF.md, the revision #377-#383): the clip on
## its real nodes, the pistol Ethan holds as `aim_arms.gd` builds it on his rig, its tracks
## resolved (the pistol's slide and magazine and the SupportHand target, as properties), its keys
## on the phase table's frames at 30 fps within half a frame, its length 66 frames
## (RELOAD_SECONDS 2.2 s), LOOP_NONE, its first and last keys the rest pose, the magazine out of
## sight only between the drop and the fresh one, and its player's clock.

const Readback = preload("res://tests/animation_readback.gd")
const AimArms = preload("res://features/weapons/pistol/aim_arms.gd")
const Handgun = preload("res://features/weapons/pistol/handgun.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const FPS := 30.0
const FRAMES := 66
## The phase table's boundaries (startup 0-17, active 18-47, recovery 48-65) and the moments the
## brief names inside them, each a frame some track keys.
const BOUNDARIES := [0, 17, 18, 47, 48, 55, 58, 65]

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
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var arms := AimArms.new()
	model.add_child(arms)
	arms.call("setup", skeleton, 1.4)
	await process_frame
	var player := arms.get_node_or_null("Grip/ReloadPlayer") as AnimationPlayer
	check("RL1 the held pistol has its ReloadPlayer (%s)" % player, player != null)
	if player == null:
		_finish()
		return
	var problems := Readback.track_problems(player)
	check("RL2 every track resolves %s" % [problems], problems.is_empty())
	check("RL3 the clip 'reload' exists", player.has_animation("reload"))
	var clip := player.get_animation("reload")
	var tol := 0.5 / FPS
	check("RL4 length %.4f s is %d frames at 30 fps = RELOAD_SECONDS %.1f" % [clip.length, FRAMES,
		Handgun.RELOAD_SECONDS], absf(clip.length - FRAMES / FPS) < tol
		and absf(clip.length - Handgun.RELOAD_SECONDS) < tol)
	check("RL5 step is one frame period (%.5f)" % clip.step, absf(clip.step - 1.0 / FPS) < 0.0001)
	check("RL6 it plays once (loop_mode %d)" % clip.loop_mode, clip.loop_mode == Animation.LOOP_NONE)
	var paths: Array[String] = []
	var off_frame: Array[String] = []
	var keyed := {}
	for t in clip.get_track_count():
		paths.append(String(clip.track_get_path(t)))
		for k in clip.track_get_key_count(t):
			var frame := clip.track_get_key_time(t, k) * FPS
			if absf(frame - roundf(frame)) >= 0.5 * 0.5:
				off_frame.append("%s@%.2f" % [clip.track_get_path(t), frame])
			keyed[int(roundf(frame))] = true
	paths.sort()
	check(("RL7 it keys the held gun drawn in, the magazine, its visibility, the slide and the "
		+ "left hand %s") % [paths], paths == [".:position", "Pistol/clip_pistolLow_0:position",
		"Pistol/clip_pistolLow_0:visible", "Pistol/slide_pistolLow_0:position",
		"SupportHand:position"])
	check("RL8 every key sits on a whole frame at 30 fps (off: %s)" % [off_frame],
		off_frame.is_empty())
	var missing: Array[int] = []
	for frame in BOUNDARIES:
		if not keyed.has(frame):
			missing.append(frame)
	check("RL9 the phase table's frames are keyed %s (missing %s)" % [BOUNDARIES, missing],
		missing.is_empty())
	var rest_ok := true
	var rest_detail := []
	for t in clip.get_track_count():
		var node := player.get_node(player.root_node).get_node(NodePath(
			clip.track_get_path(t).get_concatenated_names()))
		var property := clip.track_get_path(t).get_concatenated_subnames()
		var rest: Variant = node.get(property)
		var first: Variant = clip.track_get_key_value(t, 0)
		var last: Variant = clip.track_get_key_value(t, clip.track_get_key_count(t) - 1)
		var same := func(a: Variant, b: Variant) -> bool:
			return a == b if typeof(a) == TYPE_BOOL else (a as Vector3).distance_to(b) < 0.0005
		var ok: bool = same.call(first, rest) and same.call(last, rest) \
			and is_zero_approx(clip.track_get_key_time(t, 0))
		rest_ok = rest_ok and ok
		if not ok:
			rest_detail.append("%s rest %s first %s last %s" % [clip.track_get_path(t), rest, first,
				last])
	check("RL10 every track starts at 0 on the rest pose and ends on it %s" % [rest_detail], rest_ok)
	var vis := clip.find_track(NodePath("Pistol/clip_pistolLow_0:visible"), Animation.TYPE_VALUE)
	var hidden: Array[int] = []
	for k in clip.track_get_key_count(vis):
		if not bool(clip.track_get_key_value(vis, k)):
			hidden.append(int(roundf(clip.track_get_key_time(vis, k) * FPS)))
	check("RL11 the magazine's visibility is discrete and it is hidden only from frame 17 (%s)" % [
		hidden], clip.value_track_get_update_mode(vis) == Animation.UPDATE_DISCRETE
		and hidden == [17])
	check("RL12 the player advances on the process tick (the handgun's clock) and plays nothing "
		+ "by itself", player.callback_mode_process
		== AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE and player.autoplay == ""
		and not player.is_playing())
	_finish()


func _finish() -> void:
	print("RELOAD READBACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
