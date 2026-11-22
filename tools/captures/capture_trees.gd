extends SceneTree
## #280: the forest highway's roadside kinds in stills at night. For each kind (red alder, young
## Douglas fir, mountain hemlock, western red cedar) the roadside tree of that kind nearest the
## road's first kilometre is found; the van stands on the road 11 m short of the road's point
## nearest it, turned toward it as on a bend, high beams on, and the view is from just ahead of
## the van's front, 6 m ahead of its middle and 1 m to its left, at eye height, toward the
## tree's trunk 5 m up.
## Then the driver's seat on the first straight. With "price", the four kinds' instances (TRS),
## then only their near versions (TRN), far versions (TRF) and shadow casters (TRH), are
## shown and hidden in alternating blocks from the driver's seat for tools/tests/gpu_price.py
## (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1). Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_trees.gd -- <absolute stills folder> [price]

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const KINDS: Array[String] = ["red_alder", "young_fir", "mountain_hemlock", "western_red_cedar"]
const SHORT := 18.0
const LANE := 1.1
const EYE := 1.6
const AHEAD := 6.0
const DRIVER := Vector3(-0.45, 2.05, -0.9)
const CYCLES := 10
const BLOCK := 1.0
const SKIP := 0.3

var _out := ""
var _camera: Camera3D
var _van: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	var price := args.size() > 1 and args[1] == "price"
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_trees.cfg")
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
	var forest := world.get_node("RoadsideForest")
	_van = app.get_node("FreightVan") as Node3D
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	await create_timer(2.0, true, false, true).timeout
	var points: PackedVector3Array = world.get("road").points
	var placed: Dictionary = forest.get("species")
	if price:
		await _price(forest, points)
		quit(0)
		return
	for kind in KINDS:
		var best: Dictionary = {}
		var best_gap := INF
		for tree: Dictionary in placed.get(kind, []):
			var at: Vector3 = (tree["at"] as Transform3D).origin
			var index := _nearest(points, at, 0, 600)
			var gap := Vector2(at.x - points[index].x, at.z - points[index].z).length()
			if gap < best_gap:
				best_gap = gap
				best = {"at": at, "index": index}
		if best.is_empty():
			continue
		await _view(kind, best["at"], int(best["index"]), points)
	await _place(points, 40)
	var eye := _van.global_transform * DRIVER
	var forward := -_van.global_basis.z
	await _shot("driver", eye, eye + forward * 20.0 + Vector3.DOWN * 1.6)
	quit(0)


func _nearest(points: PackedVector3Array, at: Vector3, from: int, to: int) -> int:
	var best := from
	for index in range(from, mini(to, points.size())):
		if at.distance_squared_to(points[index]) < at.distance_squared_to(points[best]):
			best = index
	return best


func _place(points: PackedVector3Array, index: int) -> Vector3:
	var from := posmod(index, points.size())
	var ahead := points[(from + 1) % points.size()] - points[from]
	var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := forward.cross(Vector3.UP)
	_van.call("recover", Transform3D(Basis.looking_at(forward, Vector3.UP),
		points[from] + right * LANE))
	await create_timer(0.6, true, false, true).timeout
	return forward


func _view(kind: String, at: Vector3, index: int, points: PackedVector3Array) -> void:
	var road := points[index]
	var toward := Vector3(at.x - road.x, 0.0, at.z - road.z).normalized()
	var along := Vector3(points[(index + 1) % points.size()] - road)
	along = Vector3(along.x, 0.0, along.z).normalized()
	var heading := (toward + along * 2.0).normalized()
	var stand := road - along * SHORT * 0.6
	_van.call("recover", Transform3D(Basis.looking_at(heading, Vector3.UP), stand))
	await create_timer(0.6, true, false, true).timeout
	_van.set("high_beams", true)
	await create_timer(0.3, true, false, true).timeout
	var eye := _van.global_position - _van.global_basis.z * AHEAD + _van.global_basis.x * -1.0 \
		+ Vector3.UP * EYE
	await _shot(kind, eye, at + Vector3.UP * 5.0)
	_van.set("high_beams", false)


func _shot(label: String, from: Vector3, toward: Vector3) -> void:
	_camera.look_at_from_position(from, toward)
	_camera.make_current()
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))


func _price(forest: Node, points: PackedVector3Array) -> void:
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f" % [root.get_visible_rect().size,
		DisplayServer.window_get_vsync_mode(), root.scaling_3d_scale])
	await _place(points, 40)
	var eye := _van.global_transform * DRIVER
	_camera.look_at_from_position(eye, eye - _van.global_basis.z * 20.0 + Vector3.DOWN * 1.6)
	_camera.make_current()
	var instances: Array[MultiMeshInstance3D] = []
	for node in forest.get_children():
		if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null \
				and not (node as MultiMeshInstance3D).multimesh.use_colors:
			instances.append(node)
	var near := instances.filter(func(instance: MultiMeshInstance3D) -> bool:
		return instance.visibility_range_begin == 0.0 \
			and instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
			and instance.visibility_range_end < 50.0)
	var shadows := instances.filter(func(instance: MultiMeshInstance3D) -> bool:
		return instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	var far := instances.filter(func(instance: MultiMeshInstance3D) -> bool:
		return instance.visibility_range_begin > 0.0)
	for step: Array in [["TRS", instances], ["TRN", near], ["TRF", far], ["TRH", shadows]]:
		for cycle in range(CYCLES):
			for shown in [true, false]:
				for instance: MultiMeshInstance3D in step[1]:
					instance.visible = shown
				var began := Time.get_unix_time_from_system()
				await create_timer(BLOCK, true, false, true).timeout
				var ended := Time.get_unix_time_from_system()
				print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles 0|%s|-"
					% [step[0], "on" if shown else "off", cycle + 1, began, ended, SKIP,
					"driver, %d" % (step[1] as Array).size()])
		for instance in instances:
			instance.visible = true
	print("GPU PRICE DONE")
