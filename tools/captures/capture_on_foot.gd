extends SceneTree

const SIDE_VIEW := Vector3(-5.2, 1.7, -2.6)
const SIDE_TARGET := Vector3(-1.4, 1.3, -0.6)
const CLIP_SHOTS := {1.05: "reach_for_handle", 1.6: "door_open"}


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-on-foot-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.get_node("DrivingHud").emit_signal("resume_requested")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/characters/step2")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await _seconds(2.0)
	await _shot("start_on_foot")
	_hold("accelerate", true)
	await _seconds(0.6)
	await _shot("walking_to_the_van")
	_hold("accelerate", false)
	await _seconds(0.5)
	await _press("interact")
	var side := Camera3D.new()
	side.fov = 50.0
	root.add_child(side)
	for moment: float in CLIP_SHOTS:
		while _driver.call("clip_time") < moment or not _clip_playing():
			await process_frame
		await _shot(CLIP_SHOTS[moment])
		if moment == 1.6:
			var own := root.get_viewport().get_camera_3d()
			side.look_at_from_position(_van.to_global(SIDE_VIEW), _van.to_global(SIDE_TARGET))
			side.make_current()
			await _shot("door_open_side")
			own.make_current()
	while not _van.get("occupied"):
		await process_frame
	await _seconds(0.45)
	await _shot("in_the_cab_engine_off")
	while float(_van.call("ignition_sweep")) < 0.9:
		await process_frame
	await _shot("ignition_gauge_sweep")
	while not _van.get("headlights_on"):
		await process_frame
	await _seconds(1.0)
	await _shot("low_beams_and_wipers_on")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("on_foot_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _clip_playing() -> bool:
	var ethan := _driver.get_node("Ethan")
	var player := ethan.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	return player.current_animation == "EnterVan"


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	_report.append("saved %s.png: mean brightness %.1f (0-255), engine %s, lights %s, door %.2f"
		% [stem, _mean(image), str(_van.get("engine_on")), str(_van.get("headlights_on")),
		float(_van.get("driver_door"))])


func _mean(image: Image) -> float:
	var small := image.duplicate() as Image
	small.resize(160, 100, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in range(small.get_height()):
		for x in range(small.get_width()):
			var colour := small.get_pixel(x, y)
			total += 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
	return total * 255.0 / float(small.get_width() * small.get_height())


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
