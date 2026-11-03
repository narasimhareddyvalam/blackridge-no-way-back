extends SceneTree

const APPROACH := 672
const RUN_SPEED := 8.0
const LANE := 1.0
const GLARE_AT := 70.0
const OVERVIEW := Vector3(8.0, 6.0, -12.0)
const LaneKeeper = preload("res://tests/lane_keeper.gd")
const DEPOT := Vector3(-28.0, 0.1, 93.0)
const WINDSHIELD := Rect2i(160, 60, 960, 380)
const SIDE_VIEW := Vector3(-7.0, 1.6, -5.0)
const SEQUENCE: Array[int] = [3, 9, 21, 36, 60]
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _route: Node
var _road: RefCounted
var _folder: String
var _report := PackedStringArray()
var _driving := false
var _run_speed := RUN_SPEED


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-collision-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/collision/run25")
	if OS.get_cmdline_user_args().size() > 1:
		_run_speed = float(OS.get_cmdline_user_args()[1])
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	_place(APPROACH, LANE)
	_van.set("speed", _run_speed)
	_drive(LaneKeeper.new(_road, APPROACH))
	while not is_instance_valid(_route.get("oncoming")):
		await physics_frame
	var oncoming: Node3D = _route.get("oncoming")
	var pedestrian: Node3D = _route.get("pedestrian")
	var crossing: Node3D = _route.get("crossing")
	await _overview(crossing, pedestrian)
	while is_instance_valid(oncoming) and _van.global_position.distance_to(
			oncoming.global_position) > GLARE_AT:
		await physics_frame
	await _shot("oncoming_high_beams", pedestrian)
	while is_instance_valid(oncoming) and oncoming.to_local(_van.global_position).z \
			< -OncomingVan.BUMPERS:
		await physics_frame
	await _shot("blinded_as_it_passes", pedestrian)
	while pedestrian.get("waiting"):
		await physics_frame
	_driving = false
	_hold("brake", true)
	await _shot("he_steps_out", pedestrian)
	while _van.to_local(pedestrian.global_position).z < -4.2 and not pedestrian.get("hit"):
		await physics_frame
	await _shot("skidding_on_the_paint", pedestrian)
	while not pedestrian.get("hit"):
		await physics_frame
	var struck_frame := Engine.get_physics_frames()
	_hold("brake", false)
	await _shot("impact", pedestrian)
	var glass := _presentation.get("_glass") as ShaderMaterial
	while glass.get_shader_parameter("crack_amount") == null \
			or float(glass.get_shader_parameter("crack_amount")) <= 0.0:
		await physics_frame
	await _shot("head_strikes_the_windshield", pedestrian)
	await _side_sequence(pedestrian, struck_frame)
	while float(_presentation.get("_lean")) < 1.0 and _van.get("held"):
		await physics_frame
	await _shot("leaning_over_the_wheel", pedestrian)
	while not _route.get("fleeing"):
		await physics_frame
	await _shot("drive_objective", pedestrian)
	await _seconds(1.2)
	await _shot("sitting_back", pedestrian)
	while not pedestrian.get("settled"):
		await physics_frame
	await _debug_look(pedestrian)
	_hold("accelerate", true)
	await _seconds(1.5)
	_hold("accelerate", false)
	await _shot("driving_on_with_the_crack", pedestrian)
	_route.set("stage", 4)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DEPOT))
	_hold("brake", true)
	while not _route.get("complete"):
		await physics_frame
	_hold("brake", false)
	await _seconds(4.0)
	await _shot("quiet_ending_in_the_cab", pedestrian)
	var fade := _app.get_node("DrivingHud").get("_fade") as ColorRect
	while fade.modulate.a < 0.5:
		await process_frame
	await _shot("fading_to_black", pedestrian)
	while not paused:
		await process_frame
	await _shot("menu_after_the_ending", pedestrian)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("collision_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _drive(keeper: RefCounted) -> void:
	_driving = true
	while _driving:
		await physics_frame
		if _driving:
			keeper.steer(_van, LANE)
			_hold("accelerate", float(_van.get("speed")) < _run_speed)
	keeper.release()
	_hold("accelerate", false)


func _overview(crossing: Node3D, pedestrian: Node3D) -> void:
	var holder := _app.get_node("IndustrialLoop").find_children("*", "WorldEnvironment", false,
		false)[0] as WorldEnvironment
	var environment := holder.environment
	var camera := Camera3D.new()
	camera.fov = 55.0
	root.add_child(camera)
	var centre: Vector3 = crossing.centre
	var eye: Vector3 = centre + (crossing.right as Vector3) * OVERVIEW.x + Vector3.UP * OVERVIEW.y \
		+ (crossing.forward as Vector3) * OVERVIEW.z
	camera.look_at_from_position(eye, centre + (crossing.right as Vector3) * 2.0)
	camera.make_current()
	await _seconds(0.5)
	await _shot("crossing_overview_night", pedestrian)
	var ambient := environment.ambient_light_energy
	var fog := environment.fog_enabled
	environment.ambient_light_energy = 6.0
	environment.fog_enabled = false
	await _seconds(0.5)
	await _shot("crossing_overview_debug_light", pedestrian)
	environment.ambient_light_energy = ambient
	environment.fog_enabled = fog
	_van.call("get_camera").make_current()
	camera.queue_free()


func _side_sequence(pedestrian: Node3D, struck_frame: int) -> void:
	var holder := _app.get_node("IndustrialLoop").find_children("*", "WorldEnvironment", false,
		false)[0] as WorldEnvironment
	var environment := holder.environment
	var ambient := environment.ambient_light_energy
	var fog := environment.fog_enabled
	environment.ambient_light_energy = 6.0
	environment.fog_enabled = false
	var camera := Camera3D.new()
	camera.fov = 50.0
	root.add_child(camera)
	var at: Vector3 = pedestrian.call("hips_position")
	var aim := _van.to_local(at + _van.global_basis * Vector3(0.0, -0.4, -2.5))
	camera.make_current()
	for stop in SEQUENCE:
		while Engine.get_physics_frames() - struck_frame < stop:
			await physics_frame
		camera.look_at_from_position(_van.to_global(SIDE_VIEW), _van.to_global(aim))
		await _shot("thrown_%03d_ms_debug_light" % roundi((Engine.get_physics_frames()
			- struck_frame) * 1000.0 / 60.0), pedestrian)
	environment.ambient_light_energy = ambient
	environment.fog_enabled = fog
	_van.call("get_camera").make_current()
	camera.queue_free()


func _debug_look(pedestrian: Node3D) -> void:
	var holder := _app.get_node("IndustrialLoop").find_children("*", "WorldEnvironment", false,
		false)[0] as WorldEnvironment
	var environment := holder.environment
	var camera := Camera3D.new()
	camera.fov = 45.0
	root.add_child(camera)
	var side := _van.global_basis.x
	var hips: Vector3 = pedestrian.call("hips_position")
	camera.look_at_from_position(hips + side * 4.0 + Vector3.UP * 2.2, hips + Vector3.UP * 0.1)
	camera.make_current()
	await _seconds(0.5)
	await _shot("on_the_road_night", pedestrian)
	var ambient := environment.ambient_light_energy
	var fog := environment.fog_enabled
	environment.ambient_light_energy = 6.0
	environment.fog_enabled = false
	await _seconds(0.5)
	await _shot("on_the_road_debug_light", pedestrian)
	environment.ambient_light_energy = ambient
	environment.fog_enabled = fog
	_van.call("get_camera").make_current()
	camera.queue_free()


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _shot(stem: String, pedestrian: Node3D) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var local := _van.to_local(pedestrian.call("hips_position"))
	_report.append("saved %s.png: van %.1f m/s, pedestrian %.1f m ahead and %.1f m right, "
		% [stem, float(_van.get("speed")), -local.z, local.x]
		+ "windshield brightness %.1f, eye %.2f m forward, objective %s" % [_luma(image, WINDSHIELD),
		Presentation.EYE.z - (_presentation.get("_look") as Node3D).position.z,
		(_app.get_node("DrivingHud").get("_objective") as Label).text])


func _luma(image: Image, area: Rect2i) -> float:
	var total := 0.0
	var count := 0
	for y in range(area.position.y, area.end.y, 4):
		for x in range(area.position.x, area.end.x, 4):
			var colour := image.get_pixel(x, y)
			total += 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
			count += 1
	return total * 255.0 / maxf(1.0, float(count))


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
