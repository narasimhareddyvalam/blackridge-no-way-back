extends SceneTree
## Part F of step 5 of #253: the transfer shed's safety and work kit (`shed_kit.gd`) in stills, on
## Mission 2's start save, from about where Ethan's eyes are: the charging bay (charger, hatching,
## eyewash, spill kit, NO SMOKING), the west exit inside and out, the cross-aisle's hung EXIT signs,
## the mirrors at the aisles' mouths, the walkway's crossing, the side door's first aid and EXIT,
## the baler. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_shed_kit.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["charging_bay", Vector3(-82.6, 2.9, 7.4), Vector3(-87.2, 1.9, 11.0), 65.0],
	["west_exit", Vector3(-84.8, 2.9, 1.6), Vector3(-89.75, 2.6, 4.0), 60.0],
	["west_exit_outside", Vector3(-91.9, 2.4, -0.8), Vector3(-90.4, 1.6, 3.6), 70.0],
	["hung_exit_signs", Vector3(-55.5, 2.9, 15.8), Vector3(-58.0, 4.3, 12.0), 55.0],
	["aisle_mirrors", Vector3(-50.0, 2.9, 11.6), Vector3(-70.0, 3.6, 8.4), 60.0],
	["walkway_crossing", Vector3(-46.0, 2.9, 15.8), Vector3(-46.0, 1.3, 9.0), 60.0],
	["side_door_first_aid", Vector3(-42.9, 1.62, 15.2), Vector3(-40.25, 1.8, 16.0), 70.0],
	["baler", Vector3(-84.4, 2.9, -0.6), Vector3(-89.3, 1.0, -5.6), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_shed_kit_progress.cfg")
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
