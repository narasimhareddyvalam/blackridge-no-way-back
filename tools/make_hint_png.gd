extends SceneTree

const OUTPUT := "res://experiments/hint_experiment/greys_3x1.png"
const GREYS: Array[int] = [64, 128, 192]


func _initialize() -> void:
	var image := Image.create_empty(GREYS.size(), 1, false, Image.FORMAT_RGB8)
	for index in range(GREYS.size()):
		var value := GREYS[index] / 255.0
		image.set_pixel(index, 0, Color(value, value, value))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var error := image.save_png(OUTPUT)
	var check := Image.load_from_file(OUTPUT)
	var written: Array[int] = []
	for index in range(check.get_width()):
		written.append(check.get_pixel(index, 0).r8)
	print("wrote %s (%s): texels %s" % [OUTPUT, error_string(error), str(written)])
	quit(0 if error == OK and written == GREYS else 1)
