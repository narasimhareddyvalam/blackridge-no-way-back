extends AnimatableBody3D
## The transfer shed's electric counterbalance forklift at work (part G of step 5 of #253; the
## author's choices, #302-#303): Kamran Mughal's truck (CC BY), its carriage cut free to ride up
## its mast (`convert_depot_models.py`), driven by a Rocketbox warehouse worker
## (`Construction_Male_07`, MIT) seated at the wheel, his hands on it and his feet on the plate by
## two-bone IK, his head turned the way he travels (`look_travel.gd`). While the camera is within
## ACTIVE_REACH of it, it works in trips: a pallet of its own from dock 6's staging lane to an
## empty floor place facing aisle 03 (z 7.56 on row 3's west frames), then back again, as a
## putaway and a pick; between trips it parks where it stood, over its oil drip (part D).
##
## It moves as a three-wheel electric truck does in a tight shed: straight runs, and turns on
## the spot about its front axle, this node's origin. OSHA 1910.178(n): the load carried low
## (TRAVEL_LIFT), never over 5 mph (2.2 m/s) and slower in the aisle, its horn at the aisle's
## mouth, its blue spot projected ahead of it in its direction of travel, its broadband alarm
## while it backs, and it gives way to Ethan: it slows so as to stop KEEP_CLEAR short of him in
## its way, and does not turn while he stands within its swing. The mast does not tilt: the
## model's mast is not cut from its body.

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
const LIFT_RATE := 0.15
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
## place, aisle 03's mouth, where it turns in the aisle and the floor place.
const HOME := Vector3(-63.150, FLOOR, 12.645)
const HOME_HEADING := 0.2
const LANE := Vector2(-60.0, 12.0)
const STAGE := Vector2(-60.0, 15.32)
const MOUTH := Vector2(-66.1, 12.0)
const AISLE_TURN := Vector2(-66.1, 7.56)
const SLOT := Vector2(-64.77, 7.56)
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
			GRIPS[index])))
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
		_sounds(delta)
		return
	_run_step(delta)
	_sounds(delta)


func _plan() -> void:
	var home := Vector2(HOME.x, HOME.z)
	_steps = []
	if _to_slot:
		_steps.append_array([_go("to_lane", LANE, false, TOP_SPEED), _turn(0.0),
			_go("to_stage", STAGE, false, CREEP), {"do": "take"}, _raise(TRAVEL_LIFT),
			_go("from_stage", LANE, true, REVERSE_SPEED), {"do": "horn"},
			_go("to_mouth", MOUTH, false, TOP_SPEED), {"do": "horn"},
			_turn(PI), _go("down_aisle", AISLE_TURN, false, AISLE_SPEED), _turn(PI / 2.0),
			_go("to_slot", SLOT, false, CREEP), _raise(0.0), {"do": "leave", "at": "slot"},
			_go("from_slot", AISLE_TURN, true, CREEP), _turn(0.0),
			_go("up_aisle", MOUTH, false, AISLE_SPEED), {"do": "horn"},
			_go("to_home", home, false, TOP_SPEED), _turn(HOME_HEADING)])
	else:
		_steps.append_array([{"do": "horn"}, _go("to_mouth", MOUTH, false, TOP_SPEED),
			{"do": "horn"}, _turn(PI), _go("down_aisle", AISLE_TURN, false, AISLE_SPEED),
			_turn(PI / 2.0), _go("to_slot", SLOT, false, CREEP), {"do": "take"},
			_raise(TRAVEL_LIFT), _go("from_slot", AISLE_TURN, true, CREEP), _turn(0.0),
			_go("up_aisle", MOUTH, false, AISLE_SPEED), {"do": "horn"},
			_go("to_lane", LANE, false, TOP_SPEED), _turn(0.0),
			_go("to_stage", STAGE, false, CREEP), _raise(0.0), {"do": "leave", "at": "stage"},
			_go("from_stage", LANE, true, REVERSE_SPEED),
			_go("to_home", home, false, TOP_SPEED), _turn(HOME_HEADING)])
	_step = -1
	_next()


func _go(label: String, to: Vector2, reverse: bool, most: float) -> Dictionary:
	return {"do": "drive", "phase": label, "to": to, "reverse": reverse, "most": most}


func _turn(heading: float) -> Dictionary:
	return {"do": "turn", "to": heading}


func _raise(height: float) -> Dictionary:
	return {"do": "lift", "to": height}


func _next() -> void:
	_step += 1
	_speed = 0.0
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
	if step["do"] == "drive":
		var to: Vector2 = step["to"]
		var way := to - Vector2(global_position.x, global_position.z)
		if way.length() > 0.01:
			var facing := way.normalized() * (-1.0 if bool(step["reverse"]) else 1.0)
			var heading := atan2(facing.x, facing.y)
			var now := atan2(global_basis.z.x, global_basis.z.z)
			if absf(angle_difference(now, heading)) > 0.002:
				_steps.insert(_step, _turn(heading))
				_phase = "turn"


func _run_step(delta: float) -> void:
	var step: Dictionary = _steps[_step]
	match String(step["do"]):
		"turn":
			if _turn_toward(float(step["to"]), delta):
				_next()
		"drive":
			if _drive(step, delta):
				_next()
		"lift":
			_lift = move_toward(_lift, float(step["to"]), LIFT_RATE * delta)
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


func _turn_toward(heading: float, delta: float) -> bool:
	var now := atan2(global_basis.z.x, global_basis.z.z)
	var left := angle_difference(now, heading)
	if absf(left) < 0.002:
		global_basis = Basis(Vector3.UP, heading)
		_spin = 0.0
		return true
	if _swing_blocked():
		_spin = move_toward(_spin, 0.0, SPIN_ACCEL * 2.0 * delta)
	else:
		var most := minf(SPIN_RATE, sqrt(2.0 * SPIN_ACCEL * absf(left)))
		_spin = move_toward(_spin, most, SPIN_ACCEL * delta)
	var turn := minf(_spin * delta, absf(left)) * signf(left)
	global_basis = Basis(Vector3.UP, now + turn)
	_look_ahead(false)
	_spots_for(0.0)
	return false


func _drive(step: Dictionary, delta: float) -> bool:
	var to: Vector2 = step["to"]
	var here := Vector2(global_position.x, global_position.z)
	var left := here.distance_to(to)
	var reverse := bool(step["reverse"])
	if left < 0.003:
		global_position = Vector3(to.x, FLOOR, to.y)
		return true
	var most := float(step["most"])
	most = minf(most, sqrt(2.0 * BRAKE * left))
	most = minf(most, _give_way(reverse))
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
	var place := SLOT if at == "slot" else STAGE
	var facing := Basis(Vector3.UP, PI / 2.0 if at == "slot" else 0.0)
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
	var arms := _limbs("Hands", ["Bip01 %s UpperArm", "Bip01 %s Forearm", "Bip01 %s Hand"],
		WRISTS, [Vector3(0.45, 1.0, -0.5), Vector3(-0.45, 1.0, -0.5)])
	var legs := _limbs("Feet", ["Bip01 %s Thigh", "Bip01 %s Calf", "Bip01 %s Foot"], FEET,
		[Vector3(0.2, 1.5, 0.4), Vector3(-0.2, 1.5, 0.4)])
	arms.active = true
	legs.active = true
	_look = LookTravel.new()
	_look.name = "LookTravel"
	_skeleton.add_child(_look)
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
