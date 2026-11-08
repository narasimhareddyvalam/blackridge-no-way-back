extends SceneTree

const FRAMES_PER_STROKE := 8
const DRIVE_SPEED := 13.5
const GLASS_CROP := Rect2i(0, 0, 1280, 420)

var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _folder: String
var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-wiper-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/wipers")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_presentation.set("_look_target", Vector2(-0.05, 0.0))
	_hold("brake", true)
	await _seconds(3.0)
	await _stroke("parked")
	_hold("brake", false)
	_hold("accelerate", true)
	while absf(float(_van.get("actual_speed"))) < DRIVE_SPEED:
		await process_frame
	_hold("accelerate", false)
	await _stroke("driving")
	_hold("brake", true)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("wiper_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _stroke(label: String) -> void:
	var last := _phase()
	while true:
		await process_frame
		var now := _phase()
		if now < last:
			break
		last = now
	for frame in range(FRAMES_PER_STROKE):
		var target := float(frame) / FRAMES_PER_STROKE
		while _phase() < target and _phase() < 0.99:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image().get_region(GLASS_CROP)
		var stem := "%s_%02d" % [label, frame]
		image.save_png(_folder.path_join(stem + ".png"))
		_report.append("%s: phase %.2f, wiper angle %.2f rad, speed %.1f m/s, blade 2 cm = %.1f px"
			% [stem, _phase(), float(_van.get("wiper_angle")),
			absf(float(_van.get("actual_speed"))), _blade_pixels()])


func _phase() -> float:
	return fposmod(float(_van.call("wiper_cycles")), 1.0)


func _blade_pixels() -> float:
	var blades: Array = _presentation.get("_blades")
	var camera: Camera3D = _presentation.get("driving_camera")
	if blades.is_empty() or camera == null:
		return 0.0
	var blade: Node3D = blades[0]
	var left := camera.unproject_position(blade.to_global(Vector3(-0.01, 0.0, 0.0)))
	var right := camera.unproject_position(blade.to_global(Vector3(0.01, 0.0, 0.0)))
	return left.distance_to(right)


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
