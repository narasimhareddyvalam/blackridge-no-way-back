extends SceneTree
## Part G of step 5 of #253: the transfer shed at work in stills, on Mission 2's start save: the
## forklift's driver at the wheel, the truck backing out of dock 6's lane with its load (its rear
## blue spot lit), along the cross-aisle loaded, down aisle 03, creeping into the rack, and bay
## 9's dock worker scanning a pallet set down on the lift. Each still is taken as the truck
## reaches that part of its trip, in real time. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_shed_work.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## Stills by the truck's phase: name, phase, seconds into it, from, looking at, field of view.
const VIEWS := [["backing_out_with_its_load", "from_stage", 1.5, Vector3(-56.0, 2.9, 11.0),
		Vector3(-60.0, 1.6, 14.5), 60.0],
	["loaded_on_the_cross_aisle", "to_mouth", 1.5, Vector3(-68.5, 2.9, 13.6),
		Vector3(-62.0, 1.6, 12.0), 60.0],
	["down_aisle_03", "down_aisle", 2.0, Vector3(-66.3, 3.1, 13.5), Vector3(-66.1, 1.5, 7.0),
		55.0],
	["into_the_rack", "to_slot", 2.0, Vector3(-67.6, 2.6, 5.4), Vector3(-64.5, 1.5, 7.6), 60.0]]
const DRIVER_VIEW := [Vector3(-61.6, 2.5, 14.0), Vector3(-63.15, 2.2, 12.2), 45.0]
const SCAN_VIEW := [Vector3(-44.6, 2.9, 15.2), Vector3(-46.9, 1.9, 17.6), 55.0]

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_shed_work_progress.cfg")
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
	await create_timer(2.0, true, false, true).timeout
	var shed := app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var truck := shed.get_node("Building/Forklift") as Node3D
	_camera = Camera3D.new()
	root.add_child(_camera)
	await _still("driver_at_the_wheel", DRIVER_VIEW)
	for view: Array in VIEWS:
		while String(truck.call("phase")) != view[1]:
			await process_frame
		await create_timer(float(view[2]), true, false, true).timeout
		await _still(view[0], [view[3], view[4], view[5]])
	var load := shed.get_node("Building/Pallet6") as Node3D
	var lift := shed.get_node("Building/DockLift9") as Node3D
	var worker := shed.get("dock_worker") as Node3D
	load.global_position = lift.global_position
	while String(worker.get("state")) != "scanning":
		await process_frame
	await create_timer(1.0, true, false, true).timeout
	await _still("scanning_at_the_lift", SCAN_VIEW)
	quit(0)


func _still(label: String, view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % label))
