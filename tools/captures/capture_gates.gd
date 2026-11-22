extends SceneTree
## Mission 2's gates at night (the audit, #349): the transfer shed's barrier, the container yard's
## and the compound's sliding gates, each from a driver's approach, close at its machinery, along
## it, from inside and from high; then each moving, its warning lamp flashing. Run windowed, from
## the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_gates.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## In the world, from each gate's middle (x, z), the lanes running along z, the van coming from +z.
const VIEWS := {
	"approach": [Vector3(1.5, 1.9, 12.0), Vector3(0.0, 1.0, 0.0)],
	"machinery": [Vector3(-6.5, 1.7, 3.5), Vector3(-3.2, 0.6, 0.0)],
	"along": [Vector3(5.5, 1.5, 2.5), Vector3(-2.0, 1.0, 0.0)],
	"inside": [Vector3(2.0, 1.8, -8.0), Vector3(0.0, 1.0, 0.0)],
	"high": [Vector3(6.0, 6.5, 8.0), Vector3(-1.0, 0.5, 0.0)],
	"inside_machinery": [Vector3(-2.6, 1.3, -2.4), Vector3(-4.4, 0.25, -0.35)],
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_gates.cfg")
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
	var key := InputEventKey.new()
	for pressed in [true, false]:
		key = InputEventKey.new()
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
	var world := app.get_node("IndustrialLoop")
	var shed := world.get("transfer_shed") as Node3D
	var gates := {
		"0_shed_barrier": Vector3(float(shed.get("LANE_X")), 0.0, float(shed.get("GATE_Z"))),
		"1_yard_gate": (world.get("container_yard").get_node("SlidingGate") as Node3D)
			.global_position,
		"2_compound_gate": (world.get("compound").get_node("SlidingGate") as Node3D)
			.global_position,
	}
	for label: String in gates:
		var at: Vector3 = gates[label]
		for view: String in VIEWS:
			var eye: Vector3 = at + VIEWS[view][0]
			_camera.global_position = eye
			await create_timer(0.6, true, false, true).timeout
			_camera.look_at_from_position(eye, at + VIEWS[view][1])
			for frame in range(3):
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [label, view]))
	var sliding := [world.get("container_yard").get_node("SlidingGate"),
		world.get("compound").get_node("SlidingGate")]
	for index in range(sliding.size()):
		var gate := sliding[index] as Node3D
		gate.call("set_open", 2.5)
		gate.call("set_moving", true)
		var at := gate.global_position
		for view: String in ["machinery", "along", "inside_machinery"]:
			var eye: Vector3 = at + VIEWS[view][0]
			_camera.look_at_from_position(eye, at + VIEWS[view][1])
			await create_timer(0.35, true, false, true).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("%d_moving_%s.png"
				% [index + 1, view]))
		gate.call("set_moving", false)
		gate.call("set_open", 0.0)
	shed.call("set_barrier_moving", true)
	var arm := shed.get_node("BarrierArm") as Node3D
	arm.rotation.z = deg_to_rad(40.0)
	var gate_at: Vector3 = gates["0_shed_barrier"]
	for view: String in ["approach", "machinery"]:
		var eye: Vector3 = gate_at + VIEWS[view][0]
		_camera.look_at_from_position(eye, gate_at + VIEWS[view][1])
		await create_timer(0.35, true, false, true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("0_moving_%s.png" % view))
	quit(0)
