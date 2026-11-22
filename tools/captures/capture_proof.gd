extends SceneTree
## Mission 3's confrontation and reconciliation in play (#359, step 4): three frames of each scene.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_proof.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=1\n"
const AT: Array[float] = [4.0, 10.0, 20.0]

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
	var progress := OS.get_user_data_dir().path_join("capture_proof.cfg")
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
	var run := _app.get("run") as Node
	await _scene(run.get("depot_meeting"), "1_confrontation")
	await _wait(8.0)
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _wait(1.0)
	await _save("2_recording")
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _wait(1.0)
	await _scene(run.get("viewpoint_meeting"), "3_reconciliation")
	quit(0)


func _scene(place: Vector3, label: String) -> void:
	var van := _app.get_node("FreightVan") as Node3D
	var along := place - van.global_position
	along.y = 0.0
	van.call("recover", Transform3D(Basis.looking_at(along.normalized(), Vector3.UP),
		place - along.normalized() * 6.0 + Vector3.UP * 0.1))
	var waited := 0.0
	for index in range(AT.size()):
		await _wait(AT[index] - waited)
		waited = AT[index]
		await _save("%s_%d" % [label, index + 1])


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
