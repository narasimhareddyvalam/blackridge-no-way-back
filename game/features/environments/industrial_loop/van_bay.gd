extends Node
## Bay 9, the transfer shed's van bay (docs/PHASE_BRIEF.md, step 2d, rules G2 and G4–G6): judges
## each stop at its bumpers by where and how the van ended up, and holds the chock. A stop counts
## as docked within 0.3 m of the bumpers' face, 3 degrees of square and 0.1 m of the bay's centre
## line, arrived at walking pace (1.4 m/s or less) with the rear doors open; any other stop there
## is a miss, named for the first thing wrong, so the driver pulls forward and tries again (the
## author's U3 a, #228). Docked, Ethan chocks the driver's-side rear wheel (U1 a); then the bay's
## lights turn, red outside and green inside. It reads the van and moves only the chock. Since
## step 2e it also works the bay's dock lift from its pendant: down to the docked van's floor with
## the bridge plate laid on it, or to the pit's lowest with no van, and back up.

signal changed

const CENTRE_X := -47.75
const TransferBuilding = preload("transfer_building.gd")
## The dock's two bumpers, either side of the bay's centre line.
const BUMPER_X := TransferBuilding.VAN_BUMPER_OFF
const BUMPERS_Z := 20.13
const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
## Docked within the reversing camera's red stop line (#287): one distance for both.
const DOCKED_WITHIN := ParkingGuides.STOP_LINE
const SQUARE_WITHIN := 3.0
const CENTRED_WITHIN := 0.1
const GENTLE := 1.4
const SETTLE := 0.5
const STILL := 0.05
const AT_BAY := 1.0
const ARRIVING := 0.4
const LINED_UP := 1.5
const REAR := Vector3(0.0, 1.0, 3.01)
const WHEEL_FRONT := Vector3(-0.872, 0.15, 1.48)
const REACH := 1.0
const HOLD_FLOOR := Vector3(0.0, 0.614, 2.5)
const LOWEST := 0.42
const ON_DECK := Vector2(0.95, 1.25)

var verdict := ""
var chocked := false
var measured := {"gap": 0.0, "angle": 0.0, "offset": 0.0, "arrived": 0.0}
var vehicle: CharacterBody3D

var _building: Node3D
var _chock: Node3D
var _lift: Node3D
## Whose hand is on the pendant's button, or null: the lift stops when E is let go or he leaves.
var _holder: Node3D
var _rest := Transform3D()
var _arrived := 0.0
var _still := 0.0
var _judged := false


func setup(building: Node3D, chock: Node3D, lift: Node3D) -> void:
	_building = building
	_chock = chock
	_lift = lift
	_rest = chock.transform


func reset() -> void:
	if chocked:
		unchock()
	if _lift != null:
		_lift.call("reset")
	_decide("")
	_arrived = 0.0
	_still = 0.0
	_judged = false


## What E does to the lift for Ethan at `at`, on its deck, by its pendant, or "".
func lift_action(at: Vector3) -> String:
	if _lift == null or bool(_lift.call("moving")) or not _at_controls(at):
		return ""
	if bool(_lift.call("travelling")):
		return "Hold to raise the lift" if bool(_lift.call("rising")) \
			else "Hold to lower the lift"
	return "Hold to lower the lift" if bool(_lift.call("at_top")) else "Hold to raise the lift"


## Whether Ethan at `at` can work the lift: on its deck or within reach of its pendant.
func _at_controls(at: Vector3) -> bool:
	var deck := _lift.global_position
	var on_deck := absf(at.x - deck.x) < ON_DECK.x and absf(at.z - deck.z) < ON_DECK.y \
		and absf(at.y - deck.y) < 0.3
	return on_deck or pendant_reach(at) <= REACH


## How far Ethan at `at` is from the lift's pendant, across the deck, or INF on another level.
func pendant_reach(at: Vector3) -> float:
	var spot: Vector3 = _lift.call("pendant")
	if absf(at.y - spot.y) > 0.3:
		return INF
	return Vector2(at.x - spot.x, at.z - spot.z).length()


## E pressed at the pendant by `holder`, who holds the button until he lets go or leaves.
func operate_lift(holder: Node3D = null) -> void:
	_holder = holder if holder != null else _lift
	if bool(_lift.call("travelling")):
		_lift.call("resume")
		return
	_lift.call("hold", true)
	if bool(_lift.call("at_top")):
		var docked := verdict == "docked" and is_instance_valid(vehicle)
		var level := (vehicle.call("floor_point", HOLD_FLOOR) as Vector3).y if docked else LOWEST
		_lift.call("lower", level, docked, vehicle if docked else null)
	else:
		_lift.call("raise")


## How far the van's rear stands from the bumpers' face while it is lined up with the bay, or
## INF once it is elsewhere (step 2e-3, rule H4).
func clearance() -> float:
	if not is_instance_valid(vehicle):
		return INF
	var rear := vehicle.to_global(REAR)
	if absf(rear.x - CENTRE_X) > LINED_UP or rear.z < BUMPERS_Z - 0.5:
		return INF
	return rear.z - BUMPERS_Z


func can_chock(at: Vector3) -> bool:
	return verdict == "docked" and not chocked and _near_wheel(at)


func can_unchock(at: Vector3) -> bool:
	return chocked and _near_wheel(at)


func chock_wheel() -> void:
	chocked = true
	_chock.global_transform = vehicle.global_transform * Transform3D(Basis.IDENTITY, WHEEL_FRONT)
	vehicle.set("chocked", true)
	_building.call("set_bay_nine_docked", true)
	changed.emit()


func unchock() -> void:
	chocked = false
	_chock.transform = _rest
	if is_instance_valid(vehicle):
		vehicle.set("chocked", false)
	_building.call("set_bay_nine_docked", false)
	changed.emit()


func _physics_process(delta: float) -> void:
	if _holder != null and (not Input.is_action_pressed("interact")
			or not is_instance_valid(_holder)
			or (_holder != _lift and not _at_controls(_holder.global_position))):
		_holder = null
		_lift.call("hold", false)
	if not is_instance_valid(vehicle):
		return
	if chocked:
		if not bool(vehicle.get("chocked")):
			unchock()
		return
	var rear := vehicle.to_global(REAR)
	var gap := rear.z - BUMPERS_Z
	var facing := vehicle.global_basis.z.normalized().z < -0.9
	if not facing or absf(rear.x - CENTRE_X) > LINED_UP or gap > AT_BAY:
		_arrived = 0.0
		_still = 0.0
		_judged = false
		if verdict == "docked":
			_decide("")
		return
	var speed := absf(float(vehicle.get("actual_speed")))
	if gap < ARRIVING:
		_arrived = maxf(_arrived, speed)
	if speed > STILL:
		_still = 0.0
		_judged = false
		if verdict == "docked":
			_decide("")
		return
	_still += delta
	if _still >= SETTLE and not _judged:
		_judged = true
		_judge(rear, gap)


func _judge(rear: Vector3, centre_gap: float) -> void:
	var gap := centre_gap
	var across := vehicle.global_basis.x.normalized()
	for side: float in [-1.0, 1.0]:
		gap = minf(gap, (rear + across * side * BUMPER_X).z - BUMPERS_Z)
	var square := rad_to_deg(acos(clampf(-vehicle.global_basis.z.normalized().z, -1.0, 1.0)))
	var offset := absf(rear.x - CENTRE_X)
	measured = {"gap": maxf(gap, 0.0), "angle": square, "offset": offset, "arrived": _arrived}
	var result := "docked"
	if _arrived > GENTLE:
		result = "fast"
	elif gap > DOCKED_WITHIN:
		result = "far"
	elif square > SQUARE_WITHIN:
		result = "crooked"
	elif offset > CENTRED_WITHIN:
		result = "off_centre"
	elif not bool(vehicle.get("rear_doors_open")):
		result = "doors"
	_decide(result)


func _decide(value: String) -> void:
	if verdict != value:
		verdict = value
		changed.emit()


func _near_wheel(at: Vector3) -> bool:
	if not is_instance_valid(vehicle):
		return false
	var spot := vehicle.to_global(WHEEL_FRONT)
	return Vector2(at.x - spot.x, at.z - spot.z).length() < REACH
