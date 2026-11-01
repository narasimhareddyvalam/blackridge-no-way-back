extends SceneTree

const TRIGGER_SIDE := 966
const WATCH_FROM := 1000
const PULL_OVER := 1.35
const DISTANCES: Array[float] = [120.0, 60.0, 35.0, 20.0, 10.0]
const FLASH_AT := 80.0
const WINDSHIELD := Rect2i(160, 60, 960, 380)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _environment: Environment
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-oncoming-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/oncoming/step3")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	var holder := _app.get_node("IndustrialLoop").find_children("*", "WorldEnvironment", false,
		false)[0] as WorldEnvironment
	_environment = holder.environment
	_route.set("stage", 4)
	_place(TRIGGER_SIDE, 0.0)
	while not is_instance_valid(_route.get("oncoming")):
		await physics_frame
	var oncoming: Node3D = _route.get("oncoming")
	await _debug_look(oncoming)
	_place(WATCH_FROM, PULL_OVER)
	_hold("brake", true)
	await _seconds(1.5)
	await _shot("before_it_comes", oncoming)
	var flashed := false
	for limit in DISTANCES:
		while is_instance_valid(oncoming) and _gap(oncoming) > limit:
			if not flashed and _gap(oncoming) < FLASH_AT:
				flashed = true
				await _press("headlights")
				while is_instance_valid(oncoming) and not oncoming.get("high_beams"):
					await process_frame
				await _shot("high_beams_flash_back", oncoming)
				await _press("headlights")
				await _press("headlights")
			await process_frame
		await _shot("oncoming_%dm" % int(limit), oncoming)
	while is_instance_valid(oncoming) and not oncoming.get("_passed"):
		await process_frame
	await _seconds(1.0)
	await _shot("after_it_passed", oncoming)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("oncoming_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _debug_look(oncoming: Node3D) -> void:
	oncoming.set_physics_process(false)
	var camera := Camera3D.new()
	camera.fov = 45.0
	root.add_child(camera)
	camera.look_at_from_position(oncoming.to_global(Vector3(-5.5, 2.2, -9.0)),
		oncoming.to_global(Vector3(0.0, 1.3, -0.5)))
	camera.make_current()
	_report.append("debug camera at %s, oncoming van at %s" % [str(camera.global_position),
		str(oncoming.global_position)])
	await _seconds(1.0)
	await _shot("oncoming_van_night", oncoming)
	var ambient := _environment.ambient_light_energy
	var fog := _environment.fog_enabled
	_environment.ambient_light_energy = 6.0
	_environment.fog_enabled = false
	await _seconds(0.5)
	await _shot("oncoming_van_debug_light", oncoming)
	_environment.ambient_light_energy = ambient
	_environment.fog_enabled = fog
	oncoming.set_physics_process(true)
	_van.call("get_camera").make_current()
	camera.queue_free()


func _gap(oncoming: Node3D) -> float:
	return _van.global_position.distance_to(oncoming.global_position)


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _shot(stem: String, oncoming: Node3D) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var glass := _van.get_node("VanPresentation").get("_glass") as ShaderMaterial
	var power: Variant = glass.get_shader_parameter("glare_power")
	var gap := _gap(oncoming) if is_instance_valid(oncoming) else -1.0
	var lamps := ""
	if is_instance_valid(oncoming):
		var camera := root.get_viewport().get_camera_3d()
		for lamp: Node3D in oncoming.get("lamps"):
			lamps += " %s" % str(camera.unproject_position(lamp.global_position).round())
	_report.append("saved %s.png: oncoming %.0f m away, glare %s at %s, lamps on screen%s, "
		% [stem, gap, str(power), str(glass.get_shader_parameter("glare_points")), lamps]
		+ "windshield brightness %.1f, %.0f FPS" % [_luma(image, WINDSHIELD),
		Engine.get_frames_per_second()])


func _luma(image: Image, area: Rect2i) -> float:
	var total := 0.0
	var count := 0
	for y in range(area.position.y, area.end.y, 4):
		for x in range(area.position.x, area.end.x, 4):
			var colour := image.get_pixel(x, y)
			total += 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
			count += 1
	return total * 255.0 / maxf(1.0, float(count))


func _press(action: String) -> void:
	_hold(action, true)
	await process_frame
	_hold(action, false)
	await process_frame


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
