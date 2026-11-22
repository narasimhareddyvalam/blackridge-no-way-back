extends SceneTree
## Part B of #267: the forest highway's new roadside in stills at night, lit as a driver lights
## it: the van set on the road 20 m short of each item, in its lane, facing along the road with
## its own headlights on, and the view from 6 m short of the item, at eye height, a step toward
## its side of the road. The items: the weathered SPEED LIMIT 45, a deer
## crossing, mile 1, the branch at the asphalt's edge, the gallon jug, the bottle, the lay-by's
## bin, and the valley's delineators ahead. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_roadside.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BACK := 10
const VIEW_BACK := 3
const LANE := 1.1
const EYE := 1.6

var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_roadside_progress.cfg")
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
	var road: RefCounted = world.get("road")
	var dressing: Node3D = world.get("dressing")
	var van := app.get_node("FreightVan") as Node3D
	var targets: Array[Array] = []
	for sign: Dictionary in dressing.get("signs"):
		var kind := String(sign["kind"])
		if kind in ["limit_45_weathered", "mile_1"] or (kind == "deer_crossing"
				and not targets.any(func(t: Array) -> bool: return t[0] == "deer_crossing")):
			targets.append([kind, int(sign["index"]), sign["at"]])
	for item: Dictionary in dressing.get("roadside"):
		var label := String(item.get("asset", item["kind"]))
		if label in ["branch", "plastic_bottle_gallon", "wine_bottles_01", "bin"] \
				and not targets.any(func(t: Array) -> bool: return t[0] == label):
			targets.append([label, int(item["index"]), item["at"]])
	var valley: Array = dressing.get("valley_delineators")
	if not valley.is_empty():
		targets.append(["valley_delineators", 1100, (valley[valley.size() / 2] as Vector3)])
	var camera := Camera3D.new()
	camera.fov = 60.0
	root.add_child(camera)
	await create_timer(2.0, true, false, true).timeout
	var points: PackedVector3Array = road.points
	for target in targets:
		var index: int = target[1]
		var from := posmod(index - BACK, points.size())
		var ahead := points[(from + 1) % points.size()] - points[from]
		var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
		var right := forward.cross(Vector3.UP)
		var spot := points[from] + right * LANE
		van.call("recover", Transform3D(Basis.looking_at(forward, Vector3.UP), spot))
		await create_timer(0.6, true, false, true).timeout
		var at: Vector3 = target[2]
		var near := posmod(index - VIEW_BACK, points.size())
		var toward := signf((at - points[near]).dot(right))
		var eye := points[near] + right * toward * LANE + Vector3.UP * EYE
		camera.look_at_from_position(eye, at + Vector3.UP * 0.8)
		camera.make_current()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("%s.png" % target[0]))
	quit(0)
