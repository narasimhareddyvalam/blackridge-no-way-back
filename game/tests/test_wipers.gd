extends SceneTree

const WipeMap = preload("res://features/vehicles/freight_van/windshield_wipe_map.gd")
const GLASS = preload("res://features/vehicles/freight_van/windshield.gdshader")
const PARTS: Array[String] = ["PivotCap", "SpringCover", "Arm", "Hook", "Blade"]
const BLADE_PARTS: Array[String] = ["Spoiler", "Rubber", "EndCapInner", "EndCapOuter", "Adapter"]
const WATER_UNIFORMS: Array[String] = ["blade_speed", "stroke_progress", "dump", "wiper_cycles",
	"wiper_park", "wiper_sweep", "wiper_pivots", "wiper_spans"]
const HIGHWAY := 20.0

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-wipers-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	_app.call("_resume")
	await physics_frame
	_check_parts()
	_check_glass_fit()
	_check_shader()
	await _check_water()
	_finish()


func _check_parts() -> void:
	var wipers: Array = _presentation.get("_wipers")
	_check(wipers.size() == 2, "Two wipers are built (%d)" % wipers.size())
	var complete := true
	var outside := true
	var widths: Array[float] = []
	var lengths: Array[float] = []
	for wiper: Node3D in wipers:
		var blade: Node3D = wiper.get("blade")
		for part in PARTS:
			complete = complete and wiper.has_node(part)
		for part in BLADE_PARTS:
			complete = complete and blade.has_node(part)
		if not complete:
			continue
		widths.append((blade.get_node("Spoiler") as MeshInstance3D).get_aabb().size.x)
		lengths.append((blade.get_node("Rubber") as MeshInstance3D).get_aabb().size.y)
		var into_wiper := wiper.global_transform.affine_inverse()
		for found in wiper.find_children("*", "MeshInstance3D", true, false):
			var part: MeshInstance3D = found
			var bounds := into_wiper * part.global_transform * part.get_aabb()
			outside = outside and bounds.end.z < 0.001
	_check(complete, "Each wiper has a pivot cap, spring cover, arm and hook, and a blade with "
		+ "spoiler, rubber lip, end caps and adapter")
	if widths.size() < 2:
		return
	_check(widths[0] > 0.017 and widths[0] < 0.024 and widths[1] > 0.017 and widths[1] < 0.024,
		"The blades are about 2 cm wide (%.1f and %.1f cm)" % [widths[0] * 100.0,
		widths[1] * 100.0])
	_check(lengths[0] > lengths[1] + 0.1,
		"The driver's blade is longer than the passenger's (%.0f and %.0f cm)" % [
		lengths[0] * 100.0, lengths[1] * 100.0])
	_check(outside, "Every wiper part sits outside the glass")


func _check_glass_fit() -> void:
	var overlays: Array = _presentation.get("fog_overlays")
	var pane: Node3D = (overlays[0] as Node3D).get_parent()
	var wipers: Array = _presentation.get("_wipers")
	var worst := 0.0
	for index in range(wipers.size()):
		var wiper: Node3D = wipers[index]
		var blade: Node3D = wiper.get("blade")
		var half: float = WipeMap.BLADES[index] * 0.5
		var pivot := pane.to_local(wiper.global_position)
		var inner := pane.to_local(blade.to_global(Vector3(0.0, -half, 0.0)))
		var outer := pane.to_local(blade.to_global(Vector3(0.0, half, 0.0)))
		var expected: Vector2 = WipeMap.PIVOTS[index]
		var reach := WipeMap.span(index)
		worst = maxf(worst, Vector2(pivot.x, pivot.y).distance_to(expected) + absf(pivot.z))
		worst = maxf(worst, absf(Vector2(inner.x, inner.y).distance_to(expected) - reach.x))
		worst = maxf(worst, absf(Vector2(outer.x, outer.y).distance_to(expected) - reach.y))
	_check(worst < 0.005,
		"The wiped area on the glass matches where the blades lie (worst %.1f mm)" % (worst * 1000.0))


func _check_shader() -> void:
	var names: Array[String] = []
	for item in GLASS.get_shader_uniform_list():
		names.append(String(item["name"]))
	var missing: Array[String] = []
	for name in WATER_UNIFORMS:
		if not names.has(name):
			missing.append(name)
	_check(missing.is_empty(), "The windshield takes the blade's motion, the dumped water and the "
		+ "wiper layout (missing: %s)" % ", ".join(missing))
	_check(GLASS.code.count("wipe_seed(") >= 4,
		"New drops land in new places after each wipe (three resting layers reseeded)")
	var parked := WipeMap.REWET_SECONDS
	var fast := parked / (1.0 + HIGHWAY / WipeMap.SPEED_REWET)
	_check(parked >= 1.5 and fast >= 0.5,
		"Wiped glass stays clear long enough to see (re-wets over %.1f s parked, %.2f s at 72 km/h)"
		% [parked, fast])


func _check_water() -> void:
	var glass: ShaderMaterial = _presentation.get("_glass")
	var fastest := 0.0
	var progress_ok := true
	var turned_at := -1
	var later_dump := 1.0
	for frame in range(200):
		await physics_frame
		fastest = maxf(fastest, absf(_param(glass, "blade_speed")))
		var progress := _param(glass, "stroke_progress")
		progress_ok = progress_ok and progress >= 0.0 and progress <= 1.0
		var dump := _param(glass, "dump")
		if turned_at < 0 and dump > 0.95:
			turned_at = frame
		if turned_at >= 0 and frame == turned_at + 72:
			later_dump = dump
	_check(fastest > 3.0 and fastest < 6.0 and progress_ok,
		"The glass follows each blade's swing (fastest %.1f rad/s)" % fastest)
	_check(turned_at >= 0 and later_dump < 0.25,
		"Water is dumped where the blades turn at the top, then breaks up (%.2f after 1.2 s)"
		% later_dump)
	_van.wiper_setting = 0
	for frame in range(150):
		await physics_frame
	_check(is_zero_approx(_param(glass, "blade_speed")) and _param(glass, "dump") < 0.05,
		"Parked wipers push no water")


func _param(glass: ShaderMaterial, name: String) -> float:
	var value: Variant = glass.get_shader_parameter(name)
	return float(value) if value != null else 0.0


func _finish() -> void:
	print("WIPERS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Wiper test finished within 100 s of game time")
	quit(1)
