extends Control
## The reversing camera's parking guides (#287), as a real van's camera draws them: two lines
## the van's width apart running back from its bumper, red to 0.5 m, yellow to 1 m and green to
## 3 m, with a mark at each. They are worked out on the ground itself: each point is found under
## where it lies behind the van and drawn where the camera showing this picture sees it, so the
## lines lie on the ground in true perspective and follow it as it slopes; a piece the camera
## cannot see, behind something standing there, is left out, and the lines stop where the ground
## gives way to something standing on it. Across them runs the red stop line, STOP_LINE behind
## the bumper: backing onto a loading bay, the van is docked once it reaches the dock's bumpers,
## the one distance the bay's verdict and its lift's bridge plate are built to (`van_bay.gd`).

const BUMPER := 3.012
## Where a dock's bumpers stand when the van is docked: near enough that the lift's 0.91 m bridge
## plate, laid from the dock to the van's sill at its middle, rests at least 0.10 m (4 in) onto its
## floor even with the van 3° from square, the most a bay allows.
const STOP_LINE := 0.10
const HALF_WIDTH := 1.0
const REACH := 3.0
const STEP := 0.25
const TICK := 0.25
const ABOVE := 0.01
const PROBE := 1.5
const RISE_MOST := 0.12
const SEEN_BY := 0.03
const BANDS: Array[float] = [0.5, 1.0, 3.0]
const COLOURS: Array[Color] = [Color("e0483e"), Color("f2c230"), Color("4fd18b")]
const MARKS: Array[float] = [0.5, 1.0, 2.0, 3.0]
const LINE := 0.005
const WORLD := 1
const SEEN_MASK := 3

## The van whose bumper the guides start from, its own frame's +z pointing back.
var van: CollisionObject3D

var _segments: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	_segments = _work_out()
	queue_redraw()


## The pieces drawn: each with its ends on the ground (`from`, `to`), where they are drawn
## (`from_drawn`, `to_drawn`), its `colour`, its `kind` ("side" or "mark") and, for a mark, its
## `distance` behind the bumper.
func segments() -> Array:
	if is_visible_in_tree():
		_segments = _work_out()
	return _segments


func _draw() -> void:
	var width := maxf(size.y * LINE, 1.5)
	for segment: Dictionary in _segments:
		draw_line(segment["from_drawn"], segment["to_drawn"], segment["colour"], width, true)


func _work_out() -> Array:
	var found: Array = []
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null or not is_instance_valid(van):
		return found
	var space := van.get_world_3d().direct_space_state
	_stop_line(found, camera, space)
	for side: float in [-1.0, 1.0]:
		var line := _ground_line(space, side * HALF_WIDTH)
		for index in range(line.size() - 1):
			var distance := (index + 0.5) * STEP
			_add(found, camera, space, line[index], line[index + 1], _colour(distance), "side",
				distance)
		for mark in MARKS:
			var index := roundi(mark / STEP)
			if index >= line.size():
				continue
			var inward := _ground_point(space, side * (HALF_WIDTH - TICK), mark,
				(line[index] as Vector3).y)
			if inward != Vector3.INF:
				_add(found, camera, space, line[index], inward, _colour(mark - 0.001), "mark",
					mark)
	return found


## The red stop line across the van's width, STOP_LINE behind its bumper, on the ground.
func _stop_line(found: Array, camera: Camera3D, space: PhysicsDirectSpaceState3D) -> void:
	var last := Vector3.INF
	var count := roundi(HALF_WIDTH * 2.0 / STEP)
	for index in range(count + 1):
		var x := -HALF_WIDTH + index * STEP
		var point := _ground_point(space, x, STOP_LINE,
			last.y if last != Vector3.INF else INF)
		if point != Vector3.INF and last != Vector3.INF:
			_add(found, camera, space, last, point, COLOURS[0], "stop", STOP_LINE)
		last = point


## Points on the ground every STEP back from the bumper at `x` across the van, stopping where
## the ground gives way to something standing on it or there is no ground.
func _ground_line(space: PhysicsDirectSpaceState3D, x: float) -> Array:
	var points: Array = []
	var last := INF
	var count := roundi(REACH / STEP)
	for index in range(count + 1):
		var point := _ground_point(space, x, index * STEP, last)
		if point == Vector3.INF:
			break
		points.append(point)
		last = point.y
	return points


func _ground_point(space: PhysicsDirectSpaceState3D, x: float, behind: float,
		last: float) -> Vector3:
	var at := van.to_global(Vector3(x, 0.0, BUMPER + behind))
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * PROBE,
		at + Vector3.DOWN * PROBE, WORLD)
	ray.exclude = [van.get_rid()]
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		return Vector3.INF
	var point: Vector3 = hit["position"]
	if last != INF and absf(point.y - last) > RISE_MOST:
		return Vector3.INF
	return point + Vector3.UP * ABOVE


func _add(found: Array, camera: Camera3D, space: PhysicsDirectSpaceState3D, from: Vector3,
		to: Vector3, colour: Color, kind: String, distance: float) -> void:
	if not _seen(camera, space, from) or not _seen(camera, space, to):
		return
	found.append({"from": from, "to": to, "from_drawn": camera.unproject_position(from),
		"to_drawn": camera.unproject_position(to), "colour": colour, "kind": kind,
		"distance": distance})


## Whether the camera sees `point`: in front of it, with nothing standing between.
func _seen(camera: Camera3D, space: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	if camera.is_position_behind(point):
		return false
	var eye := camera.global_position
	var ray := PhysicsRayQueryParameters3D.create(eye, point, SEEN_MASK)
	ray.exclude = [van.get_rid()]
	var hit := space.intersect_ray(ray)
	return hit.is_empty() or (hit["position"] as Vector3).distance_to(point) < SEEN_BY


func _colour(distance: float) -> Color:
	for index in range(BANDS.size()):
		if distance < BANDS[index]:
			return COLOURS[index]
	return COLOURS[COLOURS.size() - 1]
