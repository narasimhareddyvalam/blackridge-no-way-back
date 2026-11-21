extends SceneTree
## Mission 1's opening cutscene (#357; GAME_STORY's prologue, C35; the author's storyboard, take 2,
## "much better, i like it"): a new game plays it in the neo-noir film look: black bars, the HUD
## and the map hidden, its own camera, Ethan's keys held; its eight shots in the storyboard's order
## over about 48 s, the studio card first and NIGHT FREIGHT filling the screen last, each cut
## dipping through black, the caption BLACKRIDGE,
## never the game's own title (C04, C42); E skips it at once and gives play back exactly as it
## starts without it; played through, it ends on the player's own camera behind Ethan at the
## clipboard; and a saved game resumed does not play it.

const SHOTS: Array[String] = ["studio", "lamp_in_the_water", "hill_road", "crossing",
	"empty_shelter", "ethan", "van_waits", "title"]
const LENGTH := Vector2(44.0, 50.0)
const SAVE_TWO := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-opening-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_new_drive")
	for frame in range(5):
		await process_frame
	var director := _app.get("cutscene") as Node
	if director == null or not bool(director.get("playing")):
		_check(false, "O1: a new game plays the opening (no cutscene playing)")
		_finish()
		return
	await _while_playing(director)
	await _skips(director)
	await _plays_through(director)
	await _not_on_restart(director)
	await _not_on_resume()
	_finish()


func _while_playing(director: Node) -> void:
	var hud := _app.get("hud") as CanvasLayer
	var driver := _app.get("driver") as CharacterBody3D
	var film := director.get("film") as CanvasLayer
	var camera := director.get("camera") as Camera3D
	var map := hud.get("mission_map") as Control
	var objective := hud.get("_objective") as Label
	var at := driver.global_position
	Input.action_press("accelerate")
	for frame in range(40):
		await physics_frame
	Input.action_release("accelerate")
	var still := driver.global_position.distance_to(at) < 0.05
	_check(film != null and bool(film.call("bars_shown")) and not map.is_visible_in_tree()
		and not objective.is_visible_in_tree() and root.get_viewport().get_camera_3d() == camera
		and bool(driver.get("held")) and still, ("O1: a new game plays the opening in the film "
		+ "look: black bars, the HUD and map hidden, its own camera, Ethan's keys held (still %s)")
		% still)
	var names: Array = director.call("shot_names")
	var length: float = director.call("total_seconds")
	var texts: Array = director.call("all_texts")
	var titled: bool = texts.has("NIGHT FREIGHT") and texts.has("BLACKRIDGE") \
		and texts.has("NRVALAM WORKS")
	var no_game_title: bool = texts.all(func(text: String) -> bool:
		return not text.to_upper().contains("NO WAY BACK"))
	_check(names == SHOTS and length >= LENGTH.x and length <= LENGTH.y and titled
		and no_game_title, ("O2: its shots in the storyboard's order over %.1f s (%s), the studio "
		+ "card, BLACKRIDGE and NIGHT FREIGHT shown, never the game's title (%s)") % [length,
		names, texts])


func _skips(director: Node) -> void:
	var driver := _app.get("driver") as CharacterBody3D
	var hud := _app.get("hud") as CanvasLayer
	var film := director.get("film") as CanvasLayer
	for frame in range(330):
		await process_frame
	var moved: int = director.get("shot")
	await _press("interact")
	for frame in range(3):
		await process_frame
	var objective := hud.get("_objective") as Label
	var back: bool = not bool(director.get("playing")) and not bool(film.call("bars_shown")) \
		and root.get_viewport().get_camera_3d() == driver.call("get_camera") \
		and not bool(driver.get("held")) and objective.is_visible_in_tree() \
		and objective.text == "SIGN THE RUN SHEET"
	_check(moved >= 1 and back, ("O3: E skips it at once and gives play back as it starts: the "
		+ "player's camera, no bars, the HUD, Ethan free, SIGN THE RUN SHEET (was on shot %d; "
		+ "playing %s, bars %s, held %s, objective %s)") % [moved, director.get("playing"),
		film.call("bars_shown"), driver.get("held"), objective.text])


func _plays_through(director: Node) -> void:
	var driver := _app.get("driver") as CharacterBody3D
	_app.call("_new_drive")
	_app.call("_play_opening")
	var film := director.get("film") as CanvasLayer
	var waited := 0.0
	var at_cut := {}
	var clear_mid := {}
	var full_title := false
	var last_shot := -1
	var last_dip := 0.0
	while bool(director.get("playing")) and waited < 70.0:
		await process_frame
		waited += 1.0 / 60.0
		var now: int = director.get("shot")
		var dip: float = film.call("dip")
		if now != last_shot and last_shot >= 1:
			at_cut[last_shot] = last_dip
		if dip < 0.05:
			clear_mid[now] = true
		if now == SHOTS.size() - 1 and bool(film.call("full_title_shown")):
			full_title = true
		last_shot = now
		last_dip = dip
	var dipped := true
	for index in range(1, SHOTS.size() - 1):
		dipped = dipped and float(at_cut.get(index, 0.0)) > 0.9 and clear_mid.has(index)
	_check(dipped and full_title, ("O6: every cut dips through black (black at the cuts %s), each "
		+ "shot clear between, and the title fills the screen on black (%s)") % [at_cut,
		full_title])
	var end: Transform3D = director.get("last_view")
	var player := (driver.call("get_camera") as Camera3D).global_transform
	var landed: bool = end.origin.distance_to(player.origin) < 0.15 \
		and (-end.basis.z).angle_to(-player.basis.z) < deg_to_rad(4.0)
	_check(not bool(director.get("playing")) and landed and not bool(driver.get("held"))
		and root.get_viewport().get_camera_3d() == driver.call("get_camera"), ("O4: played "
		+ "through (%.1f s), it ends on the player's own camera behind Ethan (%.2f m off) and "
		+ "gives him back") % [waited, end.origin.distance_to(player.origin)])


## A restart in play (New drive from the pause menu, or after the ending) starts the drive at
## once, as a game's restart skips its intro (#358): the opening belongs to a new game.
func _not_on_restart(director: Node) -> void:
	var hud := _app.get("hud") as CanvasLayer
	hud.emit_signal("restart_requested")
	for frame in range(10):
		await process_frame
	var objective := hud.get("_objective") as Label
	_check(not bool(director.get("playing")) and objective.is_visible_in_tree(), ("O7: New drive "
		+ "in play starts at the office at once, no opening (playing %s, objective shown %s)")
		% [director.get("playing"), objective.is_visible_in_tree()])


func _not_on_resume() -> void:
	_app.queue_free()
	await process_frame
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(SAVE_TWO)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_begin")
	for frame in range(10):
		await process_frame
	var director := _app.get("cutscene") as Node
	_check(director != null and not bool(director.get("playing")), "O5: a saved game resumed "
		+ "does not play the opening")


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _finish() -> void:
	print("OPENING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if is_instance_valid(_app):
		_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The opening's checks finish within 300 s")
	quit(1)
