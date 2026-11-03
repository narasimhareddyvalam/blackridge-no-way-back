extends CanvasLayer

signal resume_requested
signal restart_requested
signal recovery_requested
signal pause_requested

const SETTINGS_PATH := "user://driving_audio.cfg"
const VanGuide = preload("van_guide.gd")
const CONTROLS := "W / S   Accelerate / brake     A / D   Steer\n" + \
	"Q   Select forward / reverse (stop first)     SPACE   Handbrake\n" + \
	"Z / C   Left / right indicator     X   Hazard lights\n" + \
	"V   Wipers: low / high / off     L   Headlights     I   Cabin light\n" + \
	"J / K   Driver / passenger window     H   Horn     MOUSE   Look     F   Center view\n" + \
	"E   Get in / out of the van (stop first)     SHIFT   Run     T   Answer a call\n" + \
	"R   Recover to checkpoint     ESC   Pause / controls / audio"

var menu_visible: bool = true
var van_guide := VanGuide.new()
var _heading: VBoxContainer
var _objective: Label
var _detail: Label
var _hint: Label
var _notice: Label
var _menu: PanelContainer
var _resume: Button
var _notice_timer: float = 0.0
var _fade: ColorRect
var _subtitles: PanelContainer
var _speaker: Label
var _words: Label
var _document: PanelContainer
var _sheet: RichTextLabel
var _typewriter := SystemFont.new()
var _handwriting := SystemFont.new()
var _settings := ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings.load(SETTINGS_PATH)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_heading = VBoxContainer.new()
	_heading.position = Vector2(32, 28)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_heading)
	var eyebrow := _label("NIGHT FREIGHT   /   DRIVING PROTOTYPE", 14, Color("bcad89"))
	_heading.add_child(eyebrow)
	_objective = _label("RETURN TO THE DEPOT", 25)
	_heading.add_child(_objective)
	_detail = _label("Follow the freight loop. Keep right.", 16, Color("c0c9cc"))
	_heading.add_child(_detail)
	_hint = _label("W / S  Drive / brake    A / D  Steer    ESC  Controls & audio", 15)
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
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_fade)
	_build_menu(root)


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


func _build_menu(root: Control) -> void:
	_menu = PanelContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.position = Vector2(-335, -330)
	_menu.size = Vector2(670, 660)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.025, 0.045, 0.06, 0.97)
	panel.border_color = Color("67766f")
	panel.set_border_width_all(1)
	panel.set_content_margin_all(24)
	_menu.add_theme_stylebox_override("panel", panel)
	root.add_child(_menu)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	_menu.add_child(rows)
	rows.add_child(_label("NIGHT FREIGHT", 30))
	rows.add_child(_label("First drive · vehicle and atmosphere prototype", 17, Color("bcad89")))
	var intro := _label("Follow the industrial loop and park at the freight depot.\n" +
		"The dashboard map and roadside signs show the way.", 16)
	rows.add_child(intro)
	_resume = _button("Begin / continue drive", func() -> void: resume_requested.emit())
	rows.add_child(_resume)
	rows.add_child(_label(CONTROLS, 15, Color("c4cdca")))
	rows.add_child(HSeparator.new())
	for bus in ["Master", "Vehicle", "Ambience", "Music"]:
		_audio_slider(rows, bus)
	var buttons := HBoxContainer.new()
	rows.add_child(buttons)
	buttons.add_child(_button("Recover van", func() -> void: recovery_requested.emit()))
	buttons.add_child(_button("New drive", func() -> void: restart_requested.emit()))
	buttons.add_child(_button("Quit", func() -> void: get_tree().quit()))
	_resume.grab_focus()


func _button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	return button


func _audio_slider(parent: Control, bus: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var title := _label(bus, 15)
	title.custom_minimum_size.x = 100
	row.add_child(title)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var index := AudioServer.get_bus_index(bus)
	var default_volume := db_to_linear(AudioServer.get_bus_volume_db(index))
	var stored: Variant = _settings.get_value("audio", bus, default_volume)
	var volume := default_volume
	if (stored is float or stored is int) and is_finite(float(stored)):
		volume = clampf(float(stored), 0.0, 1.0)
	slider.value = volume * 100
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0)
	slider.value_changed.connect(_volume_changed.bind(bus))
	row.add_child(slider)


func _volume_changed(percent: float, bus: String) -> void:
	var volume := percent / 100.0
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0)
	_settings.set_value("audio", bus, volume)
	var result := _settings.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Could not save audio preferences: %s" % error_string(result))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		pause_requested.emit()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _notice_timer > 0 and not menu_visible:
		_notice_timer -= delta
		if _notice_timer <= 0:
			_notice.text = ""


func set_menu(value: bool) -> void:
	menu_visible = value
	_menu.visible = value
	if value:
		_resume.grab_focus()


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
	_heading.visible = not value
	_hint.visible = not value
	_notice.visible = not value


func set_ended(value: bool) -> void:
	_resume.text = "Drive again" if value else "Begin / continue drive"


func fade(to: float, seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", to, seconds)
	return tween


func notify(words: String) -> void:
	_notice.text = words
	_notice_timer = 4.0
