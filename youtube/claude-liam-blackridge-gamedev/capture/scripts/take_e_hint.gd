extends SceneTree

## Take E: the hint experiment scene (res://experiments/hint_experiment/hint_experiment.tscn,
## unchanged) rendered at native 3840x2160 in the capture rig, under whichever renderer the
## run was started with (the project's gl_compatibility, or --rendering-method forward_plus).
## Saves hint_<renderer>_4k.png and samples the centre pixel of each of the three bands on
## both quads (plus the min/max over a 9x9 neighbourhood) into logs/hint_samples_<renderer>.txt.
## Usage: Godot --path <copy> --fixed-fps 60 --audio-driver Dummy [--rendering-method forward_plus]
##   --script res://capture_drivers/take_e_hint.gd -- <capture_dir>

const Rig = preload("res://capture_drivers/capture_rig.gd")
const SCENE := "res://experiments/hint_experiment/hint_experiment.tscn"
const SIZE := Vector2i(3840, 2160)
const QUADS: Array[String] = ["AsColor", "AsData"]
const BAND_X: Array[float] = [-0.5, 0.0, 0.5]
const SHOT_FRAME := 20
const EARLIER := {
	"gl_compatibility": "AsColor 64/128/192, AsData 64/128/192 (1280x800 window, evidence/captures)",
	"forward_plus": "AsColor 64/128/192, AsData 137/188/225 (1280x800 window, evidence/captures)",
}

var rig: Rig
var scene: Node3D
var capture_dir: String
var method: String
var file_name: String


func _initialize() -> void:
	capture_dir = OS.get_cmdline_user_args()[0]
	method = RenderingServer.get_current_rendering_method()
	file_name = "hint_%s_4k.png" % ("compatibility" if method == "gl_compatibility" else method)
	rig = Rig.new()
	rig.open_logs("take_e_hint_" + method, capture_dir, PackedStringArray())
	scene = (load(SCENE) as PackedScene).instantiate()
	rig.build(self, SIZE, Vector2i.ZERO, scene)
	rig.tick.connect(_tick)


func _tick(frame: int) -> void:
	if frame == SHOT_FRAME:
		rig.request_still(file_name)
	elif frame == SHOT_FRAME + 2:
		_sample()


func _sample() -> void:
	var image := Image.load_from_file(capture_dir.path_join(file_name))
	var camera: Camera3D = scene.get_node("Camera3D")
	var scale := Vector2(image.get_size()) / rig.viewport.get_visible_rect().size
	var lines := PackedStringArray()
	lines.append("renderer=%s driver=%s adapter=%s image=%dx%d file=%s" % [method,
		RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(),
		image.get_width(), image.get_height(), file_name])
	var results := {}
	for quad_name in QUADS:
		var quad: MeshInstance3D = scene.get_node(quad_name)
		var bands := PackedStringArray()
		var centres := []
		for band in range(3):
			var at := Vector2i((camera.unproject_position(quad.to_global(
				Vector3(BAND_X[band], 0.0, 0.0))) * scale).round())
			var pixel := image.get_pixelv(at)
			var low := Vector3i(255, 255, 255)
			var high := Vector3i(0, 0, 0)
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var near := image.get_pixel(at.x + dx, at.y + dy)
					low = Vector3i(mini(low.x, near.r8), mini(low.y, near.g8), mini(low.z, near.b8))
					high = Vector3i(maxi(high.x, near.r8), maxi(high.y, near.g8), maxi(high.z, near.b8))
			bands.append("band %d at (%d, %d) = (%d, %d, %d) [9x9 min %s max %s]" % [band + 1, at.x,
				at.y, pixel.r8, pixel.g8, pixel.b8, str(low), str(high)])
			centres.append([pixel.r8, pixel.g8, pixel.b8])
		lines.append("%s: %s" % [quad_name, "; ".join(bands)])
		results[quad_name] = centres
	lines.append("earlier measurement (lower resolution): " + EARLIER.get(method, "none"))
	var text := "\n".join(lines)
	print(text)
	var file := FileAccess.open(capture_dir.path_join("logs/hint_samples_%s.txt" % method),
		FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	rig.log_event({"kind": "samples", "renderer": method, "centres": results})
	rig.check(image.get_width() == SIZE.x and image.get_height() == SIZE.y,
		"Hint capture is native %dx%d" % [SIZE.x, SIZE.y])
	for quad_name in QUADS:
		var grey := true
		for centre in results[quad_name]:
			grey = grey and centre[0] == centre[1] and centre[1] == centre[2]
		var rising: bool = results[quad_name][0][0] < results[quad_name][1][0] \
			and results[quad_name][1][0] < results[quad_name][2][0]
		rig.check(grey and rising, "%s bands are grey and increase left to right" % quad_name)
	rig.finish({"renderer": method, "centres": results})
