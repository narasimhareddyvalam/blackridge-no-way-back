extends "res://previews/preview_fixture.gd"
## B1's frame strip (CHANGE-BRIEF.md §4): one lamp's rain, seen from where a person would stand: the
## valley-road lamp at (−15, 63.8), the site office's door hood, or its floodlight. In the game the
## condition is the camera's distance, and a camera that leaves to end it can no longer see the rain
## drain, so this preview gives the condition itself. The game's lamp-rain controller is hidden,
## which stops all of its volumes, and the preview runs its own copy of the chosen lamp's volume,
## from the same scene at the same place. It starts it as the controller does, shown and restarted
## so its preprocess fills it, on frame 10; stops emitting on frame 70; and hides it once its last
## drops and splashes are gone. Fixed seeds on this copy only. Capture with --quit-after 120.

const VALLEY_LAMP := Vector2(-15.0, 63.8)
const START_FRAME := 10
const STOP_FRAME := 70
const FRAME_SECONDS := 1.0 / 30.0
## Each view from the volume's centre, in world axes: the eye at a standing height, what it looks
## at, and the vertical field of view in degrees.
const VIEWS := {
	"post": [Vector3(15.0, -4.7, 3.6), Vector3(0.0, -3.6, 0.3), 40.0],
	"door": [Vector3(1.9, -1.23, 6.4), Vector3(0.0, -1.0, -0.6), 45.0],
	"floodlight": [Vector3(-5.4, -2.33, 7.0), Vector3(1.6, -2.8, 1.0), 50.0],
}
const SCENES := {
	"post": "lamp_rain_street.tscn",
	"door": "lamp_rain_door.tscn",
	"floodlight": "lamp_rain_floodlight.tscn",
}

@export_enum("post", "door", "floodlight") var place: String = "post"

var _volume: Node3D
var _rain: GPUParticles3D
var _splash: GPUParticles3D
var _hide_frame: int = -1


func set_up() -> void:
	if not SCENES.has(place):
		push_error("Unknown place %s: use post, door or floodlight" % place)
		return
	var controller: Node3D = world.get("lamp_rain")
	controller.visible = false
	var source := _source(controller.volumes)
	_volume = (load(source.scene_file_path) as PackedScene).instantiate() as Node3D
	_volume.visible = false
	add_child(_volume)
	_volume.global_transform = source.global_transform
	_rain = _volume.get_node("LampRain")
	_splash = _volume.get_node("LampSplash")
	fix_seeds([_rain, _splash], 6)
	var view: Array = VIEWS[place]
	look(source.global_position + view[0], source.global_position + view[1], view[2])


func on_frame(number: int) -> void:
	if _volume == null:
		return
	if number == 0:
		report("B1 at the %s lamp (%s), condition from frame %d to frame %d" % [place,
			_volume.global_position, START_FRAME, STOP_FRAME])
	if number == START_FRAME:
		_volume.visible = true
		_rain.restart()
		report("condition starts: shown, and restarted so its preprocess fills it")
	elif number == STOP_FRAME:
		_rain.emitting = false
		var seconds := _rain.lifetime + _splash.lifetime
		_hide_frame = STOP_FRAME + ceili(seconds / FRAME_SECONDS)
		report("condition ends: no new drops; hidden on frame %d, %.2f s on" % [_hide_frame,
			seconds])
	elif number == _hide_frame:
		_volume.visible = false
		report("emptied and hidden")


func _source(volumes: Array[Node3D]) -> Node3D:
	var found: Node3D
	for volume in volumes:
		if not volume.scene_file_path.ends_with(SCENES[place]):
			continue
		var at := Vector2(volume.global_position.x, volume.global_position.z)
		if found == null or at.distance_to(VALLEY_LAMP) < Vector2(found.global_position.x,
				found.global_position.z).distance_to(VALLEY_LAMP):
			found = volume
	return found
