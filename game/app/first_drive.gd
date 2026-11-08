extends Node3D

const Driver = preload("res://features/characters/driver/driver.gd")
const Audio = preload("res://features/audio/first_drive/driving_audio.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const WrongCargo = preload("res://features/missions/the_wrong_cargo/the_wrong_cargo.gd")
const DriveLessons = preload("res://features/ui/driving_hud/drive_lessons.gd")
const SaveFile = preload("res://shared/save/save_file.gd")
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const PROGRESS_PATH := "user://progress.cfg"
const SETTINGS_PATH := "user://settings.cfg"
const SHEET_RANGE := 1.6
const SIGN_DELAY := 1.2
const SHEET_HOLD := 6.0
const SHEET_WALK_AWAY := 1.5
const WALK_LESSON := 3.0
const DRIVE_LESSON := 25.0
const FAST := 12.5
const VIEWPOINT_NEAR := 40.0
const STUCK_HINT := 3.0
const BOARD_SPOT := Vector3(-2.02, 0.0, -0.51)
const BOARD_RANGE := 4.5
const DOOR_GRAB := 1.05
const REACH_FROM := 0.75
const GRIP_ELBOW := Vector3(-1.85, 0.85, -0.95)
const DOOR_OPENED := 1.6
const CUT := 1.75
const FADE_OUT := 0.25
const FADE_IN := 0.5
const IGNITION_DELAY := 0.6
const EXIT_FROM := 2.6
const EXIT_SPOT := Vector3(-1.88, 0.0, -0.5)
const SEAT_FLOOR := Vector3(-0.45, 0.0, -0.5)
const PASSENGER_EXIT := Vector3(1.85, 0.2, -0.72)
const EXIT_DOOR := 2.26
const PUSH := Vector2(3.55, 4.35)
const SLAM := 0.2
const REACH_DOOR := 0.3
const IMPACT_SPEED := 9.0
const ENDING_HOLD := 9.0
const ENDING_FADE := 3.0
const ENDING_BLACK := 2.0
const TITLE_FADE_OUT := 0.35
const TITLE_FADE_IN := 0.8
const DAY := 86400
const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
	"Oct", "Nov", "Dec"]

@onready var van: CharacterBody3D = $FreightVan
@onready var route: Node = $DrivingTrial
@onready var hud: CanvasLayer = $DrivingHud
@onready var world: Node3D = $IndustrialLoop
var driver: CharacterBody3D
var cargo: Node
var title_camera: Camera3D
var _audio: Node
var _on_title: bool = false
var _changing: bool = false
var _exit_query := PhysicsShapeQueryParameters3D.new()
var _hint_time: float = 0.0
var _begun: bool = false
var _boarding: bool = false
var _boarding_token: int = 0
var _awaiting_van: bool = false
var _route_title: String = ""
var _route_detail: String = ""
var _ending: bool = false
var _ended: bool = false
var _ending_token: int = 0
var _signed: bool = false
var _sheet_token: int = 0
var _lessons := DriveLessons.new()
var _walk_from := Vector3.ZERO
var _odometer: float = 0.0
var _stuck_for: float = 0.0
var _call_done: bool = false
var _mission: Node


func _ready() -> void:
	if get_tree().current_scene == self:
		route.checkpoint_path = PROGRESS_PATH
		hud.settings_path = SETTINGS_PATH
	driver = Driver.new()
	driver.name = "Driver"
	add_child(driver)
	var exit_shape := CapsuleShape3D.new()
	exit_shape.radius = 0.35
	exit_shape.height = 1.8
	_exit_query.shape = exit_shape
	_exit_query.collision_mask = 3
	_exit_query.exclude = [van.get_rid(), driver.get_rid()]
	_audio = Audio.new()
	add_child(_audio)
	_audio.configure(van)
	route.objective_changed.connect(_route_objective)
	route.checkpoint_saved.connect(func() -> void: hud.notify("Checkpoint saved"))
	route.checkpoint_save_failed.connect(_checkpoint_save_failed)
	route.drive_completed.connect(_drive_completed)
	route.struck.connect(_struck)
	route.phone_call.ringing.connect(_call_ringing)
	route.phone_call.missed.connect(_call_missed)
	route.phone_call.connected.connect(_call_connected)
	route.phone_call.line_started.connect(hud.show_subtitle)
	route.phone_call.ended.connect(_call_ended)
	route.road = world.road
	route.crossing = world.crossing
	route.playable_area = world.playable_area
	cargo = WrongCargo.new()
	cargo.name = "TheWrongCargo"
	add_child(cargo)
	cargo.objective_changed.connect(_route_objective)
	route.configure(van)
	_pick_mission()
	_warn_about_progress()
	hud.load_settings()
	_navigation().follow(world.road, Mission.TARGETS[Mission.TARGETS.size() - 1],
		Mission.START.origin)
	hud.van_guide.road = world.road_points
	hud.van_guide.office = world.office_transform
	hud.resume_requested.connect(_begin)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_new_drive)
	hud.recovery_requested.connect(_recover)
	var menu: Node = hud.menu
	menu.continue_chosen.connect(func() -> void: _through_black(_begin))
	menu.new_game_chosen.connect(_new_game_from_title)
	menu.resume_chosen.connect(_resume)
	menu.recover_chosen.connect(_recover)
	menu.main_menu_chosen.connect(func() -> void: _through_black(_back_to_title))
	title_camera = Camera3D.new()
	title_camera.name = "TitleCamera"
	title_camera.cull_mask = 0xFFFFF & ~Presentation.MIRROR_LAYER
	add_child(title_camera)
	_show_title()


func _show_title() -> void:
	_on_title = true
	get_tree().paused = true
	van.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	driver.set_active(false)
	van.recover(_mission.START)
	van.engine_on = true
	van.headlights_on = true
	van.high_beams = false
	van.get_node("VanPresentation").settle()
	title_camera.fov = _mission.TITLE_FOV
	title_camera.look_at_from_position(_mission.START * _mission.TITLE_EYE,
		_mission.START * _mission.TITLE_LOOK, Vector3.UP)
	title_camera.make_current()
	_audio.title_ambience(true)
	hud.show_title(_continue_place(), _saved_when())


func _leave_title() -> void:
	if not _on_title:
		return
	_on_title = false
	_audio.title_ambience(false)
	van.get_camera().make_current()


func _through_black(action: Callable) -> void:
	if _changing:
		return
	_changing = true
	await hud.fade(1.0, TITLE_FADE_OUT).finished
	action.call()
	hud.reveal(TITLE_FADE_IN)
	_changing = false


func _new_game_from_title() -> void:
	_through_black(_new_drive if _has_progress() else _begin)


func _back_to_title() -> void:
	_reset_session()
	route.reload()
	_pick_mission()
	_show_title()


func _pick_mission() -> void:
	_mission = route
	if route.handed_on != null:
		_mission = cargo
		cargo.configure(van, route.handed_on)
	hud.set_mission(_mission.NAME)


func _has_progress() -> bool:
	return _mission == cargo or route.stage > 0 or route.fleeing


func _reset_session() -> void:
	_ending_token += 1
	_ending = false
	_ended = false
	_begun = false
	_boarding_token += 1
	_boarding = false
	driver.grip(Vector3.ZERO, Vector3.ZERO, 0.0)
	van.driver_door = 0.0
	_close_run_sheet()
	_awaiting_van = false
	_signed = false
	_call_done = false
	_odometer = 0.0
	_stuck_for = 0.0
	_lessons.reset()
	hud.set_cinematic(false)
	hud.clear_subtitle()
	hud.van_guide.hide_guide()
	_audio.restore()
	van.get_node("VanPresentation").look_target_node = null


func _begin() -> void:
	if _ended:
		_new_drive()
		return
	if not _begun:
		_begun = true
		_leave_title()
		van.recover(_mission.recovery_pose)
		van.foot_on_brake = _mission.fleeing
		if _has_progress():
			_continue_in_van()
		else:
			_begin_on_foot()
	_resume()


func _continue_in_van() -> void:
	_awaiting_van = false
	_signed = true
	_enter_van()
	van.start_engine()
	if _mission.fleeing:
		_audio.silence_music()


func _resume() -> void:
	_leave_title()
	_set_paused(false)


func _new_drive() -> void:
	_begun = true
	_leave_title()
	_ending_token += 1
	_ending = false
	_ended = false
	hud.set_cinematic(false)
	_audio.restore()
	_restart()
	_audio.play_music()
	_begin_on_foot()


func _struck(speed: float) -> void:
	_audio.silence_music()
	_audio.body_impact()
	var presentation := van.get_node("VanPresentation")
	var strength := clampf(speed / IMPACT_SPEED, 0.3, 1.0)
	presentation.jolt(strength)
	presentation.watch_head(route.pedestrian.head_body(), strength)
	presentation.look_target_node = route.pedestrian.hips_body()


func _call_ringing(caller: String) -> void:
	_audio.ring()
	_navigation().ring(caller, route.phone_call.answers_itself())


func _call_connected() -> void:
	_audio.answer()
	_navigation().talk()


func _call_missed(caller: String) -> void:
	_audio.stop_ringing()
	_navigation().miss(caller)


func _call_ended() -> void:
	_call_done = true
	_audio.hang_up()
	hud.clear_subtitle()
	_navigation().end_call()


func _navigation() -> Control:
	return van.get_node("VanPresentation").navigation


func _drive_completed() -> void:
	_ending_token += 1
	var token := _ending_token
	_ending = true
	van.held = true
	van.get_node("VanPresentation").look_target_node = null
	hud.set_cinematic(true)
	van.switch_off()
	_audio.silence_music()
	_audio.cool_down()
	if route.fleeing:
		_audio.breathe()
	await get_tree().create_timer(ENDING_HOLD, false).timeout
	if token != _ending_token:
		return
	await hud.fade(1.0, ENDING_FADE).finished
	if token != _ending_token:
		return
	_audio.fade_out(ENDING_BLACK)
	await get_tree().create_timer(ENDING_BLACK, false).timeout
	await get_tree().physics_frame
	if token != _ending_token:
		return
	_back_to_title()
	hud.reveal(TITLE_FADE_IN)


func _begin_on_foot() -> void:
	_cancel_boarding()
	_close_run_sheet()
	van.switch_off()
	van.occupied = false
	_awaiting_van = true
	_signed = false
	_call_done = false
	_odometer = 0.0
	_stuck_for = 0.0
	_lessons.reset()
	hud.set_objective("SIGN THE RUN SHEET", "Take the run sheet from the clipboard by the office door.")
	driver.global_position = _on_ground(world.run_sheet_spot)
	driver.velocity = Vector3.ZERO
	driver.set_active(true)
	var facing: Vector3 = world.run_sheet_at - world.run_sheet_spot
	facing = Vector3(facing.x, 0.0, facing.z).normalized()
	driver.face(facing)
	driver.look_toward(facing)
	_walk_from = driver.global_position


func _sign_run_sheet() -> void:
	_sheet_token += 1
	var token := _sheet_token
	hud.show_document(Mission.RUN_SHEET)
	await get_tree().create_timer(SIGN_DELAY, false).timeout
	if token != _sheet_token:
		return
	hud.sign_document(Mission.RUN_SHEET_SIGNATURE)
	_signed = true
	_walk_from = driver.global_position
	hud.set_objective("GET IN THE VAN", "Walk to the driver's door, on the left, and press E.")
	await get_tree().create_timer(SHEET_HOLD, false).timeout
	if token == _sheet_token:
		_close_run_sheet()


func _needs_sheet() -> bool:
	return _awaiting_van and not _signed


func _close_run_sheet() -> void:
	_sheet_token += 1
	hud.hide_document()


func _route_objective(title: String, detail: String) -> void:
	_route_title = title
	_route_detail = detail
	if not _awaiting_van:
		hud.set_objective(title, detail)


func _warn_about_progress() -> void:
	var words := ""
	if route.progress_read == SaveFile.Read.CORRUPT:
		words = "Saved progress could not be read, so a new drive has started. The old file was " \
			+ "kept."
	elif route.progress_read == SaveFile.Read.NEWER:
		words = "This save is from a newer version of the game. It was not loaded or changed, " \
			+ "and progress will not be saved this session."
	hud.warn("progress", words)


func _checkpoint_save_failed(_error: int) -> void:
	hud.notify("Checkpoint could not be saved. Recovery is available for this session.")


func _toggle_pause() -> void:
	if _ended or _on_title or _changing:
		return
	_set_paused(not get_tree().paused)


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	van.input_enabled = not value
	if value:
		hud.show_pause(_mission.NAME, _next_checkpoint(), _last_saved())
	else:
		hud.set_menu(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED


func _continue_place() -> String:
	if not _has_progress():
		return ""
	return "%s · %s" % [_mission.NAME, _last_place()]


func _last_place() -> String:
	if _mission == cargo:
		return cargo.place_reached()
	if route.fleeing:
		return "Where the van stopped"
	if route.stage == 0:
		return "The lumber yard"
	return _sentence(Mission.DIRECTIONS[route.stage - 1])


func _last_saved() -> String:
	var path: String = route.checkpoint_path
	if path.is_empty() or not FileAccess.file_exists(path):
		return "Nothing saved yet"
	return _last_place()


func _next_checkpoint() -> String:
	if _mission == cargo:
		return cargo.place_next()
	return _sentence(Mission.DIRECTIONS[mini(route.stage, Mission.DIRECTIONS.size() - 1)])


func _saved_when() -> String:
	var path: String = route.checkpoint_path
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var saved := int(FileAccess.get_modified_time(path)) + bias
	var now := int(Time.get_unix_time_from_system()) + bias
	var when := Time.get_datetime_dict_from_unix_time(saved)
	var clock := "%02d:%02d" % [when.hour, when.minute]
	var days_ago := floori(float(now) / DAY) - floori(float(saved) / DAY)
	if days_ago == 0:
		return "Saved today, " + clock
	if days_ago == 1:
		return "Saved yesterday, " + clock
	return "Saved %d %s, %s" % [when.day, MONTHS[int(when.month) - 1], clock]


func _sentence(words: String) -> String:
	var lower := words.to_lower()
	return lower.left(1).to_upper() + lower.substr(1)


func _restart() -> void:
	_cancel_boarding()
	var presentation := van.get_node("VanPresentation")
	presentation.clear_crack()
	presentation.look_target_node = null
	_enter_van()
	van.start_engine()
	route.restart()
	_pick_mission()
	_set_paused(false)


func _recover() -> void:
	if _ending or _ended:
		return
	_cancel_boarding()
	_enter_van()
	van.start_engine()
	_mission.recover()
	_set_paused(false)
	hud.notify("Van recovered to the last safe checkpoint")


func _toggle_vsync() -> void:
	var off := DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if off
		else DisplayServer.VSYNC_DISABLED)
	hud.notify("Vsync on" if off else "Vsync off (F9, for the FPS check)")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _ending or _ended:
		return
	if event.is_action_pressed("recover"):
		_recover()
	elif event.is_action_pressed("vsync_debug"):
		_toggle_vsync()
	elif event.is_action_pressed("answer_call"):
		if van.occupied and route.phone_call.can_answer():
			route.phone_call.answer()
	elif event.is_action_pressed("interact") and not _boarding:
		if van.occupied and (route.fleeing or van.held):
			return
		if van.occupied:
			_exit_van()
		elif hud.document_visible():
			if _signed:
				_close_run_sheet()
		elif _needs_sheet() and driver.global_position.distance_to(world.run_sheet_spot) \
				< SHEET_RANGE:
			_sign_run_sheet()
		elif driver.global_position.distance_to(van.global_position) < BOARD_RANGE:
			if _needs_sheet():
				hud.notify("Sign the run sheet at the office first.")
			else:
				_board_van()


func _exit_van() -> void:
	if absf(van.speed) > 0.4:
		hud.notify("Stop before leaving the van")
		return
	if _clear(van.to_global(EXIT_SPOT) + Vector3.UP * 0.2):
		_step_out()
		return
	var other := van.to_global(PASSENGER_EXIT)
	if _clear(other):
		van.occupied = false
		driver.global_position = other
		driver.velocity = Vector3.ZERO
		driver.set_active(true)
		return
	hud.notify("Both doors are obstructed. Move the van before leaving.")


func _clear(at: Vector3) -> bool:
	_exit_query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.9)
	return get_world_3d().direct_space_state.intersect_shape(_exit_query, 1).is_empty()


func _step_out() -> void:
	_boarding = true
	hud.set_hint("")
	_boarding_token += 1
	var token := _boarding_token
	await hud.fade(1.0, FADE_OUT).finished
	if token != _boarding_token:
		return
	van.occupied = false
	van.driver_door = EXIT_DOOR
	driver.set_active(true)
	driver.global_position = _on_ground(van.to_global(EXIT_SPOT))
	driver.velocity = Vector3.ZERO
	var shift := van.to_global(SEAT_FLOOR) - van.to_global(EXIT_SPOT)
	driver.play_clip("ExitVan", -van.global_basis.z, EXIT_FROM, Vector3(shift.x, 0.0, shift.z))
	driver.look_toward(van.global_basis.x)
	hud.fade(0.0, FADE_IN)
	while not driver.clip_finished():
		van.driver_door = _door_under_hand(driver.clip_time())
		await get_tree().process_frame
		if token != _boarding_token:
			return
	van.driver_door = 0.0
	driver.finish_clip()
	_boarding = false


func _door_under_hand(time: float) -> float:
	var pushed := clampf(van.door_opening_toward(driver.grip_point()), 0.0, EXIT_DOOR)
	if time < PUSH.x - REACH_DOOR:
		return EXIT_DOOR
	if time < PUSH.x:
		return lerpf(EXIT_DOOR, pushed, smoothstep(PUSH.x - REACH_DOOR, PUSH.x, time))
	if time > PUSH.y:
		return maxf(0.0, van.driver_door - get_process_delta_time() * EXIT_DOOR / SLAM)
	return minf(van.driver_door, pushed)


func _enter_van() -> void:
	van.occupied = true
	driver.set_active(false)
	van.get_camera().make_current()
	if _awaiting_van:
		_awaiting_van = false
		hud.set_objective(_route_title, _route_detail)


func _board_van() -> void:
	_boarding = true
	hud.set_hint("")
	_boarding_token += 1
	var token := _boarding_token
	driver.walk_to(_path_to(_on_ground(van.to_global(BOARD_SPOT))))
	while driver.walking():
		await get_tree().physics_frame
		if token != _boarding_token:
			return
	driver.play_clip("EnterVan", van.global_basis.x)
	while driver.clip_time() < CUT:
		var time: float = driver.clip_time()
		van.driver_door = smoothstep(DOOR_GRAB, DOOR_OPENED, time)
		driver.grip(van.door_handle(), van.to_global(GRIP_ELBOW),
			smoothstep(REACH_FROM, DOOR_GRAB, time))
		await get_tree().process_frame
		if token != _boarding_token:
			return
	await hud.fade(1.0, FADE_OUT).finished
	if token != _boarding_token:
		return
	driver.grip(Vector3.ZERO, Vector3.ZERO, 0.0)
	van.driver_door = 0.0
	_boarding = false
	_enter_van()
	hud.fade(0.0, FADE_IN)
	if van.engine_on:
		return
	await get_tree().create_timer(IGNITION_DELAY).timeout
	if token == _boarding_token and van.occupied:
		van.start_engine()


func _cancel_boarding() -> void:
	_boarding_token += 1
	_boarding = false
	driver.grip(Vector3.ZERO, Vector3.ZERO, 0.0)
	van.driver_door = 0.0
	hud.fade(0.0, 0.0)


func _path_to(spot: Vector3) -> Array[Vector3]:
	var local := van.to_local(driver.global_position)
	var path: Array[Vector3] = []
	if local.x > -1.15:
		var end := -3.3 if local.z < 0.3 else 3.6
		if local.x > 0.0:
			path.append(_on_ground(van.to_global(Vector3(1.9, 0.0, end))))
		path.append(_on_ground(van.to_global(Vector3(-1.9, 0.0, end))))
	path.append(spot)
	return path


func _on_ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 3.0,
		point + Vector3.DOWN * 6.0, 3, [van.get_rid(), driver.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else point


func _process(delta: float) -> void:
	_guide_to_van()
	if route.phone_call.talking:
		_navigation().call_seconds = route.phone_call.elapsed
	_hint_time += delta
	if _hint_time < 0.2:
		return
	_hint_time = 0.0
	var ground := Vector2(van.global_position.x, van.global_position.z)
	if van.global_position.y < -5 or not world.playable_area.has_point(ground):
		_recover()
	if hud.document_visible() and driver.global_position.distance_to(world.run_sheet_spot) \
			> SHEET_WALK_AWAY + SHEET_RANGE and _signed:
		_close_run_sheet()
	hud.set_hint(_hint(0.2))


func _guide_to_van() -> void:
	if driver.active and not van.occupied and not _boarding and not _needs_sheet() \
			and not _ending and not _ended:
		hud.van_guide.guide(driver.get_camera(), van, driver.global_position)
	else:
		hud.van_guide.hide_guide()


func _hint(delta: float) -> String:
	if _boarding or _ending or _ended or hud.document_visible():
		return ""
	if not van.occupied:
		if _needs_sheet():
			if driver.global_position.distance_to(world.run_sheet_spot) < SHEET_RANGE:
				return "E  Sign the run sheet"
			return ""
		if driver.global_position.distance_to(van.global_position) < BOARD_RANGE:
			return "E  Get in the van"
		if driver.global_position.distance_to(_walk_from) > WALK_LESSON:
			_lessons.learn("walk")
		_lessons.offer("walk")
		return _lessons.tick(delta)
	_lessons.learn("walk")
	if route.phone_call.can_answer() and not route.phone_call.answers_itself():
		return "T  Answer the call"
	if not van.engine_on or van.scripted or van.held or route.fleeing:
		return ""
	_teach_driving(delta)
	return _lessons.tick(delta)


func _teach_driving(delta: float) -> void:
	_odometer += absf(van.speed) * delta
	if not _lessons.done("drive"):
		if _odometer > DRIVE_LESSON:
			_lessons.learn("drive")
		_lessons.offer("drive")
	_lessons.offer("pause")
	if van.high_beams:
		_lessons.learn("high_beams")
	if _call_done and van.headlights_on:
		_lessons.offer("high_beams")
	if absf(van.speed) > FAST:
		if _lessons.showing() == "wipers" and van.wiper_setting != 1:
			_lessons.learn("wipers")
		_lessons.offer("wipers")
	var viewpoint: Vector3 = Mission.TARGETS[1]
	if route.stage == 1 and van.global_position.distance_to(viewpoint) < VIEWPOINT_NEAR:
		_lessons.offer("look")
	var pushing := Input.is_action_pressed("accelerate") and absf(van.speed) < 0.5
	_stuck_for = _stuck_for + delta if pushing else 0.0
	if _stuck_for > STUCK_HINT:
		_stuck_for = 0.0
		_lessons.again("recover")
		_lessons.offer("recover")
