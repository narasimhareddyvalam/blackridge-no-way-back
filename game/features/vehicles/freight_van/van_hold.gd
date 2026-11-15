extends StaticBody3D
## The van's hold as Ethan and the dock's pallet jack meet it (docs/PHASE_BRIEF.md, step 2e,
## rule H2): its floor, side walls, bulkhead, roof and rear wheel arches, in the van's frame,
## measured on 2026-11-11 by casting rays inside the Iveco model's own interior: the floor
## 0.614 m up as far back as its rear sill, 2.74 m behind the bulkhead's face at z -0.25; the
## walls 0.867 m either side; the headliner 2.15 m up; the arches 0.29 m tall from 0.62 m out,
## between z 1.62 and 2.38. The van builds it when its rear doors first open. It sits on the
## van's layer, which the van's own movement never reads, so it changes nothing in how the van
## drives; Ethan stands on it, and a pallet stops against it. Its floor has lashing rings by each
## wall, folding D-rings in recessed plates, to strap a load to (#286): three a side, 0.64 m
## apart from just behind the bulkhead, where a load set against the bulkhead takes its straps;
## their exact places on a 2014 Daily are not confirmed.

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
const RING_X := 0.8
const RINGS_Z: Array[float] = [0.05, 0.69, 1.33]
const RING_PLATE := Vector3(0.07, 0.004, 0.07)


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
	_rings()


func _rings() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.32, 0.33, 0.34)
	steel.metallic = 0.8
	steel.roughness = 0.45
	var recess := StandardMaterial3D.new()
	recess.albedo_color = Color(0.1, 0.1, 0.1)
	recess.roughness = 0.8
	var count := 0
	for side: float in [-1.0, 1.0]:
		for z in RINGS_Z:
			count += 1
			var ring := Node3D.new()
			ring.name = "FloorRing%d" % count
			ring.position = Vector3(side * RING_X, FLOOR, z)
			add_child(ring)
			var plate := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = RING_PLATE
			plate.mesh = box
			plate.material_override = recess
			plate.position = Vector3.UP * RING_PLATE.y / 2.0
			ring.add_child(plate)
			var loop := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = 0.018
			torus.outer_radius = 0.025
			loop.mesh = torus
			loop.material_override = steel
			loop.scale = Vector3(1.0, 0.6, 1.0)
			loop.position = Vector3.UP * 0.006
			ring.add_child(loop)


func _box(label: String, box: AABB) -> void:
	var shape := BoxShape3D.new()
	shape.size = box.size
	var collision := CollisionShape3D.new()
	collision.name = label
	collision.shape = shape
	collision.position = box.get_center()
	add_child(collision, true)
