extends SceneTree

const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const Navigation = preload("res://features/vehicles/freight_van/navigation_display.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
const CLIMB := 125
const BEFORE_HAIRPIN := 98
const HAIRPIN := 148
const MID_LEG := 470
const LANE := 1.0
const SPEED := 8.0
const OVERHANG := 0.003

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _nav: Control
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
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-dash-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_road = _app.get_node("IndustrialLoop").get("road")
	await process_frame
	_app.call("_resume")
	_nav = _presentation.get("navigation")
	await _seconds(0.5)
	_check_fit()
	_check_display()
	await _check_power()
	await _check_map()
	await _check_directions()
	_check_run_sheet()
	await _check_reverse()
	_finish()


func _check_fit() -> void:
	var screen: MeshInstance3D = _presentation.get("_map_screen")
	var cover := _presentation.find_child("ScreenCover", true, false) as MeshInstance3D
	if screen == null or cover == null:
		_check(false, "The map fills the van's own display")
		return
	var frame := screen.global_transform
	var half := (screen.mesh as QuadMesh).size * 0.5
	var faces := cover.global_transform * (cover.mesh as ArrayMesh).get_faces()
	var low := Vector2(INF, INF)
	var high := -low
	for point in faces:
		var local := frame.affine_inverse() * point
		low = low.min(Vector2(local.x, local.y))
		high = high.max(Vector2(local.x, local.y))
	var spill := maxf(maxf(-half.x - low.x, high.x - half.x), maxf(-half.y - low.y,
		high.y - half.y))
	var overhang := maxf(maxf(low.x + half.x, half.x - high.x), maxf(low.y + half.y,
		half.y - high.y))
	_check(faces.size() >= 18 and spill < 0.001 and overhang < OVERHANG,
		"The map fills the van's own display, %.1f x %.1f cm, and no more: it covers the " % [
		half.x * 200.0, half.y * 200.0] + "screen's glass to within %.1f mm and stops %.1f mm "
		% [spill * 1000.0, overhang * 1000.0] + "short of the buttons and knob around it")
	var eye := _presentation.global_transform * Presentation.EYE
	var facing := frame.basis.z.normalized().dot((eye - frame.origin).normalized())
	_check(facing > 0.75, "The display faces the driver, as the van's own screen does (%.2f)"
		% facing)


func _check_display() -> void:
	var screen: MeshInstance3D = _presentation.get("_map_screen")
	var surface := screen.material_override as ShaderMaterial
	var border: Vector2 = surface.get_shader_parameter("border")
	var black := float(surface.get_shader_parameter("black_level"))
	var angle := float(surface.get_shader_parameter("view_falloff"))
	_check(border.x > 0.0 and border.y > 0.0 and black > 0.0 and angle > 0.0,
		"It looks like an LCD: a thin black border, backlit blacks (%.3f), and a little dimmer "
		% black + "seen from the side (%.0f%%)" % (angle * 100.0))
	var glass := _presentation.find_child("ScreenGlass", true, false) as MeshInstance3D
	var gloss := glass.material_override as StandardMaterial3D if glass else null
	var in_front := glass != null and (glass.global_position - screen.global_position).dot(
		screen.global_basis.z) > 0.001
	var glow := _presentation.find_child("ScreenGlow", true, false) as OmniLight3D
	_check(gloss != null and gloss.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
		and gloss.roughness < 0.2 and in_front and glow != null and glow.light_cull_mask == 4
		and glow.light_energy > 0.0,
		"Glossy glass sits in front of it, and it throws a faint glow on the dash")


func _check_power() -> void:
	_van.call("switch_off")
	await _seconds(1.5)
	var off := float(_presentation.get("_screen_power"))
	var dark: Array = _presentation.get("_dark_screens")
	var dark_shown := (dark[1] as Node3D).visible
	_van.call("start_engine")
	await _seconds(0.6)
	var booting := float(_presentation.get("_screen_power"))
	await _seconds(1.0)
	var on := float(_presentation.get("_screen_power"))
	_check(off < 0.01 and dark_shown and booting > 0.2 and booting < 0.8 and on > 0.99,
		"It goes dark with the engine off, and starts up with a fade at the "
		+ "ignition (%.0f%% after 0.6 s)" % (booting * 100.0))


func _check_map() -> void:
	_place(CLIMB, LANE, false)
	await _drive(1.5, SPEED)
	var yaw := float(_van.global_rotation.y)
	var turned := absf(rad_to_deg(angle_difference(float(_nav.get("map_yaw")), yaw)))
	var slow := float(_nav.get("map_scale"))
	_check(turned < 5.0, "The map turns with the van, heading-up (%.1f degrees behind)" % turned)
	_place(MID_LEG, LANE, false)
	await _drive(2.5, 16.0)
	var fast := float(_nav.get("map_scale"))
	_check(fast < slow - 0.4, "It zooms out at speed and in when slow (%.2f px/m at 58 km/h, "
		% fast + "%.2f at 29 km/h)" % slow)
	_place(CLIMB, LANE, false)
	var started := float(_van.get("clock"))
	await _drive(1.0, SPEED)
	var here := int(_nav.get("route_index"))
	var depot := _nearest(Mission.TARGETS[Mission.TARGETS.size() - 1])
	var along := _along(here, depot)
	var bay: Vector3 = Mission.TARGETS[Mission.TARGETS.size() - 1]
	var straight := Vector2(_van.global_position.x - bay.x,
		_van.global_position.z - bay.z).length()
	var shown := float(_nav.get("to_turn"))
	_check(absf(shown - along) < 6.0 and along > straight + 300.0,
		"It counts down the distance along the road to the depot turn, %.0f m, not the %.0f m "
		% [shown, straight] + "straight line")
	var left := float(_nav.get("seconds_left"))
	await _drive(2.0, SPEED)
	var later := float(_nav.get("seconds_left"))
	var ran := float(_van.get("clock")) - started
	_check(later < left and left > 120.0 and absf(ran - 3.0) < 0.1,
		"The clock runs (%.1f s in 3 s), and the arrival time follows the drive left " % ran
		+ "(%.0f s to go, then %.0f s)" % [left, later])


func _check_directions() -> void:
	_place(BEFORE_HAIRPIN, LANE, false)
	await _drive(0.6, SPEED)
	var near := float(_nav.get("next_hairpin"))
	var expected := _along(int(_nav.get("route_index")), HAIRPIN)
	_place(MID_LEG, LANE, false)
	await _drive(0.6, SPEED)
	var far := float(_nav.get("next_hairpin"))
	_check(absf(near - expected) < 6.0 and near <= Navigation.HAIRPIN_WARNING and far < 0.0,
		"A hairpin warning shows %.0f m before the hairpin, and none on the open road" % near)
	_place(MID_LEG, LANE, true)
	await _drive(2.5, SPEED)
	var wrong := bool(_nav.get("wrong_way"))
	_place(MID_LEG, LANE, false)
	await _drive(2.0, SPEED)
	_check(wrong and not bool(_nav.get("wrong_way")),
		"Driving the wrong way it says Turn around, and stops once the van turns back")
	var bay: Vector3 = Mission.TARGETS[Mission.TARGETS.size() - 1]
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), bay + Vector3.UP * 0.1))
	await _drive(0.6, 0.0)
	_check(bool(_nav.get("arrived")), "In the depot bay it says Arrived")


func _check_run_sheet() -> void:
	var fair := true
	for line: String in Navigation.RUN_SHEET:
		for part in line.split(" · "):
			fair = fair and part in Mission.RUN_SHEET
	_check(fair, "Every line on the screen's run sheet comes from the signed run sheet")


func _check_reverse() -> void:
	var view: SubViewport = _presentation.get("reverse_view")
	var guides := false
	for child in view.get_children():
		guides = guides or child is Control and (child as Control).get_script() == ParkingGuides
	var aspect := float(view.size.x) / view.size.y
	var display := Presentation.MAP_SIZE.x / Presentation.MAP_SIZE.y
	_van.set("gear", -1)
	await _seconds(0.2)
	var shown := (_presentation.get("reverse_screen") as Node3D).visible
	_van.set("gear", 1)
	await _seconds(0.2)
	_check(guides and shown and absf(aspect - display) < 0.05,
		"In reverse the camera fills the display with parking guide lines")


func _place(index: int, right: float, backwards: bool) -> void:
	var points: PackedVector3Array = _road.points
	var yaw: float = _road.call("heading_at", index) + (PI if backwards else 0.0)
	var basis := Basis(Vector3.UP, yaw)
	var side := Basis(Vector3.UP, _road.call("heading_at", index)).x
	_van.call("recover", Transform3D(basis, points[index] + side * right + Vector3.UP * 0.1))


func _drive(duration: float, speed: float) -> void:
	for frame in range(int(duration * 60.0)):
		_van.set("speed", speed)
		await physics_frame


func _nearest(at: Vector3) -> int:
	var points: PackedVector3Array = _road.points
	var best := 0
	for index in range(points.size()):
		if Vector2(points[index].x - at.x, points[index].z - at.z).length() \
				< Vector2(points[best].x - at.x, points[best].z - at.z).length():
			best = index
	return best


func _along(from: int, to: int) -> float:
	var points: PackedVector3Array = _road.points
	var total := 0.0
	for index in range(from, to):
		total += Vector2(points[index + 1].x - points[index].x,
			points[index + 1].z - points[index].z).length()
	return total


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("DASH SCREEN RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Dash screen test finished within 120 s of game time")
	quit(1)
