extends SceneTree

const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const LOW_BEAM = preload("res://features/vehicles/freight_van/art/low_beam_pattern.png")
const TRIGGER_SIDE := 966
const WAIT_AT := 1030
const PULL_OVER := 1.35

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _route: Node
var _road: RefCounted
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(140.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-oncoming-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	await physics_frame
	_check(_route.get("road") == _road, "The mission is given the ghat road")
	_route.set("stage", 4)
	_place(TRIGGER_SIDE, 0.0)
	await _seconds(0.5)
	var oncoming: Node3D = _route.get("oncoming")
	_check_arrival(oncoming)
	if not is_instance_valid(oncoming):
		_finish()
		return
	_place(WAIT_AT, 0.0)
	await _check_blocked(oncoming)
	_place(WAIT_AT, PULL_OVER)
	await _check_passing(oncoming)
	await _check_gone(oncoming)
	_place(TRIGGER_SIDE, 0.0)
	await _seconds(0.5)
	_check(not is_instance_valid(_route.get("oncoming")),
		"Driving past the trigger again sends no second van (once per drive)")
	_route.call("restart")
	_check(not bool(_route.get("_encounter_done")), "New drive allows the encounter again")
	_finish()


func _check_arrival(oncoming: Node3D) -> void:
	_check(oncoming is AnimatableBody3D, "Below the last hairpin the mission sends one oncoming van")
	if not is_instance_valid(oncoming):
		return
	var start := int(round(float(oncoming.get("distance")) / OncomingVan.SPACING))
	_check(start >= 1040, "It starts beyond the valley S-bend, out of sight (sample %d)" % start)
	var points: PackedVector3Array = _road.points
	var downhill := points[start - 1] - points[start]
	_check((-oncoming.global_basis.z).dot(downhill.normalized()) > 0.9,
		"It drives towards the player, against the lap")
	var lamps: Array = oncoming.get("lamps")
	var proper := lamps.size() == 2
	for lamp: SpotLight3D in lamps:
		proper = proper and not lamp.shadow_enabled and lamp.light_cull_mask == 5 \
			and lamp.light_projector == LOW_BEAM
	_check(proper, "Its two low beams cast no shadows and light the road and the player's cab")
	_check((oncoming.collision_layer & 1) != 0 and (_van.collision_mask & 1) != 0,
		"The player's van can collide with it")
	_check(_presentation.get("oncoming") == oncoming,
		"The player's van is told about it, for the glare")


func _check_blocked(oncoming: Node3D) -> void:
	var waited := 0.0
	var brightest := 0.0
	var darkest := 1.0
	var backlit := 0.0
	var toggles := 0
	var was_high := false
	var dipped := false
	while waited < 25.0:
		await physics_frame
		waited += 1.0 / 60.0
		var power := _glare_power()
		brightest = maxf(brightest, maxf(power.x, power.y))
		darkest = minf(darkest, _exposure())
		var lit_rain: Variant = _rain().get_shader_parameter("oncoming")
		backlit = maxf(backlit, 0.0 if lit_rain == null else float(lit_rain))
		var gap := -_van_from(oncoming).z - OncomingVan.BUMPERS
		if gap < 60.0 and toggles == 0 and not _van.get("high_beams"):
			await _tap("headlights")
		var high: bool = oncoming.get("high_beams")
		if high != was_high:
			toggles += 1
			was_high = high
		if toggles >= 4 and _van.get("high_beams") and not dipped:
			dipped = true
			await _tap("headlights")
			await _tap("headlights")
		if float(oncoming.get("speed")) < 0.05 and gap < 15.0:
			break
	var stopped_gap := -_van_from(oncoming).z - OncomingVan.BUMPERS
	_check(float(oncoming.get("speed")) < 0.05 and stopped_gap > 1.5 and stopped_gap < 6.0,
		"Blocked by the player's van in mid-road, it stops short (%.1f m gap, %.1f s)" % [
			stopped_gap, waited])
	_check(toggles >= 4, "It flashes its high beams twice at the player's high beams (%d changes)"
		% toggles)
	_check(brightest > 0.3, "Its lamps put glare on the wet windshield (peak %.2f)" % brightest)
	_check(darkest < 0.7, "Staring into them, the driver's eyes adapt: the road darkens to %.2f"
		% darkest)
	_check(backlit > 0.0, "Its beams light the rain in front of the player (%.1f)" % backlit)
	_check(_van.get("headlights_on") and not _van.get("high_beams"),
		"The player's lights are back on low beam")


func _check_passing(oncoming: Node3D) -> void:
	var waited := 0.0
	var closest := INF
	var offset_error := 0.0
	while waited < 20.0 and not bool(oncoming.get("_passed")):
		await physics_frame
		waited += 1.0 / 60.0
		var local := _van_from(oncoming)
		if absf(local.z) < OncomingVan.LENGTH:
			closest = minf(closest, absf(local.x))
		offset_error = maxf(offset_error, absf(_side_offset(oncoming)
			- (2.25 - OncomingVan.KEEP_RIGHT)))
	_check(bool(oncoming.get("_passed")),
		"When the player keeps right it squeezes past (%.1f s)" % waited)
	_check(closest >= 2.45, "The two vans never overlap (%.2f m between centres)" % closest)
	_check(offset_error < 0.1, "It hugs its own verge, %.2f m right of the centre line (error %.2f)"
		% [2.25 - OncomingVan.KEEP_RIGHT, offset_error])
	await _seconds(1.0)
	var power := _glare_power()
	_check(maxf(power.x, power.y) < 0.02, "Once it is behind, the glare is gone (%.3f)"
		% maxf(power.x, power.y))
	var after_pass := _exposure()
	await _seconds(6.0)
	_check(after_pass < 0.9 and _exposure() > 0.97,
		"The eyes recover over a few seconds (%.2f a second after, %.2f later)" % [after_pass,
		_exposure()])


func _check_gone(oncoming: Node3D) -> void:
	var waited := 0.0
	while is_instance_valid(oncoming) and waited < 45.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(not is_instance_valid(oncoming),
		"It drives back up the hill and is gone (%.0f s)" % waited)


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var heading: float = _road.call("heading_at", index)
	var basis := Basis(Vector3.UP, heading)
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _van_from(oncoming: Node3D) -> Vector3:
	return oncoming.to_local(_van.global_position)


func _side_offset(oncoming: Node3D) -> float:
	var along := float(oncoming.get("distance"))
	var points: PackedVector3Array = _road.points
	var index := int(along / OncomingVan.SPACING)
	var centre := points[index].lerp(points[index + 1], along / OncomingVan.SPACING - index)
	var right := (-oncoming.global_basis.z).cross(Vector3.UP).normalized()
	return (oncoming.global_position - centre).dot(right)


func _exposure() -> float:
	var camera := _presentation.get("driving_camera") as Camera3D
	return (camera.attributes as CameraAttributesPractical).exposure_multiplier


func _glare_power() -> Vector2:
	var power: Variant = _glass().get_shader_parameter("glare_power")
	return Vector2.ZERO if power == null else power


func _glass() -> ShaderMaterial:
	return _presentation.get("_glass")


func _rain() -> ShaderMaterial:
	return _presentation.get("_beam_rain_material")


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("ONCOMING VAN RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Oncoming-van test finished within 140 s of game time")
	quit(1)
