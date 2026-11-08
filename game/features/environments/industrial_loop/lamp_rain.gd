extends Node3D
## Rain in every lamp's light (CHANGE-BRIEF.md §4): a rain volume under each lamp that runs while
## the active camera is within RANGE of it, the MOST_ACTIVE nearest at most. A volume starts
## already falling (its emitter restarts, so its preprocess fills it), stops emitting when the
## camera leaves, and hides once its last drops and their splashes are gone. It reads the camera
## and never writes game state; the rain's look lives in game/effects/lamp_rain_*.tscn.

const POST = preload("res://effects/lamp_rain_post.tscn")
const STREET = preload("res://effects/lamp_rain_street.tscn")
const FLOODLIGHT = preload("res://effects/lamp_rain_floodlight.tscn")
const DOOR = preload("res://effects/lamp_rain_door.tscn")
const RANGE := 65.0
const MOST_ACTIVE := 8
const POST_HEAD := Vector3(-1.9, 6.4, 0.0)
const FLOOD_HEIGHT := 4.0
const DOOR_HEIGHT := 3.0
const DOOR_OUT := 0.8

var volumes: Array[Node3D] = []
var activations: int = 0

var _active: Array[bool] = []
var _drain: Array[float] = []


func add_volume(scene: PackedScene, place: Transform3D) -> Node3D:
	var volume := scene.instantiate() as Node3D
	volume.name = "%s%d" % [volume.name, volumes.size()]
	volume.transform = place
	volume.visible = false
	add_child(volume)
	volumes.append(volume)
	_active.append(false)
	_drain.append(0.0)
	return volume


func is_active(index: int) -> bool:
	return _active[index]


func active_count() -> int:
	return _active.count(true)


func rain(index: int) -> GPUParticles3D:
	return volumes[index].get_node("LampRain") as GPUParticles3D


## How long a stopped volume takes to empty: its last drop's life, then that drop's splash.
func settle_time(index: int) -> float:
	var splash := volumes[index].get_node("LampSplash") as GPUParticles3D
	return rain(index).lifetime + splash.lifetime


func _ready() -> void:
	_update.call_deferred(0.0)


func _physics_process(delta: float) -> void:
	_update(delta)


func _update(delta: float) -> void:
	if not is_inside_tree():
		return
	var wanted: Array[int] = []
	if is_visible_in_tree():
		wanted = _nearest(get_viewport().get_camera_3d())
	for index in range(volumes.size()):
		var volume := volumes[index]
		if wanted.has(index) and not _active[index]:
			volume.visible = true
			rain(index).restart()
			_active[index] = true
			activations += 1
		elif not wanted.has(index) and _active[index]:
			rain(index).emitting = false
			_active[index] = false
			_drain[index] = settle_time(index)
		elif not _active[index] and volume.visible:
			_drain[index] -= delta
			if _drain[index] <= 0.0:
				volume.visible = false


func _nearest(camera: Camera3D) -> Array[int]:
	var found: Array[int] = []
	if camera == null:
		return found
	var distances: Array[float] = []
	for volume in volumes:
		distances.append(camera.global_position.distance_to(volume.global_position))
	for index in range(volumes.size()):
		if distances[index] < RANGE:
			found.append(index)
	found.sort_custom(func(a: int, b: int) -> bool: return distances[a] < distances[b])
	return found.slice(0, MOST_ACTIVE)
