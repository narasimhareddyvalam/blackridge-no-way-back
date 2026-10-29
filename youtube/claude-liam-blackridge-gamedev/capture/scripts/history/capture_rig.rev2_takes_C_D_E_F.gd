extends Node

## Shared capture rig for the "Blackridge, Shaded" reel takes.
## Runs only inside the isolated project copy (never the repository's game/).
##
## Why a SubViewport: Godot 4.7.2 Movie Maker records at the project's 1280x800
## window override and macOS clamps the window to the display (probe in CAPTURE.md),
## so it cannot give native 4K frames. This rig renders the scene offline into a
## SubViewport of the requested size while the engine runs with --fixed-fps 60.
##
## Input path: Input.parse_input_event(InputEventAction) -> root Window ->
## SubViewportContainer.input() -> SubViewport.push_input() -> the game's own
## _unhandled_input() handlers. Physical keyboard/mouse events are blocked by
## InputGate so a stray touch cannot leak into a take; they are counted and logged.

signal tick(frame: int)

const INPUT_DEVICE := 4242

var viewport: SubViewport
var container: SubViewportContainer
var content: Node
var out_dir: String
var frames_dir: String
var take_name: String
var fps: int = 60
var record_start: int = -1
var record_count: int = 0
var record_prefix: String = ""
var jpg_quality: float = 0.95
var checks: int = 0
var failures: PackedStringArray = []
var blocked_events: Dictionary = {}
var saved_clip_frames: int = 0
var saved_stills: PackedStringArray = []
var game_time: float = 0.0
var _stills: Dictionary = {}
var _jsonl: FileAccess
var _csv: FileAccess
var _seq: int = 0
var _gate: Node
var _finished: bool = false
var _save_ms_total: int = 0
var _last_drawn: int = -1
var _can_draw: bool = true


class InputGate extends Node:
	var rig: Node

	func _input(event: InputEvent) -> void:
		if event is InputEventAction and event.device == rig.INPUT_DEVICE:
			return
		rig.note_blocked(event)
		get_viewport().set_input_as_handled()


func _init() -> void:
	name = "CaptureRig"
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000


func open_logs(take: String, directory: String, csv_header: PackedStringArray) -> void:
	take_name = take
	out_dir = directory
	DirAccess.make_dir_recursive_absolute(out_dir)
	_jsonl = FileAccess.open(out_dir.path_join("%s-inputs.jsonl" % take), FileAccess.WRITE)
	if csv_header.size() > 0:
		_csv = FileAccess.open(out_dir.path_join("%s-frames.csv" % take), FileAccess.WRITE)
		_csv.store_line(",".join(csv_header))
	log_event({"kind": "start", "take": take, "godot": Engine.get_version_info().string,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"fixed_fps_cmdline": OS.get_cmdline_args(),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"user_data_dir": OS.get_user_data_dir()})


func build(tree: SceneTree, size: Vector2i, size_2d: Vector2i, scene: Node) -> void:
	tree.root.add_child(self)
	container = SubViewportContainer.new()
	container.name = "CaptureContainer"
	container.process_mode = Node.PROCESS_MODE_ALWAYS
	container.stretch = false
	viewport = SubViewport.new()
	viewport.name = "CaptureViewport"
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	viewport.size = size
	if size_2d != Vector2i.ZERO:
		viewport.size_2d_override = size_2d
		viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_match_root_shadow_atlas()
	container.add_child(viewport)
	tree.root.add_child(container)
	var window_base := Vector2(tree.root.get_visible_rect().size)
	container.scale = Vector2.ONE * minf(window_base.x / size.x, window_base.y / size.y)
	_gate = InputGate.new()
	_gate.name = "InputGate"
	_gate.rig = self
	_gate.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(_gate)
	content = scene
	content.process_mode = Node.PROCESS_MODE_PAUSABLE
	viewport.add_child(content)
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
	log_event({"kind": "rig", "viewport_size": [size.x, size.y],
		"size_2d_override": [size_2d.x, size_2d.y],
		"size_2d_override_stretch": size_2d != Vector2i.ZERO,
		"render_target_update_mode": "UPDATE_ALWAYS",
		"positional_shadow_atlas_size": viewport.positional_shadow_atlas_size,
		"window_size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"content_process_mode": content.process_mode})


func _match_root_shadow_atlas() -> void:
	var prefix := "rendering/lights_and_shadows/positional_shadow/"
	viewport.positional_shadow_atlas_size = ProjectSettings.get_setting(prefix + "atlas_size")
	viewport.positional_shadow_atlas_16_bits = ProjectSettings.get_setting(
		prefix + "atlas_16_bits")
	for quadrant in range(4):
		viewport.set_positional_shadow_atlas_quadrant_subdiv(quadrant,
			ProjectSettings.get_setting(prefix + "atlas_quadrant_%d_subdiv" % quadrant))


func _process(delta: float) -> void:
	game_time += delta
	var frame := Engine.get_process_frames()
	var can_draw := DisplayServer.window_can_draw()
	if can_draw != _can_draw:
		_can_draw = can_draw
		log_event({"kind": "window_can_draw_changed", "window_can_draw": can_draw})
	if in_recording(frame - 1) and _last_drawn != frame - 1 and not _finished:
		check(false, "Recording frame %d (process frame %d) was drawn; window_can_draw=%s" % [
			frame - 1 - record_start, frame - 1, str(can_draw)])
		finish({"aborted": "a recording frame was not drawn by the engine"})
		return
	tick.emit(frame)


func frame_info() -> Dictionary:
	var frame := Engine.get_process_frames()
	var info := {"process_frame": frame, "physics_frame": Engine.get_physics_frames(),
		"game_time": snappedf(game_time, 0.000001), "wall_usec": Time.get_ticks_usec(),
		"paused": (Engine.get_main_loop() as SceneTree).paused, "time_scale": Engine.time_scale}
	if record_start >= 0:
		info["clip_frame"] = frame - record_start
		info["t_clip"] = snappedf(float(frame - record_start) / fps, 0.000001)
	return info


func log_event(fields: Dictionary) -> void:
	var line := frame_info()
	line.merge(fields, true)
	line["seq"] = _seq
	_seq += 1
	_jsonl.store_line(JSON.stringify(line, "", true))
	_jsonl.flush()


func csv_row(values: Array) -> void:
	var cells := PackedStringArray()
	for value in values:
		cells.append(str(value))
	_csv.store_line(",".join(cells))


func inject(action: String, pressed: bool, purpose: String = "") -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.device = INPUT_DEVICE
	Input.parse_input_event(event)
	log_event({"kind": "inject", "api": "Input.parse_input_event(InputEventAction)",
		"action": action, "pressed": pressed, "device": INPUT_DEVICE, "purpose": purpose,
		"note": "buffered by Input; dispatched at the start of the next engine iteration"})


func start_recording(prefix: String, start_frame: int, count: int) -> void:
	record_prefix = prefix
	record_start = start_frame
	record_count = count
	frames_dir = out_dir.path_join("raw").path_join("frames_" + prefix)
	DirAccess.make_dir_recursive_absolute(frames_dir)
	log_event({"kind": "record_window", "prefix": prefix, "first_process_frame": start_frame,
		"frame_count": count, "fps": fps, "format": "jpg", "jpg_quality": jpg_quality,
		"frames_dir": frames_dir})


func request_still(file_name: String) -> void:
	_stills[Engine.get_process_frames()] = file_name


func in_recording(frame: int) -> bool:
	return record_start >= 0 and frame >= record_start and frame < record_start + record_count


func _on_frame_post_draw() -> void:
	var frame := Engine.get_process_frames()
	_last_drawn = frame
	var still_name: String = _stills.get(frame, "")
	var clip := in_recording(frame)
	if not clip and still_name == "":
		return
	var began := Time.get_ticks_msec()
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	if clip:
		var index := frame - record_start
		var path := frames_dir.path_join("%s_%05d.jpg" % [record_prefix, index])
		var error := image.save_jpg(path, jpg_quality)
		if error != OK:
			check(false, "Saved clip frame %d (%s)" % [index, error_string(error)])
		saved_clip_frames += 1
	if still_name != "":
		var error := image.save_png(out_dir.path_join(still_name))
		check(error == OK, "Saved still %s at %dx%d (process frame %d)" % [
			still_name, image.get_width(), image.get_height(), frame])
		saved_stills.append(still_name)
		log_event({"kind": "still", "file": still_name, "width": image.get_width(),
			"height": image.get_height()})
		_stills.erase(frame)
	_save_ms_total += Time.get_ticks_msec() - began


func note_blocked(event: InputEvent) -> void:
	var type := event.get_class()
	var first: bool = not blocked_events.has(type)
	blocked_events[type] = int(blocked_events.get(type, 0)) + 1
	if first:
		log_event({"kind": "blocked_physical_input", "event_class": type,
			"event": event.as_text(), "note": "first of its class; total counted at finish"})


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
	print(("PASS: " if condition else "FAIL: ") + label)
	log_event({"kind": "check", "passed": condition, "label": label})


func finish(extra: Dictionary = {}) -> void:
	if _finished:
		return
	_finished = true
	var summary := {"take": take_name, "checks": checks, "failed": failures.size(),
		"failures": failures, "passed": failures.is_empty(),
		"saved_clip_frames": saved_clip_frames, "saved_stills": saved_stills,
		"blocked_physical_input": blocked_events,
		"save_ms_total": _save_ms_total}
	summary.merge(extra, true)
	log_event({"kind": "finish", "summary": summary})
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("logs"))
	var file := FileAccess.open(out_dir.path_join("logs/%s-result.json" % take_name),
		FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "  ", true) + "\n")
	file.close()
	if _csv:
		_csv.close()
	_jsonl.close()
	print("CAPTURE RESULT %s: %d/%d checks passed" % [take_name, checks - failures.size(),
		checks])
	get_tree().quit(0 if failures.is_empty() else 1)
