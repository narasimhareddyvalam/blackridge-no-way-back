extends SceneTree

const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const PROGRESS := "user://progress.cfg"
const SETTINGS := "user://settings.cfg"
const DRAWS := 8


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var args := OS.get_cmdline_user_args()
	_folder = args[0] if not args.is_empty() else "evidence/phase_1/menu/run34"
	DirAccess.make_dir_recursive_absolute(_folder)
	if not OS.get_environment("HOME").ends_with("/.scratch-home"):
		print("Run with HOME pointing at .scratch-home, so the real save folder is never touched")
		quit(1)
		return
	_clear_user()
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	change_scene_to_packed(load("res://app/first_drive.tscn") as PackedScene)
	await _frames(4)
	_app = current_scene
	await _seconds(2.5)
	await _save("title_new_game")
	await _press("ui_down")
	await _press("ui_accept")
	await _seconds(0.6)
	await _save("settings_audio")
	await _press("ui_up")
	await _press("ui_right")
	await _seconds(0.4)
	await _save("settings_controls")
	await _press("pause")
	await _press("ui_down")
	await _press("ui_accept")
	await _seconds(0.6)
	await _save("credits")
	await _press("pause")
	await _press("ui_up")
	await _press("ui_up")
	await _press("ui_accept")
	await _seconds(3.0)
	await _press("pause")
	await _seconds(0.6)
	await _save("pause_on_foot")
	await _press("pause")
	_app.call("_close_run_sheet")
	_app.call("_enter_van")
	var van: CharacterBody3D = _app.get_node("FreightVan")
	var route: Node = _app.get_node("DrivingTrial")
	for index in [0, 1]:
		var target: Vector3 = Mission.TARGETS[index]
		van.call("recover", Transform3D(Basis(Vector3.UP, Mission.HEADINGS[index]),
			target + Vector3.UP * 0.1))
		route.call("_process", 0.2)
	await _seconds(2.0)
	await _press("pause")
	await _seconds(0.6)
	await _save("pause_in_van")
	for step in range(3):
		await _press("ui_down")
	await _press("ui_accept")
	await _seconds(0.4)
	await _save("confirm_main_menu")
	await _press("ui_left")
	await _press("ui_accept")
	await _seconds(2.5)
	await _save("title_continue")
	await _press("ui_down")
	await _press("ui_accept")
	await _seconds(0.4)
	await _save("confirm_new_game")
	await _press("ui_accept")
	await _press("ui_up")
	await _press("ui_accept")
	await _seconds(3.0)
	await _save("continued_in_van")
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("menu_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	_clear_user()
	quit(0)


func _press(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _frames(3)


func _save(stem: String) -> void:
	for frame in range(DRAWS):
		RenderingServer.force_draw(false, 1.0 / 60.0)
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	var menu: Control = _app.get_node("DrivingHud").get("menu")
	var focus := root.gui_get_focus_owner()
	_report.append("saved %s: screen \"%s\", focus %s" % [stem, menu.call("screen"),
		focus.name if focus != null else "(nothing)"])


func _clear_user() -> void:
	for path in [PROGRESS, SETTINGS]:
		for suffix in ["", ".tmp", ".corrupt"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame
