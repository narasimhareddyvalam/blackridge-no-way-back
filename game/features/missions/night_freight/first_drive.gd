extends Node

signal objective_changed(title: String, detail: String)
signal checkpoint_saved
signal checkpoint_save_failed(error: int)
signal drive_completed
signal struck

const SAVE_PATH := "user://driving_prototype.cfg"
const TARGETS: Array[Vector3] = [Vector3(482.24, 25.4, -24.37), Vector3(458.48, 43.6, -114.17),
	Vector3(164.28, 64.42, -206.81), Vector3(-20.05, 24.98, -50.67), Vector3(-28, 0, 93)]
const HEADINGS: Array[float] = [0.2508, 0.2966, 1.5538, -2.6609, PI]
const DIRECTIONS: Array[String] = ["THE SWITCHBACKS", "THE VIEWPOINT", "THE PASS",
	"THE DESCENT", "PARK AT THE DEPOT"]
const START := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(560, 0.1, 130))
const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const ENCOUNTER := Vector2(98.7, 25.5)
const ENCOUNTER_RADIUS := 14.0
const MEETING_INDEX := 1012
const SPAWN_LIMITS := Vector2i(1040, 1090)
const SEARCH := Vector2i(900, 1100)
const ONCOMING_END := 900
const MIN_CLOSING := 7.0
const Pedestrian = preload("res://features/characters/pedestrian/pedestrian.gd")
const PAUSE_AFTER_PASS := 1.0
const MIN_IMPACT_SPEED := 6.9
const LEAD_SECONDS := 0.75
const BUMPER_AHEAD := 2.45
const IMPACT_RIGHT := 0.4
const VERGE_STEP := 1.3
const SKID_BRAKING := 3.0
const HOLD_SECONDS := 4.0

var vehicle: CharacterBody3D
var road: RefCounted
var oncoming: Node3D
var pedestrian: Node3D
var fleeing: bool = false
var checkpoint_path: String = SAVE_PATH
var stage: int = 0
var complete: bool = false
var recovery_pose := START
var _timer: float = 0.0
var _encounter_done: bool = false
var _since_passed: float = -1.0
var _usual_braking: float = 0.0
var _held_for: float = -1.0


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_load_checkpoint()
	vehicle.recover(recovery_pose)
	_update_objective()


func _process(delta: float) -> void:
	if not is_instance_valid(vehicle) or complete or not vehicle.occupied:
		return
	_timer += delta
	if _timer < 0.15:
		return
	_timer = 0.0
	var target := TARGETS[stage]
	var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
	if stage == 4 and not _encounter_done and road != null:
		if at.distance_to(ENCOUNTER) < ENCOUNTER_RADIUS:
			_send_oncoming()
	if at.distance_to(Vector2(target.x, target.z)) > (5.0 if stage == 4 else 13.0):
		return
	if stage == 4:
		if absf(vehicle.speed) < 0.3:
			complete = true
			_update_objective()
			drive_completed.emit()
		return
	recovery_pose = Transform3D(Basis(Vector3.UP, HEADINGS[stage]), target + Vector3.UP * 0.1)
	stage += 1
	_save_checkpoint()
	_update_objective()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	if _since_passed >= 0.0:
		_since_passed += delta
		if _since_passed >= PAUSE_AFTER_PASS and vehicle.occupied \
				and vehicle.speed >= MIN_IMPACT_SPEED:
			_send_pedestrian()
	if _held_for >= 0.0 and absf(vehicle.speed) < 0.05:
		_held_for += delta
		if _held_for >= HOLD_SECONDS:
			_held_for = -1.0
			vehicle.held = false
			_restore_braking()
			fleeing = true
			_update_objective()


func _send_pedestrian() -> void:
	_since_passed = -1.0
	var forward := Vector3(-vehicle.global_basis.z.x, 0.0, -vehicle.global_basis.z.z).normalized()
	var right := Vector3(vehicle.global_basis.x.x, 0.0, vehicle.global_basis.x.z).normalized()
	var ahead: float = vehicle.speed * LEAD_SECONDS + BUMPER_AHEAD
	var impact := vehicle.global_position + forward * ahead + right * IMPACT_RIGHT
	pedestrian = Pedestrian.new()
	pedestrian.name = "Pedestrian"
	add_child(pedestrian)
	pedestrian.step_out(impact + right * VERGE_STEP, impact, vehicle)
	pedestrian.struck.connect(_on_struck)
	_usual_braking = vehicle.brake_deceleration
	vehicle.brake_deceleration = SKID_BRAKING


func _on_struck(speed: float) -> void:
	_restore_braking()
	vehicle.held = true
	vehicle.collided.emit(clampf(speed, 2.0, 12.0))
	_held_for = 0.0
	struck.emit()


func _restore_braking() -> void:
	if _usual_braking > 0.0:
		vehicle.brake_deceleration = _usual_braking
		_usual_braking = 0.0


func _update_objective() -> void:
	var title := "RETURN TO THE DEPOT"
	var detail := "Follow the freight loop via " + DIRECTIONS[stage].to_lower() + "."
	if stage == 4:
		detail = "Turn into the depot yard. Stop inside the marked parking bay."
	if fleeing:
		title = "DRIVE."
		detail = ""
	if complete:
		title = "DRIVE COMPLETE"
		detail = "Parked at the depot. Explore the controls or start another drive " + \
			"from the pause menu."
	objective_changed.emit(title, detail)
	var presentation: Node3D = vehicle.get_node("VanPresentation")
	presentation.navigation.destination = TARGETS[stage]
	presentation.navigation.instruction = DIRECTIONS[stage]


func _send_oncoming() -> void:
	_encounter_done = true
	var closing := maxf(absf(vehicle.speed), MIN_CLOSING)
	var gap := maxf(0.0, (MEETING_INDEX - _nearest_index()) * OncomingVan.SPACING)
	var travel := gap / closing * OncomingVan.CRUISE / OncomingVan.SPACING
	var start := clampi(MEETING_INDEX + int(travel), SPAWN_LIMITS.x, SPAWN_LIMITS.y)
	oncoming = OncomingVan.new()
	oncoming.name = "OncomingVan"
	add_child(oncoming)
	oncoming.configure(road, vehicle, start, ONCOMING_END)
	oncoming.passed.connect(func() -> void: _since_passed = 0.0)
	vehicle.get_node("VanPresentation").set("oncoming", oncoming)


func _nearest_index() -> int:
	var points: PackedVector3Array = road.points
	var at := vehicle.global_position
	var best := SEARCH.x
	for index in range(SEARCH.x, SEARCH.y):
		if at.distance_squared_to(points[index]) < at.distance_squared_to(points[best]):
			best = index
	return best


func _clear_oncoming() -> void:
	_encounter_done = false
	_since_passed = -1.0
	_held_for = -1.0
	fleeing = false
	vehicle.held = false
	_restore_braking()
	if is_instance_valid(oncoming):
		oncoming.queue_free()
	if is_instance_valid(pedestrian):
		pedestrian.queue_free()
	oncoming = null
	pedestrian = null


func restart() -> void:
	_clear_oncoming()
	stage = 0
	complete = false
	recovery_pose = START
	vehicle.recover(recovery_pose)
	_save_checkpoint()
	_update_objective()


func recover() -> void:
	if not (is_instance_valid(pedestrian) and pedestrian.hit):
		_clear_oncoming()
	vehicle.recover(recovery_pose)


func _save_checkpoint() -> Error:
	var config := ConfigFile.new()
	config.set_value("drive", "stage", stage)
	var temporary_path := checkpoint_path + ".tmp"
	var result := config.save(temporary_path)
	if result == OK:
		result = DirAccess.rename_absolute(temporary_path, checkpoint_path)
	if result == OK:
		checkpoint_saved.emit()
	else:
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		checkpoint_save_failed.emit(result)
		push_warning("Could not save driving checkpoint: %s" % error_string(result))
	return result


func _load_checkpoint() -> void:
	var config := ConfigFile.new()
	if config.load(checkpoint_path) != OK:
		return
	var value: Variant = config.get_value("drive", "stage", 0)
	if not value is int or value < 0 or value > 4:
		return
	stage = value
	if stage > 0:
		recovery_pose = Transform3D(Basis(Vector3.UP, HEADINGS[stage - 1]),
			TARGETS[stage - 1] + Vector3.UP * 0.1)
