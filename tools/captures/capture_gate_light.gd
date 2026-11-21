extends SceneTree
## The compound's gate at night (the audit, #353): down the driveway, at the stop line, the flood
## pole close, from inside the gate, the yard's floods with their rain, and the gate's floods close. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_gate_light.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VIEWS := {
	"1_approach": [Vector3(199.3, 2.2, 163.0), Vector3(200.0, 1.5, 146.0)],
	"2_stop_line": [Vector3(201.8, 2.4, 156.0), Vector3(198.5, 1.4, 148.0)],
	"3_pole_close": [Vector3(208.0, 2.5, 154.0), Vector3(204.0, 5.0, 147.4)],
	"4_inside_out": [Vector3(200.5, 2.0, 137.0), Vector3(200.0, 1.5, 152.0)],
	"5_yard_floods": [Vector3(196.0, 2.0, 130.0), Vector3(222.0, 4.0, 142.0)],
	"6_floods_close": [Vector3(201.8, 6.2, 149.6), Vector3(204.6, 7.5, 147.4)],
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_gate_light.cfg")
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
	(app.get_node("FreightVan") as Node3D).call("recover", Transform3D(Basis.IDENTITY,
		Vector3(-28.0, 0.1, 93.0)))
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	_camera.make_current()
	for view: String in VIEWS:
		_camera.global_position = VIEWS[view][0]
		await create_timer(0.8, true, false, true).timeout
		_camera.look_at_from_position(VIEWS[view][0], VIEWS[view][1])
		for frame in range(3):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
	quit(0)
