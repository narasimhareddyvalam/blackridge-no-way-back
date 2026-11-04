extends CanvasLayer

signal resume_requested
signal restart_requested
signal recovery_requested
signal pause_requested

const SaveFile = preload("res://shared/save/save_file.gd")
const SETTINGS_VERSION := 1
const VanGuide = preload("van_guide.gd")
const FrontMenu = preload("res://features/ui/menus/front_menu.gd")

var menu_visible: bool = true
var settings_path: String = ""
var van_guide := VanGuide.new()
var menu: Control
var _heading: VBoxContainer
var _objective: Label
var _detail: Label
var _hint: Label
var _notice: Label
var _cinematic: bool = false
var _notice_timer: float = 0.0
var _fade: ColorRect
var _subtitles: PanelContainer
var _speaker: Label
var _words: Label
var _document: PanelContainer
var _sheet: RichTextLabel
var _typewriter := SystemFont.new()
var _handwriting := SystemFont.new()
var _warnings: Dictionary = {}
var _sliders: Dictionary = {}
var _defaults: Dictionary = {}
var _settings: SaveFile
var _settings_changed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_heading = VBoxContainer.new()
	_heading.position = Vector2(32, 28)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_heading)
	var eyebrow := _label("NIGHT FREIGHT", 14, Color("bcad89"))
	_heading.add_child(eyebrow)
	_objective = _label("RETURN TO THE DEPOT", 25)
	_heading.add_child(_objective)
	_detail = _label("", 16, Color("c0c9cc"))
	_heading.add_child(_detail)
	_hint = _label("", 15)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(32, -45)
	root.add_child(_hint)
	_notice = _label("", 18, Color("e3c799"))
	_notice.position = Vector2(32, 127)
	root.add_child(_notice)
	van_guide.name = "VanGuide"
	root.add_child(van_guide)
	_build_subtitles(root)
	_build_document(root)
	menu = FrontMenu.new()
	menu.name = "FrontMenu"
	root.add_child(menu)
	menu.settings_left.connect(save_settings)
	menu.quit_chosen.connect(_quit)
	for bus in ["Master", "Vehicle", "Ambience", "Music"]:
		_audio_slider(bus)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_fade)


func _label(words: String, size: int, color: Color = Color("e2e5df")) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _build_subtitles(root: Control) -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	holder.offset_top = -150.0
	holder.offset_bottom = -82.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	_subtitles = PanelContainer.new()
	_subtitles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	panel.set_corner_radius_all(4)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 7
	panel.content_margin_bottom = 7
	_subtitles.add_theme_stylebox_override("panel", panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_subtitles.add_child(row)
	_speaker = _label("", 20, Color("e3c799"))
	row.add_child(_speaker)
	_words = _label("", 20)
	row.add_child(_words)
	_subtitles.visible = false
	holder.add_child(_subtitles)


func _build_document(root: Control) -> void:
	_typewriter.font_names = PackedStringArray(["Courier New", "Courier", "Menlo", "monospace"])
	_handwriting.font_names = PackedStringArray(["Bradley Hand", "Noteworthy", "Snell Roundhand",
		"cursive"])
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	_document = PanelContainer.new()
	_document.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e9e4d6")
	paper.border_color = Color("c9c2ae")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(2)
	paper.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	paper.shadow_size = 10
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 24
	paper.content_margin_bottom = 26
	_document.add_theme_stylebox_override("panel", paper)
	holder.add_child(_document)
	_sheet = RichTextLabel.new()
	_sheet.fit_content = true
	_sheet.scroll_active = false
	_sheet.autowrap_mode = TextServer.AUTOWRAP_OFF
	_sheet.custom_minimum_size = Vector2(470, 0)
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_document.add_child(_sheet)
	_document.visible = false


func _audio_slider(bus: String) -> void:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	_defaults[bus] = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))
	slider.value = _defaults[bus] * 100
	slider.value_changed.connect(_volume_changed.bind(bus))
	_sliders[bus] = slider
	menu.add_volume(bus, slider)


func _volume_changed(percent: float, bus: String) -> void:
	_set_volume(bus, percent / 100.0)
	_settings_changed = true


func _set_volume(bus: String, volume: float) -> void:
	(_sliders[bus] as HSlider).set_value_no_signal(volume * 100)
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0)


func load_settings() -> SaveFile.Read:
	_settings = SaveFile.new(settings_path, SETTINGS_VERSION)
	var config := _settings.read(_valid_settings)
	for bus: String in _sliders:
		var volume: float = _defaults[bus]
		if config != null and config.has_section_key("audio", bus):
			volume = float(config.get_value("audio", bus))
		_set_volume(bus, volume)
	_settings_changed = false
	var words := ""
	if _settings.status == SaveFile.Read.CORRUPT:
		words = "Settings could not be read, so the default volumes are in use."
	elif _settings.status == SaveFile.Read.NEWER:
		words = "These settings are from a newer version of the game. The default volumes are " \
			+ "in use, and volume changes will not be saved this session."
	warn("settings", words)
	return _settings.status


func save_settings() -> Error:
	if not _settings_changed or _settings == null:
		return OK
	var config := ConfigFile.new()
	for bus: String in _sliders:
		config.set_value("audio", bus, (_sliders[bus] as HSlider).value / 100.0)
	var result := _settings.write(config)
	if result == OK:
		_settings_changed = false
	elif result != ERR_UNAVAILABLE:
		notify("Settings could not be saved. These volumes last until you quit.")
	return result


func _valid_settings(config: ConfigFile) -> bool:
	for bus: String in _sliders:
		if config.has_section_key("audio", bus):
			var volume: Variant = config.get_value("audio", bus)
			if not (volume is float or volume is int) or not (volume >= 0.0 and volume <= 1.0):
				return false
	return true


func warn(source: String, words: String) -> void:
	if words.is_empty():
		_warnings.erase(source)
	else:
		_warnings[source] = words
	menu.set_warning(warning())


func warning() -> String:
	return "\n".join(_warnings.values())


func _quit() -> void:
	save_settings()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if not menu.back():
			pause_requested.emit()


func _process(delta: float) -> void:
	if _notice_timer > 0 and not menu_visible:
		_notice_timer -= delta
		if _notice_timer <= 0:
			_notice.text = ""


func show_title(place: String, saved: String) -> void:
	menu_visible = true
	menu.show_title(place, saved)
	_refresh_overlays()


func show_pause(mission: String, next: String, last: String) -> void:
	menu_visible = true
	menu.show_pause(mission, _objective.text, _detail.text, next, last)
	_refresh_overlays()


func set_menu(value: bool) -> void:
	if value:
		show_pause("", "", "")
		return
	menu_visible = false
	menu.close()
	save_settings()
	_refresh_overlays()


func _refresh_overlays() -> void:
	var shown := not _cinematic and not menu_visible
	_heading.visible = shown
	_hint.visible = shown
	_notice.visible = shown


func set_objective(title: String, detail: String) -> void:
	_objective.text = title
	_detail.text = detail


func set_hint(words: String) -> void:
	_hint.text = words


func show_subtitle(speaker: String, words: String) -> void:
	_speaker.text = speaker
	_words.text = words
	_subtitles.visible = true


func clear_subtitle() -> void:
	_subtitles.visible = false


func subtitle() -> String:
	return "%s: %s" % [_speaker.text, _words.text] if _subtitles.visible else ""


func show_document(words: String) -> void:
	_sheet.clear()
	_sheet.push_font(_typewriter, 17)
	_sheet.push_color(Color("23252b"))
	_sheet.add_text(words)
	_sheet.pop()
	_sheet.pop()
	_document.visible = true


func sign_document(signature: String) -> void:
	_sheet.push_font(_handwriting, 26)
	_sheet.push_color(Color("1d3a7a"))
	_sheet.add_text(" " + signature)
	_sheet.pop()
	_sheet.pop()


func hide_document() -> void:
	_document.visible = false


func document_visible() -> bool:
	return _document.visible


func document_text() -> String:
	return _sheet.get_parsed_text() if _document.visible else ""


func set_cinematic(value: bool) -> void:
	_cinematic = value
	_refresh_overlays()


func fade(to: float, seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", to, seconds)
	return tween


func reveal(seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, seconds).from(1.0)
	return tween


func notify(words: String) -> void:
	_notice.text = words
	_notice_timer = 4.0
