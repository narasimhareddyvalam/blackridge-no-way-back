extends SceneTree

## Take F: a small test scene (built here in code, not part of the game) with two upright
## quads side by side in front of a high-contrast diagonal-stripe backdrop, one
## DirectionalLight3D and a plain Environment, rendered at native 3840x2160 in the rig.
##   Left:  ShaderMaterial with res://shaders/standard_generated.gdshader (unchanged file)
##          and StandardMaterial3D-like values set explicitly (listed in the log).
##   Right: res://materials/windshield/light_fog.tres with fog_amount 1.0 set at runtime
##          on the loaded resource (never saved) so the fog is visible.
## Usage: Godot --path <copy> --fixed-fps 60 --audio-driver Dummy
##   --script res://capture_drivers/take_f_generated_vs_fog.gd -- <capture_dir>

const Rig = preload("res://capture_drivers/capture_rig.gd")
const SIZE := Vector2i(3840, 2160)
const GENERATED := "res://shaders/standard_generated.gdshader"
const LIGHT_FOG := "res://materials/windshield/light_fog.tres"
const FOG_COLOR := "res://assets/textures/windshield/fog_color.png"
const FOG_NORMAL := "res://assets/textures/windshield/fog_normal.png"
const SHOT_FRAME := 30
const QUAD_SIZE := Vector2(1.2, 1.5)

var rig: Rig
var capture_dir: String
var generated: ShaderMaterial
var fog: ShaderMaterial
var record := {}


func _initialize() -> void:
	capture_dir = OS.get_cmdline_user_args()[0]
	rig = Rig.new()
	rig.open_logs("take_f_generated_vs_fog", capture_dir, PackedStringArray())
	var scene := _build()
	rig.build(self, SIZE, Vector2i.ZERO, scene)
	rig.tick.connect(_tick)


func _build() -> Node3D:
	var root_3d := Node3D.new()
	root_3d.name = "GeneratedVsFog"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.03, 0.03, 0.035)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 0.25
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = false
	environment.fog_enabled = false
	var world := WorldEnvironment.new()
	world.environment = environment
	root_3d.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -30.0, 0.0)
	sun.light_color = Color(1, 1, 1)
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	root_3d.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 3.2)
	camera.fov = 40.0
	camera.current = true
	root_3d.add_child(camera)
	var backdrop := MeshInstance3D.new()
	var backdrop_mesh := QuadMesh.new()
	backdrop_mesh.size = Vector2(8.0, 4.5)
	backdrop.mesh = backdrop_mesh
	backdrop.position = Vector3(0, 0, -1.5)
	var stripes := StandardMaterial3D.new()
	stripes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stripes.albedo_texture = ImageTexture.create_from_image(_stripe_image())
	stripes.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	backdrop.material_override = stripes
	root_3d.add_child(backdrop)
	generated = ShaderMaterial.new()
	generated.shader = load(GENERATED)
	var generated_values := {
		"albedo": Color(1, 1, 1, 1),
		"texture_albedo": load(FOG_COLOR),
		"texture_normal": load(FOG_NORMAL),
		"roughness": 1.0,
		"metallic": 0.0,
		"specular": 0.5,
		"normal_scale": 1.0,
		"uv1_scale": Vector3(1, 1, 1),
		"uv1_offset": Vector3(0, 0, 0),
		"metallic_texture_channel": Vector4(1, 0, 0, 0),
	}
	for key in generated_values:
		generated.set_shader_parameter(key, generated_values[key])
	fog = load(LIGHT_FOG)
	var tres_amount: float = fog.get_shader_parameter("fog_amount")
	fog.set_shader_parameter("fog_amount", 1.0)
	root_3d.add_child(_quad("GeneratedQuad", Vector3(-0.75, 0, 0), generated))
	root_3d.add_child(_quad("FogQuad", Vector3(0.75, 0, 0), fog))
	record = {
		"scene": "built in code by take_f_generated_vs_fog.gd (not saved, not part of the game)",
		"environment": {"background_mode": "BG_COLOR", "background_color": "Color(0.03, 0.03, 0.035)",
			"ambient_light_source": "AMBIENT_SOURCE_COLOR", "ambient_light_color": "Color(1, 1, 1)",
			"ambient_light_energy": 0.25, "tonemap_mode": "TONE_MAPPER_LINEAR",
			"tonemap_exposure": 1.0, "glow_enabled": false, "fog_enabled": false},
		"directional_light": {"rotation_degrees": "(-35, -30, 0)", "light_color": "Color(1, 1, 1)",
			"light_energy": 1.0, "shadow_enabled": false},
		"camera": {"position": "(0, 0, 3.2)", "fov_deg": 40.0, "projection": "perspective"},
		"backdrop": {"mesh": "QuadMesh 8 x 4.5 at z = -1.5",
			"material": "StandardMaterial3D unshaded, nearest filter, 1600x900 diagonal stripes "
			+ "(48 px black / 48 px white)"},
		"quads": {"mesh": "QuadMesh %s x %s, upright, facing the camera" % [QUAD_SIZE.x,
			QUAD_SIZE.y], "left_position": "(-0.75, 0, 0)", "right_position": "(0.75, 0, 0)"},
		"left_generated": {"shader": GENERATED, "parameters_set": _describe(generated_values),
			"left_unset": ["texture_metallic (hint_default_white)",
				"texture_roughness (hint_roughness_r)", "albedo_texture_size", "point_size",
				"uv2_scale", "uv2_offset"]},
		"right_fog": {"material": LIGHT_FOG, "runtime_change": "fog_amount %s -> 1.0 (never saved)"
			% tres_amount, "values_now": _describe(_fog_values())},
	}
	return root_3d


func _quad(quad_name: String, at: Vector3, material: Material) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	quad.name = quad_name
	var mesh := QuadMesh.new()
	mesh.size = QUAD_SIZE
	quad.mesh = mesh
	quad.material_override = material
	quad.position = at
	return quad


func _stripe_image() -> Image:
	var image := Image.create(1600, 900, false, Image.FORMAT_RGB8)
	for y in range(900):
		for x in range(1600):
			var band := int(floor((x + y) / 48.0)) % 2
			image.set_pixel(x, y, Color(1, 1, 1) if band == 0 else Color(0, 0, 0))
	return image


func _fog_values() -> Dictionary:
	var out := {}
	for key in ["fog_amount", "fog_opacity", "clear_center", "edge_softness", "normal_strength",
			"texture_scale", "fog_tint", "fog_color", "fog_normal", "fog_data"]:
		out[key] = fog.get_shader_parameter(key)
	return out


func _describe(values: Dictionary) -> Dictionary:
	var out := {}
	for key in values:
		var value: Variant = values[key]
		out[key] = value.resource_path if value is Resource else str(value)
	return out


func _tick(frame: int) -> void:
	if frame == 1:
		rig.log_event({"kind": "test_scene", "record": record})
		var file := FileAccess.open(capture_dir.path_join("logs/generated_vs_fog_parameters.json"),
			FileAccess.WRITE)
		file.store_string(JSON.stringify(record, "  ", true) + "\n")
		file.close()
		rig.check(generated.shader.resource_path == GENERATED
			and generated.shader.get_shader_uniform_list().size() > 0,
			"Left quad uses %s and it parses" % GENERATED)
		rig.check(fog.resource_path == LIGHT_FOG and fog.get_shader_parameter("fog_amount") == 1.0,
			"Right quad uses light_fog.tres with fog_amount 1.0 (runtime only)")
	elif frame == SHOT_FRAME:
		rig.request_still("generated_vs_fog_4k.png")
	elif frame == SHOT_FRAME + 2:
		rig.finish({"record": record})
