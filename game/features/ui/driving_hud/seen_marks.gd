extends Control
## Who is seeing the player (#358, Mission 2's escape): over each guard who sees Ethan, a mark
## that fills from white toward red with how near he is to being caught (the guard's sight over
## the second it takes), as a stealth game warns of being noticed; when that guard is off the
## screen or behind, the mark sits at the screen's edge pointing to him. It goes once he is out of
## sight again and the guard forgets.

const ABOVE := 2.25
const EDGE := 70.0
const SIZE := 13.0
const CALM := Color(0.95, 0.95, 0.93)
const ALARM := Color(0.92, 0.16, 0.12)

var _marks: Array = []
var _camera: Camera3D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `marks`: one [where the guard stands, how full 0..1] for each guard seeing him; seen by
## `camera`.
func show_marks(marks: Array, camera: Camera3D) -> void:
	_marks = marks.filter(func(mark: Array) -> bool: return float(mark[1]) > 0.001)
	_camera = camera
	queue_redraw()


## How full each mark shown is.
func shares() -> Array:
	return _marks.map(func(mark: Array) -> float: return float(mark[1]))


func _draw() -> void:
	if _camera == null:
		return
	var frame := Rect2(Vector2.ZERO, size).grow(-EDGE)
	for mark: Array in _marks:
		var over: Vector3 = (mark[0] as Vector3) + Vector3.UP * ABOVE
		var share := clampf(float(mark[1]), 0.0, 1.0)
		var behind := _camera.is_position_behind(over)
		var at := _camera.unproject_position(over)
		if behind or not frame.has_point(at):
			var middle := size * 0.5
			var toward := (at - middle) * (-1.0 if behind else 1.0)
			if toward.length() < 1.0:
				toward = Vector2(0.0, 1.0)
			var reach := minf(frame.size.x * 0.5 / maxf(absf(toward.x), 0.001),
				frame.size.y * 0.5 / maxf(absf(toward.y), 0.001))
			at = middle + toward * reach
		_mark(at, share)


## A downward triangle (a warning), outlined, filled from its point up as `share` grows.
func _mark(at: Vector2, share: float) -> void:
	var colour := CALM.lerp(ALARM, share)
	var top_left := at + Vector2(-SIZE, -SIZE * 0.9)
	var top_right := at + Vector2(SIZE, -SIZE * 0.9)
	var tip := at + Vector2(0.0, SIZE * 0.9)
	var shadow := PackedVector2Array([top_left, top_right, tip])
	for index in range(shadow.size()):
		shadow[index] += Vector2(0.0, 2.0)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.45))
	var level := tip.lerp(top_left, share)
	var level_right := tip.lerp(top_right, share)
	if share > 0.02:
		draw_colored_polygon(PackedVector2Array([tip, level_right, level]), colour)
	draw_polyline(PackedVector2Array([top_left, top_right, tip, top_left]), colour, 2.5, true)
