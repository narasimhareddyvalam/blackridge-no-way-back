extends SceneTree
## The ending in play (#359, Mission 3's step 8): the reunion at the service gate, its cards, then
## the family home six months later, the watcher, black, the title; a still from each beat, timed
## by the scenes' own clocks. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_ending.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=4\n"
const NIGHT: Array = [[4.0, "01_reunion"], [12.0, "02_maya"], [19.5, "03_ethan"],
	[25.5, "04_police_lights"], [30.5, "05_statement"], [36.0, "06_six_months_later"]]
const HOME: Array = [[4.0, "07_home"], [10.0, "08_maya_and_ethan"], [13.5, "09_a_family"],
	[19.0, "10_uncle_ethan"], [24.5, "11_the_keys"], [31.0, "12_the_drive"],
	[39.0, "13_the_empty_driveway"], [48.0, "14_across_the_street"], [53.0, "15_the_watcher"],
	[65.5, "16_the_messages"], [71.0, "17_he_drives_away"], [74.0, "18_black"],
	[77.5, "19_the_title"]]

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
	var progress := OS.get_user_data_dir().path_join("capture_ending.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _wait(1.5)
	var run := _app.get("run") as Node
	var maya := run.get("maya") as Node3D
	var lily := run.get("lily") as Node3D
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var gate: Vector3 = field.get("service_gate")
	_app.call("_stand_ethan", gate + Vector3(0.5, 0.0, 1.5), maya.global_position)
	lily.call("go_to", maya.global_position + Vector3(0.6, 0.0, 0.4), maya.global_position)
	await _wait(1.0)
	run.set("story", "home")
	for still: Array in NIGHT:
		while float(run.get("_scene_clock")) < float(still[0]):
			await physics_frame
		await _save(String(still[1]))
	var epilogue: Node = null
	while epilogue == null:
		await physics_frame
		epilogue = run.get("epilogue") as Node
	for still: Array in HOME:
		while float(epilogue.get("_clock")) < float(still[0]):
			await physics_frame
		await _save(String(still[1]))
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
