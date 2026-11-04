extends Node

signal objective_changed(title: String, detail: String)
signal checkpoint_saved
signal checkpoint_save_failed(error: int)
signal drive_completed
signal struck(speed: float)

const SaveFile = preload("res://shared/save/save_file.gd")
const MISSION := "night_freight"
const NAME := "Night Freight"
const TITLE_EYE := Vector3(3.2, 1.0, -9.5)
const TITLE_LOOK := Vector3(1.3, 1.3, 0.7)
const TITLE_FOV := 32.0
const PROGRESS_VERSION := 1
const AFTER_HIT: Array[String] = ["recovery", "body", "crack"]
const TARGETS: Array[Vector3] = [Vector3(482.24, 25.4, -24.37), Vector3(458.48, 43.6, -114.17),
	Vector3(164.28, 64.42, -206.81), Vector3(-20.05, 24.98, -50.67), Vector3(-28, 0, 93)]
const HEADINGS: Array[float] = [0.2508, 0.2966, 1.5538, -2.6609, PI]
const DIRECTIONS: Array[String] = ["THE SWITCHBACKS", "THE VIEWPOINT", "THE PASS",
	"THE DESCENT", "PARK AT THE DEPOT"]
const START := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(568.0, -0.02, 123.5))
const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const ENCOUNTER_STAGE := 3
const ENCOUNTER_SPAN := Vector2i(680, 730)
const ENCOUNTER_SPEED := 1.0
const ENCOUNTER_ALIGN := 0.5
const MEETING_BEFORE := 15
const SPAWN_AT := 815
const SEARCH := Vector2i(680, 900)
const ONCOMING_END := 690
const ETA_FLOOR := 6.0
const Pedestrian = preload("res://features/characters/pedestrian/pedestrian.gd")
const PhoneCall = preload("phone_call.gd")
const CALL_AT := 91
const CALL_SEARCH := Vector2i(0, 300)
const RUN_SHEET := "BLACKRIDGE FREIGHT DEPOT\nRUN SHEET - NIGHT\n\n" \
	+ "Driver ......... E. COLE\nVan ............ BR 048\n" \
	+ "Pick-up ........ Lumber yard, Hill Road\nLoad ........... 14 pallets, sawn timber\n" \
	+ "Deliver to ..... Freight depot, bay 2\nRoute .......... Over the pass\n" \
	+ "                 (valley road closed)\n\nSigned ........."
const RUN_SHEET_SIGNATURE := "E. Cole"
const MAYA_CALL: Array = [
	["MAYA", "Hey. Still working?"],
	["ETHAN", "Last run of the night. Almost done."],
	["MAYA", "You always say that."],
	["ETHAN", "You eating okay?"],
	["MAYA", "Ethan."],
	["ETHAN", "That's not an answer."],
	["MAYA", "I'm fine. Work's just busy."],
	["ETHAN", "Come by Sunday. I'll cook."],
	["MAYA", "Maybe. I'll let you know."],
	["ETHAN", "Lock your door tonight."],
	["MAYA", "I'm twenty-five."],
	["ETHAN", "Lock it anyway."],
	["MAYA", "Drive safe, okay?"],
]
const MIN_STEP_SPEED := 4.5
const WATCH_SAMPLES := 20
const BUMPER_AHEAD := 2.52
const IMPACT_RIGHT := 0.4
const HOLD_SECONDS := 4.0
const LOCK_PAST := 5
const STEP_HORIZON := 1.9
const LOCK_LOOK := 6
const REACTION := 0.5

var vehicle: CharacterBody3D
var road: RefCounted
var crossing: Node3D
var oncoming: Node3D
var pedestrian: Node3D
var fleeing: bool = false
var checkpoint_path: String = ""
var playable_area := Rect2()
var progress_read: SaveFile.Read = SaveFile.Read.OFF
var stage: int = 0
var complete: bool = false
var recovery_pose := START
var _timer: float = 0.0
var phone_call := PhoneCall.new()
var _encounter_done: bool = false
var _called: bool = false
var _held_for: float = -1.0
var _coast_for: float = -1.0
var _lock_lane: float = 0.0
var _progress: SaveFile


func _ready() -> void:
	phone_call.name = "PhoneCall"
	add_child(phone_call)


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_load_checkpoint()
	vehicle.recover(recovery_pose)
	vehicle.foot_on_brake = fleeing
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
	if stage == 0 and not _called and vehicle.engine_on and road != null \
			and _nearest_index(vehicle.global_position, CALL_SEARCH) >= CALL_AT:
		_called = true
		phone_call.start("MAYA", MAYA_CALL)
	if stage == ENCOUNTER_STAGE and not _encounter_done and road != null and crossing != null \
			and not phone_call.active and _entering_encounter():
		_send_oncoming()
	if at.distance_to(Vector2(target.x, target.z)) > (5.0 if stage == 4 else 13.0):
		return
	if stage == 4:
		if absf(vehicle.speed) < 0.3:
			complete = true
			_update_objective()
			drive_completed.emit()
			_save_finished()
		return
	recovery_pose = Transform3D(Basis(Vector3.UP, HEADINGS[stage]), target + Vector3.UP * 0.1)
	stage += 1
	_save_checkpoint()
	_update_objective()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	if _coast_for >= 0.0:
		_coast(delta)
	if is_instance_valid(oncoming):
		_time_the_meeting()
	if is_instance_valid(pedestrian) and pedestrian.waiting and vehicle.occupied:
		_watch_crossing()
	if vehicle.locked:
		_watch_lock()
	if _held_for >= 0.0 and absf(vehicle.speed) < 0.05:
		_held_for += delta
		if _held_for >= HOLD_SECONDS:
			_held_for = -1.0
			vehicle.held = false
			vehicle.foot_on_brake = true
			fleeing = true
			recovery_pose = Transform3D(Basis(Vector3.UP, vehicle.global_rotation.y),
				vehicle.global_position + Vector3.UP * 0.1)
			_save_checkpoint(false)
			_update_objective()


func _entering_encounter() -> bool:
	var here := _nearest_index(vehicle.global_position)
	if here < ENCOUNTER_SPAN.x or here > ENCOUNTER_SPAN.y or vehicle.speed < ENCOUNTER_SPEED:
		return false
	var along := Basis(Vector3.UP, road.heading_at(here))
	var forward := Vector3(-vehicle.global_basis.z.x, 0.0, -vehicle.global_basis.z.z).normalized()
	var lateral: float = (vehicle.global_position - road.points[here]).dot(along.x)
	if forward.dot(-along.z) <= ENCOUNTER_ALIGN or absf(lateral) >= road.half_widths[here]:
		return false
	var meeting: int = crossing.index - MEETING_BEFORE
	var arrival := (meeting - here) * OncomingVan.SPACING / maxf(absf(vehicle.speed), ETA_FLOOR)
	return arrival <= (SPAWN_AT - meeting) * OncomingVan.SPACING / OncomingVan.CRUISE \
		or here >= ENCOUNTER_SPAN.y - 2


func _time_the_meeting() -> void:
	var meeting: int = crossing.index - MEETING_BEFORE
	var here := _nearest_index(vehicle.global_position)
	if here >= meeting or float(oncoming.distance) < meeting * OncomingVan.SPACING:
		oncoming.meet(-INF, 0.0)
		return
	oncoming.meet(meeting * OncomingVan.SPACING, (meeting - here) * OncomingVan.SPACING
		/ maxf(absf(vehicle.speed), ETA_FLOOR))


func _watch_lock() -> void:
	var here := _nearest_index(vehicle.global_position)
	if absf(vehicle.speed) < 0.2 or here > crossing.index + LOCK_PAST:
		vehicle.locked = false
		return
	var ahead := mini(here + LOCK_LOOK, road.points.size() - 1)
	var along := Basis(Vector3.UP, road.heading_at(ahead))
	var target: Vector3 = road.points[ahead] + along.x * _lock_lane - vehicle.global_position
	var local := vehicle.global_basis.inverse() * Vector3(target.x, 0.0, target.z)
	vehicle.lock_curvature = -2.0 * local.x / maxf(local.length_squared(), 1.0)


func _release_van() -> void:
	vehicle.scripted = false
	vehicle.locked = false
	vehicle.scripted_throttle = 0.0
	vehicle.scripted_brake = 0.0
	vehicle.scripted_steer = 0.0


func _coast(delta: float) -> void:
	_coast_for += delta
	if _coast_for >= REACTION:
		_coast_for = -1.0
		_release_van()
		vehicle.held = true
		_held_for = 0.0


func _watch_crossing() -> void:
	var speed: float = vehicle.speed
	if speed < MIN_STEP_SPEED:
		return
	var here := _nearest_index(vehicle.global_position)
	if here > crossing.index or crossing.index - here > WATCH_SAMPLES:
		return
	if is_instance_valid(oncoming) and float(oncoming.distance) > here * OncomingVan.SPACING:
		return
	var forward := Vector3(-vehicle.global_basis.z.x, 0.0, -vehicle.global_basis.z.z).normalized()
	if forward.dot(crossing.forward) < 0.7:
		return
	var front := vehicle.global_position + forward * BUMPER_AHEAD
	var gap: float = (crossing.centre - front).dot(crossing.forward)
	if gap <= 0.0:
		return
	if gap / speed > STEP_HORIZON:
		return
	var along := Basis(Vector3.UP, road.heading_at(here))
	var across := clampf((vehicle.global_position - road.points[here]).dot(along.x),
		-crossing.half_width, crossing.half_width)
	var impact: Vector3 = crossing.centre + crossing.right * (across + IMPACT_RIGHT)
	var walk: float = Vector2(crossing.kerb.x - impact.x, crossing.kerb.z - impact.z).length() \
		/ Pedestrian.WALK_SPEED + Pedestrian.FREEZE_SECONDS
	if gap / speed > walk:
		return
	pedestrian.step_out(crossing.kerb, impact, vehicle)
	_lock_lane = across
	vehicle.locked = true


func _spawn_pedestrian() -> void:
	pedestrian = Pedestrian.new()
	pedestrian.name = "Pedestrian"
	add_child(pedestrian)
	pedestrian.wait_at(crossing.kerb, -crossing.right)
	pedestrian.struck.connect(_on_struck)


func _on_struck(speed: float) -> void:
	vehicle.locked = false
	vehicle.scripted = true
	vehicle.scripted_throttle = 0.0
	vehicle.scripted_brake = 0.0
	vehicle.scripted_steer = 0.0
	_coast_for = 0.0
	struck.emit(speed)


func _update_objective() -> void:
	var title := "RETURN TO THE DEPOT"
	var detail := "Freight depot, bay 2. Next: " + DIRECTIONS[stage].to_lower() + "."
	if stage == 4:
		detail = "Turn into the depot yard. Stop inside the marked parking bay."
	if fleeing:
		title = "DRIVE."
		detail = ""
	if complete:
		title = ""
		detail = ""
	objective_changed.emit(title, detail)


func _send_oncoming() -> void:
	_encounter_done = true
	oncoming = OncomingVan.new()
	oncoming.name = "OncomingVan"
	add_child(oncoming)
	oncoming.configure(road, vehicle, SPAWN_AT, ONCOMING_END)
	vehicle.get_node("VanPresentation").set("oncoming", oncoming)
	_spawn_pedestrian()


func _nearest_index(at: Vector3, span: Vector2i = SEARCH) -> int:
	var points: PackedVector3Array = road.points
	var best := span.x
	for index in range(span.x, span.y):
		if at.distance_squared_to(points[index]) < at.distance_squared_to(points[best]):
			best = index
	return best


func _clear_oncoming() -> void:
	_encounter_done = false
	_held_for = -1.0
	_coast_for = -1.0
	fleeing = false
	vehicle.held = false
	_release_van()
	if is_instance_valid(oncoming):
		oncoming.queue_free()
	if is_instance_valid(pedestrian):
		pedestrian.queue_free()
	oncoming = null
	pedestrian = null


func restart() -> void:
	_clear_oncoming()
	_called = false
	phone_call.stop()
	stage = 0
	complete = false
	recovery_pose = START
	vehicle.recover(recovery_pose)
	vehicle.reset_clock()
	_save_checkpoint()
	_update_objective()


func reload() -> void:
	_clear_oncoming()
	_called = false
	phone_call.stop()
	stage = 0
	complete = false
	recovery_pose = START
	vehicle.reset_clock()
	vehicle.get_node("VanPresentation").clear_crack()
	_load_checkpoint()
	vehicle.recover(recovery_pose)
	vehicle.foot_on_brake = fleeing
	_update_objective()


func recover() -> void:
	if not (is_instance_valid(pedestrian) and pedestrian.hit):
		_clear_oncoming()
	vehicle.recover(recovery_pose)
	vehicle.foot_on_brake = fleeing


func _save_checkpoint(announce: bool = true) -> Error:
	var config := _progress_at(stage)
	if fleeing and is_instance_valid(pedestrian):
		config.set_value("drive", "recovery", recovery_pose)
		config.set_value("drive", "body", pedestrian.lying_pose())
		config.set_value("drive", "crack", vehicle.get_node("VanPresentation").crack_state())
	return _write_progress(config, announce)


func _save_finished() -> void:
	_write_progress(_progress_at(0), false)


func _progress_at(at_stage: int) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("save", "mission", MISSION)
	config.set_value("drive", "stage", at_stage)
	return config


func _write_progress(config: ConfigFile, announce: bool) -> Error:
	if checkpoint_path.is_empty():
		return ERR_UNAVAILABLE
	if _progress == null or _progress.path != checkpoint_path:
		_progress = SaveFile.new(checkpoint_path, PROGRESS_VERSION)
	var result := _progress.write(config)
	if result == OK:
		if announce:
			checkpoint_saved.emit()
	else:
		checkpoint_save_failed.emit(result)
	return result


func _load_checkpoint() -> void:
	_progress = SaveFile.new(checkpoint_path, PROGRESS_VERSION)
	var config := _progress.read(_valid_progress)
	progress_read = _progress.status
	if config == null:
		return
	stage = config.get_value("drive", "stage")
	if stage > 0:
		recovery_pose = Transform3D(Basis(Vector3.UP, HEADINGS[stage - 1]),
			TARGETS[stage - 1] + Vector3.UP * 0.1)
	if not config.has_section_key("drive", "body") or crossing == null:
		return
	_encounter_done = true
	fleeing = true
	recovery_pose = config.get_value("drive", "recovery")
	_spawn_pedestrian()
	pedestrian.lie_as(config.get_value("drive", "body"))
	vehicle.get_node("VanPresentation").restore_crack(config.get_value("drive", "crack"))


func _valid_progress(config: ConfigFile) -> bool:
	var value: Variant = config.get_value("drive", "stage", -1)
	if config.get_value("save", "mission", "") != MISSION or not value is int or value < 0 \
			or value >= TARGETS.size():
		return false
	var found := AFTER_HIT.filter(func(key: String) -> bool:
		return config.has_section_key("drive", key))
	if found.is_empty():
		return true
	return found.size() == AFTER_HIT.size() and value >= ENCOUNTER_STAGE \
		and _placed(config.get_value("drive", "recovery")) \
		and _lying(config.get_value("drive", "body")) \
		and _cracked(config.get_value("drive", "crack"))


func _placed(value: Variant) -> bool:
	if not value is Transform3D:
		return false
	var place: Transform3D = value
	return place.is_finite() and absf(place.basis.determinant() - 1.0) < 0.01 \
		and playable_area.has_point(Vector2(place.origin.x, place.origin.z))


func _lying(value: Variant) -> bool:
	return value is Array and (value as Array).size() == Pedestrian.BONES.size() \
		and (value as Array).all(_placed)


func _cracked(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var amount: Variant = (value as Dictionary).get("amount")
	var point: Variant = (value as Dictionary).get("point")
	var seed: Variant = (value as Dictionary).get("seed")
	return (amount is float or amount is int) and amount >= 0.0 and amount <= 1.0 \
		and point is Vector2 and (point as Vector2).is_finite() \
		and (seed is float or seed is int) and is_finite(float(seed))
