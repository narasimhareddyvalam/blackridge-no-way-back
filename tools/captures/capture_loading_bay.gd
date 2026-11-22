extends SceneTree
## Mission 2's step 5, part C: the loading bay and the yard (`warehouse.gd`, `compound.gd`) in
## stills, on Mission 2's stage 3 save, the dark van docked at door 3: door 3 open and lit with
## the van backed onto it, the bay inside from the dock, the trailers dropped at the west
## warehouse, the court under the floodlights, and the parked forklift by its pallets. Run
## windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_loading_bay.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=3\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["van_docked_at_door_3", Vector3(255.0, 2.6, 145.0),
		Vector3(248.0, 2.0, 132.0), 60.0],
	["the_bay_inside", Vector3(248.6, 3.0, 131.0), Vector3(248.0, 1.8, 124.0), 70.0],
	["trailers_at_the_west_docks", Vector3(160.0, 2.2, 144.0), Vector3(147.0, 2.0, 128.0),
		60.0],
	["the_court_under_the_floods", Vector3(200.0, 7.0, 144.0), Vector3(230.0, 0.0, 128.0),
		70.0],
	["forklift_and_pallets", Vector3(200.0, 2.0, 120.0), Vector3(229.0, 1.0, 124.0), 55.0],
	["a_flood_pool_from_above", Vector3(222.0, 16.0, 152.0), Vector3(222.0, 0.0, 128.0), 70.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_loading_bay_progress.cfg")
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
	await create_timer(1.0, true, false, true).timeout
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
