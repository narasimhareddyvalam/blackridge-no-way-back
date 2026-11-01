extends Control

const MAP := Rect2(37, 55, 310, 148)
const MAP_MARGIN := 10.0
const ROAD_STEP := 3

var vehicle: CharacterBody3D
var destination := Vector3(109, 0, 20)
var instruction: String = "EAST ROAD"
var road := PackedVector3Array():
	set(value):
		road = value
		_fit_road()
var _elapsed: float = 0.0
var _font := ThemeDB.fallback_font
var _road_line := PackedVector2Array()
var _origin := Vector2.ZERO
var _scale: float = 1.25


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > 0.15:
		_elapsed = 0.0
		queue_redraw()


func _draw() -> void:
	if not is_instance_valid(vehicle):
		return
	draw_rect(Rect2(0, 0, 384, 256), Color("0c1b24"))
	draw_string(_font, Vector2(17, 27), instruction, 0, -1, 19, Color("d8dacb"))
	draw_style_box(_panel_style(), MAP)
	if _road_line.size() > 1:
		draw_polyline(_road_line, Color("677e84"), 3.0, true)
	var position_2d := _map_point(vehicle.global_position)
	var target := _map_point(destination)
	draw_circle(target, 7, Color("d9ac70"))
	draw_circle(target, 12, Color("d9ac70"), false, 2, true)
	var heading := Vector2(-vehicle.global_basis.z.x, -vehicle.global_basis.z.z)
	var side := heading.orthogonal()
	var arrow := PackedVector2Array([position_2d + heading * 12,
		position_2d - heading * 7 + side * 7, position_2d - heading * 7 - side * 7])
	draw_colored_polygon(arrow, Color("b0e2db"))
	draw_string(_font, Vector2(17, 239), "DEPOT  /  %d m" % int(
		vehicle.global_position.distance_to(destination)), 0, -1, 18, Color("8fa7af"))


func _map_point(at: Vector3) -> Vector2:
	return _origin + Vector2(at.x, at.z) * _scale


func _fit_road() -> void:
	_road_line = PackedVector2Array()
	if road.is_empty():
		return
	var low := Vector2(road[0].x, road[0].z)
	var high := low
	for point in road:
		low = low.min(Vector2(point.x, point.z))
		high = high.max(Vector2(point.x, point.z))
	var room := MAP.size - Vector2.ONE * MAP_MARGIN * 2.0
	_scale = minf(room.x / maxf(high.x - low.x, 1.0), room.y / maxf(high.y - low.y, 1.0))
	_origin = MAP.get_center() - (low + high) * 0.5 * _scale
	for index in range(0, road.size(), ROAD_STEP):
		_road_line.append(_map_point(road[index]))
	_road_line.append(_road_line[0])


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10202a")
	style.set_corner_radius_all(10)
	return style
