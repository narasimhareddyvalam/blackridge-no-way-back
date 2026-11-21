extends SceneTree
## The guard sliding her booth's service window (#348): she leans in from her chair, takes the
## sash's pull with her left hand, slides it open and lets go, then slides it shut. Filmed at each
## booth from the driver's place at the window and, at the shed's, from inside behind her. Run
## windowed with Movie Maker, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 --fixed-fps 30 \
##     --write-movie <absolute .avi> --script ../tools/captures/film_booth_window.gd

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## In the booth's frame: the driver's place at the window, and inside behind her left shoulder.
const OUTSIDE := [Vector3(2.4, 1.75, 0.2), Vector3(0.9, 1.35, 0.05)]
const INSIDE := [Vector3(0.05, 1.8, -0.75), Vector3(1.15, 1.3, 0.0)]
const HOLD := 4.0

var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("film_booth_window.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	await process_frame
	await process_frame
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await create_timer(1.0).timeout
	_camera = Camera3D.new()
	_camera.fov = 55.0
	root.add_child(_camera)
	_camera.make_current()
	var world := app.get_node("IndustrialLoop")
	var shed := world.get("transfer_shed").get_node("GuardBooth") as Node3D
	var compound := world.get("compound").get_node("GuardBooth") as Node3D
	await _slide(shed, OUTSIDE)
	await _slide(shed, INSIDE)
	await _slide(compound, OUTSIDE)
	quit(0)


func _slide(booth: Node3D, view: Array) -> void:
	_camera.look_at_from_position(booth.to_global(view[0]), booth.to_global(view[1]))
	await create_timer(0.8).timeout
	for open in [true, false]:
		booth.call("open_window", open)
		await create_timer(HOLD).timeout
