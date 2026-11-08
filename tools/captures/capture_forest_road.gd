extends SceneTree

const WINDSHIELD := Rect2i(160, 60, 960, 420)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-forest-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/forest_road")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_report.append("renderer=%s" % RenderingServer.get_current_rendering_method())
	var forest: Node = _app.get_node("IndustrialLoop").get("forest")
	_report.append("trees=%d saplings=%d colliders=%d" % [forest.get("tree_count"),
		forest.get("sapling_count"), forest.get("collider_count")])
	_report.append("forest floor props=%d" % _app.get_node("IndustrialLoop").get("forest_floor")
		.get("prop_count"))
	await _park_wipers()
	_app.get_node("FreightVan/VanPresentation").set("_look_target", Vector2.ZERO)
	await _frames(40)
	var road := _road_pixels()
	_report.append("road sample points visible: %d" % road.size())
	var lit := await _save("driver_headlights_on.png")
	await _press("headlights")
	await _press("headlights")
	await _frames(30)
	var dark := await _save("driver_headlights_off.png")
	var road_on := _mean_luma(lit, road)
	var road_off := _mean_luma(dark, road)
	_report.append("road on %.1f off %.1f ratio %.2f" % [road_on, road_off,
		road_on / maxf(road_off, 0.01)])
	_report.append("white-out in windshield: on %.2f%% off %.2f%%" % [
		_white_share(lit, WINDSHIELD), _white_share(dark, WINDSHIELD)])
	await _press("headlights")
	await _frames(30)
	await _from_camera(Vector3(0.0, 3.6, 9.0), Vector3(0.0, 1.2, -12.0), "chase_headlights_on.png")
	await _from_camera(Vector3(0.0, 24.0, 14.0), Vector3(0.0, 0.0, -45.0), "overview.png")
	await _from_camera(Vector3(3.3, 1.5, -6.0), Vector3(1.8, 0.4, -26.0), "roadside_low.png")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("forest_road_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _park_wipers() -> void:
	var park: float = _van.get_script().get_script_constant_map()["WIPER_PARK"]
	await _press("wipers")
	await _frames(10)
	await _press("wipers")
	for frame in range(600):
		await physics_frame
		if _van.get("wiper_setting") == 0 and is_equal_approx(_van.get("wiper_angle"), park):
			break
	await _frames(20)
	_report.append("wipers parked: setting %d angle %.2f" % [_van.get("wiper_setting"),
		_van.get("wiper_angle")])


func _from_camera(offset: Vector3, look_offset: Vector3, file_name: String) -> void:
	var camera := Camera3D.new()
	camera.far = 400.0
	camera.fov = 60.0
	root.add_child(camera)
	var basis := _van.global_transform.basis
	camera.global_position = _van.global_position + basis * offset
	camera.look_at(_van.global_position + basis * look_offset, Vector3.UP)
	camera.make_current()
	await _frames(20)
	await _save(file_name)
	camera.queue_free()
	_van.call("get_camera").make_current()
	await _frames(5)


func _save(file_name: String) -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(file_name))
	_report.append("saved %s %dx%d" % [file_name, image.get_width(), image.get_height()])
	return image


func _road_pixels() -> Array[Vector2i]:
	var camera: Camera3D = _van.call("get_camera")
	var basis := _van.global_transform.basis
	var size := root.get_visible_rect().size
	var result: Array[Vector2i] = []
	for distance in [10.0, 13.0, 16.0, 20.0, 25.0, 30.0, 38.0, 46.0]:
		for lateral in [-1.4, -0.7, 0.0, 0.7, 1.4]:
			var point := _van.global_position + basis * Vector3(lateral, 0.0, -distance)
			point.y = 0.03
			if camera.is_position_behind(point):
				continue
			var screen := camera.unproject_position(point)
			if screen.x >= 0 and screen.y >= 0 and screen.x < size.x and screen.y < size.y:
				result.append(Vector2i(screen))
	return result


func _mean_luma(image: Image, pixels: Array[Vector2i]) -> float:
	var total := 0.0
	for at in pixels:
		total += _luma_at(image, at)
	return total / maxf(pixels.size(), 1.0)


func _white_share(image: Image, region: Rect2i) -> float:
	var white := 0
	var count := 0
	for y in range(region.position.y, region.end.y, 2):
		for x in range(region.position.x, region.end.x, 2):
			count += 1
			if _luma_at(image, Vector2i(x, y)) >= 250.0:
				white += 1
	return 100.0 * white / maxf(count, 1.0)


func _luma_at(image: Image, at: Vector2i) -> float:
	var pixel := image.get_pixelv(at)
	return 255.0 * (0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b)


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


func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
