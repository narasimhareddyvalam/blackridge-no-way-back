extends SceneTree

const SWEEP := {
	"fog_amount": [0.0, 0.25, 1.0],
	"fog_opacity": [0.0, 0.45, 1.0],
	"clear_center": [0.0, 0.65, 0.9],
	"edge_softness": [0.01, 0.2, 0.5],
	"normal_strength": [0.0, 0.5, 2.0],
	"texture_scale": [0.5, 1.0, 4.0],
	"fog_tint": [Color(0, 0, 0, 1), Color(0.82, 0.87, 0.9, 1), Color(1, 1, 1, 1)],
}
const SIDE_LOOK := Vector2(0.0, 0.75)

var _folder: String
var _presentation: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-fog-capture-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	_presentation = app.get_node("FreightVan/VanPresentation")
	var overlays: Array = _presentation.get("fog_overlays")
	var light: ShaderMaterial = overlays[0].material_override
	var heavy: ShaderMaterial = overlays[1].material_override
	var world: WorldEnvironment = app.find_children("*", "WorldEnvironment", true, false)[0]
	_folder = ProjectSettings.globalize_path("res://").path_join("../evidence/captures/fog")
	DirAccess.make_dir_recursive_absolute(_folder)
	var log := PackedStringArray(["renderer=%s" % RenderingServer.get_current_rendering_method()])
	world.environment.fog_enabled = false
	await _look(SIDE_LOOK)
	await _save("side_by_side_world_fog_off.png", log)
	world.environment.fog_enabled = true
	await _save("side_by_side_world_fog_on.png", log)
	world.environment.fog_enabled = false
	await _look(Vector2.ZERO)
	await _save("windshield_forward.png", log)
	for uniform_name: String in SWEEP:
		var steps: Array = SWEEP[uniform_name]
		var labels := ["min", "default", "max"]
		for index in range(steps.size()):
			light.set_shader_parameter(uniform_name, steps[index])
			await _save("sweep_%s_%s.png" % [uniform_name, labels[index]], log)
		light.set_shader_parameter(uniform_name, steps[1])
	await _look(SIDE_LOOK)
	var before: float = heavy.get_shader_parameter("fog_amount")
	light.set_shader_parameter("fog_amount", 1.0)
	await _save("material_edit_light_fog_amount_1.0.png", log)
	log.append("material edit: light_fog fog_amount 0.25 -> 1.0 at runtime; heavy_fog fog_amount "
		+ "stayed %s" % str(heavy.get_shader_parameter("fog_amount")) + " (was %s)" % str(before))
	light.set_shader_parameter("fog_amount", 0.25)
	var text := "\n".join(log)
	print(text)
	var file := FileAccess.open(_folder.path_join("fog_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _look(target: Vector2) -> void:
	_presentation.set("_look_target", target)
	for frame in range(45):
		await process_frame


func _save(file_name: String, log: PackedStringArray) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(file_name))
	log.append("saved fog/" + file_name)
