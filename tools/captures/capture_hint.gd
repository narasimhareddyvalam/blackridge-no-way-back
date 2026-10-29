extends SceneTree

const SCENE := "res://experiments/hint_experiment/hint_experiment.tscn"
const QUADS: Array[String] = ["AsColor", "AsData"]
const BAND_WIDTH := 0.5


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://").path_join("../evidence/captures")
	DirAccess.make_dir_recursive_absolute(folder)
	image.save_png(folder.path_join("hint_experiment.png"))
	var scale := Vector2(image.get_size()) / root.get_visible_rect().size
	var camera: Camera3D = scene.get_node("Camera3D")
	var report := PackedStringArray()
	report.append("renderer=%s image=%dx%d" % [
		RenderingServer.get_current_rendering_method(), image.get_width(), image.get_height()])
	for quad_name in QUADS:
		var quad: MeshInstance3D = scene.get_node(quad_name)
		var bands := PackedStringArray()
		for band in range(3):
			var local := Vector3(-0.75 + BAND_WIDTH * (band + 0.5), 0.0, 0.0)
			var at := Vector2i(camera.unproject_position(quad.to_global(local)) * scale)
			var pixel := image.get_pixelv(at)
			bands.append("band %d at %s = (%d, %d, %d)" % [band + 1, at, pixel.r8, pixel.g8,
				pixel.b8])
		report.append("%s: %s" % [quad_name, "; ".join(bands)])
	var text := "\n".join(report)
	print(text)
	var file := FileAccess.open(folder.path_join("hint_experiment_samples.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)
