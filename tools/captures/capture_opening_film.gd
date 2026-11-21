extends SceneTree
## Stills of Mission 1's opening cutscene as it plays in the game (#357): a new game begun and a
## frame saved at each shot's middle, in the film look. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_opening_film.gd -- <absolute stills folder>

const TIMES: Array[float] = [2.5, 4.2, 7.5, 10.8, 14.0, 20.5, 26.5, 32.5, 38.0, 42.5, 44.6, 46.5,
	48.6]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = OS.get_user_data_dir().path_join(
		"capture_opening_film.cfg")
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	app.call("_new_drive")
	var start := Time.get_ticks_msec()
	for at in TIMES:
		while (Time.get_ticks_msec() - start) / 1000.0 < at:
			await process_frame
		for frame in range(2):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("opening_%04.1f.png" % at))
	quit(0)
