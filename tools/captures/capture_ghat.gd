extends SceneTree

const GhatRoad = preload("res://features/environments/industrial_loop/ghat_road.gd")
const SAMPLE_SECONDS := 4.0

var _app: Node3D
var _world: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _road: RefCounted
var _folder: String
var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-ghat-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/ghat")
	DirAccess.make_dir_recursive_absolute(_folder)
	_world = _app.get_node("IndustrialLoop")
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_road = _world.get("road")
	await _seconds(3.0)
	await _shot("start_lumber_yard", -1, Vector2.ZERO)
	await _measure("start, parked")
	await _wiper_shots()
	var climb := _steepest(GhatRoad.Section.CLIMB, 1.0)
	await _shot("climb_leg", climb, Vector2.ZERO)
	await _measure("steepest climb, parked")
	var hairpins := _hairpin_starts(GhatRoad.Section.CLIMB_HAIRPIN)
	await _shot("hairpin_approach_signs", hairpins[1] - 22, Vector2(-0.04, 0.0))
	await _shot("hairpin_apex", _middle_of(hairpins[2]), Vector2(-0.05, 0.0))
	var trial := _app.get_node("DrivingTrial")
	var view: Vector3 = trial.TARGETS[1]
	await _pose_shot("viewpoint_town_lights", view, 2.4, Vector2(-0.1, 0.0))
	await _measure("viewpoint, looking at town")
	await _shot("pass_ahead", _nearest(trial.TARGETS[2]), Vector2.ZERO)
	await _measure("pass, parked")
	var descent: int = _road.sections.find(GhatRoad.Section.DESCENT)
	await _shot("descent_grade_sign", descent - 6, Vector2.ZERO)
	var low := _hairpin_starts(GhatRoad.Section.DESCENT_HAIRPIN)
	await _shot("descent_mirror_hairpin", low[2] - 10, Vector2(-0.05, 0.0))
	await _shot("descent_leg", _steepest(GhatRoad.Section.DESCENT, -1.0), Vector2.ZERO)
	await _measure("steepest descent, parked")
	var slide := _nearest(Vector3(330, 0, 166))
	await _shot("landslide_closed", slide - 34, Vector2.ZERO)
	await _shot("town_lamps", _nearest(Vector3(60, 0, 55)), Vector2.ZERO)
	await _climb_measure(climb)
	await _zoom_map()
	await _overview()
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("ghat_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _shot(stem: String, index: int, look: Vector2) -> void:
	if index >= 0:
		_place(index)
	_hold("brake", true)
	_presentation.set("_look_target", look)
	await _seconds(1.5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	_report.append("saved %s.png at %s, road grade %.1f%%, body pitch %.1f degrees" % [stem,
		str(_van.global_position.snapped(Vector3.ONE * 0.1)), _grade_here() * 100.0,
		rad_to_deg(_presentation.rotation.x)])
	_hold("brake", false)


func _pose_shot(stem: String, at: Vector3, heading: float, look: Vector2) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, heading), at + Vector3.UP * 0.35))
	_hold("brake", true)
	_presentation.set("_look_target", look)
	await _seconds(1.5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	_report.append("saved %s.png at %s" % [stem,
		str(_van.global_position.snapped(Vector3.ONE * 0.1))])
	_hold("brake", false)


func _wiper_shots() -> void:
	var middle: float = _van.WIPER_PARK + _van.WIPER_SWEEP * 0.5
	var waited := 0
	while absf(float(_van.get("wiper_angle")) - middle) > 0.08 and waited < 400:
		await process_frame
		waited += 1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join("wipers_mid_sweep.png"))
	_report.append("saved wipers_mid_sweep.png (wiper angle %.2f rad)" % _van.get("wiper_angle"))
	await _press("wipers")
	await _press("wipers")
	await _seconds(1.2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join("wipers_parked.png"))
	_report.append("saved wipers_parked.png (setting %d, angle %.2f rad)" % [
		_van.get("wiper_setting"), _van.get("wiper_angle")])
	await _press("wipers")


func _press(action: String) -> void:
	_hold(action, true)
	await process_frame
	_hold(action, false)
	await process_frame


func _climb_measure(index: int) -> void:
	_place(index - 40)
	_presentation.set("_look_target", Vector2.ZERO)
	await _seconds(1.0)
	_hold("accelerate", true)
	await _seconds(1.0)
	await _measure("climbing at full throttle")
	_hold("accelerate", false)
	_hold("brake", true)
	await _seconds(1.0)
	_hold("brake", false)


func _measure(label: String) -> void:
	var times := PackedFloat32Array()
	var start := Time.get_ticks_usec()
	var last := start
	while last - start < int(SAMPLE_SECONDS * 1000000.0):
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	var sorted := times.duplicate()
	sorted.sort()
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	_report.append(("%-28s FPS %5.1f | median %6.2f ms, slowest 5%% %6.2f ms | %d draws, "
		+ "%.2fM triangles") % [label, times.size() / SAMPLE_SECONDS, sorted[sorted.size() / 2],
		sorted[int(sorted.size() * 0.95)], draws, triangles / 1000000.0])


func _zoom_map() -> void:
	_place(_nearest(_app.get_node("DrivingTrial").TARGETS[2]))
	var camera: Camera3D = _presentation.get("driving_camera")
	var wide := camera.fov
	camera.fov = 24.0
	_presentation.set("_look_target", Vector2(-0.16, -0.30))
	_hold("brake", true)
	await _seconds(1.2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join("map_screen.png"))
	_report.append("saved map_screen.png")
	camera.fov = wide
	_hold("brake", false)


func _overview() -> void:
	var holder := _world.find_children("*", "WorldEnvironment", false, false)[0]
	var environment: Environment = (holder as WorldEnvironment).environment
	var ambient := environment.ambient_light_energy
	environment.ambient_light_energy = 6.0
	environment.fog_enabled = false
	var camera := Camera3D.new()
	camera.far = 1200.0
	root.add_child(camera)
	camera.look_at_from_position(Vector3(260, 230, 420), Vector3(250, 20, -60))
	camera.make_current()
	await _seconds(1.5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join("overview_debug_light.png"))
	_report.append("saved overview_debug_light.png (debug: ambient 6.0, fog off)")
	environment.ambient_light_energy = ambient
	environment.fog_enabled = true
	_van.call("get_camera").make_current()
	camera.queue_free()


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var at := posmod(index, points.size())
	_van.call("recover", Transform3D(Basis(Vector3.UP, _road.heading_at(at)),
		points[at] + Vector3.UP * 0.35))


func _steepest(section: int, sign: float) -> int:
	var best := -1
	for index in range(3, _road.points.size() - 3):
		if _road.sections[index - 3] != section or _road.sections[index + 3] != section:
			continue
		if best < 0 or _road.grade_at(index) * sign > _road.grade_at(best) * sign:
			best = index
	return best


func _hairpin_starts(section: int) -> Array[int]:
	var starts: Array[int] = []
	for index in range(1, _road.points.size()):
		if _road.sections[index] == section and _road.sections[index - 1] != section:
			starts.append(index)
	return starts


func _middle_of(start: int) -> int:
	var end := start
	while _road.sections[end] == _road.sections[start]:
		end += 1
	return (start + end) / 2


func _nearest(target: Vector3) -> int:
	var best := 0
	var points: PackedVector3Array = _road.points
	for index in range(points.size()):
		if points[index].distance_to(target) < points[best].distance_to(target):
			best = index
	return best


func _grade_here() -> float:
	return _road.grade_at(_nearest(_van.global_position))


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
