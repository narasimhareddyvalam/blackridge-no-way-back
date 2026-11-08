extends SceneTree

const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const PROGRESS := "user://progress.cfg"
const SETTINGS := "user://settings.cfg"
const OLD_WORDS: Array[String] = ["PROTOTYPE", "prototype", "freight loop", "industrial loop",
	"Begin / continue drive", "Drive again", "First drive"]
const KEYS: Array[String] = ["W / S", "A / D", "SPACE", "Z / C", "J / K", "MOUSE", "SHIFT", "ESC"]
const CREDITED: Array[String] = ["NRVALAM WORKS", "Max", "CC BY 4.0", "Mixamo", "Poly Haven",
	"Alex Murias", "Godot Engine", "MIT"]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _hud: CanvasLayer
var _route: Node
var _van: CharacterBody3D
var _menu: Control
var _quits: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(110.0, true, false, true).timeout.connect(_timeout)
	if not _in_scratch_home():
		_check(false, "The menus are checked only in scripts/run-test.sh's scratch home, so the "
			+ "real save folder is never touched")
		_finish()
		return
	_clear_user()
	await _launch()
	if _menu == null:
		_check(false, "The HUD has a front menu")
		_finish()
		return
	_check_title_at_launch()
	_check_names()
	_check_wording()
	await _check_escape_on_title()
	await _check_settings()
	await _check_credits()
	await _check_new_game()
	await _check_pause()
	await _save_at_viewpoint()
	await _check_quit_to_title()
	await _check_new_game_asks()
	await _check_continue()
	await _check_recover()
	await _check_quit()
	_clear_user()
	_finish()


func _check_title_at_launch() -> void:
	var camera: Camera3D = _app.get("title_camera")
	var shot: Variant = (Mission as Script).get_script_constant_map().get("TITLE_EYE")
	var eye: Vector3 = Mission.START * (shot as Vector3) if shot is Vector3 else Vector3.INF
	var at_start := _van.global_position.distance_to(Mission.START.origin)
	var lamps: Array = _van.get_node("VanPresentation").get("_headlights")
	var lit := not lamps.is_empty()
	for lamp: Light3D in lamps:
		lit = lit and lamp.visible
	_check(_screen() == "title" and camera != null and root.get_camera_3d() == camera
		and camera.global_position.distance_to(eye) < 0.01 and at_start < 0.05 and lit
		and _shown("BarTop") and _shown("BarBottom") and not _shown("Blur") and paused,
		("At launch the title screen shows the live scene of the saved mission, Night Freight: "
		+ "the van on the forecourt with its low beams on, seen through the title camera, "
		+ "between black bars (van %.2f m from its spot)") % at_start)
	_check(_focus() == "NewGame" and not _shown("Continue"),
		"With no save, focus starts on New game and Continue is not offered (focus: %s)"
		% _focus())
	var audio: Node = _app.get("_audio")
	var rain: AudioStreamPlayer = audio.get("_rain")
	var music: AudioStreamPlayer = audio.get("_music")
	_check(rain.playing and music.playing
		and rain.process_mode == Node.PROCESS_MODE_ALWAYS
		and music.process_mode == Node.PROCESS_MODE_ALWAYS,
		"While the title waits, the rain and the music keep playing")


func _check_names() -> void:
	var named := 0
	var unnamed: Array[String] = []
	for node in _menu.find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode != Control.FOCUS_ALL:
			continue
		if String(control.get("accessibility_name")).strip_edges().is_empty():
			unnamed.append(String(control.name))
		else:
			named += 1
	_check(unnamed.is_empty() and named >= 18,
		"Every control a player can reach has a name a screen reader can read (%d named; "
		% named + "unnamed: %s)" % ", ".join(unnamed))


func _check_wording() -> void:
	var found: Array[String] = []
	for node in _hud.find_children("*", "Control", true, false):
		var words := ""
		if node is Label or node is Button:
			words = String(node.get("text"))
		elif node is RichTextLabel:
			words = (node as RichTextLabel).get_parsed_text()
		for old in OLD_WORDS:
			if words.contains(old):
				found.append("\"%s\" in %s" % [old, node.name])
	var objective: String = (_hud.get("_detail") as Label).text
	for old in OLD_WORDS:
		if objective.contains(old):
			found.append("\"%s\" in the objective" % old)
	_check(found.is_empty(), "No prototype wording is left on any screen (%s)"
		% (", ".join(found) if not found.is_empty() else "none found"))


func _check_escape_on_title() -> void:
	await _key(KEY_ESCAPE)
	_check(paused and _screen() == "title" and _focus() == "NewGame"
		and root.get_camera_3d() == _app.get("title_camera"),
		"Esc on the title does nothing: the game stays on the title, paused, with focus kept")


func _check_settings() -> void:
	await _key(KEY_DOWN)
	var on_settings := _focus()
	await _key(KEY_ENTER)
	var master: HSlider = _menu.find_child("Master", true, false)
	var before := master.value if master != null else -1.0
	var opened := _screen() == "settings" and _focus() == "Master" and _shown("Blur")
	await _key(KEY_RIGHT)
	var raised := master != null and is_equal_approx(master.value, before + 5.0)
	_check(on_settings == "TitleSettings" and opened and raised,
		"Down and Enter open Settings over the blurred scene, with focus on the Master volume, "
		+ "and Right raises it 5%% (%.0f to %.0f)"
		% [before, master.value if master != null else -1.0])
	await _key(KEY_UP)
	var on_audio := _focus()
	await _key(KEY_RIGHT)
	var listed := _shown("ControlsList") and not _shown("Master")
	var missing: Array[String] = []
	var controls := _text_of("ControlsList")
	for key in KEYS:
		if not controls.contains(key):
			missing.append(key)
	_check(on_audio == "AudioTab" and _focus() == "ControlsTab" and listed and missing.is_empty(),
		"Up reaches the tabs, and Right shows Controls, which lists every key (focus %s then %s; "
		% [on_audio, _focus()] + "missing: %s)" % ", ".join(missing))
	await _key(KEY_ESCAPE)
	var saved := ConfigFile.new()
	var stored := saved.load(SETTINGS) == OK \
		and absf(float(saved.get_value("audio", "Master", -1.0)) - (before + 5.0) / 100.0) < 0.001
	_check(_screen() == "title" and _focus() == "TitleSettings" and stored,
		"Esc goes back to the title with focus on Settings, and leaving Settings saves the volume")


func _check_credits() -> void:
	await _key(KEY_DOWN)
	var on_credits := _focus()
	await _key(KEY_ENTER)
	var text := _text_of("CreditsText")
	var missing: Array[String] = []
	for name in CREDITED:
		if not text.contains(name):
			missing.append(name)
	var scroll: RichTextLabel = _menu.find_child("CreditsText", true, false)
	var top := scroll.get_v_scroll_bar().value if scroll != null else 0.0
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	var moved := scroll != null and scroll.get_v_scroll_bar().value > top
	_check(on_credits == "Credits" and _screen() == "credits" and missing.is_empty() and moved,
		"Credits name the studio, the van, the characters, the textures, the cockpit model and "
		+ "the engine's licence, and Down scrolls them (missing: %s)" % ", ".join(missing))
	await _key(KEY_ESCAPE)
	_check(_screen() == "title" and _focus() == "Credits",
		"Esc leaves Credits for the title, with focus back on Credits")


func _check_new_game() -> void:
	await _key(KEY_UP)
	await _key(KEY_UP)
	var on_new := _focus()
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var driver: CharacterBody3D = _app.get("driver")
	_check(on_new == "NewGame" and not paused and _screen() == ""
		and root.get_camera_3d() != _app.get("title_camera") and bool(driver.get("active"))
		and _objective() == "SIGN THE RUN SHEET" and root.gui_get_focus_owner() == null,
		"Enter on New game starts the drive at the office, on foot, with the menu closed and "
		+ "nothing left holding the keyboard focus")


func _check_pause() -> void:
	await _key(KEY_ESCAPE)
	var shown := _text_of("PauseObjective") + " / " + _text_of("NextCheckpoint") + " / " \
		+ _text_of("LastSaved")
	_check(paused and _screen() == "pause" and _focus() == "Resume" and _shown("Blur")
		and shown.contains("SIGN THE RUN SHEET") and shown.contains("The switchbacks")
		and shown.contains("Nothing saved yet"),
		"Esc pauses: the game freezes behind a blur, with the objective, the next checkpoint and "
		+ "the last save, and focus on Resume (%s)" % shown)
	await _key(KEY_ESCAPE)
	_check(not paused and _screen() == "", "Esc on the pause screen resumes the drive")


func _save_at_viewpoint() -> void:
	_app.call("_close_run_sheet")
	_app.call("_enter_van")
	for index in [0, 1]:
		var target: Vector3 = Mission.TARGETS[index]
		_van.call("recover", Transform3D(Basis(Vector3.UP, Mission.HEADINGS[index]),
			target + Vector3.UP * 0.1))
		_route.call("_process", 0.2)
	await _seconds(0.3)


func _check_quit_to_title() -> void:
	await _key(KEY_ESCAPE)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	var on_main := _focus()
	await _key(KEY_ENTER)
	var asked := _screen() == "confirm" and _focus() == "ConfirmNo" \
		and _text_of("ConfirmQuestion").contains("main menu")
	await _key(KEY_ESCAPE)
	_check(on_main == "MainMenu" and asked and paused and _screen() == "pause"
		and _focus() == "MainMenu",
		"Quit to main menu asks first, with focus on Cancel; Esc cancels and keeps the game paused")
	await _key(KEY_ENTER)
	await _key(KEY_LEFT)
	var on_yes := _focus()
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var place := _text_of("ContinuePlace")
	var saved := _text_of("ContinueSaved")
	_check(on_yes == "ConfirmYes" and _screen() == "title" and _focus() == "Continue"
		and place == "Night Freight · The viewpoint" and saved.begins_with("Saved today, ")
		and root.get_camera_3d() == _app.get("title_camera") and int(_route.get("stage")) == 2
		and _van.global_position.distance_to(Mission.START.origin) < 0.05,
		"Confirming returns to the title, which offers Continue from the last checkpoint (%s; %s)"
		% [place, saved])


func _check_new_game_asks() -> void:
	var before := FileAccess.get_file_as_bytes(PROGRESS)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	var asked := _screen() == "confirm" and _focus() == "ConfirmNo" \
		and _text_of("ConfirmQuestion").contains("new game")
	await _key(KEY_ENTER)
	_check(asked and _screen() == "title" and _focus() == "NewGame"
		and FileAccess.get_file_as_bytes(PROGRESS) == before,
		"With a save, New game asks first, and Cancel keeps the save as it was")


func _check_continue() -> void:
	await _key(KEY_UP)
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var viewpoint: Vector3 = Mission.TARGETS[1]
	var off := Vector2(_van.global_position.x - viewpoint.x,
		_van.global_position.z - viewpoint.z).length()
	_check(not paused and bool(_van.get("occupied")) and off < 1.0
		and root.get_camera_3d() == _van.call("get_camera") and int(_route.get("stage")) == 2,
		"Enter on Continue puts Ethan in the van at the viewpoint (%.2f m from it)" % off)


func _check_recover() -> void:
	_van.call("recover", Transform3D(Basis(), _van.global_position + Vector3(6.0, 0.0, 0.0)))
	await _key(KEY_ESCAPE)
	await _key(KEY_DOWN)
	var on_recover := _focus()
	await _key(KEY_ENTER)
	await _seconds(0.2)
	var pose: Transform3D = _route.get("recovery_pose")
	var off := Vector2(_van.global_position.x - pose.origin.x,
		_van.global_position.z - pose.origin.z).length()
	var notice := (_hud.get("_notice") as Label).text
	_check(on_recover == "RecoverVan" and not paused and off < 0.1
		and notice.contains("recovered"),
		"Recover van, from the pause menu, puts the van back at the last checkpoint (focus %s, "
		% on_recover + "%.2f m from it, notice \"%s\")" % [off, notice])


func _check_quit() -> void:
	await _key(KEY_ESCAPE)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	await _key(KEY_LEFT)
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var chosen := Signal(_menu, "quit_chosen")
	for connection in chosen.get_connections():
		chosen.disconnect(connection.callable)
	chosen.connect(func() -> void: _quits += 1)
	for step in range(4):
		await _key(KEY_DOWN)
	var on_quit := _focus()
	await _key(KEY_ENTER)
	_check(on_quit == "Quit" and _quits == 1,
		"From the title, Down to Quit and Enter asks the game to close (focus: %s)" % on_quit)


func _screen() -> String:
	return String(_menu.call("screen"))


func _focus() -> String:
	var owner := root.gui_get_focus_owner()
	return String(owner.name) if owner != null else "(nothing)"


func _shown(name: String) -> bool:
	var node := _menu.find_child(name, true, false) as CanvasItem
	return node != null and node.is_visible_in_tree()


func _text_of(name: String) -> String:
	var node := _menu.find_child(name, true, false)
	if node is Label:
		return (node as Label).text
	if node is RichTextLabel:
		return (node as RichTextLabel).get_parsed_text()
	if node == null:
		return ""
	var words := PackedStringArray()
	for label in node.find_children("*", "Label", true, false):
		words.append((label as Label).text)
	return " ".join(words)


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _launch() -> void:
	change_scene_to_packed(load("res://app/first_drive.tscn") as PackedScene)
	await process_frame
	await process_frame
	_app = current_scene
	_hud = _app.get_node("DrivingHud")
	_route = _app.get_node("DrivingTrial")
	_van = _app.get_node("FreightVan")
	_menu = _hud.get("menu")
	await process_frame
	await process_frame


func _in_scratch_home() -> bool:
	var home := OS.get_environment("HOME")
	return home.ends_with("/.scratch-home") and OS.get_user_data_dir().begins_with(home + "/")


func _clear_user() -> void:
	for path in [PROGRESS, SETTINGS]:
		for suffix in ["", ".tmp", ".corrupt"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _timeout() -> void:
	_check(false, "The menu checks finish within 110 s")
	_finish()


func _finish() -> void:
	print("MENUS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
