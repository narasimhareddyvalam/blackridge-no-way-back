extends SceneTree
## The district seen straight down for the mission map's base (#356): an orthographic camera over
## the play area, the scene drawn unshaded (its own colours, no night), the HUD hidden. Run
## windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1000x1000 \
##     --script ../tools/captures/capture_map_base.gd -- <absolute png path> [centre_x centre_z size]
## (`tools/art/bake_mission_map.py` takes two 500 m tiles from it for the mission map's ground.)

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var centre := Vector2(float(args[1]), float(args[2])) if args.size() >= 3 else Vector2(80, 100)
	var span := float(args[3]) if args.size() >= 4 else 420.0
	var progress := OS.get_user_data_dir().path_join("capture_map_base.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1000, 1000))
	await process_frame
	app.call("_resume")
	await create_timer(1.5, true, false, true).timeout
	(app.get("hud") as CanvasLayer).visible = false
	root.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = span
	camera.far = 900.0
	root.add_child(camera)
	camera.global_position = Vector3(centre.x, 400.0, centre.y)
	camera.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	camera.make_current()
	await create_timer(1.0, true, false, true).timeout
	for frame in range(4):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit(0)
