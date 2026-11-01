extends Node

signal objective_changed(title: String, detail: String)
signal checkpoint_saved
signal checkpoint_save_failed(error: int)
signal drive_completed

const SAVE_PATH := "user://driving_prototype.cfg"
const TARGETS: Array[Vector3] = [Vector3(482.24, 25.4, -24.37), Vector3(458.48, 43.6, -114.17),
	Vector3(164.28, 64.42, -206.81), Vector3(-20.05, 24.98, -50.67), Vector3(-28, 0, 93)]
const HEADINGS: Array[float] = [0.2508, 0.2966, 1.5538, -2.6609, PI]
const DIRECTIONS: Array[String] = ["THE SWITCHBACKS", "THE VIEWPOINT", "THE PASS",
	"THE DESCENT", "PARK AT THE DEPOT"]
const START := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(560, 0.1, 130))

var vehicle: CharacterBody3D
var checkpoint_path: String = SAVE_PATH
var stage: int = 0
var complete: bool = false
var recovery_pose := START
var _timer: float = 0.0


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


func _update_objective() -> void:
	var title := "RETURN TO THE DEPOT"
	var detail := "Follow the freight loop via " + DIRECTIONS[stage].to_lower() + "."
	if stage == 4:
		detail = "Turn into the depot yard. Stop inside the marked parking bay."
	if complete:
		title = "DRIVE COMPLETE"
		detail = "Parked at the depot. Explore the controls or start another drive " + \
			"from the pause menu."
	objective_changed.emit(title, detail)
	var presentation: Node3D = vehicle.get_node("VanPresentation")
	presentation.navigation.destination = TARGETS[stage]
	presentation.navigation.instruction = DIRECTIONS[stage]


func restart() -> void:
	stage = 0
	complete = false
	recovery_pose = START
	vehicle.recover(recovery_pose)
	_save_checkpoint()
	_update_objective()


func recover() -> void:
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
