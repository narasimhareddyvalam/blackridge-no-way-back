extends Node

signal objective_changed(title: String, detail: String)
signal seal_checked(words: String)
## A paper Ethan reads (the inspection's bill of lading, step 3), shown as the seal check is.
signal paper_shown(words: String)
signal checkpoint_reached(config: ConfigFile)
## The escape (step 6): a guard caught Ethan; the app puts all back as at its start.
signal escape_caught
## A text on Ethan's phone (the escape's anonymous warning, S3).
signal text_received(sender: String, words: String)
## The mission's end (step 7): stopped where the hill road begins.
signal drive_completed

const Escape = preload("escape.gd")
const LastRun = preload("res://features/missions/last_run/last_run.gd")

const MISSION := "the_wrong_cargo"
const NAME := "The Wrong Cargo"
const PLACES: Array[String] = ["The freight depot", "The transfer shed", "The container yard",
	"The warehouse compound", "Your van, taken back"]
const NEXT: Array[String] = ["The transfer shed", "The container yard", "The warehouse compound",
	"The hill road", "The hill road"]
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
const WINDOW_REACH := 0.4
const SEAL_NUMBER := "4182260"
const LOADED_AT := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
## Where the dark van waits in the container yard, nose to the gate (`container_yard.gd`).
const DARK_VAN := Transform3D(Basis(Vector3.UP, PI), Vector3(104.5, 0.1, 140.0))
## The dark van docked at the compound's door 3 (step 5): its rear 0.03 m off the bumpers.
const AT_DOOR_THREE := Transform3D(Basis(Vector3.UP, PI), Vector3(248.0, 0.1, 134.67))
## The opening's words (step 8; S2 and S3 decided by Claude Code at the author's word, #358,
## drafts): the new dispatcher's text bringing the job, and Maya's call once he drives off.
const DISPATCHER := "NORTHLINE DISPATCH · K. MARSH"
const DISPATCH := "BR 048: transfer tonight. Load at the transfer shed, bay 9; your run sheet " \
	+ "is in the cab. Sealed consignment: do not open, do not inspect. Rate as agreed."
const MAYA_CHECK_IN: Array = [
	["MAYA", "Hey. You're out again?"],
	["ETHAN", "New dispatcher. Better money."],
	["MAYA", "Good. That's good, Ethan. Keep at it."],
	["ETHAN", "You sound tired."],
	["MAYA", "I'm fine. Just take the work. Don't think about it too much."],
	["ETHAN", "Sunday still on?"],
	["MAYA", "We'll see. Drive safe."],
]
const CALL_AFTER := 80.0
## The getaway's end (step 7): within END_NEAR of the hill road's start PULL OVER, and stopped
## within END_STOP of it the mission ends.
const END_SAMPLE := 990
const END_NEAR := 60.0
const END_STOP := 12.0
const STOPPED := 0.5
## His van taken back in the container yard's bay (step 6), where stage 4 resumes.
const IN_THE_BAY := Transform3D(Basis.IDENTITY, Vector3(95.0, 0.1, 138.0))
## The inspection (step 3; S4 decided by Claude Code at the author's word, #358; its words a draft):
## the bill of lading that came with the load, the dock's scale ticket stapled to it.
const BILL := "BILL OF LADING - STRAIGHT, NOT NEGOTIABLE\nNo. 7731-046\n\n" \
	+ "SHIPPER ......... HALVERN MACHINE WORKS\n" \
	+ "                  (a correction label; at its edge,\n" \
	+ "                   the print beneath: VALE FREIGHT LT)\n" \
	+ "CONSIGNEE ....... EAST WAREHOUSE, DOOR 3\n" \
	+ "CARRIER ......... BLACKRIDGE FREIGHT, VAN BR 048\n\n" \
	+ "1 PALLET, SHRINK-WRAPPED: MACHINE PARTS\n" \
	+ "DECLARED WEIGHT . 410 KG\nSEAL ............ %s\n\n" \
	+ "DO NOT OPEN. DO NOT INSPECT CONTENTS.\n\n" \
	+ "STAPLED: DOCK 9 SCALE TICKET\nGROSS ON FORKS .. 1,180 KG"
const BILL_NOTE := "410 kg on the bill. The dock's scale said 1,180. And the van sits low on " \
	+ "its springs."
## The cut in the compound's fence (step 6), where it steps round the container yard.
const CUT := Vector3(138.0, 1.0, 140.0)
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
## The escape from the compound (step 6), once docked at door 3; null before.
var escape: Node
## Where the getaway ends (step 7): road sample 990, where the hill road begins; the app gives it.
var road_end := Vector3.INF
## Mission 2's opening still to play (step 8): set only in the save Mission 1's end leaves.
var opening_pending := false
## Maya's call still to come once he drives off, after the opening.
var call_pending := false
var _completed := false

var _shown := ""
var _title := ""
var _seal_checked := false
## Whether the bill of lading has been read (step 3); false only once the seal is checked live.
var _bill_read := true
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
	recovery_pose = [START, LOADED_AT, DARK_VAN, AT_DOOR_THREE, IN_THE_BAY][stage]
	vehicle.recover(recovery_pose)
	vehicle.call("unload")
	(vehicle.get_node("VanPresentation") as Node).call("set_paint", Color.WHITE)
	_seal_checked = stage >= 1
	_bill_read = true
	opening_pending = stage == 0 and bool(config.get_value("cargo", "opening", false))
	call_pending = false
	_completed = false
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
		elif stage == 4 and yard != null:
			yard.call("restore_unswapped", vehicle, func() -> void:
				shed.call("restore_loaded", vehicle, SEAL_NUMBER), AT_DOOR_THREE)
		elif stage >= 2 and yard != null:
			yard.call("restore_swapped", vehicle, func() -> void:
				shed.call("restore_loaded", vehicle, SEAL_NUMBER))
	if stage == 3:
		vehicle.recover(recovery_pose)
		restore_place()
		_begin_escape()
	elif escape != null:
		escape.queue_free()
		escape = null
	_shown = ""
	_update_objective()


func wants_interact() -> bool:
	if active and stage == 2 and compound != null:
		return bool(compound.call("vehicle_at_window")) and bool(compound.call("gate_shut")) \
			and not bool(compound.call("checking"))
	if active and stage == 1 and yard != null:
		if bool(yard.call("vehicle_at_stop")) and bool(yard.call("gate_shut")) \
				and not bool(yard.call("keying")):
			return true
		return not _bill_read and bool(vehicle.get("occupied"))
	return active and stage == 0 and shed != null and shed.vehicle_at_window() \
		and not shed.barrier_open() and not shed.checking()


func interact() -> String:
	if absf(float(vehicle.get("speed"))) > 0.3:
		return "Stop at the line first."
	if stage == 1 and not _bill_read and not bool(yard.call("vehicle_at_stop")):
		_bill_read = true
		paper_shown.emit(BILL % str(vehicle.get("seal_number")))
		_update_objective()
		return BILL_NOTE
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


## What E does at a gate from the driver's seat, for the key prompt (#358).
func interact_label() -> String:
	if stage == 1 and not _bill_read and yard != null and not bool(yard.call("vehicle_at_stop")):
		return "Read the bill of lading"
	return "Key in the gate code" if stage == 1 else "Hand over the run sheet"


## Where the objective shown sends him, for its marker and the map's pin (#358): the booth's
## window, the dock, the van's rear, the chock, the jack, the lift's pendant, the keypad, the
## marked bay, the dark van's door; Vector3.INF when it sends him nowhere (wait, pull forward,
## leave the van).
func objective_target() -> Vector3:
	if not active or vehicle == null:
		return Vector3.INF
	var rear := vehicle.to_global(Vector3(0.0, 1.0, VAN_REAR + 0.6))
	match _title:
		"DRIVE TO THE TRANSFER SHED", "STOP AT THE GATE" when stage == 0:
			return (shed.get("_booth_node") as Node3D).call("opening_centre")
		"DRIVE THROUGH THE GATE", "BACK ONTO BAY 9":
			return Vector3(-47.75, 1.2, 20.13)
		"OPEN THE REAR DOORS", "CLOSE THE REAR DOORS", "CHECK THE SEAL", "STRAP THE LOAD":
			return rear
		"CHOCK THE WHEEL", "TAKE THE CHOCK OUT":
			var chock := _bay().get("_chock") as Node3D
			return chock.global_position + Vector3.UP * 0.4 if chock != null else Vector3.INF
		"LOAD THE PALLET", "ROLL THE PALLET IN":
			var jack := _jack() as Node3D
			if jack == null or bool(jack.get("held")):
				return rear
			return jack.global_position + Vector3.UP * 1.0
		"RAISE THE LIFT", "LOWER THE LIFT":
			return shed.get_node("Building/DockLift9").call("pendant")
		"DRIVE TO THE CONTAINER YARD", "STOP AT THE GATE" when stage == 1:
			var keypad := yard.find_child("Keypad", true, false) as Node3D
			return keypad.global_position if keypad != null else Vector3.INF
		"PARK IN THE MARKED BAY":
			return Vector3(95.0, 0.6, 138.0)
		"TAKE THE DARK VAN":
			return DARK_VAN * Vector3(-1.1, 1.2, -1.3)
		"REACH THE CUT IN THE FENCE":
			return CUT
		"DRIVE OUT", "PULL OVER":
			return road_end + Vector3.UP * 1.5
		"GET BACK TO YOUR VAN":
			var pad := yard.find_child("Keypad", true, false) as Node3D
			return pad.global_position if pad != null else Vector3.INF
		"TAKE YOUR VAN BACK":
			var left := yard.call("left_van") as Node3D
			return left.global_transform * Vector3(-1.1, 1.2, -1.3) if left != null \
				else Vector3.INF
		"DRIVE TO THE WAREHOUSE COMPOUND", "STOP AT THE BOOTH":
			return (compound.get("booth") as Node3D).call("opening_centre")
	if _title == "DRIVE IN" and stage == 1:
		return Vector3(95.0, 0.6, 138.0)
	if _title.begins_with("BACK ONTO DOOR") or (_title == "DRIVE IN" and stage == 2):
		var judge := compound.get("judge") as Node
		return Vector3(float(judge.get("centre_x")), 1.2, float(judge.get("bumpers_z")))
	return Vector3.INF


## What Ethan, on foot at `at`, can do here with E, or "" when nothing: the van's rear doors
## from behind it, while it stands still.
func foot_action(at: Vector3) -> String:
	if not active or vehicle == null or bool(vehicle.get("occupied")):
		return ""
	if stage == 3 and yard != null and escape != null and bool(escape.get("outside")):
		if bool(yard.call("at_left_door", at)):
			return "Take your van back"
		if bool(yard.call("at_keypad", at)) and bool(yard.call("gate_shut")) \
				and not bool(yard.call("keying")):
			return "Key in the gate code"
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
		"Key in the gate code":
			yard.call("key_in", true)
			return "You key in the gate code from the run sheet."
		"Take your van back":
			_take_van_back()
			return "Your van, the load still sealed in it. Its key is where you left it."
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
	_bill_read = false
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


## At a gate, how to bring Ethan's window level with the guard's (#348): `gap` his eye's distance
## to the booth's opening along the lane, positive before it, negative past it.
func _to_window(gap: float, in_reach: bool = true) -> String:
	if absf(gap) <= WINDOW_REACH and not in_reach:
		return "Pull in closer to the booth: the guard can't reach your window from there."
	if absf(gap) <= WINDOW_REACH:
		return "Stop here, level with the guard's window, then press E to hand the guard the run sheet."
	if gap > 0.0:
		return "Pull up level with the guard's window, then press E to hand the guard the run sheet."
	return "Back up level with the guard's window, then press E to hand the guard the run sheet."


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
		return ["STOP AT THE BOOTH", _to_window(float(compound.call("window_gap")),
			bool(compound.call("window_in_reach")))]
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
	_begin_escape()
	_update_objective()


## The escape begins (step 6), or begins again: the guards at their starts, the warning unsent.
func _begin_escape() -> void:
	if escape == null:
		escape = Escape.new()
		escape.name = "Escape"
		add_child(escape)
		escape.connect("caught", func() -> void: escape_caught.emit())
		escape.connect("warning", func(sender: String, words: String) -> void:
			text_received.emit(sender, words))
	escape.set("vehicle", vehicle)
	escape.set("driver", driver)
	escape.set("area", PackedVector2Array(compound.OUTLINE))
	escape.call("reset")


## The opening played (step 8): the save no longer asks for it, and Maya's call is to come.
func opening_played() -> void:
	opening_pending = false
	call_pending = true
	checkpoint_reached.emit(start_progress())


## Whether Maya should call now: the opening played and the van CALL_AFTER from the depot.
func call_due() -> bool:
	if not call_pending or vehicle == null or not bool(vehicle.get("occupied")):
		return false
	var away := Vector2(vehicle.global_position.x - START.origin.x,
		vehicle.global_position.z - START.origin.z).length()
	if away < CALL_AFTER:
		return false
	call_pending = false
	return true


func _to_the_end() -> float:
	if road_end == Vector3.INF or vehicle == null:
		return INF
	return Vector2(vehicle.global_position.x - road_end.x,
		vehicle.global_position.z - road_end.z).length()


## Stopped where the hill road begins (step 7): Mission 3's start saved (#359, its opening to
## play), and the end as Mission 1's, a quiet beat in the cab with no title (C04).
func _check_end() -> void:
	if _completed or not bool(vehicle.get("occupied")) or _to_the_end() > END_STOP \
			or absf(float(vehicle.get("speed"))) > STOPPED:
		return
	_completed = true
	var next := LastRun.start_progress()
	next.set_value("run", "opening", true)
	checkpoint_reached.emit(next)
	drive_completed.emit()


func _in_yard(at: Vector3) -> bool:
	return Rect2(64.0, 132.0, 72.0, 26.0).has_point(Vector2(at.x, at.z))


## His van taken back (step 6): the swap undone in the yard, the dark van left at door 3, the
## escape over, stage 4 saved.
func _take_van_back() -> void:
	yard.call("unswap", vehicle, AT_DOOR_THREE)
	if escape != null:
		escape.queue_free()
		escape = null
	stage = 4
	recovery_pose = IN_THE_BAY
	var config := start_progress()
	config.set_value("cargo", "stage", stage)
	checkpoint_reached.emit(config)
	_update_objective()


## The escape's objective (step 6; its words drafts for the author, S3).
func _escaping() -> Array[String]:
	if bool(escape.get("outside")):
		if bool(yard.call("keying")) or (not bool(yard.call("gate_open"))
				and not bool(yard.call("gate_shut"))):
			return ["WAIT FOR THE GATE", "The gate is sliding open."]
		if bool(yard.call("gate_open")) or _in_yard(driver.global_position):
			return ["TAKE YOUR VAN BACK", "Your van is in the marked bay, the load still sealed "
				+ "in it: E at its driver's door."]
		return ["GET BACK TO YOUR VAN", "Round to the container yard's gate by the valley road: "
			+ "key in the code from the run sheet."]
	if bool(vehicle.get("occupied")):
		return ["GET OUT AND RUN",
			"They have come for the van. Get out before they reach the cab."]
	if bool(escape.get("warned")):
		return ["REACH THE CUT IN THE FENCE", "West, where the fence steps round the container "
			+ "yard. Keep something solid between you and the torches."]
	return ["GET PAST THE PATROLS",
		"Stay out of the guards' sight: keep trailers, stacks and walls between you and them."]


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
	if stage == 3 and escape != null:
		escape.call("reset")


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


func _physics_process(_delta: float) -> void:
	if _hand_when_shut and not bool(vehicle.call("rear_doors_busy")):
		_hand_when_shut = false
		if not bool(vehicle.get("rear_doors_open")):
			shed.call("call_dock_hand", vehicle, SEAL_NUMBER)
	if active and stage <= 4:
		_update_objective()
	if active and stage == 4:
		_check_end()


func _update_objective() -> void:
	var title := ""
	var detail := "Next: %s." % NEXT[stage].to_lower()
	if stage == 1 and yard != null:
		var words := _to_the_yard()
		title = words[0]
		detail = words[1]
		if not _bill_read:
			title = "READ THE BILL OF LADING"
			detail = "In the cab: the paperwork that came with the load."
	if stage == 2 and compound != null:
		var words := _to_the_compound()
		title = words[0]
		detail = words[1]
	if stage == 3 and escape != null:
		var words := _escaping()
		title = words[0]
		detail = words[1]
	if stage == 4:
		title = "DRIVE OUT"
		detail = "Out of the yard and west on the valley road, past the depot, then up the " \
			+ "hill road."
		if _to_the_end() < END_NEAR:
			title = "PULL OVER"
			detail = "Pull onto the verge here and stop."
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
		elif shed.barrier_rising():
			title = "WAIT FOR THE BARRIER"
			detail = "The barrier is rising."
		elif shed.barrier_open():
			title = "DRIVE THROUGH THE GATE"
			detail = "The barrier is up."
		elif shed.vehicle_near():
			title = "STOP AT THE GATE"
			detail = _to_window(shed.window_gap(), shed.window_in_reach())
		else:
			title = "DRIVE TO THE TRANSFER SHED"
			detail = "Take the spur north off the valley road, just west of the depot."
	_title = title
	if title + detail != _shown:
		_shown = title + detail
		objective_changed.emit(title, detail)
