extends Node
## Mission 3, Last Run (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360): the dispatcher's "last run"
## to the waterfront, its ambush, the truth about Maya, the convoy, the airfield and home. Its
## checkpoints are saved in the progress file's version 2 as `[run] stage`. Step 1 (missions in a
## row): its start at the freight depot, where Mission 2 began; each later step adds its places.
## The app drives it as it drives Mission 2, through the same small set of calls.

signal objective_changed(title: String, detail: String)
signal checkpoint_reached(config: ConfigFile)
## The ambush caught Ethan at the gate (step 3); the app puts him back at the berth.
signal ambush_caught
## A paper or screen Ethan reads (the attacker's phone, step 3; Maya's recording, step 4).
signal paper_shown(words: String)
## A scene's lines as subtitles, and their end (step 4).
signal line_spoken(speaker: String, words: String)
signal lines_cleared
## Ethan out of the van to stand at `at` facing `toward` for a scene, and back in after it.
signal stand_ethan(at: Vector3, toward: Vector3)
signal seat_ethan
## A text on Ethan's phone (Maya's, step 4).
signal text_received(sender: String, words: String)
## The convoy saw him, or he lost it (step 5); the app puts him back at the junction.
signal convoy_spotted(lost: bool)
## Maya's call with the convoy's timing (step 5): the app starts it on Mission 1's phone.
signal call_now(lines: Array)
## Down in the hangar's encounter, or the van heard on the airfield (step 6): the app fades and
## calls `retry_hangar`.
signal hangar_lost(heard: bool)

const Ambush = preload("ambush.gd")
const Scenes = preload("story_scenes.gd")
const Convoy = preload("convoy.gd")
const Encounter = preload("hangar_encounter.gd")
## Maya at the service gate (step 6): where she stands from the gate, and her handover (its
## words a draft, #359): the office, the three men, Adrian's pistol, the van left outside.
const MAYA_AT_GATE := Vector3(-4.5, 0.0, 5.0)
const GATE_POSE_BACK := 14.0
const INSIDE_GATE := 4.0
const TALK_WITHIN := 2.6
const AT_OFFICE := 1.6
const MAYA_GUN: Array = [
	[0.5, "MAYA", "You came.", 1.6],
	[2.4, "ETHAN", "Where is she?", 1.6],
	[4.3, "MAYA", "The office, at the back of the hangar. Three of his men outside it.", 3.2],
	[7.8, "MAYA", "Here. It's Adrian's. It was in the car.", 2.6],
	[10.7, "ETHAN", "I drive vans, Maya.", 2.0],
	[13.0, "MAYA", "Then only if they make you. Fifteen in it, and one spare.", 3.0],
	[16.3, "MAYA", "Leave the van here. They'd hear it. I'll be right here.", 3.0],
]
## Where the tail begins (step 5): the coastal road at the east road's end.
const JUNCTION := Vector3(726.0, 0.0, 151.7)
const AT_JUNCTION := 40.0
const AT_SERVICE := 9.0
## Maya's call once the convoy is ahead (step 5; its words a draft, #359).
const MAYA_TIMING: Array = [
	["MAYA", "They're on the coastal road. Two cars. Adrian's in the second."],
	["ETHAN", "I see them."],
	["MAYA", "Don't get close. He knows your van."],
	["MAYA", "I've put the plane back half an hour. He'll blame the tower."],
	["MAYA", "There's a service gate on the south side, off the freight track. Two, four, one, "
		+ "seven."],
	["ETHAN", "And you?"],
	["MAYA", "I'll be at the service gate. Bring her to me."],
]
const MAYA_MODEL = preload("res://features/characters/maya/maya.glb")
const CAR = preload("res://features/environments/industrial_loop/art/town/sedan.glb")
## Where Maya waits (step 4): at the depot by her car, then at the viewpoint on the hill road.
const DEPOT_MEETING := Vector3(-16.0, 0.02, 100.0)
const VIEWPOINT_MEETING := Vector3(461.5, 0.0, -111.0)
const VALLEY := Vector3(200.0, 8.0, 90.0)
const MEET_WITHIN := 11.0
const FACE_TO_FACE := 2.3
## Checkpoint 1 resumes on the coastal road, where the phone was read.
const AWAY_POSE := Transform3D(Basis.IDENTITY, Vector3(726.0, 0.1, 60.0))
## The attacker's phone (step 3; its words a draft, #359): his thread with "M", whose number is
## the one saved in Ethan's own phone as Maya.
const PHONE := "A PHONE, NOT YOURS. ITS SCREEN STILL ON.\n\nM  (360) 555-0148\n\n" \
	+ "M  23:52  BR 048 takes the waterfront job. Berth 2, 01:40. He'll come alone.\n" \
	+ "   23:55  He trusts the dispatcher?\n" \
	+ "M  23:58  He trusts me.\n\n" \
	+ "(360) 555-0148: the number saved in your phone as MAYA."
const PHONE_NOTE := "That's Maya's number."
const AWAY := 150.0
const STOPPED := 0.4

const MISSION := "last_run"
const NAME := "Last Run"
const PLACES: Array[String] = ["The freight depot", "Away from the waterfront", "The viewpoint",
	"The airfield gate", "The hangar"]
const NEXT: Array[String] = ["The waterfront", "The viewpoint", "The airfield", "The hangar",
	"Home"]
const START := Transform3D(Basis(Vector3.UP, PI), Vector3(-28.0, 0.1, 93.0))
const TITLE_EYE := Vector3(3.2, 1.0, -9.5)
const TITLE_LOOK := Vector3(1.3, 1.3, 0.7)
const TITLE_FOV := 32.0

var vehicle: CharacterBody3D
var stage: int = 0
var recovery_pose := START
var fleeing: bool = false
var active: bool = false
var driver: Node3D
## The waterfront's terminal (step 3); the app gives it.
var waterfront: Node3D
## The ambush at berth 2 (step 3), at stage 0.
var ambush: Node
## The app's cutscene director: playing shots, and whether it is (the ambush's cutscene).
var play_cutscene: Callable
var cutscene_playing: Callable
## Maya and her car (step 4), and where she waits.
var maya: Node3D
var maya_car: Node3D
var depot_meeting := DEPOT_MEETING
var viewpoint_meeting := VIEWPOINT_MEETING
## Where stage 1 stands: "depot", "confrontation", "recording", "viewpoint", "reconciliation".
var story := ""
## The convoy (step 5) and the airfield it drives to; the app gives the airfield.
var convoy: Node
var airfield: Node3D
## The hangar's guard encounter (step 6), from stage 3.
var encounter: Node
var _lines: Array = []
var _line_clock := 0.0
var _line_next := 0
var _scene_started := false
## Its opening still to play: set only in the save Mission 2's end leaves.
var opening_pending := false

var _shown := ""
var _title := ""


static func valid_progress(config: ConfigFile) -> bool:
	var value: Variant = config.get_value("run", "stage", -1)
	return config.get_value("save", "mission", "") == MISSION and value is int and value >= 0 \
		and value < PLACES.size()


static func start_progress() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("save", "mission", MISSION)
	config.set_value("run", "stage", 0)
	return config


func configure(van: CharacterBody3D, config: ConfigFile) -> void:
	vehicle = van
	stage = config.get_value("run", "stage")
	recovery_pose = AWAY_POSE if stage == 1 else START
	opening_pending = stage == 0 and bool(config.get_value("run", "opening", false))
	vehicle.recover(recovery_pose)
	vehicle.call("unload")
	(vehicle.get_node("VanPresentation") as Node).call("set_paint", Color.WHITE)
	if stage == 0 and waterfront != null:
		if ambush == null:
			ambush = Ambush.new()
			ambush.name = "Ambush"
			add_child(ambush)
			ambush.connect("caught", func() -> void: ambush_caught.emit())
		ambush.set("vehicle", vehicle)
		ambush.set("berth", waterfront.get("berth"))
		ambush.set("play_cutscene", play_cutscene)
		ambush.set("cutscene_playing", cutscene_playing)
		ambush.call("reset")
	elif ambush != null:
		ambush.queue_free()
		ambush = null
	_place_maya(stage == 1)
	story = "depot" if stage == 1 else ""
	if stage == 2:
		story = "approach"
		recovery_pose = Transform3D(Basis(Vector3.UP, PI / 2.0), _on_ground(VIEWPOINT_MEETING
			+ Vector3(-6.0, 0.0, 0.0)) + Vector3.UP * 0.1)
		vehicle.recover(recovery_pose)
	if stage >= 3 and airfield != null:
		var gate: Vector3 = airfield.get("service_gate")
		recovery_pose = Transform3D(Basis.IDENTITY, _on_ground(gate + Vector3(0.0, 0.0,
			GATE_POSE_BACK)) + Vector3.UP * 0.1)
		vehicle.recover(recovery_pose)
		airfield.call("open_service_now")
	if stage == 3:
		story = "maya"
		_maya_at_gate()
	if stage == 4:
		story = "lily"
	_ensure_convoy()
	_ensure_encounter()
	_lines.clear()
	_shown = ""
	_update_objective()


func recover() -> void:
	vehicle.recover(recovery_pose)


func _ensure_encounter() -> void:
	if encounter == null and airfield != null and driver != null:
		encounter = Encounter.new()
		encounter.name = "HangarEncounter"
		add_child(encounter)
		encounter.call("build", airfield, driver, vehicle)
		encounter.connect("down_and_out", func() -> void: hangar_lost.emit(false))
		encounter.connect("heard_van", func() -> void: hangar_lost.emit(true))
	if encounter != null:
		encounter.call("reset")
		encounter.get("handgun").set("armed", false)
		encounter.call("set_running", stage == 3)


## Maya by her car just outside the service gate (step 6), facing the way he comes.
func _maya_at_gate() -> void:
	var gate: Vector3 = airfield.get("service_gate")
	_stand_maya(_on_ground(gate + MAYA_AT_GATE), true)
	var look := gate + Vector3(0.0, 0.0, GATE_POSE_BACK) - maya.global_position
	maya.rotation.y = atan2(look.x, look.z)


## Back at the service gate after he went down, or they heard the van (step 6): on foot just
## inside it, the van outside, every man at his post, the gun full.
func retry_hangar() -> void:
	var gate: Vector3 = airfield.get("service_gate")
	vehicle.recover(recovery_pose)
	encounter.call("reset")
	var hangar: Vector3 = airfield.get("hangar_at")
	stand_ethan.emit(_on_ground(gate + Vector3(0.0, 0.0, -INSIDE_GATE)), hangar)


## The handover's lines, without a cutscene: true once the last has been shown its time.
func _talk(delta: float) -> bool:
	_line_clock += delta
	while _line_next < _lines.size() and _line_clock >= float(_lines[_line_next][0]):
		var line: Array = _lines[_line_next]
		line_spoken.emit(String(line[1]), String(line[2]))
		_maya_play("TalkSad" if String(line[1]) == "MAYA" else "Idle")
		_line_next += 1
	var last: Array = _lines[_lines.size() - 1]
	if _line_next >= _lines.size() and _line_clock > float(last[0]) + float(last[3]):
		lines_cleared.emit()
		_maya_play("Idle")
		_lines.clear()
		return true
	return false


## Maya and her car at the depot (`at_depot`), or out of sight.
func _place_maya(at_depot: bool) -> void:
	if maya == null:
		maya = MAYA_MODEL.instantiate() as Node3D
		maya.name = "Maya"
		maya.set_meta("model", MAYA_MODEL.resource_path)
		add_child(maya)
		maya_car = CAR.instantiate() as Node3D
		maya_car.name = "MayasCar"
		add_child(maya_car)
		_maya_play("Idle")
	viewpoint_meeting = _on_ground(VIEWPOINT_MEETING)
	_stand_maya(DEPOT_MEETING if at_depot else Vector3(0.0, -50.0, 0.0), at_depot)


func _stand_maya(at: Vector3, shown: bool) -> void:
	maya.visible = shown
	maya_car.visible = shown
	maya.global_position = at
	maya_car.global_position = at + Vector3(4.2, 0.0, 2.5)
	maya_car.rotation.y = PI / 2.0
	var look := START.origin - at if at == DEPOT_MEETING else VALLEY - at
	maya.rotation.y = atan2(look.x, look.z)


func _maya_play(clip: String) -> void:
	var player := maya.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	if player.current_animation != clip:
		player.play(clip, 0.3)


func _on_ground(at: Vector3) -> Vector3:
	if vehicle == null:
		return at
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 120.0, at
		+ Vector3.DOWN * 60.0, 1)
	var hit := vehicle.get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else at


## A scene (step 4): Ethan out to stand facing Maya, its shots played, its lines spoken.
func _play_scene(shots: Array, lines: Array, ethan_at: Vector3) -> void:
	stand_ethan.emit(ethan_at, maya.global_position)
	var look := ethan_at - maya.global_position
	maya.rotation.y = atan2(look.x, look.z)
	_lines = lines
	_line_clock = 0.0
	_line_next = 0
	_scene_started = false
	play_cutscene.call(shots)


func _run_lines(delta: float) -> bool:
	if _lines.is_empty():
		return false
	_line_clock += delta
	_scene_started = _scene_started or bool(cutscene_playing.call())
	while _line_next < _lines.size() and _line_clock >= float(_lines[_line_next][0]):
		var line: Array = _lines[_line_next]
		line_spoken.emit(String(line[1]), String(line[2]))
		_maya_play("TalkSad" if String(line[1]) == "MAYA" else "Idle")
		_line_next += 1
	if _line_next > 0:
		var last: Array = _lines[_line_next - 1]
		if _line_clock > float(last[0]) + float(last[3]):
			lines_cleared.emit()
			_maya_play("Idle")
	if _scene_started and not bool(cutscene_playing.call()):
		lines_cleared.emit()
		_lines.clear()
		seat_ethan.emit()
		return true
	return false


func _near(at: Vector3) -> bool:
	return bool(vehicle.get("occupied")) and absf(float(vehicle.get("speed"))) < STOPPED \
		and Vector2(vehicle.global_position.x - at.x, vehicle.global_position.z - at.z).length() \
		< MEET_WITHIN


func _ensure_convoy() -> void:
	if convoy == null and airfield != null:
		convoy = Convoy.new()
		convoy.name = "Convoy"
		add_child(convoy)
		convoy.connect("spotted", func(lost: bool) -> void: convoy_spotted.emit(lost))
	if convoy != null:
		convoy.set("vehicle", vehicle)
		convoy.set("airfield", airfield)
		convoy.call("stop")
		for suv: Node3D in convoy.get("suvs"):
			suv.visible = false


## Back at the junction after the convoy saw him (step 5): the convoy ahead again.
func retry_tail() -> void:
	vehicle.recover(Transform3D(Basis(Vector3.UP, -PI / 2.0), JUNCTION + Vector3(-20.0, 0.1,
		0.0)))
	convoy.call("start")


func _face_to_face(at: Vector3) -> Vector3:
	var toward := vehicle.global_position - at
	toward.y = 0.0
	return at + toward.normalized() * FACE_TO_FACE


func _story(delta: float) -> void:
	match story:
		"depot":
			if _near(DEPOT_MEETING):
				story = "confrontation"
				var ethan_at := _face_to_face(DEPOT_MEETING)
				_play_scene(Scenes.confrontation(DEPOT_MEETING, ethan_at,
					vehicle.global_position), Scenes.CONFRONTATION_LINES, ethan_at)
		"confrontation":
			if _run_lines(delta):
				story = "recording"
				_stand_maya(Vector3(0.0, -50.0, 0.0), false)
		"viewpoint":
			if _near(viewpoint_meeting):
				story = "reconciliation"
				var ethan_at := _face_to_face(viewpoint_meeting)
				_play_scene(Scenes.reconciliation(viewpoint_meeting, ethan_at, VALLEY),
					Scenes.RECONCILIATION_LINES, ethan_at)
		"approach":
			if Vector2(vehicle.global_position.x - JUNCTION.x,
					vehicle.global_position.z - JUNCTION.z).length() < AT_JUNCTION:
				story = "tail"
				convoy.call("start")
				call_now.emit(MAYA_TIMING)
		"tail":
			if bool(convoy.get("inside")):
				story = "service"
				_maya_at_gate()
		"gun":
			if _talk(delta):
				story = "hangar"
				encounter.call("arm")
		"hangar":
			var door: Vector3 = airfield.get("office_door")
			if bool(driver.get("active")) and Vector2(driver.global_position.x - door.x,
					driver.global_position.z - door.z).length() < AT_OFFICE \
					and not bool(encounter.call("on_them")):
				story = "lily"
				stage = 4
				encounter.call("set_running", false)
				var reached := start_progress()
				reached.set_value("run", "stage", stage)
				checkpoint_reached.emit(reached)
		"reconciliation":
			if _run_lines(delta):
				story = "approach"
				_stand_maya(Vector3(0.0, -50.0, 0.0), false)
				stage = 2
				var config := start_progress()
				config.set_value("run", "stage", stage)
				checkpoint_reached.emit(config)


## Back at berth 2 after the ambush caught him (step 3): the van in its bay, the escape on again.
func retry_ambush() -> void:
	vehicle.recover(Transform3D(Basis(Vector3.UP, PI), (waterfront.get("berth") as Vector3)
		+ Vector3.UP * 0.1))
	ambush.call("retry")


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


## Where the objective sends him, for its marker and the map's pin; Vector3.INF for none.
func objective_target() -> Vector3:
	if waterfront == null:
		return Vector3.INF
	if _title == "INTERCEPT THE CONVOY":
		return JUNCTION + Vector3.UP * 1.5
	if _title == "THE SERVICE GATE" and airfield != null:
		return (airfield.get("service_gate") as Vector3) + Vector3.UP * 1.5
	if _title in ["GET INTO THE HANGAR", "FIND LILY"] and airfield != null:
		return (airfield.get("office_door") as Vector3) + Vector3.UP * 1.5
	if _title == "MAYA" and stage == 3 and maya != null:
		return maya.global_position + Vector3.UP * 1.9
	if _title == "DRIVE TO THE DEPOT":
		return depot_meeting + Vector3.UP * 1.5
	if _title == "MEET MAYA AT THE VIEWPOINT":
		return viewpoint_meeting + Vector3.UP * 1.5
	if _title == "GET OUT OF THE TERMINAL":
		return (waterfront.get("gate") as Vector3) + Vector3.UP * 1.5
	if _title == "PARK AT BERTH 2":
		return (waterfront.get("berth") as Vector3) + Vector3.UP * 1.2
	if _title == "DRIVE TO THE WATERFRONT":
		return (waterfront.get("gate") as Vector3) + Vector3.UP * 1.5
	return Vector3.INF


## Whether E does something from the driver's seat here, what, and doing it.
func wants_interact() -> bool:
	if _title == "THE SERVICE GATE":
		var gate: Vector3 = airfield.get("service_gate")
		return absf(float(vehicle.get("speed"))) < STOPPED and not bool(airfield.call(
			"service_open")) and Vector2(vehicle.global_position.x - gate.x,
			vehicle.global_position.z - gate.z).length() < AT_SERVICE
	return _title in ["CHECK THE PHONE", "LISTEN TO THE RECORDING"] \
		and absf(float(vehicle.get("speed"))) < STOPPED


func interact_label() -> String:
	match _title:
		"CHECK THE PHONE":
			return "Check the phone"
		"LISTEN TO THE RECORDING":
			return "Listen to the recording"
		"THE SERVICE GATE":
			return "Key in Maya's code"
	return ""


func interact() -> String:
	if _title == "THE SERVICE GATE":
		airfield.call("open_service")
		story = "maya"
		stage = 3
		if encounter != null:
			encounter.call("set_running", true)
		var reached := start_progress()
		reached.set_value("run", "stage", stage)
		checkpoint_reached.emit(reached)
		_update_objective()
		return "Two, four, one, seven. The gate rolls aside."
	if _title == "LISTEN TO THE RECORDING":
		paper_shown.emit(Scenes.RECORDING)
		story = "viewpoint"
		_stand_maya(viewpoint_meeting, true)
		text_received.emit("MAYA", Scenes.MAYA_TEXT)
		_update_objective()
		return Scenes.RECORDING_NOTE
	if _title != "CHECK THE PHONE":
		return ""
	paper_shown.emit(PHONE)
	stage = 1
	story = "depot"
	recovery_pose = AWAY_POSE
	_stand_maya(DEPOT_MEETING, true)
	if ambush != null:
		ambush.queue_free()
		ambush = null
	var config := start_progress()
	config.set_value("run", "stage", stage)
	checkpoint_reached.emit(config)
	_update_objective()
	return PHONE_NOTE


## What Ethan on foot at `at` can do with E, or "", and doing it.
func foot_action(at: Vector3) -> String:
	if story == "maya" and maya != null and maya.visible and Vector2(at.x
			- maya.global_position.x, at.z - maya.global_position.z).length() < TALK_WITHIN:
		return "Talk to Maya"
	return ""


func do_foot_action(at: Vector3) -> String:
	if foot_action(at) != "Talk to Maya":
		return ""
	story = "gun"
	var look := at - maya.global_position
	maya.rotation.y = atan2(look.x, look.z)
	_lines = MAYA_GUN
	_line_clock = 0.0
	_line_next = 0
	return ""


func _physics_process(delta: float) -> void:
	if active:
		_story(delta)
		_update_objective()


func _update_objective() -> void:
	var title := "DRIVE TO THE WATERFRONT"
	var detail := "The dispatcher's last run: east to the end of the valley road, then on to the " \
		+ "harbour."
	if waterfront != null and vehicle != null and bool(waterfront.call("inside",
			vehicle.global_position)):
		title = "PARK AT BERTH 2"
		detail = "The pickup: berth 2, at the quay's edge past the stacks."
	if ambush != null and String(ambush.get("phase")) in ["scene", "escape", "retry", "caught"]:
		title = "GET OUT OF THE TERMINAL"
		detail = "They are closing the gate with a car. Get out through it before they do."
	elif ambush != null and String(ambush.get("phase")) == "away":
		var gate: Vector3 = waterfront.get("gate")
		var away := Vector2(vehicle.global_position.x - gate.x,
			vehicle.global_position.z - gate.z).length()
		title = "GET AWAY" if away < AWAY else "CHECK THE PHONE"
		detail = "Away from the waterfront, along the coastal road." if away < AWAY \
			else "Pull over and look at the phone that fell into the cab."
	if stage == 1:
		title = "DRIVE TO THE DEPOT"
		detail = "Back west to the freight depot. Maya is waiting there, by her car."
		match story:
			"confrontation":
				title = "MAYA"
				detail = ""
			"recording":
				title = "LISTEN TO THE RECORDING"
				detail = "Maya's phone, on the passenger seat where she left it."
			"viewpoint", "reconciliation":
				title = "MEET MAYA AT THE VIEWPOINT"
				detail = "Up the hill road to the viewpoint, where she asked to meet."
	if stage == 2:
		title = "INTERCEPT THE CONVOY"
		detail = "Maya will call with its timing. Head for the harbour flats."
		match story:
			"tail":
				title = "TAIL THE CONVOY"
				detail = "Stay well back: close enough to keep them in sight, never close " \
					+ "enough to be seen."
			"service":
				title = "THE SERVICE GATE"
				detail = "Along the freight track to the airfield's south side. Maya's code " \
					+ "opens it."
	if stage == 3:
		title = "MAYA"
		detail = "She is waiting by her car at the service gate."
		if story == "hangar":
			title = "GET INTO THE HANGAR"
			detail = "Lily is in the office at the back of the hangar. Right mouse aims, left " \
				+ "mouse fires, R reloads."
	if stage == 4:
		title = "FIND LILY"
		detail = "In the office at the back of the hangar."
	_title = title
	if title + detail != _shown:
		_shown = title + detail
		objective_changed.emit(title, detail)
