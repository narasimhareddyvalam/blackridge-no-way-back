extends SceneTree

const SHADER_PATH := "res://shaders/night_cluster.gdshader"
const DRIVER_PATH := "res://features/vehicles/freight_van/night_dimming.gd"
const VAN_SCENE := "res://features/vehicles/freight_van/freight_van.tscn"
const COLOUR_LINE := "COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * night_color.rgb" \
	+ " * night_brightness, night_amount);"
const UNIFORM_TYPES := {
	"night_amount": TYPE_FLOAT,
	"night_color": TYPE_COLOR,
	"night_brightness": TYPE_FLOAT,
}
const DECLARATIONS: Array[String] = [
	"uniform float night_amount : hint_range(0.0, 1.0) = 0.0;",
	"uniform vec4 night_color : source_color = vec4(1.0, 0.55, 0.20, 1.0);",
	"uniform float night_brightness : hint_range(0.1, 1.0) = 0.55;",
]
const FADE_IN := 0.25
const FADE_OUT := 0.35
const FRAME_BUDGET := 3000


class Sampler extends Node:
	var material: ShaderMaterial
	var values: Array[float] = []
	var deltas: Array[float] = []
	var scales: Array[float] = []

	func _process(delta: float) -> void:
		values.append(float(material.get_shader_parameter("night_amount")))
		deltas.append(delta)
		scales.append(Engine.time_scale)


var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _material: ShaderMaterial
var _sampler: Sampler
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_check_contract()
	_check_driver_reads_only()
	await _start_game()
	await _check_fades()
	await _check_retrigger()
	await _check_time_scale()
	await _check_pause()
	await _check_recovery()
	await _check_second_van()
	_check_smoothness()
	_finish()


func _check_contract() -> void:
	var shader := load(SHADER_PATH) as Shader
	var listed := {}
	for item in shader.get_shader_uniform_list():
		listed[item.name] = item.type
	_check(not listed.is_empty(), "Shader parses: get_shader_uniform_list() is not empty")
	for uniform_name: String in UNIFORM_TYPES:
		var expected: int = UNIFORM_TYPES[uniform_name]
		_check(listed.get(uniform_name, -1) == expected,
			"Uniform %s is listed with type %s" % [uniform_name, type_string(expected)])
	var source := FileAccess.get_file_as_string(SHADER_PATH)
	_check(source.begins_with("shader_type canvas_item;"),
		"Line 1 of the shader is shader_type canvas_item")
	for declaration in DECLARATIONS:
		_check(source.contains(declaration), "Source declares hint and default: " + declaration)
	_check(source.contains(COLOUR_LINE), "Source contains the colour line from CHANGE-BRIEF 2.4")
	_check(not source.contains("sampler2D"), "Shader declares no sampler uniforms")
	_check(not source.contains("TIME"), "Shader does not use TIME")


func _check_driver_reads_only() -> void:
	var source := FileAccess.get_file_as_string(DRIVER_PATH)
	var writes := RegEx.create_from_string("headlights_on\\s*=[^=]")
	_check(writes.search(source) == null, "Dimming driver never assigns headlights_on")


func _start_game() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-night-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	var presentation := _van.get_node("VanPresentation")
	_material = presentation.get("night_dimming").get("material")
	_check(_material.shader.resource_path == SHADER_PATH,
		"Cluster material uses res://shaders/night_cluster.gdshader")
	_check(_cluster_uses(presentation, _material), "The instruments Control draws with that material")
	_check(_van.get("headlights_on") and _parameter(_material) == 1.0,
		"night_amount is 1.0 before the first frame because headlights start on")
	await process_frame
	_app.call("_resume")
	_sampler = Sampler.new()
	_sampler.material = _material
	_sampler.process_priority = 1000
	_sampler.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_sampler)
	await _wait_frames(10)


func _check_fades() -> void:
	var start := _sampler.values.size()
	await _press("headlights")
	await _wait_for(0.0)
	_check(not _van.get("headlights_on"), "Real L press turned the headlights off")
	_check_duration(start, 0.0, FADE_OUT, "Off-fade 1 -> 0", false)
	start = _sampler.values.size()
	await _press("headlights")
	await _wait_for(1.0)
	_check(_van.get("headlights_on"), "Real L press turned the headlights on")
	_check_duration(start, 1.0, FADE_IN, "On-fade 0 -> 1", false)


func _check_retrigger() -> void:
	await _press("headlights")
	await _wait_frames(roundi(0.1 / _period()))
	var turn := _sampler.values.size()
	await _press("headlights")
	await _wait_for(1.0)
	var lowest := 1.0
	for index in range(turn, _sampler.values.size()):
		lowest = minf(lowest, _sampler.values[index])
	_check(lowest > 0.0 and lowest < 1.0,
		"Retrigger mid-fade turned around at %.3f without reaching 0" % lowest)
	var start := _first_rise(turn)
	var seconds := _seconds(start, _first_at(start, 1.0), false)
	var expected := (1.0 - lowest) * FADE_IN
	_check(absf(seconds - expected) <= _period() + 1e-6,
		"Reverse from current value: rise took %.4f s, expected %.4f s" % [seconds, expected])


func _check_time_scale() -> void:
	await _press("headlights")
	await _wait_for(0.0)
	Engine.time_scale = 0.5
	var start := _sampler.values.size()
	await _press("headlights")
	await _wait_for(1.0)
	_check_duration(start, 1.0, FADE_IN * 2.0, "On-fade at time_scale 0.5 in real time", true)
	Engine.time_scale = 1.0


func _check_pause() -> void:
	await _press("headlights")
	await _wait_frames(5)
	await _press("pause")
	await _wait_frames(2)
	_check(paused, "Real Escape press paused the tree")
	var held := _parameter(_material)
	await _wait_frames(30)
	_check(_parameter(_material) == held and held > 0.0 and held < 1.0,
		"night_amount holds at %.3f while paused" % held)
	await _press("headlights")
	await _wait_frames(5)
	_check(_van.get("headlights_on") == false and _parameter(_material) == held,
		"L while paused changes neither headlights_on nor night_amount")
	await _press("pause")
	await _wait_for(0.0)
	_check(not paused and _parameter(_material) == 0.0, "After resume the fade finishes at 0")


func _check_recovery() -> void:
	await _press("headlights")
	await _wait_for(1.0)
	await _press("recover")
	await _wait_frames(10)
	_check(_van.get("headlights_on") and _parameter(_material) == 1.0,
		"R recovery leaves headlights_on and night_amount unchanged")


func _check_second_van() -> void:
	var second := (load(VAN_SCENE) as PackedScene).instantiate() as CharacterBody3D
	second.position = Vector3(40, 0.1, 40)
	root.add_child(second)
	var other: ShaderMaterial = second.get_node("VanPresentation").get("night_dimming").get(
		"material")
	_check(other != _material, "Each van builds its own ShaderMaterial instance")
	await _press("headlights")
	await _wait_for(0.0)
	_check(_parameter(other) == 1.0 and second.get("headlights_on"),
		"The other van keeps night_amount 1.0 while the first van fades out")
	second.queue_free()
	await process_frame


func _check_smoothness() -> void:
	var worst := 0.0
	for index in range(1, _sampler.values.size()):
		var step := absf(_sampler.values[index] - _sampler.values[index - 1])
		worst = maxf(worst, step - _sampler.deltas[index] / FADE_IN)
	_check(worst <= 1e-5, "No frame changes night_amount faster than the fade-in rate")


func _check_duration(start: int, target: float, spec: float, label: String,
		real_time: bool) -> void:
	var first := -1
	var last := -1
	for index in range(start, _sampler.values.size()):
		if first < 0 and _sampler.values[index] != _sampler.values[index - 1]:
			first = index
		if first >= 0 and _sampler.values[index] == target:
			last = index
			break
	if first < 0 or last < 0:
		_check(false, label + " finished within the frame budget")
		return
	var seconds := _seconds(first, last, real_time)
	var tolerance := _period() + 1e-6
	_check(absf(seconds - spec) <= tolerance, "%s took %d frames = %.4f s (spec %.2f +/- %.4f)"
		% [label, last - first + 1, seconds, spec, tolerance])


func _seconds(first: int, last: int, real_time: bool) -> float:
	var total := 0.0
	for index in range(first, last + 1):
		var delta := _sampler.deltas[index]
		total += delta / _sampler.scales[index] if real_time else delta
	return total


func _first_rise(from: int) -> int:
	for index in range(from, _sampler.values.size()):
		if _sampler.values[index] > _sampler.values[index - 1]:
			return index
	return _sampler.values.size() - 1


func _first_at(from: int, target: float) -> int:
	for index in range(from, _sampler.values.size()):
		if _sampler.values[index] == target:
			return index
	return _sampler.values.size() - 1


func _period() -> float:
	return _sampler.deltas.back() / _sampler.scales.back()


func _parameter(material: ShaderMaterial) -> float:
	return float(material.get_shader_parameter("night_amount"))


func _cluster_uses(presentation: Node, material: Material) -> bool:
	for viewport in presentation.get_children():
		if viewport is SubViewport:
			for control in viewport.get_children():
				if control is CanvasItem and control.material == material:
					return true
	return false


func _press(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _wait_frames(count: int) -> void:
	for index in range(count):
		await process_frame


func _wait_for(target: float) -> void:
	for index in range(FRAME_BUDGET):
		await process_frame
		if _parameter(_material) == target:
			await process_frame
			return


func _finish() -> void:
	print("NIGHT DIMMING RESULT: %d/%d passed; %d failed" % [
		_checks - _failures, _checks, _failures])
	_app.queue_free()
	_sampler.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Night dimming test finished within 120 s of game time")
	quit(1)
