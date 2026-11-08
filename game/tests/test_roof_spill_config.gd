extends SceneTree
## A2, the roof spill: reads back every setting of its scene, as CHANGE-BRIEF.md §3 gives them and
## TUNING.md's r1 revises them at the author's request (#146, #147, #149): a curtain of streams and
## beads that leaves the roof lip just in front of the glass and runs down it, the clear sheet of
## water that runs down ahead of them, drawn first so they show on it, and the rivulets it breaks
## into. Directions and boxes are in the glass's frame (+x toward the passenger side, +y up the
## glass, +z into the cab); the scene's gravity is the still air's, to which the van adds the surge
## of the water as it slows. No emitter uses a feature the B effects are graded on.

const Readback = preload("res://tests/particle_readback.gd")
const SCENE := "res://effects/roof_spill.tscn"
const SCATTER := "res://effects/scatter_particle.gdshader"
const BEAD := "res://effects/textures/water_bead.png"
const BOX := AABB(Vector3(-2.0, -3.0, -3.0), Vector3(4.0, 4.0, 4.0))
const RIGID := ParticleProcessMaterial.COLLISION_RIGID
const ALONG_MOTION := GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
const OFF_THE_LIP := Vector3(0.0, -0.985, -0.18)
const STILL_AIR := Vector3(0.0, -9.8, 0.0)
const FLAT: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(1.0, 1.0)]
const WATER_WASH := {
	"node": {"sorting_offset": -0.25, "amount": 40, "one_shot": true, "explosiveness": 0.7,
		"lifetime": 0.6, "local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.02, "transform_align": GPUParticles3D.TRANSFORM_ALIGN_DISABLED},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(0.0, -0.04, -0.004),
		"emission_box_extents": Vector3(0.45, 0.03, 0.002), "direction": Vector3(0.0, -1.0, 0.05),
		"spread": 8.0, "initial_velocity_min": 0.3, "initial_velocity_max": 0.8,
		"gravity": STILL_AIR, "damping_min": 0.0, "damping_max": 0.0,
		"color": Color(0.82, 0.86, 0.9, 1.0), "scale_min": 1.2, "scale_max": 2.2,
		"collision_mode": RIGID, "collision_friction": 0.3, "collision_bounce": 0.0},
	"alpha_curve": [Vector2(0.0, 0.0), Vector2(0.15, 0.6), Vector2(0.5, 0.4), Vector2(1.0, 0.0)],
	"scale_curve": {"x": [Vector2(0.0, 1.4), Vector2(1.0, 0.8)],
		"y": [Vector2(0.0, 0.8), Vector2(1.0, 1.6)], "z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.0, "min_pixels": 0.0,
		"forward_scatter": 0.85, "scatter": 0.0, "diffuse": 0.0, "glint": 0.0, "sky": 0.0,
		"catch_light": 0.4, "refraction": 0.03, "lens_blur": 1.2, "rim_dark": 0.1,
		"ripple": 0.012}},
	"mesh": {"size": Vector2(0.1, 0.1)},
	"texture": "res://effects/textures/rain_streak.png",
}
const ROOF_STREAMS := {
	"node": {"amount": 96, "one_shot": true, "explosiveness": 0.8, "lifetime": 0.85,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.01, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.48, 0.02, 0.015), "direction": OFF_THE_LIP,
		"spread": 10.0, "initial_velocity_min": 0.5, "initial_velocity_max": 1.4,
		"gravity": STILL_AIR, "damping_min": 0.1, "damping_max": 0.4,
		"color": Color(0.82, 0.86, 0.88, 1.0), "scale_min": 0.6, "scale_max": 1.5,
		"scale_over_velocity_min": 0.0, "scale_over_velocity_max": 3.0, "collision_mode": RIGID,
		"collision_friction": 0.3, "collision_bounce": 0.0},
	"alpha_curve": [Vector2(0.0, 0.1), Vector2(0.12, 0.6), Vector2(0.5, 0.4), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 1.0), Vector2(0.5, 0.8), Vector2(1.0, 0.4)],
	"scale_over_velocity_curve": {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 31.0)],
		"z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.6, "min_pixels": 1.2,
		"forward_scatter": 0.85, "scatter": 1.5, "diffuse": 0.15, "glint": 0.0, "sky": 0.8,
		"catch_light": 1.0, "refraction": 0.04, "lens_blur": 0.8, "rim_dark": 0.4}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/roof_stream.png",
}
const ROOF_BEADS := {
	"node": {"amount": 120, "one_shot": true, "explosiveness": 0.65, "lifetime": 1.3,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.005, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.48, 0.025, 0.02), "direction": OFF_THE_LIP,
		"spread": 24.0, "initial_velocity_min": 0.4, "initial_velocity_max": 1.6,
		"gravity": STILL_AIR, "damping_min": 0.1, "damping_max": 0.6,
		"color": Color(0.78, 0.86, 0.91, 1.0), "scale_min": 0.25, "scale_max": 0.6,
		"scale_over_velocity_min": 0.0, "scale_over_velocity_max": 6.0, "collision_mode": RIGID,
		"collision_friction": 0.3, "collision_bounce": 0.0},
	"alpha_curve": [Vector2(0.0, 0.5), Vector2(0.2, 0.8), Vector2(0.7, 0.3), Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 1.0), Vector2(0.6, 0.85), Vector2(1.0, 0.5)],
	"scale_over_velocity_curve": {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 26.0)],
		"z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.35, "min_pixels": 2.0,
		"forward_scatter": 0.85, "scatter": 3.0, "diffuse": 0.3, "glint": 1.0, "sky": 1.2,
		"catch_light": 1.0, "refraction": 0.015, "lens_blur": 0.6, "rim_dark": 0.4}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const RIVULETS := {
	"node": {"amount": 8, "one_shot": true, "explosiveness": 0.5, "lifetime": 1.6,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.004, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.45, 0.02, 0.01), "direction": Vector3(0.0, -0.996, 0.09),
		"spread": 15.0, "initial_velocity_min": 0.2, "initial_velocity_max": 0.5,
		"gravity": STILL_AIR, "damping_min": 0.0, "damping_max": 0.0,
		"color": Color(0.8, 0.86, 0.9, 1.0), "scale_min": 0.3, "scale_max": 0.5,
		"scale_over_velocity_min": 0.0, "scale_over_velocity_max": 2.0, "collision_mode": RIGID,
		"collision_friction": 0.35, "collision_bounce": 0.0},
	"alpha_curve": [Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.3, 0.7), Vector2(0.85, 0.5),
		Vector2(1.0, 0.0)],
	"scale_over_velocity_curve": {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 151.0)],
		"z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.8, "min_pixels": 1.5,
		"forward_scatter": 0.85, "scatter": 1.5, "diffuse": 0.15, "glint": 0.5, "sky": 0.8,
		"catch_light": 1.0, "refraction": 0.03, "lens_blur": 0.6, "rim_dark": 0.4}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const EMITTERS := {"WaterWash": WATER_WASH, "RoofStreams": ROOF_STREAMS,
	"RoofBeads": ROOF_BEADS, "Rivulets": RIVULETS}

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
	_check(effect is Node3D and effect.get_child_count() == EMITTERS.size(),
		"One RoofSpill root holds its %d emitters (%d children)" % [EMITTERS.size(),
		effect.get_child_count()])
	for emitter_name: String in EMITTERS:
		var emitter := effect.get_node_or_null(emitter_name) as GPUParticles3D
		Readback.check_emitter(emitter, EMITTERS[emitter_name], _check, emitter_name)
		if emitter:
			Readback.check_no_b_features(emitter, _check, emitter_name)
			var quad := emitter.draw_pass_1 as QuadMesh
			var priority: int = quad.material.render_priority if quad and quad.material else -1
			_check(priority == 1,
				"%s draws after the windshield's glass, which would hide water on its " % [
				emitter_name] + "outside (render priority 1, found %d)" % priority)
	effect.free()
	_finish()


func _finish() -> void:
	print("ROOF SPILL CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
