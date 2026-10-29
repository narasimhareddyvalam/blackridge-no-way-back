extends SceneTree

## Rig self-test (probe phase, not a take). Checks on the isolated copy that:
## - a real "pause" (Escape) action press reaches the game through the rig and begins the drive;
## - one "headlights" press toggles headlights_on exactly once, and on which frame;
## - a still requested on frame k shows state set on frame k (frame_post_draw timing);
## - shader TIME keeps running while the tree is paused, and stops at Engine.time_scale 0;
## - how long a 3840x2400 JPEG frame save takes.
## Usage: Godot --path <copy> --fixed-fps 60 --audio-driver Dummy
##   --script res://capture_drivers/rig_selftest.gd -- <out_dir>

const Rig = preload("res://capture_drivers/capture_rig.gd")
const BEGIN_FRAME := 2

var rig: Rig
var app: Node
var van: Node
var presentation: Node
var switch_frames: PackedInt64Array = []
var resumed_at: int = -1


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	rig = Rig.new()
	rig.open_logs("selftest", out_dir, PackedStringArray())
	app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	rig.build(self, Vector2i(3840, 2400), Vector2i(1280, 800), app)
	van = app.get_node("FreightVan")
	presentation = van.get_node("VanPresentation")
	van.switch_operated.connect(_on_switch)
	rig.tick.connect(_tick)


func _on_switch() -> void:
	switch_frames.append(Engine.get_process_frames())
	rig.log_event({"kind": "handled", "signal": "switch_operated",
		"headlights_on": van.headlights_on})


func _tick(frame: int) -> void:
	var light: ShaderMaterial = presentation.fog_overlays[0].material_override
	if frame == 0:
		rig.check(paused and not van.input_enabled, "Game starts paused at its start menu")
	elif frame == BEGIN_FRAME:
		rig.inject("pause", true, "begin the drive (start menu)")
	elif frame == BEGIN_FRAME + 1:
		rig.check(not paused and van.input_enabled,
			"Escape action press reached the HUD through the rig: unpaused on frame %d" % frame)
		resumed_at = frame
		rig.inject("pause", false)
	elif frame == 60:
		rig.request_still("selftest_hud_3840x2400.png")
		rig.inject("headlights", true, "toggle test")
	elif frame == 61:
		rig.inject("headlights", false)
		rig.check(not van.headlights_on, "headlights_on is false on frame 61")
	elif frame == 70:
		rig.check(switch_frames.size() == 1, "One press toggled once (switch_operated x%d at %s)"
			% [switch_frames.size(), str(switch_frames)])
		rig.start_recording("selftest", 71, 30)
	elif frame == 110:
		paused = true
		rig.log_event({"kind": "scripted", "what": "SceneTree.paused = true"})
	elif frame == 112:
		rig.request_still("selftest_paused_ts1_a.png")
	elif frame == 172:
		rig.request_still("selftest_paused_ts1_b.png")
	elif frame == 173:
		Engine.time_scale = 0.0
		rig.log_event({"kind": "scripted", "what": "Engine.time_scale = 0.0"})
	elif frame == 175:
		rig.request_still("selftest_paused_ts0_a.png")
	elif frame == 235:
		rig.request_still("selftest_paused_ts0_b.png")
	elif frame == 236:
		light.set_shader_parameter("fog_amount", 1.0)
		rig.request_still("selftest_same_frame_edit.png")
	elif frame == 237:
		light.set_shader_parameter("fog_amount", 0.25)
	elif frame == 240:
		rig.finish({"switch_frames": switch_frames, "resumed_at": resumed_at})
