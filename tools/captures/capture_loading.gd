extends SceneTree
## The whole job at bay 9 by real play (#245–#247, part C), in a 1280x800 window on Mission 2's
## start save, for Godot's Movie Maker to film from Ethan's own camera. Behind a short fade the
## van stands stopped in the open court, its rear doors shut, Ethan at the wheel; from there
## everything goes by the game's own keys, sent by this script: Ethan gets out, opens the rear
## doors by hand, gets back in, backs onto bay 9 between its guides to the bumpers, gets out,
## chocks the rear wheel, goes in by the side door and up the stair, takes the pallet jack, pushes
## the pallet onto the lift, rides it down, pushes it into the hold to the bulkhead, straps it,
## pulls the jack back out and rides up; then the chock out, the van pulled forward, the doors
## closed by hand, and the dock worker walks out to seal them. The window shows only Ethan's own
## camera, as play does; each still of him from beside comes from a second, hidden camera that
## renders off the screen, saved in the background so that the game never pauses. Keys and clicks
## from the keyboard and mouse are swallowed; the script's own keys carry a tag that lets them by.
## Usage, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --write-movie <absolute folder>/job.avi \
##     --fixed-fps 30 --script ../tools/captures/capture_loading.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const SENT := "capture_loading_key"
const COURT := Vector3(-47.75, 0.1, 31.0)
const BAY := -47.75
const BUMPERS := 20.13
const VAN_REAR := 3.012
const REAR := Vector3(0.0, 1.0, 3.01)
const FULL_PULL := 3.0
const GENTLE := 1.0
const SLOWER := 0.6
const TO_THE_SIDE_DOOR: Array[Vector3] = [Vector3(-39.0, 0.0, 22.0), Vector3(-39.0, 0.0, 17.5)]
const UP_THE_STAIR: Array[Vector3] = [Vector3(-41.2, 0.0, 17.5), Vector3(-44.2, 0.0, 16.0),
	Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 13.4), Vector3(-45.6, 0.0, 13.4)]
const DOWN_THE_STAIR: Array[Vector3] = [Vector3(-46.3, 0.0, 15.0), Vector3(-45.6, 0.0, 13.4),
	Vector3(-44.2, 0.0, 13.4), Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 16.0),
	Vector3(-41.2, 0.0, 17.5), Vector3(-39.0, 0.0, 17.5), Vector3(-39.0, 0.0, 22.0)]
const ROUND_THE_LOAD: Array[Vector3] = [Vector3(-46.3, 0.0, 15.0), Vector3(-47.2, 0.0, 15.15)]
const BEHIND_THE_HANDLE := 0.3
const PAST_THE_GUARD := Vector2(-47.75, 20.6)
const ON_THE_DOCK := Vector2(-47.2, 18.0)
const TRAVEL := 8.0
const STOP_WAIT := 3.5
const BREAKAWAY := 0.8
const TO_THE_BULKHEAD := Vector2(-47.75, 22.9)
const BY_THE_WHEEL := Vector3(-1.5, 0.0, 1.5)
const AT_THE_DOOR := Vector3(-2.0, 0.0, -0.5)
const TO_THE_REAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 4.3),
	Vector3(0.0, 0.0, 4.2)]
const TO_THE_CAB: Array[Vector3] = [Vector3(-1.85, 0.0, 3.7), Vector3(-1.75, 0.0, 1.5),
	Vector3(-1.6, 0.0, 0.5)]
const ASIDE: Array[Vector3] = [Vector3(-1.6, 0.0, 4.4), Vector3(-2.2, 0.0, 3.4)]
const GRIP_BACK := 1.17
const REAR_LEFT := [Vector3(-2.7, 1.95, 6.7), Vector3(0.2, 1.05, 3.0), 55.0]
const REAR_RIGHT := [Vector3(2.9, 1.95, 6.4), Vector3(-0.2, 1.05, 3.0), 55.0]
const DOCK_REAR_LEFT := [Vector3(-2.3, 2.5, 4.8), Vector3(0.2, 1.0, 2.8), 70.0]
const DOCK_REAR_RIGHT := [Vector3(2.3, 2.5, 4.8), Vector3(-0.2, 1.0, 2.8), 70.0]
const LEFT_SIDE := [Vector3(-4.6, 1.8, 2.8), Vector3(-1.1, 1.0, 2.4), 55.0]
const RIGHT_SIDE := [Vector3(4.6, 1.8, 2.8), Vector3(1.1, 1.0, 2.4), 55.0]
const AT_THE_WHEEL := [Vector3(-3.4, 1.6, -0.6), Vector3(-0.95, 0.25, 1.45), 50.0]
const THE_COURT := [Vector3(-41.6, 2.8, 31.5), Vector3(-47.75, 1.0, 24.5), 55.0]
const THE_SIDE_DOOR := [Vector3(-37.3, 2.0, 22.2), Vector3(-40.0, 1.1, 17.5), 55.0]
const THE_STAIR := [Vector3(-40.5, 2.35, 15.5), Vector3(-44.2, 1.1, 14.6), 60.0]
const THE_LIFT_DOWN := [Vector3(-45.5, 2.5, 16.6), Vector3(-47.75, 0.6, 20.0), 60.0]
const FROM_THE_BULKHEAD := [Vector3(-47.75, 1.95, 22.75), Vector3(-47.75, 1.0, 19.4), 72.0]
const DOWN_THE_HOLD := [Vector3(-47.45, 1.9, 19.55), Vector3(-47.75, 0.9, 22.6), 70.0]
const OVER_THE_LOAD := [Vector3(0.72, 1.95, -0.15), Vector3(-0.3, 1.1, 0.8), 80.0]
const THE_WORKER := [Vector3(-44.9, 1.8, 21.3), Vector3(-47.75, 1.1, 23.1), 55.0]


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if (event is InputEventMouse or event is InputEventKey) and not event.has_meta(SENT):
			get_viewport().set_input_as_handled()


var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _shed: Node3D
var _rig: Node
var _jack: Node3D
var _player: AnimationPlayer
var _shot: SubViewport
var _lens: Camera3D
var _folder: String
var _report := PackedStringArray()
var _saving: Array[int] = []
var _number := 0
var _timing := false
var _stage := "start"
var _last_tick := 0
var _times := {}
var _hold_off := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_loading_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	await process_frame
	_hud = _app.get_node("DrivingHud")
	_app.call("_begin")
	_hud.call("fade", 1.0, 0.01)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var args := OS.get_cmdline_user_args()
	_folder = args[0] if not args.is_empty() \
		else ProjectSettings.globalize_path("res://").path_join("../captures/loading/c")
	_timing = args.has("frames")
	if _timing:
		process_frame.connect(_tick)
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_rig = _shed.get("pallet_jack")
	_jack = _shed.find_child("PalletJack", true, false) as Node3D
	_player = _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_hidden_camera()
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT))
	await _seconds(1.5)
	_report.append("start, behind the fade: the van stopped in the open court, its rear doors "
		+ "shut, Ethan at the wheel")
	_hud.call("fade", 0.0, 0.6)
	await _seconds(1.0)
	_stage = "the court, the doors by hand"
	await _the_doors_by_hand()
	_stage = "backing onto bay 9"
	await _onto_bay_nine()
	_stage = "the side door and the stair"
	await _walk(TO_THE_SIDE_DOOR)
	await _key(KEY_E)
	await _seconds(1.2)
	await _view("the_side_door_open", THE_SIDE_DOOR)
	await _walk(UP_THE_STAIR.slice(0, 2))
	Input.action_press("accelerate")
	await _seconds(1.6)
	await _view("up_the_stair_a_tread_a_step", THE_STAIR)
	Input.action_release("accelerate")
	await _walk(UP_THE_STAIR.slice(2))
	_stage = "the dock, the lift and the hold"
	await _loading()
	await _stopping()
	_stage = "the doors closed, the seal"
	await _sealing()
	for task in _saving:
		WorkerThreadPool.wait_for_task_completion(task)
	if _timing:
		_report_frames()
	var text := "\n".join(_report)
	print(text)
	var notes := FileAccess.open(_folder.path_join("job_stills.txt"), FileAccess.WRITE)
	notes.store_string(text + "\n")
	notes.close()
	quit(0)


## Out of the van in the court, round to its back, the rear doors opened by his hand; back in.
func _the_doors_by_hand() -> void:
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk_by_van(TO_THE_REAR)
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)
	await _key(KEY_E)
	await _during(_doors_done, 24.0, [[1.6, "takes_the_right_doors_handle", REAR_LEFT],
		[3.6, "pulls_it_open_stepping_back", REAR_LEFT],
		[6.2, "round_its_edge_to_push_it_on", REAR_LEFT],
		[7.6, "it_swings_round_to_its_stay", REAR_RIGHT],
		[10.0, "the_left_door_by_its_edge", REAR_RIGHT],
		[13.0, "the_left_door_swinging_round", REAR_LEFT]])
	await _seconds(0.6)
	await _view_by_van("both_doors_on_their_stays", REAR_LEFT)
	await _walk_by_van(TO_THE_CAB)
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	await _seconds(0.5)


## Back onto bay 9 by the keys, gently between its guides to the bumpers; out, the wheel chocked.
func _onto_bay_nine() -> void:
	if int(_van.get("gear")) > 0:
		await _key(KEY_Q)
	var time := 0.0
	var still := 0.0
	var shot := false
	while time < 40.0 and still < 1.2:
		var rear := _van.to_global(REAR)
		var gap := rear.z - BUMPERS
		var speed := absf(float(_van.get("actual_speed")))
		var wanted := GENTLE if gap > 1.5 else minf(GENTLE, SLOWER)
		_press("accelerate", speed < wanted - 0.15)
		_press("brake", speed > wanted + 0.4)
		_steer_into_bay(rear)
		if not shot and gap < 3.5:
			shot = true
			await _view("backing_onto_bay_9", THE_COURT)
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if speed < 0.03 and gap < 1.0 else 0.0
	for action: String in ["accelerate", "brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	await _seconds(0.8)
	_report.append("backed onto bay 9: %s, its rear %.2f m from the bumpers"
		% [(_shed.get("bay_nine") as Node).get("verdict"), _gap()])
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk_by_van([BY_THE_WHEEL])
	await _key(KEY_E)
	await _seconds(0.8)
	await _view_by_van("the_rear_wheel_chocked", AT_THE_WHEEL)
	_report.append("chocked: %s" % (_shed.get("bay_nine") as Node).get("chocked"))


func _steer_into_bay(rear: Vector3) -> void:
	var ahead := -_van.global_basis.z
	var heading := atan2(ahead.x, ahead.z)
	var wanted := clampf((rear.x - BAY) * 0.6, -0.3, 0.3)
	var command := clampf((heading - wanted) * 3.0, -1.0, 1.0)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if command > 0.02:
		Input.action_press("steer_left", command)
	elif command < -0.02:
		Input.action_press("steer_right", -command)


func _loading() -> void:
	await _walk(ROUND_THE_LOAD)
	await _key(KEY_E)
	await _seconds(0.8)
	await _side("taken_standing_back_to_pump")
	await _pump(true)
	await _side("pumped_up_and_stepped_in_close")
	await _push_to(PAST_THE_GUARD, 25.0, 2.0, 0.9)
	await _side("leaning_in_to_get_it_going")
	await _push_to(PAST_THE_GUARD, 25.0, 2.0, 1.6)
	await _side("walking_upright_behind_it")
	await _eye("walking_from_ethans_camera")
	await _push_to(PAST_THE_GUARD, 25.0, 2.0)
	await _seconds(2.0)
	await _side("against_the_toe_guard_stepped_up_to_it")
	await _key(KEY_E)
	await _seconds(0.5)
	await _side("the_lowering_valve_open_the_pallet_sinking")
	await _seconds(1.1)
	await _key(KEY_E)
	await _seconds(0.8)
	await _to_the_pendant()
	var pendant: Vector3 = _shed.get_node("Building/DockLift9").call("pendant") + Vector3.UP * 1.08
	await _view("the_pendant_up_down_and_its_stop", [pendant + Vector3(0.35, 0.12, 0.45), pendant,
		35.0])
	await _hold_key(KEY_E, TRAVEL * 0.4)
	await _view("held_the_lift_going_down_beeping", THE_LIFT_DOWN)
	await _hold_key(KEY_E, TRAVEL * 0.6)
	await _view("the_lift_down_its_plate_on_the_sill", THE_LIFT_DOWN)
	await _walk([_behind_the_handle()])
	await _key(KEY_E)
	await _seconds(0.8)
	await _pump(false)
	await _push_to(TO_THE_BULKHEAD, 25.0, 0.8, 5.6)
	await _view("into_the_van_stooped", FROM_THE_BULKHEAD)
	await _eye("into_the_van_from_ethans_camera")
	await _push_to(TO_THE_BULKHEAD, 25.0, 0.8)
	await _seconds(1.5)
	await _view("against_the_bulkhead_stooped", DOWN_THE_HOLD)
	await _key(KEY_E)
	await _seconds(1.6)
	await _strap_by_hand()
	await _view_by_van("strapped_down", OVER_THE_LOAD)
	await _view("strapped_down_from_the_doors", DOWN_THE_HOLD)
	await _pull(3.4, [[3.0, "pulling_out_stooped", FROM_THE_BULKHEAD],
		[8.5, "out_and_walking_back_upright", []]])
	await _key(KEY_E)
	await _seconds(2.0)
	await _to_the_pendant()
	await _hold_key(KEY_E, TRAVEL)


## The jack pumped up, E a stroke at a time while the hint offers it, a still from beside at the
## bottom and top of the first stroke when `stills`; then he steps in to the handle.
func _pump(stills: bool) -> void:
	var strokes := 0
	while _hint_text() == "E  Pump the handle" and strokes < 10:
		await _key(KEY_E)
		if stills and strokes == 0:
			await _seconds(0.2)
			await _side("pumping_the_handle_lifted")
			await _seconds(0.4)
		else:
			await _seconds(0.6)
		strokes += 1
	await _seconds(1.0)
	_report.append("pumped up in %d strokes" % strokes)


## Both straps by hand, E a step at a time, a still over the load after each of the first
## strap's hook, throw and far hook.
func _strap_by_hand() -> void:
	var presses := 0
	var stems := {1: "hooked_to_the_floor_ring", 2: "thrown_over_the_load",
		3: "hooked_to_the_far_ring"}
	while _hint_text().begins_with("E  ") and _hint_text() != "E  Let go of the jack" \
			and _hint_text() != "E  Pull the jack out first" and presses < 20:
		await _key(KEY_E)
		presses += 1
		await _seconds(0.45)
		if stems.has(presses):
			await _view_by_van(stems[presses], OVER_THE_LOAD)
	_report.append("strapped by hand in %d presses" % presses)


func _hint_text() -> String:
	return (_hud.get("_hint") as Label).text


## The empty jack put back after the ride up: from behind its handle wherever it stands on the
## lift, taken again, pulled back off the deck onto the dock floor, and let go.
func _stopping() -> void:
	var ahead: Vector2 = _rig.call("heading")
	var grip: Vector3 = _rig.call("handle")
	var behind := Vector3(grip.x - ahead.x * 0.55, 0.0, grip.z - ahead.y * 0.55)
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(behind - _driver.global_position).length() > 0.08 and time < 6.0:
		_driver.call("look_toward", _flat(behind - _driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	_driver.call("look_toward", Vector3(ahead.x, 0.0, ahead.y))
	await _seconds(0.4)
	await _key(KEY_E)
	await _seconds(0.8)
	await _pull(1.8, [[1.0, "pulling_the_empty_jack_off_the_lift", []]])
	await _key(KEY_E)
	await _seconds(0.8)
	await _side("the_jack_left_on_the_dock")


func _sealing() -> void:
	await _walk(DOWN_THE_STAIR)
	await _walk_by_van([BY_THE_WHEEL])
	await _key(KEY_E)
	await _seconds(0.8)
	await _walk_by_van([AT_THE_DOOR])
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	await _seconds(0.5)
	await _pull_van(FULL_PULL)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk_by_van(TO_THE_REAR)
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)
	await _key(KEY_E)
	await _during(_doors_done, 30.0, [[3.0, "the_left_door_tugged_off_its_stay", LEFT_SIDE],
		[4.8, "it_swings_back_round", LEFT_SIDE],
		[8.0, "walked_shut_onto_its_latch", DOCK_REAR_LEFT],
		[12.4, "the_right_door_off_its_stay", RIGHT_SIDE],
		[15.6, "the_right_door_walked_shut", DOCK_REAR_RIGHT]])
	await _seconds(0.4)
	await _view_by_van("both_doors_shut_on_their_latches", DOCK_REAR_LEFT)
	_report.append("the doors closed by hand: open %s, a job under way %s"
		% [_van.get("rear_doors_open"), not _doors_done()])
	await _walk_by_van(ASIDE)
	var worker := _shed.find_child("DockWorker", true, false) as Node3D
	var hasp: Vector3 = _van.call("seal_point")
	var time := 0.0
	while time < 60.0 and worker != null and _flat(worker.global_position - hasp).length() > 0.9:
		await process_frame
		time += root.get_process_delta_time()
	await _seconds(1.6)
	await _view("the_dock_worker_seals_the_doors", THE_WORKER)
	while time < 60.0 and not bool(_van.get("sealed")):
		await process_frame
		time += root.get_process_delta_time()
	await _seconds(2.5)
	await _view("the_bolt_seal_on_the_hasp", [hasp + Vector3(1.1, 0.25, -0.55), hasp, 45.0])
	_report.append("the worker reached the doors and the van was sealed: %s, after %.1f s"
		% [bool(_van.get("sealed")), time])


## Up to the lift's pendant, as near as a man stands to work it, from the side he comes from.
func _to_the_pendant() -> void:
	var pendant: Vector3 = _shed.get_node("Building/DockLift9").call("pendant")
	var from := _flat(_driver.global_position - pendant)
	var spot := pendant + (from.normalized() if from.length() > 0.01 else Vector3.LEFT) * 0.35
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(spot - _driver.global_position).length() > 0.08 and time < 4.0:
		_driver.call("look_toward", _flat(spot - _driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	await _seconds(0.4)


## Waits until `done` or `limit` runs out, taking each `[seconds, stem, view]` still on the way, its
## view in the van's frame.
func _during(done: Callable, limit: float, shots: Array) -> void:
	var time := 0.0
	while time < 1.0 or (not done.call() and time < limit):
		for shot: Array in shots:
			if time < shot[0] and time + 1.0 / 60.0 >= shot[0]:
				await _view_by_van(shot[1], shot[2])
		await physics_frame
		time += 1.0 / 60.0


## A camera beside Ethan, behind his shoulder on whichever side nothing stands between it and
## him, looking past him to the handle; his own camera if every side is blocked.
func _side(stem: String) -> void:
	var facing := -_jack.global_basis.z
	facing = Vector3(facing.x, 0.0, facing.z).normalized()
	var across := Vector3.UP.cross(facing)
	var chest := _driver.global_position + Vector3.UP * 1.1
	var looks := chest + facing * 0.6 - Vector3.UP * 0.2
	for offset: Vector3 in [across * 2.4 - facing * 0.9 + Vector3.UP * 0.7,
			-across * 2.4 - facing * 0.9 + Vector3.UP * 0.7,
			across * 1.6 + facing * 1.4 + Vector3.UP * 0.6, -facing * 2.6 + Vector3.UP * 1.0]:
		if _clear(chest + offset, chest):
			await _view(stem, [chest + offset, looks, 55.0])
			return
	await _eye(stem)


func _clear(from: Vector3, to: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(from, to)
	ray.exclude = [_driver.get_rid()]
	return _van.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


## The hidden camera: a viewport of its own on the same world, off the screen, rendered only for
## a still, so that the window keeps showing Ethan's camera.
func _hidden_camera() -> void:
	_shot = SubViewport.new()
	_shot.size = Vector2i(1280, 800)
	_shot.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(_shot)
	_lens = Camera3D.new()
	_lens.far = 400.0
	_shot.add_child(_lens)
	_lens.make_current()


func _view_by_van(stem: String, view: Array) -> void:
	await _view(stem, [_van.to_global(view[0]), _van.to_global(view[1]), view[2]])


func _view(stem: String, view: Array) -> void:
	if DisplayServer.get_name() == "headless":
		_keep(null, stem, "hidden camera (a headless run draws nothing)")
		return
	_lens.fov = view[2]
	_lens.look_at_from_position(view[0], view[1])
	_shot.render_target_update_mode = SubViewport.UPDATE_ONCE
	_hold_off = 4
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_keep(_shot.get_texture().get_image(), stem, "hidden camera at %s looking at %s, fov %.0f"
		% [str(view[0].snapped(Vector3.ONE * 0.01)), str(view[1].snapped(Vector3.ONE * 0.01)),
		view[2]])


## Each drawn frame's time, by stage, leaving out the frames a still was read back in.
func _tick() -> void:
	var now := Time.get_ticks_usec()
	if _last_tick > 0 and _hold_off <= 0:
		if not _times.has(_stage):
			_times[_stage] = []
		(_times[_stage] as Array).append((now - _last_tick) / 1000.0)
	_hold_off -= 1
	_last_tick = now


func _report_frames() -> void:
	var refresh := DisplayServer.screen_get_refresh_rate()
	var budget := 1000.0 / refresh if refresh > 0.0 else 1000.0 / 60.0
	_report.append("frame times: the screen at %.0f Hz (a frame every %.1f ms), vsync %s"
		% [refresh, budget, str(DisplayServer.window_get_vsync_mode())])
	for stage: String in _times:
		var list: Array = (_times[stage] as Array).duplicate()
		list.sort()
		var count := list.size()
		var total := 0.0
		var late := 0
		for ms: float in list:
			total += ms
			if ms > budget * 1.5:
				late += 1
		_report.append(("  %s: %d frames, %.1f per second; median %.1f ms, 95th %.1f, 99th %.1f, "
			+ "worst %.1f; %d frames over 1.5 frames' time") % [stage, count,
			1000.0 * count / maxf(total, 0.001), list[count / 2], list[int(count * 0.95)],
			list[int(count * 0.99)], list[-1], late])


func _eye(stem: String) -> void:
	if DisplayServer.get_name() == "headless":
		_keep(null, stem, "Ethan's own camera (a headless run draws nothing)")
		return
	await RenderingServer.frame_post_draw
	_keep(root.get_texture().get_image(), stem, "Ethan's own camera, the window")


## Saves a still in the background, numbered in order, and notes where it was seen from and what
## Ethan and the jack were doing.
func _keep(image: Image, stem: String, where: String) -> void:
	_number += 1
	var path := _folder.path_join("%02d_%s.png" % [_number, stem])
	if image != null:
		_saving.append(WorkerThreadPool.add_task(func() -> void: image.save_png(path)))
	var frame := 1.0 + _player.current_animation_position * 30.0
	_report.append("%02d_%s: %s; clip %s frame %.0f at %.2fx; objective %s" % [_number, stem,
		where, _player.current_animation, frame, _player.speed_scale,
		(_hud.get("_objective") as Label).text])


## As `test_loading.gd` does: W pushes, A and D steer it as it rolls toward the line to `goal`,
## until its load's centre is at or past `goal`, stuck for a second, or `limit` runs out; or,
## with `pause`, only for that long, W kept down.
func _push_to(goal: Vector2, limit: float, lead: float, pause: float = INF) -> void:
	var time := 0.0
	var still := 0.0
	var last := Vector2.INF
	while time < limit and still < 1.0 and time < pause:
		var centre: Vector2 = _rig.call("load_centre")
		var ahead: Vector2 = _rig.call("heading")
		if (goal - centre).length() < 0.05 or centre.y >= goal.y:
			break
		var turn := ahead.angle_to(Vector2(goal.x, minf(centre.y + lead, goal.y)) - centre)
		_press("steer_left", turn < -0.03)
		_press("steer_right", turn > 0.03)
		Input.action_press("accelerate")
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if centre.distance_to(last) < 0.001 else 0.0
		last = centre
	_press("steer_left", false)
	_press("steer_right", false)
	if time < pause:
		Input.action_release("accelerate")
		await _seconds(0.3)


## S held until Ethan has gone `metres`, a still at each `[seconds, stem, view]` on the way (an
## empty view for the side camera).
func _pull(metres: float, shots: Array) -> void:
	var from := _driver.global_position
	var time := 0.0
	Input.action_press("brake")
	while _flat(_driver.global_position - from).length() < metres and time < 25.0:
		for shot: Array in shots:
			if time < shot[0] and time + 1.0 / 60.0 >= shot[0]:
				if (shot[2] as Array).is_empty():
					await _side(shot[1])
				else:
					await _view(shot[1], shot[2])
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("brake")
	await _seconds(1.5)


func _pull_van(gap: float) -> void:
	if int(_van.get("gear")) < 0:
		await _key(KEY_Q)
	var time := 0.0
	Input.action_press("accelerate", 0.5)
	while _gap() < gap - 0.45 and time < 8.0:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	Input.action_press("brake")
	time = 0.0
	while absf(float(_van.get("speed"))) > 0.02 and time < 4.0:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("brake")
	await _seconds(0.5)


func _gap() -> float:
	return _van.to_global(Vector3(0.0, 1.0, VAN_REAR)).z - BUMPERS


func _walk(points: Array[Vector3], limit: float = 12.0) -> void:
	for point in points:
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(point - _driver.global_position).length() > 0.3 and time < limit:
			_driver.call("look_toward", _flat(point - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	await _seconds(0.4)


func _walk_by_van(points: Array[Vector3]) -> void:
	var world: Array[Vector3] = []
	for point in points:
		world.append(_van.to_global(point))
	await _walk(world)


func _press(action: String, down: bool) -> void:
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta(SENT, true)
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


## E held `seconds` at the pendant: the lift moves only while its button is held (#286).
func _hold_key(code: Key, seconds: float) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta(SENT, true)
		Input.parse_input_event(event)
		await process_frame
		if pressed:
			await _seconds(seconds)
	await process_frame
	await process_frame


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _doors_done() -> bool:
	return not bool(_van.call("rear_doors_busy"))


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _in_the_van() -> bool:
	return bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


## Where Ethan stands to take the jack again: just behind its handle, wherever it was left.
func _behind_the_handle() -> Vector3:
	var rig: Node = _shed.get("pallet_jack")
	var grip: Vector3 = rig.call("handle")
	var ahead: Vector2 = rig.call("heading")
	return Vector3(grip.x - ahead.x * BEHIND_THE_HANDLE, 0.0, grip.z - ahead.y * BEHIND_THE_HANDLE)


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _seconds(duration: float) -> void:
	await create_timer(duration, true, false, true).timeout
