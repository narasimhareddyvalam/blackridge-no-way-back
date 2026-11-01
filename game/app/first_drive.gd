extends Node3D

const Driver = preload("res://features/characters/driver/driver.gd")
const Audio = preload("res://features/audio/first_drive/driving_audio.gd")
const START_SPOT := Vector3(-3.4, 0.0, 0.6)
const START_FACING := Vector3(1.0, 0.0, -0.37)
const BOARD_SPOT := Vector3(-2.25, 0.0, -0.35)
const BOARD_RANGE := 4.5
const DOOR_GRAB := 1.05
const DOOR_OPENED := 1.6
const CUT := 1.75
const FADE_OUT := 0.25
const FADE_IN := 0.5
const IGNITION_DELAY := 0.6
const EXIT_FROM := 2.6
const EXIT_SPOT := Vector3(-1.6, 0.0, -0.35)
const SEAT_FLOOR := Vector3(-0.52, 0.0, -0.32)
const DOOR_SHUT := Vector2(3.7, 4.3)

@onready var van: CharacterBody3D = $FreightVan
@onready var route: Node = $DrivingTrial
@onready var hud: CanvasLayer = $DrivingHud
@onready var world: Node3D = $IndustrialLoop
var driver: CharacterBody3D
var _audio: Node
var _exit_query := PhysicsShapeQueryParameters3D.new()
var _hint_time: float = 0.0
var _begun: bool = false
var _boarding: bool = false
var _boarding_token: int = 0
var _awaiting_van: bool = false
var _route_title: String = ""
var _route_detail: String = ""


func _ready() -> void:
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
	route.road = world.road
	route.configure(van)
	van.get_node("VanPresentation").navigation.road = world.road_points
	hud.resume_requested.connect(_begin)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_new_drive)
	hud.recovery_requested.connect(_recover)
	_set_paused(true)


func _begin() -> void:
	if not _begun:
		_begun = true
		_begin_on_foot()
	_resume()


func _resume() -> void:
	_set_paused(false)


func _new_drive() -> void:
	_restart()
	_audio.play_music()
	_begin_on_foot()


func _struck() -> void:
	_audio.silence_music()
	van.get_node("VanPresentation").jolt(1.0)


func _drive_completed() -> void:
	if route.fleeing:
		_exit_at_depot()
	else:
		hud.notify("Depot reached. Drive complete.")


func _exit_at_depot() -> void:
	_boarding = true
	await hud.fade(1.0, FADE_OUT).finished
	van.occupied = false
	van.driver_door = 1.0
	driver.set_active(true)
	driver.global_position = _on_ground(van.to_global(EXIT_SPOT))
	var shift := van.to_global(SEAT_FLOOR) - van.to_global(EXIT_SPOT)
	driver.play_clip("ExitVan", -van.global_basis.z, EXIT_FROM, Vector3(shift.x, 0.0, shift.z))
	driver.look_toward(van.global_basis.x)
	hud.fade(0.0, FADE_IN)
	while not driver.clip_finished():
		van.driver_door = 1.0 - smoothstep(DOOR_SHUT.x, DOOR_SHUT.y, driver.clip_time())
		await get_tree().process_frame
	van.driver_door = 0.0
	driver.finish_clip()
	_boarding = false


func _begin_on_foot() -> void:
	_cancel_boarding()
	van.switch_off()
	van.occupied = false
	_awaiting_van = true
	hud.set_objective("GET IN THE VAN", "Walk to the driver's door, on the left, and press E.")
	driver.global_position = _on_ground(van.to_global(START_SPOT))
	driver.velocity = Vector3.ZERO
	driver.set_active(true)
	var facing := van.global_basis * START_FACING
	driver.face(facing)
	driver.look_toward(facing)


func _route_objective(title: String, detail: String) -> void:
	_route_title = title
	_route_detail = detail
	if not _awaiting_van:
		hud.set_objective(title, detail)


func _checkpoint_save_failed(_error: int) -> void:
	hud.notify("Checkpoint could not be saved. Recovery is available for this session.")


func _toggle_pause() -> void:
	_set_paused(not get_tree().paused)


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	van.input_enabled = not value
	hud.set_menu(value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED


func _restart() -> void:
	_cancel_boarding()
	_enter_van()
	van.start_engine()
	route.restart()
	_set_paused(false)


func _recover() -> void:
	_cancel_boarding()
	_enter_van()
	van.start_engine()
	route.recover()
	_set_paused(false)
	hud.notify("Van recovered to the last safe checkpoint")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("recover"):
		_recover()
	elif event.is_action_pressed("interact") and not _boarding:
		if van.occupied and (route.fleeing or van.held):
			return
		if van.occupied:
			_exit_van()
		elif driver.global_position.distance_to(van.global_position) < BOARD_RANGE:
			_board_van()


func _exit_van() -> void:
	if absf(van.speed) > 0.4:
		hud.notify("Stop before leaving the van")
		return
	for side in [-1, 1]:
		var at := van.to_global(Vector3(side * 2.05, 0.2, -0.4))
		_exit_query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.9)
		if get_world_3d().direct_space_state.intersect_shape(_exit_query, 1).is_empty():
			van.occupied = false
			driver.global_position = at
			driver.velocity = Vector3.ZERO
			driver.set_active(true)
			return
	hud.notify("Both doors are obstructed. Move the van before leaving.")


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
		van.driver_door = smoothstep(DOOR_GRAB, DOOR_OPENED, driver.clip_time())
		await get_tree().process_frame
		if token != _boarding_token:
			return
	await hud.fade(1.0, FADE_OUT).finished
	if token != _boarding_token:
		return
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
	van.driver_door = 0.0
	hud.fade(0.0, 0.0)


func _path_to(spot: Vector3) -> Array[Vector3]:
	var local := van.to_local(driver.global_position)
	var path: Array[Vector3] = []
	if local.x > -1.4:
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
	_hint_time += delta
	if _hint_time < 0.2:
		return
	_hint_time = 0.0
	var ground := Vector2(van.global_position.x, van.global_position.z)
	if van.global_position.y < -5 or not world.playable_area.has_point(ground):
		_recover()
	if _boarding:
		hud.set_hint("")
	elif van.occupied:
		hud.set_hint("W / S  Drive / brake    Q  D / R (stopped)    E  Exit    ESC  All controls")
	elif driver.global_position.distance_to(van.global_position) < BOARD_RANGE:
		hud.set_hint("E  Get in the van    WASD  Walk    SHIFT  Run    MOUSE  Look    ESC  Pause")
	else:
		hud.set_hint("WASD  Walk    SHIFT  Run    R  Recover van    ESC  Pause")
