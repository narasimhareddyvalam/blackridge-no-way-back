extends SceneTree
## Part H of step 5 of #253: the transfer shed's yard at night (`yard_vehicles.gd`) in stills, on
## Mission 2's start save: the trailers backed onto docks 1-3 from the yard, one close at its
## chocked tandem, the trailer bays (the dropped trailer, the coupled rig, the box truck), the
## staff cars, the dumpsters, and the way in from the gate toward bay 9. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_yard.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["trailers_at_docks_1_to_3", Vector3(-62.0, 2.2, 40.0), Vector3(-76.0, 2.0, 26.0),
		60.0],
	["chocked_tandem", Vector3(-69.6, 1.2, 19.4), Vector3(-72.0, 0.6, 24.0), 55.0],
	["trailer_bays", Vector3(-24.0, 3.5, 27.0), Vector3(-34.0, 2.0, 10.0), 60.0],
	["coupled_rig", Vector3(-28.5, 1.8, 26.5), Vector3(-33.6, 1.6, 18.0), 55.0],
	["staff_cars", Vector3(-80.0, 2.0, 50.0), Vector3(-86.5, 0.8, 48.5), 60.0],
	["dumpsters", Vector3(-33.0, 1.9, -6.0), Vector3(-39.0, 0.8, -2.0), 60.0],
	["way_in_from_the_gate", Vector3(-70.0, 2.4, 53.0), Vector3(-50.0, 1.5, 30.0), 70.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_yard_progress.cfg")
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
