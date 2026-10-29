extends Node

const ROOT := "res://features/audio/first_drive/"
var vehicle: CharacterBody3D
var _engine: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _cabin_rain: AudioStreamPlayer
var _tires: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _horn: AudioStreamPlayer
var _music: AudioStreamPlayer
var _click: AudioStreamPlayer
var _wiper: AudioStreamPlayer
var _window: AudioStreamPlayer
var _collision: AudioStreamPlayer


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_engine = _player("engine", "Vehicle", -15, true)
	_rain = _player("rain", "Ambience", -22, true)
	_cabin_rain = _player("cabin_rain", "Ambience", -5, true)
	_tires = _player("tires", "Vehicle", -60, true)
	_wind = _player("wind", "Ambience", -60, true)
	_horn = _player("horn", "Vehicle", -12, true)
	_horn.stop()
	_music = _player("music", "Music", -13, true)
	_click = _player("indicator_on", "Vehicle", -10)
	_wiper = _player("wiper", "Vehicle", -19)
	_window = _player("window", "Vehicle", -17)
	_collision = _player("collision", "Vehicle", -8)
	vehicle.indicator_clicked.connect(_indicator)
	vehicle.switch_operated.connect(func() -> void: _click.play())
	vehicle.wiper_swept.connect(func() -> void: _wiper.play())
	vehicle.window_operated.connect(func() -> void: _window.play())
	vehicle.collided.connect(_impact)


func _player(
	file: String, bus: String, volume: float, looping: bool = false
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := load(ROOT + file + ".wav") as AudioStreamWAV
	if looping:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.bus = bus
	player.volume_db = volume
	add_child(player)
	if looping:
		player.play()
	return player


func _process(_delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	var opening: float = vehicle.get_window_openness() if vehicle.occupied else 1.0
	var speed: float = absf(vehicle.speed) / vehicle.maximum_speed
	_engine.pitch_scale = 0.78 + speed * 1.05
	_engine.volume_db = -18.0 + speed * 5.0 + opening * 3.0
	_rain.volume_db = lerpf(-24.0, -7.0, opening)
	_cabin_rain.volume_db = lerpf(-6.0, -28.0, opening)
	_tires.volume_db = linear_to_db(maxf(0.0001, speed * 0.45))
	_wind.volume_db = linear_to_db(maxf(0.0001, speed * lerpf(0.03, 0.4, opening)))
	if vehicle.horn_on and not _horn.playing:
		_horn.play()
	elif not vehicle.horn_on and _horn.playing:
		_horn.stop()


func _indicator(high: bool) -> void:
	_click.stream = load(ROOT + ("indicator_on.wav" if high else "indicator_off.wav"))
	_click.play()


func _impact(strength: float) -> void:
	_collision.volume_db = clampf(-17.0 + strength, -17.0, -3.0)
	_collision.play()
