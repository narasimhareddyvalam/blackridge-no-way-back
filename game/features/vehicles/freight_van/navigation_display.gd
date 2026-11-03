extends Control

const SIZE := Vector2(768, 400)
const RAIL := 72.0
const MAP := Rect2(72, 0, 696, 400)
const VAN_AT := Vector2(0.62, 0.76)
const MARGIN := 16.0
const CARD_WIDTH := 300.0
const NEAR_SCALE := 3.0
const FAR_SCALE := 1.8
const ZOOM_SPEEDS := Vector2(4.0, 17.0)
const TURN_RATE := 5.0
const ZOOM_RATE := 1.5
const REDRAW := 1.0 / 30.0
const SEARCH := 40
const LOST := 25.0
const ROAD_STEP := 2
const LABEL_AHEAD := 20
const HAIRPIN_WARNING := 150.0
const WRONG_WAY_SECONDS := 1.5
const ARRIVED_WITHIN := 12.0
const CRUISE := 40.0 / 3.6
const HAIRPIN_PACE := 18.0 / 3.6
const VALLEY_FROM := 950
const DESTINATION := "Freight depot"
const RUN_SHEET: Array[String] = ["RUN SHEET · NIGHT", "BR 048 · E. COLE",
	"Freight depot, bay 3", "14 pallets, sawn timber", "Over the pass · valley road closed"]
const LAND := Color("15191c")
const ROAD := Color("2e3439")
const ROUTE := Color("4c8dff")
const RAIL_COLOUR := Color("0d0f11")
const CARD := Color("1d2126")
const BUTTON := Color("1f2328")
const ACTIVE := Color("2a5bd7")
const CALLING := Color("1f8a4c")
const HANG_UP := Color("d4403a")
const INK := Color("f2f4f5")
const SOFT := Color("c5cbd0")
const DIM := Color("9aa3a9")
const AMBER := Color("e3c799")
const TALKING := Color("7fd6a5")
const WARNING := Color("f2c230")
const TRACK := Color("2b3036")

var vehicle: CharacterBody3D
var caller: String = ""
var call_seconds: float = -1.0
var call_state: String = ""
var wrong_way: bool = false
var arrived: bool = false
var route_index: int = -1
var to_turn: float = 0.0
var seconds_left: float = 0.0
var next_hairpin: float = -1.0
var progress: float = 0.0
var map_yaw: float = 0.0
var map_scale: float = NEAR_SCALE
var drawn_road := PackedVector2Array()
var _road: RefCounted
var _flat := PackedVector2Array()
var _distance := PackedFloat32Array()
var _time_to_depot := PackedFloat32Array()
var _hairpins := PackedInt32Array()
var _depot := -1
var _start := 0
var _depot_at := Vector2.ZERO
var _since_draw: float = 0.0
var _wrong_for: float = 0.0
var _clock: float = 0.0
var _fonts := {}


func _ready() -> void:
	for weight in [400, 600, 700]:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["SF Pro Text", "SF Pro", "Helvetica Neue", "Arial"])
		font.font_weight = weight
		_fonts[weight] = font


func follow(road: RefCounted, depot: Vector3, start: Vector3) -> void:
	_road = road
	var points: PackedVector3Array = road.points
	_flat = PackedVector2Array()
	_distance = PackedFloat32Array()
	_hairpins = PackedInt32Array()
	var travelled := 0.0
	for index in range(points.size()):
		_flat.append(Vector2(points[index].x, points[index].z))
		if index > 0:
			travelled += _flat[index].distance_to(_flat[index - 1])
		_distance.append(travelled)
		if road.is_hairpin(index) and not road.is_hairpin(index - 1):
			_hairpins.append(index)
	_depot_at = Vector2(depot.x, depot.z)
	_depot = _nearest_overall(_depot_at)
	_start = _nearest_overall(Vector2(start.x, start.z))
	_time_to_depot = PackedFloat32Array()
	_time_to_depot.resize(points.size())
	for index in range(_depot - 1, -1, -1):
		var pace := HAIRPIN_PACE if road.is_hairpin(index) else CRUISE
		_time_to_depot[index] = _time_to_depot[index + 1] \
			+ (_distance[index + 1] - _distance[index]) / pace
	route_index = -1


func ring(name: String, answers_itself: bool) -> void:
	caller = name
	call_seconds = -1.0
	call_state = "auto" if answers_itself else "ringing"


func talk() -> void:
	call_state = "talking"
	call_seconds = 0.0


func miss(name: String) -> void:
	caller = name
	call_seconds = -1.0
	call_state = "missed"


func end_call() -> void:
	caller = ""
	call_seconds = -1.0
	call_state = ""


func _process(delta: float) -> void:
	_clock += delta
	_since_draw += delta
	if _since_draw < REDRAW or not is_instance_valid(vehicle) or _flat.is_empty():
		return
	_track(_since_draw)
	_since_draw = 0.0
	queue_redraw()


func _track(delta: float) -> void:
	var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
	route_index = _nearest_near(at) if route_index >= 0 else _nearest_overall(at)
	if at.distance_to(_flat[route_index]) > LOST:
		route_index = _nearest_overall(at)
	var forward := Vector2(-vehicle.global_basis.z.x, -vehicle.global_basis.z.z).normalized()
	var along := (_flat[(route_index + 1) % _flat.size()] - _flat[route_index]).normalized()
	var speed := absf(float(vehicle.speed))
	var backwards := forward.dot(along) * signf(float(vehicle.speed)) < -0.3 and speed > 1.5
	_wrong_for = _wrong_for + delta if backwards else maxf(0.0, _wrong_for - delta * 2.0)
	arrived = at.distance_to(_depot_at) < ARRIVED_WITHIN
	wrong_way = not arrived and (_wrong_for > WRONG_WAY_SECONDS or route_index > _depot + 3)
	var ahead := mini(route_index, _depot)
	to_turn = _distance[_depot] - _distance[ahead]
	seconds_left = _time_to_depot[ahead]
	progress = clampf((_distance[ahead] - _distance[_start])
		/ maxf(_distance[_depot] - _distance[_start], 1.0), 0.0, 1.0)
	next_hairpin = -1.0
	for start in _hairpins:
		if start > route_index:
			var gap := _distance[start] - _distance[route_index]
			if gap <= HAIRPIN_WARNING and not _road.is_hairpin(route_index):
				next_hairpin = gap
			break
	var yaw := atan2(-forward.x, -forward.y)
	map_yaw += angle_difference(map_yaw, yaw) * minf(1.0, TURN_RATE * delta)
	var zoom := clampf(inverse_lerp(ZOOM_SPEEDS.x, ZOOM_SPEEDS.y, speed), 0.0, 1.0)
	map_scale = lerpf(map_scale, lerpf(NEAR_SCALE, FAR_SCALE, zoom), minf(1.0, ZOOM_RATE * delta))


func _draw() -> void:
	if not is_instance_valid(vehicle) or _flat.is_empty() or route_index < 0:
		return
	draw_rect(Rect2(Vector2.ZERO, SIZE), LAND)
	_draw_map()
	_draw_rail()
	_draw_turn_card()
	if next_hairpin >= 0.0:
		_draw_hairpin_chip()
	var calling := caller != ""
	if calling:
		_draw_call_card()
	_draw_run_sheet(calling)


func _draw_map() -> void:
	drawn_road = _runs(0, _flat.size(), ROAD, 13.0, true)
	if not wrong_way or route_index <= _depot:
		_runs(route_index, _depot + 1, ROUTE, 9.0, false)
	var label_at := _to_map(_flat[mini(route_index + LABEL_AHEAD, _flat.size() - 1)])
	if MAP.grow(-40.0).has_point(label_at):
		_text(label_at + Vector2(14, 5), _road_name(), 14, SOFT, 600, LAND)
	var van := MAP.position + MAP.size * VAN_AT
	var turn := float(vehicle.global_rotation.y) - map_yaw
	draw_circle(van, 17.0, Color(ROUTE, 0.25))
	var chevron := PackedVector2Array([Vector2(0, -15), Vector2(11, 11), Vector2(0, 5),
		Vector2(-11, 11)])
	var shape := PackedVector2Array()
	for point in chevron:
		shape.append(van + point.rotated(-turn))
	draw_colored_polygon(shape, INK)
	shape.append(shape[0])
	draw_polyline(shape, ACTIVE, 2.0, true)


func _runs(from: int, to: int, colour: Color, width: float, record: bool) -> PackedVector2Array:
	var seen := PackedVector2Array()
	var run := PackedVector2Array()
	var room := MAP.grow(40.0)
	var index := from
	while index <= to:
		var point := _to_map(_flat[index % _flat.size()])
		if room.has_point(point):
			run.append(point)
			if record and MAP.has_point(point):
				seen.append(point)
		elif run.size() > 1:
			draw_polyline(run, colour, width, true)
			run = PackedVector2Array()
		else:
			run = PackedVector2Array()
		index += ROAD_STEP if index + ROAD_STEP <= to or index == to else to - index
	if run.size() > 1:
		draw_polyline(run, colour, width, true)
	return seen


func _to_map(point: Vector2) -> Vector2:
	var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
	var forward := Vector2(-sin(map_yaw), -cos(map_yaw))
	var right := Vector2(cos(map_yaw), -sin(map_yaw))
	var offset := point - at
	return MAP.position + MAP.size * VAN_AT \
		+ Vector2(offset.dot(right), -offset.dot(forward)) * map_scale


func _draw_rail() -> void:
	draw_rect(Rect2(0, 0, RAIL, SIZE.y), RAIL_COLOUR)
	_centred(Vector2(RAIL * 0.5, 30), vehicle.clock_text(), 16, INK, 600)
	_centred(Vector2(RAIL * 0.5, 48), "7°C", 13, DIM, 400)
	var talking := caller != "" and call_state != "missed"
	_button(Vector2(12, 64), ACTIVE if not talking else BUTTON)
	_icon_route(Vector2(36, 88), INK if not talking else SOFT)
	_button(Vector2(12, 124), CALLING if talking else BUTTON)
	_icon_phone(Vector2(36, 148), INK if talking else SOFT, 1.0)
	_button(Vector2(12, 184), BUTTON)
	_icon_music(Vector2(36, 208), SOFT)
	_button(Vector2(12, SIZE.y - 64), BUTTON)
	for corner in [Vector2(-9, -9), Vector2(2, -9), Vector2(-9, 2), Vector2(2, 2)]:
		draw_rect(Rect2(Vector2(36, SIZE.y - 40) + corner, Vector2(7, 7)), SOFT)


func _draw_turn_card() -> void:
	var at := MAP.position + Vector2(MARGIN, MARGIN)
	var heading := _distance_text(to_turn)
	var detail := DESTINATION
	if arrived:
		heading = "Arrived"
		detail = RUN_SHEET[2]
	elif wrong_way:
		heading = "Turn around"
		detail = _road_name()
	var width := 92.0 + maxf(_width(heading, 34, 700), _width(detail, 16, 600))
	_card(Rect2(at, Vector2(width, 80)))
	if wrong_way and not arrived:
		_icon_turn_around(at + Vector2(16, 12), INK)
	else:
		_icon_turn_left(at + Vector2(16, 14), INK)
	_text(at + Vector2(78, 42), heading, 34, INK, 700)
	_text(at + Vector2(78, 64), detail, 16, SOFT, 600)


func _draw_hairpin_chip() -> void:
	var centre := Vector2(MAP.end.x - MARGIN - 32.0, MARGIN + 32.0)
	draw_circle(centre, 32.0, CARD)
	var diamond := PackedVector2Array()
	for corner in [Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0)]:
		diamond.append(centre + Vector2(0, -6) + corner)
	draw_colored_polygon(diamond, WARNING)
	var glyph := PackedVector2Array()
	for step in range(9):
		var angle := PI + PI * step / 8.0
		glyph.append(centre + Vector2(0, -8) + Vector2(cos(angle), sin(angle)) * 3.5)
	glyph.insert(0, centre + Vector2(-3.5, 0))
	glyph.append(centre + Vector2(3.5, -4))
	draw_polyline(glyph, Color.BLACK, 1.8, true)
	draw_polyline(PackedVector2Array([centre + Vector2(1.5, -5.5), centre + Vector2(3.5, -3.5),
		centre + Vector2(5.5, -5.5)]), Color.BLACK, 1.8, true)
	_centred(centre + Vector2(0, 22), _distance_text(next_hairpin), 13, INK, 600)


func _draw_call_card() -> void:
	var at := MAP.position + Vector2(MARGIN, 112)
	if call_state == "missed":
		_card(Rect2(at, Vector2(CARD_WIDTH, 48)))
		_icon_phone(at + Vector2(26, 24), HANG_UP, 0.8)
		_text(at + Vector2(48, 30), "Missed call · " + caller.capitalize(), 16, INK, 600)
		return
	_card(Rect2(at, Vector2(CARD_WIDTH, 76)))
	var pulse := 1.0 + 0.12 * sin(_clock * 8.0) if call_seconds < 0.0 else 1.0
	draw_circle(at + Vector2(40, 38), 24.0 * pulse, Color("3a4a5c"))
	_centred(at + Vector2(40, 46), caller.substr(0, 1), 22, INK, 600)
	_text(at + Vector2(76, 34), caller.capitalize(), 21, INK, 700)
	if call_seconds >= 0.0:
		_text(at + Vector2(76, 58), "Hands-free · %02d:%02d" % [int(call_seconds) / 60,
			int(call_seconds) % 60], 15, TALKING, 400)
		draw_circle(at + Vector2(228, 38), 22.0, TRACK)
		_icon_microphone(at + Vector2(228, 38), INK)
		draw_circle(at + Vector2(276, 38), 22.0, HANG_UP)
		_icon_phone(at + Vector2(276, 40), INK, 0.8)
	elif call_state == "auto":
		_text(at + Vector2(76, 58), "Answering automatically", 15, TALKING, 400)
	else:
		_text(at + Vector2(76, 58), "Incoming call", 15, SOFT, 400)
		var key := Rect2(at + Vector2(212, 22), Vector2(32, 32))
		var style := StyleBoxFlat.new()
		style.bg_color = INK
		style.set_corner_radius_all(6)
		draw_style_box(style, key)
		_centred(key.get_center() + Vector2(0, 7), "T", 18, CARD, 700)
		_text(at + Vector2(250, 44), "Answer", 15, INK, 600)


func _draw_run_sheet(compact: bool) -> void:
	var height := 150.0 if compact else 200.0
	var at := Vector2(MAP.position.x + MARGIN, SIZE.y - MARGIN - height)
	_card(Rect2(at, Vector2(CARD_WIDTH, height)))
	_text(at + Vector2(18, 26), RUN_SHEET[0], 12, AMBER, 600)
	_text(at + Vector2(CARD_WIDTH - 18 - _width(RUN_SHEET[1], 12, 600), 26), RUN_SHEET[1], 12,
		DIM, 600)
	_text(at + Vector2(18, 54), RUN_SHEET[2], 21, INK, 600)
	var y := 54.0
	if not compact:
		_text(at + Vector2(18, 76), RUN_SHEET[3], 15, SOFT, 400)
		_text(at + Vector2(18, 96), RUN_SHEET[4], 14, DIM, 400)
		y = 96.0
	var bar := Rect2(at + Vector2(18, y + 16), Vector2(CARD_WIDTH - 36, 6))
	draw_rect(bar, TRACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), AMBER)
	_text(at + Vector2(18, y + 38), "Lumber yard", 12, DIM, 400)
	_text(at + Vector2(CARD_WIDTH - 18 - _width("Depot", 12, 400), y + 38), "Depot", 12, DIM,
		400)
	var eta := float(vehicle.clock) + seconds_left
	var arrive := "%02d:%02d" % [int(eta / 3600.0) % 24, int(eta / 60.0) % 60]
	_text(at + Vector2(18, height - 16), arrive, 24, INK, 700)
	var minutes := maxi(1, ceili(seconds_left / 60.0))
	_text(at + Vector2(26 + _width(arrive, 24, 700), height - 16), "%d min · %s" % [minutes,
		_distance_text(to_turn)], 15, SOFT, 400)


func _road_name() -> String:
	return "Valley Road" if route_index >= VALLEY_FROM else "Hill Road"


func _distance_text(metres: float) -> String:
	if metres >= 1000.0:
		return "%.1f km" % (metres / 1000.0)
	if metres >= 100.0:
		return "%d m" % (roundi(metres / 10.0) * 10)
	return "%d m" % (roundi(metres / 5.0) * 5)


func _nearest_overall(at: Vector2) -> int:
	var best := 0
	for index in range(_flat.size()):
		if at.distance_squared_to(_flat[index]) < at.distance_squared_to(_flat[best]):
			best = index
	return best


func _nearest_near(at: Vector2) -> int:
	var best := route_index
	for offset in range(-SEARCH, SEARCH + 1):
		var index := posmod(route_index + offset, _flat.size())
		if at.distance_squared_to(_flat[index]) < at.distance_squared_to(_flat[best]):
			best = index
	return best


func _card(area: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD
	style.set_corner_radius_all(22)
	style.anti_aliasing = true
	draw_style_box(style, area)


func _button(at: Vector2, colour: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(14)
	draw_style_box(style, Rect2(at, Vector2(48, 48)))


func _text(at: Vector2, words: String, font_size: int, colour: Color, weight: int,
		outline := Color(0, 0, 0, 0)) -> void:
	var font: Font = _fonts[weight]
	if outline.a > 0.0:
		draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6,
			outline)
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _centred(at: Vector2, words: String, font_size: int, colour: Color, weight: int) -> void:
	_text(at - Vector2(_width(words, font_size, weight) * 0.5, 0), words, font_size, colour,
		weight)


func _width(words: String, font_size: int, weight: int) -> float:
	return (_fonts[weight] as Font).get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size).x


func _icon_turn_left(at: Vector2, colour: Color) -> void:
	var stem := PackedVector2Array([at + Vector2(34, 50), at + Vector2(34, 26)])
	for step in range(7):
		var angle := PI * 0.5 * step / 6.0
		stem.append(at + Vector2(30, 26) + Vector2(cos(angle), -sin(angle)) * 4.0)
	stem.append(at + Vector2(12, 22))
	draw_polyline(stem, colour, 6.0, true)
	draw_polyline(PackedVector2Array([at + Vector2(20, 13), at + Vector2(11, 22),
		at + Vector2(20, 31)]), colour, 6.0, true)


func _icon_turn_around(at: Vector2, colour: Color) -> void:
	var path := PackedVector2Array([at + Vector2(14, 54), at + Vector2(14, 26)])
	for step in range(13):
		var angle := PI - PI * step / 12.0
		path.append(at + Vector2(28, 26) + Vector2(cos(angle), -sin(angle)) * 14.0)
	path.append(at + Vector2(42, 40))
	draw_polyline(path, colour, 6.0, true)
	draw_polyline(PackedVector2Array([at + Vector2(33, 32), at + Vector2(42, 42),
		at + Vector2(51, 32)]), colour, 6.0, true)


func _icon_route(centre: Vector2, colour: Color) -> void:
	draw_colored_polygon(PackedVector2Array([centre + Vector2(0, -10), centre + Vector2(8, 10),
		centre + Vector2(0, 5), centre + Vector2(-8, 10)]), colour)


func _icon_phone(centre: Vector2, colour: Color, factor: float) -> void:
	var points := PackedVector2Array()
	for point in [Vector2(-7, -9), Vector2(-3, -9), Vector2(-1, -4), Vector2(-4, -2),
			Vector2(2, 4), Vector2(4, 1), Vector2(9, 3), Vector2(9, 7), Vector2(6, 9),
			Vector2(-9, -6)]:
		points.append(centre + point * factor)
	points.append(points[0])
	draw_polyline(points, colour, 2.0, true)


func _icon_music(centre: Vector2, colour: Color) -> void:
	draw_polyline(PackedVector2Array([centre + Vector2(-4, 7), centre + Vector2(-4, -8),
		centre + Vector2(7, -10), centre + Vector2(7, 5)]), colour, 2.0, true)
	draw_circle(centre + Vector2(-7, 7), 3.0, colour)
	draw_circle(centre + Vector2(4, 5), 3.0, colour)


func _icon_microphone(centre: Vector2, colour: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = colour
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	draw_style_box(style, Rect2(centre + Vector2(-3, -9), Vector2(6, 11)))
	draw_arc(centre + Vector2(0, -2), 7.0, 0.0, PI, 10, colour, 2.0, true)
	draw_line(centre + Vector2(0, 5), centre + Vector2(0, 9), colour, 2.0, true)
