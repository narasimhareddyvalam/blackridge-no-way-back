extends SceneTree
## #282: the headlamps and their beams in stills at night. The van stands on the loop's first
## straight, 20 m short of the weathered SPEED LIMIT 45. Views: the driver's-side headlamp from
## 1.6 m ahead (F) and from the side (S), the driver's seat (D) and the van from 7 m ahead (O),
## each with the low beams, the high beams and the lights off. Run windowed, from the repository
## root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_headlights.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BACK := 10
const LANE := 1.1
const LAMP := Vector3(-0.64, 1.15, -2.31)
const EYE := Vector3(-0.45, 2.05, -0.9)

var _out := ""
var _camera: Camera3D
var _van: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_headlights.cfg")
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
	var world := app.get_node("IndustrialLoop") as Node3D
	_van = app.get_node("FreightVan") as Node3D
	_camera = Camera3D.new()
	root.add_child(_camera)
	await create_timer(2.0, true, false, true).timeout
	var index := 0
	for sign: Dictionary in world.get("dressing").get("signs"):
		if String(sign["kind"]) == "limit_45_weathered":
			index = int(sign["index"])
	var points: PackedVector3Array = world.get("road").points
	var from := posmod(index - BACK, points.size())
	var ahead := points[(from + 1) % points.size()] - points[from]
	var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := forward.cross(Vector3.UP)
	_van.call("recover", Transform3D(Basis.looking_at(forward, Vector3.UP),
		points[from] + right * LANE))
	await create_timer(0.6, true, false, true).timeout
	for state in ["low", "high", "off"]:
		_van.set("headlights_on", state != "off")
		_van.set("high_beams", state == "high")
		await create_timer(0.4, true, false, true).timeout
		var lamp := _van.global_transform * LAMP
		await _shot("F_" + state, 35.0, lamp + forward * 1.6 + Vector3.UP * 0.1, lamp)
		await _shot("S_" + state, 35.0, lamp + forward * 0.9 - right * 1.2 + Vector3.UP * 0.15,
			lamp)
		var eye := _van.global_transform * EYE
		await _shot("D_" + state, 60.0, eye, eye + forward * 20.0 + Vector3.DOWN * 1.6)
		await _shot("O_" + state, 60.0, _van.global_position + forward * 7.0 + right * 2.5
			+ Vector3.UP * 1.3, _van.global_position + Vector3.UP * 1.1 + forward * 1.5)
	quit(0)


func _shot(label: String, fov: float, from: Vector3, at: Vector3) -> void:
	_camera.fov = fov
	_camera.look_at_from_position(from, at)
	_camera.make_current()
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))
