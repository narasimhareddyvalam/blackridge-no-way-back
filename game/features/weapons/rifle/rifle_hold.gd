extends RefCounted
## Where the M16 is in Ethan's hands, from his hands themselves, each frame (Assignment 7, #399):
## its pistol grip in the hole of his closed right hand (the middle of his middle, ring and little
## fingers' knuckles and tips; his index lies straight along the frame), its grip's axis along his
## knuckles from the little finger to the index, and, while his left hand is under the rifle's front,
## its barrel from his right fist through his left; when his left hand is away (the reload's trip
## to his belt, the charging handle), the barrel keeps the placement that fits that set of clips
## best (tools/art/solve_rifle_grip.py): the Basic Shooter Pack's (IN_PACK) or the author's own
## downloads (IN_OWN: the draw, the put-away, the idles, Aim To Down), which hold it differently. Presentation only: it reads his bones and is
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
## His left fist counts as on the front when it is this far from his right (a rifle's grip to
## handguard is 0.25-0.40 m) and within this angle of where the solved placement points the barrel.
const LEFT_REACH := Vector2(0.16, 0.55)
const LEFT_ANGLE := 55.0
const FINGERS := ["Middle", "Ring", "Pinky"]

var skeleton: Skeleton3D
## How much the left hand steers the barrel, and how much the own downloads' placement is used,
## each eased frame to frame.
var support := 0.0
var own := 0.0


func _init(on: Skeleton3D) -> void:
	skeleton = on


## The rifle's global transform this frame, for the upper-body clip `clip` now playing; `delta`
## eases the left hand's hold and the change of set in and out.
func place(delta: float, clip: String) -> Transform3D:
	var hand := _bone("RightHand")
	var right := _fist("Right")
	var left := _fist("Left")
	own = move_toward(own, 1.0 if clip in OWN_CLIPS else 0.0, delta * 4.0)
	var pack_basis := (hand * IN_PACK).basis.orthonormalized()
	var own_basis := (hand * IN_OWN).basis.orthonormalized()
	var fixed_basis := pack_basis.slerp(own_basis, smoothstep(0.0, 1.0, own))
	var knuckles := (_bone("RightHandIndex1").origin - _bone("RightHandPinky1").origin).normalized()
	var reach := right.distance_to(left)
	var toward := (left - right).normalized()
	var barrel := -fixed_basis.z
	var steered := 1.0 if reach > LEFT_REACH.x and reach < LEFT_REACH.y \
		and rad_to_deg(toward.angle_to(barrel)) < LEFT_ANGLE else 0.0
	support = move_toward(support, steered, delta * 6.0)
	var held := _align(GUARD - GRIP, toward, GRIP_AXIS, knuckles)
	var one_hand := _align(Vector3(0, 0, -1), barrel, GRIP_AXIS, knuckles)
	var basis := one_hand.slerp(held, smoothstep(0.0, 1.0, support))
	return Transform3D(basis, right - basis * GRIP)


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
