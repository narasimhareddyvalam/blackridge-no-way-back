extends Node

signal objective_changed(title: String, detail: String)

const MISSION := "the_wrong_cargo"
const NAME := "The Wrong Cargo"
const PLACES: Array[String] = ["The freight depot", "The transfer shed", "The container yard",
	"The warehouse compound"]
const NEXT: Array[String] = ["The transfer shed", "The container yard", "The warehouse compound",
	"The hill road"]
const START := Transform3D(Basis(Vector3.UP, PI), Vector3(-28.0, 0.1, 93.0))
const TITLE_EYE := Vector3(3.2, 1.0, -9.5)
const TITLE_LOOK := Vector3(1.3, 1.3, 0.7)
const TITLE_FOV := 32.0

var vehicle: CharacterBody3D
var stage: int = 0
var recovery_pose := START
var fleeing: bool = false
var active: bool = false
var shed: Node3D

var _shown := ""


static func valid_progress(config: ConfigFile) -> bool:
	var value: Variant = config.get_value("cargo", "stage", -1)
	return config.get_value("save", "mission", "") == MISSION and value is int and value >= 0 \
		and value < PLACES.size()


static func start_progress() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("save", "mission", MISSION)
	config.set_value("cargo", "stage", 0)
	return config


func configure(van: CharacterBody3D, config: ConfigFile) -> void:
	vehicle = van
	stage = config.get_value("cargo", "stage")
	recovery_pose = START
	vehicle.recover(recovery_pose)
	if shed != null:
		shed.reset()
		shed.watch(vehicle)
	_shown = ""
	_update_objective()


func wants_interact() -> bool:
	return active and stage == 0 and shed != null and shed.vehicle_at_stop() \
		and not shed.barrier_open() and not shed.checking()


func interact() -> String:
	if absf(float(vehicle.get("speed"))) > 0.3:
		return "Stop at the line first."
	shed.hand_run_sheet()
	_update_objective()
	return "You hand the guard the run sheet."


func recover() -> void:
	vehicle.recover(recovery_pose)


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


func _physics_process(_delta: float) -> void:
	if active and stage == 0:
		_update_objective()


func _update_objective() -> void:
	var title := "MISSION 2 IS BEING BUILT"
	var detail := "Next: %s." % NEXT[stage].to_lower()
	if stage == 0 and shed != null:
		if shed.vehicle_through():
			detail = "Next: backing onto the dock."
		elif shed.checking():
			title = "WAIT AT THE GATE"
			detail = "The guard is checking the run sheet."
		elif shed.barrier_open():
			title = "DRIVE THROUGH THE GATE"
			detail = "The barrier is up."
		elif shed.vehicle_near():
			title = "STOP AT THE GATE"
			detail = "Stop at the line, then press E to hand the guard the run sheet."
		else:
			title = "DRIVE TO THE TRANSFER SHED"
			detail = "Take the spur north off the valley road, just west of the depot."
	if title + detail != _shown:
		_shown = title + detail
		objective_changed.emit(title, detail)
