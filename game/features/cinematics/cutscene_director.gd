extends Node
## Plays a cutscene (#357; GAME_DESIGN §10-11's CutsceneDirector: camera hand-offs, skip, and play
## given back as it was): its own camera moves through the shots, each eased from its `from` to
## its `to` (through `via` when it has one) over its `seconds`, its field of view between `fov`'s
## two; in the film look (`film_look.gd`) with each shot's card or caption; a shot's `lights` lit
## while it plays (a cutscene's key and rim lights) and `black` hiding the world behind a card.
## A shot whose `to` is "player" ends on the player's own camera, read each frame, so the hand-off
## has no cut. While it plays the HUD is hidden and Ethan's keys held; E, Enter or Space skips it.
## When it ends, played through or skipped, the player's camera, the HUD and his keys come back.

signal finished(skipped: bool)

const FilmLook = preload("film_look.gd")
const SKIP_AFTER := 1.0
## Each cut dips through black: the last DIP of a shot fades to black and the first DIP of the
## next fades up from it, so a change of place, lens or grade is never a jump.
const DIP := 0.45

var playing := false
var film: CanvasLayer
var camera: Camera3D
var shot := -1
var last_view := Transform3D.IDENTITY
var _shots: Array = []
var _t := 0.0
var _hud: CanvasLayer
var _driver: Node3D
var _player_camera: Camera3D
var _lights: Array[Node3D] = []
var _texts: Array[String] = []
var _hidden_driver := false


func _ready() -> void:
	film = FilmLook.new()
	film.name = "FilmLook"
	add_child(film)
	camera = Camera3D.new()
	camera.name = "CutsceneCamera"
	camera.attributes = CameraAttributesPractical.new()
	add_child(camera)
	set_process(false)


## Plays `shots` (each a Dictionary: name, seconds, from, to, optional via, fov, card, caption,
## full_card, hold, black, lights, focus, hide_driver, exposure, gamma; `hold` keeps the camera
## still and the frame black under a full-screen title for its first seconds), holding `driver` and hiding `hud`; `player_camera` is the
## camera play goes back to.
func play(shots: Array, hud: CanvasLayer, driver: Node3D, player_camera: Camera3D) -> void:
	_shots = shots
	_hud = hud
	_driver = driver
	_player_camera = player_camera
	_texts.clear()
	for each: Dictionary in shots:
		for key in ["card", "caption", "full_card"]:
			if each.has(key):
				_texts.append(String((each[key] as Array)[0]))
	playing = true
	shot = -1
	_t = 0.0
	hud.call("set_cinematic", true)
	driver.set("held", true)
	film.show_film(true)
	camera.make_current()
	set_process(true)
	_enter(0)


func shot_names() -> Array:
	return _shots.map(func(each: Dictionary) -> String: return String(each["name"]))


func total_seconds() -> float:
	var total := 0.0
	for each: Dictionary in _shots:
		total += float(each["seconds"])
	return total


## Every word the cutscene puts on screen.
func all_texts() -> Array:
	return _texts.duplicate()


func _enter(index: int) -> void:
	_clear_lights()
	film.clear_texts()
	shot = index
	_t = 0.0
	var each: Dictionary = _shots[index]
	film.set_black(bool(each.get("black", false)))
	film.set_grade(float(each.get("exposure", 1.0)), float(each.get("gamma", 0.92)))
	if each.has("card"):
		var card: Array = each["card"]
		film.show_card(card[0], card[1])
	if each.has("full_card"):
		var full: Array = each["full_card"]
		film.show_full_title(full[0], full[1])
	if each.has("caption"):
		var caption: Array = each["caption"]
		film.show_caption(caption[0], caption[1])
	for light: Dictionary in each.get("lights", []):
		var lamp := OmniLight3D.new()
		lamp.light_color = light["colour"]
		lamp.light_energy = light["energy"]
		lamp.omni_range = light["range"]
		add_child(lamp)
		lamp.global_position = light["at"]
		_lights.append(lamp)
	var hide := bool(each.get("hide_driver", false))
	if hide != _hidden_driver and is_instance_valid(_driver):
		_driver.visible = not hide
		_hidden_driver = hide
	var practical := camera.attributes as CameraAttributesPractical
	var focus := float(each.get("focus", 0.0))
	practical.dof_blur_far_enabled = focus > 0.0
	if focus > 0.0:
		practical.dof_blur_far_distance = focus + 1.5
		practical.dof_blur_far_transition = 4.0
		practical.dof_blur_amount = 0.12
	_place(0.0)


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	film.show_skip(_elapsed() >= SKIP_AFTER)
	var each: Dictionary = _shots[shot]
	var seconds := float(each["seconds"])
	if each.has("card") and _t >= seconds - FilmLook.CARD_FADE - 0.4:
		film.hide_card()
	var hold := float(each.get("hold", 0.0))
	if each.has("full_card") and _t >= hold - FilmLook.CARD_FADE:
		film.hide_full_title()
	film.set_dip(_dip_at(each, seconds, hold))
	if _t >= seconds:
		if shot + 1 < _shots.size():
			_enter(shot + 1)
		else:
			_place(1.0)
			_finish(false)
			return
	_place(clampf((_t - hold) / maxf(seconds - hold, 0.01), 0.0, 1.0))


## How black the frame is at this moment of the shot: up from black at its start (none for the
## first, which is black anyway) and down to black at its end (none for the last, which hands to
## play); a shot held black under its title stays black until `hold` and then fades up.
func _dip_at(each: Dictionary, seconds: float, hold: float) -> float:
	var amount := 0.0
	if hold > 0.0:
		amount = 1.0 - smoothstep(hold, hold + DIP * 2.0, _t)
	elif shot > 0:
		amount = 1.0 - smoothstep(0.0, DIP, _t)
	if shot + 1 < _shots.size() and not bool(each.get("black", false)):
		amount = maxf(amount, smoothstep(seconds - DIP, seconds, _t))
	return amount


func _elapsed() -> float:
	var total := 0.0
	for index in range(maxi(shot, 0)):
		total += float((_shots[index] as Dictionary)["seconds"])
	return total + _t


func _view(value: Variant) -> Transform3D:
	if value is String and value == "player" and is_instance_valid(_player_camera):
		return _player_camera.global_transform
	return value


## The camera at `share` (0..1) of the shot, eased in and out.
func _place(share: float) -> void:
	var each: Dictionary = _shots[shot]
	var eased := share * share * (3.0 - 2.0 * share)
	var from := _view(each["from"])
	var to := _view(each["to"])
	var view: Transform3D
	if each.has("via"):
		var via := _view(each["via"])
		var split := float(each.get("split", 0.5))
		if eased < split:
			view = from.interpolate_with(via, smoothstep(0.0, 1.0, eased / split))
		else:
			view = via.interpolate_with(to, smoothstep(0.0, 1.0, (eased - split) / (1.0 - split)))
	else:
		view = from.interpolate_with(to, eased)
	camera.global_transform = view
	last_view = view
	var fov: Vector2 = each.get("fov", Vector2(40.0, 40.0))
	camera.fov = lerpf(fov.x, fov.y, eased)
	if each.get("to") is String and is_instance_valid(_player_camera):
		camera.fov = lerpf(fov.x, _player_camera.fov, eased)


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_finish(true)


## Skips the cutscene to its end.
func skip() -> void:
	if playing:
		_finish(true)


func _finish(skipped: bool) -> void:
	playing = false
	set_process(false)
	_clear_lights()
	film.show_film(false)
	if _hidden_driver and is_instance_valid(_driver):
		_driver.visible = true
		_hidden_driver = false
	if is_instance_valid(_player_camera):
		_player_camera.make_current()
	if is_instance_valid(_hud):
		_hud.call("set_cinematic", false)
	if is_instance_valid(_driver):
		_driver.set("held", false)
	finished.emit(skipped)


func _clear_lights() -> void:
	for lamp in _lights:
		lamp.queue_free()
	_lights.clear()
