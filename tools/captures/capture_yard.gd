extends SceneTree
## Mission 2's container yard at night (the audit, #351): from the driveway at the gate, down the
## lane between the blocks, the container doors close up, a stack's corner, the marked bay and
## the dark van, a light mast, from high over the yard, the top-loader and the boxes' sides. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_yard.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const VIEWS := {
	"1_gate": [Vector3(100.0, 1.7, 166.0), Vector3(100.0, 1.5, 150.0)],
	"2_lane": [Vector3(100.0, 1.7, 155.0), Vector3(100.0, 2.0, 135.0)],
	"3_doors_close": [Vector3(105.5, 1.6, 141.5), Vector3(109.5, 1.4, 139.5)],
	"4_stack_corner": [Vector3(106.0, 1.8, 155.0), Vector3(110.0, 3.0, 150.0)],
	"5_bay_and_dark_van": [Vector3(100.0, 2.2, 150.0), Vector3(99.0, 0.8, 139.0)],
	"6_mast": [Vector3(96.0, 1.7, 150.0), Vector3(91.3, 9.0, 156.8)],
	"7_west_doors": [Vector3(94.5, 1.6, 147.0), Vector3(90.5, 1.4, 145.0)],
	"8_high": [Vector3(100.0, 24.0, 170.0), Vector3(100.0, 0.0, 142.0)],
	"9_top_loader": [Vector3(112.0, 2.2, 156.5), Vector3(127.0, 3.0, 153.0)],
	"10_side_names": [Vector3(100.0, 1.8, 152.0), Vector3(84.0, 2.5, 150.0)],
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_yard.cfg")
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
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	await create_timer(1.5, true, false, true).timeout
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	_camera.make_current()
	for view: String in VIEWS:
		_camera.global_position = VIEWS[view][0]
		await create_timer(0.7, true, false, true).timeout
		_camera.look_at_from_position(VIEWS[view][0], VIEWS[view][1])
		for frame in range(3):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
	quit(0)
