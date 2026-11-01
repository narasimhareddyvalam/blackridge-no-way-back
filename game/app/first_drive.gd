extends Node3D

const Driver = preload("res://features/characters/driver/driver.gd")
const Audio = preload("res://features/audio/first_drive/driving_audio.gd")

@onready var van: CharacterBody3D = $FreightVan
@onready var route: Node = $DrivingTrial
@onready var hud: CanvasLayer = $DrivingHud
@onready var world: Node3D = $IndustrialLoop
var driver: CharacterBody3D
var _audio: Node
var _exit_query := PhysicsShapeQueryParameters3D.new()
var _hint_time: float = 0.0


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
	route.objective_changed.connect(hud.set_objective)
	route.checkpoint_saved.connect(func() -> void: hud.notify("Checkpoint saved"))
	route.checkpoint_save_failed.connect(_checkpoint_save_failed)
	route.drive_completed.connect(func() -> void: hud.notify("Depot reached. Drive complete."))
	route.configure(van)
	van.get_node("VanPresentation").navigation.road = world.road_points
	hud.resume_requested.connect(_resume)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_restart)
	hud.recovery_requested.connect(_recover)
	_set_paused(true)


func _resume() -> void:
	_set_paused(false)


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
	_enter_van()
	route.restart()
	_set_paused(false)


func _recover() -> void:
	_enter_van()
	route.recover()
	_set_paused(false)
	hud.notify("Van recovered to the last safe checkpoint")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("recover"):
		_recover()
	elif event.is_action_pressed("interact"):
		if van.occupied:
			_exit_van()
		elif driver.global_position.distance_to(van.global_position) < 4.5:
			_enter_van()


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


func _process(delta: float) -> void:
	_hint_time += delta
	if _hint_time < 0.2:
		return
	_hint_time = 0.0
	var ground := Vector2(van.global_position.x, van.global_position.z)
	if van.global_position.y < -5 or not world.playable_area.has_point(ground):
		_recover()
	if van.occupied:
		hud.set_hint("W / S  Drive / brake    Q  D / R (stopped)    E  Exit    ESC  All controls")
	elif driver.global_position.distance_to(van.global_position) < 4.5:
		hud.set_hint("E  Enter van    WASD  Walk    MOUSE  Look    ESC  Pause")
	else:
		hud.set_hint("WASD  Walk    SHIFT  Faster    R  Recover van    ESC  Pause")
