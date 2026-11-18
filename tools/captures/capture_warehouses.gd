extends SceneTree
## Mission 2's step 5, part B: the compound's two warehouses (`warehouse.gd`) in stills, on Mission
## 2's stage 2 save: the east warehouse's docks from its court, one dock close, the man door's stair
## and the fire department connection, the west warehouse from the gate, the back with its
## downpipes, and the roofs from above. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_warehouses.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["east_docks_from_the_court", Vector3(250.0, 2.0, 144.0),
		Vector3(250.0, 3.5, 131.5), 70.0],
	["a_dock_close", Vector3(253.5, 1.6, 136.5), Vector3(248.0, 2.0, 131.5), 55.0],
	["man_door_stair", Vector3(238.5, 1.8, 136.0), Vector3(235.2, 1.2, 132.0), 55.0],
	["west_from_the_gate", Vector3(196.0, 3.0, 143.0), Vector3(150.0, 4.0, 123.5), 60.0],
	["the_back_and_downpipes", Vector3(270.0, 2.0, 100.0), Vector3(255.0, 5.0, 108.5), 60.0],
	["the_roofs_from_above", Vector3(205.0, 40.0, 160.0), Vector3(205.0, 5.0, 115.0), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_warehouses_progress.cfg")
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
	(app.get_node("FreightVan") as CharacterBody3D).call("recover", Transform3D(Basis.IDENTITY,
		Vector3(215.0, 0.1, 138.0)))
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
