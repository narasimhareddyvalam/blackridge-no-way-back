extends SceneTree
## Part D of step 5 of #253: the transfer shed's floor (`shed_floor.gd`) in stills, on Mission 2's
## start save, from about where Ethan's eyes are: along the cross-aisle past the parked forklift
## and its oil, the wet floor in from bay 9 and dock 5, the scuffs before the closed docks'
## levellers, down aisle 03, the footprints in from the side door, and from high, where the joints
## must fade without shimmering. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_shed_floor.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["cross_aisle", Vector3(-47.0, 2.9, 12.2), Vector3(-66.0, 1.3, 12.0), 60.0],
	["forklift_oil", Vector3(-61.2, 2.7, 14.2), Vector3(-63.2, 1.3, 12.4), 55.0],
	["in_from_bay_9", Vector3(-48.6, 2.9, 12.8), Vector3(-47.8, 1.3, 18.6), 60.0],
	["in_from_dock_5", Vector3(-62.0, 2.9, 12.6), Vector3(-64.0, 1.3, 19.0), 60.0],
	["before_the_levellers", Vector3(-58.0, 2.9, 14.8), Vector3(-58.0, 1.3, 19.0), 60.0],
	["down_aisle_03", Vector3(-66.3, 2.9, 12.6), Vector3(-66.3, 1.6, -8.0), 55.0],
	["in_from_the_side_door", Vector3(-43.2, 1.62, 13.4), Vector3(-41.0, 0.02, 17.4), 60.0],
	["high", Vector3(-46.5, 7.2, 12.5), Vector3(-68.0, 1.3, -4.0), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_shed_floor_progress.cfg")
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
