extends SceneTree
## Mission 2's step 4: the container yard (`container_yard.gd`) in stills, on Mission 2's stage 1
## save: the gate from the driveway with the van at the stop line, the keypad at the driver's
## window, the lane between the blocks, the stacks corner on corner, the fence's barbed wire, the
## yard's masts from the road, and the bay with the dark van before the swap and after it (the
## mission's own swap, so its objective moves on with it). Run
## windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_container_yard.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const AT_THE_LINE := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.1, 165.3))
const BAY_POSE := Transform3D(Basis.IDENTITY, Vector3(95.0, 0.1, 138.0))
## Views: name, from, looking at, field of view.
const AT_THE_GATE := [["gate_from_the_driveway", Vector3(101.5, 2.0, 178.0),
		Vector3(100.0, 1.4, 158.0), 60.0],
	["keypad_at_the_window", Vector3(97.2, 1.7, 164.4), Vector3(98.4, 1.1, 162.0), 55.0]]
const IN_THE_YARD := [["the_lane", Vector3(100.0, 3.0, 156.5), Vector3(100.0, 1.5, 134.0), 70.0],
	["stacks_corner_on_corner", Vector3(93.6, 1.6, 152.0), Vector3(90.8, 4.0, 148.6), 60.0],
	["fence_and_barbed_wire", Vector3(66.5, 2.0, 154.5), Vector3(64.0, 2.6, 158.0), 55.0],
	["masts_from_the_road", Vector3(122.0, 3.0, 176.0), Vector3(100.0, 6.0, 145.0), 70.0]]
const AT_THE_BAY := ["bay_and_dark_van", Vector3(100.0, 4.0, 151.0), Vector3(99.5, 0.5, 138.5),
	65.0]

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_container_yard_progress.cfg")
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
	app.call("_begin")
	await create_timer(1.0, true, false, true).timeout
	var van := app.get_node("FreightVan") as CharacterBody3D
	var yard := app.get_node("IndustrialLoop").get("container_yard") as Node3D
	van.call("recover", AT_THE_LINE)
	await create_timer(1.5, true, false, true).timeout
	_camera = Camera3D.new()
	root.add_child(_camera)
	for view: Array in AT_THE_GATE + IN_THE_YARD:
		await _shoot(view, String(view[0]))
	van.call("recover", BAY_POSE)
	await create_timer(1.5, true, false, true).timeout
	await _shoot(AT_THE_BAY, "bay_and_dark_van_before_the_swap")
	app.get("cargo").call("_take_dark_van")
	await create_timer(1.5, true, false, true).timeout
	await _shoot(AT_THE_BAY, "bay_and_dark_van_after_the_swap")
	quit(0)


func _shoot(view: Array, name: String) -> void:
	_camera.fov = view[3]
	_camera.look_at_from_position(view[1], view[2])
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % name))
