extends "res://capture_drivers/game_take.gd"

## Take A: headlights and dashboard dimming (also yields still G, cockpit_hero_4k.png).
## Cockpit view, van stationary, headlights start on. Real "headlights" (L) action presses
## are handled by FreightVan._unhandled_input on clip frames 180, 510, 720 and 727
## (t = 3.000, 8.500, 12.000 and 12.117 s; 12.12 s is not a frame boundary at 60 fps,
## 727 is the nearest frame). NightDimming.night_amount and headlights_on are logged
## for every frame, and the fades are asserted from those values.

const REC_START := 180
const CLIP_FRAMES := 1560
const PRESSES: Array[int] = [180, 510, 720, 727]
const HERO_FRAME := 120
const FADE_IN := 0.25
const FADE_OUT := 0.35
const STEP := 1.0 / 60.0

var dimming: Node
var material: ShaderMaterial
var values: PackedFloat64Array = []
var lights: Array[bool] = []
var param_mismatch: int = 0


func _take_name() -> String:
	return "take_a_headlights"


func _csv_header() -> PackedStringArray:
	return PackedStringArray(["process_frame", "clip_frame", "t_clip", "recorded", "paused",
		"headlights_on", "night_amount", "night_amount_shader_param", "van_y", "van_speed",
		"wiper_angle", "frame_file"])


func _setup() -> void:
	dimming = presentation.get("night_dimming")
	material = dimming.get("material")
	rig.log_event({"kind": "objects", "night_dimming_node": str(dimming.get_path()),
		"cluster_material_id": material.get_instance_id(),
		"cluster_shader": material.shader.resource_path})


func _take_tick(frame: int) -> void:
	var clip := frame - REC_START
	if frame == REC_START - 1:
		rig.check(settled(), "Physics settled before recording (y stable for %d frames)"
			% SETTLE_FRAMES)
		rig.log_event(settle_report())
		anchor_stationary()
		rig.start_recording(_take_name(), REC_START, CLIP_FRAMES)
	if clip >= 0 and clip < CLIP_FRAMES:
		for target in PRESSES:
			if clip == target - 1:
				rig.inject("headlights", true, "L press; handled on clip frame %d (t=%.3f s)"
					% [target, target * STEP])
			elif clip == target:
				rig.inject("headlights", false, "L release")
		if clip == HERO_FRAME:
			rig.request_still("cockpit_hero_4k.png")
	var amount: float = dimming.get("night_amount")
	var param: float = material.get_shader_parameter("night_amount")
	var lit: bool = van.get("headlights_on")
	var recorded := rig.in_recording(frame)
	if recorded:
		values.append(amount)
		lights.append(lit)
		if param != amount:
			param_mismatch += 1
	rig.csv_row([frame, clip, "%.6f" % (clip * STEP), int(recorded), int(paused), int(lit),
		"%.9f" % amount, "%.9f" % param, "%.6f" % (van as Node3D).global_position.y,
		"%.6f" % van.get("speed"), "%.6f" % van.get("wiper_angle"),
		("raw/frames_%s/%s_%05d.jpg" % [_take_name(), _take_name(), clip]) if recorded else ""])
	if clip == CLIP_FRAMES:
		_verify()


func _first(from: int, predicate: Callable) -> int:
	for index in range(from, values.size()):
		if predicate.call(values[index]):
			return index
	return -1


func _all(from: int, to: int, wanted: float, lit: bool) -> bool:
	for index in range(from, to + 1):
		if values[index] != wanted or lights[index] != lit:
			return false
	return true


func _verify() -> void:
	var expected_switch := PackedInt64Array()
	for target in PRESSES:
		expected_switch.append(REC_START + target)
	rig.check(switch_frames == expected_switch,
		"The game handled the four L presses on process frames %s (expected %s)" % [
		str(switch_frames), str(expected_switch)])
	rig.check(_all(0, PRESSES[0] - 1, 1.0, true),
		"Before the first press: headlights on, night_amount 1.0 (amber) on every frame")
	var off_end := _first(PRESSES[0], func(v: float) -> bool: return v == 0.0)
	var off_seconds := (off_end - PRESSES[0] + 1) * STEP
	rig.check(values[PRESSES[0]] < 1.0 and off_end > 0
		and absf(off_seconds - FADE_OUT) <= STEP + 1e-6,
		"Off-fade 1 -> 0 took %d frames = %.4f s (spec %.2f s +/- 1 frame)" % [
		off_end - PRESSES[0] + 1, off_seconds, FADE_OUT])
	rig.check(_all(off_end, PRESSES[1] - 1, 0.0, false),
		"Lights off: night_amount holds 0.0 (mint-white) until the second press")
	var on_end := _first(PRESSES[1], func(v: float) -> bool: return v == 1.0)
	var on_seconds := (on_end - PRESSES[1] + 1) * STEP
	rig.check(values[PRESSES[1]] > 0.0 and on_end > 0
		and absf(on_seconds - FADE_IN) <= STEP + 1e-6,
		"On-fade 0 -> 1 took %d frames = %.4f s (spec %.2f s +/- 1 frame)" % [
		on_end - PRESSES[1] + 1, on_seconds, FADE_IN])
	rig.check(_all(on_end, PRESSES[2] - 1, 1.0, true),
		"Lights on: night_amount holds 1.0 until the double tap")
	var falling := true
	for index in range(PRESSES[2], PRESSES[3]):
		falling = falling and values[index] < values[index - 1] and not lights[index]
	var lowest := values[PRESSES[3] - 1]
	var expected_low := 1.0 - (PRESSES[3] - PRESSES[2]) * STEP / FADE_OUT
	rig.check(falling and absf(lowest - expected_low) < 1e-6,
		"Double tap: fading out for %d frames, turned at %.6f (expected %.6f)" % [
		PRESSES[3] - PRESSES[2], lowest, expected_low])
	var first_rise := values[PRESSES[3]] - lowest
	rig.check(lights[PRESSES[3]] and absf(first_rise - STEP / FADE_IN) < 1e-6,
		"Reversal continues from the current value: first step +%.6f (one fade-in step %.6f)"
		% [first_rise, STEP / FADE_IN])
	var back := _first(PRESSES[3], func(v: float) -> bool: return v == 1.0)
	var back_seconds := (back - PRESSES[3] + 1) * STEP
	rig.check(back > 0 and absf(back_seconds - (1.0 - lowest) * FADE_IN) <= STEP + 1e-6,
		"Rise from %.4f to 1.0 took %d frames = %.4f s (expected %.4f s +/- 1 frame)" % [
		lowest, back - PRESSES[3] + 1, back_seconds, (1.0 - lowest) * FADE_IN])
	rig.check(_all(back, CLIP_FRAMES - 1, 1.0, true),
		"After the reversal: headlights on, night_amount 1.0 to the end of the clip")
	var worst := 0.0
	for index in range(1, values.size()):
		worst = maxf(worst, absf(values[index] - values[index - 1]))
	rig.check(worst <= STEP / FADE_IN + 1e-6,
		"No jump: largest per-frame change %.6f <= one fade-in step %.6f" % [worst,
		STEP / FADE_IN])
	rig.check(param_mismatch == 0,
		"The cluster ShaderMaterial's night_amount equals NightDimming.night_amount every frame")
	rig.check(rig.saved_clip_frames == CLIP_FRAMES,
		"Saved %d of %d clip frames" % [rig.saved_clip_frames, CLIP_FRAMES])
	rig.check(rig.saved_stills.has("cockpit_hero_4k.png"), "Saved the hero still (clip frame %d)"
		% HERO_FRAME)
	guard_checks()
	rig.finish({"record_start_process_frame": REC_START, "clip_frames": CLIP_FRAMES,
		"press_clip_frames": PRESSES, "switch_process_frames": switch_frames,
		"off_fade_end_clip_frame": off_end, "on_fade_end_clip_frame": on_end,
		"reversal_low": lowest, "reversal_back_clip_frame": back,
		"hero_clip_frame": HERO_FRAME})
