extends Control
## The objective's marker in the world (#358, the mission guidance's step 2): an amber diamond
## over the place the objective sends the player, its distance under it, a soft shadow behind
## both; when the place is off the screen or behind him, an arrow at the screen's edge points
## the way to it. It fades out as he comes close (NEAR, nearer on foot), where the key prompt
## takes over, so it never sits on what he is doing.

const AMBER := Color(1.0, 0.72, 0.3)
const INK := Color("e8e9e4")
const EDGE := 60.0
const SIZE := 11.0
const NEAR_DRIVING := Vector2(10.0, 22.0)
const NEAR_ON_FOOT := Vector2(1.5, 4.0)
const LETTERING = preload("fonts/BarlowCondensed-SemiBold.ttf")

var screen_at := Vector2.INF
var on_edge := false
var _target := Vector3.INF
var _from := Vector3.ZERO
var _camera: Camera3D
var _on_foot := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Points at `target` (Vector3.INF for none) from `from`, seen by `camera`.
func point_at(target: Vector3, from: Vector3, camera: Camera3D, on_foot: bool) -> void:
	_target = target
	_from = from
	_camera = camera
	_on_foot = on_foot
	queue_redraw()


func shown() -> bool:
	return _target != Vector3.INF and _camera != null and _fade() > 0.0


func distance() -> float:
	if _target == Vector3.INF:
		return INF
	return Vector2(_target.x - _from.x, _target.z - _from.z).length()


func _fade() -> float:
	var near := NEAR_ON_FOOT if _on_foot else NEAR_DRIVING
	return smoothstep(near.x, near.y, distance())


func _draw() -> void:
	screen_at = Vector2.INF
	if not shown():
		return
	var fade := _fade()
	var behind := _camera.is_position_behind(_target)
	var at := _camera.unproject_position(_target)
	var frame := Rect2(Vector2.ZERO, size).grow(-EDGE)
	on_edge = behind or not frame.has_point(at)
	var words := "%d m" % roundi(distance())
	if not on_edge:
		screen_at = at
		_diamond(at, fade)
		_text(at + Vector2(0.0, SIZE + 20.0), words, fade)
		return
	var middle := size * 0.5
	var toward := (at - middle) * (-1.0 if behind else 1.0)
	if toward.length() < 1.0:
		toward = Vector2(0.0, 1.0)
	var reach := INF
	if absf(toward.x) > 0.001:
		reach = minf(reach, (frame.size.x * 0.5) / absf(toward.x))
	if absf(toward.y) > 0.001:
		reach = minf(reach, (frame.size.y * 0.5) / absf(toward.y))
	var way := toward.normalized()
	screen_at = middle + toward * reach
	var tip := screen_at + way * 12.0
	var side := Vector2(-way.y, way.x)
	var arrow := PackedVector2Array([tip, screen_at - way * 6.0 + side * 9.0,
		screen_at - way * 2.0, screen_at - way * 6.0 - side * 9.0])
	var shadow := PackedVector2Array()
	for point in arrow:
		shadow.append(point + Vector2(0.0, 2.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.5 * fade))
	draw_colored_polygon(arrow, Color(AMBER, fade))
	_text(screen_at - way * 30.0 + Vector2(0.0, 6.0), words, fade)


func _diamond(at: Vector2, fade: float) -> void:
	var points := PackedVector2Array([at + Vector2(0.0, -SIZE), at + Vector2(SIZE, 0.0),
		at + Vector2(0.0, SIZE), at + Vector2(-SIZE, 0.0), at + Vector2(0.0, -SIZE)])
	draw_circle(at, SIZE + 9.0, Color(0.0, 0.0, 0.0, 0.25 * fade))
	draw_polyline(points, Color(AMBER, fade), 3.0, true)
	draw_circle(at, 3.0, Color(AMBER, fade))


func _text(at: Vector2, words: String, fade: float) -> void:
	var width := LETTERING.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	var left := at - Vector2(width * 0.5, 0.0)
	draw_string(LETTERING, left + Vector2(1.0, 2.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, 19,
		Color(0.0, 0.0, 0.0, 0.6 * fade))
	draw_string(LETTERING, left, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(INK, fade))
