extends Node

const ROOT := "res://features/audio/first_drive/"
const MUSIC_DB := -13.0
const CALL_DUCK := -13.0
const DUCK_SECONDS := 0.6
const BREATH_DB := -11.0
const BREATH_IN := 1.5
const ENGINE_RUN_DOWN := 1.6
const TICKS := 12
const TICK_GAP := Vector2(0.5, 1.8)
const SKID_DB := -6.0
const SKID_FULL := 10.0
const TITLE_RAIN_DB := -7.0
var vehicle: CharacterBody3D
var _engine: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _cabin_rain: AudioStreamPlayer
var _tires: AudioStreamPlayer
var _skid: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _horn: AudioStreamPlayer
var _music: AudioStreamPlayer
var _click: AudioStreamPlayer
var _wiper: AudioStreamPlayer
var _window: AudioStreamPlayer
var _collision: AudioStreamPlayer
var _body_impact: AudioStreamPlayer
var _ring: AudioStreamPlayer
var _call_connect: AudioStreamPlayer
var _call_end: AudioStreamPlayer
var _breathing: AudioStreamPlayer
var _tick: AudioStreamPlayer
var _engine_level: float = 1.0
var _hush: float = 1.0
var _breath: float = 0.0
var _ticks_left: int = 0
var _tick_wait: float = 0.0
var _rng := RandomNumberGenerator.new()


func configure(van: CharacterBody3D) -> void:
	vehicle = van
	_engine = _player("engine", "Vehicle", -15, true)
	_rain = _player("rain", "Ambience", -22, true)
	_cabin_rain = _player("cabin_rain", "Ambience", -5, true)
	_tires = _player("tires", "Vehicle", -60, true)
	_skid = _player("skid", "Vehicle", -60, true)
	_wind = _player("wind", "Ambience", -60, true)
	_horn = _player("horn", "Vehicle", -12, true)
	_horn.stop()
	_music = _player("music", "Music", MUSIC_DB, true)
	_click = _player("indicator_on", "Vehicle", -10)
	_wiper = _player("wiper", "Vehicle", -19)
	_window = _player("window", "Vehicle", -17)
	_collision = _player("collision", "Vehicle", -8)
	_body_impact = _player("impact_body", "Vehicle", -3)
	_ring = _player("phone_ring", "Vehicle", -14, true)
	_ring.stop()
	_call_connect = _player("call_connect", "Vehicle", -12)
	_call_end = _player("call_end", "Vehicle", -12)
	_breathing = _player("breathing", "Vehicle", BREATH_DB, true)
	_breathing.stop()
	_tick = _player("engine_tick", "Vehicle", -18)
	_rng.seed = 7
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


func _process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	var opening: float = vehicle.get_window_openness() if vehicle.occupied else 1.0
	var speed: float = absf(vehicle.speed) / vehicle.maximum_speed
	var hush := linear_to_db(maxf(_hush, 0.0001))
	_engine_level = move_toward(_engine_level, 1.0 if vehicle.engine_on else 0.0,
		delta * ENGINE_RUN_DOWN)
	_engine.pitch_scale = (0.78 + speed * 1.05) * lerpf(0.6, 1.0, _engine_level)
	_engine.volume_db = -18.0 + speed * 5.0 + opening * 3.0 \
		+ linear_to_db(maxf(_engine_level, 0.0001)) + hush
	_rain.volume_db = lerpf(-24.0, -7.0, opening) + hush
	_cabin_rain.volume_db = lerpf(-6.0, -28.0, opening) + hush
	_tires.volume_db = linear_to_db(maxf(0.0001, speed * 0.45)) + hush
	_skid.volume_db = (SKID_DB + linear_to_db(clampf(absf(vehicle.speed) / SKID_FULL, 0.05, 1.0))
		if skidding() else -60.0) + hush
	_wind.volume_db = linear_to_db(maxf(0.0001, speed * lerpf(0.03, 0.4, opening))) + hush
	if _breathing.playing:
		_breath = move_toward(_breath, 1.0, delta / BREATH_IN)
		_breathing.volume_db = BREATH_DB + linear_to_db(maxf(_breath * _hush, 0.0001))
	if _ticks_left > 0:
		_tick_wait -= delta
		if _tick_wait <= 0.0:
			_ticks_left -= 1
			_tick_wait = _rng.randf_range(TICK_GAP.x, TICK_GAP.y)
			_tick.pitch_scale = _rng.randf_range(0.9, 1.15)
			_tick.volume_db = _rng.randf_range(-24.0, -17.0) + hush
			_tick.play()
	if vehicle.horn_on and not _horn.playing:
		_horn.play()
	elif not vehicle.horn_on and _horn.playing:
		_horn.stop()


func skidding() -> bool:
	return vehicle.locked and vehicle.braking and absf(vehicle.speed) > 1.0


func body_impact() -> void:
	_body_impact.play()


func silence_music() -> void:
	_music.stop()


func ring() -> void:
	_ring.play()


func stop_ringing() -> void:
	_ring.stop()


func answer() -> void:
	_ring.stop()
	_call_connect.play()
	_duck(CALL_DUCK)


func hang_up() -> void:
	if _ring.playing:
		_ring.stop()
	else:
		_call_end.play()
	_duck(0.0)


func calling() -> bool:
	return _ring.playing


func music_level() -> float:
	return _music.volume_db - MUSIC_DB


func breathe() -> void:
	_breath = 0.0
	_breathing.volume_db = -80.0
	_breathing.play()


func breathing() -> bool:
	return _breathing.playing


func cool_down() -> void:
	_ticks_left = TICKS
	_tick_wait = 1.2


func fade_out(seconds: float) -> void:
	create_tween().tween_property(self, "_hush", 0.0, seconds)


func restore() -> void:
	_hush = 1.0
	_breathing.stop()
	_ticks_left = 0
	_music.volume_db = MUSIC_DB


func _duck(by: float) -> void:
	create_tween().tween_property(_music, "volume_db", MUSIC_DB + by, DUCK_SECONDS)


func play_music() -> void:
	if not _music.playing:
		_music.play()


func title_ambience(value: bool) -> void:
	var mode := Node.PROCESS_MODE_ALWAYS if value else Node.PROCESS_MODE_INHERIT
	_rain.process_mode = mode
	_music.process_mode = mode
	if value:
		_rain.volume_db = TITLE_RAIN_DB
		play_music()


func _indicator(high: bool) -> void:
	_click.stream = load(ROOT + ("indicator_on.wav" if high else "indicator_off.wav"))
	_click.play()


func _impact(strength: float) -> void:
	_collision.volume_db = clampf(-17.0 + strength, -17.0, -3.0)
	_collision.play()
