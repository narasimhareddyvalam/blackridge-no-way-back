extends SceneTree
## The run sheet handed over at the transfer shed's booth (#355): the van tucked in by the booth,
## E pressed, stills through the handover from Ethan's seat with his head turned to the booth,
## then the compound's handover from beside the van. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_handover.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const EYE := Vector3(-0.45, 1.8, -0.72)
const GAP := 0.4
const TIMES: Array[float] = [3.2, 4.0, 4.6, 5.4, 7.0, 9.6, 10.6, 11.4]

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_handover.cfg")
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
	var van := app.get_node("FreightVan") as Node3D
	var world := app.get_node("IndustrialLoop")
	_camera = Camera3D.new()
	_camera.fov = 70.0
	root.add_child(_camera)
	await _hand_over(van, world.get("transfer_shed"), world.get("transfer_shed").get("_booth_node"),
		"shed", true)
	await _hand_over(van, world.get("compound"), world.get("compound").get("booth"), "compound",
		false)
	quit(0)


func _hand_over(van: Node3D, gate: Node3D, booth: Node3D, label: String, seat: bool) -> void:
	var out := booth.global_basis.x.normalized()
	var opening: Vector3 = booth.call("opening_centre")
	var forward := -out.cross(Vector3.UP)
	var origin := opening + out * (GAP + 1.0) + forward * EYE.z
	origin.y = booth.global_position.y - 0.25
	van.call("recover", Transform3D(Basis(out, Vector3.UP, out.cross(Vector3.UP)), origin))
	await create_timer(1.5, true, false, true).timeout
	_camera.make_current()
	gate.call("hand_run_sheet")
	var start := Time.get_ticks_msec()
	for at in TIMES:
		while (Time.get_ticks_msec() - start) / 1000.0 < at:
			if seat:
				var eye := van.to_global(EYE)
				_camera.look_at_from_position(eye, opening + Vector3(0.0, -0.35, 0.0))
			else:
				var side := van.to_global(Vector3(-1.75, 2.05, 1.2))
				_camera.look_at_from_position(side, van.to_global(Vector3(-1.2, 1.35, -0.8)))
			await process_frame
		for frame in range(2):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("%s_%04.1f.png" % [label, at]))
	while bool(gate.call("checking")):
		await process_frame
	await create_timer(1.0, true, false, true).timeout
