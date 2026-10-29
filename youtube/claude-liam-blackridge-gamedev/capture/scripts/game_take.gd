extends SceneTree

## Common start for the cockpit takes (A-D) on the isolated copy:
## the real main scene (res://app/first_drive.tscn) inside the 3840x2400 rig,
## a real Escape ("pause" action) press to leave the start menu, a settle check,
## and per-frame guards (van stationary, no driving action held).
## Usage: Godot --path <copy> --fixed-fps 60 --audio-driver Dummy
##   --script res://capture_drivers/<take>.gd -- <capture_dir>

const Rig = preload("res://capture_drivers/capture_rig.gd")
const SIZE := Vector2i(3840, 2400)
const BASE_2D := Vector2i(1280, 800)
const BEGIN_FRAME := 2
const SETTLE_FRAMES := 60
const DRIVING_ACTIONS: Array[String] = ["accelerate", "brake", "steer_left", "steer_right",
	"handbrake"]

var rig: Rig
var app: Node
var van: Node
var presentation: Node
var capture_dir: String
var begun_frame: int = -1
var switch_frames: PackedInt64Array = []
var window_frames: PackedInt64Array = []
var _y_history: PackedFloat64Array = []
var _anchor: Vector3
var _anchor_set: bool = false
var _max_drift: float = 0.0
var _max_speed: float = 0.0
var _held_driving_frames: int = 0


func _initialize() -> void:
	capture_dir = OS.get_cmdline_user_args()[0]
	rig = Rig.new()
	rig.open_logs(_take_name(), capture_dir, _csv_header())
	app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	rig.build(self, SIZE, BASE_2D, app)
	van = app.get_node("FreightVan")
	presentation = van.get_node("VanPresentation")
	van.connect("switch_operated", _on_switch_operated)
	van.connect("window_operated", _on_window_operated)
	rig.tick.connect(_on_tick)


func _late_setup() -> void:
	rig.log_event({"kind": "scene", "main_scene": "res://app/first_drive.tscn",
		"van_path": str(van.get_path()), "camera": str(van.call("get_camera").get_path()),
		"note": "SceneTree._initialize runs before the root enters the tree, so scene-dependent "
		+ "setup runs on the first engine frame, after every _ready()"})
	_setup()


func _on_switch_operated() -> void:
	switch_frames.append(Engine.get_process_frames())
	rig.log_event({"kind": "handled", "signal": "FreightVan.switch_operated",
		"headlights_on": van.get("headlights_on"), "wiper_setting": van.get("wiper_setting")})


func _on_window_operated() -> void:
	window_frames.append(Engine.get_process_frames())
	rig.log_event({"kind": "handled", "signal": "FreightVan.window_operated",
		"left_window_target": van.get("left_window_target")})


func _on_tick(frame: int) -> void:
	if frame == 0:
		_late_setup()
		rig.check(paused and not van.get("input_enabled") and app.get("hud").get("menu_visible"),
			"Game starts paused at its start menu (input disabled)")
	elif frame == BEGIN_FRAME:
		rig.inject("pause", true, "Escape: leave the start menu and begin the drive")
	elif frame == BEGIN_FRAME + 1:
		rig.inject("pause", false)
		var begun: bool = not paused and van.get("input_enabled") \
			and not app.get("hud").get("menu_visible")
		rig.check(begun, "Real Escape press began the drive on frame %d" % frame)
		if begun:
			begun_frame = frame
	if begun_frame >= 0 and not paused:
		_y_history.append((van as Node3D).global_position.y)
	_guard(frame)
	_take_tick(frame)


func settled() -> bool:
	if _y_history.size() < SETTLE_FRAMES:
		return false
	var recent := _y_history.slice(_y_history.size() - SETTLE_FRAMES)
	var low := recent[0]
	var high := recent[0]
	for value in recent:
		low = minf(low, value)
		high = maxf(high, value)
	return high - low < 0.0001 and van.call("is_on_floor")


func settle_report() -> Dictionary:
	var first := _y_history[0] if _y_history.size() > 0 else 0.0
	var last := _y_history[_y_history.size() - 1] if _y_history.size() > 0 else 0.0
	return {"kind": "settle", "start_y": first, "settled_y": last, "drop_m": first - last,
		"frames_observed": _y_history.size(), "is_on_floor": van.call("is_on_floor")}


func anchor_stationary() -> void:
	_anchor = (van as Node3D).global_position
	_anchor_set = true
	rig.log_event({"kind": "anchor", "van_global_position": [_anchor.x, _anchor.y, _anchor.z]})


func _guard(_frame: int) -> void:
	for action in DRIVING_ACTIONS:
		if Input.is_action_pressed(action):
			_held_driving_frames += 1
			break
	if _anchor_set:
		_max_drift = maxf(_max_drift, (van as Node3D).global_position.distance_to(_anchor))
		_max_speed = maxf(_max_speed, absf(van.get("speed")))


func guard_checks() -> void:
	rig.check(_held_driving_frames == 0,
		"No driving action was held on any frame (%d frames)" % _held_driving_frames)
	rig.check(_max_drift < 0.001 and _max_speed < 0.001,
		"Van stayed stationary while recording (max drift %.6f m, max |speed| %.6f)" % [
		_max_drift, _max_speed])


func _take_name() -> String:
	return "take"


func _csv_header() -> PackedStringArray:
	return PackedStringArray()


func _setup() -> void:
	pass


func _take_tick(_frame: int) -> void:
	pass
