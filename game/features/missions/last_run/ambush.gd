extends Node
## Mission 3's step 3, part B: the ambush at berth 2 (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360).
## The van stopped in berth 2, the trap closes in a cutscene: two black SUVs waiting between the
## stacks light up, three men in dark jackets come out with pistols, one at the driver's window
## grabbing for the door; shots, one into the windshield; the man's phone falls into the cab as
## Ethan floors it. Then the escape: one SUV races round to block the gate; out through it first and
## he is away (`escaped`), there first and they have him (`caught`): all is put back at the berth
## and the escape begins again without the cutscene. The men shoot as he goes; nothing in the game
## is harmed by it but the glass. Words and choices are Claude Code's (#359), drafts.

signal caught
signal escaped_now

const SUV = preload("res://features/vehicles/scripted_suv/scripted_suv.gd")
const MAN = preload("res://features/characters/syndicate_man/syndicate_man.glb")
const PISTOL = preload("res://features/weapons/pistol/pistol.glb")
const SHOT = preload("res://features/audio/last_run/pistol_shot.wav")
const GLASS = preload("res://features/audio/last_run/glass_hit.wav")
const GATE := Vector3(840.0, 0.0, 200.0)
const AT_BERTH := 3.0
const STOPPED := 0.4
## Where the SUVs wait between the stacks, facing the lane, and where the first rolls out to.
const SUV_A := Transform3D(Basis(Vector3.UP, PI), Vector3(906.0, 0.0, 182.0))
const SUV_B := Transform3D(Basis.IDENTITY, Vector3(906.0, 0.0, 280.0))
const SUV_A_OUT: Array[Vector3] = [Vector3(906.0, 0.0, 206.0)]
## The second SUV's way round to the gate, and where it stops across it.
const BLOCK_ROUTE: Array[Vector3] = [Vector3(906.0, 0.0, 250.0), Vector3(872.0, 0.0, 213.0),
	Vector3(848.0, 0.0, 204.0), Vector3(843.6, 0.0, 200.0)]
const BLOCK_AT := Transform3D(Basis(Vector3.UP, PI), Vector3(843.6, 0.0, 200.0))
const BLOCK_SPEED := 7.0
const BLOCK_DELAY := 1.0
const RETRY_DELAY := 3.0
const CAUGHT_AFTER := 1.5
## The men's posts: one by the driver's window (placed from the van), two by the SUVs.
const MEN_AT: Array[Vector3] = [Vector3.ZERO, Vector3(913.0, 0.0, 214.0),
	Vector3(914.0, 0.0, 252.0)]
const WINDOW_POST := Vector3(-1.75, 0.0, -0.75)
## The cutscene's moments, seconds from its start.
const LIGHTS_AT := 3.0
const MEN_STEP_AT := 5.5
const SHOTS_AT := 8.0
const FIRE_EVERY := 0.9

var suvs: Array[Node3D] = []
var men: Array[Node3D] = []
var phone_in_cab := false
var escaped := false
var caught_count := 0
var phase := "waiting"
var vehicle: CharacterBody3D
var berth := Vector3.ZERO
## Plays a cutscene's shots (the app's director), and says whether one is playing.
var play_cutscene: Callable
var cutscene_playing: Callable
var _clock := 0.0
var _events := 0
var _blocked_for := 0.0
var _fire := 0.0
var _shot_player: AudioStreamPlayer3D
var _glass_player: AudioStreamPlayer3D
var _flash: OmniLight3D


func _ready() -> void:
	for at in [SUV_A, SUV_B]:
		var suv := SUV.new()
		add_child(suv)
		suv.place(at)
		suvs.append(suv)
	for index in range(MEN_AT.size()):
		var man := MAN.instantiate() as Node3D
		man.name = "SyndicateMan%d" % (index + 1)
		man.set_meta("model", MAN.resource_path)
		add_child(man)
		man.rotation.y = PI
		_arm(man)
		var player := man.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		player.play("Idle")
		man.visible = false
		men.append(man)
	_shot_player = AudioStreamPlayer3D.new()
	_shot_player.stream = SHOT
	_shot_player.unit_size = 30.0
	_shot_player.max_polyphony = 4
	add_child(_shot_player)
	_glass_player = AudioStreamPlayer3D.new()
	_glass_player.stream = GLASS
	_glass_player.unit_size = 6.0
	add_child(_glass_player)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.8, 0.45)
	_flash.omni_range = 7.0
	_flash.light_energy = 0.0
	add_child(_flash)


## A pistol in the man's right hand.
func _arm(man: Node3D) -> void:
	var skeleton := man.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var hand := BoneAttachment3D.new()
	hand.bone_name = "mixamorig_RightHand"
	skeleton.add_child(hand)
	var pistol := PISTOL.instantiate() as Node3D
	pistol.name = "Pistol"
	hand.add_child(pistol)
	pistol.position = Vector3(0.0, 0.08, 0.03)


## All as before the van came: the SUVs dark in their places, the men out of sight.
func reset() -> void:
	phase = "waiting"
	escaped = false
	phone_in_cab = false
	_clock = 0.0
	_events = 0
	_blocked_for = 0.0
	suvs[0].call("place", SUV_A)
	suvs[1].call("place", SUV_B)
	for suv in suvs:
		suv.call("set_lights", false)
	for man in men:
		man.visible = false


## Back at the berth after being caught: the trap already sprung, the escape on again.
func retry() -> void:
	_blocked_for = 0.0
	escaped = false
	suvs[0].call("place", Transform3D(SUV_A.basis, SUV_A_OUT[0]))
	suvs[1].call("place", SUV_B)
	for suv in suvs:
		suv.call("set_lights", true)
	_post_men()
	phase = "retry"
	_clock = 0.0


func gate_blocked() -> bool:
	return phase in ["escape", "retry"] and bool(suvs[1].call("arrived")) \
		and Vector2(suvs[1].global_position.x - BLOCK_AT.origin.x,
		suvs[1].global_position.z - BLOCK_AT.origin.z).length() < 0.5


func _physics_process(delta: float) -> void:
	if vehicle == null:
		return
	match phase:
		"waiting":
			if bool(vehicle.get("occupied")) and absf(float(vehicle.get("speed"))) < STOPPED \
					and Vector2(vehicle.global_position.x - berth.x,
					vehicle.global_position.z - berth.z).length() < AT_BERTH:
				_spring()
		"scene":
			_clock += delta
			_scene_events()
			if _clock > 1.0 and not bool(cutscene_playing.call()):
				_begin_escape(BLOCK_DELAY)
		"retry":
			_clock += delta
			if _clock >= RETRY_DELAY:
				_begin_escape(0.0)
		"escape":
			_escape(delta)


func _spring() -> void:
	phase = "scene"
	_clock = 0.0
	_events = 0
	_post_men()
	for man in men:
		man.visible = false
	play_cutscene.call(_shots())


func _post_men() -> void:
	for index in range(men.size()):
		var man := men[index]
		man.visible = true
		var at := MEN_AT[index]
		if index == 0:
			at = vehicle.to_global(WINDOW_POST)
		man.global_position = Vector3(at.x, 0.0, at.z)
		var look := vehicle.global_position - man.global_position
		man.rotation.y = atan2(look.x, look.z)


func _scene_events() -> void:
	if _events == 0 and _clock >= LIGHTS_AT:
		_events = 1
		for suv in suvs:
			suv.call("set_lights", true)
	if _events == 1 and _clock >= MEN_STEP_AT:
		_events = 2
		for man in men:
			man.visible = true
		suvs[0].call("drive", SUV_A_OUT, 3.0)
	if _events == 2 and _clock >= SHOTS_AT:
		_events = 3
		_shoot(men[1])
		var glass := vehicle.to_global(Vector3(0.35, 1.75, -1.75))
		(vehicle.get_node("VanPresentation") as Node).call("crack_at", glass, 0.45)
		_glass_player.global_position = glass
		_glass_player.play()
		phone_in_cab = true


func _begin_escape(delay: float) -> void:
	phase = "escape"
	_clock = -delay
	suvs[0].call("place", Transform3D(SUV_A.basis, SUV_A_OUT[0]))


func _escape(delta: float) -> void:
	_clock += delta
	if _clock >= 0.0 and bool(suvs[1].call("arrived")) and not gate_blocked():
		suvs[1].call("drive", BLOCK_ROUTE, BLOCK_SPEED)
	if gate_blocked():
		suvs[1].global_transform = BLOCK_AT
	if vehicle.global_position.x < GATE.x - 2.0:
		escaped = true
		phase = "away"
		escaped_now.emit()
		return
	_fire -= delta
	if _fire <= 0.0:
		_fire = FIRE_EVERY
		_shoot(men[1 + randi() % 2])
	if gate_blocked():
		_blocked_for += delta
		if _blocked_for >= CAUGHT_AFTER:
			caught_count += 1
			phase = "caught"
			caught.emit()


func _shoot(man: Node3D) -> void:
	var muzzle := man.global_position + Vector3.UP * 1.35 + man.global_basis.z * 0.6
	_shot_player.global_position = muzzle
	_shot_player.play()
	_flash.global_position = muzzle
	_flash.light_energy = 6.0
	create_tween().tween_property(_flash, "light_energy", 0.0, 0.08)


## The trap's shots, worked out from the van in its bay: in the cab, quiet; from behind it the
## SUVs' lights flaring between the stacks; low at the men coming out; close on the driver's window,
## the man at it; then up to the player's own camera.
func _shots() -> Array:
	var eye := vehicle.to_global(Vector3(-0.45, 1.8, -0.72))
	var ahead := vehicle.to_global(Vector3(0.0, 1.5, -20.0))
	var gap := SUV_A.origin + Vector3(-3.0, 2.4, 44.0)
	var stacks := SUV_A.origin + Vector3.UP * 1.0
	var low := MEN_AT[1] + Vector3(-4.5, 0.7, 7.0)
	var window := vehicle.to_global(Vector3(-2.6, 1.6, -2.4))
	return [
		{"name": "berth", "seconds": LIGHTS_AT, "fov": Vector2(48.0, 46.0), "exposure": 1.3,
			"gamma": 0.8, "from": _look(eye, ahead), "to": _look(eye + Vector3(0.0, 0.02, 0.0),
			ahead)},
		{"name": "lights", "seconds": MEN_STEP_AT - LIGHTS_AT, "fov": Vector2(40.0, 34.0),
			"exposure": 1.2, "gamma": 0.85, "from": _look(gap, stacks),
			"to": _look(gap + Vector3(0.0, -0.5, -3.0), stacks)},
		{"name": "men", "seconds": SHOTS_AT - MEN_STEP_AT, "fov": Vector2(30.0, 30.0),
			"exposure": 1.3, "gamma": 0.8, "lights": [{"at": MEN_AT[1] + Vector3(2.5, 2.2, 1.5),
			"colour": Color(0.55, 0.7, 1.0), "energy": 1.5, "range": 5.0}],
			"from": _look(low, MEN_AT[1] + Vector3.UP * 1.3),
			"to": _look(low + Vector3(0.0, 0.2, 0.6), MEN_AT[1] + Vector3.UP * 1.4)},
		{"name": "window", "seconds": 2.6, "fov": Vector2(34.0, 30.0), "exposure": 1.3,
			"gamma": 0.8, "from": _look(window, vehicle.to_global(Vector3(-0.95, 1.5, -0.8))),
			"to": _look(window + Vector3(0.0, 0.1, 0.3), vehicle.to_global(Vector3(-0.95, 1.5,
			-0.8)))},
		{"name": "go", "seconds": 1.6, "fov": Vector2(40.0, 40.0), "from": _look(eye, ahead),
			"to": "player"},
	]


static func _look(eye: Vector3, at: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
