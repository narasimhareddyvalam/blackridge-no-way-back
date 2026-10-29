extends CanvasLayer

@export var refresh_seconds: float = 0.5

var _label := Label.new()


func _ready() -> void:
	layer = 20
	_label.position = Vector2(16, 12)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(_label)
	var timer := Timer.new()
	timer.wait_time = refresh_seconds
	timer.autostart = true
	timer.timeout.connect(_refresh)
	add_child(timer)


func _refresh() -> void:
	var frame_ms := 1000.0 / maxf(Engine.get_frames_per_second(), 1.0)
	var draw_calls := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var video_mb := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	_label.text = "%s   %d FPS   %.1f ms   %d draw calls   %.0f MB video" % [
		RenderingServer.get_current_rendering_method(), Engine.get_frames_per_second(),
		frame_ms, draw_calls, video_mb]
