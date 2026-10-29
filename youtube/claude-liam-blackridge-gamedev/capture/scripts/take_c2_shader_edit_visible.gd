extends "res://capture_drivers/fog_take.gd"

## Take C2: the shader edit again, with the windshield's fog made visible first.
## Added on request after take C: at the light_fog.tres values (fog_amount 0.25) the
## windshield's fog sits in its outer edge band, mostly behind the window frame, so the
## shader edit hardly shows there. Same parked/paused/frozen setup as take C (fog_take.gd).
## Before recording: light_fog fog_amount 0.25 -> 1.0 at runtime (a disclosed visibility
## change; heavy_fog untouched). Then a 7 s clip: 2 s baseline, at clip frame 120 replace
## "ALBEDO = color_sample * fog_tint.rgb;" with "ALBEDO = vec3(1.0, 0.35, 0.2);" in the
## loaded Shader's code (in memory, never saved), hold 5 s; afterwards restore the code and
## restore light_fog to its .tres values.
## The scene is frozen (tree paused, time_scale 0), so this take enables the rig's
## force_draw_when_hidden fallback: if the window cannot draw (it lost its Space or
## desktop during the first attempt), the rig draws the frame itself.

const SHADER_PATH := "res://shaders/foggy_windshield.gdshader"
const ORIGINAL_LINE := "ALBEDO = color_sample * fog_tint.rgb;"
const REPLACEMENT_LINE := "ALBEDO = vec3(1.0, 0.35, 0.2);"
const CLIP := "shader_edit_visible"
const CLIP_FRAMES := 420
const EDIT_AT := 120
const VISIBLE_AMOUNT := 1.0

var original_code: String
var disk_before: String
var clip_start: int = -1
var edited_flags: Array[bool] = []
var light_amounts: PackedFloat64Array = []
var heavy_ok: bool = true


func _take_name() -> String:
	return "take_c2_shader_edit_visible"


func _csv_header() -> PackedStringArray:
	return PackedStringArray(["process_frame", "clip_frame", "t_clip", "paused", "time_scale",
		"light_fog_amount", "heavy_fog_amount", "shader_line_replaced", "frame_file"])


func _setup() -> void:
	super._setup()
	rig.force_draw_when_hidden = true
	original_code = shader.code
	disk_before = FileAccess.get_file_as_string(SHADER_PATH)
	rig.check(original_code.count(ORIGINAL_LINE) == 1 and original_code == disk_before,
		"Loaded Shader code equals the file on disk and contains the original line once")


func _take_tick(frame: int) -> void:
	if not park_and_freeze(frame):
		_row(frame, -1)
		return
	var step := frame - freeze_frame
	if step == 2:
		light.set_shader_parameter("fog_amount", VISIBLE_AMOUNT)
		rig.log_event({"kind": "edit", "what": "light_fog.set_shader_parameter(\"fog_amount\", 1.0)",
			"was": light_snapshot["fog_amount"],
			"note": "disclosed visibility change before recording, runtime only, never saved; "
			+ "heavy_fog untouched"})
		check_heavy_unchanged("after the visibility change")
	elif step == 4:
		clip_start = frame
		rig.start_recording(CLIP, frame, CLIP_FRAMES)
	if clip_start >= 0:
		_clip(frame)
	_row(frame, frame - clip_start if clip_start >= 0 else -1)
	if clip_start >= 0 and frame == clip_start + CLIP_FRAMES + 2:
		_verify()


func _clip(frame: int) -> void:
	var clip := frame - clip_start
	if clip == EDIT_AT - 1:
		rig.request_still("shader_edit_visible_before.png")
	elif clip == EDIT_AT:
		var edited := original_code.replace(ORIGINAL_LINE, REPLACEMENT_LINE)
		shader.code = edited
		var listed := shader.get_shader_uniform_list()
		rig.check(edited.count(REPLACEMENT_LINE) == 1 and edited.count(ORIGINAL_LINE) == 0
			and listed.size() > 0,
			"In-memory edit replaced exactly one line and the shader still compiles (%d uniforms)"
			% listed.size())
		rig.log_event({"kind": "edit", "clip": CLIP,
			"what": "Shader.code line replacement (in memory, never saved)",
			"shader": SHADER_PATH, "shader_instance_id": shader.get_instance_id(),
			"original_line": ORIGINAL_LINE, "replacement_line": REPLACEMENT_LINE,
			"materials_sharing_it": [light.resource_path, heavy.resource_path]})
		rig.request_still("shader_edit_visible_after.png")
	if clip >= 0 and clip < CLIP_FRAMES:
		edited_flags.append(shader.code != original_code)
		light_amounts.append(light.get_shader_parameter("fog_amount"))
		heavy_ok = heavy_ok and params(heavy) == heavy_snapshot
	elif clip == CLIP_FRAMES:
		shader.code = original_code
		rig.log_event({"kind": "edit", "what": "Shader.code restored to the original text"})
		for key in light_snapshot:
			if not (key in ["fog_color", "fog_normal", "fog_data"]):
				light.set_shader_parameter(key, light_snapshot[key])
		rig.log_event({"kind": "edit", "what": "light_fog restored to its .tres values",
			"values": str(params(light))})


func _row(frame: int, clip_frame: int) -> void:
	var recorded := rig.in_recording(frame)
	rig.csv_row([frame, clip_frame, "%.6f" % (clip_frame / 60.0) if recorded else "",
		int(paused), Engine.time_scale, light.get_shader_parameter("fog_amount"),
		heavy.get_shader_parameter("fog_amount"), int(shader.code != original_code),
		("raw/frames_%s/%s_%05d.jpg" % [CLIP, CLIP, clip_frame]) if recorded else ""])


func _verify() -> void:
	var flags_ok := edited_flags.size() == CLIP_FRAMES
	for index in range(edited_flags.size()):
		flags_ok = flags_ok and edited_flags[index] == (index >= EDIT_AT)
	rig.check(flags_ok, "Original code for clip frames 0-119, edited code for 120-419")
	var amounts_ok := light_amounts.size() == CLIP_FRAMES
	for value in light_amounts:
		amounts_ok = amounts_ok and value == VISIBLE_AMOUNT
	rig.check(amounts_ok, "light_fog fog_amount was 1.0 on every recorded frame (disclosed)")
	rig.check(heavy_ok, "heavy_fog values unchanged on every recorded frame")
	rig.check(light.shader == heavy.shader and light != heavy,
		"Still one shared Shader object (id %d) and two different materials (ids %d / %d)" % [
		shader.get_instance_id(), light.get_instance_id(), heavy.get_instance_id()])
	rig.check(shader.code == original_code, "Shader code restored in memory after the clip")
	rig.check(FileAccess.get_file_as_string(SHADER_PATH) == disk_before,
		"foggy_windshield.gdshader on disk is unchanged")
	rig.check(params(light) == light_snapshot, "light_fog restored to its .tres values: %s"
		% str(params(light)))
	check_heavy_unchanged("at the end")
	rig.check(rig.saved_clip_frames == CLIP_FRAMES,
		"Saved %d of %d clip frames" % [rig.saved_clip_frames, CLIP_FRAMES])
	for still in ["shader_edit_visible_before.png", "shader_edit_visible_after.png"]:
		rig.check(rig.saved_stills.has(still), "Saved still " + still)
	guard_checks()
	rig.finish({"freeze_process_frame": freeze_frame, "clip_start_process_frame": clip_start,
		"edit_clip_frame": EDIT_AT, "visibility_change": "light_fog fog_amount 0.25 -> 1.0 "
		+ "before recording (runtime only), restored afterwards",
		"original_line": ORIGINAL_LINE, "replacement_line": REPLACEMENT_LINE,
		"light_fog_instance_id": light.get_instance_id(),
		"heavy_fog_instance_id": heavy.get_instance_id(),
		"shared_shader_instance_id": shader.get_instance_id()})
