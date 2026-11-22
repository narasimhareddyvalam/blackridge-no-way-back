extends SceneTree
## Assignment 7's read-back of the shock (the fourth clip, C67): game/animations/ethan_shock.tres's
## Shock on Ethan's rig: every track resolves to a real bone (track_problems), 105 frames at 30 fps,
## step one frame period, LOOP_NONE, its keys on the phase table's frames (startle 0-8, panic 8-30,
## disbelief 30-47, drop 47-63, checks 63-83, stare 83-104; #404) within half a frame, and its
## motion: the head jerked up in the startle, fallen in the drop, turned to his left mirror and then
## to his right, level again in the stare.

const Readback = preload("res://tests/animation_readback.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const LIBRARY := "res://animations/ethan_shock.tres"
const FPS := 30.0
const FRAMES := [0, 4, 8, 14, 20, 26, 31, 35, 39, 43, 47, 55, 63, 68, 73, 78, 83, 88, 94, 104]

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
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	player.add_animation_library("shock", load(LIBRARY))
	var problems := Readback.track_problems(player)
	check("K1 every track of every clip on his player resolves (bones) %s" % [problems.slice(0, 3)],
		problems.is_empty())
	check("K2 the clip shock/Shock exists", player.has_animation("shock/Shock"))
	var clip := player.get_animation("shock/Shock")
	var tol := 0.5 / FPS
	check("K3 length %.4f s is 105 frames at 30 fps" % clip.length,
		absf(clip.length - 104.0 / FPS) < tol)
	check("K4 step one frame period (%.5f)" % clip.step, absf(clip.step - 1.0 / FPS) < 0.0001)
	check("K5 it plays once (loop_mode %d)" % clip.loop_mode, clip.loop_mode == Animation.LOOP_NONE)
	var bones := 0
	var keyed_ok := true
	for t in clip.get_track_count():
		if clip.track_get_type(t) in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D,
				Animation.TYPE_SCALE_3D]:
			bones += 1
		var times: Array[int] = []
		for k in clip.track_get_key_count(t):
			times.append(int(roundf(clip.track_get_key_time(t, k) * FPS)))
			keyed_ok = keyed_ok and absf(clip.track_get_key_time(t, k) * FPS
				- roundf(clip.track_get_key_time(t, k) * FPS)) < 0.5
		keyed_ok = keyed_ok and times == FRAMES
	check("K6 its %d tracks are all bone tracks" % clip.get_track_count(), bones == clip.get_track_count())
	check("K7 every track is keyed on the phase table's frames %s, within half a frame" % [FRAMES],
		keyed_ok)
	var looks := []
	var turns := []
	var ahead := Vector3.ZERO
	for frame in [0, 4, 58, 68, 78, 104]:
		player.play("shock/Shock")
		player.seek(frame / FPS, true)
		player.pause()
		await process_frame
		var head := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
			"mixamorig_Head"))
		var facing := head.basis.z.normalized()
		looks.append(rad_to_deg(-asin(facing.y)))
		var level := Vector3(facing.x, 0.0, facing.z).normalized()
		if frame == 0:
			ahead = level
		turns.append(rad_to_deg(ahead.signed_angle_to(level, Vector3.UP)))
	check("K8 his head: %.0f degrees down at rest, %.0f in the startle (up), %.0f in the drop, "
		% [looks[0], looks[1], looks[2]] + "%.0f in the stare (level again)" % looks[5],
		looks[1] < looks[0] - 5.0 and looks[2] > looks[0] + 25.0 and absf(looks[5] - looks[0]) < 6.0)
	check("K9 his head turns %.0f degrees at his left mirror (f68) and %.0f at his right (f78)"
		% [turns[3], turns[4]], absf(turns[3]) > 20.0 and absf(turns[4]) > 20.0
		and signf(turns[3]) != signf(turns[4]))
	print("SHOCK READBACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
