extends Node3D
## The transfer shed's yard at night (docs/PHASE_BRIEF.md, step 5 of #253, part H; the author's
## choices, #305): what stands in it overnight, parked, none of it moving. NLM's 45 ft dry van
## (CC BY), dropped and backed square onto docks 1-3 for the morning's loading, their rears at
## the bumpers, their floors at the dock's height, their landing gear down on the paving and a
## rear wheel chocked; a third dropped in the west trailer bay and a fourth coupled to Brian
## Trepanier's 1980 tractor (CC BY) in the middle bay, its nose resting on the fifth wheel and its
## landing gear cranked up; Daniel Zhabotinsky's box truck (CC BY) nose out in the east bay; the
## sedan and Poly Haven's covered car in the staff bays, nose in; YJ_'s dumpsters (CC BY) against
## the shed's east wall, where a refuse truck can reach them (the paving beyond the west wall is
## 2 m wide). Each is solid (`VehicleBodies`), and drawn only within DRAWN_WITHIN.

const ART := "res://features/environments/industrial_loop/art/"
const TRAILER := preload("res://features/environments/industrial_loop/art/depot/trailer_dryvan.glb")
const TRACTOR := preload("res://features/environments/industrial_loop/art/depot/tractor_1980.glb")
const TRUCK := preload("res://features/environments/industrial_loop/art/depot/box_truck.glb")
const DUMPSTERS := preload("res://features/environments/industrial_loop/art/depot/dumpsters.glb")
const SEDAN := preload("res://features/environments/industrial_loop/art/town/sedan.glb")
const COVERED_CAR := "res://features/environments/depot_yard/polyhaven/models/covered_car/" \
	+ "covered_car.gltf"
const GROUND := 0.02
const DRAWN_WITHIN := 90.0
## The dry van as converted: half its length, its width, its rear sill's height, its kingpin
## plate (0.91 m behind its nose, 1.21 m up), its rear axle (4.9 m behind its middle).
const TRAILER_HALF := 6.875
const TRAILER_WIDTH := 2.41
const TRAILER_SILL := 1.32
const KINGPIN := Vector3(0.0, 1.21, 5.95)
const REAR_AXLE := -4.9
const GEAR_LIFT := 0.28
## The tractor's fifth wheel, 2.7 m behind its middle and 1.11 m up.
const FIFTH_WHEEL := Vector3(0.0, 1.11, -2.7)
const TRUCK_LENGTH := 6.02
## Its body's width; its mirrors reach 2.61 m, past its bay's lines as a parked truck's do.
const TRUCK_WIDTH := 2.28
## The docks and their bumpers' faces (`transfer_building.gd`), the trailer bays and the staff
## bays (`transfer_yard.gd`).
const TRAILER_DOCKS: Array[float] = [-80.0, -76.0, -72.0]
const BUMPER_FACE := 20.13
const DOCK_GAP := 0.02
const BAYS: Array[float] = [-37.4, -33.6, -29.8]
const BAY_BACK := 4.0
const BAY_LENGTH := 14.0
const BAY_GAP := 0.1
const STAFF_BAYS := Rect2(-88.4, 42.4, 5.0, 12.5)
const STAFF_BAY := 2.5
const CARS_IN: Array[int] = [1, 3]
## The staff bays' kerb: a car parked nose in stops short of it, over the bay's front line.
const KERB_X := -89.0
const FROM_KERB := 0.3
const EAST_WALL := -40.0
const DUMPSTER_Z := -2.0
const DUMPSTER_DEPTH := 1.75
const DUMPSTER_FROM_WALL := 0.15
const CHOCK := Vector3(0.25, 0.2, 0.3)
const CHOCK_OUT := 1.0
## The chock just ahead of the tandem's forward tyres (their axle 0.6 m ahead of the tandem's middle,
## the tyres 0.5 m round).
const CHOCK_AHEAD := 1.25

var _placed := {}
var _footprints: Array[Rect2] = []
var _car_boxes: Array[Rect2] = []
var _body: StaticBody3D
var _kingpin := Vector3.ZERO
var _fifth := Vector3.ZERO
var _gear_lift := 0.0
var _sedan_front := Vector3.ZERO
var _dumpster_box := Rect2()


func build() -> void:
	_body = StaticBody3D.new()
	_body.name = "VehicleBodies"
	add_child(_body)
	var docked: Array[Transform3D] = []
	var chocks: Array[Transform3D] = []
	for x in TRAILER_DOCKS:
		var at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND, BUMPER_FACE + DOCK_GAP
			+ TRAILER_HALF))
		docked.append(at)
		_trailer("DockedTrailer", at, false)
		var chock := Transform3D(Basis.IDENTITY, at * Vector3(CHOCK_OUT, 0.0,
			REAR_AXLE + CHOCK_AHEAD))
		chocks.append(chock)
		_chock(chock)
	_placed["DockedTrailers"] = docked
	_placed["Chocks"] = chocks
	var bay_z := BAY_BACK + BAY_GAP + TRAILER_HALF
	var dropped := Transform3D(Basis.IDENTITY, Vector3(BAYS[0], GROUND, bay_z))
	_trailer("BayTrailer", dropped, false)
	_couple(Vector3(BAYS[1], GROUND, bay_z))
	var truck := Transform3D(Basis.IDENTITY, Vector3(BAYS[2], GROUND, BAY_BACK + BAY_LENGTH
		- BAY_GAP - TRUCK_LENGTH / 2.0))
	_placed["BoxTruck"] = [truck] as Array[Transform3D]
	_model(TRUCK, "BoxTruck", truck)
	_solid(truck, Vector3(TRUCK_WIDTH, 2.85, TRUCK_LENGTH))
	_cars()
	_dumpsters()


func placements(label: String) -> Array:
	return (_placed.get(label, []) as Array).duplicate()


## Where the coupled trailer's kingpin plate is, and where the tractor's fifth wheel is.
func kingpin() -> Vector3:
	return _kingpin


func fifth_wheel() -> Vector3:
	return _fifth


func coupled_gear_lift() -> float:
	return _gear_lift


func car_boxes() -> Array:
	return _car_boxes.duplicate()


func sedan_front() -> Vector3:
	return _sedan_front


func dumpster_box() -> Rect2:
	return _dumpster_box


## Each parked vehicle's footprint on the paving (x, z).
func footprints() -> Array:
	return _footprints.duplicate()


func _trailer(label: String, at: Transform3D, coupled: bool) -> Node3D:
	var trailer := _model(TRAILER, label, at)
	if label == "BayTrailer":
		var list: Array = _placed.get("BayTrailers", [])
		list.append(at)
		_placed["BayTrailers"] = list
	_solid(at, Vector3(TRAILER_WIDTH, 4.35, TRAILER_HALF * 2.0))
	if coupled:
		var gear := trailer.find_child("LandingGear", true, false) as Node3D
		if gear != null:
			gear.position.y += GEAR_LIFT
			_gear_lift = GEAR_LIFT
	return trailer


## The tractor coupled to a trailer standing in the bay at `at`: the trailer's nose lowered onto
## the fifth wheel, pitched about its rear axle, and the tractor under it, nose out.
func _couple(at: Vector3) -> void:
	var drop := (KINGPIN.y - FIFTH_WHEEL.y)
	var reach := KINGPIN.z - REAR_AXLE
	var pitch := atan(drop / reach)
	var level := Transform3D(Basis.IDENTITY, at)
	var axle := level * Vector3(0.0, 0.0, REAR_AXLE)
	var tipped := Basis(Vector3.RIGHT, pitch)
	var trailer := Transform3D(tipped, axle + tipped * (at - axle))
	var list: Array = _placed.get("BayTrailers", [])
	list.append(trailer)
	_placed["BayTrailers"] = list
	_trailer("CoupledTrailer", trailer, true)
	_kingpin = trailer * KINGPIN
	var tractor := Transform3D(Basis.IDENTITY, Vector3(_kingpin.x, GROUND, _kingpin.z
		- FIFTH_WHEEL.z))
	_fifth = tractor * FIFTH_WHEEL
	_placed["Tractor"] = [tractor] as Array[Transform3D]
	_model(TRACTOR, "Tractor", tractor)
	_solid(tractor, Vector3(2.57, 3.93, 8.46))


func _cars() -> void:
	var models: Array[PackedScene] = [SEDAN, load(COVERED_CAR) as PackedScene]
	var cars: Array[Transform3D] = []
	for index in range(models.size()):
		var car := models[index].instantiate() as Node3D
		car.name = "StaffCar%d" % (index + 1)
		add_child(car)
		var box := _local_box(car)
		var long_along_x := box.size.x > box.size.z
		var turn := Basis(Vector3.UP, 0.0 if long_along_x else -PI / 2.0)
		var length := maxf(box.size.x, box.size.z)
		var width := minf(box.size.x, box.size.z)
		var centre := turn * box.get_center()
		var bay_middle := STAFF_BAYS.position.y + (CARS_IN[index] + 0.5) * STAFF_BAY
		var front := KERB_X + FROM_KERB + length / 2.0
		var at := Transform3D(turn, Vector3(front - centre.x, GROUND - box.position.y,
			bay_middle - centre.z))
		car.global_transform = at
		cars.append(at)
		if index == 0:
			_sedan_front = (turn * Vector3(0.0, 0.0, 1.0)).normalized()
		var rect := Rect2(front - length / 2.0, bay_middle - width / 2.0, length, width)
		_car_boxes.append(rect)
		_footprints.append(rect)
		_box_shape(Vector3(rect.get_center().x, GROUND + box.size.y / 2.0, rect.get_center().y),
			Vector3(length, box.size.y, width))
		_far(car)
	_placed["Cars"] = cars


func _dumpsters() -> void:
	var turn := Basis(Vector3.UP, PI / 2.0)
	var at := Transform3D(turn, Vector3(EAST_WALL + DUMPSTER_FROM_WALL + DUMPSTER_DEPTH / 2.0,
		GROUND, DUMPSTER_Z))
	_placed["Dumpsters"] = [at] as Array[Transform3D]
	_model(DUMPSTERS, "Dumpsters", at)
	_dumpster_box = Rect2(EAST_WALL + DUMPSTER_FROM_WALL, DUMPSTER_Z - 2.18, DUMPSTER_DEPTH, 4.36)
	_footprints.append(_dumpster_box)
	_box_shape(Vector3(_dumpster_box.get_center().x, GROUND + 0.77, _dumpster_box.get_center().y),
		Vector3(DUMPSTER_DEPTH, 1.54, 4.36))


func _chock(at: Transform3D) -> void:
	var wedge := MeshInstance3D.new()
	wedge.name = "WheelChock"
	var prism := PrismMesh.new()
	prism.size = Vector3(CHOCK.z, CHOCK.y, CHOCK.x)
	prism.left_to_right = 0.0
	wedge.mesh = prism
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.85, 0.65, 0.08)
	rubber.roughness = 0.8
	wedge.material_override = rubber
	add_child(wedge)
	wedge.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0), at.origin
		+ Vector3.UP * CHOCK.y / 2.0)


func _model(scene: PackedScene, label: String, at: Transform3D) -> Node3D:
	var model := scene.instantiate() as Node3D
	model.name = label
	add_child(model)
	model.global_transform = at
	_far(model)
	return model


func _far(model: Node3D) -> void:
	for found in model.find_children("*", "GeometryInstance3D", true, false):
		(found as GeometryInstance3D).visibility_range_end = DRAWN_WITHIN


func _solid(at: Transform3D, size: Vector3) -> void:
	_box_shape(at.origin + at.basis * Vector3(0.0, size.y / 2.0, 0.0), size, at.basis)
	var half := Vector2(size.x, size.z) / 2.0
	_footprints.append(Rect2(Vector2(at.origin.x, at.origin.z) - half, half * 2.0))


func _box_shape(centre: Vector3, size: Vector3, basis: Basis = Basis.IDENTITY) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_body.add_child(collision)
	collision.global_transform = Transform3D(basis, centre)


## A model's box in its own frame, from its meshes.
func _local_box(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var part := model.global_transform.affine_inverse() * mesh.global_transform \
			* mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
