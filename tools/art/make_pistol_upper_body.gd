extends SceneTree
## Writes Ethan's upper-body pistol clips (Assignment 7, CHANGE-BRIEF.md's revision #386-#390):
## game/animations/ethan_pistol.tres, an AnimationLibrary built from the motion-captured clips that
## tools/art/convert_mixamo.py puts in ethan.glb. The glTF export samples every bone, so the
## imported PistolIdle and PistolReload also hold the hips and legs, frozen; played over his walk
## they would stop his legs. This keeps only the tracks of the bones above the waist (spine, neck,
## head, shoulders, arms, hands, fingers), every key as imported, so a second player can lay them
## over his own player's Idle, Walk or Run:
##   PistolIdle    all 250 frames of Mixamo's "Pistol Idle", LOOP_LINEAR
##   PistolReload  all 100 frames of Mixamo's "Reloading", LOOP_NONE
##   PistolAim     PistolReload's first frame held: his two-handed aim, LOOP_NONE
## Built by this committed script, never at runtime. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/make_pistol_upper_body.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const TARGET := "res://animations/ethan_pistol.tres"
const UPPER := ["Spine", "Neck", "Head", "Shoulder", "Arm", "Hand"]
const FPS := 30.0


func _initialize() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var library := AnimationLibrary.new()
	library.add_animation("PistolIdle", _upper(player.get_animation("PistolIdle"),
		Animation.LOOP_LINEAR))
	var reload := _upper(player.get_animation("PistolReload"), Animation.LOOP_NONE)
	library.add_animation("PistolReload", reload)
	library.add_animation("PistolAim", _first_frame(reload))
	var error := ResourceSaver.save(library, TARGET)
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name)
		print("UPPER: %s %d tracks, %.0f frames, loop %d" % [clip_name, clip.get_track_count(),
			roundf(clip.length * FPS), clip.loop_mode])
	print("UPPER: saved %s (%s)" % [TARGET, error_string(error)])
	model.free()
	quit(0 if error == OK else 1)


func _upper(source: Animation, loop: Animation.LoopMode) -> Animation:
	var clip := source.duplicate(true) as Animation
	for t in range(clip.get_track_count() - 1, -1, -1):
		var path := clip.track_get_path(t)
		var bone := String(path.get_concatenated_subnames()) if path.get_subname_count() else ""
		var keep := false
		for part in UPPER:
			keep = keep or bone.contains(part)
		if not keep:
			clip.remove_track(t)
	clip.loop_mode = loop
	clip.step = 1.0 / FPS
	return clip


func _first_frame(source: Animation) -> Animation:
	var clip := Animation.new()
	clip.length = 1.0 / FPS
	clip.step = 1.0 / FPS
	clip.loop_mode = Animation.LOOP_NONE
	for t in source.get_track_count():
		var kind := source.track_get_type(t)
		var index := clip.add_track(kind)
		clip.track_set_path(index, source.track_get_path(t))
		clip.track_insert_key(index, 0.0, source.track_get_key_value(t, 0))
	return clip
