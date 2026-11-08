extends RefCounted

const LOOK_AHEAD := 6.0
const LOOK_TIME := 0.7
const GAIN := 0.45
const DEAD_ZONE := 0.02
const SEARCH := 20

var _road: RefCounted
var _index: int = 0


func _init(road: RefCounted, start: int) -> void:
	_road = road
	_index = start


func steer(van: Node3D, lateral_goal: float) -> float:
	var points: PackedVector3Array = _road.points
	var forward := Vector3(-van.global_basis.z.x, 0.0, -van.global_basis.z.z).normalized()
	var look := maxf(LOOK_AHEAD, absf(float(van.get("speed"))) * LOOK_TIME)
	var ahead := van.global_position + forward * look
	_index = _nearest(points, ahead)
	var right := Basis(Vector3.UP, _road.heading_at(_index)).x
	var lateral := (ahead - points[_index]).dot(right)
	var command := clampf((lateral - lateral_goal) * GAIN * LOOK_AHEAD / look, -1.0, 1.0)
	release()
	if command > DEAD_ZONE:
		Input.action_press("steer_left", command)
	elif command < -DEAD_ZONE:
		Input.action_press("steer_right", -command)
	return lateral


func release() -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")


func _nearest(points: PackedVector3Array, at: Vector3) -> int:
	var best := _index
	for offset in range(-SEARCH, SEARCH + 1):
		var candidate := clampi(_index + offset, 0, points.size() - 1)
		if at.distance_squared_to(points[candidate]) < at.distance_squared_to(points[best]):
			best = candidate
	return best
