extends Control

const DESIGN_SIZE := Vector2(640.0, 256.0)
const SWEEP_START := 150.0
const SWEEP := 240.0
const FACE := Color("0a0f13")
const INK := Color("d6dfd9")
const DIM_INK := Color("6f7d79")
const NEEDLE := Color("ff5a36")
const LAMP_GREEN := Color("49e07a")
const LAMP_BLUE := Color("3d84ff")
const LAMP_OFF := Color("17241f")
const WARNING := Color("ff4b3a")

var vehicle: CharacterBody3D
var render_scale: float = 1.0
var _elapsed: float = 0.0
var _font := ThemeDB.fallback_font


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.05:
		_elapsed = 0.0
		queue_redraw()


func _draw() -> void:
	if not is_instance_valid(vehicle):
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * render_scale)
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("05080a"))
	var speed_kmh := absf(vehicle.actual_speed) * 3.6
	var load: float = 0.13 + absf(vehicle.speed) / vehicle.maximum_speed * 0.6
	_dial(Vector2(158, 130), 106, speed_kmh / 160.0, 160, 20, 5, "km/h", 0.0)
	_dial(Vector2(482, 130), 96, load, 7, 1, 0.5, "x1000 r/min", 6.0)
	_sub_gauge(Vector2(158, 196), 0.62, "E", "F")
	_sub_gauge(Vector2(482, 192), 0.48, "C", "H")
	_centre_display(speed_kmh)
	_lamps()


func _dial(centre: Vector2, radius: float, fraction: float, top: int, major: int,
		minor: float, label: String, red_from: float) -> void:
	draw_circle(centre, radius + 7.0, Color("161d22"))
	draw_arc(centre, radius + 5.0, 0.0, TAU, 96, Color("3a464d"), 3.0, true)
	draw_arc(centre, radius + 5.0, deg_to_rad(200), deg_to_rad(290), 32, Color("8a989e"), 1.5, true)
	draw_circle(centre, radius, FACE)
	if red_from > 0.0:
		var from := deg_to_rad(SWEEP_START + SWEEP * red_from / top)
		draw_arc(centre, radius - 4.0, from, deg_to_rad(SWEEP_START + SWEEP), 24, WARNING, 6.0)
	var steps := int(round(top / minor))
	for step in range(steps + 1):
		var value := step * minor
		var angle := deg_to_rad(SWEEP_START + SWEEP * value / top)
		var direction := Vector2(cos(angle), sin(angle))
		var is_major := is_zero_approx(fmod(value, major))
		var length := 14.0 if is_major else 6.0
		draw_line(centre + direction * (radius - 2.0 - length), centre + direction * (radius - 2.0),
			INK if is_major else DIM_INK, 2.4 if is_major else 1.2, true)
		if is_major:
			var text := str(int(value))
			var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
			var at := centre + direction * (radius - 32.0) + Vector2(-size.x * 0.5, 6.0)
			draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	var label_size := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(_font, centre + Vector2(-label_size.x * 0.5, 40.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM_INK)
	_needle(centre, radius - 12.0, clampf(fraction, 0.0, 1.0))


func _needle(centre: Vector2, length: float, fraction: float) -> void:
	var angle := deg_to_rad(SWEEP_START + SWEEP * fraction)
	var direction := Vector2(cos(angle), sin(angle))
	var across := Vector2(-direction.y, direction.x)
	draw_line(centre - direction * 14.0, centre + direction * length, Color(1.0, 0.3, 0.15, 0.22),
		9.0, true)
	draw_colored_polygon(PackedVector2Array([centre - direction * 16.0 + across * 3.4,
		centre + direction * length + across * 0.8, centre + direction * length - across * 0.8,
		centre - direction * 16.0 - across * 3.4]), NEEDLE)
	draw_circle(centre, 11.0, Color("1d252b"))
	draw_circle(centre, 6.5, Color("879c94"))
	draw_circle(centre + Vector2(-2.0, -2.0), 2.0, Color("c9d4d0"))


func _sub_gauge(centre: Vector2, level: float, low: String, high: String) -> void:
	var from := deg_to_rad(205.0)
	var to := deg_to_rad(335.0)
	draw_arc(centre, 22.0, from, to, 24, DIM_INK, 1.5, true)
	for index in range(5):
		var angle := lerpf(from, to, index / 4.0)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(centre + direction * 18.0, centre + direction * 23.0, DIM_INK, 1.5, true)
	var needle := lerpf(from, to, level)
	draw_line(centre, centre + Vector2(cos(needle), sin(needle)) * 20.0, NEEDLE, 2.0, true)
	draw_string(_font, centre + Vector2(-31.0, 6.0), low, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM_INK)
	draw_string(_font, centre + Vector2(25.0, 6.0), high, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM_INK)


func _centre_display(speed_kmh: float) -> void:
	var panel := Rect2(270.0, 34.0, 100.0, 188.0)
	draw_rect(panel.grow(3.0), Color("1b2328"))
	draw_rect(panel, Color("08161b"))
	draw_string(_font, Vector2(278, 52), "23:42", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM_INK)
	draw_string(_font, Vector2(334, 52), "7°C", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM_INK)
	var gear := "D" if vehicle.gear > 0 else "R"
	var x := 282.0
	for letter in ["P", "R", "N", "D"]:
		var active: bool = letter == gear
		draw_string(_font, Vector2(x, 80), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			INK if active else Color("2c3a3d"))
		x += 20.0
	var reading := "%d" % roundi(speed_kmh)
	var size := _font.get_string_size(reading, HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
	draw_string(_font, Vector2(320.0 - size.x * 0.5, 136), reading, HORIZONTAL_ALIGNMENT_LEFT, -1,
		44, Color("e8efe9"))
	draw_string(_font, Vector2(304, 154), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM_INK)
	draw_line(Vector2(280, 166), Vector2(360, 166), Color("1f2d31"), 1.0)
	draw_string(_font, Vector2(279, 184), "ODO 048213 km", HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		DIM_INK)
	if vehicle.headlights_on:
		draw_string(_font, Vector2(299, 210), "LIGHTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			LAMP_GREEN)


func _lamps() -> void:
	var left: bool = vehicle.indicator_lit and (vehicle.indicator < 0 or vehicle.hazards_on)
	var right: bool = vehicle.indicator_lit and (vehicle.indicator > 0 or vehicle.hazards_on)
	_arrow(Vector2(250, 22), -1.0, LAMP_GREEN if left else LAMP_OFF)
	_arrow(Vector2(390, 22), 1.0, LAMP_GREEN if right else LAMP_OFF)
	_low_beam_symbol(Vector2(320, 238), LAMP_GREEN if vehicle.headlights_on else LAMP_OFF)
	_high_beam_symbol(Vector2(352, 238), LAMP_BLUE if vehicle.high_beams else LAMP_OFF)
	if vehicle.braking:
		draw_string(_font, Vector2(214, 246), "BRAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, WARNING)


func _arrow(at: Vector2, side: float, colour: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(10.0 * side, 0.0),
		at + Vector2(0.0, -8.0), at + Vector2(0.0, -3.5), at + Vector2(-9.0 * side, -3.5),
		at + Vector2(-9.0 * side, 3.5), at + Vector2(0.0, 3.5), at + Vector2(0.0, 8.0)]), colour)


func _low_beam_symbol(at: Vector2, colour: Color) -> void:
	draw_arc(at + Vector2(4.0, 0.0), 7.0, deg_to_rad(-90), deg_to_rad(90), 12, colour, 2.0, true)
	draw_line(at + Vector2(4.0, -7.0), at + Vector2(4.0, 7.0), colour, 2.0)
	for row in range(3):
		var y := -5.0 + row * 5.0
		draw_line(at + Vector2(0.0, y), at + Vector2(-9.0, y + 3.0), colour, 1.6, true)


func _high_beam_symbol(at: Vector2, colour: Color) -> void:
	draw_arc(at + Vector2(4.0, 0.0), 7.0, deg_to_rad(-90), deg_to_rad(90), 12, colour, 2.0, true)
	draw_line(at + Vector2(4.0, -7.0), at + Vector2(4.0, 7.0), colour, 2.0)
	for row in range(4):
		var y := -5.25 + row * 3.5
		draw_line(at + Vector2(0.0, y), at + Vector2(-9.0, y), colour, 1.6, true)
