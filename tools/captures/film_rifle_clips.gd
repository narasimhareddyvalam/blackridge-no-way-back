extends SceneTree
## A film of the rifle clips on Ethan for the author (Assignment 7, #396), built as driver.gd will
## build them: his own player (Idle, or the rifle's gaits, whole body), UpperBody with
## game/animations/ethan_rifle.tres over it, the M16 slung on his upper back (SLUNG, on Spine2) or in
## his hands (game/features/weapons/rifle/rifle_hold.gd: the grip in his right fist, the barrel
## through his left fist while it is under the front), easing from his back to his hand over
## frames 22-28 of the draw and back onto his back for 0.35 s after frame 40 of the put-away. Real speed, 0.25 s blends: slung, the draw, the
## ready, raised to aim, three shots, the complete reload, a hit, lowered, the second ready, put
## away; then the gaits and turns. A Movie Maker run; a plain lit room, not the game's world.

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
const RIFLE := preload("res://features/weapons/rifle/m16.glb")
const RifleHold = preload("res://features/weapons/rifle/rifle_hold.gd")
const IN_HANDS := Transform3D(Vector3(77.3186, 15.674, -61.4504),
	Vector3(60.9294, 8.51759, 78.8356), Vector3(17.5908, -98.396, -2.96439),
	Vector3(5.13684, 16.5887, 8.61718))
const SLUNG := Transform3D(Vector3(-83.35921, 55.23804, -0.000001),
	Vector3(-2.217297, -3.346099, -99.91941), Vector3(-55.19352, -83.29205, 4.014071),
	Vector3(0.552367, -36.17239, -22.57224))
## The draw: the rifle stays on his back until his fist reaches its grip at TAKE_FROM, then rides
## in his fist, turning from its slung angle to his hold by TAKE_TO; the put-away: he lets go at
## LET_GO_FRAME and it swings onto his back over SWING seconds.
const TAKE_FROM := 25
const TAKE_TO := 33
const LET_GO_FRAME := 40
const SWING := 0.35
const GRIP := Vector3(0.0, -0.105, 0.088)
const BLEND := 0.25

var _legs: AnimationPlayer
var _upper: AnimationPlayer
var _rifle: Node3D
var _back: BoneAttachment3D
var _hand: BoneAttachment3D
## 0 on his back, 1 in his hand: the rifle follows a blend of the two each frame.
var _held := 0.0
var _in_fist := false
var _hold: RefCounted
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
	_back = BoneAttachment3D.new()
	_back.bone_name = "mixamorig_Spine2"
	skeleton.add_child(_back)
	_hand = BoneAttachment3D.new()
	_hand.bone_name = "mixamorig_RightHand"
	skeleton.add_child(_hand)
	_hold = RifleHold.new(skeleton)
	_rifle = RIFLE.instantiate() as Node3D
	root.add_child(_rifle)
	_rifle.top_level = true
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
	await _say("Slung across his back", 1.0)
	_held = 1.0
	_in_fist = true
	for gait in [["RifleWalk", "Walk"], ["RifleWalkBack", "Walk backwards"], ["RifleRun", "Run"],
			["RifleRunBack", "Run backwards"], ["RifleStrafeLeft", "Strafe left"],
			["RifleStrafeRight", "Strafe right"], ["RifleStrafe", "Strafe"],
			["RifleStrafe2", "Strafe (2)"], ["RifleTurnLeft", "Turn left"],
			["RifleTurnRight", "Turn right 45"]]:
		_legs.play(gait[0], BLEND)
		await _say("%s (%s, whole body)" % [gait[1], gait[0]], 2.0)
	quit(0)


func _process(delta: float) -> bool:
	if _rifle != null and _back != null:
		var back := _back.global_transform * SLUNG
		var clip := String(_upper.current_animation) if _upper.is_playing() else ""
		var hand: Transform3D = _hold.call("place", delta, clip)
		var t := smoothstep(0.0, 1.0, _held)
		var basis := back.basis.orthonormalized().slerp(hand.basis.orthonormalized(), t)
		var grip := hand * GRIP if _in_fist else (back * GRIP).lerp(hand * GRIP, t)
		_rifle.global_transform = Transform3D(basis, grip - basis * GRIP)
	return false


func _draw() -> void:
	_upper.play("RifleGrab", BLEND)
	_label.text = "Draw (Grab Rifle From Back)"
	while _upper.current_animation == "RifleGrab" and _upper.is_playing():
		var frame := _upper.current_animation_position * 30.0
		_in_fist = frame >= TAKE_FROM
		_held = clampf(inverse_lerp(TAKE_FROM, TAKE_TO, frame), 0.0, 1.0)
		await process_frame
	_held = 1.0
	_in_fist = true


func _put_away() -> void:
	_upper.play("RifleAway", BLEND)
	_label.text = "Put away (Rifle Put Away)"
	while _upper.current_animation_position * 30.0 < LET_GO_FRAME:
		await process_frame
	_in_fist = false
	var clock := 0.0
	while clock < SWING:
		await process_frame
		clock += 1.0 / 30.0
		_held = 1.0 - clock / SWING
	_held = 0.0
	while _upper.is_playing() and _upper.current_animation == "RifleAway":
		await process_frame


func _say(words: String, seconds: float) -> void:
	_label.text = words
	await create_timer(seconds).timeout
