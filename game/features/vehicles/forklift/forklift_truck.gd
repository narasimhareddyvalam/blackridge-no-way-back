extends AnimatableBody3D
## The transfer shed's electric counterbalance forklift at work (part G of step 5 of #253; the
## author's choices, #302-#303): Kamran Mughal's truck (CC BY), its carriage cut free to ride up
## its mast (`convert_depot_models.py`), driven by a Rocketbox warehouse worker
## (`Construction_Male_07`, MIT) seated at the wheel, his hands on it and his feet on the plate by
## two-bone IK, his head turned the way he travels (`look_travel.gd`). While the camera is within
## ACTIVE_REACH of it, it works in trips: a pallet of its own from dock 6's staging lane to the
## floor stacking bay FS-01 at the north end of the clear strip east of the racking, then back
## again, as a putaway and a pick; between trips it parks where it stood, over its oil drip
## (part D). (Until #324 its putaway went to a floor place in aisle 03, which a four-wheel truck
## of its turning radius cannot reach at right angles in a 3.81 m aisle.)
##
## It moves as the four-wheel counterbalance truck it is (the audit's second fix, #323): it steers
## with its rear wheels, its heading turning at v·tan(δ)/L about a point on its front axle's
## line, the two steer wheels set by Ackermann geometry; each corner of its rounds is a turn the
## driver winds the wheel into, holds and winds out of at his hands' pace, planned from those
## kinematics so that it lands on the next leg's line; where it backs and then drives on it
## swings round backing and stops; from its parking place it sets off along an arc. Its
## steering wheel turns with the steer, every wheel rolls with the ground it covers, and its
## mast tilts back with a load on the move. OSHA 1910.178(n): the load carried low
## (TRAVEL_LIFT), never over 5 mph (2.2 m/s) and slower in the aisle, its horn at the aisle's
## mouth, its blue spot projected ahead of it in its direction of travel, its broadband alarm
## while it backs, and it gives way to Ethan: it slows so as to stop KEEP_CLEAR short of him in
## its way, and does not turn while he stands within its swing.

const LookTravel = preload("look_travel.gd")
const TRUCK := preload("res://features/environments/industrial_loop/art/depot/forklift.glb")
const DRIVER := preload("res://features/characters/forklift_driver/forklift_driver.glb")
const AUDIO := "res://features/audio/shed/"
const FLOOR := 1.3
## The front axle, 0.25 m ahead of the model's origin; the truck's reach from it.
const AXLE := 0.25
const HEEL := 0.37
const TIP := 1.40
const REAR := 1.90
const HALF := 0.56
const BODY := Vector3(1.12, 2.21, 3.3)
## A pallet sits on the forks against the backrest: its middle LOAD_AT ahead of the axle.
const LOAD_AT := 0.98
const LOAD_HALF := 0.61
const TRAVEL_LIFT := 0.12
## A 2.5 t electric truck's lift (#323 †): up at 0.35 m/s, down at 0.5 m/s.
const LIFT_RATE := 0.35
const LOWER_RATE := 0.5
## Its kinematics (#323), measured from the model: the front axle 0.055 m behind this node's
## origin, the rear 1.461 m behind it, the steer wheels' pivots 1.019 m apart; full lock puts the
## inner steer wheel at 80 degrees †, 2.25 turns of the wheel from straight †; its turns are
## taken about a point 0.9 m from the front axle's middle (the inner wheel at 75 degrees).
const FRONT_AXLE := -0.055
const WHEELBASE := 1.461
const TRACK := 1.019
const LOCK_INNER := deg_to_rad(80.0)
const LOCK := atan(WHEELBASE / (TRACK / 2.0 + WHEELBASE / tan(LOCK_INNER)))
const LOCK_TURNS := 2.25
const HANDS_RATE := 1.5
const STEER_RATE := HANDS_RATE / LOCK_TURNS * LOCK
const TURN_RADIUS := 0.9
const TURN_SPEED := 0.8
const DRIVE_RADIUS := 0.318
const STEER_RADIUS := 0.277
const SAMPLE := 0.01
## The steering wheel's axis in the model, down and forward along its column.
const COLUMN := Vector3(0.0, -0.70711, 0.70711)
## The spinner knob (#323), which the model lacks and nearly every forklift has: on the rim (0.125
## m out) at ten o'clock from the driver's seat, standing 0.06 m toward him. His left hand holds
## it and goes round with the wheel; his right is on the control lever's knob beside the seat
## (measured from the model), or backing on the overhead guard's right rear post.
const RIM := 0.125
const KNOB_AT := Vector3(0.866, 0.354, 0.354)
const KNOB_TALL := 0.06
const LEVER := Vector3(-0.387, 1.16, -0.546)
const GUARD_POST := Vector3(-0.475, 1.35, -1.11)
const SHOULDERS: Array[Vector3] = [Vector3(0.19, 1.45, -0.8), Vector3(-0.19, 1.45, -0.8)]
const WRIST_BACK := 0.07
const HAND_MOVE := 0.25
## The mast tilted back with a load on the move, level to take or leave one (#323 †).
const TILT_BACK := deg_to_rad(4.0)
const TILT_RATE := deg_to_rad(4.0)
const TOP_SPEED := 2.2
const AISLE_SPEED := 1.0
const REVERSE_SPEED := 1.0
const CREEP := 0.3
const ACCEL := 0.8
const BRAKE := 1.5
const SPIN_RATE := 0.6
const SPIN_ACCEL := 0.8
const KEEP_CLEAR := 2.0
const SWING_CLEAR := 2.5
const ACTIVE_REACH := 60.0
const START_AFTER := 2.0
const PAUSE := 12.0
## The places it works between, as the front axle's place and the truck's heading (its forks'
## way, an angle about up from +z): parked, the cross-aisle before dock 6's lane, the staging
## place, where it passes aisle 05's mouth (it sounds its horn there, an intersection), where it
## turns off the cross-aisle for the floor bay, and where it stands to set its load in the bay
## (the load's middle at FLOOR_BAY, its forks toward -z). The bay stands 3.24 m west of the
## dock's edge (x -44.76, `dock_access.gd`'s EDGE_X), where its guardrail stands over the drive-in
## lane: backing out and swinging its forks west, the truck's rear sweeps about 2.9 m east of its
## line.
const HOME := Vector3(-63.150, FLOOR, 12.645)
const HOME_HEADING := 0.2
const LANE := Vector2(-60.0, 12.0)
const STAGE := Vector2(-60.0, 15.32)
const BAY_TURN := Vector2(-48.0, 12.5)
const PASS_05 := Vector2(-53.81, LANE.y + (BAY_TURN.y - LANE.y) * (-53.81 - LANE.x)
	/ (BAY_TURN.x - LANE.x))
const FLOOR_BAY := Vector2(-48.0, 9.1)
const BAY_STOP := Vector2(FLOOR_BAY.x, FLOOR_BAY.y + LOAD_AT)
## Where it comes off and goes onto its parking place (#323): a four-wheel truck cannot turn on
## the spot, so it parks nose in from a line along the cross-aisle (z 11.2) and backs out to it,
## swinging its rear as it backs so its forks face the way it goes.
const PARK_LINE := 11.2
const HOME_EXIT := Vector2(HOME.x - (HOME.z - PARK_LINE) * tan(HOME_HEADING), PARK_LINE)
const SPOT_REACH := 4.0
const SPOT_UP := 2.15
const SPOT_COLOUR := Color(0.15, 0.35, 1.0)
## The driver on the seat (cushion top 0.99 m over z -0.90 to -0.52 in the model), his hands at
## ten and two on the wheel (its middle at 1.42 m, 0.40 m behind the model's origin, tilted 45
## degrees back), his feet on the plate (0.70 m).
const SEAT := Vector3(0.0, 0.33, -0.78)
const SEAT_TOP := 0.99
const GRIPS: Array[Vector3] = [Vector3(0.112, 1.466, -0.354), Vector3(-0.112, 1.466, -0.354)]
## His wrists, which the IK places, 7 cm back from each grip toward his shoulder, as a hand
## round a rim holds it.
const WRISTS: Array[Vector3] = [Vector3(0.139, 1.491, -0.413), Vector3(-0.139, 1.491, -0.413)]
const FEET: Array[Vector3] = [Vector3(0.12, 0.78, -0.30), Vector3(-0.12, 0.78, -0.25)]
const SIDES: Array[String] = ["L", "R"]

signal horned(at: Vector3)

var walker: Node3D
var trips := 0

var _load: Node3D
var _model: Node3D
var _carriage: Node3D
var _carriage_rest := 0.0
var _driver: Node3D
var _skeleton: Skeleton3D
var _look: Node
var _spots: Array[SpotLight3D] = []
var _motor: AudioStreamPlayer3D
var _pump: AudioStreamPlayer3D
var _alarm: AudioStreamPlayer3D
var _horn: AudioStreamPlayer3D
var _steps: Array = []
var _step := -1
var _phase := "parked"
var _speed := 0.0
var _spin := 0.0
var _lift := 0.0
var _carrying := false
var _wait := 0.0
var _active := 0.0
var _to_slot := true
var _fit := {}
var _steer := 0.0
var _turn_s := 0.0
var _tilt := 0.0
var _parts := {}
var _rolled := {}
var _hubs := {}
var _knob: Node3D
var _grips: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _right_from := Vector3.ZERO
var _right_to := Vector3.ZERO
var _right_move := 1.0
var _wrists: Array[Marker3D] = []


func _init() -> void:
	name = "Forklift"
	sync_to_physics = false


func _ready() -> void:
	_model = TRUCK.instantiate() as Node3D
	_model.position = Vector3(0.0, 0.0, -AXLE)
	add_child(_model)
	_carriage = _model.find_child("Carriage", true, false) as Node3D
	if _carriage != null:
		_carriage_rest = _carriage.position.y
	for label: String in ["SteeringWheel", "Mast", "DriveWheelL", "DriveWheelR", "SteerWheelL",
			"SteerWheelR"]:
		var part := _model.find_child(label, true, false) as Node3D
		if part != null:
			_parts[label] = part
			_rolled[label] = 0.0
	_add_knob()
	var shape := BoxShape3D.new()
	shape.size = BODY
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, BODY.y / 2.0, -AXLE)
	add_child(collision)
	_seat_driver()
	for end: float in [1.0, -1.0]:
		var spot := SpotLight3D.new()
		spot.name = "BlueSpot" + ("Front" if end > 0.0 else "Rear")
		spot.light_color = SPOT_COLOUR
		spot.light_energy = 6.0
		spot.spot_angle = 6.0
		spot.spot_range = 7.0
		spot.shadow_enabled = false
		spot.visible = false
		add_child(spot)
		var at := Vector3(0.0, SPOT_UP, 0.2 if end > 0.0 else -1.8)
		spot.transform = Transform3D(Basis.looking_at(Vector3(0.0, 0.0, end * SPOT_REACH) - at,
			Vector3.UP), at)
		_spots.append(spot)
	_motor = _sound("forklift_motor", -14.0)
	_pump = _sound("forklift_pump", -12.0)
	_alarm = _sound("reverse_alarm", -10.0)
	_horn = _sound("forklift_horn", -6.0)


## Puts the truck at its parking place with `load` standing in dock 6's lane.
func park(load: Node3D) -> void:
	_load = load
	global_transform = Transform3D(Basis(Vector3.UP, HOME_HEADING), HOME)


func phase() -> String:
	return _phase


func speed() -> float:
	return _speed


func lift() -> float:
	return _lift


func carrying() -> bool:
	return _carrying


func reversing() -> bool:
	return _step >= 0 and _step < _steps.size() and bool(_steps[_step].get("reverse", false))


func alarm_playing() -> bool:
	return _alarm.playing


func head_turned() -> float:
	return absf(float(_look.get("turned"))) if _look != null else 0.0


func load_node() -> Node3D:
	return _load


## Where his left hand holds the spinner knob, and the grips of both his hands, in the world.
func knob_point() -> Vector3:
	return _knob.global_position + _knob.global_basis.y * KNOB_TALL / 2.0 if _knob != null \
		else Vector3.INF


func grips() -> Array[Vector3]:
	var found: Array[Vector3] = []
	for grip in _grips:
		found.append(_model.to_global(grip))
	return found


## How far his chest is turned as he looks back.
func chest_turned() -> float:
	return absf(float(_look.call("chest"))) if _look != null else 0.0


## The steer at the rear axle's middle, δ (positive turning toward +x going forward).
func steer() -> float:
	return _steer


## Each steer wheel's angle about up (its own, by Ackermann), and the steering wheel's turns.
func steer_wheels() -> Dictionary:
	return _ackermann(_steer)


func steering_turns() -> float:
	return _steer / LOCK * LOCK_TURNS


## The mast's tilt back, in radians.
func tilt() -> float:
	return _tilt


## How far each wheel has rolled, in radians.
func rolled() -> Dictionary:
	return _rolled.duplicate()


## How far the truck reaches from its front axle in its direction of travel.
func reach_ahead() -> float:
	if reversing():
		return REAR
	return LOAD_AT + LOAD_HALF if _carrying else TIP


## Where its lit blue spot lands on the floor.
func spot_point() -> Vector3:
	for spot in _spots:
		if spot.visible:
			var from := spot.global_position
			var down := -spot.global_basis.z
			if down.y < -0.01:
				return from + down * ((FLOOR - from.y) / down.y)
	return Vector3.INF


## How well the driver sits: his hands' farthest from their grips, his feet's from the plate,
## and his pelvis over the seat, as his skeleton last drew him (after its modifiers).
func driver_fit() -> Dictionary:
	return _fit.duplicate()


func _measure_fit() -> void:
	var hands := 0.0
	var feet := 0.0
	for index in range(2):
		var side := SIDES[index]
		hands = maxf(hands, _bone("Bip01 %s Hand" % side).distance_to(_model.to_global(
			_grips[index])))
		feet = maxf(feet, _bone("Bip01 %s Foot" % side).distance_to(_model.to_global(
			FEET[index])))
	var pelvis := _model.to_local(_bone("Bip01 Pelvis"))
	var on_seat := pelvis.y > SEAT_TOP and pelvis.y < SEAT_TOP + 0.2 and pelvis.z > -0.9 \
		and pelvis.z < -0.5 and absf(pelvis.x) < 0.1
	_fit = {"hands": hands, "feet": feet, "on_seat": on_seat}


func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var near := camera != null and camera.global_position.distance_to(global_position) \
		< ACTIVE_REACH
	if _phase == "parked":
		_speed = 0.0
		_active = _active + delta if near else 0.0
		_wait = maxf(_wait - delta, 0.0)
		if near and _active >= START_AFTER and _wait <= 0.0 and _load != null:
			_plan()
		_hands()
		_sounds(delta)
		return
	_run_step(delta)
	_animate()
	_sounds(delta)


func _plan() -> void:
	var home := Vector2(HOME.x, HOME.z)
	_steps = []
	if _to_slot:
		_steps.append_array([_go("back_out", HOME_EXIT, true, CREEP),
			_go("to_lane", LANE, false, TOP_SPEED),
			_go("to_stage", STAGE, false, CREEP), {"do": "take"}, _raise(TRAVEL_LIFT),
			_tilt_to(TILT_BACK), _go("from_stage", LANE, true, REVERSE_SPEED),
			_go("to_crossing", PASS_05, false, TOP_SPEED), {"do": "horn"},
			_go("to_bay_turn", BAY_TURN, false, TOP_SPEED),
			_go("to_bay", BAY_STOP, false, CREEP), _tilt_to(0.0), _raise(0.0),
			{"do": "leave", "at": "bay"},
			_go("from_bay", BAY_TURN, true, CREEP),
			_go("to_crossing", PASS_05, false, TOP_SPEED), {"do": "horn"},
			_go("to_park", HOME_EXIT, false, TOP_SPEED), _go("to_home", home, false, CREEP)])
	else:
		_steps.append_array([_go("back_out", HOME_EXIT, true, CREEP),
			_go("to_crossing", PASS_05, false, TOP_SPEED), {"do": "horn"},
			_go("to_bay_turn", BAY_TURN, false, TOP_SPEED),
			_go("to_bay", BAY_STOP, false, CREEP), {"do": "take"},
			_raise(TRAVEL_LIFT), _tilt_to(TILT_BACK), _go("from_bay", BAY_TURN, true, CREEP),
			_go("to_crossing", PASS_05, false, TOP_SPEED), {"do": "horn"},
			_go("to_lane", LANE, false, TOP_SPEED),
			_go("to_stage", STAGE, false, CREEP), _tilt_to(0.0), _raise(0.0),
			{"do": "leave", "at": "stage"},
			_go("from_stage", LANE, true, REVERSE_SPEED),
			_go("to_park", HOME_EXIT, false, TOP_SPEED), _go("to_home", home, false, CREEP)])
	_steps = _route(_steps)
	_step = -1
	_next()


func _go(label: String, to: Vector2, reverse: bool, most: float) -> Dictionary:
	return {"do": "drive", "phase": label, "to": to, "reverse": reverse, "most": most}


func _turn(heading: float) -> Dictionary:
	return {"do": "turn", "to": heading}


func _raise(height: float) -> Dictionary:
	return {"do": "lift", "to": height}


func _tilt_to(angle: float) -> Dictionary:
	return {"do": "tilt", "to": angle}


func _next() -> void:
	var flowing := 0.0
	if _step >= 0 and _step < _steps.size():
		flowing = float((_steps[_step] as Dictionary).get("end_speed", 0.0))
	_step += 1
	_speed = minf(_speed, flowing)
	if _step >= _steps.size():
		_phase = "parked"
		_step = -1
		trips += 1
		_to_slot = not _to_slot
		_wait = PAUSE
		_spots_for(0.0)
		return
	var step: Dictionary = _steps[_step]
	_phase = String(step.get("phase", step["do"]))
	_turn_s = 0.0


func _run_step(delta: float) -> void:
	var step: Dictionary = _steps[_step]
	match String(step["do"]):
		"turn":
			if _follow_turn(step, delta):
				_next()
		"tilt":
			_tilt = move_toward(_tilt, float(step["to"]), TILT_RATE * delta)
			if is_equal_approx(_tilt, float(step["to"])):
				_next()
		"drive":
			if _drive(step, delta):
				_next()
		"lift":
			var rate := LIFT_RATE if float(step["to"]) > _lift else LOWER_RATE
			_lift = move_toward(_lift, float(step["to"]), rate * delta)
			if _carriage != null:
				_carriage.position.y = _carriage_rest + _lift
			if is_equal_approx(_lift, float(step["to"])):
				_next()
		"take":
			_load.reparent(_carriage, true)
			_carrying = true
			_next()
		"leave":
			_leave(String(step["at"]))
			_next()
		"horn":
			_horn.play()
			horned.emit(global_position)
			_next()


## The planned steps as it drives them: the turns dropped, every change of heading made a turn
## of its kinematics: at a corner between two legs one filleted into both (taken in the first
## leg's way, so where it backs and then drives on it swings round backing and stops), and from
## a standstill one setting off toward the leg's end.
func _route(steps: Array) -> Array:
	var routed: Array = []
	var at := Vector2(global_position.x, global_position.z)
	var heading := atan2(global_basis.z.x, global_basis.z.z)
	var before: Dictionary = {}
	for step: Dictionary in steps:
		match String(step["do"]):
			"turn":
				continue
			"horn":
				routed.append(step)
				continue
			"drive":
				var to: Vector2 = step["to"]
				var sense := -1.0 if bool(step["reverse"]) else 1.0
				var way := (to - at).normalized()
				var wanted := atan2(way.x * sense, way.y * sense)
				var change := angle_difference(heading, wanted)
				var leg := step.duplicate()
				if absf(change) > 0.003:
					var speed := minf(TURN_SPEED, float(step["most"]))
					var turn: Dictionary
					if not before.is_empty():
						var into := -1.0 if bool(before["reverse"]) else 1.0
						speed = minf(speed, float(before["most"]))
						turn = _fillet(at, heading, change, into, speed)
						before["to"] = turn["from"]
						before["end_speed"] = speed
						if into == sense:
							turn["end_speed"] = speed
					else:
						turn = _setting_off(at, heading, to, sense, speed)
						turn["end_speed"] = speed
					routed.append(turn)
					at = turn["at"]
					heading = float(turn["heading"])
				leg["end_speed"] = 0.0
				routed.append(leg)
				before = leg
				at = to
			_:
				routed.append(step)
				before = {}
	return routed


## A turn of `change` from `heading` at the corner `corner`, taken in the way `sense` (1 ahead,
## -1 backing) at `speed`, filleted so it leaves the first leg's line and lands on the next's.
func _fillet(corner: Vector2, heading: float, change: float, sense: float, speed: float) \
		-> Dictionary:
	var run := _simulate(Vector2.ZERO, heading, change, sense, speed)
	var start: Vector2 = run["start"]
	var end: Vector2 = run["end"]
	var into := Vector2(sin(heading), cos(heading)) * sense
	var out := Vector2(sin(heading + change), cos(heading + change)) * sense
	var span := into.cross(out)
	var a := (end - start).cross(out) / span
	var shift := corner - (start + into * a)
	return _placed(run, shift, sense, speed)


## A turn from a standstill at `at` facing `heading`, in the way `sense`, ending facing `to`.
func _setting_off(at: Vector2, heading: float, to: Vector2, sense: float, speed: float) \
		-> Dictionary:
	var first := (to - at).normalized() * sense
	var side := signf(angle_difference(heading, atan2(first.x, first.y)))
	var low := 0.0
	var high := PI
	var run: Dictionary = {}
	for attempt in range(32):
		var change := (low + high) / 2.0 * side
		run = _simulate(at, heading, change, sense, speed)
		var end: Vector2 = run["end"]
		var facing := Vector2(sin(heading + change), cos(heading + change)) * sense
		var still := angle_difference(atan2(facing.x, facing.y), atan2((to - end).x,
			(to - end).y))
		if signf(still) == side or is_zero_approx(still):
			low = (low + high) / 2.0
		else:
			high = (low + high) / 2.0
	return _placed(run, Vector2.ZERO, sense, speed)


## The turn's front axle traced by its kinematics: the steer wound in at the driver's pace for
## `speed`, held at the turn's lock and wound out, its sign and length giving `change`.
func _simulate(at: Vector2, heading: float, change: float, sense: float, speed: float) \
		-> Dictionary:
	var wind := STEER_RATE / maxf(speed, 0.05)
	var most := atan(WHEELBASE / TURN_RADIUS)
	var ramps := 2.0 * -log(cos(most)) / (WHEELBASE * wind)
	var hold := 0.0
	if ramps > absf(change):
		most = acos(exp(-absf(change) * WHEELBASE * wind / 2.0))
	else:
		hold = (absf(change) - ramps) * WHEELBASE / tan(most)
	var ramp := most / wind
	var length := ramp * 2.0 + hold
	var side := signf(change) * sense
	var front := at + Vector2(sin(heading), cos(heading)) * FRONT_AXLE
	var h := heading
	var samples: Array = []
	var count := maxi(ceili(length / SAMPLE), 1)
	var spacing := length / count
	var steps := 5
	for index in range(count + 1):
		var into := spacing * index
		var point := front - Vector2(sin(h), cos(h)) * FRONT_AXLE
		samples.append([into, point.x, point.y, h, _profile(into, length, ramp, most) * side])
		if index == count:
			break
		for sub in range(steps):
			var mid := into + spacing * (sub + 0.5) / steps
			var go := spacing / steps
			var steer := _profile(mid, length, ramp, most) * side
			h += go * sense * tan(steer) / WHEELBASE * 0.5
			front += Vector2(sin(h), cos(h)) * go * sense
			h += go * sense * tan(steer) / WHEELBASE * 0.5
	var last: Array = samples[samples.size() - 1]
	last[3] = heading + change
	last[4] = 0.0
	var end := Vector2(float(last[1]), float(last[2]))
	return {"samples": samples, "start": at, "end": end, "length": length,
		"heading": heading + change, "spacing": spacing}


## The steer's share of its most a distance `into` along a turn: wound in over `ramp`, held,
## and wound out over the last `ramp`.
func _profile(into: float, length: float, ramp: float, most: float) -> float:
	var r := maxf(ramp, 0.0001)
	return minf(minf(into / r, 1.0), maxf(length - into, 0.0) / r) * most


func _placed(run: Dictionary, shift: Vector2, sense: float, speed: float) -> Dictionary:
	var samples: Array = []
	for sample: Array in run["samples"]:
		samples.append([sample[0], float(sample[1]) + shift.x, float(sample[2]) + shift.y,
			sample[3], sample[4]])
	return {"do": "turn", "phase": "turn", "samples": samples, "length": run["length"],
		"spacing": run["spacing"],
		"reverse": sense < 0.0, "most": speed, "end_speed": 0.0,
		"from": Vector2(run["start"]) + shift, "at": Vector2(run["end"]) + shift,
		"heading": run["heading"]}


## Along a planned turn at its speed, slowing for Ethan in its swing or its way.
func _follow_turn(step: Dictionary, delta: float) -> bool:
	var length := float(step["length"])
	var left := length - _turn_s
	var reverse := bool(step["reverse"])
	var most := float(step["most"])
	most = minf(most, sqrt(float(step["end_speed"]) ** 2 + 2.0 * BRAKE * maxf(left, 0.0)))
	most = minf(most, _give_way(reverse))
	if _swing_blocked():
		most = 0.0
	if _speed > most:
		_speed = move_toward(_speed, most, BRAKE * delta)
	else:
		_speed = move_toward(_speed, most, ACCEL * delta)
	_turn_s = minf(_turn_s + _speed * delta, length)
	_pose_at(step["samples"], float(step["spacing"]), _turn_s)
	_look_ahead(reverse)
	_spots_for(-1.0 if reverse else 1.0)
	return _turn_s >= length - 0.0001


## Each steer wheel's angle about up for the rear's steer `steer`, by Ackermann geometry about the
## turn's centre on the front axle's line: the inner wheel steered more; a wheel's front turned
## away from the turn, as a rear wheel's is.
func _ackermann(steer: float) -> Dictionary:
	if absf(steer) < 0.0001:
		return {"SteerWheelL": 0.0, "SteerWheelR": 0.0}
	var out := WHEELBASE / tan(absf(steer))
	var near := -atan(WHEELBASE / maxf(out - TRACK / 2.0, 0.001)) * signf(steer)
	var far := -atan(WHEELBASE / (out + TRACK / 2.0)) * signf(steer)
	return {"SteerWheelL": near if steer > 0.0 else far,
		"SteerWheelR": far if steer > 0.0 else near}


## The truck's moving parts as it now stands: its steering wheel at the steer's share of its
## turns to lock, its steer wheels at their Ackermann angles, every wheel rolled by the ground
## its hub covered along its own way, and its mast tilted.
func _animate() -> void:
	var wheel := _parts.get("SteeringWheel") as Node3D
	if wheel != null:
		wheel.basis = Basis(COLUMN, -steering_turns() * TAU)
	var angles := _ackermann(_steer)
	for label: String in ["DriveWheelL", "DriveWheelR", "SteerWheelL", "SteerWheelR"]:
		var part := _parts.get(label) as Node3D
		if part == null:
			continue
		var yaw := float(angles.get(label, 0.0))
		var hub := part.global_position
		if _hubs.has(label):
			var moved: Vector3 = hub - _hubs[label]
			var ahead := (global_basis * Basis(Vector3.UP, yaw)).z
			var radius := STEER_RADIUS if label.begins_with("Steer") else DRIVE_RADIUS
			_rolled[label] = float(_rolled[label]) + moved.dot(ahead) / radius
		_hubs[label] = hub
		part.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, float(_rolled[label]))
	var mast := _parts.get("Mast") as Node3D
	if mast != null:
		mast.basis = Basis(Vector3.RIGHT, -_tilt)
	_hands()


## His hands' holds this frame: the left on the knob wherever the wheel has turned it, the right
## moving over HAND_MOVE seconds to the guard's post as he backs and to the lever otherwise; each
## wrist target WRIST_BACK from its grip toward his shoulder.
func _hands() -> void:
	if _knob == null or _wrists.size() < 2:
		return
	_grips[0] = _model.to_local(knob_point())
	var wanted := GUARD_POST if reversing() else LEVER
	if not wanted.is_equal_approx(_right_to):
		_right_from = _grips[1] if _right_to != Vector3.ZERO else wanted
		_right_to = wanted
		_right_move = 0.0
	_right_move = minf(_right_move + get_physics_process_delta_time() / HAND_MOVE, 1.0)
	var ease := _right_move * _right_move * (3.0 - 2.0 * _right_move)
	_grips[1] = _right_from.lerp(_right_to, ease)
	for index in range(2):
		var toward := (SHOULDERS[index] - _grips[index]).normalized()
		_wrists[index].position = _grips[index] + toward * WRIST_BACK


## The spinner knob on the steering wheel's rim, turning with it.
func _add_knob() -> void:
	var wheel := _parts.get("SteeringWheel") as Node3D
	if wheel == null:
		return
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = Color(0.04, 0.04, 0.045)
	plastic.roughness = 0.45
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.021
	mesh.bottom_radius = 0.019
	mesh.height = KNOB_TALL
	_knob = MeshInstance3D.new()
	_knob.name = "SpinnerKnob"
	_knob.mesh = mesh
	_knob.material_override = plastic
	wheel.add_child(_knob)
	var up := -COLUMN
	var along := KNOB_AT.normalized()
	var across := along.cross(up).normalized()
	_knob.transform = Transform3D(Basis(across, up, across.cross(up)), along * RIM
		+ up * KNOB_TALL / 2.0)


func _pose_at(samples: Array, spacing: float, s: float) -> void:
	var index := clampi(int(s / spacing), 0, samples.size() - 1)
	var a: Array = samples[index]
	var b: Array = samples[mini(index + 1, samples.size() - 1)]
	var span := float(b[0]) - float(a[0])
	var t := clampf((s - float(a[0])) / span, 0.0, 1.0) if span > 0.0 else 0.0
	var heading := lerp_angle(float(a[3]), float(b[3]), t)
	var point := Vector2(float(a[1]), float(a[2])).lerp(Vector2(float(b[1]), float(b[2])), t)
	_steer = lerpf(float(a[4]), float(b[4]), t)
	global_transform = Transform3D(Basis(Vector3.UP, heading), Vector3(point.x, FLOOR, point.y))


func _drive(step: Dictionary, delta: float) -> bool:
	var to: Vector2 = step["to"]
	var here := Vector2(global_position.x, global_position.z)
	var left := here.distance_to(to)
	var reverse := bool(step["reverse"])
	if left < 0.003:
		global_position = Vector3(to.x, FLOOR, to.y)
		return true
	var most := float(step["most"])
	most = minf(most, sqrt(float(step.get("end_speed", 0.0)) ** 2 + 2.0 * BRAKE * left))
	most = minf(most, _give_way(reverse))
	_steer = 0.0
	if _speed > most:
		_speed = move_toward(_speed, most, BRAKE * delta)
	else:
		_speed = move_toward(_speed, most, ACCEL * delta)
	var move := minf(_speed * delta, left)
	var along := (to - here).normalized() * move
	global_position += Vector3(along.x, 0.0, along.y)
	_look_ahead(reverse)
	_spots_for(-1.0 if reverse else 1.0)
	return false


## The most it may go so as to stop KEEP_CLEAR short of Ethan, if he is in its way.
func _give_way(reverse: bool) -> float:
	if walker == null or not is_instance_valid(walker):
		return INF
	var travel := global_basis.z * (-1.0 if reverse else 1.0)
	var to := walker.global_position - global_position
	var ahead := Vector2(to.x, to.z).dot(Vector2(travel.x, travel.z).normalized())
	var aside := absf(Vector2(to.x, to.z).cross(Vector2(travel.x, travel.z).normalized()))
	if ahead <= 0.0 or aside > HALF + 0.6:
		return INF
	var gap := ahead - reach_ahead() - KEEP_CLEAR - 0.15
	return sqrt(2.0 * BRAKE * maxf(gap, 0.0))


func _swing_blocked() -> bool:
	return walker != null and is_instance_valid(walker) and Vector2(walker.global_position.x
		- global_position.x, walker.global_position.z - global_position.z).length() \
		< REAR + SWING_CLEAR


func _leave(at: String) -> void:
	var building := get_parent() as Node3D
	_load.reparent(building, true)
	var place := BAY_STOP if at == "bay" else STAGE
	var facing := Basis(Vector3.UP, PI if at == "bay" else 0.0)
	var centre := Vector3(place.x, FLOOR, place.y) + facing * Vector3(0.0, 0.0, LOAD_AT)
	_load.global_transform = Transform3D(facing, centre)
	_carrying = false


func _look_ahead(reverse: bool) -> void:
	if _look != null:
		_look.set("wanted", LookTravel.LOOK_BACK if reverse else 0.0)


func _spots_for(direction: float) -> void:
	_spots[0].visible = direction > 0.0 and absf(_speed) > 0.05
	_spots[1].visible = direction < 0.0 and absf(_speed) > 0.05


func _sounds(_delta: float) -> void:
	var moving := absf(_speed) > 0.02 or absf(_spin) > 0.02
	if moving and not _motor.playing:
		_motor.play()
	elif not moving and _motor.playing:
		_motor.stop()
	_motor.pitch_scale = 0.6 + 0.5 * clampf(absf(_speed) / TOP_SPEED, 0.0, 1.0)
	var lifting := _step >= 0 and _step < _steps.size() and String(_steps[_step]["do"]) == "lift" \
		and float(_steps[_step]["to"]) > _lift
	if lifting != _pump.playing:
		if lifting:
			_pump.play()
		else:
			_pump.stop()
	var backing := reversing()
	if backing != _alarm.playing:
		if backing:
			_alarm.play()
		else:
			_alarm.stop()


func _sound(file: String, volume: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = file.to_pascal_case()
	player.stream = load(AUDIO + file + ".wav") as AudioStream
	player.volume_db = volume
	player.bus = "Ambience"
	player.unit_size = 6.0
	add_child(player)
	player.position = Vector3(0.0, 1.0, -AXLE)
	return player


func _seat_driver() -> void:
	_driver = DRIVER.instantiate() as Node3D
	_driver.name = "ForkliftDriver"
	_driver.position = SEAT
	_model.add_child(_driver)
	var player := _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.play("SitIdle")
	_skeleton = _driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_look = LookTravel.new()
	_look.name = "LookTravel"
	_skeleton.add_child(_look)
	var arms := _limbs("Hands", ["Bip01 %s UpperArm", "Bip01 %s Forearm", "Bip01 %s Hand"],
		WRISTS, [Vector3(0.45, 1.0, -0.5), Vector3(-0.45, 1.0, -0.5)])
	var legs := _limbs("Feet", ["Bip01 %s Thigh", "Bip01 %s Calf", "Bip01 %s Foot"], FEET,
		[Vector3(0.2, 1.5, 0.4), Vector3(-0.2, 1.5, 0.4)])
	arms.active = true
	legs.active = true
	for side in SIDES:
		_wrists.append(_model.find_child("Hands%sTarget" % side, false, false) as Marker3D)
	_grips = [GRIPS[0], LEVER]
	_skeleton.skeleton_updated.connect(_measure_fit)


func _limbs(label: String, bones: Array, targets: Array[Vector3], poles: Array[Vector3]) \
		-> TwoBoneIK3D:
	var ik := TwoBoneIK3D.new()
	ik.name = label
	ik.set_setting_count(2)
	_skeleton.add_child(ik)
	for index in range(2):
		var side := SIDES[index]
		ik.set_root_bone_name(index, String(bones[0]) % side)
		ik.set_middle_bone_name(index, String(bones[1]) % side)
		ik.set_end_bone_name(index, String(bones[2]) % side)
		var target := Marker3D.new()
		target.name = "%s%sTarget" % [label, side]
		target.position = targets[index]
		_model.add_child(target)
		var pole := Marker3D.new()
		pole.name = "%s%sPole" % [label, side]
		pole.position = poles[index]
		_model.add_child(pole)
		ik.set_target_node(index, ik.get_path_to(target))
		ik.set_pole_node(index, ik.get_path_to(pole))
	return ik


func _bone(label: String) -> Vector3:
	var index := _skeleton.find_bone(label)
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(index)).origin
