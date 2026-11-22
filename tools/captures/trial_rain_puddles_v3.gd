extends SceneTree
## #273: Rain Puddles V3 (`game/experiments/rain_puddles_v3/`, GloriousGlider8, MIT) tried as it
## comes on the ground at three places: A the dock apron by the court, R the valley road under the
## town lamp, D the freight depot's yard. Each ground mesh there is given the shader at run time
## (Poly Haven's worn concrete floor under the apron, its asphalt 02 under the road and the yard,
## at the meshes' own UVs in metres; the shader's defaults); its GPU time is logged in alternating
## blocks for tools/tests/gpu_price.py (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1), then a still of
## each place as it is and with the shader. It changes no game file. Run windowed:
##   MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 HOME="$PWD/.scratch-home" Godot --path game \
##     --resolution 1280x800 --script ../tools/captures/trial_rain_puddles_v3.gd -- <stills folder>

const SHADER := "res://experiments/rain_puddles_v3/rain_puddles_v3.gdshader"
const RIPPLES := "res://experiments/rain_puddles_v3/ripple_data.png"
const TEXTURES := "res://features/environments/depot_yard/polyhaven/textures/%s/%s_%s_2k.jpg"
const SETTLE := 3.0
const CYCLES := 14
const BLOCK := 1.0
const SKIP := 0.3
## Each place: the view (from, at, field), a point on its ground, and the ground's texture.
const PLACES := {"A": [Vector3(-58.0, 1.7, 30.0), Vector3(-54.0, 0.2, 22.0), 55.0,
		Vector2(-54.0, 24.0), "concrete_floor_worn_001"],
	"R": [Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0, Vector2(-15.0, 66.0),
		"asphalt_02"],
	"D": [Vector3(-24.0, 1.7, 92.0), Vector3(-30.0, 0.0, 104.0), 60.0, Vector2(-30.0, 100.0),
		"asphalt_02"]}

var _app: Node3D
var _camera: Camera3D
var _grounds := {}
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	var world: Node3D = _app.get_node("IndustrialLoop")
	var puddles := _noise(false)
	var wind := _noise(true)
	await _wait(1.0)
	for place: String in PLACES:
		var spot: Vector2 = PLACES[place][3]
		var mesh := _ground_at(world, spot, place == "R")
		if mesh == null:
			print("TRIAL: no ground mesh at %s" % spot)
			continue
		_grounds[place] = [mesh, mesh.material_override, _material(PLACES[place][4], puddles,
			wind)]
		print("TRIAL: %s ground %s" % [place, world.get_path_to(mesh)])
	_camera = Camera3D.new()
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f" % [root.get_visible_rect().size,
		DisplayServer.window_get_vsync_mode(), root.scaling_3d_scale])
	for place: String in _grounds:
		var view: Array = PLACES[place]
		_camera.fov = view[2]
		_camera.look_at_from_position(view[0], view[1], Vector3.UP)
		_camera.make_current()
		await _wait(1.0)
		for cycle in range(CYCLES):
			for shown: bool in [true, false]:
				DisplayServer.window_move_to_foreground()
				_use(place, shown)
				var began := Time.get_unix_time_from_system()
				await _wait(BLOCK)
				var ended := Time.get_unix_time_from_system()
				print("GPU PRICE BLOCK|%sV3|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles 0|%s|-"
					% [place, "on" if shown else "off", cycle + 1, began, ended, SKIP, place])
		for shown: bool in [false, true]:
			_use(place, shown)
			await _wait(0.8)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [place,
				"v3" if shown else "now"]))
		_use(place, false)
	print("GPU PRICE DONE")
	quit()


func _use(place: String, on: bool) -> void:
	var entry: Array = _grounds[place]
	(entry[0] as MeshInstance3D).material_override = entry[2] if on else entry[1]


## The ground mesh under `spot`: on the road, the road's (drawn by `wet_asphalt.gdshader`); else
## the largest flat mesh near y 0 whose box holds it (not a painted line on it, nor the road).
func _ground_at(world: Node3D, spot: Vector2, road: bool) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var largest := 5.0
	for found in world.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		if box.position.x > spot.x or box.end.x < spot.x or box.position.z > spot.y \
				or box.end.z < spot.y:
			continue
		var paint := mesh.get_active_material(0) as ShaderMaterial
		var asphalt := paint != null and paint.shader != null \
			and paint.shader.resource_path.ends_with("wet_asphalt.gdshader")
		if road:
			if asphalt:
				return mesh
			continue
		if box.position.y > -1.0 and box.end.y < 0.6 and box.size.y < 1.0 \
				and box.size.x * box.size.z > largest:
			largest = box.size.x * box.size.z
			best = mesh
	return best


func _material(asset: String, puddles: Texture2D, wind: Texture2D) -> ShaderMaterial:
	var made := ShaderMaterial.new()
	made.shader = load(SHADER)
	made.set_shader_parameter("base_albedo", load(TEXTURES % [asset, asset, "diff"]))
	made.set_shader_parameter("base_normal", load(TEXTURES % [asset, asset, "nor_gl"]))
	made.set_shader_parameter("base_roughness", load(TEXTURES % [asset, asset, "arm"]))
	made.set_shader_parameter("base_aoc", load(TEXTURES % [asset, asset, "arm"]))
	made.set_shader_parameter("base_metallic", _flat(0.0))
	made.set_shader_parameter("base_emission", _flat(0.0))
	made.set_shader_parameter("base_specular", _flat(0.5))
	made.set_shader_parameter("puddle_noise", puddles)
	made.set_shader_parameter("wind_normal_noise", wind)
	made.set_shader_parameter("rain_ripples_data", load(RIPPLES))
	return made


func _noise(normal: bool) -> NoiseTexture2D:
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.as_normal_map = normal
	var noise := FastNoiseLite.new()
	noise.frequency = 0.01
	texture.noise = noise
	return texture


func _flat(value: float) -> ImageTexture:
	var image := Image.create(1, 1, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, Color(value, value, value))
	return ImageTexture.create_from_image(image)


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
