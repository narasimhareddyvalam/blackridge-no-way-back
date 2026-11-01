extends Node2D

const GLASS_SIZE := Vector2(2.12, 1.08)
const PIVOTS: Array[Vector2] = [Vector2(-0.8, -0.51), Vector2(0.14, -0.51)]
const ARMS: Array[float] = [0.5, 0.46]
const BLADES: Array[float] = [0.7, 0.55]
const REWET_SECONDS := 2.0
const SPEED_REWET := 10.0

var vehicle: Node
var map_size := Vector2(512.0, 256.0)
var _previous_angle: float = NAN
var _delta: float = 0.0
var _filled: bool = false


func _process(delta: float) -> void:
	_delta = delta
	queue_redraw()


func _draw() -> void:
	var whole := Rect2(Vector2.ZERO, map_size)
	if not _filled:
		draw_rect(whole, Color.WHITE)
		_filled = true
		return
	var seconds := REWET_SECONDS
	if is_instance_valid(vehicle):
		seconds /= 1.0 + absf(float(vehicle.get("actual_speed"))) / SPEED_REWET
	var rewet := 1.0 - exp(-_delta / seconds)
	draw_rect(whole, Color(1.0, 1.0, 1.0, rewet))
	if not is_instance_valid(vehicle):
		return
	var blade := -float(vehicle.get("wiper_angle"))
	if not is_nan(_previous_angle) and absf(blade - _previous_angle) > 0.0005:
		for index in range(PIVOTS.size()):
			draw_colored_polygon(_sector(index, _previous_angle, blade), Color.BLACK)
	_previous_angle = blade


static func span(index: int) -> Vector2:
	return Vector2(ARMS[index] - BLADES[index] * 0.5, ARMS[index] + BLADES[index] * 0.5)


func _sector(wiper: int, from_angle: float, to_angle: float) -> PackedVector2Array:
	var pivot := PIVOTS[wiper]
	var reach := span(wiper)
	var steps := maxi(2, ceili(absf(to_angle - from_angle) / 0.04))
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for index in range(steps + 1):
		var angle := lerpf(from_angle, to_angle, float(index) / steps)
		var direction := Vector2(sin(angle), cos(angle))
		outer.append(_to_map(pivot + direction * reach.y))
		inner.append(_to_map(pivot + direction * reach.x))
	inner.reverse()
	return outer + inner


func _to_map(glass: Vector2) -> Vector2:
	return Vector2((glass.x / GLASS_SIZE.x + 0.5) * map_size.x,
		(0.5 - glass.y / GLASS_SIZE.y) * map_size.y)
