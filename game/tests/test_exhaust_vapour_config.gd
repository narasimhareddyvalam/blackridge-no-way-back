extends SceneTree
## B2, the exhaust vapour: reads back every setting CHANGE-BRIEF.md §5 names from the scene, as
## TUNING.md's r1 revises them at the author's request (#146, #149): a short jet of wet exhaust
## that the still air stops within a metre or so, where its vapour spreads and thins out in under
## two seconds. Also the features neither A effect uses: an amount_ratio the game drives (the node
## must have it, with amount fixed at 300) and turbulence.

const Readback = preload("res://tests/particle_readback.gd")
const SCENE := "res://effects/exhaust_vapour.tscn"
const PLUME := {
	"node": {"amount": 300, "one_shot": false, "explosiveness": 0.0, "lifetime": 1.6,
		"local_coords": false, "preprocess": 0.0, "layers": 1,
		"visibility_aabb": AABB(Vector3(-3.0, -1.0, -11.0), Vector3(6.0, 5.0, 60.0))},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 0.025, "initial_velocity_min": 4.0, "initial_velocity_max": 7.0,
		"direction": Vector3(0.0, -0.26, 0.97), "spread": 10.0,
		"gravity": Vector3(0.0, 0.8, 0.0), "damping_min": 12.0, "damping_max": 18.0,
		"color": Color(0.92, 0.93, 0.94, 1.0), "scale_min": 0.6, "scale_max": 1.0,
		"turbulence_enabled": true, "turbulence_noise_strength": 0.35,
		"turbulence_noise_scale": 1.6, "turbulence_noise_speed": Vector3(0.3, 0.25, 0.3)},
	"alpha_curve": [Vector2(0.0, 0.0), Vector2(0.02, 0.22), Vector2(0.3, 0.14),
		Vector2(0.7, 0.05), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 1.0), Vector2(0.3, 3.0), Vector2(1.0, 6.0)],
	"draw": {"shader": "res://effects/scatter_particle.gdshader", "params": {
		"face_camera": true, "min_pixels": 0.0, "forward_scatter": 0.75, "scatter": 0.8,
		"diffuse": 0.25, "glint": 0.0, "sky": 0.0}},
	"mesh": {"size": Vector2(0.1, 0.1)},
	"texture": "res://effects/textures/exhaust_puff.png",
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
	var plume := effect.get_node_or_null("ExhaustPlume") as GPUParticles3D
	_check(effect is Node3D and effect.get_child_count() == 1,
		"One ExhaustVapour root holds its emitter (%d children)" % effect.get_child_count())
	Readback.check_emitter(plume, PLUME, _check, "ExhaustPlume")
	if plume:
		_check("amount_ratio" in plume and not plume.emitting,
			"The plume has amount_ratio for the throttle, and waits for the engine (emitting off)")
		_check(scale_curve_can_reach(plume, 6.0),
			"Its scale curve can reach 6 (max_value %.1f)" % _max_scale(plume))
	effect.free()
	_finish()


func scale_curve_can_reach(plume: GPUParticles3D, value: float) -> bool:
	return _max_scale(plume) >= value


func _max_scale(plume: GPUParticles3D) -> float:
	var process := plume.process_material as ParticleProcessMaterial
	var texture := process.scale_curve as CurveTexture if process else null
	return texture.curve.max_value if texture and texture.curve else 0.0


func _finish() -> void:
	print("EXHAUST VAPOUR CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures,
		_checks, _failures])
	quit(0 if _failures == 0 else 1)
