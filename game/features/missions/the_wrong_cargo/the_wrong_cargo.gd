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
const VAN_REAR := 3.01
const REAR_REACH := Vector2(0.6, 1.8)
const REAR_WIDTH := 1.2
const MISSES := {
	"fast": "Too fast: you met the dock at %.1f m/s. Pull forward and back in at walking pace.",
	"far": "%.1f m short of the bumpers. Back in until they stop you.",
	"crooked": "%.1f° off square. Pull forward, straighten up and back in.",
	"off_centre": "%.2f m off the bay's centre. Pull forward and line up between the guides.",
	"doors": "The rear doors are shut and can't open against the dock. Pull forward and open them.",
}
const MEASURES := {"fast": "arrived", "far": "gap", "crooked": "angle", "off_centre": "offset"}

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


## What Ethan, on foot at `at`, can do here with E, or "" when nothing: the van's rear doors
## from behind it, while it stands still.
func foot_action(at: Vector3) -> String:
	if not active or vehicle == null or bool(vehicle.get("occupied")):
		return ""
	var bay := _bay()
	if bay != null and bool(bay.call("can_chock", at)):
		return "Chock the rear wheel"
	if bay != null and bool(bay.call("can_unchock", at)):
		return "Take the chock out"
	if _behind_the_van(at) and absf(float(vehicle.get("speed"))) < 0.1:
		return "Close the rear doors" if bool(vehicle.get("rear_doors_open")) \
			else "Open the rear doors"
	return ""


func do_foot_action(at: Vector3) -> String:
	match foot_action(at):
		"Chock the rear wheel":
			_bay().call("chock_wheel")
			return "You set the chock in front of the rear wheel."
		"Take the chock out":
			_bay().call("unchock")
			return "You take the chock out and hang it back on the dock."
		"Open the rear doors":
			vehicle.set("rear_doors_open", true)
			return "You swing the rear doors round and hook them back against the sides."
		"Close the rear doors":
			vehicle.set("rear_doors_open", false)
			return "You close the rear doors."
	return ""


func _bay() -> Node:
	return shed.get("bay_nine") as Node if shed != null else null


func _behind_the_van(at: Vector3) -> bool:
	var local := vehicle.to_local(at)
	return local.z > VAN_REAR + REAR_REACH.x and local.z < VAN_REAR + REAR_REACH.y \
		and absf(local.x) < REAR_WIDTH


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
			var bay := _bay()
			var verdict: String = bay.get("verdict")
			if bool(bay.get("chocked")):
				detail = "Next: the load."
			elif verdict == "docked":
				title = "CHOCK THE WHEEL"
				detail = "Get out and press E at the rear wheel on the driver's side."
			elif MISSES.has(verdict):
				title = "BACK ONTO BAY 9"
				detail = MISSES[verdict]
				if MEASURES.has(verdict):
					detail = detail % float((bay.get("measured") as Dictionary)[MEASURES[verdict]])
			elif not bool(vehicle.get("rear_doors_open")):
				title = "OPEN THE REAR DOORS"
				detail = "They can't open once docked: stop, get out and press E at the back."
			else:
				title = "BACK ONTO BAY 9"
				detail = "Press Q for reverse, then back in slowly between the guides to the bumpers."
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
