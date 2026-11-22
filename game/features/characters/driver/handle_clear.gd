extends SkeletonModifier3D
## Ethan's back straightened from the foot of his spine just enough that the handle he holds in
## front of him, the pallet jack's (#250), stays outside his body, as a man close behind a handle
## pushes it with his arms rather than leaning into it; leaning in deeper again as it runs out
## ahead of him. The handle is given each frame as straight pieces in the world (`pieces`, in
## pairs of ends, with the rod's own thickness `thick`); his body is his spine's bones, each
## between two joints as thick as his rest pose's mesh stands in front of it. Runs before his
## hands' IK, so that his hands reach the handle from where his shoulders are then. With his head
## under a low roof (`roof`: the van's transform `space`, its hold's `roof` and rear `door`
## heights, its `rear` and `side`, and `by_door`, how far in the doorway's top is over him) he
## straightens no higher than his hair clears it, and where his
## clip would put his head into it, as the heavy pull's nearly upright haul does in the van's hold,
## he bends forward from the foot of his spine until it clears, never into the handle, and asks
## (`crouch_wanted`) for as much more as his knees must give (#257-#258).

const BONES: Array[String] = ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1",
	"mixamorig_Spine2", "mixamorig_Neck", "mixamorig_Head", "mixamorig_HeadTop_End"]
const AROUND: Array[float] = [0.126, 0.129, 0.146, 0.143, 0.138, 0.133]
const MARGIN := 0.03
const HAIR := 0.06
const HEAD_OUT := 0.25
const MOST := deg_to_rad(35.0)
const DUCK_MOST := deg_to_rad(40.0)
const DUCK_MARGIN := 0.05
const TRY := deg_to_rad(1.0)
const UP_RATE := deg_to_rad(180.0)
const DOWN_RATE := deg_to_rad(60.0)

var pieces: PackedVector3Array = PackedVector3Array()
var thick := 0.0
var roof := {}
var ceiling := INF
var facing := Vector3.FORWARD
var back := 0.0
var crouch_wanted := 0.0
var _bones: Array[int] = []


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _bones.is_empty():
		for bone in BONES:
			_bones.append(skeleton.find_bone(bone))
	if _bones.has(-1):
		return
	var space := skeleton.global_transform
	var points: Array[Vector3] = []
	for bone in _bones:
		points.append((space * skeleton.get_bone_global_pose(bone)).origin)
	var left := Vector3.UP.cross(Vector3(facing.x, 0.0, facing.z).normalized())
	ceiling = _ceiling_over(points[-1])
	var wanted := 0.0
	if pieces.size() >= 2:
		while wanted < MOST and _clear(points, left, wanted) < MARGIN \
				and _top(points, left, wanted + TRY) + HAIR <= ceiling:
			wanted += TRY
	while wanted > -DUCK_MOST and _top(points, left, wanted) + HAIR > ceiling \
			and (pieces.size() < 2 or _clear(points, left, wanted - TRY) >= DUCK_MARGIN):
		wanted -= TRY
	back = move_toward(back, clampf(wanted, -DUCK_MOST, MOST), (UP_RATE if absf(wanted)
		> absf(back) else DOWN_RATE) * delta)
	crouch_wanted = _top(points, left, back) + HAIR - ceiling if ceiling < INF else -INF
	if is_zero_approx(back):
		return
	var spine := skeleton.get_bone_global_pose(_bones[1])
	var turn := Basis((space.basis.inverse() * left).normalized(), -back)
	skeleton.set_bone_global_pose(_bones[1],
		Transform3D(turn, spine.origin - turn * spine.origin) * spine)


## How high in the world the roof over `head` is: the van's hold's, or its rear doorway's lower
## top near its rear, or none outside it.
func _ceiling_over(head: Vector3) -> float:
	if roof.is_empty():
		return INF
	var space: Transform3D = roof["space"]
	var at := space.affine_inverse() * head
	var rear: float = roof["rear"]
	if absf(at.x) > float(roof["side"]) or at.z > rear + HEAD_OUT:
		return INF
	var height: float = roof["door"] if at.z > rear - float(roof["by_door"]) else roof["roof"]
	return (space * Vector3(at.x, height, at.z)).y


## How high the top of his head is with his back straightened by `angle`.
func _top(points: Array[Vector3], left: Vector3, angle: float) -> float:
	return (points[1] + Basis(left, -angle) * (points[-1] - points[1])).y


## How far the handle is outside his body at the nearest with his back straightened by `angle`.
func _clear(points: Array[Vector3], left: Vector3, angle: float) -> float:
	var turn := Basis(left, -angle)
	var joint := points[1]
	var nearest := INF
	for index in range(AROUND.size()):
		var a := points[index] if index == 0 else joint + turn * (points[index] - joint)
		var b := joint + turn * (points[index + 1] - joint)
		for piece in range(0, pieces.size() - 1, 2):
			var near := Geometry3D.get_closest_points_between_segments(pieces[piece],
				pieces[piece + 1], a, b)
			nearest = minf(nearest, near[0].distance_to(near[1]) - thick - AROUND[index])
	return nearest
