extends SceneTree
## The objective's marker, map pin, distance and key prompt in play (#358, guidance step 2):
## Mission 2 driving toward the transfer shed, the shed behind the van (the edge arrow), level with
## the booth's window (the key prompt), the yard's keypad and the compound's booth from their
## approaches; with `mission1`, Mission 1's run sheet from the office on foot. Run windowed, from
## the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_markers.gd -- <absolute stills folder> [mission1]

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=%d\n"

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
	if args.has("mission1"):
		await _mission_one()
		quit(0)
		return
	await _open(0)
	var van := _app.get_node("FreightVan") as Node3D
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var booth := shed.get("_booth_node") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, 0.35), Vector3(-30.0, 0.1, 100.0)))
	await _wait(2.0)
	await _save("1_toward_the_shed")
	van.call("recover", Transform3D(Basis(Vector3.UP, PI - 0.4), Vector3(-30.0, 0.1, 100.0)))
	await _wait(2.0)
	await _save("2_shed_behind")
	var out := booth.global_basis.x.normalized()
	out.y = 0.0
	out = out.normalized()
	var origin: Vector3 = booth.call("opening_centre") + out * 1.4 + out.cross(Vector3.UP) * 0.72
	origin.y = booth.global_position.y - 0.25
	van.call("recover", Transform3D(Basis(out, Vector3.UP, out.cross(Vector3.UP)), origin))
	await _wait(2.0)
	await _save("3_at_the_window")
	_app.queue_free()
	await _wait(0.5)
	await _open(1)
	van = _app.get_node("FreightVan") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), Vector3(80.0, 0.1, 190.0)))
	await _wait(2.0)
	await _save("4_toward_the_yard")
	_app.queue_free()
	await _wait(0.5)
	await _open(2)
	van = _app.get_node("FreightVan") as Node3D
	van.call("recover", Transform3D(Basis.IDENTITY, Vector3(199.6, 0.1, 172.0)))
	await _wait(2.0)
	await _save("5_toward_the_compound")
	quit(0)


func _mission_one() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_markers_m1.cfg")
	DirAccess.remove_absolute(progress)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _wait(1.5)
	await _action("interact")
	await _wait(3.0)
	await _save("6_run_sheet_on_foot")


func _open(stage: int) -> void:
	var progress := OS.get_user_data_dir().path_join("capture_markers.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE % stage)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _wait(1.5)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame


func _action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
