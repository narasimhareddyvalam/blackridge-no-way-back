extends Node
## Mission 2's step 6, the escape (docs/PHASE_BRIEF.md, 2026-11-18; the author's choices, #319;
## built overnight at the author's word, #358). Docked at door 3, the turn: two guards walk out
## of the east warehouse's man door toward the van, a third stands inside the gate; why they turn
## on Ethan stays unsaid (S1). Staying in the van, he is caught when the first reaches the cab.
## Out of it, the guards walk their rounds: one along the north strip east of the gate, one along
## the west warehouse's front by the cut, the third at the gate looking side to side. A guard who
## sees him for CATCH_AFTER without a break, or comes within NEAR, catches him: `caught`, and the
## app puts all back as at the escape's start (`reset`). WARN_AFTER after he is out, a text from
## an unknown number (secretly Maya, S3; its words a draft) tells him of the cut.
## The guards are stand-ins (D6): Assignment 9 replaces their behaviour, not their places.

signal caught
signal warning(sender: String, words: String)

const PatrolGuard = preload("res://features/characters/patrol_guard/patrol_guard.gd")
const CATCH_AFTER := 1.0
const NEAR := 1.5
const FORGET_RATE := 0.5
const CHEST := 1.2
const IN_VAN_CATCH := 1.0
const WARN_AFTER := 4.0
const SENDER := "UNKNOWN NUMBER"
const WARNING := "Don't go for the gate. The fence by the containers is cut. Wait for the " \
	+ "torch to turn."
const FLOOR := 0.02
## Each guard: where he starts (facing his -Z), the points he walks, his wait at each end and
## how far he looks either side standing. The first two come out of the east warehouse's man
## door (x 234.6) toward the van at door 3; the first stops at its cab, then walks the north
## strip east of the gate; the second walks on west to the strip north of the trailers dropped at
## the west warehouse, by the cut, and back.
const GUARDS := [
	{"at": Vector3(234.6, FLOOR, 133.4), "yaw": -PI / 2.0, "wait": 3.0, "look": 0.0,
		"route": [Vector3(245.4, FLOOR, 135.6), Vector3(242.0, FLOOR, 141.0),
			Vector3(208.0, FLOOR, 141.0)]},
	{"at": Vector3(233.4, FLOOR, 134.6), "yaw": -PI / 2.0, "wait": 3.0, "look": 0.0,
		"route": [Vector3(243.0, FLOOR, 136.4), Vector3(228.0, FLOOR, 136.0),
			Vector3(171.0, FLOOR, 139.5), Vector3(141.5, FLOOR, 139.5)]},
	{"at": Vector3(200.0, FLOOR, 142.0), "yaw": 0.0, "wait": 0.0, "look": deg_to_rad(45.0),
		"route": []},
]

var guards: Array[Node3D] = []
var caught_count := 0
var warned := false
var warnings_sent := 0
var vehicle: CharacterBody3D
var driver: CharacterBody3D
## The compound's fence outline (x, z); once Ethan is out of it, through the cut, the guards
## inside no longer catch him.
var area := PackedVector2Array()
var outside := false
var _out_for := 0.0
var _in_van_for := 0.0
var _catching := false


func _ready() -> void:
	for index in range(GUARDS.size()):
		var plan: Dictionary = GUARDS[index]
		var guard := PatrolGuard.new()
		guard.name = "PatrolGuard%d" % (index + 1)
		add_child(guard)
		var points: Array[Vector3] = []
		points.assign(plan["route"])
		guard.setup(Transform3D(Basis(Vector3.UP, plan["yaw"]), plan["at"]), points,
			plan["wait"], plan["look"])
		guards.append(guard)


## All as at the escape's start: the guards where they came from, the warning unsent.
func reset() -> void:
	for guard in guards:
		var plan: Dictionary = GUARDS[guards.find(guard)]
		var points: Array[Vector3] = []
		points.assign(plan["route"])
		guard.call("setup", Transform3D(Basis(Vector3.UP, plan["yaw"]), plan["at"]), points,
			plan["wait"], plan["look"])
	warned = false
	outside = false
	_out_for = 0.0
	_in_van_for = 0.0
	_catching = false


func _physics_process(delta: float) -> void:
	if _catching or vehicle == null or driver == null:
		return
	if bool(vehicle.get("occupied")):
		var lead := guards[0]
		_in_van_for = _in_van_for + delta if bool(lead.get("arrived_first")) else 0.0
		if _in_van_for >= IN_VAN_CATCH:
			_catch()
		return
	if not bool(driver.get("active")):
		return
	if not area.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(
			driver.global_position.x, driver.global_position.z), area):
		outside = true
	if outside:
		return
	_out_for += delta
	if not warned and _out_for >= WARN_AFTER:
		warned = true
		warnings_sent += 1
		warning.emit(SENDER, WARNING)
	var chest := driver.global_position + Vector3.UP * CHEST
	var exclude: Array[RID] = [driver.get_rid()]
	for guard in guards:
		var apart := Vector2(guard.global_position.x - driver.global_position.x,
			guard.global_position.z - driver.global_position.z).length()
		if apart <= NEAR:
			_catch()
			return
		var seen := bool(guard.call("sees", chest, exclude))
		var held: float = guard.get("sight")
		held = held + delta if seen else maxf(held - delta * FORGET_RATE, 0.0)
		guard.set("sight", held)
		if held >= CATCH_AFTER - 0.0001:
			_catch()
			return


## The most any guard has seen him, 0..1 (for the HUD's warning of being seen).
func seen_share() -> float:
	var most := 0.0
	for guard in guards:
		most = maxf(most, float(guard.get("sight")) / CATCH_AFTER)
	return clampf(most, 0.0, 1.0)


func _catch() -> void:
	_catching = true
	caught_count += 1
	caught.emit()
