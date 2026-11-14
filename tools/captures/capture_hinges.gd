extends SceneTree
## The van's rear-door hinges (#258-#259) in stills: the van stopped in the depot's open court on
## Mission 2's start save, its doors shut, then swung open to their stays, each view from close
## beside a rear corner. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_hinges.gd \
##     -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const COURT := Vector3(-47.75, 0.1, 31.0)
## Views in the van's own frame (x to its left side, +z behind it): where, what at, field.
const VIEWS := [["right_corner", Vector3(1.9, 1.35, 4.0), Vector3(0.85, 1.05, 2.9), 40.0],
	["right_close", Vector3(1.45, 1.75, 3.55), Vector3(0.95, 1.6, 2.95), 30.0],
	["left_corner", Vector3(-1.9, 1.35, 4.0), Vector3(-0.85, 1.05, 2.9), 40.0],
	["right_side", Vector3(2.6, 1.3, 1.6), Vector3(1.05, 1.05, 2.4), 45.0]]

var _app: Node3D
var _van: Node3D
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_hinges_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	await process_frame
	_app.call("_begin")
	_van = _app.get_node("FreightVan")
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT))
	await _seconds(1.5)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	await _shots(camera, "shut")
	_van.set("rear_doors_open", true)
	await _seconds(5.0)
	await _shots(camera, "open")
	await _hinge_shots(camera, "open")
	_van.set("rear_doors_open", false)
	await _seconds(5.0)
	await _hinge_shots(camera, "shut")
	quit(0)


## Each hinge from 0.45 m behind and outside it, looking at its pin: the door's rotation printed.
func _hinge_shots(camera: Camera3D, state: String) -> void:
	var look: Node3D = _van.get("_visual")
	for index in range(2):
		var door: Node3D = look.call("rear_door", index)
		print("%s door %d turned %.1f degrees" % [state, index, rad_to_deg(door.rotation.y)])
		var outward := 1.0 if index == 1 else -1.0
		for height: float in [0.52, 1.65]:
			var pin: Vector3 = door.get_parent().to_global(Vector3(door.position.x, height,
				door.position.z))
			var from: Vector3 = pin + _van.global_basis * Vector3(outward * 0.35, 0.08, 0.3)
			camera.fov = 35.0
			camera.look_at_from_position(from, pin)
			camera.make_current()
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("hinge_%s_%d_%d.png"
				% [state, index, int(height * 100)]))


func _shots(camera: Camera3D, state: String) -> void:
	for view: Array in VIEWS:
		camera.fov = view[3]
		camera.look_at_from_position(_van.to_global(view[1]), _van.to_global(view[2]))
		camera.make_current()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(_out.path_join("%s_%s.png" % [state, view[0]]))


func _seconds(duration: float) -> void:
	await create_timer(duration, true, false, true).timeout
