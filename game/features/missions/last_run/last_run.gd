extends Node
## Mission 3, Last Run (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360): the dispatcher's "last run"
## to the waterfront, its ambush, the truth about Maya, the convoy, the airfield and home. Its
## checkpoints are saved in the progress file's version 2 as `[run] stage`. Step 1 (missions in a
## row): its start at the freight depot, where Mission 2 began; each later step adds its places.
## The app drives it as it drives Mission 2, through the same small set of calls.

signal objective_changed(title: String, detail: String)
signal checkpoint_reached(config: ConfigFile)

const MISSION := "last_run"
const NAME := "Last Run"
const PLACES: Array[String] = ["The freight depot", "Away from the waterfront", "The viewpoint",
	"The airfield gate"]
const NEXT: Array[String] = ["The waterfront", "The viewpoint", "The airfield", "Home"]
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
## Its opening still to play: set only in the save Mission 2's end leaves.
var opening_pending := false

var _shown := ""


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
	recovery_pose = START
	opening_pending = stage == 0 and bool(config.get_value("run", "opening", false))
	vehicle.recover(recovery_pose)
	vehicle.call("unload")
	(vehicle.get_node("VanPresentation") as Node).call("set_paint", Color.WHITE)
	_shown = ""
	_update_objective()


func recover() -> void:
	vehicle.recover(recovery_pose)


func place_reached() -> String:
	return PLACES[stage]


func place_next() -> String:
	return NEXT[stage]


## Where the objective sends him, for its marker and the map's pin; Vector3.INF for none.
func objective_target() -> Vector3:
	return Vector3.INF


## Whether E does something from the driver's seat here, what, and doing it.
func wants_interact() -> bool:
	return false


func interact_label() -> String:
	return ""


func interact() -> String:
	return ""


## What Ethan on foot at `at` can do with E, or "", and doing it.
func foot_action(_at: Vector3) -> String:
	return ""


func do_foot_action(_at: Vector3) -> String:
	return ""


func _physics_process(_delta: float) -> void:
	if active:
		_update_objective()


func _update_objective() -> void:
	var title := "DRIVE TO THE WATERFRONT"
	var detail := "The dispatcher's last run: east to the end of the valley road, then on to the " \
		+ "harbour."
	if title + detail != _shown:
		_shown = title + detail
		objective_changed.emit(title, detail)
