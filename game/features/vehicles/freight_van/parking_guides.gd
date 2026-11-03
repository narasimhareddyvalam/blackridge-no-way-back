extends Control

const NEAR := Vector2(0.18, 0.97)
const FAR := Vector2(0.36, 0.42)
const BANDS: Array[Color] = [Color("e0483e"), Color("f2c230"), Color("4fd18b")]
const TICK := 0.18
const WIDTH := 4.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var near_left := Vector2(size.x * NEAR.x, size.y * NEAR.y)
	var near_right := Vector2(size.x * (1.0 - NEAR.x), size.y * NEAR.y)
	var far_left := Vector2(size.x * FAR.x, size.y * FAR.y)
	var far_right := Vector2(size.x * (1.0 - FAR.x), size.y * FAR.y)
	for band in range(BANDS.size()):
		var from := float(band) / BANDS.size()
		var to := float(band + 1) / BANDS.size()
		var left := near_left.lerp(far_left, to)
		var right := near_right.lerp(far_right, to)
		draw_line(near_left.lerp(far_left, from), left, BANDS[band], WIDTH, true)
		draw_line(near_right.lerp(far_right, from), right, BANDS[band], WIDTH, true)
		draw_line(left, left.lerp(right, TICK), BANDS[band], WIDTH, true)
		draw_line(right, right.lerp(left, TICK), BANDS[band], WIDTH, true)
