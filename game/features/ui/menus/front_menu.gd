extends Control

signal continue_chosen
signal new_game_chosen
signal resume_chosen
signal recover_chosen
signal main_menu_chosen
signal quit_chosen
signal settings_left

const BLUR = preload("menu_blur.gdshader")
const AMBER := Color("e3a33b")
const WHITE := Color("f2f4f5")
const GREY := Color("a9b1b7")
const SOFT := Color("c6cdd1")
const QUIET := Color("9ea7ad")
const PAPER := Color("d6dbdf")
const KEY_EDGE := Color("59626a")
const KEY_FILL := Color("111417")
const SHADE := Color(0.012, 0.02, 0.027)
const LEFT := 96.0
const BAR := 0.1
const ITEM_WIDTH := 440.0
const VOLUME_STEP := 5.0
const STUDIO := "NRVALAM WORKS"
const CONTROLS := [["W / S", "Accelerate / brake"], ["A / D", "Steer"],
	["W A S D", "Walk, on foot"], ["SHIFT", "Run"], ["Q", "Forward / reverse (stop first)"],
	["SPACE", "Handbrake"], ["Z / C", "Left / right indicator"], ["X", "Hazard lights"],
	["L", "Headlights: low / high / off"], ["V", "Wipers: low / high / off"],
	["I", "Cabin light"], ["J / K", "Driver / passenger window"], ["H", "Horn"],
	["MOUSE", "Look around"], ["F", "Center view"], ["E", "Get in / out (stop first)"],
	["T", "Answer a call"], ["R", "Recover to the last checkpoint"], ["ESC", "Pause"]]
const HINTS := {
	"title": [[["↑", "↓"], "Select"], [["Enter"], "Confirm"]],
	"pause": [[["↑", "↓"], "Select"], [["Enter"], "Confirm"], [["Esc"], "Resume"]],
	"settings": [[["↑", "↓"], "Select"], [["←", "→"], "Adjust"], [["Esc"], "Back"]],
	"credits": [[["↑", "↓"], "Scroll"], [["Esc"], "Back"]],
	"confirm": [[["←", "→"], "Select"], [["Enter"], "Confirm"], [["Esc"], "Cancel"]],
}

var _screen: String = ""
var _origin: String = "title"
var _screens: Dictionary = {}
var _return_focus: Control
var _confirmed := Callable()
var _has_save: bool = false
var _last_saved: String = ""
var _display := SystemFont.new()
var _ui := SystemFont.new()
var _ui_strong := SystemFont.new()
var _plain := StyleBoxEmpty.new()
var _marked := StyleBoxFlat.new()
var _row_plain := StyleBoxEmpty.new()
var _row_marked := StyleBoxFlat.new()
var _blur: ColorRect
var _keys: HBoxContainer
var _warning: Label
var _continue: Button
var _about: Control
var _place: Label
var _saved: Label
var _new_game: Button
var _resume: Button
var _mission: Label
var _objective: Label
var _detail: Label
var _next: Label
var _last: Label
var _audio_tab: Button
var _controls_tab: Button
var _audio_panel: VBoxContainer
var _settings_note: Label
var _controls_list: GridContainer
var _first_volume: HSlider
var _values: Dictionary = {}
var _credits: RichTextLabel
var _question: Label
var _question_detail: Label
var _yes: Button
var _no: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fonts()
	_styles()
	_blur = ColorRect.new()
	_blur.name = "Blur"
	_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blur_material := ShaderMaterial.new()
	blur_material.shader = BLUR
	_blur.material = blur_material
	add_child(_blur)
	add_child(_shade())
	_bar("BarTop", 0.0, BAR)
	_bar("BarBottom", 1.0 - BAR, 1.0)
	_build_title()
	_build_pause()
	_build_settings()
	_build_credits()
	_build_confirm()
	_keys = HBoxContainer.new()
	_keys.name = "Keys"
	_keys.position = Vector2(LEFT, 720.0)
	_keys.size = Vector2(1088.0, 80.0)
	_keys.alignment = BoxContainer.ALIGNMENT_END
	_keys.add_theme_constant_override("separation", 24)
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keys)
	visible = false


func show_title(place: String, saved: String) -> void:
	_has_save = not place.is_empty()
	_continue.visible = _has_save
	_about.visible = _has_save
	_place.text = place
	_saved.text = saved
	_continue.accessibility_description = "%s. %s" % [place, saved] if _has_save else ""
	_origin = "title"
	_open("title", _continue if _has_save else _new_game)


func show_pause(mission: String, objective: String, detail: String, next: String,
		last: String) -> void:
	_mission.text = mission.to_upper()
	_objective.text = objective
	_detail.text = detail
	_detail.visible = not detail.is_empty()
	_next.text = next
	_last.text = last
	_last_saved = last
	_origin = "pause"
	_open("pause", _resume)


func close() -> void:
	if _screen == "settings":
		settings_left.emit()
	_screen = ""
	visible = false
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and is_ancestor_of(owner):
		owner.release_focus()


func screen() -> String:
	return _screen


func back() -> bool:
	match _screen:
		"settings":
			settings_left.emit()
			_open(_origin, _return_focus)
			return true
		"credits", "confirm":
			_open(_origin, _return_focus)
			return true
		"title":
			return true
	return false


func set_warning(words: String) -> void:
	_warning.text = words
	_warning.visible = not words.is_empty()


func add_volume(title: String, slider: HSlider) -> void:
	var row := PanelContainer.new()
	row.name = title + "Row"
	row.add_theme_stylebox_override("panel", _row_plain)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 28)
	row.add_child(line)
	var label := _text(title + "Label", title, _ui, 16, SOFT)
	label.custom_minimum_size.x = 180.0
	line.add_child(label)
	slider.name = title
	slider.custom_minimum_size = Vector2(440.0, 24.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.gui_input.connect(_nudge.bind(slider))
	slider.accessibility_name = title + " volume"
	_style_slider(slider)
	line.add_child(slider)
	var value := _text(title + "Value", "", _ui, 15, SOFT)
	value.custom_minimum_size.x = 64.0
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value)
	_values[slider] = value
	slider.value_changed.connect(func(_amount: float) -> void: _show_value(slider))
	slider.focus_entered.connect(_mark_row.bind(row, label, value, true))
	slider.focus_exited.connect(_mark_row.bind(row, label, value, false))
	_audio_panel.add_child(row)
	_audio_panel.move_child(_settings_note, -1)
	if _first_volume == null:
		_first_volume = slider
		slider.focus_neighbor_top = slider.get_path_to(_audio_tab)
		_audio_tab.focus_neighbor_bottom = _audio_tab.get_path_to(slider)
		_controls_tab.focus_neighbor_bottom = _controls_tab.get_path_to(_controls_tab)


func _open(name: String, focus: Control) -> void:
	_screen = name
	for key: String in _screens:
		(_screens[key] as Control).visible = key == name
	_blur.visible = name != "title"
	visible = true
	_hints(HINTS[name])
	if focus != null and focus.is_visible_in_tree():
		focus.grab_focus.call_deferred()


func _open_settings(from: Control) -> void:
	_return_focus = from
	for slider: HSlider in _values:
		_show_value(slider)
	_show_tab(true)
	_open("settings", _first_volume)


func _open_credits(from: Control) -> void:
	_return_focus = from
	_credits.scroll_to_line(0)
	_open("credits", _credits)


func _ask(question: String, detail: String, yes: String, from: Control,
		chosen: Callable) -> void:
	_return_focus = from
	_confirmed = chosen
	_question.text = question
	_question_detail.text = detail
	_yes.text = yes.to_upper()
	_yes.accessibility_name = yes
	_open("confirm", _no)


func _choose_new_game() -> void:
	if _has_save:
		_ask("Start a new game?", "Your saved progress will be replaced.", "Start new game",
			_new_game, func() -> void: new_game_chosen.emit())
	else:
		new_game_chosen.emit()


func _choose_main_menu(from: Control) -> void:
	var detail := "Nothing has been saved yet."
	if _last_saved != "Nothing saved yet":
		detail = "You will continue from the last checkpoint: %s." % _last_saved.to_lower()
	_ask("Quit to the main menu?", detail, "Quit to main menu", from,
		func() -> void: main_menu_chosen.emit())


func _show_tab(audio: bool) -> void:
	_audio_panel.visible = audio
	_controls_list.visible = not audio
	_audio_tab.set_pressed_no_signal(audio)
	_controls_tab.set_pressed_no_signal(not audio)


func _show_value(slider: HSlider) -> void:
	(_values[slider] as Label).text = "%d%%" % roundi(slider.value)


func _mark_row(row: PanelContainer, label: Label, value: Label, marked: bool) -> void:
	row.add_theme_stylebox_override("panel", _row_marked if marked else _row_plain)
	var colour := WHITE if marked else SOFT
	label.add_theme_color_override("font_color", colour)
	value.add_theme_color_override("font_color", colour)


func _nudge(event: InputEvent, slider: HSlider) -> void:
	var step := 0.0
	if event.is_action_pressed("ui_right", true):
		step = VOLUME_STEP
	elif event.is_action_pressed("ui_left", true):
		step = -VOLUME_STEP
	if step != 0.0:
		slider.value += step
		slider.accept_event()


func _scroll_credits(event: InputEvent) -> void:
	var step := 0.0
	if event.is_action_pressed("ui_down", true):
		step = 40.0
	elif event.is_action_pressed("ui_up", true):
		step = -40.0
	elif event.is_action_pressed("ui_page_down", true):
		step = _credits.size.y * 0.8
	elif event.is_action_pressed("ui_page_up", true):
		step = -_credits.size.y * 0.8
	if step != 0.0:
		_credits.get_v_scroll_bar().value += step
		_credits.accept_event()


func _build_title() -> void:
	var screen := _screen_node("Title")
	var heading := VBoxContainer.new()
	heading.name = "Heading"
	heading.position = Vector2(LEFT, 150.0)
	heading.add_theme_constant_override("separation", 12)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(heading)
	heading.add_child(_text("GameTitle", "BLACKRIDGE", _tracked(_display, 5), 96, WHITE))
	heading.add_child(_text("Subtitle", "NO WAY BACK", _tracked(_ui, 9), 15, Color("c8ced2")))
	var list := _list(screen, "TitleList", 344.0)
	_warning = _text("Warning", "", _ui, 15, AMBER)
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.custom_minimum_size.x = 520.0
	_warning.visible = false
	list.add_child(_warning)
	_continue = _item("Continue", "CONTINUE", "Continue")
	_continue.pressed.connect(func() -> void: continue_chosen.emit())
	list.add_child(_continue)
	var about := MarginContainer.new()
	about.name = "ContinueAbout"
	about.add_theme_constant_override("margin_left", 24)
	about.add_theme_constant_override("margin_bottom", 6)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 2)
	about.add_child(lines)
	_place = _text("ContinuePlace", "", _ui, 13, SOFT)
	_saved = _text("ContinueSaved", "", _ui, 12, QUIET)
	lines.add_child(_place)
	lines.add_child(_saved)
	_about = about
	list.add_child(about)
	_new_game = _item("NewGame", "NEW GAME", "New game")
	_new_game.pressed.connect(_choose_new_game)
	list.add_child(_new_game)
	var settings := _item("TitleSettings", "SETTINGS", "Settings")
	settings.pressed.connect(func() -> void: _open_settings(settings))
	list.add_child(settings)
	var credits := _item("Credits", "CREDITS", "Credits")
	credits.pressed.connect(func() -> void: _open_credits(credits))
	list.add_child(credits)
	var quit := _item("Quit", "QUIT", "Quit")
	quit.pressed.connect(func() -> void: quit_chosen.emit())
	list.add_child(quit)


func _build_pause() -> void:
	var screen := _screen_node("Pause")
	var heading := VBoxContainer.new()
	heading.name = "PauseHeading"
	heading.position = Vector2(LEFT, 132.0)
	heading.custom_minimum_size.x = 560.0
	heading.add_theme_constant_override("separation", 14)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(heading)
	var eyebrow := HBoxContainer.new()
	eyebrow.add_theme_constant_override("separation", 14)
	eyebrow.add_child(_text("Paused", "PAUSED", _tracked(_ui_strong, 4), 13, Color("c9cfd3")))
	var dot := ColorRect.new()
	dot.color = AMBER
	dot.custom_minimum_size = Vector2(4.0, 4.0)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eyebrow.add_child(dot)
	_mission = _text("Mission", "", _tracked(_ui_strong, 4), 13, Color("c9cfd3"))
	eyebrow.add_child(_mission)
	heading.add_child(eyebrow)
	_objective = _text("PauseObjective", "", _tracked(_display, 2), 56, WHITE)
	heading.add_child(_objective)
	_detail = _text("PauseDetail", "", _ui, 16, PAPER)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(_detail)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 40)
	heading.add_child(facts)
	_next = _fact(facts, "NEXT CHECKPOINT", "NextCheckpoint")
	_last = _fact(facts, "LAST SAVED", "LastSaved")
	var list := _list(screen, "PauseList", 418.0)
	_resume = _item("Resume", "RESUME", "Resume")
	_resume.pressed.connect(func() -> void: resume_chosen.emit())
	list.add_child(_resume)
	var recover := _item("RecoverVan", "RECOVER VAN", "Recover van")
	recover.pressed.connect(func() -> void: recover_chosen.emit())
	list.add_child(recover)
	var settings := _item("PauseSettings", "SETTINGS", "Settings")
	settings.pressed.connect(func() -> void: _open_settings(settings))
	list.add_child(settings)
	var main_menu := _item("MainMenu", "QUIT TO MAIN MENU", "Quit to main menu")
	main_menu.pressed.connect(func() -> void: _choose_main_menu(main_menu))
	list.add_child(main_menu)


func _build_settings() -> void:
	var screen := _screen_node("Settings")
	screen.add_child(_heading("SettingsTitle", "SETTINGS"))
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.position = Vector2(LEFT, 206.0)
	tabs.add_theme_constant_override("separation", 36)
	screen.add_child(tabs)
	var group := ButtonGroup.new()
	_audio_tab = _tab("AudioTab", "AUDIO", "Audio", group)
	_controls_tab = _tab("ControlsTab", "CONTROLS", "Controls", group)
	for tab: Button in [_audio_tab, _controls_tab]:
		var audio := tab == _audio_tab
		tab.focus_entered.connect(_show_tab.bind(audio))
		tab.pressed.connect(_show_tab.bind(audio))
		tabs.add_child(tab)
	var rule := ColorRect.new()
	rule.color = Color(1.0, 1.0, 1.0, 0.16)
	rule.position = Vector2(LEFT, 250.0)
	rule.size = Vector2(800.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(rule)
	_audio_panel = VBoxContainer.new()
	_audio_panel.name = "AudioPanel"
	_audio_panel.position = Vector2(LEFT, 272.0)
	_audio_panel.custom_minimum_size.x = 800.0
	_audio_panel.add_theme_constant_override("separation", 4)
	screen.add_child(_audio_panel)
	_audio_panel.add_child(_text("Volume", "VOLUME", _tracked(_ui_strong, 3), 11, QUIET))
	_settings_note = _text("SettingsNote", "Changes are saved when you leave this screen.",
		_ui, 13, GREY)
	_audio_panel.add_child(_settings_note)
	_controls_list = GridContainer.new()
	_controls_list.name = "ControlsList"
	_controls_list.columns = 4
	_controls_list.position = Vector2(LEFT, 276.0)
	_controls_list.add_theme_constant_override("h_separation", 28)
	_controls_list.add_theme_constant_override("v_separation", 10)
	screen.add_child(_controls_list)
	for pair: Array in CONTROLS:
		var key := _text("", pair[0], _ui_strong, 14, WHITE)
		key.custom_minimum_size.x = 84.0
		_controls_list.add_child(key)
		var action := _text("", pair[1], _ui, 14, GREY)
		action.custom_minimum_size.x = 270.0
		_controls_list.add_child(action)


func _build_credits() -> void:
	var screen := _screen_node("Credits")
	screen.add_child(_heading("CreditsTitle", "CREDITS"))
	_credits = RichTextLabel.new()
	_credits.name = "CreditsText"
	_credits.position = Vector2(LEFT, 206.0)
	_credits.size = Vector2(760.0, 490.0)
	_credits.bbcode_enabled = true
	_credits.scroll_active = true
	_credits.focus_mode = Control.FOCUS_ALL
	_credits.accessibility_name = "Credits"
	_credits.add_theme_font_override("normal_font", _ui)
	_credits.add_theme_font_override("bold_font", _ui_strong)
	_credits.add_theme_font_size_override("normal_font_size", 15)
	_credits.add_theme_font_size_override("bold_font_size", 15)
	_credits.add_theme_color_override("default_color", SOFT)
	_credits.add_theme_constant_override("line_separation", 4)
	_credits.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_credits.text = _credits_text()
	_credits.gui_input.connect(_scroll_credits)
	var bar := _credits.get_v_scroll_bar()
	bar.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	track.content_margin_left = 2.0
	track.content_margin_right = 2.0
	var grip := StyleBoxFlat.new()
	grip.bg_color = Color(1.0, 1.0, 1.0, 0.28)
	grip.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("scroll", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(state, grip)
	screen.add_child(_credits)


func _build_confirm() -> void:
	var screen := _screen_node("Confirm")
	var box := VBoxContainer.new()
	box.name = "ConfirmBox"
	box.position = Vector2(LEFT, 300.0)
	box.custom_minimum_size.x = 640.0
	box.add_theme_constant_override("separation", 14)
	screen.add_child(box)
	_question = _text("ConfirmQuestion", "", _tracked(_display, 2), 44, WHITE)
	box.add_child(_question)
	_question_detail = _text("ConfirmDetail", "", _ui, 16, PAPER)
	_question_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_question_detail)
	var buttons := HBoxContainer.new()
	buttons.name = "ConfirmButtons"
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	_yes = _item("ConfirmYes", "", "Confirm")
	_yes.custom_minimum_size.x = 0.0
	_yes.pressed.connect(func() -> void: _confirmed.call())
	buttons.add_child(_yes)
	_no = _item("ConfirmNo", "CANCEL", "Cancel")
	_no.custom_minimum_size.x = 0.0
	_no.pressed.connect(func() -> void: back())
	buttons.add_child(_no)


func _credits_text() -> String:
	var lines := PackedStringArray()
	lines.append("[color=#%s]BLACKRIDGE: NO WAY BACK[/color]" % QUIET.to_html(false))
	lines.append("[font_size=24][color=#%s]A game by %s[/color][/font_size]"
		% [WHITE.to_html(false), STUDIO])
	_section(lines, "THE VAN", "\"Iveco Daily Van 2014\" by Max (Sketchfab: Max-7215), "
		+ "licensed CC BY 4.0. Adapted for this game: the badges removed, a new number plate, "
		+ "and its glass, lights and wipers rebuilt. Blackridge is not affiliated with Iveco.")
	_section(lines, "THE PEOPLE", "Ethan and the man at the crossing are Adobe Mixamo "
		+ "characters, with Mixamo animations.")
	_section(lines, "THE FOREST, THE ROAD AND THE YARD", "Textures, trees, plants and rocks "
		+ "from Poly Haven, released CC0 by its artists.")
	_section(lines, "INTERIOR MODEL", "\"FREE // Honda E (Detailed Interior) 2021\" by Alex "
		+ "Murias (Sketchfab: Xlay3D), licensed CC BY 4.0, used while the cab was being built.")
	_section(lines, "SOUND", "Every sound was made in code for this game.")
	_section(lines, "ENGINE", "Made with Godot Engine, godotengine.org. Godot is distributed "
		+ "under the MIT license:")
	lines.append(_plain_text(Engine.get_license_text()))
	_section(lines, "THIRD-PARTY COMPONENTS IN GODOT ENGINE", "")
	for component: Dictionary in Engine.get_copyright_info():
		var parts := PackedStringArray()
		for part: Dictionary in component.get("parts", []):
			parts.append(", ".join(part.get("copyright", PackedStringArray()))
				+ " (" + String(part.get("license", "")) + ")")
		lines.append("[b]%s[/b]  %s" % [_plain_text(component.get("name", "")),
			_plain_text("; ".join(parts))])
	var licenses: Dictionary = Engine.get_license_info()
	for name: String in licenses:
		_section(lines, name.to_upper(), _plain_text(String(licenses[name])))
	return "\n".join(lines)


func _section(lines: PackedStringArray, heading: String, body: String) -> void:
	lines.append("")
	lines.append("[b][color=#%s]%s[/color][/b]" % [WHITE.to_html(false), _plain_text(heading)])
	if not body.is_empty():
		lines.append(body)


func _plain_text(words: String) -> String:
	return words.strip_edges().replace("[", "[lb]")


func _screen_node(name: String) -> Control:
	var screen := Control.new()
	screen.name = name
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.visible = false
	add_child(screen)
	_screens[name.to_lower()] = screen
	return screen


func _list(screen: Control, name: String, top: float) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.name = name
	list.position = Vector2(LEFT, top)
	list.custom_minimum_size.x = ITEM_WIDTH
	list.add_theme_constant_override("separation", 2)
	screen.add_child(list)
	return list


func _heading(name: String, words: String) -> Label:
	var label := _text(name, words, _tracked(_display, 2), 56, WHITE)
	label.position = Vector2(LEFT, 128.0)
	return label


func _fact(parent: Control, title: String, name: String) -> Label:
	var fact := VBoxContainer.new()
	fact.add_theme_constant_override("separation", 4)
	parent.add_child(fact)
	fact.add_child(_text("", title, _tracked(_ui_strong, 3), 11, QUIET))
	var value := _text(name, "", _ui, 15, Color("eef1f2"))
	fact.add_child(value)
	return value


func _text(name: String, words: String, font: Font, size: int, colour: Color) -> Label:
	var label := Label.new()
	if not name.is_empty():
		label.name = name
	label.text = words
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _item(name: String, words: String, spoken: String) -> Button:
	var button := Button.new()
	button.name = name
	button.text = words
	button.accessibility_name = spoken
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(ITEM_WIDTH, 46.0)
	button.add_theme_font_override("font", _tracked(_ui_strong, 3))
	button.add_theme_font_size_override("font_size", 15)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		button.add_theme_stylebox_override(state, _plain)
	button.add_theme_stylebox_override("focus", _marked)
	button.add_theme_color_override("font_color", GREY)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color",
			"font_hover_pressed_color"]:
		button.add_theme_color_override(state, WHITE)
	return button


func _tab(name: String, words: String, spoken: String, group: ButtonGroup) -> Button:
	var tab := Button.new()
	tab.name = name
	tab.text = words
	tab.accessibility_name = spoken
	tab.toggle_mode = true
	tab.button_group = group
	tab.custom_minimum_size.y = 44.0
	tab.add_theme_font_override("font", _tracked(_ui_strong, 3))
	tab.add_theme_font_size_override("font_size", 14)
	var flat := StyleBoxEmpty.new()
	flat.content_margin_bottom = 14.0
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.border_width_bottom = 2
	line.border_color = AMBER
	line.content_margin_bottom = 14.0
	for state in ["normal", "hover", "disabled", "focus"]:
		tab.add_theme_stylebox_override(state, flat)
	for state in ["pressed", "hover_pressed"]:
		tab.add_theme_stylebox_override(state, line)
	tab.add_theme_color_override("font_color", GREY)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color",
			"font_hover_pressed_color"]:
		tab.add_theme_color_override(state, WHITE)
	return tab


func _hints(pairs: Array) -> void:
	for child in _keys.get_children():
		_keys.remove_child(child)
		child.queue_free()
	for pair: Array in pairs:
		var group := HBoxContainer.new()
		group.add_theme_constant_override("separation", 6)
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for key: String in pair[0]:
			group.add_child(_key_cap(key))
		var words := _text("", pair[1], _ui, 12, Color("aab2b8"))
		words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		group.add_child(words)
		_keys.add_child(group)


func _key_cap(key: String) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = KEY_FILL
	box.border_color = KEY_EDGE
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	cap.add_theme_stylebox_override("panel", box)
	var label := _text("", key, _ui_strong, 12, Color("e3e7ea"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 12.0
	cap.add_child(label)
	return cap


func _bar(name: String, top: float, bottom: float) -> void:
	var bar := ColorRect.new()
	bar.name = name
	bar.color = Color.BLACK
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = top
	bar.anchor_bottom = bottom
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)


func _shade() -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.32, 0.6, 1.0])
	gradient.colors = PackedColorArray([Color(SHADE, 0.84), Color(SHADE, 0.62),
		Color(SHADE, 0.16), Color(SHADE, 0.08)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 4
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var shade := TextureRect.new()
	shade.name = "Shade"
	shade.texture = texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shade


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1.0, 1.0, 1.0, 0.24)
	track.content_margin_top = 1.0
	track.content_margin_bottom = 1.0
	var filled := StyleBoxFlat.new()
	filled.bg_color = SOFT
	filled.content_margin_top = 1.0
	filled.content_margin_bottom = 1.0
	var lit := filled.duplicate() as StyleBoxFlat
	lit.bg_color = AMBER
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", lit)
	slider.add_theme_icon_override("grabber", _dot(SOFT, Color(0, 0, 0, 0)))
	slider.add_theme_icon_override("grabber_highlight", _dot(WHITE, AMBER))
	slider.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _dot(fill: Color, ring: Color) -> ImageTexture:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var centre := Vector2(11.5, 11.5)
	for x in range(24):
		for y in range(24):
			var distance := Vector2(x, y).distance_to(centre)
			var colour := fill
			colour.a = clampf(8.5 - distance, 0.0, 1.0)
			if ring.a > 0.0 and distance > 8.0:
				colour = ring
				colour.a = clampf(11.5 - distance, 0.0, 1.0)
			image.set_pixel(x, y, colour)
	return ImageTexture.create_from_image(image)


func _fonts() -> void:
	_display.font_names = PackedStringArray(["DIN Condensed", "Avenir Next Condensed",
		"Helvetica Neue", "Arial"])
	_display.font_weight = 700
	_ui.font_names = PackedStringArray(["SF Pro Text", "SF Pro", "Helvetica Neue", "Arial"])
	_ui_strong.font_names = _ui.font_names
	_ui_strong.font_weight = 600


func _tracked(base: Font, spacing: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = base
	font.spacing_glyph = spacing
	return font


func _styles() -> void:
	_plain.content_margin_left = 24.0
	_plain.content_margin_right = 24.0
	_plain.content_margin_top = 13.0
	_plain.content_margin_bottom = 13.0
	_marked.draw_center = false
	_marked.border_width_left = 3
	_marked.border_color = AMBER
	_marked.expand_margin_top = -13.0
	_marked.expand_margin_bottom = -13.0
	_row_plain.content_margin_left = 24.0
	_row_plain.content_margin_top = 16.0
	_row_plain.content_margin_bottom = 16.0
	_row_marked.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	_row_marked.border_width_left = 3
	_row_marked.border_color = AMBER
	_row_marked.content_margin_left = 24.0
	_row_marked.content_margin_top = 16.0
	_row_marked.content_margin_bottom = 16.0
