extends "res://capture_drivers/game_take.gd"

## Take B: the driver's window and its heavy-fog overlay. Cockpit view, van stationary.
## Real "window_left" (J) action presses are handled by FreightVan._unhandled_input on clip
## frames 120 (t = 2.0 s, lowers) and 660 (t = 11.0 s, raises). The pane and the overlay
## are logged per frame in the van's own frame (FreightVan.to_local), and the travel is asserted.

const REC_START := 180
const CLIP_FRAMES := 1200
const PRESSES: Array[int] = [120, 660]
const STEP := 1.0 / 60.0
const TRAVEL := 0.88

var pane: Node3D
var overlay: Node3D
var pane_y: PackedFloat64Array = []
var overlay_y: PackedFloat64Array = []
var offsets: Array[Vector3] = []
var openness: PackedFloat64Array = []


func _take_name() -> String:
	return "take_b_driver_window"


func _csv_header() -> PackedStringArray:
	return PackedStringArray(["process_frame", "clip_frame", "t_clip", "recorded",
		"left_window", "left_window_target", "pane_van_x", "pane_van_y", "pane_van_z",
		"overlay_van_x", "overlay_van_y", "overlay_van_z", "overlay_minus_pane_y",
		"van_y", "frame_file"])


func _setup() -> void:
	var windows: Array = presentation.get("_windows")
	pane = windows[0]
	overlay = presentation.get("fog_overlays")[1]
	var material: ShaderMaterial = overlay.get("material_override")
	rig.log_event({"kind": "objects", "pane": str(pane.get_path()),
		"overlay": str(overlay.get_path()), "overlay_parent_is_pane": overlay.get_parent() == pane,
		"overlay_material": material.resource_path})


func _van_local(node: Node3D) -> Vector3:
	return (van as Node3D).to_local(node.global_position)


func _take_tick(frame: int) -> void:
	var clip := frame - REC_START
	if frame == REC_START - 1:
		rig.check(settled(), "Physics settled before recording (y stable for %d frames)"
			% SETTLE_FRAMES)
		rig.log_event(settle_report())
		rig.check(overlay.get_parent() == pane,
			"Heavy-fog overlay is a child of the driver's window pane")
		anchor_stationary()
		rig.start_recording(_take_name(), REC_START, CLIP_FRAMES)
	if clip >= 0 and clip < CLIP_FRAMES:
		for target in PRESSES:
			if clip == target - 1:
				rig.inject("window_left", true, "J press; handled on clip frame %d (t=%.3f s)"
					% [target, target * STEP])
			elif clip == target:
				rig.inject("window_left", false, "J release")
	var at_pane := _van_local(pane)
	var at_overlay := _van_local(overlay)
	var recorded := rig.in_recording(frame)
	if recorded:
		pane_y.append(at_pane.y)
		overlay_y.append(at_overlay.y)
		offsets.append(at_overlay - at_pane)
		openness.append(van.get("left_window"))
	rig.csv_row([frame, clip, "%.6f" % (clip * STEP), int(recorded),
		"%.6f" % van.get("left_window"), "%.1f" % van.get("left_window_target"),
		"%.6f" % at_pane.x, "%.6f" % at_pane.y, "%.6f" % at_pane.z,
		"%.6f" % at_overlay.x, "%.6f" % at_overlay.y, "%.6f" % at_overlay.z,
		"%.6f" % (at_overlay.y - at_pane.y), "%.6f" % (van as Node3D).global_position.y,
		("raw/frames_%s/%s_%05d.jpg" % [_take_name(), _take_name(), clip]) if recorded else ""])
	if clip == CLIP_FRAMES:
		_verify()


func _verify() -> void:
	var expected := PackedInt64Array([REC_START + PRESSES[0], REC_START + PRESSES[1]])
	rig.check(window_frames == expected,
		"The game handled both J presses on process frames %s (expected %s)" % [
		str(window_frames), str(expected)])
	var closed_y := pane_y[0]
	var lowest := closed_y
	var lowest_at := 0
	for index in range(pane_y.size()):
		if pane_y[index] < lowest:
			lowest = pane_y[index]
			lowest_at = index
	var drop := closed_y - lowest
	rig.check(absf(closed_y - 2.12) < 0.0005 and openness[0] == 0.0,
		"Window starts closed: pane at y = %.4f m in the van frame" % closed_y)
	var still_closed := true
	for index in range(PRESSES[0]):
		still_closed = still_closed and pane_y[index] == closed_y
	rig.check(still_closed and pane_y[PRESSES[0]] < closed_y,
		"Pane starts moving on the J frame (clip frame %d)" % PRESSES[0])
	rig.check(absf(drop - TRAVEL) < 0.002,
		"J lowers the pane by %.4f m in the van's frame (expected %.2f), fully open at clip "
		% [drop, TRAVEL] + "frame %d (t=%.3f s)" % [lowest_at, lowest_at * STEP])
	var overlay_drop := overlay_y[0] - overlay_y[lowest_at]
	rig.check(absf(overlay_drop - drop) < 0.00001,
		"Heavy-fog overlay moves with the pane: dropped %.4f m" % overlay_drop)
	var worst := 0.0
	for offset in offsets:
		worst = maxf(worst, offset.distance_to(offsets[0]))
	rig.check(worst < 0.00001,
		"Overlay offset from the pane is constant on every frame (max change %.7f m)" % worst)
	var open_hold := true
	for index in range(lowest_at, PRESSES[1]):
		open_hold = open_hold and absf(pane_y[index] - lowest) < 0.00001
	rig.check(open_hold, "Window stays open until the second J press")
	var last := pane_y.size() - 1
	var closed_again := -1
	for index in range(PRESSES[1], pane_y.size()):
		if absf(pane_y[index] - closed_y) < 0.00001:
			closed_again = index
			break
	rig.check(closed_again > 0 and absf(pane_y[last] - closed_y) < 0.00001,
		"Second J press raises it again: closed at clip frame %d (t=%.3f s), holds to the end"
		% [closed_again, closed_again * STEP])
	rig.check(rig.saved_clip_frames == CLIP_FRAMES,
		"Saved %d of %d clip frames" % [rig.saved_clip_frames, CLIP_FRAMES])
	guard_checks()
	rig.finish({"record_start_process_frame": REC_START, "clip_frames": CLIP_FRAMES,
		"press_clip_frames": PRESSES, "window_operated_process_frames": window_frames,
		"closed_y_van_frame": closed_y, "lowest_y_van_frame": lowest, "drop_m": drop,
		"overlay_drop_m": overlay_drop, "fully_open_clip_frame": lowest_at,
		"closed_again_clip_frame": closed_again})
