extends SceneTree
## Part A of #267: the transfer shed's racking (`racking.gd`) in stills, on Mission 2's start
## save: down aisle 03 from the staging lanes, as the author's photo looks down its aisle; across
## the rows; a row's end with its guard, protectors and board; from high; and inside an aisle.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_racking.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["down_aisle_03", Vector3(-66.3, 3.0, 12.6), Vector3(-66.3, 3.6, -8.0), 55.0],
	["across_rows", Vector3(-50.0, 3.2, 12.0), Vector3(-68.0, 3.4, 1.0), 60.0],
	["row_end", Vector3(-63.6, 2.7, 9.9), Vector3(-62.3, 2.2, 8.2), 50.0],
	["high", Vector3(-46.5, 7.2, 12.5), Vector3(-68.0, 2.5, -4.0), 60.0],
	["in_the_aisle", Vector3(-60.1, 3.0, 1.5), Vector3(-61.9, 2.6, -1.5), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_racking_progress.cfg")
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
