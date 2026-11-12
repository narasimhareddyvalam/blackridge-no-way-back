extends SceneTree
## The depot's stills (step 2c revised, parts 1 and 2), in a 1280x800 window on Mission 2's start
## save: the driver's seat at the gate's stop line and in the court, the docks, the views into the
## open docks 5 and 9, the office and the east side at eye height, the depot from above at night,
## then the same view and a plan from straight above in a debug light (ambient 6, no fog), which
## is not the game's look. Real keys and clicks are swallowed. Usage, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_depot.gd \
##     -- <absolute output folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const STOP_LINE_VAN := Vector3(-71.0, 0.1, 60.9)
const COURT_VAN := Vector3(-62.0, 0.1, 42.0)
const COURT_HEADING := 0.15
const DOCKS := [Vector3(-58.0, 1.7, 36.0), Vector3(-62.0, 3.0, 20.0), 60.0]
const DOCK_5 := [Vector3(-65.5, 1.7, 29.0), Vector3(-63.6, 2.4, 14.0), 50.0]
const BAY_9 := [Vector3(-49.5, 1.7, 28.0), Vector3(-47.4, 2.3, 14.0), 50.0]
const OFFICE := [Vector3(-80.0, 1.7, 36.0), Vector3(-88.0, 3.0, 20.0), 60.0]
const EAST_SIDE := [Vector3(-33.0, 1.7, 45.0), Vector3(-33.0, 4.0, -5.0), 60.0]
const ABOVE := [Vector3(-66.0, 55.0, 95.0), Vector3(-60.0, 0.0, 22.0), 50.0]
const PLAN_CENTRE := Vector3(-59.0, 120.0, 21.0)
const PLAN_HEIGHT := 76.0


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _camera: Camera3D
var _environment: Environment
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_depot_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	await process_frame
	_app.call("_begin")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() \
		else ProjectSettings.globalize_path("res://").path_join("../captures/transfer_shed/2c_p2")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	var world: Node3D = _app.get_node("IndustrialLoop")
	var holder := world.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
	_environment = holder.environment
	_camera = Camera3D.new()
	_camera.far = 400.0
	root.add_child(_camera)
	await _seconds(1.0)
	if not bool(_van.get("headlights_on")):
		_send("headlights")
	if int(_van.get("wiper_setting")) == 0:
		_send("wipers")
	await _driver_view("1_driver_at_the_stop_line", STOP_LINE_VAN, 0.0)
	await _driver_view("2_driver_in_the_court", COURT_VAN, COURT_HEADING)
	await _view("3_docks_at_eye_height", DOCKS)
	await _view("3b_into_dock_5", DOCK_5)
	await _view("3c_into_bay_9", BAY_9)
	await _view("4_office_and_walkway", OFFICE)
	await _view("5_east_side_and_cut_walls", EAST_SIDE)
	await _view("6_depot_from_above", ABOVE)
	var ambient := _environment.ambient_light_energy
	var fog := _environment.fog_enabled
	_environment.ambient_light_energy = 6.0
	_environment.fog_enabled = false
	await _view("7_depot_from_above_debug_light_not_the_game", ABOVE)
	await _plan("8_plan_from_above_debug_light_not_the_game")
	_environment.ambient_light_energy = ambient
	_environment.fog_enabled = fog
	var text := "\n".join(_report)
	print(text)
	var notes := FileAccess.open(_folder.path_join("depot_stills.txt"), FileAccess.WRITE)
	notes.store_string(text + "\n")
	notes.close()
	quit(0)


func _driver_view(stem: String, at: Vector3, heading: float) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, heading), at))
	var presentation := _van.get_node("VanPresentation")
	(presentation.get("driving_camera") as Camera3D).make_current()
	await _seconds(2.5)
	_report.append("%s: the van at %s, heading %.2f rad, headlights %s, wipers %d" % [stem,
		str(_van.global_position.snapped(Vector3.ONE * 0.01)), heading,
		_van.get("headlights_on"), int(_van.get("wiper_setting"))])
	await _shot(stem)


func _view(stem: String, view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()
	await _seconds(1.5)
	_report.append("%s: camera at %s looking at %s, fov %.0f" % [stem, str(view[0]),
		str(view[1]), view[2]])
	await _shot(stem)


func _plan(stem: String) -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = PLAN_HEIGHT
	_camera.look_at_from_position(PLAN_CENTRE, PLAN_CENTRE + Vector3.DOWN, Vector3.FORWARD)
	_camera.make_current()
	await _seconds(1.5)
	_report.append("%s: straight down from %s, %.0f m from top to bottom, north up" % [stem,
		str(PLAN_CENTRE), PLAN_HEIGHT])
	await _shot(stem)
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var dark := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			if image.get_pixel(x, y).get_luminance() < 0.02:
				dark += 1
	var samples := (image.get_width() / 4) * (image.get_height() / 4)
	_report.append("  saved %s.png (%dx%d), near black %.0f%%" % [stem, image.get_width(),
		image.get_height(), 100.0 * dark / samples])


func _send(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	_report.append("%s pressed and released" % action)


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame
