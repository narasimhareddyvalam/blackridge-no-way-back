extends SceneTree
## The van's tail lamps (#343, #344) in stills, from behind the van at night: as they were (one
## dull red over the lens, the converter's spikes cut from it), lit now as a tail lamp, braking
## (the real brake key held), with its left indicator on (its key) and reversing; and a close one.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_tail_lamps.gd -- <absolute stills folder>

const Build = preload("res://shared/components/mesh_builder.gd")
const EYE := Vector3(0.7, 1.45, 6.6)
const AT := Vector3(0.0, 1.1, 2.8)
const CLOSE_EYE := Vector3(-0.55, 1.2, 4.1)
const CLOSE_AT := Vector3(-0.88, 1.15, 2.75)

var _out := ""
var _van: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var save := OS.get_user_data_dir().path_join("capture_tail_lamps.cfg")
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = save
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	app.call("_resume")
	await create_timer(2.0, true, false, true).timeout
	_van = app.get_node("FreightVan") as Node3D
	var lamps := _van.find_child("TailLamps", true, false) as MeshInstance3D
	var lamp := lamps.material_override as ShaderMaterial
	_camera = Camera3D.new()
	_camera.fov = 40.0
	root.add_child(_camera)
	_camera.make_current()
	await _shot("2_tail_now", EYE, AT)
	await _shot("6_close_now", CLOSE_EYE, CLOSE_AT)
	Input.action_press("brake", 1.0)
	await create_timer(0.3, true, false, true).timeout
	await _shot("3_braking_now", EYE, AT)
	Input.action_release("brake")
	await create_timer(0.3, true, false, true).timeout
	await _key("indicator_left")
	var time := 0.0
	while float(lamp.get_shader_parameter("amber_left")) <= 0.0 and time < 2.0:
		await process_frame
		time += 1.0 / 60.0
	await _shot("4_indicator_now", EYE, AT)
	await _key("indicator_left")
	_van.set("gear", -1)
	await create_timer(0.3, true, false, true).timeout
	await _shot("5_reversing_now", EYE, AT)
	_van.set("gear", 1)
	await create_timer(0.3, true, false, true).timeout
	lamps.material_override = Build.luminous(Color("68251e"))
	for label in ["RearIndicatorLeft", "RearIndicatorRight"]:
		(_van.find_child(label, true, false) as MeshInstance3D).material_override = null
	await _shot("1_tail_before", EYE, AT)
	quit(0)


func _key(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _shot(label: String, eye: Vector3, at: Vector3) -> void:
	_camera.look_at_from_position(_van.to_global(eye), _van.to_global(at))
	for frame in range(4):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))
