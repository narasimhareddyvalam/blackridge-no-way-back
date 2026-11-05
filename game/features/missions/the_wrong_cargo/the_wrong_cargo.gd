extends Node

signal objective_changed(title: String, detail: String)

const MISSION := "the_wrong_cargo"
const NAME := "The Wrong Cargo"
const PLACES: Array[String] = ["The freight depot", "The transfer shed", "The container yard",
	"The warehouse compound"]
const NEXT: Array[String] = ["The transfer shed", "The container yard", "The warehouse compound",
	"The hill road"]
const START := Transform3D(Basis(Vector3.UP, PI), Vector3(-28.0, 0.1, 93.0))
const TITLE_EYE := Vector3(3.2, 1.0, -9.5)
const TITLE_LOOK := Vector3(1.3, 1.3, 0.7)
const TITLE_FOV := 32.0

var vehicle: CharacterBody3D
var stage: int = 0
var recovery_pose := START
var fleeing: bool = false


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
	recovery_pose = START
	vehicle.recover(recovery_pose)
	_update_objective()


func recover() -> void:
	vehicle.recover(recovery_pose)


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


func _update_objective() -> void:
	objective_changed.emit("MISSION 2 IS BEING BUILT", "Next: %s." % NEXT[stage].to_lower())
