extends "res://capture_drivers/fog_take.gd"

## Take C: one shader, two materials. After the parked/paused/frozen setup (fog_take.gd):
## stills fog_baseline.png, world_fog_off.png, world_fog_on.png (runtime-only
## Environment.fog_enabled toggle, never saved), then two 7 s clips:
##   material_edit: light_fog fog_amount 0.25 -> 1.0 at clip frame 120 (t = 2.0 s);
##   shader_edit:   in memory only, on the shared Shader resource loaded from
##                  res://shaders/foggy_windshield.gdshader, at clip frame 120 replace
##                  "ALBEDO = color_sample * fog_tint.rgb;" with "ALBEDO = vec3(1.0, 0.35, 0.2);".
## Nothing is saved: no ResourceSaver call; the file on disk is compared before and after.

const SHADER_PATH := "res://shaders/foggy_windshield.gdshader"
const ORIGINAL_LINE := "ALBEDO = color_sample * fog_tint.rgb;"
const REPLACEMENT_LINE := "ALBEDO = vec3(1.0, 0.35, 0.2);"
const CLIP_FRAMES := 420
const EDIT_AT := 120

var original_code: String
var disk_before: String
var material_start: int = -1
var shader_start: int = -1
var light_amounts: PackedFloat64Array = []
var heavy_amounts: PackedFloat64Array = []
var edited_flags: Array[bool] = []


func _take_name() -> String:
	return "take_c_one_shader_two_materials"


func _csv_header() -> PackedStringArray:
	return PackedStringArray(["process_frame", "clip", "clip_frame", "t_clip", "paused",
		"time_scale", "world_fog_enabled", "light_fog_amount", "heavy_fog_amount",
		"shader_line_replaced", "frame_file"])


func _setup() -> void:
	super._setup()
	original_code = shader.code
	disk_before = FileAccess.get_file_as_string(SHADER_PATH)
	rig.check(original_code.count(ORIGINAL_LINE) == 1 and original_code == disk_before,
		"Loaded Shader code equals the file on disk and contains the original line once")


func _take_tick(frame: int) -> void:
	if not park_and_freeze(frame):
		_row(frame, "", -1)
		return
	var step := frame - freeze_frame
	if step == 2:
		rig.check(world.environment.fog_enabled, "World fog is on in the game's own state")
		rig.request_still("fog_baseline.png")
	elif step == 3:
		world.environment.fog_enabled = false
		rig.log_event({"kind": "scripted", "what": "WorldEnvironment.environment.fog_enabled = false",
			"note": "runtime only, never saved"})
	elif step == 4:
		rig.request_still("world_fog_off.png")
	elif step == 5:
		world.environment.fog_enabled = true
		rig.log_event({"kind": "scripted", "what": "WorldEnvironment.environment.fog_enabled = true"})
	elif step == 6:
		rig.request_still("world_fog_on.png")
	elif step == 10:
		material_start = frame
		rig.start_recording("material_edit", frame, CLIP_FRAMES)
	_material_clip(frame)
	_shader_clip(frame)
	_row(frame, _clip_name(frame), _clip_frame(frame))
	if shader_start >= 0 and frame == shader_start + CLIP_FRAMES + 2:
		_verify()


func _clip_name(frame: int) -> String:
	if material_start >= 0 and frame >= material_start and frame < material_start + CLIP_FRAMES:
		return "material_edit"
	if shader_start >= 0 and frame >= shader_start and frame < shader_start + CLIP_FRAMES:
		return "shader_edit"
	return ""


func _clip_frame(frame: int) -> int:
	match _clip_name(frame):
		"material_edit":
			return frame - material_start
		"shader_edit":
			return frame - shader_start
	return -1


func _material_clip(frame: int) -> void:
	if material_start < 0:
		return
	var clip := frame - material_start
	if clip == EDIT_AT - 1:
		rig.request_still("material_edit_before.png")
	elif clip == EDIT_AT:
		light.set_shader_parameter("fog_amount", 1.0)
		rig.log_event({"kind": "edit", "clip": "material_edit",
			"what": "light_fog.set_shader_parameter(\"fog_amount\", 1.0)", "was": 0.25,
			"note": "runtime only on the loaded light_fog.tres resource; never saved"})
		rig.request_still("material_edit_after.png")
	if clip >= 0 and clip < CLIP_FRAMES:
		light_amounts.append(light.get_shader_parameter("fog_amount"))
		heavy_amounts.append(heavy.get_shader_parameter("fog_amount"))
	elif clip == CLIP_FRAMES:
		check_heavy_unchanged("during the material edit")
		light.set_shader_parameter("fog_amount", 0.25)
		rig.log_event({"kind": "edit", "what": "light_fog fog_amount restored to 0.25"})
		rig.check(params(light) == light_snapshot, "light_fog restored to its .tres values")
		shader_start = frame + 10


func _shader_clip(frame: int) -> void:
	if shader_start < 0:
		return
	var clip := frame - shader_start
	if clip == 0:
		rig.start_recording("shader_edit", frame, CLIP_FRAMES)
	elif clip == EDIT_AT - 1:
		rig.request_still("shader_edit_before.png")
	elif clip == EDIT_AT:
		var edited := original_code.replace(ORIGINAL_LINE, REPLACEMENT_LINE)
		shader.code = edited
		var listed := shader.get_shader_uniform_list()
		rig.check(edited.count(REPLACEMENT_LINE) == 1 and edited.count(ORIGINAL_LINE) == 0
			and listed.size() > 0,
			"In-memory edit replaced exactly one line and the shader still compiles (%d uniforms)"
			% listed.size())
		rig.log_event({"kind": "edit", "clip": "shader_edit",
			"what": "Shader.code line replacement (in memory, never saved)",
			"shader": SHADER_PATH, "shader_instance_id": shader.get_instance_id(),
			"original_line": ORIGINAL_LINE, "replacement_line": REPLACEMENT_LINE,
			"materials_sharing_it": [light.resource_path, heavy.resource_path]})
		rig.request_still("shader_edit_after.png")
	if clip >= 0 and clip < CLIP_FRAMES:
		edited_flags.append(shader.code != original_code)
	elif clip == CLIP_FRAMES:
		shader.code = original_code
		rig.log_event({"kind": "edit", "what": "Shader.code restored to the original text"})


func _row(frame: int, clip: String, clip_frame: int) -> void:
	var file := ""
	if clip != "":
		file = "raw/frames_%s/%s_%05d.jpg" % [clip, clip, clip_frame]
	rig.csv_row([frame, clip, clip_frame, "%.6f" % (clip_frame / 60.0) if clip != "" else "",
		int(paused), Engine.time_scale, int(world.environment.fog_enabled),
		light.get_shader_parameter("fog_amount"), heavy.get_shader_parameter("fog_amount"),
		int(shader.code != original_code), file])


func _verify() -> void:
	var before_ok := true
	var after_ok := true
	for index in range(light_amounts.size()):
		if index < EDIT_AT:
			before_ok = before_ok and light_amounts[index] == 0.25
		else:
			after_ok = after_ok and light_amounts[index] == 1.0
	var heavy_ok := true
	for value in heavy_amounts:
		heavy_ok = heavy_ok and value == 0.75
	rig.check(light_amounts.size() == CLIP_FRAMES and before_ok and after_ok,
		"material_edit: light_fog fog_amount 0.25 for clip frames 0-119, 1.0 for 120-419")
	rig.check(heavy_ok, "material_edit: heavy_fog fog_amount stayed 0.75 on every frame")
	var flags_ok := edited_flags.size() == CLIP_FRAMES
	for index in range(edited_flags.size()):
		flags_ok = flags_ok and edited_flags[index] == (index >= EDIT_AT)
	rig.check(flags_ok, "shader_edit: original code for clip frames 0-119, edited for 120-419")
	rig.check(shader.code == original_code, "Shader code restored in memory after the clip")
	var disk_after := FileAccess.get_file_as_string(SHADER_PATH)
	rig.check(disk_after == disk_before, "foggy_windshield.gdshader on disk is unchanged")
	check_heavy_unchanged("at the end")
	rig.check(params(light) == light_snapshot, "light_fog values equal its .tres values at the end")
	rig.check(rig.saved_clip_frames == 2 * CLIP_FRAMES,
		"Saved %d of %d clip frames" % [rig.saved_clip_frames, 2 * CLIP_FRAMES])
	for still in ["fog_baseline.png", "world_fog_off.png", "world_fog_on.png",
			"material_edit_before.png", "material_edit_after.png", "shader_edit_before.png",
			"shader_edit_after.png"]:
		rig.check(rig.saved_stills.has(still), "Saved still " + still)
	guard_checks()
	rig.finish({"freeze_process_frame": freeze_frame, "material_edit_start": material_start,
		"shader_edit_start": shader_start, "edit_clip_frame": EDIT_AT,
		"original_line": ORIGINAL_LINE, "replacement_line": REPLACEMENT_LINE,
		"light_fog_instance_id": light.get_instance_id(),
		"heavy_fog_instance_id": heavy.get_instance_id(),
		"shared_shader_instance_id": shader.get_instance_id()})
