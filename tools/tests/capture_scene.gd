extends SceneTree

## Renders a scene in a real window, saves screenshots, then quits.
## Usage, from the repository root:
##   Godot --path game --rendering-method forward_plus \
##     --script ../tools/tests/capture_scene.gd -- <res://scene.tscn> <output_prefix> [shot ...]
## A shot is "cockpit" (the scene's own camera) or "x,y,z>x,y,z" (eye > target).

const SETTLE_FRAMES: int = 120

var _shots: PackedStringArray = []
var _prefix: String
var _free_camera := Camera3D.new()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: PackedScene = load(args[0])
	_prefix = args[1]
	_shots = args.slice(2) if args.size() > 2 else PackedStringArray(["cockpit"])
	root.add_child(scene.instantiate())
	_free_camera.fov = 62.0
	_free_camera.far = 400.0
	root.add_child(_free_camera)
	_capture.call_deferred()


func _capture() -> void:
	var scene_camera := root.get_viewport().get_camera_3d()
	for index in range(_shots.size()):
		var shot := _shots[index]
		if shot == "cockpit":
			scene_camera.make_current()
		else:
			var points := shot.split(">")
			_free_camera.make_current()
			_free_camera.look_at_from_position(_vector(points[0]), _vector(points[1]))
		for frame in range(SETTLE_FRAMES):
			await process_frame
		var path := "%s_%s_%d.png" % [
			_prefix, RenderingServer.get_current_rendering_method(), index]
		root.get_viewport().get_texture().get_image().save_png(path)
		print("Saved %s  shot=%s  fps=%d  draw_calls=%d  video_mb=%.0f" % [
			path, shot, Engine.get_frames_per_second(),
			RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0])
	quit()


func _vector(text: String) -> Vector3:
	var parts := text.split(",")
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
