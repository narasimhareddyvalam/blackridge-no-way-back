extends StaticBody3D
## The van's hold as Ethan and the dock's pallet jack meet it (docs/PHASE_BRIEF.md, step 2e,
## rule H2): its floor, side walls, bulkhead, roof and rear wheel arches, in the van's frame,
## measured on 2026-11-11 by casting rays inside the Iveco model's own interior: the floor
## 0.614 m up as far back as its rear sill, 2.74 m behind the bulkhead's face at z -0.25; the
## walls 0.867 m either side; the headliner 2.15 m up; the arches 0.29 m tall from 0.62 m out,
## between z 1.62 and 2.38. The van builds it when its rear doors first open. It sits on the
## van's layer, which the van's own movement never reads, so it changes nothing in how the van
## drives; Ethan stands on it, and a pallet stops against it.

const FLOOR := 0.614
const WALL_X := 0.867
const OUTER_X := 1.0
const BULKHEAD_Z := -0.25
const REAR_Z := 3.012
const SILL_Z := 2.74
const ROOF := 2.15
const ARCH := AABB(Vector3(0.62, FLOOR, 1.62), Vector3(0.247, 0.294, 0.76))
const SILL := Vector3(0.0, 0.66, SILL_Z)
const BASE := 0.15


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_box("HoldFloor", AABB(Vector3(-WALL_X, BASE, BULKHEAD_Z), Vector3(WALL_X * 2.0,
		FLOOR - BASE, SILL_Z - BULKHEAD_Z)))
	for side: float in [-1.0, 1.0]:
		var inner := WALL_X if side > 0.0 else -OUTER_X
		_box("HoldWall", AABB(Vector3(inner, FLOOR, BULKHEAD_Z), Vector3(OUTER_X - WALL_X,
			ROOF - FLOOR, REAR_Z - BULKHEAD_Z)))
		var arch := ARCH if side > 0.0 else AABB(Vector3(-ARCH.end.x, ARCH.position.y,
			ARCH.position.z), ARCH.size)
		_box("WheelArch", arch)
	_box("Bulkhead", AABB(Vector3(-WALL_X, FLOOR, BULKHEAD_Z - 0.15), Vector3(WALL_X * 2.0,
		ROOF - FLOOR, 0.15)))
	_box("HoldRoof", AABB(Vector3(-OUTER_X, ROOF, BULKHEAD_Z), Vector3(OUTER_X * 2.0, 0.15,
		REAR_Z - BULKHEAD_Z)))


func _box(label: String, box: AABB) -> void:
	var shape := BoxShape3D.new()
	shape.size = box.size
	var collision := CollisionShape3D.new()
	collision.name = label
	collision.shape = shape
	collision.position = box.get_center()
	add_child(collision, true)
