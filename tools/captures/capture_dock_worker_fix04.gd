extends SceneTree
## The audit's fourth fix (#329): bay 9's dock worker in stills, each taken when the moment comes:
## going down the dock stair a tread a step, his left hand on the rail and the seal log in his
## right; the bolt seal in his hand at the van's hasp; noting in the log with a pen; and his
## scanner's red aiming line on a load's shipping label. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_dock_worker_fix04.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const NUMBER := "SL483201"
const DECK_MIDDLE := Vector3(-47.75, 1.3, 18.52)
## Shots in metres in his own frame (his front ahead, his left across, up): the camera's place,
## where it looks, the field of view.
const STAIR := ["down_the_stair_hand_on_rail", Vector3(-1.6, 1.3, 1.6), Vector3(0.0, 0.7, 0.0),
	50.0]
const SEAL := ["the_seal_in_his_hand", Vector3(1.4, 1.5, 0.1), Vector3(0.0, 1.1, 0.3), 45.0]
const NOTE := ["noting_with_a_pen", Vector3(1.3, 1.6, 0.3), Vector3(0.0, 1.15, 0.25), 40.0]
const SCAN := ["aiming_at_the_label", Vector3(1.4, 1.6, -0.6), Vector3(0.0, 1.0, 0.8), 50.0]

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_dock_worker_progress.cfg")
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
	app.call("_resume")
	await physics_frame
	var shed := app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var worker := shed.find_child("DockWorker", true, false) as Node3D
	var model := worker.get_node("Model") as Node3D
	var van := app.get_node("FreightVan") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	van.set("rear_doors_open", false)
	for frame in range(10):
		await physics_frame
	_camera = Camera3D.new()
	root.add_child(_camera)
	shed.call("call_dock_hand", van, NUMBER)
	var taken := {}
	var time := 0.0
	while time < 90.0 and taken.size() < 3:
		await physics_frame
		time += 1.0 / 60.0
		var at := worker.global_position
		var on_flight := at.x > -44.3 and at.x < -43.7 and at.z > 14.2 and at.z < 14.8 \
			and String(worker.get("state")) == "out"
		if on_flight and not taken.has("stair"):
			await _shot(model, STAIR)
			taken["stair"] = true
		elif String(worker.get("state")) == "sealing" and float(worker.get("_timer")) > 2.0 \
				and not taken.has("seal"):
			await _shot(model, SEAL)
			taken["seal"] = true
		elif String(worker.get("state")) == "noting" and float(worker.get("_timer")) > 1.0 \
				and not taken.has("note"):
			await _shot(model, NOTE)
			taken["note"] = true
	while not bool(worker.get("home")) and time < 160.0:
		await physics_frame
		time += 1.0 / 60.0
	for frame in range(300):
		await physics_frame
	var load := shed.get_node("Building/Pallet6") as Node3D
	load.global_position = DECK_MIDDLE
	worker.call("go_scan", load)
	time = 0.0
	while time < 20.0:
		await physics_frame
		time += 1.0 / 60.0
		var line := worker.find_child("AimLine", true, false) as Node3D
		if line != null and line.visible:
			await _shot(model, SCAN)
			break
	quit(0)


func _shot(model: Node3D, shot: Array) -> void:
	var ahead := model.global_basis.z
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var frame := Basis(Vector3.UP.cross(ahead), Vector3.UP, ahead)
	var at := model.global_position
	_camera.fov = shot[3]
	_camera.look_at_from_position(at + frame * (shot[1] as Vector3), at + frame * (shot[2]
		as Vector3))
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % shot[0]))
	_camera.clear_current()
