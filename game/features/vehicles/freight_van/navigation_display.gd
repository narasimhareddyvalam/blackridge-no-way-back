extends Control

var vehicle: CharacterBody3D
var destination := Vector3(109, 0, 20)
var instruction: String = "EAST ROAD"
var _elapsed: float = 0.0
var _font := ThemeDB.fallback_font


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
	var map := Rect2(37, 55, 310, 148)
	draw_style_box(_road_style(), map)
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
	return Vector2(192 + at.x * 1.25, 130 + at.z * 0.95)


func _road_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10202a")
	style.border_color = Color("677e84")
	style.set_border_width_all(5)
	style.set_corner_radius_all(25)
	return style
