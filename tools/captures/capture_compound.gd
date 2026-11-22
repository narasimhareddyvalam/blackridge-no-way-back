extends SceneTree
## Mission 2's step 5: the warehouse compound (`compound.gd`) in stills, on Mission 2's stage 2
## save, the dark van at the booth's line: the gate and booth from the driveway, the guard at her
## window from Ethan's seat, the booth and its island from the lane, the fence stepped clear of
## the container yard, and the compound's north fence from the road. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_compound.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const AT_THE_LINE := Transform3D(Basis.IDENTITY, Vector3(200.0, 0.1, 151.3))
## Views: name, from, looking at, field of view.
const VIEWS := [["gate_and_booth_from_the_drive", Vector3(201.5, 2.2, 168.0),
		Vector3(199.0, 1.4, 146.0), 60.0],
	["guard_from_the_seat", Vector3(199.4, 1.7, 150.55), Vector3(197.05, 1.35, 150.75), 50.0],
	["booth_and_island", Vector3(193.0, 1.8, 155.5), Vector3(197.0, 1.1, 150.2), 55.0],
	["fence_step_by_the_yard", Vector3(140.5, 2.0, 150.0), Vector3(136.0, 1.5, 131.0), 65.0],
	["north_fence_from_the_road", Vector3(240.0, 2.0, 168.0), Vector3(232.0, 2.0, 140.0), 65.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_compound_progress.cfg")
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
	(app.get_node("FreightVan") as CharacterBody3D).call("recover", AT_THE_LINE)
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
