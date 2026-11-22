extends SceneTree
## #280: the tree trunks that turn white where the low beams strike them, tried on the running
## game before anything is written in. Each option is set on the van's own two headlights and
## the scene's environment (the beam's rain takes the lamps' pattern itself), then three stills: T the weathered SPEED LIMIT 45 with the trunks
## behind it, F the ferns and trunks at mile 1, D the driver's seat on the road there. Options:
## 1 now;
## 2 real side fall-off: the low beam's pattern with ECE R112 class B's spread, about a fifth of
##   the hot spot at 9 degrees to each side (25L, 25R), where now it is still full
##   (made by a trial-only copy of tools/make_low_beam_pattern.py, passed as its PNG);
## 3 more headroom: AgX's white point raised, so the brightest lit things keep their colour;
## 4 both.
## It prints each still's mean colour on the headlit trunks and on the road ahead, and changes no
## game file. Run windowed:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/trial_headlit_trunks.gd -- <stills folder> <pattern.png> <white>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BACK := 10
const VIEW_BACK := 3
const LANE := 1.1
const EYE := 1.6
const TRUNK_SAMPLE := 0.7
const NEAR_TRUNKS := 40.0

var _out := ""
var _camera: Camera3D
var _van: Node3D
var _world: Node3D
var _lights: Array[SpotLight3D] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var real_sides := ImageTexture.create_from_image(Image.load_from_file(args[1]))
	var white := float(args[2])
	var progress := OS.get_user_data_dir().path_join("trial_headlit_trunks.cfg")
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
	_world = app.get_node("IndustrialLoop") as Node3D
	_van = app.get_node("FreightVan") as Node3D
	for node in _van.find_children("*", "SpotLight3D", true, false):
		var light := node as SpotLight3D
		if light.light_energy > 100.0:
			_lights.append(light)
	var environment := (_world.find_children("*", "WorldEnvironment", true, false)[0]
		as WorldEnvironment).environment
	var pattern := _lights[0].light_projector
	var normal_white := environment.tonemap_white
	print("TRIAL white now %.2f, trial %.2f, headlights %d" % [normal_white, white,
		_lights.size()])
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	await create_timer(2.0, true, false, true).timeout
	var options := [["1", pattern, normal_white], ["2", real_sides, normal_white],
		["3", pattern, white], ["4", real_sides, white]]
	for option: Array in options:
		for light in _lights:
			light.light_projector = option[1]
		environment.tonemap_white = option[2]
		for view in ["T", "F", "D"]:
			await _view(view, String(option[0]))
	quit(0)


func _view(view: String, option: String) -> void:
	var dressing: Node3D = _world.get("dressing")
	var road: RefCounted = _world.get("road")
	var kind := "limit_45_weathered" if view == "T" else "mile_1"
	var index := 0
	var at := Vector3.ZERO
	for sign: Dictionary in dressing.get("signs"):
		if String(sign["kind"]) == kind:
			index = int(sign["index"])
			at = sign["at"]
	var points: PackedVector3Array = road.points
	var from := posmod(index - BACK, points.size())
	var ahead := points[(from + 1) % points.size()] - points[from]
	var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := forward.cross(Vector3.UP)
	_van.call("recover", Transform3D(Basis.looking_at(forward, Vector3.UP),
		points[from] + right * LANE))
	await create_timer(0.6, true, false, true).timeout
	if view == "D":
		var eye := _van.global_transform * Vector3(-0.45, 2.05, -0.9)
		_camera.look_at_from_position(eye, eye + forward * 20.0 + Vector3.DOWN * 1.6)
	else:
		var near := posmod(index - VIEW_BACK, points.size())
		var toward := signf((at - points[near]).dot(right))
		_camera.look_at_from_position(points[near] + right * toward * LANE + Vector3.UP * EYE,
			at + Vector3.UP * 0.8)
	_camera.make_current()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_out.path_join("%s_%s.png" % [option, view]))
	var road_ahead := _van.global_position + forward * 15.0
	print("TRIAL %s %s trunks %s road %s" % [option, view, _mean(image, _trunks()),
		_mean(image, [Vector3(road_ahead.x, points[index].y + 0.05, road_ahead.z)])])


func _trunks() -> Array:
	var found := []
	var forest: Node3D = _world.get("forest")
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape in body.get_children():
				var spot: Vector3 = (shape as CollisionShape3D).global_position
				var base := Vector3(spot.x, spot.y - 3.0 + TRUNK_SAMPLE, spot.z)
				if not _camera.is_position_behind(base) \
						and base.distance_to(_camera.global_position) < NEAR_TRUNKS \
						and base.distance_to(_van.global_position) < NEAR_TRUNKS:
					found.append(base)
	return found


func _mean(image: Image, places: Array) -> String:
	var values: Array[float] = []
	var sum := Color(0, 0, 0)
	for place: Vector3 in places:
		var pixel := _camera.unproject_position(place)
		if not Rect2(2, 2, image.get_width() - 4, image.get_height() - 4).has_point(pixel):
			continue
		var colour := image.get_pixelv(Vector2i(pixel))
		values.append(colour.get_luminance())
		sum += colour
	if values.is_empty():
		return "none"
	values.sort()
	sum /= float(values.size())
	return "n %d mean (%d,%d,%d) brightest %d" % [values.size(), sum.r8, sum.g8, sum.b8,
		roundi(values[-1] * 255.0)]
