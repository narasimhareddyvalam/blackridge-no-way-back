extends SceneTree
## The convoy in play (#359, Mission 3's step 5, part B): from the van behind them on the coastal
## road, Maya calling; then from the airfield's gate as the lead keys in, the gate open; then
## the lead's lamps close, from behind and ahead.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_convoy.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=2\n"
const JUNCTION := Vector3(726.0, 0.0, 151.7)

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
	var progress := OS.get_user_data_dir().path_join("capture_convoy.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _wait(1.0)
	var van := _app.get_node("FreightVan") as CharacterBody3D
	van.call("recover", Transform3D(Basis(Vector3.UP, -PI / 2.0), JUNCTION + Vector3(-20.0, 0.1,
		0.0)))
	await _wait(1.5)
	var convoy := (_app.get("run") as Node).get("convoy") as Node
	var tail := (convoy.get("suvs") as Array)[1] as Node3D
	van.call("recover", Transform3D(tail.global_basis, tail.global_position
		+ tail.global_basis.z * 45.0 + Vector3.UP * 0.1))
	await _wait(3.0)
	await _save("1_tailing_maya_calls")
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var waited := 0.0
	while not bool(field.call("gate_open")) and waited < 90.0:
		tail = (convoy.get("suvs") as Array)[1] as Node3D
		van.call("recover", Transform3D(tail.global_basis, tail.global_position
			+ tail.global_basis.z * 60.0 + Vector3.UP * 0.1))
		await physics_frame
		waited += 1.0 / 60.0
	var gate: Vector3 = field.get("gate")
	var camera := Camera3D.new()
	camera.fov = 50.0
	root.add_child(camera)
	camera.make_current()
	camera.look_at_from_position(gate + Vector3(8.0, 3.0, -9.0), gate + Vector3(-12.0, 1.0, 0.0))
	await _wait(0.5)
	await _save("2_the_gate_opens_for_them")
	var lead := (convoy.get("suvs") as Array)[0] as Node3D
	var back := lead.global_basis.z
	var side := lead.global_basis.x
	camera.fov = 40.0
	camera.look_at_from_position(lead.global_position + back * 6.5 + side * 1.8 + Vector3.UP * 1.4,
		lead.global_position + back * 2.7 + Vector3.UP * 1.0)
	await _save("3_lamps_from_behind")
	camera.look_at_from_position(lead.global_position - back * 6.5 - side * 1.8 + Vector3.UP * 1.3,
		lead.global_position - back * 2.6 + Vector3.UP * 0.9)
	await _save("4_lamps_from_ahead")
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
