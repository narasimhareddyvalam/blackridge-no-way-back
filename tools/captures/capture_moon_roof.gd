extends SceneTree

const DRIVE_SPEED := 13.5
const UP := Vector2(1.0, 0.0)
const UP_RIGHT := Vector2(0.95, -0.45)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-moon-roof-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/moon_roof")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_hold("brake", true)
	await _seconds(2.0)
	await _shot("parked_look_up", UP)
	await _shot("parked_look_up_right", UP_RIGHT)
	_hold("brake", false)
	_hold("accelerate", true)
	while absf(float(_van.get("actual_speed"))) < DRIVE_SPEED:
		await process_frame
	_hold("accelerate", false)
	await _shot("driving_look_up_right", UP_RIGHT, 1.2)
	_hold("brake", true)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("moon_roof_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _shot(stem: String, look: Vector2, settle: float = 2.0) -> void:
	_presentation.set("_look_target", look)
	await _seconds(settle)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	var rain := (_presentation.get("roof_rain") as MeshInstance3D).material_override as ShaderMaterial
	_report.append("saved %s.png: look %s, speed %.1f m/s, roof water flows %s" % [stem, str(look),
		absf(float(_van.get("actual_speed"))), str(rain.get_shader_parameter("flow_dir"))])


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
