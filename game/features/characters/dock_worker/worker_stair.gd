extends RefCounted
## Bay 9's dock worker on the dock stair (the audit's fourth fix, #329): a tread a step, at a
## stair's cadence (Di Giulio et al. 2019: about 76 steps a minute up and 117 down), his feet
## taking turns, each set on a tread of its own by his legs' IK, his body as low as his lower
## foot lets it be; his hand on the rail's side holding the rail, sliding along it (going down
## his left, coming up his right). Everything is in the world; the stair is described as
## `dock_access.gd`'s `stair()` gives it, and the rail by its top's two ends.

const UP_CADENCE := 76.0
const DOWN_CADENCE := 117.0
const SIDE := 0.1
const CLEAR := 0.05
const DOWN_FROM := 0.35
const BLEND_IN := 0.15
const BLEND_OUT := 0.3
const RAIL_NEAR := 0.4
const RAIL_AHEAD := 0.12
const GRIP_ABOVE := 0.04
const RAIL_RATE := 1.0 / 0.3
const WIDE := 0.2
## His body 3 cm lower on the flight than his lower foot's tread, his knees a little bent.
const BEND := 0.03
## His hand lets go of the rail as his reach comes to its end.
const RAIL_END := 0.05
const LEGS := ["Bip01 %s Thigh", "Bip01 %s Calf", "Bip01 %s Foot"]
const ARMS := ["Bip01 %s UpperArm", "Bip01 %s Forearm", "Bip01 %s Hand"]
const SIDES := ["L", "R"]

var _stair := {}
var _rail_from := Vector3.ZERO
var _rail_to := Vector3.ZERO
var _model: Node3D
var _skeleton: Skeleton3D
var _legs: TwoBoneIK3D
var _arms: Array[TwoBoneIK3D] = []
var _feet: Array[Marker3D] = []
var _hands: Array[Marker3D] = []
var _ankle := 0.0
var _start: Array[Vector3] = []
var _down := true
var _weight := 0.0
var _grip := 0.0
var _gripping := 0


## `rail_from` and `rail_to` are the rail's top at the foot of the flight and at its top.
func setup(model: Node3D, skeleton: Skeleton3D, stair: Dictionary, rail_from: Vector3,
		rail_to: Vector3) -> void:
	_model = model
	_skeleton = skeleton
	_stair = stair
	_rail_from = rail_from
	_rail_to = rail_to
	_ankle = (skeleton.global_transform * skeleton.get_bone_global_rest(
		skeleton.find_bone("Bip01 L Foot"))).origin.y - model.global_position.y
	_legs = _limbs("StairFeet", LEGS, _feet, [Vector3(0.12, 0.5, 0.6), Vector3(-0.12, 0.5, 0.6)])
	for index in range(2):
		_arms.append(_limbs("RailHand%s" % SIDES[index], ARMS, _hands,
			[[Vector3(0.6, 0.6, -0.3), Vector3(-0.6, 0.6, -0.3)][index]], index))
	reset()


func reset() -> void:
	_weight = 0.0
	_grip = 0.0
	_start.clear()
	_apply()


## How far `at` is up the flight from its foot, across the floor.
func along(at: Vector3) -> float:
	var up := _stair["up"] as Vector3
	var foot := _stair["foot"] as Vector3
	return Vector2(at.x - foot.x, at.z - foot.z).dot(Vector2(up.x, up.z))


func flight() -> float:
	return float(_stair["tread"]) * (int(_stair["risers"]) - 1)


## Whether `at` is on the flight or within its first step of it, where the stair takes his feet.
func near(at: Vector3) -> bool:
	var a := along(at)
	var across := _stair["across"] as Vector3
	var foot := _stair["foot"] as Vector3
	var aside := absf(Vector2(at.x - foot.x, at.z - foot.z).dot(Vector2(across.x, across.z)))
	return a > -float(_stair["tread"]) and a < flight() + float(_stair["tread"]) \
		and aside < float(_stair["width"]) / 2.0 + WIDE


## His pace across the floor on the flight: a tread a step at the stair's cadence.
func pace(down: bool) -> float:
	return float(_stair["tread"]) * (DOWN_CADENCE if down else UP_CADENCE) / 60.0


## His walk's rate on the flight against its own 100 steps a minute (37 frames a stride at 30).
func rate(down: bool) -> float:
	return (DOWN_CADENCE if down else UP_CADENCE) / (2.0 * 30.0 * 60.0 / 36.0)


## One frame on the stair at `at`, going down or up and facing `facing`: sets his feet and his
## rail hand and gives the height his body stands at.
func step(at: Vector3, down: bool, facing: Vector3, ground: float, delta: float) -> float:
	if not near(at):
		_weight = move_toward(_weight, 0.0, delta / BLEND_OUT)
		_grip = move_toward(_grip, 0.0, delta * RAIL_RATE)
		if _weight <= 0.0:
			_start.clear()
		_apply()
		return ground
	if down != _down:
		_down = down
		_start.clear()
	var tread := float(_stair["tread"])
	var d := _travel(at)
	var landing := d >= -tread / 2.0 and d <= flight() + tread / 2.0
	if _start.is_empty():
		if not landing:
			_hold_rail(at, down, facing, delta)
			_apply()
			return ground
		_start = [_onto_level(_bone(LEGS[2] % "L")), _onto_level(_bone(LEGS[2] % "R"))]
	var heights: Array[float] = []
	for side in range(2):
		var target := _foot_target(side, d, at)
		_feet[side].global_position = target
		heights.append(target.y - _ankle)
	_weight = move_toward(_weight, 1.0 if landing else 0.0,
		delta / (BLEND_IN if landing else BLEND_OUT))
	_hold_rail(at, down, facing, delta)
	_apply()
	var body := minf(heights[0], heights[1]) - BEND
	return lerpf(ground, body, _weight)


## How far he has gone over the flight the way he goes: from its top edge going down, from its
## foot going up.
func _travel(at: Vector3) -> float:
	var a := along(at)
	return flight() - a if _down else a


## Where foot `side` is set with his body `d` over the flight: on the tread of its last step,
## or on its arc to the next, a step being one tread of his travel, the two feet taking turns.
func _foot_target(side: int, d: float, at: Vector3) -> Vector3:
	var tread := float(_stair["tread"])
	var count := int(_stair["risers"])
	var j := clampi(floori(d / tread + 1.5), 0, count)
	var mine := j if j % 2 == (1 if side == 0 else 0) else j - 1
	var last := mine - 2 if mine == j else mine
	var into := clampf((d - (mine - 1.5) * tread) / tread, 0.0, 1.0) if mine == j else 1.0
	var from := _place(side, last, at)
	var to := _place(side, mine, at)
	if mine <= 0:
		return _place(side, 0, at)
	var eased := smoothstep(0.0, 1.0, into)
	var point := from.lerp(to, eased)
	var lift := CLEAR * sin(PI * into)
	if _down:
		var drop := smoothstep(DOWN_FROM, 1.0, into)
		point.y = lerpf(from.y, to.y, drop) + lift
	else:
		point.y = lerpf(from.y, to.y, smoothstep(0.0, 0.7, into)) + lift
	return point


## Foot `side`'s place after step `k` (0 before the first): the tread it lands on, or, before
## the flight, where it stood as he came to it.
func _place(side: int, k: int, at: Vector3) -> Vector3:
	if k <= 0:
		return _start[side] if not _start.is_empty() else at
	var tread := float(_stair["tread"])
	var rise := float(_stair["rise"])
	var count := int(_stair["risers"])
	var up := _stair["up"] as Vector3
	var across := _stair["across"] as Vector3
	var foot := _stair["foot"] as Vector3
	var a := 0.0
	var height := 0.0
	if _down:
		var level := count - k
		a = (level - 0.5) * tread if level >= 1 else -0.2
		height = level * rise if level >= 1 else 0.0
	else:
		a = (k - 0.5) * tread if k < count else flight() + 0.2
		height = k * rise if k < count else count * rise
	var lateral := across * Vector2(at.x - foot.x, at.z - foot.z).dot(
		Vector2(across.x, across.z))
	var out := SIDE * (-1.0 if side == 0 else 1.0) * (1.0 if _down else -1.0)
	var point := foot + up * a + lateral + across * out
	point.y = foot.y + height + _ankle
	return point


## `foot` where it stands before the flight: on the landing's edge going down, on the floor at
## the flight's foot going up, never over a tread.
func _onto_level(foot: Vector3) -> Vector3:
	var up := _stair["up"] as Vector3
	var a := along(foot)
	var edge := flight() if _down else 0.0
	var beyond := maxf(a, edge + 0.02) if _down else minf(a, edge - 0.02)
	var point := foot + up * (beyond - a)
	point.y = (_stair["foot"] as Vector3).y + _ankle \
		+ (float(_stair["rise"]) * int(_stair["risers"]) if _down else 0.0)
	return point


## The hand on the rail's side (left going down, right coming up) on the rail's top, sliding along
## it: going up a little ahead of his shoulder, going down beside it, where the falling rail is
## still within his reach.
func _hold_rail(at: Vector3, down: bool, facing: Vector3, delta: float) -> void:
	var side := 0 if down else 1
	_gripping = side
	var shoulder := _bone(ARMS[0] % SIDES[side])
	var reach := _rail_t(shoulder + facing * (0.0 if down else RAIL_AHEAD))
	var t := clampf(reach, 0.0, 1.0)
	var grip := _rail_from.lerp(_rail_to, t) + Vector3.UP * GRIP_ABOVE
	_hands[side].global_position = grip
	var a := along(at)
	var on := a > -RAIL_NEAR and a < flight() + RAIL_NEAR and reach > RAIL_END \
		and reach < 1.0 - RAIL_END
	_grip = move_toward(_grip, 1.0 if on else 0.0, delta * RAIL_RATE)


func _rail_t(at: Vector3) -> float:
	var run := _rail_to - _rail_from
	var flat := Vector2(run.x, run.z)
	return Vector2(at.x - _rail_from.x, at.z - _rail_from.z).dot(flat) / flat.length_squared()


func _apply() -> void:
	if _legs == null:
		return
	_legs.influence = _weight
	_legs.active = _weight > 0.0
	for side in range(2):
		var on := _grip if side == _gripping else 0.0
		_arms[side].influence = on
		_arms[side].active = on > 0.0


## A two-bone IK of `bones` for both sides, or for side `only` alone, each reaching for a target
## of its own in the world, its knee or elbow toward a pole in his own frame.
func _limbs(label: String, bones: Array, targets: Array[Marker3D], poles: Array[Vector3],
		only := -1) -> TwoBoneIK3D:
	var ik := TwoBoneIK3D.new()
	ik.name = label
	ik.set_setting_count(2 if only < 0 else 1)
	_skeleton.add_child(ik)
	for index in range(ik.get_setting_count()):
		var side: String = SIDES[index if only < 0 else only]
		ik.set_root_bone_name(index, String(bones[0]) % side)
		ik.set_middle_bone_name(index, String(bones[1]) % side)
		ik.set_end_bone_name(index, String(bones[2]) % side)
		var target := Marker3D.new()
		target.name = "%s%sTarget" % [label, side]
		target.top_level = true
		_model.add_child(target)
		targets.append(target)
		var pole := Marker3D.new()
		pole.name = "%s%sPole" % [label, side]
		pole.position = poles[index]
		_model.add_child(pole)
		ik.set_target_node(index, ik.get_path_to(target))
		ik.set_pole_node(index, ik.get_path_to(pole))
	ik.active = false
	ik.influence = 0.0
	return ik


func _bone(label: String) -> Vector3:
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone(label))).origin
