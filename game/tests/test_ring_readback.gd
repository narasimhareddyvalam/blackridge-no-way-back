extends SceneTree
## Assignment 7's read-back of the ring cycle (CHANGE-BRIEF.md §2-3): the clip on its real node in
## the game (the dash's navigation screen in the van), its tracks resolved, its keys, step, length,
## loop mode, update mode and frame range against the brief, its seam rule for a frame track, the
## sheet's slicing, and the player's clock. Key times compare with a tolerance of half a frame
## period, never ==, because they are stored as 32-bit floats.

const Readback = preload("res://tests/animation_readback.gd")
const FPS := 10.0
const FRAMES := 6
const SHEET := "res://features/vehicles/freight_van/art/ring/phone_ring.png"

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
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(app)
	await process_frame
	await process_frame
	var navigation := app.get_node("FreightVan/VanPresentation").get("navigation") as Control
	var player := navigation.get_node_or_null("RingPlayer") as AnimationPlayer
	var sprite := navigation.get_node_or_null("RingIcon") as Sprite2D
	check("R1 the ring's player and sprite exist on the dash (%s, %s)" % [player, sprite],
		player != null and sprite != null)
	if player == null or sprite == null:
		_finish()
		return
	var problems := Readback.track_problems(player)
	check("R2 every track resolves %s" % [problems], problems.is_empty())
	check("R3 the clip 'ring' exists", player.has_animation("ring"))
	var clip := player.get_animation("ring")
	var tol := 0.5 / FPS
	check("R4 step is one frame period (%.4f)" % clip.step, is_equal_approx(clip.step, 1.0 / FPS))
	check("R5 length %.3f s is %d frames at %d fps" % [clip.length, FRAMES, FPS],
		absf(clip.length - FRAMES / FPS) < tol)
	check("R6 the cycle loops (loop_mode %d, LOOP_LINEAR)" % clip.loop_mode,
		clip.loop_mode == Animation.LOOP_LINEAR)
	check("R7 one value track keying RingIcon:frame (%d tracks, %s)" % [clip.get_track_count(),
		clip.track_get_path(0)], clip.get_track_count() == 1
		and clip.track_get_type(0) == Animation.TYPE_VALUE
		and String(clip.track_get_path(0)) == "RingIcon:frame")
	check("R8 discrete updates", clip.value_track_get_update_mode(0) == Animation.UPDATE_DISCRETE)
	var count := clip.track_get_key_count(0)
	var times_ok := count == FRAMES
	var values_ok := count == FRAMES
	var in_sheet := true
	for k in range(count):
		times_ok = times_ok and absf(clip.track_get_key_time(0, k) - float(k) / FPS) < tol
		var value := int(clip.track_get_key_value(0, k))
		values_ok = values_ok and value == k
		in_sheet = in_sheet and value >= 0 and value < sprite.hframes * sprite.vframes
	check("R9 six keys, one every frame period from 0 (%d keys)" % count, times_ok)
	check("R10 the frame order 0 to 5", values_ok)
	check("R11 every key is a cell the sheet has (%d cells)" % (sprite.hframes * sprite.vframes),
		in_sheet)
	var last := clip.track_get_key_time(0, count - 1)
	check("R12 seam: the gap from the last key to length equals the key interval (%.3f)" % (
		clip.length - last), absf((clip.length - last) - 1.0 / FPS) < tol)
	check("R13 seam: no duplicate across the wrap (last %d, first %d)" % [
		clip.track_get_key_value(0, count - 1), clip.track_get_key_value(0, 0)],
		clip.track_get_key_value(0, count - 1) != clip.track_get_key_value(0, 0))
	var texture := sprite.texture
	check("R14 sliced as the brief says: %s, hframes %d, vframes %d, cells %s" % [
		texture.resource_path if texture else "none", sprite.hframes, sprite.vframes,
		texture.get_size() / Vector2(sprite.hframes, sprite.vframes) if texture else Vector2.ZERO],
		texture != null and texture.resource_path == SHEET and sprite.hframes == 6
		and sprite.vframes == 1 and texture.get_size() == Vector2(384, 64))
	check("R15 the player advances on the process tick and plays nothing by itself",
		player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
		and player.autoplay == "")
	_finish()


func _finish() -> void:
	print("RING READBACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
