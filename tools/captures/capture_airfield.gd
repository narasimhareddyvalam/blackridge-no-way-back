extends SceneTree
## The airfield in play (#359, Mission 3's step 5, part A).
## the coastal road at the junction, the quay and the sea, the embankment, and the flats from above.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_airfield.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\n"

var _out := ""
var _app: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var progress := OS.get_user_data_dir().path_join("capture_airfield.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	await _wait(2.0)
	var van := _app.get_node("FreightVan") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(735.0, 0.1, -150.0)))
	await _wait(2.0)
	await _save("1_to_the_gate_seat")
	_camera = Camera3D.new()
	_camera.fov = 55.0
	root.add_child(_camera)
	_camera.make_current()
	_camera.look_at_from_position(Vector3(925.0, 3.0, -190.0), Vector3(960.0, 2.0, -130.0))
	await _save("2_apron_plane_and_hangar")
	_camera.look_at_from_position(Vector3(960.0, 1.7, -130.0), Vector3(968.0, 1.5, -100.0))
	await _save("3_inside_the_hangar")
	_camera.look_at_from_position(Vector3(770.0, 1.5, -245.0), Vector3(1100.0, 0.0, -250.0))
	await _save("4_down_the_runway")
	_camera.fov = 60.0
	_camera.look_at_from_position(Vector3(870.0, 60.0, -40.0), Vector3(990.0, 0.0, -190.0))
	await _save("5_airfield_from_above")
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
