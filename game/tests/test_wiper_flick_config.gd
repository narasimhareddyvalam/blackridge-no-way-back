extends SceneTree
## A1, the wiper flick: reads back every setting CHANGE-BRIEF.md §2 names from the scene.

const Readback = preload("res://tests/particle_readback.gd")
const SCENE := "res://effects/wiper_flick.tscn"
const BOX := AABB(Vector3(-2.0, -2.0, -1.5), Vector3(3.0, 3.0, 3.0))
const DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,
	"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,
	"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,
	"billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES, "vertex_color_use_as_albedo": true}
const BIG_DROPS := {
	"node": {"amount": 22, "one_shot": true, "explosiveness": 1.0, "lifetime": 0.65,
		"local_coords": false, "visibility_aabb": BOX, "preprocess": 0.0},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 0.025, "initial_velocity_min": 1.2, "initial_velocity_max": 2.8,
		"direction": Vector3(-0.94, 0.09, -0.32), "spread": 28.0,
		"gravity": Vector3(0.0, -9.8, 0.0), "damping_min": 0.3, "damping_max": 0.7,
		"color": Color(0.78, 0.86, 0.91, 1.0), "scale_min": 0.3, "scale_max": 0.7,
		"inherit_velocity_ratio": 0.0},
	"alpha_curve": [Vector2(0.0, 0.75), Vector2(0.15, 0.9), Vector2(0.55, 0.4), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 0.75), Vector2(0.2, 1.0), Vector2(1.0, 1.0)],
	"draw": DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/water_bead.png",
}
const FINE_SPRAY := {
	"node": {"amount": 36, "one_shot": true, "explosiveness": 0.9, "lifetime": 1.2,
		"local_coords": false, "visibility_aabb": BOX, "preprocess": 0.0},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 0.035, "initial_velocity_min": 0.35, "initial_velocity_max": 1.1,
		"direction": Vector3(-0.94, 0.09, -0.32), "spread": 48.0,
		"gravity": Vector3(0.0, -1.0, 0.0), "damping_min": 0.8, "damping_max": 1.6,
		"color": Color(0.82, 0.87, 0.91, 1.0), "scale_min": 0.15, "scale_max": 0.3,
		"inherit_velocity_ratio": 0.0},
	"alpha_curve": [Vector2(0.0, 0.35), Vector2(0.2, 0.45), Vector2(0.65, 0.15), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 0.7), Vector2(0.5, 1.0), Vector2(1.0, 1.4)],
	"draw": DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/fine_spray.png",
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
		"One WiperFlick root holds its two emitters (%d children)" % effect.get_child_count())
	Readback.check_emitter(effect.get_node_or_null("BigDrops"), BIG_DROPS, _check, "BigDrops")
	Readback.check_emitter(effect.get_node_or_null("FineSpray"), FINE_SPRAY, _check, "FineSpray")
	effect.free()
	_finish()


func _finish() -> void:
	print("WIPER FLICK CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
