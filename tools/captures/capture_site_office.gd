extends SceneTree

const ROAD_VIEW := [Vector3(3.0, 1.75, 11.0), Vector3(0.0, 1.6, 0.0), 55.0]
const DOOR_VIEW := [Vector3(0.7, 1.7, 5.2), Vector3(-0.9, 1.75, 1.8), 45.0]
const SIDE_VIEW := [Vector3(8.5, 2.0, 6.5), Vector3(0.5, 1.8, 0.0), 50.0]
const VAN_VIEW := Vector3(-1.5, 2.1, 4.5)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _office: Node3D
var _camera: Camera3D
var _environment: Environment
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-office-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.get_node("DrivingHud").emit_signal("resume_requested")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/start/run24_office")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	var world: Node3D = _app.get_node("IndustrialLoop")
	_office = world.get_node("SiteOffice")
	var holder := world.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
	_environment = holder.environment
	_camera = Camera3D.new()
	_camera.far = 400.0
	root.add_child(_camera)
	await _seconds(2.0)
	await _view("office_from_the_road", ROAD_VIEW)
	await _view("door_board_and_clipboard", DOOR_VIEW)
	await _view("office_side_and_floodlight", SIDE_VIEW)
	await _floodlight()
	var ambient := _environment.ambient_light_energy
	var fog := _environment.fog_enabled
	_environment.ambient_light_energy = 6.0
	_environment.fog_enabled = false
	await _view("office_debug_light", ROAD_VIEW)
	_environment.ambient_light_energy = ambient
	_environment.fog_enabled = fog
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("site_office_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _view(stem: String, view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(_office.to_global(view[0]), _office.to_global(view[1]))
	_camera.make_current()
	await _seconds(0.6)
	await _shot(stem)


func _floodlight() -> void:
	var target := _van.global_position + Vector3.UP * 0.9
	_camera.fov = 50.0
	_camera.look_at_from_position(_office.to_global(VAN_VIEW), target)
	_camera.make_current()
	var flood := _office.get_node("FloodLight") as SpotLight3D
	await _seconds(0.6)
	var lit := _van_brightness(await _shot("floodlight_on_the_van"))
	flood.visible = false
	await _seconds(0.4)
	var dark := _van_brightness(await _shot("van_without_the_floodlight"))
	flood.visible = true
	_report.append("van brightness: %.1f with the floodlight, %.1f without (%.1fx)"
		% [lit, dark, lit / maxf(dark, 0.01)])


func _van_brightness(image: Image) -> float:
	var area := _van_area(image.get_size())
	var total := 0.0
	var count := 0
	for y in range(area.position.y, area.end.y, 2):
		for x in range(area.position.x, area.end.x, 2):
			var pixel := image.get_pixel(x, y)
			total += (pixel.r + pixel.g + pixel.b) / 3.0 * 255.0
			count += 1
	_report.append("van area %s on screen" % str(area))
	return total / maxf(count, 1)


func _shot(stem: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var white := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			if pixel.r > 0.995 and pixel.g > 0.995 and pixel.b > 0.995:
				white += 1
	var samples := (image.get_width() / 4) * (image.get_height() / 4)
	_report.append("saved %s.png: pure white %.2f%%" % [stem, 100.0 * white / samples])
	return image


func _van_area(size: Vector2i) -> Rect2i:
	var bounds := Rect2(Vector2(INF, INF), Vector2.ZERO)
	var first := true
	for x in [-1.0, 1.0]:
		for y in [0.2, 2.0]:
			for z in [-2.6, 2.6]:
				var corner := _van.to_global(Vector3(x, y, z))
				if _camera.is_position_behind(corner):
					continue
				var at := _camera.unproject_position(corner)
				bounds = Rect2(at, Vector2.ZERO) if first else bounds.expand(at)
				first = false
	var area := Rect2i(bounds).intersection(Rect2i(Vector2i.ZERO, size))
	return area if area.has_area() else Rect2i(0, 0, 1, 1)


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
