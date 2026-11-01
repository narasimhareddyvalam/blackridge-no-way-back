extends SceneTree

const PROJECTOR_PATH := "res://features/vehicles/freight_van/art/low_beam_pattern.png"
const HIGH_PATH := "res://features/vehicles/freight_van/art/high_beam_pattern.png"

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
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
	await _start_game()
	var lights := _headlights()
	_check(lights.size() == 2, "The van has two headlight SpotLight3Ds (found %d)" % lights.size())
	var camera: Camera3D = _van.call("get_camera")
	for index in range(lights.size()):
		var light := lights[index]
		_check(light.layers & camera.cull_mask != 0,
			"Headlight %d is on a layer the driving camera sees (layers %d, cull mask %d)" % [
			index, light.layers, camera.cull_mask])
		_check(light.light_cull_mask & 1 != 0, "Headlight %d lights the world layer" % index)
		_check(light.shadow_enabled, "Headlight %d casts shadows, which its pattern needs" % index)
		_check(light.light_projector != null
			and light.light_projector.resource_path == PROJECTOR_PATH,
			"Headlight %d uses the low-beam pattern" % index)
	_check(_van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, true) and _all_patterns(lights, PROJECTOR_PATH),
		"Headlights start on, on low beams")
	await _press("headlights")
	await _wait_physics(3)
	_check(_van.get("headlights_on") and _van.get("high_beams") and _all_visible(lights, true)
		and _all_patterns(lights, HIGH_PATH) and lights[0].spot_range > 200.0,
		"A real L press switches both headlights to high beams")
	await _press("headlights")
	await _wait_physics(3)
	_check(not _van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, false), "A second L press switches both headlights off")
	await _press("headlights")
	await _wait_physics(3)
	_check(_van.get("headlights_on") and not _van.get("high_beams")
		and _all_visible(lights, true) and _all_patterns(lights, PROJECTOR_PATH),
		"A third L press brings the low beams back")
	_check_patterns()
	_finish()


func _check_patterns() -> void:
	var low := Image.load_from_file(ProjectSettings.globalize_path(PROJECTOR_PATH))
	var high := Image.load_from_file(ProjectSettings.globalize_path(HIGH_PATH))
	var region := Rect2i(96, 108, 64, 12)
	var gain := _mean(high, region) / maxf(_mean(low, region), 0.001)
	_check(gain > 3.0 and _mean(high, Rect2i(0, 160, 256, 96)) >= _mean(low, Rect2i(0, 160, 256,
		96)) - 0.01, "High beams light far up the road, above the low beam's cutoff, "
		+ "and keep the low beam's near light (%.1fx brighter at the horizon)" % gain)


func _mean(image: Image, region: Rect2i) -> float:
	var total := 0.0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			total += image.get_pixel(x, y).srgb_to_linear().r
	return total / float(region.get_area())


func _start_game() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-headlights-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	await process_frame
	_app.call("_resume")
	await _wait_physics(10)


func _headlights() -> Array[SpotLight3D]:
	var result: Array[SpotLight3D] = []
	for node in _van.find_children("*", "SpotLight3D", true, false):
		result.append(node as SpotLight3D)
	return result


func _all_patterns(lights: Array[SpotLight3D], path: String) -> bool:
	for light in lights:
		if light.light_projector == null or light.light_projector.resource_path != path:
			return false
	return not lights.is_empty()


func _all_visible(lights: Array[SpotLight3D], expected: bool) -> bool:
	for light in lights:
		if light.visible != expected:
			return false
	return not lights.is_empty()


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


func _wait_physics(count: int) -> void:
	for step in range(count):
		await physics_frame


func _finish() -> void:
	print("HEADLIGHTS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Headlight test finished within 120 s of game time")
	quit(1)
