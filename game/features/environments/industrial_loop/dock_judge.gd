extends Node
## Judges each stop at one dock's bumpers as bay 9 does (`van_bay.gd`, rules G4-G6), for the
## warehouse compound's door 3 (Mission 2's step 5, part C): docked within the reversing
## camera's red stop line of the bumpers' face (0.10 m), 3 degrees of square and 0.1 m of the
## door's centre line, arrived at walking pace (1.4 m/s or less) with the rear doors open; any
## other stop there is a miss, named for the first thing wrong. It reads the van and moves nothing.

signal changed

const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
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

var verdict := ""
var measured := {"gap": 0.0, "angle": 0.0, "offset": 0.0, "arrived": 0.0}
var vehicle: CharacterBody3D
## The door's centre line (x), its bumpers' face (z, the van backing toward -z) and how far
## either side of the centre line its bumpers stand.
var centre_x := 0.0
var bumpers_z := 0.0
var bumper_off := 1.1

var _arrived := 0.0
var _still := 0.0
var _judged := false


func reset() -> void:
	_decide("")
	_arrived = 0.0
	_still = 0.0
	_judged = false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	var rear := vehicle.to_global(REAR)
	var gap := rear.z - bumpers_z
	var facing := vehicle.global_basis.z.normalized().z < -0.9
	if not facing or absf(rear.x - centre_x) > LINED_UP or gap > AT_BAY:
		_arrived = 0.0
		_still = 0.0
		_judged = false
		if verdict != "":
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
		gap = minf(gap, (rear + across * side * bumper_off).z - bumpers_z)
	var square := rad_to_deg(acos(clampf(-vehicle.global_basis.z.normalized().z, -1.0, 1.0)))
	var offset := absf(rear.x - centre_x)
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
