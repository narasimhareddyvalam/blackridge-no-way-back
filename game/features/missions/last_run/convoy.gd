extends Node
## Mission 3's step 5, part B: the convoy (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360; GAME_STORY's
## Act V). Two black SUVs, Adrian in the second, north on the coastal road to the airfield. Ethan
## tails them: within TOO_CLOSE for SPOTTED_AFTER they see him; beyond TOO_FAR he loses them (either
## way `spotted`, and the app puts him back at the junction with the convoy ahead again). At the
## airfield's gate the lead stops while its driver keys in, the gate opens, both drive through to
## the apron and the gate shuts behind them (`inside`). Words and choices are Claude Code's (#359).

signal spotted(lost: bool)

const SUV = preload("res://features/vehicles/scripted_suv/scripted_suv.gd")
const STARTS: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3(726.0, 0.0, 95.0)),
	Transform3D(Basis.IDENTITY, Vector3(726.0, 0.0, 117.0))]
const SPEED := 9.0
const SPACING := 22.0
const TOO_CLOSE := 25.0
const TOO_FAR := 200.0
const SPOTTED_AFTER := 2.0
const KEYING := 3.0
const GATE_STOP := 12.0

var suvs: Array[Node3D] = []
var spotted_count := 0
var inside := false
var running := false
var vehicle: CharacterBody3D
var airfield: Node3D
var _close_for := 0.0
var _keying := -1.0
var _waiting := false


func _ready() -> void:
	for at in STARTS:
		var suv := SUV.new()
		add_child(suv)
		suv.place(at)
		suv.visible = false
		suvs.append(suv)


func _route(start: Vector3, behind: float) -> Array[Vector3]:
	var gate: Vector3 = airfield.get("gate")
	var apron: Rect2 = airfield.get("apron")
	return [Vector3(start.x, 0.0, gate.z), gate + Vector3(-GATE_STOP - behind, 0.0, 0.0), gate
		+ Vector3(20.0, 0.0, 0.0), Vector3(apron.position.x + 10.0, 0.0, gate.z),
		Vector3(apron.get_center().x - 25.0, 0.0, apron.get_center().y)]


## Ahead of him on the coastal road, lights on, heading north.
func start() -> void:
	running = true
	inside = false
	_close_for = 0.0
	_keying = -1.0
	_waiting = false
	airfield.call("close_gate")
	for index in range(suvs.size()):
		var suv := suvs[index]
		suv.visible = true
		suv.call("place", STARTS[index])
		suv.call("set_lights", true)
		suv.call("drive", _route(STARTS[index].origin, index * 8.0), SPEED)


func stop() -> void:
	running = false
	for suv in suvs:
		suv.call("drive", [] as Array[Vector3], 0.0)


func _physics_process(delta: float) -> void:
	if not running or vehicle == null or airfield == null:
		return
	_gate(delta)
	if inside:
		return
	var tail := suvs[1]
	var apart := Vector2(vehicle.global_position.x - tail.global_position.x,
		vehicle.global_position.z - tail.global_position.z).length()
	if apart > TOO_FAR:
		_spot(true)
		return
	_close_for = _close_for + delta if apart < TOO_CLOSE else 0.0
	if _close_for >= SPOTTED_AFTER:
		_spot(false)


## The gate: the lead waits at its stop while the code is keyed, the gate opens, and it shuts once
## both are through.
func _gate(delta: float) -> void:
	var gate: Vector3 = airfield.get("gate")
	var lead := suvs[0]
	if not _waiting and _keying < 0.0 and not bool(airfield.call("gate_open")) \
			and Vector2(lead.global_position.x - (gate.x - GATE_STOP),
			lead.global_position.z - gate.z).length() < 1.0:
		_waiting = true
		_keying = KEYING
		for suv in suvs:
			suv.set("speed", 0.0)
	if _keying >= 0.0:
		_keying -= delta
		if _keying < 0.0:
			airfield.call("open_gate")
	if _waiting and _keying < 0.0 and bool(airfield.call("gate_open")):
		_waiting = false
		for suv in suvs:
			suv.set("speed", SPEED)
	var through := true
	for suv in suvs:
		through = through and suv.global_position.x > gate.x + 15.0
	if through and not inside:
		inside = true
		airfield.call("close_gate")


func _spot(lost: bool) -> void:
	running = false
	spotted_count += 1
	spotted.emit(lost)
