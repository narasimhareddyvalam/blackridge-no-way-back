extends SceneTree
## #270-#271: the wet ground and the light on it as they are, in stills, on Mission 2's start
## save: the valley road under a town lamp (eye height and low), the valley road beyond, the
## dock apron, the freight depot's yard and the shed's floor. Run windowed, from the repository
## root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_wet.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Views: name, from, looking at, field of view.
const VIEWS := [["town_lamp_road", Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0],
	["town_lamp_low", Vector3(-24.0, 0.9, 69.0), Vector3(-15.0, 0.3, 64.5), 50.0],
	["valley_road", Vector3(30.0, 1.7, 62.0), Vector3(5.0, 0.0, 64.0), 60.0],
	["apron_docks", Vector3(-58.0, 1.7, 30.0), Vector3(-54.0, 0.2, 22.0), 55.0],
	["depot_yard", Vector3(-24.0, 1.7, 92.0), Vector3(-30.0, 0.0, 104.0), 60.0],
	["shed_floor", Vector3(-58.0, 3.0, 13.0), Vector3(-62.0, 1.3, 6.0), 60.0]]

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_wet_progress.cfg")
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
