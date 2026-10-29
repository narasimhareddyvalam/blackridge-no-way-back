extends SceneTree

const VALUES: Array[float] = [0.0, 0.5, 1.0, 2.0]
const PIXELS := {"background": Vector2i(10, 10), "dial hub": Vector2i(155, 136)}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-capture-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	var presentation := app.get_node("FreightVan/VanPresentation")
	var dimming: Node = presentation.get("night_dimming")
	var material: ShaderMaterial = dimming.get("material")
	var cluster := _cluster_viewport(presentation, material)
	var folder := ProjectSettings.globalize_path("res://").path_join("../evidence/captures")
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in range(30):
		await process_frame
	var report := PackedStringArray(["renderer=%s cluster=%dx%d" % [
		RenderingServer.get_current_rendering_method(), cluster.size.x, cluster.size.y]])
	for value in VALUES:
		var image := await _capture(dimming, material, value, cluster)
		image.save_png(folder.path_join("night_cluster_%.1f.png" % value))
		var cockpit := root.get_texture().get_image()
		cockpit.save_png(folder.path_join("cockpit_night_amount_%.1f.png" % value))
		var samples := PackedStringArray()
		for label: String in PIXELS:
			var pixel := image.get_pixelv(PIXELS[label])
			samples.append("%s %s = (%d, %d, %d)" % [label, PIXELS[label], pixel.r8, pixel.g8,
				pixel.b8])
		report.append("night_amount %.1f: %s" % [value, "; ".join(samples)])
	var text := "\n".join(report)
	print(text)
	var file := FileAccess.open(folder.path_join("night_cluster_samples.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _capture(driver: Node, material: ShaderMaterial, value: float,
		viewport: SubViewport) -> Image:
	driver.set_process(false)
	material.set_shader_parameter("night_amount", value)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	return image


func _cluster_viewport(presentation: Node, material: Material) -> SubViewport:
	for viewport in presentation.get_children():
		if viewport is SubViewport:
			for control in viewport.get_children():
				if control is CanvasItem and control.material == material:
					return viewport
	return null
