extends SceneTree
## B1, rain in every lamp's light: reads back every setting CHANGE-BRIEF.md §4 (and its
## revision 1) names from the three scenes, including the feature neither A effect uses:
## collision with a height field, and splashes through a sub-emitter.

const Readback = preload("res://tests/particle_readback.gd")
const SLANT := Vector3(0.08, -0.997, 0.0)
const VARIANTS := {
	"res://effects/lamp_rain_post.tscn": {"root": "LampRainPost",
		"box": Vector3(3.0, 0.2, 3.0), "direction": SLANT,
		"aabb": AABB(Vector3(-4.0, -8.5, -4.0), Vector3(8.0, 10.0, 8.0)),
		"collider": Vector3(8.0, 10.0, 8.0), "collider_at": Vector3(0.0, -3.5, 0.0)},
	"res://effects/lamp_rain_floodlight.tscn": {"root": "LampRainFloodlight",
		"box": Vector3(3.5, 0.1, 6.5), "direction": Vector3(0.023, -0.997, 0.077),
		"aabb": AABB(Vector3(-4.5, -5.0, -7.5), Vector3(9.0, 6.0, 15.0)),
		"collider": Vector3(9.0, 6.0, 15.0), "collider_at": Vector3(0.0, -2.0, 0.0)},
	"res://effects/lamp_rain_door.tscn": {"root": "LampRainDoor",
		"box": Vector3(1.0, 0.1, 0.8), "direction": SLANT,
		"aabb": AABB(Vector3(-1.5, -3.5, -1.5), Vector3(3.0, 4.0, 3.0)),
		"collider": Vector3(3.0, 4.0, 3.0), "collider_at": Vector3(0.0, -1.5, 0.0)},
}
const WATER := Color(0.88, 0.89, 0.9, 1.0)
const BACKLIGHT := Color(0.8, 0.8, 0.8, 1.0)

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
	effect.free()


func _rain(variant: Dictionary) -> Dictionary:
	return {
		"node": {"amount": 160, "one_shot": false, "explosiveness": 0.0, "lifetime": 1.1,
			"local_coords": false, "visibility_aabb": variant["aabb"], "preprocess": 1.1,
			"emitting": false, "collision_base_size": 0.01,
			"sub_emitter": NodePath("../LampSplash"),
			"transform_align": GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY},
		"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			"emission_box_extents": variant["box"], "initial_velocity_min": 6.5,
			"initial_velocity_max": 8.5, "direction": variant["direction"], "spread": 4.0,
			"gravity": Vector3(0.0, -0.5, 0.0), "damping_min": 0.0, "damping_max": 0.15,
			"color": WATER, "scale_min": 0.7, "scale_max": 1.35,
			"collision_mode": ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT,
			"sub_emitter_mode": ParticleProcessMaterial.SUB_EMITTER_AT_COLLISION,
			"sub_emitter_amount_at_collision": 4},
		"alpha_curve": [Vector2(0.0, 0.1), Vector2(0.15, 0.45), Vector2(0.75, 0.45),
			Vector2(1.0, 0.0)],
		"scale_curve": [Vector2(0.0, 0.9), Vector2(0.5, 1.0), Vector2(1.0, 0.9)],
		"draw": {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,
			"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,
			"vertex_color_use_as_albedo": true, "backlight_enabled": true,
			"backlight": BACKLIGHT, "billboard_mode": BaseMaterial3D.BILLBOARD_DISABLED},
		"mesh": {"size": Vector2(0.01, 0.25)},
		"texture": "res://effects/textures/rain_streak.png",
	}


func _splash(variant: Dictionary) -> Dictionary:
	return {
		"node": {"amount": 160, "one_shot": false, "explosiveness": 0.0, "lifetime": 0.25,
			"local_coords": false, "visibility_aabb": variant["aabb"], "preprocess": 0.0,
			"emitting": true},
		"process": {"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_POINT,
			"initial_velocity_min": 0.6, "initial_velocity_max": 1.6,
			"direction": Vector3(0.0, 1.0, 0.0), "spread": 60.0,
			"gravity": Vector3(0.0, -9.8, 0.0), "color": WATER, "scale_min": 0.1,
			"scale_max": 0.3},
		"alpha_curve": [Vector2(0.0, 0.6), Vector2(1.0, 0.0)],
		"draw": {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,
			"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,
			"vertex_color_use_as_albedo": true, "backlight_enabled": true,
			"backlight": BACKLIGHT, "billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES},
		"mesh": {"size": Vector2(0.01, 0.01)},
		"texture": "res://effects/textures/water_bead.png",
	}


func _finish() -> void:
	print("LAMP RAIN CONFIG RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(0 if _failures == 0 else 1)
