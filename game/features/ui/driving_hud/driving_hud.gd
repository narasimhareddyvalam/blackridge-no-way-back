extends CanvasLayer

signal resume_requested
signal restart_requested
signal recovery_requested
signal pause_requested

const SETTINGS_PATH := "user://driving_audio.cfg"
const CONTROLS := "W / S   Accelerate / brake     A / D   Steer\n" + \
	"Q   Select forward / reverse (stop first)     SPACE   Handbrake\n" + \
	"Z / C   Left / right indicator     X   Hazard lights\n" + \
	"V   Wipers: low / high / off     L   Headlights     H   Horn\n" + \
	"J / K   Driver / passenger window     MOUSE   Look     F   Center view\n" + \
	"E   Get in / out of the van (stop first)     SHIFT   Run\n" + \
	"R   Recover to checkpoint     ESC   Pause / controls / audio"

var menu_visible: bool = true
var _objective: Label
var _detail: Label
var _hint: Label
var _notice: Label
var _menu: PanelContainer
var _resume: Button
var _notice_timer: float = 0.0
var _fade: ColorRect
var _settings := ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings.load(SETTINGS_PATH)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var heading := VBoxContainer.new()
	heading.position = Vector2(32, 28)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heading)
	var eyebrow := _label("NIGHT FREIGHT   /   DRIVING PROTOTYPE", 14, Color("bcad89"))
	heading.add_child(eyebrow)
	_objective = _label("RETURN TO THE DEPOT", 25)
	heading.add_child(_objective)
	_detail = _label("Follow the freight loop. Keep right.", 16, Color("c0c9cc"))
	heading.add_child(_detail)
	_hint = _label("W / S  Drive / brake    A / D  Steer    ESC  Controls & audio", 15)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(32, -45)
	root.add_child(_hint)
	_notice = _label("", 18, Color("e3c799"))
	_notice.position = Vector2(32, 127)
	root.add_child(_notice)
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


func fade(to: float, seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", to, seconds)
	return tween


func notify(words: String) -> void:
	_notice.text = words
	_notice_timer = 4.0
