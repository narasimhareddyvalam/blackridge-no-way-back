extends SceneTree
## The three missions filmed as played (#362): each mission played through by `film_kit.gd`'s
## player with the real controls, from its start to its end, as the player sees it (its cutscenes,
## the HUD, the van's and Ethan's cameras). Long drives are driven, not skipped, except where a
## mission is joined to its next (a cut). Run windowed with Movie Maker, from the repository root:
##   HOME=<empty folder> Godot --path game --resolution 1280x800 --fixed-fps 30 \
##     --write-movie <absolute .avi> --script ../tools/captures/film_missions.gd -- <1|2|3>
## A run with no save starts Mission 1 from the title; Missions 2 and 3 start from the save the
## previous mission's end leaves (passed as the second argument, a save file's text).

const Kit = preload("film_kit.gd")
const SAVES := {
	2: "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\nopening=true\n",
	3: "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\nopening=true\n",
}

var kit: Kit
var app: Node3D
var _run_node: Node


func _seated() -> bool:
	return bool(kit.van.get("occupied")) and bool(kit.van.get("engine_on"))


func _convoy_running() -> bool:
	var convoy: Variant = _run_node.get("convoy")
	return convoy != null and bool((convoy as Node).get("running"))


func _armed() -> bool:
	var encounter := _run_node.get("encounter") as Node
	return bool((encounter.get("handgun") as Node).get("armed"))


func _epilogue_over() -> bool:
	var epilogue: Variant = _run_node.get("epilogue")
	return epilogue != null and not bool((epilogue as Node).get("playing"))


func _initialize() -> void:
	call_deferred("_run")


func _log(text: String) -> void:
	print("FILM %7.1f s  %s" % [Engine.get_physics_frames() / 30.0, text])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mission := int(args[0]) if not args.is_empty() else 1
	var progress := OS.get_user_data_dir().path_join("film_mission_%d.cfg" % mission)
	if FileAccess.file_exists(progress):
		DirAccess.remove_absolute(progress)
	if SAVES.has(mission):
		var file := FileAccess.open(progress, FileAccess.WRITE)
		file.store_string(SAVES[mission])
		file.close()
	app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	await process_frame
	await process_frame
	kit = Kit.new(self, app)
	await kit.seconds(2.0)
	match mission:
		1:
			await _mission_one()
		2:
			await _mission_two()
		3:
			await _mission_three()
	_log("done")
	quit(0)


## Night Freight: the title, the opening, the run sheet, the van, the loop road (Maya's call on
## the climb, the switchbacks, the viewpoint, the pass, the crossing, the flight), the depot, the
## quiet ending, back to the title.
func _mission_one() -> void:
	await kit.key(KEY_ENTER)
	_log("new game")
	await kit.until(func() -> bool: return kit.cutscene_playing(), 10.0)
	await kit.until(func() -> bool: return not kit.cutscene_playing(), 240.0)
	_log("opening over: %s" % kit.objective())
	await kit.seconds(1.0)
	var sheet: Vector3 = app.get_node("IndustrialLoop").get("run_sheet_spot")
	await kit.walk([sheet + Vector3(0.0, 0.0, 0.6)] as Array[Vector3])
	await kit.press("interact")
	await kit.until(func() -> bool: return kit.objective() == "GET IN THE VAN", 15.0)
	_log("signed: %s" % kit.objective())
	await kit.seconds(2.5)
	var door := kit.van.to_global(Vector3(-1.6, 0.0, -1.0))
	await kit.walk([door] as Array[Vector3])
	await kit.get_in()
	await kit.until(func() -> bool: return bool(kit.van.get("engine_on")), 8.0)
	_log("in the van: %s" % kit.objective())
	await kit.seconds(1.5)
	var depot := Vector3(-28.0, 0.0, 93.0)
	var turn_in := kit.nearest_anywhere(depot) - 8
	_watch_mission_one()
	await kit.drive_road(turn_in, 13.0, 5.0, 900.0)
	_log("at the depot road (sample %d): %s" % [turn_in, kit.objective()])
	await kit.drive_points([depot] as Array[Vector3], 5.0, true)
	_log("parked: %s" % kit.objective())
	await kit.until(func() -> bool: return bool(app.get("_on_title")), 40.0)
	await kit.seconds(4.0)


func _watch_mission_one() -> void:
	var route := app.get("route") as Node
	while not bool(route.get("complete")):
		await kit.seconds(15.0)
		var on: Variant = route.get("oncoming")
		var walker: Variant = route.get("pedestrian")
		var here := kit.nearest_anywhere(kit.van.global_position)
		_log("encounter %s oncoming %s pedestrian %s off-centre %.1f locked %s" % [
			route.get("_encounter_done"), (on as Node3D).global_position.snapped(
			Vector3.ONE * 0.1) if is_instance_valid(on) else "none", (walker as Node3D)
			.global_position.snapped(Vector3.ONE * 0.1) if is_instance_valid(walker) else "none", kit.van.global_position.distance_to(
			kit.road[here]), kit.van.get("locked")])
		_log("pos %s sample %d stage %d fleeing %s speed %.1f held %s %s" % [
			kit.van.global_position.snapped(Vector3.ONE * 0.1), kit.nearest_anywhere(
			kit.van.global_position), int(route.get("stage")), route.get("fleeing"),
			float(kit.van.get("speed")), kit.van.get("held"), kit.objective()])


func _mission_two() -> void:
	pass


## Last Run, from Mission 2's end: the waterfront and the trap at berth 2, out through the gate,
## the phone; the depot and Maya; the recording; the viewpoint; the convoy tailed to the airfield;
## the service gate, Maya's pistol, the hangar's men; Lily, out to Maya; Adrian; the ending.
func _mission_three() -> void:
	var run := app.get("run") as Node
	var field := app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	await kit.key(KEY_ENTER)
	await kit.until(_seated, 20.0)
	_log("start: %s" % kit.objective())
	await kit.seconds(1.5)
	await _over_the_hill_east()
	await kit.drive_points([ Vector3(690.0, 0.0, 153.4),
		Vector3(722.0, 0.0, 156.0), Vector3(724.4, 0.0, 180.0), Vector3(730.0, 0.0, 200.9), Vector3(830.0, 0.0, 200.6), Vector3(848.0, 0.0, 200.5), Vector3(880.0, 0.0, 215.0), Vector3(940.0, 0.0, 226.0),
		Vector3(975.0, 0.0, 222.0), Vector3(990.0, 0.0, 227.0), Vector3(992.0, 0.0, 233.0)]
		as Array[Vector3], 11.0, true)
	_log("at berth 2: %s" % kit.objective())
	await kit.until(func() -> bool: return kit.cutscene_playing(), 8.0)
	await kit.until(func() -> bool: return not kit.cutscene_playing(), 120.0)
	_log("trap over: %s" % kit.objective())
	var ambush := run.get("ambush") as Node
	for attempt in range(4):
		await kit.drive_points([Vector3(990.0, 0.0, 244.0), Vector3(972.0, 0.0, 247.0),
			Vector3(935.0, 0.0, 238.0), Vector3(880.0, 0.0, 214.0), Vector3(852.0, 0.0, 200.2), Vector3(830.0, 0.0, 199.4), Vector3(745.0, 0.0, 198.4), Vector3(729.0, 0.0, 190.0),
			Vector3(727.6, 0.0, 150.0), Vector3(727.6, 0.0, 96.0)] as Array[Vector3], 14.0, true)
		if ambush == null or not is_instance_valid(ambush) or bool(ambush.get("escaped")):
			break
		_log("caught at the gate, again (%d)" % attempt)
		await kit.until(func() -> bool: return String(ambush.get("phase")) == "escape", 20.0)
	_log("away: %s" % kit.objective())
	await kit.press("interact")
	await kit.seconds(7.0)
	await kit.press("interact")
	_log("phone read: %s" % kit.objective())
	await kit.seconds(2.0)
	await kit.drive_points([Vector3(735.0, 0.0, 100.0), Vector3(742.0, 0.0, 118.0),
		Vector3(731.0, 0.0, 135.0), Vector3(723.0, 0.0, 150.0), Vector3(700.0, 0.0, 150.0),
		Vector3(615.0, 0.0, 150.0)] as Array[Vector3], 12.0, false)
	var depot_road := kit.nearest_anywhere(Vector3(-16.0, 0.0, 100.0))
	await _over_the_hill_west(depot_road - 6)
	var meeting: Vector3 = run.get("depot_meeting")
	await kit.drive_points([meeting + Vector3(-6.0, 0.0, -4.0)] as Array[Vector3], 5.0, true)
	_log("at the depot: %s" % kit.objective())
	await kit.until(func() -> bool: return kit.cutscene_playing(), 10.0)
	await kit.until(func() -> bool: return not kit.cutscene_playing(), 120.0)
	await kit.until(func() -> bool: return bool(kit.van.get("occupied")), 10.0)
	await kit.seconds(2.0)
	_log("confrontation over: %s" % kit.objective())
	await kit.press("interact")
	await kit.seconds(12.0)
	await kit.press("interact")
	await kit.seconds(3.0)
	_log("recording heard: %s" % kit.objective())
	var view: Vector3 = run.get("viewpoint_meeting")
	await kit.drive_points([kit.lane_point(depot_road, -1.0)] as Array[Vector3], 5.0, false)
	await kit.drive_road_back(kit.nearest_anywhere(view) + 3, 13.0)
	await kit.stop()
	_log("at the viewpoint: %s" % kit.objective())
	await kit.until(func() -> bool: return kit.cutscene_playing(), 10.0)
	await kit.until(func() -> bool: return not kit.cutscene_playing(), 120.0)
	await kit.until(func() -> bool: return bool(kit.van.get("occupied")), 10.0)
	await kit.seconds(2.0)
	_log("reconciled: %s" % kit.objective())
	await kit.drive_road_back(4, 14.0)
	await kit.drive_points([Vector3(600.0, 0.0, 150.0), Vector3(690.0, 0.0, 153.4),
		Vector3(712.0, 0.0, 153.4)] as Array[Vector3], 11.0, false)
	await _tail(run, field)
	_log("convoy in: %s" % kit.objective())
	await kit.drive_points([Vector3(735.0, 0.0, -100.0), Vector3(742.0, 0.0, -84.0),
		Vector3(729.0, 0.0, -68.0), Vector3(727.6, 0.0, -46.0), Vector3(740.0, 0.0, -41.0),
		Vector3(984.0, 0.0, -41.0), Vector3(990.0, 0.0, -48.0), Vector3(990.0, 0.0, -66.0)]
		as Array[Vector3], 10.0, true)
	_log("at the service gate: %s" % kit.objective())
	await kit.press("interact")
	await kit.seconds(3.0)
	_log("code keyed: %s" % kit.objective())
	await _hangar(run, field)
	await _home(run, field)


## The valley road east of the depot is closed by the landslide (road sample 1326; "The way to the
## depot is over the hill", PHASE_BRIEF.md), so every trip between the depot and the east side goes
## over the hill road, the loop driven backward from the depot to its join (sample 0), then round
## the join to the coastal road at sample 1472.
func _over_the_hill_east() -> void:
	await kit.drive_points([Vector3(-33.0, 0.0, 100.0), Vector3(-42.0, 0.0, 92.0),
		Vector3(-45.0, 0.0, 82.0), kit.lane_point(1050, -1.0), kit.lane_point(1044, -1.0)]
		as Array[Vector3], 5.0, false)
	await kit.drive_road_back(2, 14.0, 4.5, 900.0)
	var round: Array[Vector3] = []
	for index in range(1502, 1471, -3):
		round.append(kit.lane_point(index, -1.0))
	await kit.drive_points(round, 12.0, false)
	_log("over the hill, east: %s" % kit.objective())


## Back from the east side to the depot over the hill: round the join forward, then the loop driven
## forward to `to`, as Mission 1 drives it.
func _over_the_hill_west(to: int) -> void:
	var round: Array[Vector3] = []
	for index in range(1474, 1502, 3):
		round.append(kit.lane_point(index))
	round.append(kit.lane_point(1))
	await kit.drive_points(round, 12.0, false)
	await kit.drive_road(to, 14.0, 4.5, 900.0)
	_log("over the hill, west: %s" % kit.objective())


## TAIL THE CONVOY: up the coastal road about 60 m behind the second SUV, slowing as it slows,
## stopping well back while it keys through the airfield's gate.
func _tail(run: Node, field: Node3D) -> void:
	_run_node = run
	await kit.until(_convoy_running, 20.0)
	var convoy := run.get("convoy") as Node
	await kit.drive_points([Vector3(724.4, 0.0, 145.0)] as Array[Vector3], 6.0, false)
	var waited := 0.0
	while not bool(convoy.get("inside")) and waited < 240.0:
		await physics_frame
		waited += 1.0 / 60.0
		var tail := (convoy.get("suvs") as Array)[1] as Node3D
		var apart := Vector2(tail.global_position.x - kit.van.global_position.x,
			tail.global_position.z - kit.van.global_position.z).length()
		var aim := Vector3(724.4, 0.0, kit.van.global_position.z - 12.0)
		var pace := clampf(9.0 + (apart - 60.0) * 0.2, 0.0, 14.0)
		if kit.van.global_position.z < -95.0:
			pace = 0.0
		if pace < 0.5:
			kit.release()
			Input.action_press("brake")
		else:
			kit.steer_for(aim, pace)
	await kit.stop()


## Stage 3: out to Maya, her pistol, then on foot into the hangar, the men dealt with as they
## come into sight, to the office's door.
func _hangar(run: Node, field: Node3D) -> void:
	await kit.get_out()
	var maya := run.get("maya") as Node3D
	await kit.walk_keys([maya.global_position + Vector3(1.2, 0.0, -1.2)] as Array[Vector3])
	await kit.press("interact")
	var encounter := run.get("encounter") as Node
	_run_node = run
	await kit.until(_armed, 40.0)
	_log("armed: %s" % kit.objective())
	await kit.seconds(1.0)
	var men: Array = encounter.get("guards")
	var fight := func() -> bool: return kit.fight_men(men)
	var door: Vector3 = field.get("office_door")
	for attempt in range(4):
		var there := await kit.walk_keys([Vector3(990.0, 0.0, -88.0), Vector3(989.0, 0.0, -110.0),
			Vector3(987.0, 0.0, -131.0), Vector3(970.0, 0.0, -131.0), Vector3(968.0, 0.0, -121.0),
			Vector3(971.0, 0.0, -110.0), door + Vector3(0.0, 0.0, -1.0), door + Vector3(0.0, 0.0,
			0.4)] as Array[Vector3], false, fight, 240.0)
		Input.action_release("aim")
		if kit.objective() == "FIND LILY":
			break
		_log("not through (%s, %s), again" % [there, kit.objective()])
		await kit.seconds(4.0)
	_log("at the office: %s" % kit.objective())


## Stage 4 to the end: Lily's hand, back out to Maya, the gate scene, the reunion, the epilogue,
## the title screen.
func _home(run: Node, field: Node3D) -> void:
	var lily := run.get("lily") as Node3D
	await kit.walk_keys([lily.global_position + Vector3(0.0, 0.0, -1.0)] as Array[Vector3])
	await kit.press("interact")
	_log("her hand: %s" % kit.objective())
	await kit.seconds(1.0)
	var door: Vector3 = field.get("office_door")
	var maya := run.get("maya") as Node3D
	await kit.walk_keys([door + Vector3(0.0, 0.0, -1.2), Vector3(971.0, 0.0, -112.0),
		Vector3(968.0, 0.0, -124.0), Vector3(970.0, 0.0, -131.0), Vector3(987.0, 0.0, -131.0),
		Vector3(989.0, 0.0, -110.0), Vector3(990.0, 0.0, -84.0), maya.global_position
		+ Vector3(1.5, 0.0, -2.0)] as Array[Vector3], false, Callable(), 300.0)
	_log("at Maya: %s" % kit.objective())
	_run_node = run
	await kit.until(_epilogue_over, 400.0)
	await kit.until(func() -> bool: return bool(app.get("_on_title")), 20.0)
	await kit.seconds(4.0)
