extends CanvasLayer
## The cutscenes' film look (#357, "C Neo-noir"): the neo-noir grade over the 3D view
## (`film_grade.gdshader`), black bars for a 2.39 frame, the cards (a studio or title card, centred,
## its letters spaced, under a short red rule), a caption at the bottom left (a red bar, a title and
## a line under it), a title filling the screen on black, the dip to black at each cut, and the
## skip hint in the bottom bar. Shown only while a cutscene plays.

const GRADE = preload("film_grade.gdshader")
const LETTERING = preload("res://features/ui/driving_hud/fonts/BarlowCondensed-SemiBold.ttf")
const RATIO := 2.39
const RED := Color(0.78, 0.12, 0.12)
const INK := Color(0.96, 0.96, 0.96)
const DIM := Color(0.66, 0.66, 0.66)
const CARD_FADE := 0.6

var _grade: ColorRect
var _black: ColorRect
var _bars: Array[ColorRect] = []
var _card: VBoxContainer
var _card_title: Label
var _card_sub: Label
var _rule: ColorRect
var _caption: Control
var _caption_title: Label
var _caption_sub: Label
var _skip: Label
var _dip: ColorRect
var _full: VBoxContainer
var _full_title: Label
var _full_sub: Label
var _shown := false


func _ready() -> void:
	layer = 4
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_grade = ColorRect.new()
	_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grade := ShaderMaterial.new()
	grade.shader = GRADE
	_grade.material = grade
	root.add_child(_grade)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_black)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		if top:
			bar.anchor_bottom = 0.0
		else:
			bar.anchor_top = 1.0
			bar.anchor_bottom = 1.0
		root.add_child(bar)
		_bars.append(bar)
	_card = VBoxContainer.new()
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_constant_override("separation", 10)
	root.add_child(_card)
	var rule_box := CenterContainer.new()
	rule_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rule = ColorRect.new()
	_rule.color = RED
	_rule.custom_minimum_size = Vector2(64.0, 4.0)
	rule_box.add_child(_rule)
	_card.add_child(rule_box)
	_card_title = _label(52, INK, 12.0)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(_card_title)
	_card_sub = _label(16, RED, 8.0)
	_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(_card_sub)
	_caption = Control.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.anchor_top = 1.0
	_caption.anchor_bottom = 1.0
	root.add_child(_caption)
	var bar := ColorRect.new()
	bar.color = RED
	bar.position = Vector2(60.0, 0.0)
	bar.size = Vector2(4.0, 36.0)
	_caption.add_child(bar)
	_caption_title = _label(26, INK, 2.0)
	_caption_title.position = Vector2(76.0, -6.0)
	_caption.add_child(_caption_title)
	_caption_sub = _label(17, DIM, 1.0)
	_caption_sub.position = Vector2(76.0, 24.0)
	_caption.add_child(_caption_sub)
	_dip = ColorRect.new()
	_dip.color = Color.BLACK
	_dip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dip.modulate.a = 0.0
	root.add_child(_dip)
	_full = VBoxContainer.new()
	_full.alignment = BoxContainer.ALIGNMENT_CENTER
	_full.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full.add_theme_constant_override("separation", 18)
	root.add_child(_full)
	var full_rule := CenterContainer.new()
	full_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var red := ColorRect.new()
	red.color = RED
	red.custom_minimum_size = Vector2(120.0, 6.0)
	full_rule.add_child(red)
	_full.add_child(full_rule)
	_full_title = _label(150, INK, 34.0)
	_full_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_full.add_child(_full_title)
	_full_sub = _label(28, RED, 16.0)
	_full_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_full.add_child(_full_sub)
	_full.visible = false
	_skip = _label(16, DIM, 1.0)
	_skip.text = "E   SKIP"
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.anchor_top = 1.0
	_skip.anchor_bottom = 1.0
	_skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(_skip)
	root.resized.connect(_fit)
	_fit()
	show_film(false)


func _label(size: int, colour: Color, spacing: float) -> Label:
	var label := Label.new()
	var font := FontVariation.new()
	font.base_font = LETTERING
	font.spacing_glyph = int(spacing)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## The bars sized for a 2.39 frame on this screen, the caption and skip hint inside them.
func _fit() -> void:
	var screen := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280, 800)
	var bar := maxf((screen.y - screen.x / RATIO) / 2.0, 0.0)
	_bars[0].offset_bottom = bar
	_bars[1].offset_top = -bar
	_caption.offset_top = -bar - 72.0
	_skip.offset_top = -bar / 2.0 - 10.0
	_skip.offset_right = -40.0


func show_film(on: bool) -> void:
	_shown = on
	visible = on
	if not on:
		clear_texts()
		set_black(false)
		set_dip(0.0)
		_skip.visible = false


func bars_shown() -> bool:
	return _shown and visible


## The shot's grade: its exposure and gamma (1 and 0.92 as the look stands).
func set_grade(exposure: float, gamma: float) -> void:
	var grade := _grade.material as ShaderMaterial
	grade.set_shader_parameter("exposure", exposure)
	grade.set_shader_parameter("gamma", gamma)


## The black between shots: 0 clear, 1 black (a dip to and from black at each cut).
func set_dip(amount: float) -> void:
	_dip.modulate.a = clampf(amount, 0.0, 1.0)


func dip() -> float:
	return _dip.modulate.a


## The title filling the screen on black (the author: "the game name should be full screen"):
## `title` in letters 150 px high across the frame, `sub` under it, a red rule over it.
func show_full_title(title: String, sub: String) -> void:
	_full_title.text = title
	_full_sub.text = sub
	_full.visible = true
	_full.modulate.a = 0.0
	create_tween().tween_property(_full, "modulate:a", 1.0, CARD_FADE * 1.5)


func hide_full_title() -> void:
	if _full.visible:
		var fade := create_tween()
		fade.tween_property(_full, "modulate:a", 0.0, CARD_FADE)
		fade.tween_callback(func() -> void: _full.visible = false)


func full_title_shown() -> bool:
	return _full.visible


func set_black(on: bool) -> void:
	_black.visible = on


func show_skip(on: bool) -> void:
	_skip.visible = on


## A centred card: `title` with `sub` under it, faded in.
func show_card(title: String, sub: String) -> void:
	_card_title.text = title
	_card_sub.text = sub
	_card.visible = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, CARD_FADE)


## The card faded out.
func hide_card() -> void:
	if _card.visible:
		var fade := create_tween()
		fade.tween_property(_card, "modulate:a", 0.0, CARD_FADE)
		fade.tween_callback(func() -> void: _card.visible = false)


## A caption at the bottom left: `title` and `sub` under it.
func show_caption(title: String, sub: String) -> void:
	_caption_title.text = title
	_caption_sub.text = sub
	_caption.visible = true
	_caption.modulate.a = 0.0
	create_tween().tween_property(_caption, "modulate:a", 1.0, CARD_FADE)


func clear_texts() -> void:
	_card.visible = false
	_caption.visible = false
	_full.visible = false
