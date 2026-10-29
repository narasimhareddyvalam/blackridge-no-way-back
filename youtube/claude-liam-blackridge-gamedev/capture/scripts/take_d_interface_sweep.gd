extends "res://capture_drivers/fog_take.gd"

## Take D: interface sweep of light_fog (the windshield overlay) after the same
## parked/paused/frozen setup as take C, with the game's own world fog (on).
## One uniform at a time, others at the light_fog.tres values: set on frame k,
## capture on frame k + 1 ("wait a frame"), restore on frame k + 2.
## Ranges: the six floats use the shader's own hint_range bounds
## (game/shaders/foggy_windshield.gdshader lines 7, 8, 14, 15, 20, 21); fog_tint
## (line 9) is a source_color vec4 with no hint_range, so black and white are the
## chosen extremes. "default" is the light_fog.tres value (equal to the shader default).

const SWEEP: Array = [
	["fog_amount", [0.0, 0.25, 1.0]],
	["fog_opacity", [0.0, 0.45, 1.0]],
	["clear_center", [0.0, 0.65, 0.9]],
	["edge_softness", [0.01, 0.2, 0.5]],
	["normal_strength", [0.0, 0.5, 2.0]],
	["texture_scale", [0.5, 1.0, 4.0]],
	["fog_tint", [Color(0, 0, 0, 1), Color(0.82, 0.87, 0.9, 1), Color(1, 1, 1, 1)]],
]
const LABELS: Array[String] = ["min", "default", "max"]

var _shots: Array = []
var _shot_index: int = 0
var _phase_frame: int = -1
var _tres_values: Dictionary = {}


func _take_name() -> String:
	return "take_d_interface_sweep"


func _csv_header() -> PackedStringArray:
	return PackedStringArray(["process_frame", "event", "uniform", "label", "value",
		"light_fog_value_now", "heavy_fog_amount", "file"])


func _setup() -> void:
	super._setup()
	for entry in SWEEP:
		_tres_values[entry[0]] = light.get_shader_parameter(entry[0])
		for index in range(3):
			_shots.append([entry[0], LABELS[index], entry[1][index]])
	rig.log_event({"kind": "sweep_plan", "shots": _shots.size(),
		"tres_values": str(_tres_values), "world_fog": "on (game state)"})


func _take_tick(frame: int) -> void:
	if not park_and_freeze(frame):
		return
	var step := frame - freeze_frame
	if step < 2:
		return
	if _shot_index >= _shots.size():
		if _phase_frame >= 0 and frame == _phase_frame + 1:
			_verify()
		return
	var shot: Array = _shots[_shot_index]
	var uniform: String = shot[0]
	if _phase_frame < 0:
		_phase_frame = frame
	var phase := frame - _phase_frame
	if phase == 0:
		light.set_shader_parameter(uniform, shot[2])
		rig.csv_row([frame, "set", uniform, shot[1], _fmt(shot[2]),
			_fmt(light.get_shader_parameter(uniform)), heavy.get_shader_parameter("fog_amount"), ""])
	elif phase == 1:
		var file := "sweep_%s_%s.png" % [uniform, shot[1]]
		var ok: bool = light.get_shader_parameter(uniform) == shot[2]
		for other in _tres_values:
			if other != uniform:
				ok = ok and light.get_shader_parameter(other) == _tres_values[other]
		rig.check(ok, "%s = %s with every other light_fog uniform at its .tres value" % [
			uniform, _fmt(shot[2])])
		rig.request_still(file)
		rig.csv_row([frame, "capture", uniform, shot[1], _fmt(shot[2]),
			_fmt(light.get_shader_parameter(uniform)), heavy.get_shader_parameter("fog_amount"),
			file])
	elif phase == 2:
		light.set_shader_parameter(uniform, _tres_values[uniform])
		rig.csv_row([frame, "restore", uniform, "tres", _fmt(_tres_values[uniform]),
			_fmt(light.get_shader_parameter(uniform)), heavy.get_shader_parameter("fog_amount"), ""])
		_shot_index += 1
		_phase_frame = frame + 1


func _fmt(value: Variant) -> String:
	if value is Color:
		return "Color(%s %s %s %s)" % [value.r, value.g, value.b, value.a]
	return str(value)


func _verify() -> void:
	rig.check(rig.saved_stills.size() == _shots.size(),
		"Saved %d of %d sweep stills" % [rig.saved_stills.size(), _shots.size()])
	rig.check(params(light) == light_snapshot, "light_fog restored to its .tres values")
	check_heavy_unchanged("through the whole sweep")
	guard_checks()
	rig.finish({"freeze_process_frame": freeze_frame, "shots": _shots.size(),
		"world_fog": "on (game state)"})
