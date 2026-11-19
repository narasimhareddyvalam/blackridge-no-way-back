extends Node

signal objective_changed(title: String, detail: String)
signal seal_checked(words: String)
signal checkpoint_reached(config: ConfigFile)

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
	"far": "%.1f m short of the bumpers. Back in until the red line reaches them.",
	"crooked": "%.1f° off square. Pull forward, straighten up and back in.",
	"off_centre": "%.2f m off the bay's centre. Pull forward and line up between the guides.",
	"doors": "The rear doors are shut and can't open against the dock. Pull forward and open them.",
}
const MEASURES := {"fast": "arrived", "far": "gap", "crooked": "angle", "off_centre": "offset"}
const CLEAR_OF_DOCK := 2.5
const SEAL_NUMBER := "4182260"
const LOADED_AT := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
## Where the dark van waits in the container yard, nose to the gate (`container_yard.gd`).
const DARK_VAN := Transform3D(Basis(Vector3.UP, PI), Vector3(104.5, 0.1, 140.0))
## The dark van docked at the compound's door 3 (step 5): its rear 0.03 m off the bumpers.
const AT_DOOR_THREE := Transform3D(Basis(Vector3.UP, PI), Vector3(248.0, 0.1, 134.67))
const SEAL_CHECK := "BOLT SEAL CHECK\n\nBolt ............ %s\nCap ............. %s\n" \
	+ "Run sheet ....... %s\n\nViewed, verified, tugged and twisted:\nthe same number, whole " \
	+ "and tight."

var vehicle: CharacterBody3D
var stage: int = 0
var recovery_pose := START
var fleeing: bool = false
var active: bool = false
var shed: Node3D
## The container yard (step 4): its gate, its bay and the dark van; the app gives it.
var yard: Node3D
## The warehouse compound (step 5): its booth, gate and doors; the app gives it.
var compound: Node3D
## Ethan on foot, who works the van's rear doors by hand (part B); the app gives him.
var driver: Node3D

var _shown := ""
var _seal_checked := false
var _hand_when_shut := false


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
	recovery_pose = [START, LOADED_AT, DARK_VAN, AT_DOOR_THREE][stage]
	vehicle.recover(recovery_pose)
	vehicle.call("unload")
	(vehicle.get_node("VanPresentation") as Node).call("set_paint", Color.WHITE)
	_seal_checked = stage >= 1
	if yard != null:
		yard.call("reset")
		yard.call("watch", vehicle)
	if compound != null:
		compound.call("reset")
		compound.call("watch", vehicle)
		var judge := compound.get("judge") as Node
		if judge != null and not judge.is_connected("changed", _judged):
			judge.connect("changed", _judged)
	if shed != null:
		shed.reset()
		shed.watch(vehicle)
		if stage == 1:
			shed.call("restore_loaded", vehicle, SEAL_NUMBER)
		elif stage >= 2 and yard != null:
			yard.call("restore_swapped", vehicle, func() -> void:
				shed.call("restore_loaded", vehicle, SEAL_NUMBER))
	if stage == 3:
		vehicle.recover(recovery_pose)
		restore_place()
	_shown = ""
	_update_objective()


func wants_interact() -> bool:
	if active and stage == 2 and compound != null:
		return bool(compound.call("vehicle_at_booth")) and bool(compound.call("gate_shut")) \
			and not bool(compound.call("checking"))
	if active and stage == 1 and yard != null:
		return bool(yard.call("vehicle_at_stop")) and bool(yard.call("gate_shut")) \
			and not bool(yard.call("keying"))
	return active and stage == 0 and shed != null and shed.vehicle_at_stop() \
		and not shed.barrier_open() and not shed.checking()


func interact() -> String:
	if absf(float(vehicle.get("speed"))) > 0.3:
		return "Stop at the line first."
	if stage == 1:
		yard.call("key_in")
		_update_objective()
		return "You key in the gate code from the run sheet."
	if stage == 2:
		compound.call("hand_run_sheet")
		_update_objective()
		return "You hand the guard the run sheet."
	shed.hand_run_sheet()
	_update_objective()
	return "You hand the guard the run sheet."


## What Ethan, on foot at `at`, can do here with E, or "" when nothing: the van's rear doors
## from behind it, while it stands still.
func foot_action(at: Vector3) -> String:
	if not active or vehicle == null or bool(vehicle.get("occupied")):
		return ""
	if stage == 1 and yard != null and bool(yard.call("at_dark_door", at)):
		return "Take the dark van" if bool(yard.call("in_bay")) \
			else "Leave your van in the marked bay first"
	var jack := _jack()
	if jack != null and bool(jack.get("held")):
		return jack.call("action", at)
	var bay := _bay()
	var door: Node = shed.get("side_door") if shed != null else null
	if door != null and not bool(door.get("door_open")) and bool(door.call("near_door", at)):
		return "Open the door"
	var lift_text: String = bay.call("lift_action", at) if bay != null else ""
	var jack_text: String = jack.call("action", at) if jack != null else ""
	if not lift_text.is_empty() and not jack_text.is_empty():
		var lift_nearer := float(bay.call("pendant_reach", at)) < float(jack.call("reach", at))
		return lift_text if lift_nearer else jack_text
	if not lift_text.is_empty() or not jack_text.is_empty():
		return lift_text + jack_text
	if bay != null and bool(bay.call("can_chock", at)):
		return "Chock the rear wheel"
	if bay != null and bool(bay.call("can_unchock", at)):
		return "Take the chock out"
	if _behind_the_van(at) and absf(float(vehicle.get("speed"))) < 0.1:
		if bool(vehicle.get("sealed")):
			return "" if _seal_checked else "Check the seal"
		return "Close the rear doors" if bool(vehicle.get("rear_doors_open")) \
			else "Open the rear doors"
	return ""


func do_foot_action(at: Vector3) -> String:
	var action := foot_action(at)
	match action:
		"Take the pallet jack":
			_jack().call("take")
			return ""
		"Set the pallet down":
			_jack().call("set_down")
			return ""
		"Pump the handle":
			_jack().call("pump")
			return ""
		"Let go of the jack":
			_jack().call("let_go")
			return ""
		"Hook the strap to the floor ring", "Throw the strap over the load", \
				"Hook it to the far ring", "Ratchet the strap tight":
			if bool(_jack().call("strap")):
				return "You strap the load down to the floor rings."
			return ""
		"Push it fully in or out first", "Pull the jack out first", \
				"Push it in against the bulkhead first":
			return action
		"Open the door":
			(shed.get("side_door") as Node).call("open_door")
			return "You push the side door open."
		"Hold to lower the lift", "Hold to raise the lift":
			_bay().call("operate_lift", driver)
			return ""
		"Chock the rear wheel":
			_bay().call("chock_wheel")
			return "You set the chock in front of the rear wheel."
		"Take the chock out":
			_bay().call("unchock")
			return "You take the chock out and hang it back on the dock."
		"Open the rear doors":
			if not bool(vehicle.call("rear_swing_clear")):
				return "No room: the rear doors swing round past the sides as they open."
			vehicle.call("open_rear_doors", driver)
			return ""
		"Close the rear doors":
			if _clearance() < CLEAR_OF_DOCK:
				return "Pull forward first: the doors swing out past the sides as they close."
			if bool(vehicle.call("close_rear_doors", driver)):
				_hand_when_shut = _loaded()
			return ""
		"Check the seal":
			_check_seal()
			return "View, verify, tug, twist: the seal is whole and its number matches."
		"Leave your van in the marked bay first":
			return action
		"Take the dark van":
			_take_dark_van()
			return "The dark van is open, its key on the visor."
	return ""


## The swap (step 4): his van and its load left in the bay, the dark van his; stage 2 saved.
func _take_dark_van() -> void:
	yard.call("swap", vehicle)
	stage = 2
	recovery_pose = DARK_VAN
	var config := start_progress()
	config.set_value("cargo", "stage", stage)
	checkpoint_reached.emit(config)
	_update_objective()


## Ethan's check of the seal (H5): the numbers side by side, then "loaded" saves stage 1 (H6).
func _check_seal() -> void:
	_seal_checked = true
	var number := str(vehicle.get("seal_number"))
	seal_checked.emit(SEAL_CHECK % [number, number, SEAL_NUMBER])
	stage = 1
	var config := start_progress()
	config.set_value("cargo", "stage", stage)
	checkpoint_reached.emit(config)
	_update_objective()


## The strapped load in the van and the lift back up: loading is done (step 2e).
func _loaded() -> bool:
	var stack: Node3D = _jack().call("in_van") as Node3D
	return stack != null and stack.has_meta("strapped") \
		and bool(shed.get_node("Building/DockLift9").call("at_top"))


func _clearance() -> float:
	var bay := _bay()
	return float(bay.call("clearance")) if bay != null else INF


func _jack() -> Node:
	return shed.get("pallet_jack") as Node if shed != null else null


func _bay() -> Node:
	return shed.get("bay_nine") as Node if shed != null else null


## The loading's objective, once the van is docked and chocked (step 2e), only ever going on as
## the job does (#245): the pallet set down on the lift waits for the lift to go down, then to be
## rolled in.
func _loading() -> Array[String]:
	var jack := _jack()
	var stack: Node3D = jack.call("in_van") as Node3D
	var lift := shed.get_node("Building/DockLift9")
	if stack != null and stack.has_meta("strapped"):
		if bool(lift.call("at_top")):
			return ["TAKE THE CHOCK OUT", "Press E at the chock by the rear wheel on the driver's side."]
		return ["RAISE THE LIFT", "Hold E at the pendant on the lift's deck until it is up."]
	if stack != null:
		return ["STRAP THE LOAD", "Beside the pallet in the hold, E hooks each strap to a floor "
			+ "ring, throws it over, hooks the far ring and ratchets it tight."]
	if bool(jack.get("held")):
		return ["ROLL THE PALLET IN",
			"W and S push and pull the jack, A and D steer; E sets it down at the bulkhead."]
	if jack.call("on_lift") != null:
		if bool(lift.call("at_bottom")):
			return ["ROLL THE PALLET IN",
				"Behind its handle E takes the jack again; W pushes the pallet into the hold."]
		return ["LOWER THE LIFT", "By the pendant on its deck, hold E to lower the lift with the "
			+ "pallet."]
	return ["LOAD THE PALLET",
		"Go in by the side door and up the stair; take the pallet jack at bay 9."]


## The objective once loaded and the chock is out: pull forward, close the doors, the seal.
func _sealing() -> Array[String]:
	if not _loaded() or bool(_bay().get("chocked")):
		return []
	if bool(vehicle.get("sealed")):
		return ["CHECK THE SEAL",
			"Press E at the doors: the bolt's and the cap's number against the run sheet's."]
	if not bool(vehicle.get("rear_doors_open")):
		return ["WAIT FOR THE SEAL", "The dock hand is coming out to seal the doors; stand clear."]
	if _clearance() < CLEAR_OF_DOCK:
		return ["PULL FORWARD",
			"Drive on until the van's rear is 2.5 m from the bumpers, so the doors can close."]
	return ["CLOSE THE REAR DOORS", "Get out and press E at the back of the van."]


## The objective from the seal to the swap (step 4; its words a draft for the author, S3).
func _to_the_yard() -> Array[String]:
	var occupied := bool(vehicle.get("occupied"))
	if bool(yard.call("vehicle_through")):
		if not bool(yard.call("in_bay")):
			return ["PARK IN THE MARKED BAY",
				"On the left of the lane, nose in toward the back fence."]
		if occupied:
			return ["LEAVE THE VAN", "Get out (E). The load stays sealed in it."]
		return ["TAKE THE DARK VAN",
			"The charcoal van across the lane, nose to the gate: E at its driver's door."]
	if bool(yard.call("keying")) or (not bool(yard.call("gate_shut"))
			and not bool(yard.call("gate_open"))):
		return ["WAIT FOR THE GATE", "The gate is sliding open."]
	if bool(yard.call("gate_open")):
		return ["DRIVE IN", "The gate is open."]
	if bool(yard.call("vehicle_near")):
		return ["STOP AT THE GATE",
			"Stop at the line by the keypad, then press E to key in the code from the run sheet."]
	return ["DRIVE TO THE CONTAINER YARD",
		"Back down the spur, then east on the valley road; the yard's gate is on the left."]


## The objective from the swap to the loading bay (step 5; its words drafts for the author, S3).
func _to_the_compound() -> Array[String]:
	if yard != null and bool(yard.call("exiting")) and not bool(yard.call("gate_open")):
		return ["WAIT FOR THE GATE", "The yard's gate is sliding open."]
	if bool(compound.call("vehicle_through")):
		var judge := compound.get("judge") as Node
		var verdict := String(judge.get("verdict"))
		var title := "BACK ONTO DOOR %d" % compound.DOOR
		if MISSES.has(verdict):
			var words := String(MISSES[verdict]).replace("the bay's centre", "the door's centre")
			if MEASURES.has(verdict):
				words = words % float((judge.get("measured") as Dictionary)[MEASURES[verdict]])
			return [title, words]
		if not bool(vehicle.get("rear_doors_open")):
			return ["OPEN THE REAR DOORS",
				"They can't open once docked: stop, get out and press E at the back."]
		return [title, "The east warehouse's open door: Q for reverse, then back in slowly "
			+ "between the guides to the bumpers."]
	if bool(compound.call("checking")):
		return ["WAIT AT THE GATE", "The guard is checking the run sheet."]
	if bool(compound.call("gate_open")):
		return ["DRIVE IN", "The guard says door %d, the east warehouse." % compound.DOOR]
	if not bool(compound.call("gate_shut")):
		return ["WAIT FOR THE GATE", "The gate is sliding open."]
	if bool(compound.call("vehicle_near")):
		return ["STOP AT THE BOOTH",
			"Stop at the line, then press E to hand the guard the run sheet."]
	return ["DRIVE TO THE WAREHOUSE COMPOUND",
		"Out of the yard and east on the valley road; the compound's gate is on the left."]


## Docked at door 3 (step 5): the guards' recognition is the escape's start (step 6, S1), so
## stage 3 is saved here.
func _judged() -> void:
	var judge := compound.get("judge") as Node
	if not active or stage != 2 or String(judge.get("verdict")) != "docked":
		_update_objective()
		return
	stage = 3
	recovery_pose = AT_DOOR_THREE
	var config := start_progress()
	config.set_value("cargo", "stage", stage)
	checkpoint_reached.emit(config)
	_update_objective()


## What a reload puts back that recovering the van does not: docked at door 3, its rear doors
## open, as they had to be to dock.
func restore_place() -> void:
	if stage == 3 and vehicle != null:
		vehicle.set("rear_doors_open", true)


func _behind_the_van(at: Vector3) -> bool:
	var local := vehicle.to_local(at)
	return local.z > VAN_REAR + REAR_REACH.x and local.z < VAN_REAR + REAR_REACH.y \
		and absf(local.x) < REAR_WIDTH


func recover() -> void:
	vehicle.recover(recovery_pose)
	restore_place()


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


func _physics_process(_delta: float) -> void:
	if _hand_when_shut and not bool(vehicle.call("rear_doors_busy")):
		_hand_when_shut = false
		if not bool(vehicle.get("rear_doors_open")):
			shed.call("call_dock_hand", vehicle, SEAL_NUMBER)
	if active and stage <= 2:
		_update_objective()


func _update_objective() -> void:
	var title := "MISSION 2 IS BEING BUILT"
	var detail := "Next: %s." % NEXT[stage].to_lower()
	if stage == 1 and yard != null:
		var words := _to_the_yard()
		title = words[0]
		detail = words[1]
	if stage == 2 and compound != null:
		var words := _to_the_compound()
		title = words[0]
		detail = words[1]
	if stage == 0 and shed != null:
		if shed.vehicle_through():
			var bay := _bay()
			var verdict: String = bay.get("verdict")
			var sealing := _sealing()
			if not sealing.is_empty():
				title = sealing[0]
				detail = sealing[1]
			elif bool(bay.get("chocked")):
				var loading := _loading()
				title = loading[0]
				detail = loading[1]
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
