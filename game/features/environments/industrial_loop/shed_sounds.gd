extends Node3D
## The transfer shed's own sounds (part G of step 5 of #253, #302), synthesized by
## `source_assets/audio/shed/synthesize.py`, each from where it comes, on the Ambience bus:
## - heavy rain drumming on the steel roof, from four places under it, which inside the shed
##   stands in for the yard's rain (`shelter()`, read by the first drive's audio);
## - each gas unit heater (`shed_fitout.gd`) running on its thermostat: on for ON_SECONDS, off
##   for OFF_SECONDS, each a third of the way through its round from the last, lighting with a
##   tick and a thump;
## - the two big fans' slow swish;
## - a small radio on the dock desk, playing low.

const AUDIO := "res://features/audio/shed/"
## The shed's inside (`transfer_building.gd`) and how far in from an open door its shelter grows
## to the whole.
const INSIDE := Rect2(-89.75, -9.75, 49.5, 29.5)
const EAVES := 9.0
const OPEN_DOORS: Array[Vector2] = [Vector2(-64.0, 19.75), Vector2(-47.75, 19.75)]
const DOOR_FADE := 4.0
const ROOF_RAIN: Array[Vector3] = [Vector3(-80.0, 7.5, 0.0), Vector3(-80.0, 7.5, 14.0),
	Vector3(-55.0, 7.5, 0.0), Vector3(-55.0, 7.5, 14.0)]
const ROOF_DB := -8.0
const HEATER_DB := -14.0
const START_DB := -12.0
const FAN_DB := -20.0
const RADIO_DB := -16.0
const ON_SECONDS := 240.0
const OFF_SECONDS := 150.0
## The radio on the dock desk (`dock_station.gd`): a small portable radio by the seal log.
const RADIO := Vector3(-45.2, 1.3 + 0.788, 17.9)
const RADIO_SIZE := Vector3(0.26, 0.15, 0.08)

var _heaters: Array[AudioStreamPlayer3D] = []
var _starts: Array[AudioStreamPlayer3D] = []
var _clock := 0.0


## Builds the sounds at `heaters` and `fans` (their world places).
func build(heaters: Array, fans: Array) -> void:
	var index := 0
	for at: Vector3 in ROOF_RAIN:
		index += 1
		var rain := _player("RoofRain%d" % index, "roof_rain", ROOF_DB, at, 20.0)
		rain.play(float(index) * 1.3)
	for heater: Transform3D in heaters:
		_heaters.append(_player("Heater%d" % (_heaters.size() + 1), "heater_run", HEATER_DB,
			heater.origin, 5.0))
		_starts.append(_player("HeaterStart%d" % _starts.size(), "heater_start", START_DB,
			heater.origin, 5.0))
	for fan: Transform3D in fans:
		_player("Fan%d" % (get_child_count() + 1), "fan_whoosh", FAN_DB, fan.origin, 6.0).play()
	_radio()
	_thermostats(true)


## How sheltered `at` is from the rain: 1 under the roof, inside its walls, fading to 0 at an
## open dock door and outside.
static func shelter(at: Vector3) -> float:
	if not INSIDE.has_point(Vector2(at.x, at.z)) or at.y > EAVES:
		return 0.0
	var share := 1.0
	for door in OPEN_DOORS:
		share = minf(share, clampf(Vector2(at.x, at.z).distance_to(door) / DOOR_FADE, 0.0, 1.0))
	return share


## Whether heater `index` is running at `time` seconds into the night.
static func heater_running(index: int, time: float) -> bool:
	var round_length := ON_SECONDS + OFF_SECONDS
	return fmod(time + index * round_length / 3.0, round_length) < ON_SECONDS


func heaters_running() -> Array[bool]:
	var running: Array[bool] = []
	for heater in _heaters:
		running.append(heater.playing)
	return running


func _process(delta: float) -> void:
	_clock += delta
	_thermostats(false)


func _thermostats(first: bool) -> void:
	for index in range(_heaters.size()):
		var running := heater_running(index, _clock)
		if running and not _heaters[index].playing:
			_heaters[index].play()
			if not first:
				_starts[index].play()
		elif not running and _heaters[index].playing:
			_heaters[index].stop()


func _radio() -> void:
	var casing := StandardMaterial3D.new()
	casing.albedo_color = Color(0.16, 0.17, 0.18)
	casing.roughness = 0.55
	var radio := MeshInstance3D.new()
	radio.name = "DeskRadio"
	var box := BoxMesh.new()
	box.size = RADIO_SIZE
	radio.mesh = box
	radio.material_override = casing
	add_child(radio)
	radio.global_transform = Transform3D(Basis(Vector3.UP, -PI / 2.0), RADIO
		+ Vector3.UP * RADIO_SIZE.y / 2.0)
	var grille := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(RADIO_SIZE.x * 0.5, RADIO_SIZE.y * 0.7, 0.004)
	grille.mesh = face
	var mesh_paint := StandardMaterial3D.new()
	mesh_paint.albedo_color = Color(0.07, 0.07, 0.07)
	mesh_paint.roughness = 0.9
	grille.material_override = mesh_paint
	radio.add_child(grille)
	grille.position = Vector3(-RADIO_SIZE.x * 0.2, 0.0, RADIO_SIZE.z / 2.0 + 0.002)
	var aerial := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.003
	rod.bottom_radius = 0.003
	rod.height = 0.3
	aerial.mesh = rod
	aerial.material_override = casing
	radio.add_child(aerial)
	aerial.position = Vector3(RADIO_SIZE.x * 0.4, RADIO_SIZE.y / 2.0 + 0.15, 0.0)
	aerial.rotation.z = 0.35
	_player("Radio", "radio", RADIO_DB, radio.global_position, 2.0).play()


func _player(label: String, file: String, volume: float, at: Vector3, unit: float) \
		-> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = label
	player.stream = load(AUDIO + file + ".wav") as AudioStream
	player.volume_db = volume
	player.bus = "Ambience"
	player.unit_size = unit
	add_child(player)
	player.global_position = at
	return player
