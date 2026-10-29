extends Control

var vehicle: CharacterBody3D
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
	draw_rect(Rect2(0, 0, 640, 256), Color("080e12"))
	var speed_kmh := absf(vehicle.actual_speed) * 3.6
	_dial(Vector2(155, 136), 105, speed_kmh / 100.0, "km/h", 100)
	var rpm: float = 0.13 + absf(vehicle.speed) / vehicle.maximum_speed * 0.6
	_dial(Vector2(487, 136), 88, rpm, "RPM x1000", 6)
	var mint := Color("b9d9c8")
	draw_string(_font, Vector2(293, 115), "D" if vehicle.gear > 0 else "R", 0, -1, 44, mint)
	draw_string(_font, Vector2(280, 161), "%02d" % roundi(speed_kmh),
		0, -1, 30, mint)
	var off := Color("1e302c")
	var on := Color("7fdca4")
	var left: bool = vehicle.indicator_lit and (vehicle.indicator < 0 or vehicle.hazards_on)
	var right: bool = vehicle.indicator_lit and (vehicle.indicator > 0 or vehicle.hazards_on)
	draw_string(_font, Vector2(270, 47), "◀", 0, -1, 26, on if left else off)
	draw_string(_font, Vector2(340, 47), "▶", 0, -1, 26, on if right else off)
	if vehicle.headlights_on:
		draw_string(_font, Vector2(283, 211), "LIGHTS", 0, -1, 14, on)
	if vehicle.braking:
		draw_string(_font, Vector2(280, 238), "BRAKE", 0, -1, 14, Color("df8c74"))


func _dial(center: Vector2, radius: float, fraction: float, label: String, limit: int) -> void:
	var ink := Color("b7c6b4")
	draw_arc(center, radius, deg_to_rad(140), deg_to_rad(400), 64, Color("445553"), 2, true)
	for tick in range(21):
		var angle := deg_to_rad(140 + tick * 13)
		var direction := Vector2(cos(angle), sin(angle))
		var major := tick % 4 == 0
		draw_line(center + direction * (radius - (15 if major else 7)),
			center + direction * radius, ink, 2, true)
		if major:
			var at := center + direction * (radius - 31) + Vector2(-8, 5)
			draw_string(_font, at, str(tick * limit / 20), 0, -1, 15, ink)
	var needle := deg_to_rad(140 + clampf(fraction, 0, 1) * 260)
	draw_line(center, center + Vector2(cos(needle), sin(needle)) * (radius - 18),
		Color("ee9a6b"), 3, true)
	draw_circle(center, 7, Color("879c94"))
	draw_string(_font, center + Vector2(-24, 60), label, 0, -1, 16, ink)
