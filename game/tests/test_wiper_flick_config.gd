extends SceneTree
## A1, the wiper flick: reads back every setting of its scene, as CHANGE-BRIEF.md §2 gives them
## and TUNING.md's r1 revises them at the author's request (#146–#148): the bow wave leaving as
## a sheet along the blade, beads that leave as threads and snap into drops of real size, a few
## heavy drops that slide, the fine spray, the extra water a roof spill leaves on the glass, and
## the run-off thrown back along the side window. Directions, boxes and gravity are
## in the glass's frame (+x toward the passenger side, +y up the glass, +z into the cab); the
## scene's gravity is the still air's, which the van turns into each emitter's frame as it drives.
## No emitter uses a feature the B effects are graded on.

const Readback = preload("res://tests/particle_readback.gd")
const SCENE := "res://effects/wiper_flick.tscn"
const SCATTER := "res://effects/scatter_particle.gdshader"
const BEAD := "res://effects/textures/water_bead.png"
const BOX := AABB(Vector3(-2.5, -2.0, -1.0), Vector3(3.5, 3.5, 3.5))
const RIGID := ParticleProcessMaterial.COLLISION_RIGID
const ALONG_MOTION := GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
const LEAVING := Vector3(-0.95, -0.15, -0.27)
const WATER := Color(0.78, 0.86, 0.91, 1.0)
const FLAT: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(1.0, 1.0)]
const THREAD := {"x": [Vector2(0.0, 0.8), Vector2(0.08, 1.0), Vector2(1.0, 1.0)],
	"y": [Vector2(0.0, 2.0), Vector2(0.08, 1.0), Vector2(1.0, 1.0)], "z": FLAT}
const SHUTTER := {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 26.0)], "z": FLAT}
const BEAD_ALPHA := [Vector2(0.0, 0.4), Vector2(0.06, 0.95), Vector2(0.55, 0.7), Vector2(1.0, 0.0)]
const BEAD_DRAW := {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.35,
	"thread_life": 0.1, "min_pixels": 2.0, "forward_scatter": 0.85, "scatter": 10.0,
	"diffuse": 0.3, "glint": 1.0, "sky": 2.0, "catch_light": 1.0, "refraction": 0.012,
	"lens_blur": 0.6, "rim_dark": 0.4, "ground_reach": 0.5}}
const WATER_SHEET := {
	"node": {"amount": 24, "one_shot": true, "explosiveness": 1.0, "lifetime": 0.15,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.006, "transform_align": GPUParticles3D.TRANSFORM_ALIGN_DISABLED},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.012, -0.2, -0.006),
		"emission_box_extents": Vector3(0.004, 0.2, 0.002), "direction": Vector3(-1.0, 0.0, -0.12),
		"spread": 6.0, "initial_velocity_min": 1.0, "initial_velocity_max": 3.0,
		"gravity": Vector3(0.0, -9.8, 0.0), "damping_min": 1.0, "damping_max": 2.0,
		"color": WATER, "scale_min": 1.0, "scale_max": 1.3, "inherit_velocity_ratio": 0.0,
		"collision_mode": RIGID, "collision_friction": 0.1, "collision_bounce": 0.0},
	"alpha_curve": [Vector2(0.0, 0.95), Vector2(0.4, 0.85), Vector2(1.0, 0.0)],
	"scale_curve": {"x": [Vector2(0.0, 1.0), Vector2(1.0, 0.4)],
		"y": [Vector2(0.0, 7.0), Vector2(0.5, 3.0), Vector2(1.0, 1.0)], "z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.0, "min_pixels": 2.0,
		"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 1.0, "sky": 2.0,
		"catch_light": 1.0, "refraction": 0.02, "lens_blur": 0.6, "rim_dark": 0.4,
		"ground_reach": 0.5}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/rain_streak.png",
}
const BIG_DROPS := {
	"node": {"amount": 120, "one_shot": true, "explosiveness": 1.0, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.004, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.05, -0.12, -0.012),
		"emission_box_extents": Vector3(0.045, 0.13, 0.004), "direction": LEAVING, "spread": 30.0,
		"initial_velocity_min": 0.2, "initial_velocity_max": 2.6,
		"gravity": Vector3(0.0, -9.8, 0.0), "damping_min": 0.2, "damping_max": 0.5,
		"color": WATER, "scale_min": 0.25, "scale_max": 0.45, "scale_over_velocity_min": 0.0,
		"scale_over_velocity_max": 6.0, "inherit_velocity_ratio": 0.0, "collision_mode": RIGID,
		"collision_friction": 0.85, "collision_bounce": 0.05},
	"alpha_curve": BEAD_ALPHA,
	"scale_curve": THREAD,
	"scale_over_velocity_curve": SHUTTER,
	"draw": BEAD_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const HEAVY_DROPS := {
	"node": {"amount": 14, "one_shot": true, "explosiveness": 0.9, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.006, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.05, -0.12, -0.012),
		"emission_box_extents": Vector3(0.045, 0.13, 0.004), "direction": LEAVING, "spread": 30.0,
		"initial_velocity_min": 0.2, "initial_velocity_max": 1.6,
		"gravity": Vector3(0.0, -9.8, 0.0), "damping_min": 0.2, "damping_max": 0.4,
		"color": WATER, "scale_min": 0.5, "scale_max": 0.65, "scale_over_velocity_min": 0.0,
		"scale_over_velocity_max": 6.0, "inherit_velocity_ratio": 0.0, "collision_mode": RIGID,
		"collision_friction": 0.25, "collision_bounce": 0.0},
	"alpha_curve": BEAD_ALPHA,
	"scale_curve": THREAD,
	"scale_over_velocity_curve": SHUTTER,
	"draw": BEAD_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const FINE_SPRAY := {
	"node": {"amount": 120, "one_shot": true, "explosiveness": 0.9, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.002},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.05, -0.12, -0.012),
		"emission_box_extents": Vector3(0.045, 0.13, 0.004), "direction": LEAVING, "spread": 45.0,
		"initial_velocity_min": 0.3, "initial_velocity_max": 1.0,
		"gravity": Vector3(0.0, -1.0, 0.0), "damping_min": 0.8, "damping_max": 1.6,
		"color": Color(0.82, 0.87, 0.91, 1.0), "scale_min": 0.05, "scale_max": 0.1,
		"inherit_velocity_ratio": 0.0,
		"collision_mode": ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT},
	"alpha_curve": [Vector2(0.0, 0.35), Vector2(0.2, 0.45), Vector2(0.65, 0.15),
		Vector2(1.0, 0.0)],
	"scale_curve": [Vector2(0.0, 0.7), Vector2(0.5, 1.0), Vector2(1.0, 1.4)],
	"draw": {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.0,
		"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 0.0, "sky": 1.2,
		"catch_light": 0.5, "refraction": 0.006, "lens_blur": 0.6, "rim_dark": 0.4,
		"ground_reach": 0.5}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/fine_spray.png",
}
const SPILL_WATER := {
	"node": {"amount": 200, "one_shot": true, "explosiveness": 1.0, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"collision_base_size": 0.005, "transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.05, -0.14, -0.012),
		"emission_box_extents": Vector3(0.05, 0.16, 0.004), "direction": LEAVING, "spread": 32.0,
		"initial_velocity_min": 0.3, "initial_velocity_max": 3.0,
		"gravity": Vector3(0.0, -9.8, 0.0), "damping_min": 0.2, "damping_max": 0.5,
		"color": WATER, "scale_min": 0.3, "scale_max": 0.6, "scale_over_velocity_min": 0.0,
		"scale_over_velocity_max": 6.0, "inherit_velocity_ratio": 0.0, "collision_mode": RIGID,
		"collision_friction": 0.85, "collision_bounce": 0.05},
	"alpha_curve": BEAD_ALPHA,
	"scale_curve": THREAD,
	"scale_over_velocity_curve": SHUTTER,
	"draw": BEAD_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const PILLAR_RUNOFF := {
	"node": {"amount": 24, "one_shot": true, "explosiveness": 0.6, "lifetime": 0.6,
		"local_coords": true, "visibility_aabb": BOX, "preprocess": 0.0,
		"transform_align": ALONG_MOTION},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_shape_offset": Vector3(-0.19, -0.03, -0.02),
		"emission_box_extents": Vector3(0.012, 0.26, 0.006), "direction": Vector3(-0.1, 0.7, 0.7),
		"spread": 8.0, "initial_velocity_min": 0.4, "initial_velocity_max": 1.2,
		"gravity": Vector3(0.0, -2.5, 0.0), "damping_min": 0.0, "damping_max": 0.3,
		"color": WATER, "scale_min": 0.3, "scale_max": 0.5, "scale_over_velocity_min": 0.0,
		"scale_over_velocity_max": 4.0, "inherit_velocity_ratio": 0.0,
		"collision_mode": ParticleProcessMaterial.COLLISION_DISABLED},
	"alpha_curve": [Vector2(0.0, 0.0), Vector2(0.12, 0.8), Vector2(0.7, 0.5), Vector2(1.0, 0.0)],
	"scale_over_velocity_curve": {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 31.0)],
		"z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.5, "min_pixels": 2.0,
		"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 0.0, "sky": 1.5,
		"catch_light": 1.0, "refraction": 0.012, "lens_blur": 0.6, "rim_dark": 0.4,
		"ground_reach": 0.5}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const PASSENGER_BOX := AABB(Vector3(-0.6, -0.3, -0.6), Vector3(1.2, 0.6, 1.2))
const PASSENGER_WATER := {
	"node": {"amount": 100, "one_shot": true, "explosiveness": 1.0, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": PASSENGER_BOX, "preprocess": 0.0,
		"collision_base_size": 0.004, "transform_align": ALONG_MOTION, "layers": 2,
		"fixed_fps": 60},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.004, 0.001, 0.24), "direction": Vector3(1.0, 0.0, 0.0),
		"spread": 20.0, "flatness": 1.0, "initial_velocity_min": 0.6, "initial_velocity_max": 2.2,
		"gravity": Vector3.ZERO, "damping_min": 4.0, "damping_max": 8.0, "color": WATER,
		"scale_min": 0.3, "scale_max": 0.6, "scale_over_velocity_min": 0.0,
		"scale_over_velocity_max": 6.0, "inherit_velocity_ratio": 0.0,
		"collision_mode": ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT},
	"alpha_curve": [Vector2(0.0, 0.0), Vector2(0.05, 0.85), Vector2(0.8, 0.85), Vector2(1.0, 0.0)],
	"scale_over_velocity_curve": SHUTTER,
	"draw": BEAD_DRAW,
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": BEAD,
}
const PASSENGER_LINE := {
	"node": {"amount": 24, "one_shot": true, "explosiveness": 1.0, "lifetime": 1.2,
		"local_coords": true, "visibility_aabb": AABB(Vector3(-0.6, -0.6, -0.3),
		Vector3(1.2, 1.2, 0.6)), "preprocess": 0.0, "collision_base_size": 0.006,
		"transform_align": GPUParticles3D.TRANSFORM_ALIGN_DISABLED, "layers": 2, "fixed_fps": 60},
	"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
		"emission_box_extents": Vector3(0.004, 0.24, 0.001), "direction": Vector3(1.0, 0.0, 0.0),
		"spread": 0.0, "initial_velocity_min": 0.2, "initial_velocity_max": 0.6,
		"gravity": Vector3.ZERO, "damping_min": 4.0, "damping_max": 8.0, "color": WATER,
		"scale_min": 1.0, "scale_max": 1.3, "inherit_velocity_ratio": 0.0,
		"collision_mode": ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT},
	"alpha_curve": [Vector2(0.0, 0.95), Vector2(0.8, 0.8), Vector2(1.0, 0.0)],
	"scale_curve": {"x": [Vector2(0.0, 1.0), Vector2(1.0, 0.6)],
		"y": [Vector2(0.0, 6.0), Vector2(1.0, 4.0)], "z": FLAT},
	"draw": {"shader": SCATTER, "params": {"face_camera": false, "tail": 0.0, "min_pixels": 2.0,
		"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 1.0, "sky": 2.0,
		"catch_light": 1.0, "refraction": 0.02, "lens_blur": 0.6, "rim_dark": 0.4,
		"ground_reach": 0.5}},
	"mesh": {"size": Vector2(0.01, 0.01)},
	"texture": "res://effects/textures/rain_streak.png",
}
const EMITTERS := {"WaterSheet": WATER_SHEET, "BigDrops": BIG_DROPS, "HeavyDrops": HEAVY_DROPS,
	"FineSpray": FINE_SPRAY, "SpillWater": SPILL_WATER, "PillarRunoff": PILLAR_RUNOFF,
	"PassengerWater": PASSENGER_WATER, "PassengerLine": PASSENGER_LINE}

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
		"One WiperFlick root holds its %d emitters (%d children)" % [EMITTERS.size(),
		effect.get_child_count()])
	for emitter_name: String in EMITTERS:
		var emitter := effect.get_node_or_null(emitter_name) as GPUParticles3D
		Readback.check_emitter(emitter, EMITTERS[emitter_name], _check, emitter_name)
		if emitter:
			Readback.check_no_b_features(emitter, _check, emitter_name)
	for emitter_name: String in ["PassengerWater", "PassengerLine"]:
		var emitter := effect.get_node_or_null(emitter_name) as GPUParticles3D
		var quad := emitter.draw_pass_1 as QuadMesh if emitter else null
		var priority: int = quad.material.render_priority if quad and quad.material else -1
		_check(priority == 1,
			"%s draws after the windshield's glass, which would hide water on its outside " % [
			emitter_name] + "(render priority 1, found %d)" % priority)
	effect.free()
	_finish()


func _finish() -> void:
	print("WIPER FLICK CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
