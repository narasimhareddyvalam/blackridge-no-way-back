extends RefCounted
## Where the M16 is in Ethan's hands, from his hands themselves, each frame (Assignment 7, #399):
## its pistol grip in the hole of his closed right hand (the middle of his middle, ring and little
## fingers' knuckles and tips; his index lies straight along the frame), its grip's axis along his
## knuckles from the little finger to the index, and, while his left hand is under the rifle's front,
## its barrel from his right fist through his left; when his left hand is away (the reload's trip
## to his belt, the charging handle), the barrel keeps the placement that fits that set of clips
## best (tools/art/solve_rifle_grip.py): the Basic Shooter Pack's (IN_PACK) or the author's own
## downloads (IN_OWN: the draw, the put-away, the idles, Aim To Down), which hold it differently.
## The captures were made with guns of other sizes, so his left hand is then drawn the last few
## centimetres onto the part it holds by a two-bone IK on his left arm (`setup_left_arm`): the
## handguard, the magazine or the charging handle, eased in and out, and let go while it is away. Presentation only: it reads his bones and is
## asked for the rifle's transform; the caller (driver.gd, or a capture) writes it.

## Points on the rifle, in m16.glb's own space (the muzzle -z, its top +y): the grip's middle,
## where a closed hand's hole is; the grip's axis from its bottom up to the receiver, as raked; the
## handguard's middle under the rail, where a support hand's hole is.
const GRIP := Vector3(0.0, -0.105, 0.088)
const GRIP_AXIS := Vector3(0.0, 0.94, -0.34)
const GUARD := Vector3(0.0, -0.055, -0.24)
## The solved placements in his right hand bone's space, one for each set of clips.
const IN_PACK := Transform3D(Vector3(59.6975, 11.5417, -79.3914),
	Vector3(77.2954, 18.2281, 60.7714), Vector3(21.4856, -97.6449, 1.96055),
	Vector3(4.8333, 21.9447, 7.82367))
const IN_OWN := Transform3D(Vector3(-71.6355, 22.8132, 65.9387),
	Vector3(-53.8582, 42.0009, -73.0426), Vector3(-44.3582, -87.8378, -17.8008),
	Vector3(-3.40057, 22.7076, -4.32732))
const OWN_CLIPS := ["RifleIdleA", "RifleIdleB", "RifleAimDown", "RifleGrab", "RifleAway"]
## The reload (#400, #401): where his left hand is on the rifle in each part of it, traced from the
## capture (frame ranges at 30 fps): on the handguard; cupping the magazine to drop it; at his belt
## for the fresh one; the fresh one pushed into the magazine well; over the top of the receiver to
## the charging handle at its rear, hooked at 62, pulled back to 64 and let go at 65 (an M16's
## T-handle travels back toward the face and the spring returns it); the handguard again. In the
## magazine and charging parts the rifle stays upright in his right hand, as a real one does, and
## only his left arm (the IK) reaches the part; on the handguard the barrel runs through his hand.
const RELOAD_LEFT := [[0, 10, "guard"], [11, 20, "magazine"], [21, 42, ""], [43, 53, "magazine"],
	[54, 61, ""], [62, 65, "charge"], [66, 71, ""], [72, 99, "guard"]]
## The hole of his left hand when it cups the magazine's base (the magazine's bottom is y -0.173,
## z -0.026 to -0.097) and when its fingers hook the charging handle's T (its rear end at y
## 0.02-0.035, z 0.094), with the handle at rest.
const MAGAZINE := Vector3(0.0, -0.205, -0.062)
const CHARGE := Vector3(0.0, 0.07, 0.085)
## The charging handle and the bolt carrier: hooked at HOOK, back by CHARGE_TRAVEL at PULLED,
## held, let go at RELEASE and home a frame later.
const CHARGE_TRAVEL := 0.08
const HOOK := 62.0
const PULLED := 64.0
const RELEASE := 65.0
## The magazine's frames: the empty one leaves the well at DROP, a fresh one is in his left hand
## from PICK (at his belt) and is seated at SEAT.
const DROP := 14
const PICK := 26
const SEAT := 47
## Slung at his right hip, where his own put-away leaves it and his draw takes it (#400,
## tools/art/measure_rifle_sling.gd), in his upper back's (Spine2) space. As a rifle is handled in
## real life (#402), its muzzle points at the ground while it goes to and from the sling, never up
## across him: in the draw his hand reaches behind his hip and takes the rifle as it comes forward
## past the grip at TAKE (the fist 0.13 m from it; easing in over TAKE_EASE frames), turning it up
## into his hold by HELD as his left hand catches the handguard; the put-away lets his
## left hand off first while the rifle turns from the low ready to a muzzle-down carry (by TURN),
## hanging nearly straight down from his fist, the muzzle a little ahead, its sights forward and its
## stock past the outside of his right arm, away from his face, as his hand rises to his shoulder;
## it turns to hang as his hand lowers to his hip (LOWER to HUNG) and he lets go at LET_GO. The
## grip stays in his fist all the while.
const SLUNG := Transform3D(Vector3(-89.71496, 22.00353, 38.30237),
	Vector3(43.32841, 60.70706, 66.61311), Vector3(-8.594996, 76.35774, -63.9971),
	Vector3(-23.53078, -54.02867, 20.49663))
const TAKE := 37
const TAKE_EASE := 5.0
const HELD := 52
const TURN := 8
const LOWER := 40
const HUNG := 54
## The muzzle-down carry: the barrel this far ahead of straight down (a share of his facing).
const CARRY_AHEAD := 0.2
const LET_GO := 62
## His left fist counts as on the front when it is this far from his right (a rifle's grip to
## handguard is 0.25-0.40 m) and within this angle of where the solved placement points the barrel.
const LEFT_REACH := Vector2(0.16, 0.55)
const LEFT_ANGLE := 55.0
const FINGERS := ["Middle", "Ring", "Pinky"]

var skeleton: Skeleton3D
## True while the rifle hangs slung (before the draw, after the put-away).
var slung := true
## How much the left hand steers the barrel, and how much the own downloads' placement is used,
## each eased frame to frame.
var support := 0.0
var own := 0.0
## The last left-hand target and how far the rifle has turned to it, for an eased change.
var _target := "guard"
var _turned := Basis.IDENTITY
var _last := Basis.IDENTITY
var _change := 1.0
## The left arm's IK and where it reaches: its target follows the part his left hand holds.
## The put-away's low ready, kept from TURN while his hand rises.
var _ready_basis := Basis.IDENTITY
var _ik: TwoBoneIK3D
var _ik_target: Node3D
var _reach := 0.0
var _point := Vector3.ZERO
## Where the IK actually put his fist differs a little from where it aimed his wrist (the hand
## turns as the arm bends): measured after each skeleton update and folded back into the aim.
var _correction := Vector3.ZERO


func _init(on: Skeleton3D) -> void:
	skeleton = on


## The rifle's global transform this frame, for the upper-body clip `clip` at `frame` (30 fps);
## `delta` eases the left hand's hold, the change of set and a change of target in and out.
func place(delta: float, clip: String, frame: float = 0.0) -> Transform3D:
	var hand := _bone("RightHand")
	var right := _fist("Right")
	var left := _fist("Left")
	own = move_toward(own, 1.0 if clip in OWN_CLIPS else 0.0, delta * 4.0)
	var pack_basis := (hand * IN_PACK).basis.orthonormalized()
	var own_basis := (hand * IN_OWN).basis.orthonormalized()
	var fixed_basis := pack_basis.slerp(own_basis, smoothstep(0.0, 1.0, own))
	var knuckles := (_bone("RightHandIndex1").origin - _bone("RightHandPinky1").origin).normalized()
	var toward := (left - right).normalized()
	var barrel := -fixed_basis.z
	var one_hand := _align(Vector3(0, 0, -1), barrel, GRIP_AXIS, knuckles)
	var wanted := "guard"
	if clip == "RifleReload":
		wanted = ""
		for part in RELOAD_LEFT:
			if frame >= part[0] and frame < part[1] + 1:
				wanted = part[2]
	else:
		var reach := right.distance_to(left)
		var near := reach > LEFT_REACH.x and reach < LEFT_REACH.y \
			and rad_to_deg(toward.angle_to(barrel)) < LEFT_ANGLE
		wanted = "guard" if near else ""
	var point: Vector3 = {"guard": GUARD, "magazine": MAGAZINE, "charge": CHARGE}.get(wanted, Vector3.ZERO)
	if wanted == "charge":
		point += Vector3(0.0, 0.0, charging_at(clip, frame))
	var target := _align(point - GRIP, toward, GRIP_AXIS, knuckles) if wanted == "guard" \
		else one_hand
	support = move_toward(support, 0.0 if wanted == "" else 1.0, delta * 6.0)
	if wanted != _target:
		_turned = _last
		_target = wanted
		_change = 0.0
		_correction = Vector3.ZERO
	_change = move_toward(_change, 1.0, delta * 7.0)
	var basis := _turned.slerp(target, smoothstep(0.0, 1.0, _change)) if _turned != Basis.IDENTITY \
		else target
	_last = basis
	var hanging := hung().basis.orthonormalized()
	if clip == "RifleGrab":
		if frame < TAKE:
			return _letting(hung())
		basis = hanging.slerp(basis, smoothstep(float(TAKE), float(HELD), frame))
		if frame < TAKE + TAKE_EASE:
			wanted = ""
		var grip := (hung() * GRIP).lerp(right, smoothstep(float(TAKE), TAKE + TAKE_EASE, frame))
		return _reaching(Transform3D(basis, grip - basis * GRIP), wanted, point, delta)
	elif clip == "RifleAway":
		if frame >= LET_GO:
			return _letting(hung())
		if frame < 1.0 or _ready_basis == Basis.IDENTITY:
			_ready_basis = basis
		var facing := _bone("Spine2").basis.z.normalized()
		var carry := _align(Vector3(0, 0, -1), Vector3.DOWN + facing * CARRY_AHEAD, Vector3(0, 1, 0),
			facing)
		basis = _ready_basis.slerp(carry, smoothstep(0.0, float(TURN), frame))
		basis = basis.slerp(hanging, smoothstep(float(LOWER), float(HUNG), frame))
		if frame > TURN + 4:
			wanted = ""
	elif slung:
		return _letting(hung())
	if clip != "RifleAway":
		_ready_basis = Basis.IDENTITY
	return _reaching(Transform3D(basis, right - basis * GRIP), wanted, point, delta)


## Draws his left hand onto the rifle's part `point` (none while `wanted` is empty) by the IK.
func _reaching(rifle: Transform3D, wanted: String, point: Vector3, delta: float) -> Transform3D:
	_reach = move_toward(_reach, 0.0 if wanted == "" else 1.0, delta * 8.0)
	_point = rifle * point if wanted != "" else _point
	if _ik != null:
		_ik_target.global_position = _point + (_bone("LeftHand").origin - _fist("Left")) \
			+ _correction
		_ik.influence = smoothstep(0.0, 1.0, _reach)
		_ik.active = _ik.influence > 0.0
	return rifle


## Builds the two-bone IK that draws his left hand onto the rifle: on his left arm (Mixamo names),
## its target moved each frame by `place`, its pole below and out from his left elbow.
func setup_left_arm(model: Node3D) -> void:
	_ik_target = Node3D.new()
	_ik_target.name = "LeftHandOnRifle"
	model.add_child(_ik_target)
	var pole := Node3D.new()
	pole.name = "LeftElbowPole"
	model.add_child(pole)
	pole.position = Vector3(0.55, 0.9, 0.15)
	_ik = TwoBoneIK3D.new()
	_ik.name = "LeftHandIK"
	_ik.set_setting_count(1)
	_ik.set_root_bone_name(0, "mixamorig_LeftArm")
	_ik.set_middle_bone_name(0, "mixamorig_LeftForeArm")
	_ik.set_end_bone_name(0, "mixamorig_LeftHand")
	_ik.set_extend_end_bone(0, false)
	_ik.influence = 0.0
	_ik.active = false
	skeleton.add_child(_ik)
	_ik.set_target_node(0, _ik.get_path_to(_ik_target))
	_ik.set_pole_node(0, _ik.get_path_to(pole))
	skeleton.skeleton_updated.connect(_after_ik)


## After the IK has moved his arm: how far his fist still is from the part, folded into the aim.
func _after_ik() -> void:
	if _ik == null or _ik.influence < 0.99 or _target == "":
		return
	_correction += (_point - _fist("Left")) * 0.6
	_correction = _correction.limit_length(0.25)


## How far back the charging handle (and the bolt carrier with it) is at `frame`, in metres.
func charging_at(clip: String, frame: float) -> float:
	if clip != "RifleReload" or frame < HOOK or frame >= RELEASE + 1.0:
		return 0.0
	if frame < PULLED:
		return CHARGE_TRAVEL * smoothstep(HOOK, PULLED, frame)
	if frame < RELEASE:
		return CHARGE_TRAVEL
	return CHARGE_TRAVEL * (1.0 - (frame - RELEASE))


## The rifle slung at his right hip this frame.
func hung() -> Transform3D:
	var spine := _bone("Spine2")
	return spine * SLUNG


## The rifle hanging slung: his left hand let go (the IK eased out).
func _letting(rifle: Transform3D) -> Transform3D:
	_reach = move_toward(_reach, 0.0, 0.25)
	if _ik != null:
		_ik.influence = smoothstep(0.0, 1.0, _reach)
		_ik.active = _ik.influence > 0.0
	return rifle


## Where the magazine is in the reload at `frame`: "gun" in its well, "gone" (the empty one
## dropped, none in his hand yet) or "hand" (the fresh one in his left hand).
func magazine_at(clip: String, frame: float) -> String:
	if clip != "RifleReload" or frame < DROP or frame >= SEAT:
		return "gun"
	return "gone" if frame < PICK else "hand"


## The fresh magazine's transform in his left hand, as it will sit in the well once seated, its
## base in the hole of his hand; `rifle` is the rifle's transform this frame.
func magazine_in_hand(rifle: Transform3D, seated: Transform3D) -> Transform3D:
	var placed := rifle * seated
	var offset := _fist("Left") - rifle * (MAGAZINE)
	return Transform3D(placed.basis, placed.origin + offset)


## The centre of the hole in a closed hand: midway between its fingers' knuckles and tips.
func _fist(side: String) -> Vector3:
	var knuckle := Vector3.ZERO
	var tip := Vector3.ZERO
	for finger in FINGERS:
		knuckle += _bone(side + "Hand" + finger + "1").origin
		tip += _bone(side + "Hand" + finger + "3").origin
	return (knuckle + tip) / (2.0 * FINGERS.size())


## The rotation taking `first` to `toward` exactly and `second` as near `second_to` as it can.
func _align(first: Vector3, toward: Vector3, second: Vector3, second_to: Vector3) -> Basis:
	return _frame(toward, second_to) * _frame(first, second).inverse()


func _frame(a: Vector3, b: Vector3) -> Basis:
	var x := a.normalized()
	var y := (b - x * b.dot(x)).normalized()
	return Basis(x, y, x.cross(y))


func _bone(name: String) -> Transform3D:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
		"mixamorig_" + name))
