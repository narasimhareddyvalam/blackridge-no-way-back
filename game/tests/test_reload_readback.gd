extends SceneTree
## Assignment 7's read-back of the third clip, the rifle reload (CHANGE-BRIEF.md, the rifle's
## revision, #393-#405; C68). It supersedes the hand-keyed pistol reload this file first read
## (3b00d46), which the author rejected (#386). The clip is Mixamo's captured "reloading" for Ethan,
## upper body only, in game/animations/ethan_rifle.tres, on the second player (UpperBody) that
## rifle_carry.gd builds over his own (built here by rifle_carry.gd's own setup). Checked: every track of every clip on that player resolves
## to a real bone; RifleReload is 100 frames at 30 fps, step one frame period, LOOP_NONE, as the
## raw clip in ethan.glb (whose loop mode is the importer's); it keys no bone below his waist; the
## handgun's RELOAD_SECONDS is the clip's length, so the magazine fills as his hands finish; and
## the parts rifle_hold.gd moves on the clip's frames follow the phase table (startup 0-29, active
## 30-47, recovery 48-99): the empty magazine out from frame 14, the fresh one in his hand from 26
## and seated at 47, the charging handle 8 cm back at 64 and home by 66, nothing moved at 0 or 99.

const Readback = preload("res://tests/animation_readback.gd")
const Handgun = preload("res://features/weapons/pistol/handgun.gd")
const RifleHold = preload("res://features/weapons/rifle/rifle_hold.gd")
const RifleCarry = preload("res://features/characters/driver/rifle_carry.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const FPS := 30.0
const LOWER := ["Hips", "UpLeg", "Leg", "Foot", "Toe"]

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
	var own := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var carry: Node = RifleCarry.new()
	root.add_child(carry)
	carry.call("setup", model, skeleton, own)
	var upper := carry.get("upper") as AnimationPlayer
	var problems := Readback.track_problems(upper)
	check("R1 every track of every clip on UpperBody resolves to a bone %s" % [problems.slice(0, 3)],
		problems.is_empty())
	check("R2 RifleReload exists on UpperBody", upper.has_animation("RifleReload"))
	var clip := upper.get_animation("RifleReload")
	var tol := 0.5 / FPS
	check("R3 length %.4f s is 100 frames at 30 fps (99 frame periods)" % clip.length,
		absf(clip.length - 99.0 / FPS) < tol)
	check("R4 step one frame period (%.5f)" % clip.step, absf(clip.step - 1.0 / FPS) < 0.0001)
	check("R5 it plays once (loop_mode %d)" % clip.loop_mode, clip.loop_mode == Animation.LOOP_NONE)
	var raw := own.get_animation("RifleReload") if own.has_animation("RifleReload") else null
	check("R6 the raw clip in ethan.glb is LOOP_NONE from its importer, the same length (%s)" % [
		raw.length if raw != null else -1.0], raw != null and raw.loop_mode == Animation.LOOP_NONE
		and absf(raw.length - clip.length) < tol)
	var low: Array[String] = []
	var whole_frames := true
	for t in clip.get_track_count():
		var bone := String(clip.track_get_path(t).get_concatenated_subnames())
		for part in LOWER:
			if bone.contains(part):
				low.append(bone)
		for k in clip.track_get_key_count(t):
			var at := clip.track_get_key_time(t, k) * FPS
			whole_frames = whole_frames and absf(at - roundf(at)) < 0.5
	check("R7 no track keys a bone below his waist %s (%d tracks)" % [low.slice(0, 3),
		clip.get_track_count()], low.is_empty())
	check("R8 every key on a whole frame at 30 fps, within half a frame", whole_frames)
	check("R9 RELOAD_SECONDS %.4f s is the clip's length %.4f s" % [Handgun.RELOAD_SECONDS,
		clip.length], absf(Handgun.RELOAD_SECONDS - clip.length) < tol)
	var hold: RefCounted = RifleHold.new(skeleton)
	var magazine := []
	for frame in [0, 13, 14, 25, 26, 46, 47, 99]:
		magazine.append(hold.call("magazine_at", "RifleReload", float(frame)))
	check("R10 the magazine: in the gun to 13, gone 14-25, in his hand 26-46, seated from 47 %s"
		% [magazine], magazine == ["gun", "gun", "gone", "gone", "hand", "hand", "gun", "gun"])
	var handle := []
	for frame in [0, 62, 63, 64, 65, 66, 99]:
		handle.append(snappedf(float(hold.call("charging_at", "RifleReload", float(frame))), 0.001))
	check("R11 the charging handle: home to 62, back 8 cm at 64-65, home by 66 %s" % [handle],
		handle[0] == 0.0 and handle[1] == 0.0 and handle[2] > 0.0 and handle[2] < 0.08
		and handle[3] == 0.08 and handle[4] == 0.08 and handle[5] == 0.0 and handle[6] == 0.0)
	check("R12 its player's clock: process idle like his own (%d)" % upper.callback_mode_process,
		upper.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE)
	print("RELOAD READBACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
