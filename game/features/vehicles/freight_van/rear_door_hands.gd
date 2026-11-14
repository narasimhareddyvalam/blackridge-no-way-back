extends Node
## The van's rear doors worked by Ethan's own hands (#245–#247, part B), as a driver works a
## Daily's 270-degree doors. To open them he takes the right door's handle, pulls it open as he
## steps back, walks round its free edge and pushes it on; it swings round on its hinges until the
## stay on the van's side catches it with a small bounce. Then the left door the same way, by its
## edge, once the right is out of its way. To close them, the left first, for the right door's lip
## laps over it: from beside the van, just past its free edge and out of its reach, he tugs it off
## its stay and sends it swinging back round, then walks it shut from its outer side and shoves it
## the last bit onto its latch; then the right. A door turns with
## his hand on it or swings freely against its hinges' friction; between his stances he walks by
## his own walk, forward or back (`driver.gd`, `door_step()`), one hand held to the door by IK
## (`door_hand()`). The van counts the doors open once both are on their stays, and shut once
## both are latched. Positions are worked in the van's frame and handed over in the world.

signal finished(open: bool)

const SWING := PI * 1.5
const GRIP_HEIGHT := 1.1
const STAND := 0.36
const BESIDE := 0.17
const FACE_OUT := 0.04
const EDGE_IN := 0.08
const PULL_TO := deg_to_rad(65.0)
const PULL_SECONDS := 2.2
const REACH_SECONDS := 0.3
const LET_GO_SECONDS := 0.2
const PUSH_SECONDS := 0.35
const PUSH_BY := deg_to_rad(12.0)
const FRICTION := 0.85
const ARRIVE := 1.0
const BOUNCE := 0.3
const STAY_PULL := 40.0
const STAY_DAMP := 6.0
const UNHOOK_TO := deg_to_rad(250.0)
const UNHOOK_SECONDS := 0.28
const EDGE_STAND := 1.35
const EDGE_BACK := deg_to_rad(15.0)
const FACE_TURNS := 0.8
const SWUNG_TO := deg_to_rad(105.0)
const SHUT_SECONDS := 2.2
const SHUT_FROM := deg_to_rad(25.0)
const SHOVE_BY := deg_to_rad(8.0)
const LATCH_SPEED := 1.2
const WALK_MOST := 1.5
const WALK_ACCEL := 3.0
const ARRIVED := 0.03
const ROUND_BY := 0.62
const ROUND_POINTS := 7
const CORNER := Vector2(1.8, 3.5)
const SIDE_LANE := Vector2(1.95, 2.3)
const SHORT_PACE := 0.6
const STAND_BACK := Vector3(0.0, 0.0, 3.95)
const VAN_REAR := 3.0
const VAN_SIDE := 1.15
const VAN_HALF := 1.02
const REAR_FACE := 3.01
const KEEP_OFF := 0.32

var van: Node3D
var _driver: Node3D
var _doors: Array[Node3D] = []
var _hinges: Array[Vector3] = []
var _grips := {}
var _angles: Array[float] = [0.0, 0.0]
var _spins: Array[float] = [0.0, 0.0]
var _ends: Array[float] = [-1.0, -1.0]
var _frictions: Array[float] = [FRICTION, FRICTION]
var _caught: Array[bool] = [false, false]
var _plan: Array[Dictionary] = []
var _step := 0
var _clock := 0.0
var _opening := true
var _held := {}
var _hand := 0.0
var _path: Array[Vector3] = []
var _guide := Vector3.ZERO
var _guide_speed := 0.0
var _facing := Vector3.BACK
var _walk_facing := Vector3.ZERO
var _long_walk := false
var _from := 0.0


func _ready() -> void:
	set_physics_process(false)


## Whether a job on the doors is under way.
func busy() -> bool:
	return not _plan.is_empty()


## While his hand is on a door: which door (0 left, 1 right), which hand, and where it holds it,
## in the world; otherwise empty.
func hold() -> Dictionary:
	return _held.duplicate()


## Each door's angle from shut (0 left, 1 right), in radians, while a job is under way.
func angles() -> Array[float]:
	var none: Array[float] = []
	return _angles.duplicate() if busy() else none


## Ethan (`driver`) opens the doors, both shut, or closes them, both open on their stays.
func start(driver: Node3D, opening: bool, doors: Array[Node3D], extents: Array[AABB]) -> bool:
	if busy() or driver == null:
		return false
	_driver = driver
	_opening = opening
	_doors = doors
	_hinges.clear()
	for index in range(2):
		_hinges.append(van.to_local(_doors[index].global_position))
	_grips = {"outer": [], "inner": [], "edge": []}
	for index in range(2):
		var box := extents[index]
		var edge := box.end.x if index == 0 else box.position.x
		var inward := -EDGE_IN if index == 0 else EDGE_IN
		var height := GRIP_HEIGHT - _hinges[index].y
		(_grips["outer"] as Array).append(Vector3(edge + inward, height, box.end.z + FACE_OUT))
		(_grips["inner"] as Array).append(Vector3(edge + inward * 1.5, height,
			box.position.z - FACE_OUT))
		(_grips["edge"] as Array).append(Vector3(edge - inward * 0.25, height,
			(box.position.z + box.end.z) / 2.0))
	var shut := 0.0 if opening else SWING
	_angles = [shut, shut]
	_spins = [0.0, 0.0]
	_ends = [-1.0, -1.0]
	_caught = [false, false]
	_plan = _opening_plan() if opening else _closing_plan()
	_step = 0
	_held = {}
	_hand = 0.0
	_guide = van.to_local(_driver.global_position)
	_guide.y = 0.0
	_guide_speed = 0.0
	_facing = -Vector3.BACK
	_driver.set("handling", true)
	_begin(_plan[0])
	set_physics_process(true)
	return true


## Stops a job at once, the doors left as they are (when the van is put back on the road).
func cancel() -> void:
	if not busy():
		return
	_plan.clear()
	_held = {}
	set_physics_process(false)
	if is_instance_valid(_driver):
		_driver.call("door_hand", 0, Vector3.ZERO, 0.0)
		_driver.call("door_hand", 1, Vector3.ZERO, 0.0)
		_driver.set("handling", false)


func _opening_plan() -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for door in [1, 0]:
		var hand: int = door
		plan.append({"do": "go", "door": door, "face": "outer", "hand": hand, "angle": 0.0})
		plan.append({"do": "reach", "door": door, "face": "outer", "hand": hand})
		plan.append({"do": "turn", "door": door, "face": "outer", "hand": hand, "to": PULL_TO,
			"time": PULL_SECONDS, "ease": "smooth"})
		plan.append({"do": "let_go", "hand": hand})
		plan.append({"do": "round", "door": door, "face": "inner", "hand": hand})
		plan.append({"do": "reach", "door": door, "face": "inner", "hand": hand})
		plan.append({"do": "push", "door": door, "face": "inner", "hand": hand})
		plan.append({"do": "let_go", "hand": hand})
	plan.append({"do": "settle"})
	plan.append({"do": "go", "spot": STAND_BACK})
	return plan


func _closing_plan() -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for door in [0, 1]:
		var hand: int = door
		var tug: int = 1 - door
		plan.append({"do": "go", "door": door, "face": "edge", "hand": tug, "angle": SWING})
		plan.append({"do": "reach", "door": door, "face": "edge", "hand": tug})
		plan.append({"do": "turn", "door": door, "face": "edge", "hand": tug, "to": UNHOOK_TO,
			"time": UNHOOK_SECONDS, "ease": "in", "still": true})
		plan.append({"do": "send", "door": door, "hand": tug})
		plan.append({"do": "go", "door": door, "face": "outer", "hand": hand, "angle": SWUNG_TO})
		plan.append({"do": "reach", "door": door, "face": "outer", "hand": hand})
		plan.append({"do": "turn", "door": door, "face": "outer", "hand": hand, "to": SHUT_FROM,
			"time": SHUT_SECONDS, "ease": "smooth"})
		plan.append({"do": "shove", "door": door, "face": "outer", "hand": hand})
		plan.append({"do": "let_go", "hand": hand})
	plan.append({"do": "settle"})
	plan.append({"do": "go", "spot": STAND_BACK})
	return plan


func _physics_process(delta: float) -> void:
	if not busy():
		return
	if not is_instance_valid(_driver) or not is_instance_valid(van):
		cancel()
		return
	_swing_free(delta)
	var phase := _plan[_step]
	_clock += delta
	var done := false
	match phase["do"]:
		"go", "round":
			done = _walk(delta)
		"reach":
			_hand = minf(_clock / REACH_SECONDS, 1.0)
			var settled := _settle_into(phase, _angles[phase["door"]], delta)
			done = _clock >= REACH_SECONDS and settled
		"turn":
			var u := minf(_clock / float(phase["time"]), 1.0)
			var ease: String = phase.get("ease", "")
			var eased := u * u if ease == "in" else (smoothstep(0.0, 1.0, u) if ease == "smooth"
				else _smootherstep(u))
			var door: int = phase["door"]
			_angles[door] = lerpf(_from, phase["to"], eased)
			if phase.get("still", false):
				_hold_from_here(phase, _angles[door])
			else:
				_stand_at(phase, _angles[door])
			done = u >= 1.0
		"push":
			done = _push(phase)
		"shove":
			done = _shove(phase)
		"send":
			done = _send(phase, delta)
		"let_go":
			_hand = maxf(1.0 - _clock / LET_GO_SECONDS, 0.0)
			done = _clock >= LET_GO_SECONDS
		"settle":
			done = _settled()
	_drive(delta)
	if done:
		_next()


func _next() -> void:
	if _plan[_step]["do"] == "let_go":
		_held = {}
	_step += 1
	if _step >= _plan.size():
		_finish()
		return
	_begin(_plan[_step])


func _begin(phase: Dictionary) -> void:
	_clock = 0.0
	match phase["do"]:
		"go":
			_held = {}
			_plot(phase)
		"round":
			_path = _round_edge(phase)
			_facing = _stance(phase["door"], phase["face"], _angles[phase["door"]],
				phase["hand"])[1]
			_held = {}
			_measure_walk()
		"reach", "push", "shove":
			_held = {"door": phase["door"], "hand": phase["hand"], "grip": Vector3.ZERO,
				"face": phase["face"]}
			_from = _angles[phase["door"]]
		"turn":
			_from = _angles[phase["door"]]
			_held = {"door": phase["door"], "hand": phase["hand"], "grip": Vector3.ZERO,
				"face": phase["face"]}
			if is_zero_approx(_from):
				van.emit_signal("rear_door_sounded", "release")
			elif is_equal_approx(_from, SWING):
				van.emit_signal("rear_door_sounded", "unhook")
		"send":
			_from = _angles[phase["door"]]


func _finish() -> void:
	var open := _opening
	_plan.clear()
	_held = {}
	set_physics_process(false)
	_driver.call("door_hand", 0, Vector3.ZERO, 0.0)
	_driver.call("door_hand", 1, Vector3.ZERO, 0.0)
	_driver.set("handling", false)
	van.set("rear_doors_open", open)
	finished.emit(open)


## His way to his stance for `phase`, round the van's rear corner if it lies that way; or to a
## plain spot behind the van, facing it.
func _plot(phase: Dictionary) -> void:
	if phase.has("spot"):
		_path = _corners(_guide, phase["spot"])
		_path.append(phase["spot"])
		_facing = Vector3.FORWARD
		_measure_walk()
		return
	var stance := _stance(phase["door"], phase["face"], phase["angle"], phase["hand"])
	_path = _corners(_guide, stance[0])
	_path.append(stance[0])
	_facing = stance[1]
	_measure_walk()


## A walk long enough to turn and walk it facing his way; a short one he steps, slowly, facing as
## he will stand.
func _measure_walk() -> void:
	var length := 0.0
	var at := _guide
	for point in _path:
		length += Vector2(point.x - at.x, point.z - at.z).length()
		at = point
	_long_walk = length > FACE_TURNS


## His body walks his path at his walk's pace, speeding up and slowing to each point, facing the
## way he goes on a long way and as he will stand on a short one; true once he is at its end.
func _walk(delta: float) -> bool:
	if _path.is_empty():
		_walk_facing = Vector3.ZERO
		return _here()
	var to := _path[0]
	var gap := Vector3(to.x - _guide.x, 0.0, to.z - _guide.z)
	var left := gap.length()
	for index in range(1, _path.size()):
		left += _path[index].distance_to(_path[index - 1])
	var most := minf(WALK_MOST if _long_walk else SHORT_PACE, sqrt(2.0 * WALK_ACCEL * left))
	_walk_facing = gap.normalized() if _long_walk and gap.length() > 0.01 else Vector3.ZERO
	_guide_speed = minf(_guide_speed + WALK_ACCEL * delta, most)
	var step := _guide_speed * delta
	while step > 0.0 and not _path.is_empty():
		var ahead := Vector3(_path[0].x - _guide.x, 0.0, _path[0].z - _guide.z)
		if ahead.length() <= step:
			_guide = Vector3(_path[0].x, 0.0, _path[0].z)
			step -= ahead.length()
			_path.pop_front()
		else:
			_guide += ahead.normalized() * step
			step = 0.0
	if _path.is_empty():
		_guide_speed = 0.0
		return _here()
	return false


func _here() -> bool:
	var at := van.to_local(_driver.global_position)
	return Vector2(at.x - _guide.x, at.z - _guide.z).length() < ARRIVED


## Where he stands while his hand is on `door`'s `face` at `angle`: his chest `STAND` from it,
## the hand he uses before its shoulder, facing it; for its free edge, out past it beyond its
## reach, a little back round from it, facing it.
func _stance(door: int, face: String, angle: float, hand: int) -> Array:
	var grip := _grip_at(door, face, angle)
	if face == "edge":
		var spot := _hinges[door] + _toward(door, angle - EDGE_BACK) * EDGE_STAND
		spot.y = 0.0
		var looking := Vector3(grip.x - spot.x, 0.0, grip.z - spot.z).normalized()
		return [spot, looking]
	var out := _normal(door, angle) * (1.0 if face == "outer" else -1.0)
	var facing := -out
	var right := facing.cross(Vector3.UP)
	var at := grip + out * STAND - right * BESIDE * (1.0 if hand == 1 else -1.0)
	return [_clear_of_van(Vector3(at.x, 0.0, at.z)), facing]


## A place kept off the van's body, its rear and sides with their corners rounded, by his
## body's breadth.
func _clear_of_van(at: Vector3) -> Vector3:
	var nearest := Vector3(clampf(at.x, -VAN_HALF, VAN_HALF), 0.0, minf(at.z, REAR_FACE))
	var off := Vector3(at.x - nearest.x, 0.0, at.z - nearest.z)
	if off.length() >= KEEP_OFF:
		return at
	if off.length() < 0.001:
		off = Vector3.BACK
	return nearest + off.normalized() * KEEP_OFF


## As his hand goes to the door, his feet step the last little way to his stance at walking
## pace, never at a hop; true once he stands there.
func _settle_into(phase: Dictionary, angle: float, delta: float) -> bool:
	var stance := _stance(phase["door"], phase["face"], angle, phase["hand"])
	var target: Vector3 = stance[0]
	_guide = _guide.move_toward(target, SHORT_PACE * delta)
	_facing = stance[1]
	_held["grip"] = van.to_global(_grip_at(phase["door"], phase["face"], angle))
	return _guide.distance_to(target) < 0.001 and _here()


## His hand stays on a door that turns under it while his feet stay where they are, his face to it.
func _hold_from_here(phase: Dictionary, angle: float) -> void:
	var grip := _grip_at(phase["door"], phase["face"], angle)
	var looking := Vector3(grip.x - _guide.x, 0.0, grip.z - _guide.z)
	if looking.length_squared() > 0.0001:
		_facing = looking.normalized()
	_held["grip"] = van.to_global(grip)


func _stand_at(phase: Dictionary, angle: float) -> void:
	var stance := _stance(phase["door"], phase["face"], angle, phase["hand"])
	_guide = stance[0]
	_facing = stance[1]
	_held["grip"] = van.to_global(_grip_at(phase["door"], phase["face"], angle))


## The push: his hand on the door's inner face sends it on from where he left it, speeding up
## under his hand, then off it to swing on round to its stay.
func _push(phase: Dictionary) -> bool:
	var door: int = phase["door"]
	var left := SWING - _from - PUSH_BY / 2.0
	var speed := sqrt(ARRIVE * ARRIVE + 2.0 * FRICTION * left)
	var u := minf(_clock / PUSH_SECONDS, 1.0)
	_angles[door] = _from + PUSH_BY * u * u
	_stand_at(phase, _angles[door])
	if u < 1.0:
		return false
	_spins[door] = maxf(speed, 2.0 * PUSH_BY / PUSH_SECONDS)
	_ends[door] = SWING
	_frictions[door] = FRICTION
	return true


## Closing: the last shove, his hand speeding the door on toward its latch, then off it to swing
## shut and latch with a clunk.
func _shove(phase: Dictionary) -> bool:
	var door: int = phase["door"]
	var u := minf(_clock / PUSH_SECONDS, 1.0)
	_angles[door] = _from - SHOVE_BY * u * u
	_stand_at(phase, _angles[door])
	if u < 1.0:
		return false
	_spins[door] = -maxf(LATCH_SPEED, 2.0 * SHOVE_BY / PUSH_SECONDS)
	_ends[door] = 0.0
	_frictions[door] = 0.0
	return true


## Closing: off its stay at the speed his pull gave it, the door swings on back round toward the
## van's rear, its hinges' friction stopping it where he will push it shut from.
func _send(phase: Dictionary, delta: float) -> bool:
	var door: int = phase["door"]
	if _ends[door] < 0.0:
		var speed := 2.0 * (SWING - UNHOOK_TO) / UNHOOK_SECONDS
		_spins[door] = -speed
		_ends[door] = SWUNG_TO
		_frictions[door] = speed * speed / (2.0 * (_angles[door] - SWUNG_TO))
	_hand = maxf(1.0 - _clock / LET_GO_SECONDS, 0.0)
	return _clock >= LET_GO_SECONDS


## The doors not under his hand swing on: friction slowing them; a stay catching an opening door
## with a little bounce; a closing door stopping where its friction leaves it.
func _swing_free(delta: float) -> void:
	for door in range(2):
		if _ends[door] < 0.0:
			continue
		if not _held.is_empty() and int(_held["door"]) == door and _plan[_step]["do"] != "send" \
				and _plan[_step]["do"] != "let_go":
			continue
		var spin := _spins[door]
		if _ends[door] == SWING:
			if _caught[door]:
				spin += (STAY_PULL * (SWING - _angles[door]) - STAY_DAMP * spin) * delta
			else:
				spin = maxf(spin - _frictions[door] * delta, 0.1)
			_angles[door] += spin * delta
			if _angles[door] >= SWING:
				_angles[door] = SWING
				if not _caught[door]:
					_caught[door] = true
					spin = -spin * BOUNCE
					van.emit_signal("rear_door_sounded", "stay")
				elif absf(spin) < 0.05:
					spin = 0.0
			if _caught[door] and absf(spin) < 0.02 and SWING - _angles[door] < 0.003:
				_angles[door] = SWING
				spin = 0.0
				_ends[door] = -1.0
		elif _ends[door] == 0.0:
			_angles[door] += spin * delta
			if _angles[door] <= 0.0:
				_angles[door] = 0.0
				spin = 0.0
				_ends[door] = -1.0
				van.emit_signal("rear_door_sounded", "latch")
		else:
			var before := spin
			spin += _frictions[door] * delta * (1.0 if spin < 0.0 else -1.0)
			if signf(spin) != signf(before) or is_zero_approx(spin):
				spin = 0.0
				_angles[door] = maxf(_angles[door], _ends[door])
				_ends[door] = -1.0
			else:
				_angles[door] = maxf(_angles[door] + spin * delta, _ends[door])
		_spins[door] = spin


func _settled() -> bool:
	return _ends[0] < 0.0 and _ends[1] < 0.0 and _here()


## Whether `door` is shut on its latch, nothing swinging it.
func latched(door: int) -> bool:
	return _ends[door] < 0.0 and is_zero_approx(_angles[door])


## Hands his body its place and facing this frame, and his hand on the door.
func _drive(delta: float) -> void:
	var facing := _walk_facing if _walk_facing != Vector3.ZERO else _facing
	_driver.call("door_step", van.to_global(_guide), van.global_basis * facing, delta)
	if _held.is_empty() or _hand <= 0.0:
		_driver.call("door_hand", 0, Vector3.ZERO, 0.0)
		_driver.call("door_hand", 1, Vector3.ZERO, 0.0)
		return
	if (_held["grip"] as Vector3) == Vector3.ZERO:
		_held["grip"] = van.to_global(_grip_at(_held["door"], _held["face"],
			_angles[_held["door"]]))
	var hand: int = _held["hand"]
	_driver.call("door_hand", hand, _held["grip"], _hand)
	_driver.call("door_hand", 1 - hand, Vector3.ZERO, 0.0)


## The way from `door`'s hinges to its free edge at `angle`, flat.
func _toward(door: int, angle: float) -> Vector3:
	var way := Basis(Vector3.UP, _sign(door) * angle) * Vector3(1.0 if door == 0 else -1.0, 0.0,
		0.0)
	return Vector3(way.x, 0.0, way.z).normalized()


func _grip_at(door: int, face: String, angle: float) -> Vector3:
	var local: Vector3 = (_grips[face] as Array)[door]
	return _hinges[door] + Basis(Vector3.UP, _sign(door) * angle) * local


func _normal(door: int, angle: float) -> Vector3:
	var normal := Basis(Vector3.UP, _sign(door) * angle) * Vector3.BACK
	return Vector3(normal.x, 0.0, normal.z).normalized()


func _sign(door: int) -> float:
	return 1.0 if door == 1 else -1.0


## Round a door's free edge from where he stands to his stance on its other face, a little way
## out from its edge all the way.
func _round_edge(phase: Dictionary) -> Array[Vector3]:
	var door: int = phase["door"]
	var angle := _angles[door]
	var free_x: float = (_grips["outer"] as Array)[door].x + (EDGE_IN if door == 0 else -EDGE_IN)
	var tip := _hinges[door] + Basis(Vector3.UP, _sign(door) * angle) * Vector3(free_x, 0.0, 0.0)
	tip.y = 0.0
	var outward := Vector3(tip.x - _hinges[door].x, 0.0, tip.z - _hinges[door].z).normalized()
	var start := _guide - tip
	var end_at: Vector3 = _stance(door, phase["face"], angle, phase["hand"])[0]
	var finish := end_at - tip
	var from := atan2(start.z, start.x)
	var to := atan2(finish.z, finish.x)
	var middle := atan2(outward.z, outward.x)
	var sweep := wrapf(to - from, -PI, PI)
	if absf(wrapf(middle - from, -PI, PI)) > absf(sweep) \
			or signf(wrapf(middle - from, -PI, PI)) != signf(sweep):
		sweep = sweep - TAU * signf(sweep)
	var path: Array[Vector3] = []
	for index in range(1, ROUND_POINTS):
		var a := from + sweep * float(index) / ROUND_POINTS
		path.append(tip + Vector3(cos(a), 0.0, sin(a)) * ROUND_BY)
	path.append(end_at)
	return path


## Round the van's rear corner when his way runs from behind it to beside it, or back, wide of a
## door folded back against its side.
func _corners(from: Vector3, to: Vector3) -> Array[Vector3]:
	var behind_from := from.z > VAN_REAR
	var behind_to := to.z > VAN_REAR
	var beside_from := absf(from.x) > VAN_SIDE and from.z < VAN_REAR
	var beside_to := absf(to.x) > VAN_SIDE and to.z < VAN_REAR
	if (behind_from and beside_to) or (beside_from and behind_to):
		var side := signf(to.x if beside_to else from.x)
		var corner := Vector3(CORNER.x * side, 0.0, CORNER.y)
		var lane := Vector3(SIDE_LANE.x * side, 0.0, SIDE_LANE.y)
		var way: Array[Vector3] = [corner, lane]
		if not beside_to:
			way.reverse()
		return way
	var none: Array[Vector3] = []
	return none


func _smootherstep(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
