extends SceneTree
## Step 3 of #253, part 2: bay 9's dock worker at his desk and on his round to seal the van, in
## stills. The van stands docked at bay 9 with its doors shut; he is sent as the shed sends him;
## each still is taken when he reaches a part of his round, from inside the shed over the lane
## at the desk and from the dock floor by bay 9's lift pit at the doors, looking at him: seated (and from the yard through bay 9's doorway), standing up, walking
## with the log, on the stair, sealing, checking, noting, sitting down and seated again.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_dock_worker.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const YARD_EYE := Vector3(-47.5, 1.7, 21.6)
## Inside the shed over the lane, looking across the dock floor at the desk; and in the yard
## on the dock floor west of bay 9's lift pit, where he stands to seal the doors at the dock face.
const INSIDE_EYE := Vector3(-44.4, 2.9, 16.6)
const AT_THE_DOORS := Vector3(-49.3, 2.1, 18.0)

var _out := ""
var _camera: Camera3D
var _worker: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_dock_worker.cfg")
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
	var shed := app.find_child("TransferShed", true, false)
	_worker = shed.find_child("DockWorker", true, false) as Node3D
	var van := app.get_node("FreightVan") as Node3D
	_camera = Camera3D.new()
	_camera.fov = 55.0
	root.add_child(_camera)
	await create_timer(2.0, true, false, true).timeout
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	van.set("rear_doors_open", false)
	await create_timer(1.0, true, false, true).timeout
	await _shot("1_seated", INSIDE_EYE)
	_camera.look_at_from_position(YARD_EYE, _worker.global_position + Vector3.UP * 1.0)
	await _frame("2_seated_from_the_yard")
	shed.call("call_dock_hand", van, "SL483201")
	var wanted := {"standing": "3_standing_up", "out": "4_walking_with_the_log",
		"sealing": "6_sealing", "checking": "7_checking", "noting": "8_noting",
		"sitting": "9_sitting_down"}
	var stair_taken := false
	var time := 0.0
	while time < 75.0 and not wanted.is_empty():
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		var state := String(_worker.get("state"))
		if not stair_taken and state == "out" and _worker.global_position.y < 0.9 \
				and _worker.global_position.y > 0.3:
			stair_taken = true
			await _shot("5_on_the_stair", _worker.global_position + Vector3(2.2, 1.6, -1.2))
		if wanted.has(state):
			var label: String = wanted[state]
			wanted.erase(state)
			if state == "out" or state == "standing" or state == "sitting":
				await create_timer(1.2, true, false, true).timeout
			else:
				await create_timer(1.0, true, false, true).timeout
			var eye := AT_THE_DOORS if state in ["sealing", "checking", "noting"] \
				else INSIDE_EYE
			await _shot(label, eye)
	await create_timer(5.0, true, false, true).timeout
	await _shot("10_seated_again", INSIDE_EYE)
	quit(0)


func _shot(label: String, eye: Vector3) -> void:
	_camera.look_at_from_position(eye, _worker.global_position + Vector3.UP * 1.0)
	await _frame(label)


func _frame(label: String) -> void:
	_camera.make_current()
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))
