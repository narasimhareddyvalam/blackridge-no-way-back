extends Node3D
## Both arms up to a pistol held in both hands, the way a pistol is aimed (Mission 3's step 6,
## #359): the gun out in front of the chest at arm's length, a little right of the middle and under
## the eyes' line, the right hand on its grip and the left wrapped round the right, elbows down and
## a little out. Shared by Ethan and Adrian's men, whose rigs both carry Mixamo's bone names. Put it
## under the character's model (Mixamo models face their +Z) at the shoulders' height; `pitch` turns
## the arms up or down to where they aim, and `influence` eases them up (1) or down (0). The pistol
## (`pistol.glb`, the men's own) is held by its grip in the right palm, ahead of the wrist the IK
## places; both hands then close round the grip (Ethan's `hand_grip.gd`, the grip's line as the bar
## each hand holds, from thumb to little finger).

const PISTOL = preload("pistol.glb")
const HandGrip = preload("res://features/characters/driver/hand_grip.gd")
## The pistol model's grip, its muzzle's way (-y) and its top (+z), in its own file.
const GRIP_IN_MODEL := Vector3(0.6378, 0.67, -0.055)
const MUZZLE_AHEAD := Vector3(0.0, 0.03, 0.12)
## Where the grip is held, from the shoulders' middle: right, down, ahead.
const HELD := Vector3(-0.04, -0.1, 0.52)
const LEFT_FROM_RIGHT := Vector3(0.05, -0.03, 0.0)
## The pistol's grip from the right wrist: in the palm, ahead and a little under it; and the
## grip's line down through the hand, raked back as a pistol's is.
const PALM := Vector3(0.0, -0.05, -0.07)
const GRIP_LINE := Vector3(0.0, -0.95, -0.31)
const ELBOW := Vector3(0.45, -0.55, 0.15)
const RATE := 6.0

var pitch := 0.0
var influence := 0.0
var wanted := 0.0
var grip: Node3D
var pistol: Node3D
var _arms := TwoBoneIK3D.new()
var _hands: SkeletonModifier3D
var _targets: Array[Node3D] = []
var _poles: Array[Node3D] = []


## Builds it on `skeleton` (Mixamo names, `prefix` before each), `shoulders` up from the model.
func setup(skeleton: Skeleton3D, shoulders: float, prefix := "mixamorig_") -> void:
	position = Vector3(0.0, shoulders, 0.0)
	grip = Node3D.new()
	grip.name = "Grip"
	add_child(grip)
	grip.position = HELD
	pistol = PISTOL.instantiate() as Node3D
	pistol.name = "Pistol"
	grip.add_child(pistol)
	var turn := Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
	pistol.transform = Transform3D(turn, PALM - turn * GRIP_IN_MODEL)
	pistol.visible = false
	_arms.name = "AimArms"
	_arms.set_setting_count(2)
	for index in range(2):
		var side: String = ["Right", "Left"][index]
		var target := Node3D.new()
		target.name = side + "HandTarget"
		var pole := Node3D.new()
		pole.name = side + "ElbowPole"
		add_child(pole)
		pole.position = Vector3(ELBOW.x * (-1.0 if index == 0 else 1.0), ELBOW.y, ELBOW.z)
		if index == 0:
			grip.add_child(target)
		else:
			grip.add_child(target)
			target.position = LEFT_FROM_RIGHT
		_targets.append(target)
		_poles.append(pole)
		_arms.set_root_bone_name(index, prefix + side + "Arm")
		_arms.set_middle_bone_name(index, prefix + side + "ForeArm")
		_arms.set_end_bone_name(index, prefix + side + "Hand")
		_arms.set_extend_end_bone(index, false)
	_arms.active = false
	_arms.influence = 0.0
	skeleton.add_child(_arms)
	for index in range(2):
		_arms.set_target_node(index, _arms.get_path_to(_targets[index]))
		_arms.set_pole_node(index, _arms.get_path_to(_poles[index]))
	_hands = HandGrip.new()
	_hands.name = "HandsOnPistol"
	skeleton.add_child(_hands)


## Where the muzzle is, in the world, and the way it points.
func muzzle() -> Vector3:
	return grip.global_transform * (PALM + MUZZLE_AHEAD)


func _process(delta: float) -> void:
	influence = move_toward(influence, wanted, RATE * delta)
	rotation.x = -pitch
	_arms.influence = influence
	_arms.active = influence > 0.0
	var line := (grip.global_basis * GRIP_LINE).normalized()
	var bars: Array[Vector3] = [line, line]
	_hands.set("bars", bars)
	_hands.set("amount", influence)
	if pistol != null:
		pistol.visible = influence > 0.5
