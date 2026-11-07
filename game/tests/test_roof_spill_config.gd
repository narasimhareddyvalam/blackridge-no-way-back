extends SceneTree
## A2, the roof spill: reads back every setting CHANGE-BRIEF.md §3 names from the scene.

const Readback = preload("res://tests/particle_readback.gd")
const SCENE := "res://effects/roof_spill.tscn"
const BOX := AABB(Vector3(-2.0, -3.0, -3.0), Vector3(4.0, 4.0, 4.0))
const ALONG_GLASS := Vector3(0.0, -0.7, -0.71)
const VAN_FRAME_GRAVITY := Vector3(0.0, -9.3, -9.51)
const STREAM_DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,
	"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,
	"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,
	"vertex_color_use_as_albedo": true, "billboard_mode": BaseMaterial3D.BILLBOARD_DISABLED}
const BEAD_DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,
	"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,
	"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,
	"vertex_color_use_as_albedo": true, "billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES}
const ROOF_STREAMS := {
	"node": {"amount": 32, "one_shot": true, "explosiveness": 0.8, "lifetime": 0.85,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"transform_align": GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.48, 0.015, 0.025), "initial_velocity_min": 0.5,
		"initial_velocity_max": 1.4, "direction": ALONG_GLASS, "spread": 12.0,
		"gravity": VAN_FRAME_GRAVITY, "damping_min": 0.1, "damping_max": 0.4,
		"color": Color(0.82, 0.86, 0.88, 1.0), "scale_min": 1.2, "scale_max": 2.8},
	"alpha_curve": [Vector2(0.0, 0.1), Vector2(0.12, 0.6), Vector2(0.5, 0.4), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 1.0), Vector2(0.5, 0.8), Vector2(1.0, 0.4)],
	"draw": STREAM_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/roof_stream.png",
}
const ROOF_BEADS := {
	"node": {"amount": 48, "one_shot": true, "explosiveness": 0.65, "lifetime": 1.3,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.48, 0.02, 0.03), "initial_velocity_min": 0.4,
		"initial_velocity_max": 1.6, "direction": ALONG_GLASS, "spread": 24.0,
		"gravity": VAN_FRAME_GRAVITY, "damping_min": 0.1, "damping_max": 0.6,
		"color": Color(0.78, 0.86, 0.91, 1.0), "scale_min": 0.3, "scale_max": 0.9},
	"alpha_curve": [Vector2(0.0, 0.5), Vector2(0.2, 0.8), Vector2(0.7, 0.3), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 1.0), Vector2(0.6, 0.85), Vector2(1.0, 0.5)],
	"draw": BEAD_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/water_bead.png",
}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "%s loads" % SCENE)
	if packed == null:
		_finish()
		return
	var effect := packed.instantiate()
	_check(effect is Node3D and effect.get_child_count() == 2,
		"One RoofSpill root holds its two emitters (%d children)" % effect.get_child_count())
	Readback.check_emitter(effect.get_node_or_null("RoofStreams"), ROOF_STREAMS, _check,
		"RoofStreams")
	Readback.check_emitter(effect.get_node_or_null("RoofBeads"), ROOF_BEADS, _check, "RoofBeads")
	effect.free()
	_finish()


func _finish() -> void:
	print("ROOF SPILL CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
