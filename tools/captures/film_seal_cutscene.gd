extends SceneTree
## Fix 4's cutscene (#333), filmed in a 1280x800 window with Godot's Movie Maker on Mission 2's
## start save: the van pulled forward from bay 9 as play leaves it to be sealed, Ethan out of it
## by E and standing at its shut rear doors as if he had just closed them (set as setup); the
## shed sends the dock hand out as the doors' shutting does, and the cutscene plays until it hands
## back Ethan's camera. Usage, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --write-movie <absolute folder>/seal.avi \
##     --fixed-fps 30 --script ../tools/captures/film_seal_cutscene.gd

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const PULLED_FORWARD := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
const AT_THE_DOORS := Vector3(0.0, 0.0, 3.7)
const NUMBER := "4182260"
const AFTER := 3.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("film_seal_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _seconds(1.0)
	var van := app.get_node("FreightVan") as Node3D
	var driver := app.get("driver") as CharacterBody3D
	var shed := app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	van.call("recover", PULLED_FORWARD)
	van.set("rear_doors_open", false)
	await _seconds(1.0)
	await _key(KEY_E)
	await _seconds(3.0)
	var spot := van.to_global(AT_THE_DOORS)
	driver.global_position = Vector3(spot.x, driver.global_position.y, spot.z)
	var toward := van.global_position - driver.global_position
	driver.call("look_toward", -Vector3(toward.x, 0.0, toward.z).normalized())
	await _seconds(1.5)
	shed.call("call_dock_hand", van, NUMBER)
	var cutscene := app.get("seal_cutscene") as Node
	await _seconds(0.5)
	var time := 0.0
	while bool(cutscene.get("playing")) and time < 90.0:
		await process_frame
		time += 1.0 / 30.0
	await _seconds(AFTER)
	quit(0)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
