extends SceneTree

## Resolution probe for Movie Maker. Loads the real main scene, prints the window,
## screen and root-viewport sizes, and quits after a short run (--quit-after).

var _frame: int = 0


func _initialize() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(app)
	print("PROBE rendering_method=%s window_size=%s screen_count=%d window_screen=%d" % [
		RenderingServer.get_current_rendering_method(), DisplayServer.window_get_size(),
		DisplayServer.get_screen_count(), DisplayServer.window_get_current_screen()])
	for screen in range(DisplayServer.get_screen_count()):
		print("PROBE screen %d size=%s scale=%.2f usable=%s" % [screen,
			DisplayServer.screen_get_size(screen), DisplayServer.screen_get_scale(screen),
			DisplayServer.screen_get_usable_rect(screen)])


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30 or _frame == 90:
		var image := root.get_texture().get_image()
		print("PROBE frame %d process_frames=%d root_texture=%s root.size=%s visible_rect=%s window_size=%s" % [
			_frame, Engine.get_process_frames(), image.get_size(), root.size,
			root.get_visible_rect(), DisplayServer.window_get_size()])
	return false
