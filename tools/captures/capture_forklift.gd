extends SceneTree
## The audit's second fix (#323-#324): the transfer shed's forklift in stills as it works, each
## taken when the moment comes: the cab in a turn (its steering wheel wound round, the driver's
## left hand on the spinner knob), its rear wheels steered in that turn, the load carried with the
## mast tilted back, the load set down in floor bay FS-01, and the driver backing, his chest
## turned and his right hand on the overhead guard's post. Run windowed, from the repository
## root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_forklift.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const NEAR := Vector3(-55.0, 4.0, 13.0)
## Shots as the truck's own offsets: name, the camera's place and where it looks, both in the
## truck's frame (its forks toward +z), and the field of view.
const CAB := ["cab_in_a_turn", Vector3(0.85, 1.95, 0.25), Vector3(0.0, 1.38, -0.42), 55.0]
const REAR_WHEELS := ["rear_wheels_steered", Vector3(-2.6, 0.7, -3.2), Vector3(0.0, 0.3, -1.5),
	55.0]
const TILTED := ["carrying_tilted_back", Vector3(3.4, 1.4, 0.6), Vector3(0.0, 1.0, 0.6), 50.0]
const BACKING := ["backing_looking_back", Vector3(-1.4, 2.3, 1.2), Vector3(0.0, 1.5, -0.8), 55.0]
const BAY_VIEW := ["load_in_floor_bay_FS-01", Vector3(-45.2, 3.4, 13.2), Vector3(-48.0, 1.3,
	9.1), 55.0]

var _out := ""
var _camera: Camera3D
var _taken := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_forklift_progress.cfg")
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
	var truck := app.get_node("IndustrialLoop").get("transfer_shed").get_node(
		"Building/Forklift") as Node3D
	_camera = Camera3D.new()
	root.add_child(_camera)
	_camera.global_position = NEAR
	_camera.make_current()
	var time := 0.0
	while time < 240.0 and _taken.size() < 5:
		await physics_frame
		time += 1.0 / 60.0
		var steer := absf(float(truck.call("steer")))
		var phase := String(truck.call("phase"))
		var speed := absf(float(truck.call("speed")))
		if not _taken.has("cab") and phase == "turn" and steer > 0.9 \
				and not bool(truck.call("reversing")):
			await _follow(truck, CAB)
			await _follow(truck, REAR_WHEELS)
			_taken["cab"] = true
		elif not _taken.has("tilted") and bool(truck.call("carrying")) and speed > 0.6 \
				and not bool(truck.call("reversing")) and phase != "turn":
			await _follow(truck, TILTED)
			_taken["tilted"] = true
		elif not _taken.has("backing") and bool(truck.call("reversing")) and speed > 0.6:
			await _follow(truck, BACKING)
			_taken["backing"] = true
		elif not _taken.has("bay") and phase == "from_bay" and int(truck.get("trips")) == 0:
			await _fixed(BAY_VIEW)
			_taken["bay"] = true
		elif not _taken.has("rest") and _taken.size() == 4:
			_taken["rest"] = true
		_camera.global_position = NEAR
		_camera.look_at(truck.global_position, Vector3.UP)
		_camera.make_current()
	quit(0)


func _follow(truck: Node3D, shot: Array) -> void:
	_camera.fov = shot[3]
	_camera.look_at_from_position(truck.to_global(shot[1]), truck.to_global(shot[2]))
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % shot[0]))


func _fixed(shot: Array) -> void:
	_camera.fov = shot[3]
	_camera.look_at_from_position(shot[1], shot[2])
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % shot[0]))
