extends SceneTree

const SIDE_LOOK := Vector2(0.0, 0.75)
const OPACITIES: Array[float] = [0.6, 0.45, 0.35, 0.25]

var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-window-fog-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var folder := _output_folder("evidence/phase_1/window_fog")
	DirAccess.make_dir_recursive_absolute(folder)
	var presentation := app.get_node("FreightVan/VanPresentation")
	var overlays: Array = presentation.get("fog_overlays")
	var heavy: ShaderMaterial = overlays[1].material_override
	presentation.set("_look_target", SIDE_LOOK)
	for frame in range(90):
		await process_frame
	for opacity in OPACITIES:
		heavy.set_shader_parameter("fog_opacity", opacity)
		for frame in range(10):
			await process_frame
		await RenderingServer.frame_post_draw
		var name := "driver_window_opacity_%.2f.png" % opacity
		root.get_texture().get_image().save_png(folder.path_join(name))
		_report.append("saved %s (runtime only; heavy_fog.tres unchanged)" % name)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(folder.path_join("window_fog_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
