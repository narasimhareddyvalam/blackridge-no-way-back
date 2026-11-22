extends Node
## Ethan's rifle in Mission 3 (Assignment 7, C68; #393-#403): the M16 (`m16.glb`) slung at his
## right hip or in his hands, and the motion-captured clips that handle it. driver.gd builds this
## and calls it; with driver.gd it is the one authority over his animation: it plays the upper-body
## rifle clips (`ethan_rifle.tres`) on a second player laid over his own player's legs, and tells
## driver.gd which whole-body rifle gait his legs play. The rifle's place in his hands, its sling,
## the reload's magazine and charging handle and his left hand on the rifle are rifle_hold.gd's.
##
## States, each with its clip on the upper body (CHANGE-BRIEF.md, the rifle's revision):
##   slung   none        armed, the rifle at his hip; aim held -> draw
##   draw    RifleGrab   to its end -> ready (then raise, if aim is still held)
##   ready   RifleIdleA and RifleIdleB in turn; aim held -> raise; R with room -> reload
##   raise   RifleAimDown backward -> aim
##   aim     RifleAim    a shot -> fire; aim let go -> lower; R -> reload
##   fire    RifleFire   to its end -> aim
##   lower   RifleAimDown -> ready
##   reload  RifleReload as long as the gun reloads (the clip is its RELOAD_SECONDS) -> aim/ready
##   hit     RifleHit    to its end -> aim/ready
##   away    RifleAway   to its end -> slung (before he gets into the van)
## While he moves his own player plays the rifle's whole-body gaits (the pack's walks, runs and
## strafes, which shoulder the rifle) and the upper body plays nothing, except to reload.
## He fires only from aim (can_fire) and reloads only with the rifle out (can_reload): a slung or
## half-drawn rifle does neither. A trained shooter brings a rifle from the low ready to the
## shoulder in about half a second, so the raise plays RAISE_SPEED times as fast as the capture
## (0.6 s) and the lower LOWER_SPEED.

const RIFLE = preload("res://features/weapons/rifle/m16.glb")
const POSE = preload("res://animations/ethan_rifle.tres")
const RifleHold = preload("res://features/weapons/rifle/rifle_hold.gd")
const BLEND := 0.2
## The gaits' own ground speeds (convert_mixamo.py prints them), so his feet keep their pace.
const GAIT_SPEED := {"RifleWalk": 0.954, "RifleWalkBack": 1.058, "RifleRun": 3.018,
	"RifleRunBack": 2.636, "RifleStrafeLeft": 1.33, "RifleStrafeRight": 0.722}
## Standing, a swing of his facing faster than this (radians a second) plays a turn.
const TURN_RATE := 1.6
const RAISE_SPEED := 2.5
const LOWER_SPEED := 1.5

var state := "none"
var rifle: Node3D
var hold: RefCounted
var upper: AnimationPlayer
var gun: Node
var want_aim := false
var _model: Node3D
var _skeleton: Skeleton3D
var _legs: AnimationPlayer
var _magazine: MeshInstance3D
var _fresh: MeshInstance3D
var _dropped: MeshInstance3D
var _fall := Vector3.ZERO
var _magazine_in_rifle := Transform3D.IDENTITY
var _sliders: Array[MeshInstance3D] = []
var _slider_rest: Array[Transform3D] = []
var _idle := "RifleIdleA"
## The speed his own player plays the gait legs() last chose, so his feet keep their ground.
var legs_speed := 1.0
var _last_yaw := 0.0
var _turning := ""


## Builds the player, the rifle and its hold on Ethan's `model` and `skeleton`; `legs` is his own
## player.
func setup(model: Node3D, skeleton: Skeleton3D, legs_player: AnimationPlayer) -> void:
	_model = model
	_skeleton = skeleton
	_legs = legs_player
	upper = AnimationPlayer.new()
	upper.name = "UpperBody"
	upper.process_priority = 1
	upper.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	model.add_child(upper)
	upper.add_animation_library("", POSE)
	upper.animation_finished.connect(_finished)
	rifle = RIFLE.instantiate() as Node3D
	rifle.name = "Rifle"
	add_child(rifle)
	rifle.top_level = true
	rifle.visible = false
	_magazine = rifle.find_child("MAGAZINE_M16A3_0", true, false) as MeshInstance3D
	_magazine_in_rifle = rifle.global_transform.affine_inverse() * _magazine.global_transform
	for part in ["CHANRIGN HANDLE_M16A3_0", "BOLT CARRIER_M16A3_0"]:
		var mesh := rifle.find_child(part, true, false) as MeshInstance3D
		_sliders.append(mesh)
		_slider_rest.append(rifle.global_transform.affine_inverse() * mesh.global_transform)
	_fresh = _magazine.duplicate() as MeshInstance3D
	add_child(_fresh)
	_fresh.top_level = true
	_fresh.visible = false
	hold = RifleHold.new(skeleton)
	hold.call("setup_left_arm", model)


## The gun he carries (the hangar's handgun node: its `armed`, `reloading` and `fired`).
func carry(with: Node) -> void:
	if with == gun or with == null:
		return
	gun = with
	if gun.has_signal("fired"):
		gun.connect("fired", _on_fired)


func armed() -> bool:
	return gun != null and bool(gun.get("armed"))


## Drawn: in his hands (not slung, not yet armed).
func drawn() -> bool:
	return state not in ["none", "slung", "away"]


func can_fire() -> bool:
	return state in ["aim", "fire"]


func can_reload() -> bool:
	return drawn() and state != "draw"


## In a cutscene that has him aim at once: the rifle straight into his hands, at the ready.
func ready_now() -> void:
	if state in ["slung", "draw"]:
		_go("ready")


## A round has hit him: his flinch, if the rifle is out.
func flinch() -> void:
	if state in ["ready", "aim", "fire"]:
		_go("hit")


## Puts the rifle away (before he gets into the van); `stowed` is emitted when it hangs slung,
## at once if it is not out.
signal stowed


func stow() -> void:
	if not drawn():
		stowed.emit.call_deferred()
		return
	want_aim = false
	_go("away")


## Each frame, after his own player: the states, the rifle, its parts.
func update(delta: float, moving: bool) -> void:
	if not armed():
		if state != "none":
			_go("none")
		rifle.visible = false
		_fresh.visible = false
		return
	rifle.visible = true
	if state == "none":
		_go("slung")
	var reloading := bool(gun.get("reloading"))
	match state:
		"slung":
			if want_aim:
				_go("draw")
		"ready":
			if reloading:
				_go("reload")
			elif want_aim:
				_go("raise")
		"aim", "fire":
			if reloading:
				_go("reload")
			elif not want_aim and state == "aim":
				_go("lower")
		"reload":
			if not reloading:
				_go("aim" if want_aim else "ready")
	_show_upper(moving)
	var clip := String(upper.current_animation) if upper.is_playing() else ""
	var frame := upper.current_animation_position * 30.0 if upper.is_playing() else 0.0
	if state == "reload":
		clip = "RifleReload"
	hold.set("slung", state in ["slung", "none"])
	rifle.global_transform = hold.call("place", delta, clip, frame)
	var travel: float = hold.call("charging_at", clip, frame)
	for i in _sliders.size():
		var rest := _slider_rest[i]
		_sliders[i].global_transform = rifle.global_transform * Transform3D(rest.basis,
			rest.origin + Vector3(0.0, 0.0, travel))
	_magazines(clip, frame, delta)


## How far left of his feet the barrel points now (radians), for driver.gd to turn him so the
## barrel lies along the crosshair.
func barrel_offset() -> float:
	var barrel := _model.global_basis.inverse() * (-rifle.global_basis.z)
	return atan2(barrel.x, barrel.z)


## Where the rifle's muzzle is, in the world.
func muzzle() -> Vector3:
	return rifle.global_transform * Vector3(0.0, 0.0, -0.558)


## The clip his own player plays while the rifle is out, and its speed: the rifle gaits, by the
## way he moves relative to where he faces, or Idle (the upper body on top), or a turn on the spot.
func legs(direction: Vector3, moving: bool, pace: float, running: bool) -> Array:
	var yaw := _model.global_rotation.y
	var rate := angle_difference(_last_yaw, yaw) / maxf(get_process_delta_time(), 0.001)
	_last_yaw = yaw
	if not moving:
		legs_speed = 1.0
		if _turning != "" and _legs.current_animation == _turning and _legs.is_playing():
			return [_turning, 1.0]
		_turning = ""
		if absf(rate) > TURN_RATE:
			_turning = "RifleTurnLeft" if rate > 0.0 else "RifleTurnRight"
			return [_turning, 1.0]
		return ["Idle", 1.0]
	_turning = ""
	var local := _model.global_basis.inverse() * direction
	var clip := "RifleRun" if running else "RifleWalk"
	if local.z < -0.5:
		clip = "RifleRunBack" if running else "RifleWalkBack"
	elif absf(local.x) > 0.6:
		clip = "RifleStrafeLeft" if local.x > 0.0 else "RifleStrafeRight"
	legs_speed = pace / float(GAIT_SPEED[clip])
	return [clip, legs_speed]


func _go(next: String) -> void:
	state = next
	upper.speed_scale = RAISE_SPEED if next == "raise" else LOWER_SPEED if next == "lower" else 1.0
	match next:
		"none", "slung":
			upper.stop()
		"draw":
			upper.play("RifleGrab", BLEND)
		"ready":
			_idle = "RifleIdleA"
			upper.play(_idle, BLEND)
		"raise":
			upper.play_backwards("RifleAimDown", BLEND)
		"aim":
			upper.play("RifleAim", BLEND)
		"fire":
			upper.play("RifleFire", 0.05)
		"lower":
			upper.play("RifleAimDown", BLEND)
		"reload":
			upper.play("RifleReload", BLEND)
		"hit":
			upper.play("RifleHit", 0.1)
		"away":
			upper.play("RifleAway", BLEND)


## While he moves, the gaits carry the rifle and the upper body rests; it comes back when he stops.
func _show_upper(moving: bool) -> void:
	var resting := moving and state in ["ready", "aim", "fire", "raise", "lower"]
	if resting and upper.is_playing():
		upper.stop()
	elif not resting and not upper.is_playing() and state not in ["none", "slung"]:
		_go(state)


func _finished(clip: StringName) -> void:
	match String(clip):
		"RifleGrab":
			state = "ready"
			_go("raise" if want_aim else "ready")
		"RifleAimDown":
			_go("aim" if state == "raise" else "ready")
		"RifleFire", "RifleHit":
			_go("aim" if want_aim else "ready")
		"RifleIdleA", "RifleIdleB":
			_idle = "RifleIdleB" if _idle == "RifleIdleA" else "RifleIdleA"
			upper.play(_idle, BLEND)
		"RifleAway":
			_go("slung")
			stowed.emit()


func _on_fired(_from: Vector3) -> void:
	if state == "aim":
		_go("fire")


## The reload's magazines: the empty one drops from the well, a fresh one rides in his left hand
## from his belt into the well (rifle_hold.gd's magazine_at and magazine_in_hand).
func _magazines(clip: String, frame: float, delta: float) -> void:
	var where: String = hold.call("magazine_at", clip, frame)
	_magazine.visible = where == "gun"
	if where != "gun" and _dropped == null and frame < 30.0:
		_dropped = _magazine.duplicate() as MeshInstance3D
		add_child(_dropped)
		_dropped.top_level = true
		_dropped.global_transform = _magazine.global_transform
		_dropped.visible = true
		_fall = Vector3.ZERO
	if _dropped != null:
		if _dropped.global_position.y > _model.global_position.y + 0.03:
			_fall += Vector3.DOWN * 9.8 * delta
			_dropped.global_position += _fall * delta
		if clip != "RifleReload":
			_dropped.queue_free()
			_dropped = null
	_fresh.visible = where == "hand"
	if where == "hand":
		_fresh.global_transform = hold.call("magazine_in_hand", rifle.global_transform,
			_magazine_in_rifle)
