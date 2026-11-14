extends SceneTree
## Step 3 of #253 (#263-#265): bay 9's dock station (`dock_station.gd`) in stills, on Mission 2's
## start save, the van away in the court, bay 9's door open: from the yard as Ethan comes to the
## doors, at the doors, walking back along the van, from the lift's deck as he loads, and close
## by. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_dock_station.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["yard", Vector3(-47.6, 1.7, 25.0), Vector3(-46.1, 2.0, 18.5), 45.0],
	["at_the_doors", Vector3(-47.5, 1.7, 21.6), Vector3(-46.1, 2.1, 18.5), 55.0],
	["walking_back", Vector3(-45.6, 2.3, 26.0), Vector3(-46.1, 2.1, 18.5), 50.0],
	["deck", Vector3(-47.75, 2.9, 16.0), Vector3(-45.6, 1.9, 18.6), 55.0],
	["close", Vector3(-47.2, 2.5, 16.3), Vector3(-45.6, 1.75, 18.6), 50.0],
	["chair", Vector3(-46.9, 2.2, 17.4), Vector3(-46.1, 1.6, 18.55), 45.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_dock_station_progress.cfg")
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
	app.call("_begin")
	await create_timer(2.0, true, false, true).timeout
	var camera := Camera3D.new()
	root.add_child(camera)
	for view: Array in VIEWS:
		camera.fov = view[3]
		camera.look_at_from_position(view[1], view[2])
		camera.make_current()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("%s.png" % view[0]))
	quit(0)
