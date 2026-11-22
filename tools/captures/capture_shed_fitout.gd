extends SceneTree
## Part E of step 5 of #253: the transfer shed's fit-out overhead and on its walls
## (`shed_fitout.gd`) in stills, on Mission 2's start save, from about where Ethan's eyes are: the
## dock wall from the staging lanes (heaters, numbers, control stations, inside lights, tray), a
## fan overhead, a control station close, the side door's wall (time clock, card racks, notice
## board), the staging lanes' overhead, the heater over the lane. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_shed_fitout.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["dock_wall", Vector3(-62.0, 2.9, 11.5), Vector3(-62.0, 4.6, 19.75), 70.0],
	["fan_overhead", Vector3(-66.0, 2.9, 11.0), Vector3(-74.0, 7.3, 15.55), 60.0],
	["control_station", Vector3(-59.0, 2.9, 17.6), Vector3(-58.0, 2.75, 19.75), 50.0],
	["side_door_wall", Vector3(-42.9, 1.62, 15.5), Vector3(-40.25, 1.45, 15.5), 65.0],
	["staging_overhead", Vector3(-48.0, 2.9, 11.0), Vector3(-70.0, 7.6, 17.5), 65.0],
	["lane_heater", Vector3(-41.6, 1.62, 12.6), Vector3(-43.4, 4.3, 16.0), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_shed_fitout_progress.cfg")
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
