extends Control

const MAP_RADIUS := 84.0
const MAP_MARGIN := 28.0
const MAP_SCALE := 2.2
const ROAD_WIDTH := 7.0
const OFFICE_SIZE := Vector2(6.0, 3.6)
const VAN_SIZE := Vector2(2.0, 5.5)
const MARKER_LIFT := 2.6
const MARKER_EDGE := 56.0
const NEAR := Vector2(4.0, 7.0)
const FONT_SIZE := 15
const INK := Color("e2e5df")
const ACCENT := Color("e3c799")
const PANEL := Color(0.03, 0.05, 0.06, 0.72)
const RIM := Color(0.74, 0.7, 0.6, 0.6)
const ROAD := Color(0.4, 0.43, 0.44, 0.95)
const OFFICE := Color(0.6, 0.53, 0.41, 0.95)

var road := PackedVector3Array()
var office := Transform3D.IDENTITY
var marker_at := Vector2.ZERO
var marker_on_edge := false
var _shown := false
var _camera: Camera3D
var _van: Node3D
var _ethan := Vector3.ZERO
var _forward := Vector2(0.0, -1.0)
var _right := Vector2(1.0, 0.0)
var _centre := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func guide(camera: Camera3D, van: Node3D, ethan: Vector3) -> void:
	_shown = true
	_camera = camera
	_van = van
	_ethan = ethan
	queue_redraw()


func hide_guide() -> void:
	if _shown:
		_shown = false
		queue_redraw()


func shown() -> bool:
	return _shown


func distance() -> float:
	if _van == null:
		return INF
	return Vector2(_van.global_position.x - _ethan.x, _van.global_position.z - _ethan.z).length()


func label() -> String:
	return "VAN  %d m" % roundi(distance())


func _draw() -> void:
	if not _shown or _camera == null or _van == null:
		return
	var view := -_camera.global_basis.z
	_forward = Vector2(view.x, view.z).normalized()
	_right = Vector2(-_forward.y, _forward.x)
	_centre = Vector2(size.x - MAP_MARGIN - MAP_RADIUS, MAP_MARGIN + MAP_RADIUS)
	_draw_map()
	_draw_marker()


func _draw_map() -> void:
	draw_circle(_centre, MAP_RADIUS, PANEL)
	var previous := Vector2.INF
	for point in road:
		var at := _to_map(point)
		if previous != Vector2.INF:
			_road_segment(previous, at)
		previous = at
	var corners := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(_to_map(office * Vector3(corner.x * OFFICE_SIZE.x * 0.5, 0.0,
			corner.y * OFFICE_SIZE.y * 0.5)))
	if _inside(corners):
		draw_colored_polygon(corners, OFFICE)
	var van := _to_map(_van.global_position)
	if van.distance_to(_centre) < MAP_RADIUS - 8.0:
		var body := PackedVector2Array()
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			body.append(_to_map(_van.global_transform * Vector3(corner.x * VAN_SIZE.x * 0.5, 0.0,
				corner.y * VAN_SIZE.y * 0.5)))
		draw_colored_polygon(body, ACCENT)
	else:
		var toward := (van - _centre).normalized()
		_arrow(_centre + toward * (MAP_RADIUS - 9.0), toward, 7.0, ACCENT)
	var north := Vector2(Vector2(0.0, -1.0).dot(_right), -Vector2(0.0, -1.0).dot(_forward))
	_text(_centre + north * (MAP_RADIUS - 11.0) + Vector2(0.0, 5.0), "N", RIM, 12)
	_arrow(_centre + Vector2(0.0, -4.0), Vector2(0.0, -1.0), 8.0, INK)
	draw_arc(_centre, MAP_RADIUS, 0.0, TAU, 72, RIM, 1.5, true)
	_text(_centre + Vector2(0.0, MAP_RADIUS + 22.0), label(), INK, FONT_SIZE)


func _draw_marker() -> void:
	var fade := smoothstep(NEAR.x, NEAR.y, distance())
	if fade <= 0.0:
		return
	var top := _van.global_position + Vector3.UP * MARKER_LIFT
	var behind := _camera.is_position_behind(top)
	var at := _camera.unproject_position(top)
	var frame := Rect2(Vector2.ZERO, size).grow(-MARKER_EDGE)
	var colour := Color(ACCENT, ACCENT.a * fade)
	marker_on_edge = behind or not frame.has_point(at)
	if not marker_on_edge:
		marker_at = at
		_arrow(at, Vector2(0.0, 1.0), 9.0, colour)
		_text(at + Vector2(0.0, -16.0), "VAN  ·  %d m" % roundi(distance()), Color(INK, fade),
			FONT_SIZE)
		return
	var screen_centre := size * 0.5
	var toward := (at - screen_centre) * (-1.0 if behind else 1.0)
	if toward.length() < 1.0:
		toward = Vector2(0.0, 1.0)
	var reach := INF
	if absf(toward.x) > 0.001:
		reach = minf(reach, (frame.size.x * 0.5) / absf(toward.x))
	if absf(toward.y) > 0.001:
		reach = minf(reach, (frame.size.y * 0.5) / absf(toward.y))
	marker_at = screen_centre + toward * reach
	_arrow(marker_at, toward.normalized(), 11.0, colour)
	_text(marker_at - toward.normalized() * 30.0 + Vector2(0.0, 5.0),
		"VAN  %d m" % roundi(distance()), Color(INK, fade), FONT_SIZE)


func _to_map(point: Vector3) -> Vector2:
	var offset := Vector2(point.x - _ethan.x, point.z - _ethan.z)
	return _centre + Vector2(offset.dot(_right), -offset.dot(_forward)) * MAP_SCALE


func _road_segment(from: Vector2, to: Vector2) -> void:
	var clipped := _clip(from, to)
	if clipped.is_empty():
		return
	draw_line(clipped[0], clipped[1], ROAD, ROAD_WIDTH, true)
	draw_circle(clipped[1], ROAD_WIDTH * 0.5, ROAD)


func _clip(from: Vector2, to: Vector2) -> PackedVector2Array:
	var limit := MAP_RADIUS - ROAD_WIDTH * 0.5
	var a := from - _centre
	var along := to - from
	var span := Vector2(0.0, 1.0)
	var qa := along.dot(along)
	if qa < 0.0001:
		return PackedVector2Array()
	var qb := 2.0 * a.dot(along)
	var qc := a.dot(a) - limit * limit
	var root := qb * qb - 4.0 * qa * qc
	if root < 0.0:
		return PackedVector2Array()
	root = sqrt(root)
	span.x = maxf(span.x, (-qb - root) / (2.0 * qa))
	span.y = minf(span.y, (-qb + root) / (2.0 * qa))
	if span.x >= span.y:
		return PackedVector2Array()
	return PackedVector2Array([from + along * span.x, from + along * span.y])


func _inside(points: PackedVector2Array) -> bool:
	for point in points:
		if point.distance_to(_centre) > MAP_RADIUS - 4.0:
			return false
	return true


func _arrow(tip: Vector2, toward: Vector2, length: float, colour: Color) -> void:
	var side := Vector2(-toward.y, toward.x) * length * 0.6
	var back := tip - toward * length
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), colour)


func _text(at: Vector2, words: String, colour: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := at - Vector2(width * 0.5, 0.0)
	draw_string(font, origin + Vector2(1.0, 1.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, Color(0.0, 0.0, 0.0, 0.8 * colour.a))
	draw_string(font, origin, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
