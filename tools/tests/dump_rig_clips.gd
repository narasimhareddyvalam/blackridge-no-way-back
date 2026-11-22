extends SceneTree
## Writes every clip of Ethan's rig (`ethan.glb`) as numbers, for Assignment 7's check that a
## re-conversion changes no earlier clip: for each clip its length and loop mode, and for each
## track, sampled every 5 frames at 30 fps, its position, rotation or scale; and each bone's rest
## pose (`__rest__`). The JSON goes to the
## path after `--`. Compared by tools/tests/compare_rig_clips.py.

const RIG := "res://features/characters/ethan/ethan.glb"


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var clips := {}
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var rests := {}
	for bone in skeleton.get_bone_count():
		var rest := skeleton.get_bone_rest(bone)
		var q := rest.basis.get_rotation_quaternion()
		var o := rest.origin
		var sc := rest.basis.get_scale()
		rests[skeleton.get_bone_name(bone)] = {"1": [o.x, o.y, o.z], "2": [q.x, q.y, q.z, q.w],
			"3": [sc.x, sc.y, sc.z]}
	clips["__rest__"] = rests
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		var tracks := {}
		for t in clip.get_track_count():
			var kind := clip.track_get_type(t)
			var samples := []
			var time := 0.0
			while time <= clip.length + 0.0001:
				var value: Variant = null
				match kind:
					Animation.TYPE_POSITION_3D:
						value = clip.position_track_interpolate(t, time)
					Animation.TYPE_ROTATION_3D:
						var q := clip.rotation_track_interpolate(t, time)
						value = [q.x, q.y, q.z, q.w]
					Animation.TYPE_SCALE_3D:
						value = clip.scale_track_interpolate(t, time)
				if value is Vector3:
					value = [value.x, value.y, value.z]
				samples.append(value)
				time += 5.0 / 30.0
			tracks["%s|%d" % [clip.track_get_path(t), kind]] = samples
		clips[clip_name] = {"length": clip.length, "loop": clip.loop_mode, "tracks": tracks}
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(clips))
	file.close()
	print("DUMP: %d clips to %s" % [clips.size() - 1, out])
	model.free()
	quit()
