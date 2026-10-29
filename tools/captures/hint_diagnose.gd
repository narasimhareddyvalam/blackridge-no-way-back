extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := (load("res://experiments/hint_experiment/hint_experiment.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var separate := ImageTexture.create_from_image(
		Image.load_from_file("res://experiments/hint_experiment/greys_3x1.png"))
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/hint_experiment.gdshader")
	material.set_shader_parameter("data_read", separate)
	material.set_shader_parameter("show_data", true)
	var quad: MeshInstance3D = scene.get_node("AsData")
	quad.material_override = material
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var row := PackedStringArray()
	for x in [473, 640, 806]:
		var pixel := image.get_pixel(x, 550)
		row.append("%d" % pixel.r8)
	print("%s, data-only separate texture: %s" % [RenderingServer.get_current_rendering_method(), ", ".join(row)])
	quit(0)
