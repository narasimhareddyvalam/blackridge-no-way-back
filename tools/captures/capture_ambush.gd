extends SceneTree
## The ambush at berth 2 in play (#359, Mission 3's step 3, part B): the trap's cutscene shot by
## shot, the escape with the SUV racing for the gate, and the phone. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_ambush.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\n"
const AT: Array[float] = [1.5, 4.2, 6.8, 8.6, 10.2]

var _out := ""
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var progress := OS.get_user_data_dir().path_join("capture_ambush.cfg")
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
	await _wait(1.5)
	var van := _app.get_node("FreightVan") as Node3D
	var front := _app.get_node("IndustrialLoop").get("harbour_flats").get("waterfront") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), (front.get("berth") as Vector3)
		+ Vector3.UP * 0.1))
	var waited := 0.0
	for index in range(AT.size()):
		await _wait(AT[index] - waited)
		waited = AT[index]
		await _save("%d_trap_%d" % [index + 1, index + 1])
	await _wait(5.0)
	await _save("6_escape_seat")
	var camera := Camera3D.new()
	camera.fov = 50.0
	root.add_child(camera)
	camera.make_current()
	camera.look_at_from_position(Vector3(855.0, 6.0, 222.0), Vector3(880.0, 1.0, 210.0))
	await _save("7_suv_racing_for_the_gate")
	quit(0)


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
