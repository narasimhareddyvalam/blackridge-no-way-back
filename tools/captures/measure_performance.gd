extends SceneTree

const WARM_UP_SECONDS := 4.0
const SAMPLE_SECONDS := 5.0

var _report := PackedStringArray()


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-performance-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	app.get_node("FreightVan/VanPresentation").set("_look_target", Vector2.ZERO)
	var folder := _output_folder("evidence/phase_1/performance")
	DirAccess.make_dir_recursive_absolute(folder)
	_report.append("renderer %s, 3D scaling mode %d at %.2f, window %s, vsync off" % [
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		root.scaling_3d_mode, root.scaling_3d_scale, str(root.get_visible_rect().size)])
	await _seconds(WARM_UP_SECONDS)
	await _measure("parked")
	_hold("accelerate", true)
	await _seconds(1.0)
	await _measure("driving")
	_hold("accelerate", false)
	_hold("brake", true)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(folder.path_join("performance.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _measure(label: String) -> void:
	var times := PackedFloat32Array()
	var draws := 0
	var primitives := 0
	var start := Time.get_ticks_usec()
	var last := start
	while last - start < int(SAMPLE_SECONDS * 1000000.0):
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		draws += RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var count := times.size()
	var sorted := times.duplicate()
	sorted.sort()
	var seconds := (last - start) / 1000000.0
	var line := "%-8s FPS %5.1f | frame median %6.2f ms, slowest 5%% %6.2f ms" % [
		label, count / seconds, sorted[count / 2], sorted[mini(count - 1, int(count * 0.95))]]
	_report.append(line + " | %d draws, %.2fM triangles per frame" % [
		draws / count, primitives / float(count) / 1000000.0])


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
