extends SceneTree
## #283: how much road the low beams show, tried on the running game before any of it is
## written in. The van stands on the loop's first straight, 20 m short of the weathered SPEED
## LIMIT 45, low beams on; the still is from the driver's seat. The options, set on its two
## headlights (pattern, degrees down, reach in metres):
## R C45's beam (the pattern before C60, passed as its PNG), 2 down, 70, no haze: the reach
##   the author chose on November 3 ("C (Recommended)", #115);
## 1 now: the measured beam, 0.5 down, 70, the haze as the street lamps' (scattering 0.016);
## 2 the measured beam, 1 down, 70, haze;
## 3 the measured beam, 1.5 down, 70, haze;
## 4 the measured beam, 1 down, its light gone by 50 m, haze;
## 5 now without the haze; 6 1.5 down without the haze; 7 1.5 down with half the haze.
## For each it prints the road's brightness at the lane's centre every 10 m ahead, from the
## still (0-255, the mean of 5 x 5 pixels), and with the lights off. It changes no game file.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/trial_low_reach.gd -- <stills folder> <c45 pattern.png>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BACK := 10
const LANE := 1.1
const EYE := Vector3(-0.45, 2.05, -0.9)
const HAZE := 0.016
const AHEAD: Array[float] = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0]

var _out := ""
var _camera: Camera3D
var _van: Node3D
var _lights: Array[SpotLight3D] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var c45 := ImageTexture.create_from_image(Image.load_from_file(args[1]))
	var progress := OS.get_user_data_dir().path_join("trial_low_reach.cfg")
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
	for node in _van.find_children("*", "SpotLight3D", true, false):
		if (node as SpotLight3D).light_energy > 100.0:
			_lights.append(node)
	_camera = Camera3D.new()
	_camera.fov = 60.0
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
	var measured := _lights[0].light_projector
	var options := [["R", c45, -2.0, 70.0, 0.0], ["1", measured, -0.5, 70.0, 1.0],
		["2", measured, -1.0, 70.0, 1.0], ["3", measured, -1.5, 70.0, 1.0],
		["4", measured, -1.0, 50.0, 1.0], ["5", measured, -0.5, 70.0, 0.0],
		["6", measured, -1.5, 70.0, 0.0], ["7", measured, -1.5, 70.0, 0.5]]
	for option: Array in options:
		for light in _lights:
			light.light_projector = option[1]
			light.rotation_degrees.x = option[2]
			light.spot_range = option[3]
			(light.get_node("Mist").material_override as ShaderMaterial).set_shader_parameter(
				"pattern", option[1])
			(light.get_node("Mist").material_override as ShaderMaterial).set_shader_parameter(
				"light_range", option[3])
			(light.get_node("Mist").material_override as ShaderMaterial).set_shader_parameter(
				"scattering", HAZE * float(option[4]))
			light.get_node("Mist").visible = float(option[4]) > 0.0
		await _shot(String(option[0]), forward, right)
	_van.set("headlights_on", false)
	await create_timer(0.3, true, false, true).timeout
	await _shot("off", forward, right)
	quit(0)


func _shot(label: String, forward: Vector3, right: Vector3) -> void:
	var eye := _van.global_transform * EYE
	_camera.look_at_from_position(eye, eye + forward * 20.0 + Vector3.DOWN * 1.6)
	_camera.make_current()
	for frame in range(3):
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_out.path_join(label + ".png"))
	var values: Array[String] = []
	var lane := _van.global_position
	for metres in AHEAD:
		var spot := lane + forward * metres
		var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 5.0,
			spot + Vector3.DOWN * 5.0, 1, [_van.get_rid()])
		var hit := _van.get_world_3d().direct_space_state.intersect_ray(query)
		var ground: Vector3 = hit["position"] if not hit.is_empty() else spot
		var pixel := _camera.unproject_position(ground)
		var sum := 0.0
		var count := 0
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var at := Vector2i(int(pixel.x) + dx, int(pixel.y) + dy)
				if Rect2i(Vector2i.ZERO, image.get_size()).has_point(at):
					sum += image.get_pixelv(at).get_luminance()
					count += 1
		values.append("%dm:%d" % [int(metres), roundi(255.0 * sum / maxf(count, 1))])
	print("REACH %s %s" % [label, " ".join(values)])
