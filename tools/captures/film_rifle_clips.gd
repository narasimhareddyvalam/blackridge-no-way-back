extends SceneTree
## A film of the rifle clips on Ethan for the author (Assignment 7, #396-#400), built as driver.gd will
## build them: his own player (Idle, or the rifle's gaits, whole body), UpperBody with
## game/animations/ethan_rifle.tres over it, the M16 slung on his upper back (SLUNG, on Spine2) or in
## his hands, and slung at his right hip, by game/features/weapons/rifle/rifle_hold.gd ( the grip in his right fist, the barrel
## through his left fist while it is under the front, his left hand drawn onto the part it holds by
## IK; in the reload the magazine dropped, a fresh one in his left hand, seated), slung at his right
## hip where his own put-away leaves it and his draw takes it, easing from his back to his hand over
## frames 22-28 of the draw and back onto his back for 0.35 s after frame 40 of the put-away. Real speed, 0.25 s blends: slung, the draw, the
## ready, raised to aim, three shots, the complete reload, a hit, lowered, the second ready, put
## away; then the gaits and turns. A Movie Maker run; a plain lit room, not the game's world.

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
const RIFLE := preload("res://features/weapons/rifle/m16.glb")
const RifleHold = preload("res://features/weapons/rifle/rifle_hold.gd")
const BLEND := 0.25

var _legs: AnimationPlayer
var _upper: AnimationPlayer
var _rifle: Node3D
## 0 on his back, 1 in his hand: the rifle follows a blend of the two each frame.
var _hold: RefCounted
var _magazine: MeshInstance3D
var _fresh: MeshInstance3D
var _dropped: MeshInstance3D
var _fall := Vector3.ZERO
## The magazine's place in the rifle (relative to the rifle's root, with the model's own scale).
var _magazine_in_rifle := Transform3D.IDENTITY
## The charging handle and the bolt carrier, and their places in the rifle at rest.
var _sliders: Array[MeshInstance3D] = []
var _slider_rest: Array[Transform3D] = []
var _label: Label


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.34, 0.37)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.62, 0.65)
	environment.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 145.0, 0.0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	root.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	ground.mesh = plane
	root.add_child(ground)
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_legs = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_legs.play("Idle")
	_upper = AnimationPlayer.new()
	_upper.process_priority = 1
	model.add_child(_upper)
	_upper.add_animation_library("", load(POSE))
	_hold = RifleHold.new(skeleton)
	_hold.call("setup_left_arm", model)
	_rifle = RIFLE.instantiate() as Node3D
	root.add_child(_rifle)
	_rifle.top_level = true
	_magazine = _rifle.find_child("MAGAZINE_M16A3_0", true, false) as MeshInstance3D
	_magazine_in_rifle = _rifle.global_transform.affine_inverse() * _magazine.global_transform
	for part in ["CHANRIGN HANDLE_M16A3_0", "BOLT CARRIER_M16A3_0"]:
		var mesh := _rifle.find_child(part, true, false) as MeshInstance3D
		_sliders.append(mesh)
		_slider_rest.append(_rifle.global_transform.affine_inverse() * mesh.global_transform)
	_fresh = _magazine.duplicate() as MeshInstance3D
	root.add_child(_fresh)
	_fresh.top_level = true
	_fresh.visible = false
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 18)
	_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(_label)
	var camera := Camera3D.new()
	camera.fov = 42.0
	root.add_child(camera)
	camera.make_current()
	camera.global_position = Vector3(1.9, 1.6, 2.3)
	camera.look_at(Vector3(0.1, 1.15, 0.2))
	await _say("Slung on his back", 1.5)
	await _draw()
	_upper.play("RifleIdleA", BLEND)
	await _say("Ready (Rifle Idle)", 3.0)
	_upper.play_backwards("RifleAimDown", BLEND)
	await _say("Raise (Rifle Aim To Down, backward)", 46.0 / 30.0)
	_upper.play("RifleAim", BLEND)
	await _say("Aim (rifle aiming idle)", 1.5)
	for shot in range(3):
		_upper.play("RifleFire", 0.05)
		await _say("Fire (firing rifle) %d" % (shot + 1), 9.0 / 30.0 + 0.15)
	_upper.play("RifleAim", BLEND)
	await _say("Aim", 0.8)
	_upper.play("RifleReload", BLEND)
	await _say("Reload (reloading, all 100 frames)", 100.0 / 30.0)
	_upper.play("RifleAim", BLEND)
	await _say("Aim", 0.8)
	_upper.play("RifleHit", 0.1)
	await _say("Hit (hit reaction)", 14.0 / 30.0)
	_upper.play("RifleAimDown", BLEND)
	await _say("Lower (Rifle Aim To Down)", 46.0 / 30.0)
	_upper.play("RifleIdleB", BLEND)
	await _say("Ready (Rifle Idle (1))", 3.0)
	await _put_away()
	_upper.stop()
	await _say("Slung at his right hip", 1.0)
	_hold.set("slung", false)
	for gait in [["RifleWalk", "Walk"], ["RifleWalkBack", "Walk backwards"], ["RifleRun", "Run"],
			["RifleRunBack", "Run backwards"], ["RifleStrafeLeft", "Strafe left"],
			["RifleStrafeRight", "Strafe right"], ["RifleStrafe", "Strafe"],
			["RifleStrafe2", "Strafe (2)"], ["RifleTurnLeft", "Turn left"],
			["RifleTurnRight", "Turn right 45"]]:
		_legs.play(gait[0], BLEND)
		await _say("%s (%s, whole body)" % [gait[1], gait[0]], 2.0)
	quit(0)


func _process(delta: float) -> bool:
	if _rifle != null:
		var clip := String(_upper.current_animation) if _upper.is_playing() else ""
		var frame := _upper.current_animation_position * 30.0 if _upper.is_playing() else 0.0
		_rifle.global_transform = _hold.call("place", delta, clip, frame)
		var travel: float = _hold.call("charging_at", clip, frame)
		for i in _sliders.size():
			var rest := _slider_rest[i]
			_sliders[i].global_transform = _rifle.global_transform * Transform3D(rest.basis,
				rest.origin + Vector3(0.0, 0.0, travel))
		_reload_magazine(clip, frame, delta)
	return false


## The reload's magazines: the empty one drops from the well, a fresh one rides in his left hand from
## his belt and goes into the well, seated.
func _reload_magazine(clip: String, frame: float, delta: float) -> void:
	var where: String = _hold.call("magazine_at", clip, frame)
	_magazine.visible = where == "gun"
	if where != "gun" and _dropped == null and frame < 30.0:
		_dropped = _magazine.duplicate() as MeshInstance3D
		root.add_child(_dropped)
		_dropped.top_level = true
		_dropped.global_transform = _magazine.global_transform
		_dropped.visible = true
		_fall = Vector3.ZERO
	if _dropped != null:
		if _dropped.global_position.y > 0.03:
			_fall += Vector3.DOWN * 9.8 * delta
			_dropped.global_position += _fall * delta
		if clip != "RifleReload":
			_dropped.queue_free()
			_dropped = null
	_fresh.visible = where == "hand"
	if where == "hand":
		_fresh.global_transform = _hold.call("magazine_in_hand", _rifle.global_transform,
			_magazine_in_rifle)


func _draw() -> void:
	_upper.play("RifleGrab", BLEND)
	_label.text = "Draw (Grab Rifle From Back)"
	while _upper.current_animation == "RifleGrab" and _upper.is_playing():
		await process_frame
	_hold.set("slung", false)


func _put_away() -> void:
	_upper.play("RifleAway", BLEND)
	_label.text = "Put away (Rifle Put Away)"
	while _upper.current_animation == "RifleAway" and _upper.is_playing():
		await process_frame
	_hold.set("slung", true)


func _say(words: String, seconds: float) -> void:
	_label.text = words
	await create_timer(seconds).timeout
