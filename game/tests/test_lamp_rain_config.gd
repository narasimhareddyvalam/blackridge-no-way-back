extends SceneTree
## B1, rain in every lamp's light: reads back every setting CHANGE-BRIEF.md §4 (and its
## revision 1) names from the three scenes, as TUNING.md's r1 revises them at the author's request
## (#146, #149): real rain's mix of drop sizes and speeds, each drop drawn as the streak it leaves
## in a 1/30 s frame, denser than before. The street scene (#156) fills the street lamps' wider
## pool, and with the post scene under the depot's wall lights scatters less light since those
## lamps became realistic (#150, #154). Also the feature neither A effect uses: collision with a
## height field, and splashes through a sub-emitter; the drops collide as rigid bodies, since
## Godot 4.7.2 fires a collision sub-emitter only then, and fade once they stop (#156).

const Readback = preload("res://tests/particle_readback.gd")
const SLANT := Vector3(0.08, -0.997, 0.0)
const BRIGHT_SPLASH := {"splash_scale": Vector2(0.05, 0.15), "splash_scatter": 30.0,
	"splash_diffuse": 1.0}
const PLAIN_SPLASH := {"splash_scale": Vector2(0.03, 0.1), "splash_scatter": 60.0,
	"splash_diffuse": 0.3}
const VARIANTS := {
	"res://effects/lamp_rain_street.tscn": {"root": "LampRainStreet",
		"box": Vector3(5.0, 0.2, 5.0), "direction": SLANT, "drops": 5000, "splashes": 2750,
		"scatter": 5.0, "splash": BRIGHT_SPLASH,
		"aabb": AABB(Vector3(-6.0, -8.5, -6.0), Vector3(12.0, 10.0, 12.0)),
		"collider": Vector3(12.0, 10.0, 12.0), "collider_at": Vector3(0.0, -3.5, 0.0)},
	"res://effects/lamp_rain_post.tscn": {"root": "LampRainPost",
		"box": Vector3(3.0, 0.2, 3.0), "direction": SLANT, "drops": 2000, "splashes": 1100,
		"scatter": 5.0, "splash": BRIGHT_SPLASH,
		"aabb": AABB(Vector3(-4.0, -8.5, -4.0), Vector3(8.0, 10.0, 8.0)),
		"collider": Vector3(8.0, 10.0, 8.0), "collider_at": Vector3(0.0, -3.5, 0.0)},
	"res://effects/lamp_rain_floodlight.tscn": {"root": "LampRainFloodlight",
		"box": Vector3(3.5, 0.1, 6.5), "direction": Vector3(0.023, -0.997, 0.077),
		"drops": 3200, "splashes": 1800, "scatter": 60.0, "splash": PLAIN_SPLASH,
		"aabb": AABB(Vector3(-4.5, -5.0, -7.5), Vector3(9.0, 6.0, 15.0)),
		"collider": Vector3(9.0, 6.0, 15.0), "collider_at": Vector3(0.0, -2.0, 0.0)},
	"res://effects/lamp_rain_door.tscn": {"root": "LampRainDoor",
		"box": Vector3(1.0, 0.1, 0.8), "direction": SLANT, "drops": 300, "splashes": 170,
		"scatter": 60.0, "splash": PLAIN_SPLASH,
		"aabb": AABB(Vector3(-1.5, -3.5, -1.5), Vector3(3.0, 4.0, 3.0)),
		"collider": Vector3(3.0, 4.0, 3.0), "collider_at": Vector3(0.0, -1.5, 0.0)},
}
const WATER := Color(0.88, 0.89, 0.9, 1.0)
const SCATTER := "res://effects/scatter_particle.gdshader"
const FLAT: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(1.0, 1.0)]

const WATER_ON_GLASS := 2

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
	for path: String in VARIANTS:
		_check_variant(path, VARIANTS[path])
	_finish()


func _check_variant(path: String, variant: Dictionary) -> void:
	var packed := load(path) as PackedScene
	_check(packed != null, "%s loads" % path)
	if packed == null:
		return
	var effect := packed.instantiate()
	var root: String = variant["root"]
	_check(effect.name == root and effect.get_child_count() == 3,
		"%s holds LampRain, LampSplash and the collider (%d children)" % [root,
		effect.get_child_count()])
	Readback.check_emitter(effect.get_node_or_null("LampRain"), _rain(variant), _check,
		root + "/LampRain")
	Readback.check_emitter(effect.get_node_or_null("LampSplash"), _splash(variant), _check,
		root + "/LampSplash")
	var collider := effect.get_node_or_null("Collider") as GPUParticlesCollisionHeightField3D
	_check(collider != null, "%s has a GPUParticlesCollisionHeightField3D" % root)
	if collider:
		_check(collider.size.is_equal_approx(variant["collider"])
			and collider.position.is_equal_approx(variant["collider_at"]),
			"%s collider is %s at %s (found %s at %s)" % [root, variant["collider"],
			variant["collider_at"], collider.size, collider.position])
		_check(collider.resolution == GPUParticlesCollisionHeightField3D.RESOLUTION_256
			and collider.update_mode == GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
			and not collider.follow_camera_enabled,
			"%s collider: 256 resolution, updated always, not following the camera" % root)
		_check(collider.cull_mask & WATER_ON_GLASS == 0,
			"%s collider leaves the water on the van's glass alone (its mask leaves out " % root
			+ "layer %d), so only a wiper blade clears it" % WATER_ON_GLASS)
	effect.free()


func _rain(variant: Dictionary) -> Dictionary:
	return {
		"node": {"amount": variant["drops"], "one_shot": false, "explosiveness": 0.0,
			"lifetime": 1.1, "fixed_fps": 60,
			"local_coords": false, "visibility_aabb": variant["aabb"], "preprocess": 1.1,
			"emitting": false, "collision_base_size": 0.01,
			"sub_emitter": NodePath("../LampSplash"),
			"transform_align": GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY},
		"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			"emission_box_extents": variant["box"], "initial_velocity_min": 3.5,
			"initial_velocity_max": 8.5, "direction": variant["direction"], "spread": 4.0,
			"gravity": Vector3(0.0, -0.5, 0.0), "damping_min": 0.0, "damping_max": 0.15,
			"color": WATER, "scale_min": 0.1, "scale_max": 0.25,
			"scale_over_velocity_min": 0.0, "scale_over_velocity_max": 9.0,
			"collision_mode": ParticleProcessMaterial.COLLISION_RIGID, "collision_friction": 1.0,
			"collision_bounce": 0.0,
			"sub_emitter_mode": ParticleProcessMaterial.SUB_EMITTER_AT_COLLISION,
			"sub_emitter_amount_at_collision": 3},
		"alpha_curve": [Vector2(0.0, 0.1), Vector2(0.15, 0.8), Vector2(0.75, 0.8),
			Vector2(1.0, 0.0)],
		"scale_curve": [Vector2(0.0, 0.9), Vector2(0.5, 1.0), Vector2(1.0, 0.9)],
		"scale_over_velocity_curve": {"x": FLAT, "y": [Vector2(0.0, 1.0), Vector2(1.0, 201.0)],
			"z": FLAT},
		"draw": {"shader": SCATTER, "params": {"face_camera": false, "min_pixels": 1.0,
			"forward_scatter": 0.5, "scatter": variant["scatter"], "diffuse": 0.3, "glint": 0.0,
			"sky": 0.0, "still_fade": 1.0}},
		"mesh": {"size": Vector2(0.01, 0.01)},
		"texture": "res://effects/textures/rain_streak.png",
	}


func _splash(variant: Dictionary) -> Dictionary:
	return {
		"node": {"amount": variant["splashes"], "one_shot": false, "explosiveness": 0.0,
			"lifetime": 0.2,
			"local_coords": false, "visibility_aabb": variant["aabb"], "preprocess": 0.0,
			"emitting": true},
		"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
			"emission_shape_offset": Vector3(0.0, 0.03, 0.0),
			"initial_velocity_min": 0.5, "initial_velocity_max": 1.3,
			"direction": Vector3(0.0, 1.0, 0.0), "spread": 70.0,
			"gravity": Vector3(0.0, -9.8, 0.0), "color": WATER,
			"scale_min": variant["splash"]["splash_scale"].x,
			"scale_max": variant["splash"]["splash_scale"].y},
		"alpha_curve": [Vector2(0.0, 0.6), Vector2(1.0, 0.0)],
		"draw": {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.0,
			"forward_scatter": 0.5, "scatter": variant["splash"]["splash_scatter"],
			"diffuse": variant["splash"]["splash_diffuse"], "glint": 0.0, "sky": 0.0}},
		"mesh": {"size": Vector2(0.01, 0.01)},
		"texture": "res://effects/textures/water_bead.png",
	}


func _finish() -> void:
	print("LAMP RAIN CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
