extends SceneTree

const TRIGGER_SIDE := 966
const WAIT_AT := 1000
const RUN_FROM := 1020
const PULL_OVER := 1.35
const DEPOT := Vector3(-28.0, 0.1, 93.0)
const WINDSHIELD := Rect2i(160, 60, 960, 380)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-collision-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/collision/step4")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_route.set("stage", 4)
	_place(TRIGGER_SIDE, 0.0)
	while not is_instance_valid(_route.get("oncoming")):
		await physics_frame
	var oncoming: Node3D = _route.get("oncoming")
	_place(WAIT_AT, PULL_OVER)
	_hold("brake", true)
	while not oncoming.get("_passed"):
		await physics_frame
	_hold("brake", false)
	_place(RUN_FROM, PULL_OVER)
	_hold("accelerate", true)
	while not is_instance_valid(_route.get("pedestrian")):
		await physics_frame
	var pedestrian: Node3D = _route.get("pedestrian")
	await _shot("he_steps_out", pedestrian)
	while _van.to_local(pedestrian.global_position).z < -4.2 and not pedestrian.get("hit"):
		await physics_frame
	await _shot("too_late_to_stop", pedestrian)
	while not pedestrian.get("hit"):
		await physics_frame
	_hold("accelerate", false)
	await _shot("impact", pedestrian)
	await _seconds(0.6)
	await _shot("skid", pedestrian)
	while absf(float(_van.get("speed"))) > 0.05:
		await physics_frame
	await _seconds(1.5)
	await _shot("he_lies_in_the_beams", pedestrian)
	while not _route.get("fleeing"):
		await physics_frame
	await _shot("drive_objective", pedestrian)
	await _debug_look(pedestrian)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DEPOT))
	_hold("brake", true)
	while not _route.get("complete"):
		await physics_frame
	_hold("brake", false)
	var driver: CharacterBody3D = _app.get("driver")
	while not driver.visible:
		await process_frame
	while float(driver.call("clip_time")) < 3.2:
		await process_frame
	await _shot("getting_out_at_the_depot", pedestrian)
	while float(driver.call("clip_time")) < 4.2:
		await process_frame
	await _shot("shutting_the_door", pedestrian)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("collision_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _debug_look(pedestrian: Node3D) -> void:
	var holder := _app.get_node("IndustrialLoop").find_children("*", "WorldEnvironment", false,
		false)[0] as WorldEnvironment
	var environment := holder.environment
	var camera := Camera3D.new()
	camera.fov = 45.0
	root.add_child(camera)
	var side := _van.global_basis.x
	camera.look_at_from_position(pedestrian.global_position + side * 4.0 + Vector3.UP * 2.2,
		pedestrian.global_position + Vector3.UP * 0.3)
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
	var local := _van.to_local(pedestrian.global_position)
	_report.append("saved %s.png: van %.1f m/s, pedestrian %.1f m ahead and %.1f m right, "
		% [stem, float(_van.get("speed")), -local.z, local.x]
		+ "windshield brightness %.1f, objective %s" % [_luma(image, WINDSHIELD),
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
