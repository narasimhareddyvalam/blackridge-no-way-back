extends SceneTree

const WINDSHIELD := Rect2i(160, 60, 960, 420)
const NEAR := Vector2(10.0, 46.0)
const FAR := Vector2(50.0, 100.0)
const SAMPLE_SECONDS := 3.0


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _road: RefCounted
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-beam-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/beams")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_road = _app.get_node("IndustrialLoop").get("road")
	_van.get_node("VanPresentation").set("_look_target", Vector2.ZERO)
	await _park_wipers()
	await _frames(40)
	var near := _road_pixels(NEAR)
	var far := _road_pixels(FAR)
	_report.append("road samples: near %d (%d-%d m), far %d (%d-%d m)" % [near.size(), NEAR.x,
		NEAR.y, far.size(), FAR.x, FAR.y])
	await _state("low_beams", near, far)
	await _press("headlights")
	await _state("high_beams", near, far)
	await _press("headlights")
	await _state("lights_off", near, far)
	await _press("headlights")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("beam_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _state(stem: String, near: Array[Vector2i], far: Array[Vector2i]) -> void:
	await _frames(30)
	var frames := 0
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < int(SAMPLE_SECONDS * 1000000.0):
		await process_frame
		frames += 1
	var fps := frames / ((Time.get_ticks_usec() - start) / 1000000.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	_report.append("%-11s road near %5.1f, far %5.1f | white-out %.2f%% | %.1f FPS | lights %s, high %s"
		% [stem, _mean_luma(image, near), _mean_luma(image, far), _white_share(image),
		fps, str(_van.get("headlights_on")), str(_van.get("high_beams"))])


func _park_wipers() -> void:
	var park: float = _van.get_script().get_script_constant_map()["WIPER_PARK"]
	await _press("wipers")
	await _frames(10)
	await _press("wipers")
	for frame in range(600):
		await physics_frame
		if _van.get("wiper_setting") == 0 and is_equal_approx(_van.get("wiper_angle"), park):
			break


func _road_pixels(band: Vector2) -> Array[Vector2i]:
	var camera: Camera3D = _van.call("get_camera")
	var size := root.get_visible_rect().size
	var points: PackedVector3Array = _road.points
	var start := _nearest(points, _van.global_position)
	var result: Array[Vector2i] = []
	var travelled := 0.0
	var index := start
	while travelled < band.y and index < start + 200:
		var here := points[index % points.size()]
		var ahead := points[(index + 1) % points.size()] - here
		travelled += Vector2(ahead.x, ahead.z).length()
		index += 1
		if travelled < band.x:
			continue
		var right := Vector3(ahead.x, 0.0, ahead.z).normalized().cross(Vector3.UP)
		for lateral: float in [-1.4, -0.7, 0.0, 0.7, 1.4]:
			var point := here + right * lateral + Vector3.UP * 0.03
			if camera.is_position_behind(point):
				continue
			var screen := camera.unproject_position(point)
			if screen.x >= 0 and screen.y >= 0 and screen.x < size.x and screen.y < size.y:
				result.append(Vector2i(screen))
	return result


func _nearest(points: PackedVector3Array, at: Vector3) -> int:
	var best := 0
	for index in range(points.size()):
		if Vector2(points[index].x - at.x, points[index].z - at.z).length_squared() < Vector2(
				points[best].x - at.x, points[best].z - at.z).length_squared():
			best = index
	return best


func _mean_luma(image: Image, pixels: Array[Vector2i]) -> float:
	var total := 0.0
	for at in pixels:
		total += _luma_at(image, at)
	return total / maxf(pixels.size(), 1.0)


func _white_share(image: Image) -> float:
	var white := 0
	var count := 0
	for y in range(WINDSHIELD.position.y, WINDSHIELD.end.y, 2):
		for x in range(WINDSHIELD.position.x, WINDSHIELD.end.x, 2):
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
