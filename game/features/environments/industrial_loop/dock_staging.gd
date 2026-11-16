extends RefCounted
## The staged loads behind the transfer shed's open docks (docs/PHASE_BRIEF.md, Phase 2 step 2c
## revised, part 2): American 48 x 40 in pallets of Poly Haven cartons in stretch wrap, four in
## dock 5's staging lane and two at bay 9; Kamran Mughal's forklift in the aisle behind dock 5,
## its forks down; FFeller's pallet jack under bay 9's second load; and a stack of empty pallets
## on the pier between dock 8 and bay 9. Since step 2e Ethan walks among them, so each is solid,
## and each load is one node (its pallet, cartons, wrap and body) that can be moved whole.

const Build = preload("res://shared/components/mesh_builder.gd")
const ForkliftTruck = preload("res://features/vehicles/forklift/forklift_truck.gd")
const ART := "res://features/environments/industrial_loop/art/depot/"
const LOADS: Array[Vector2] = [Vector2(-64.55, 16.45), Vector2(-63.45, 16.45),
	Vector2(-64.55, 15.15), Vector2(-63.45, 15.15), Vector2(-52.0, 16.6), Vector2(-47.2, 16.6)]
const LAYERS: Array[int] = [3, 3, 2, 3, 3, 2]
const EMPTIES := Vector2(-49.9, 18.95)
const EMPTY_COUNT := 5
const FORKLIFT := Vector2(-63.2, 12.4)
const FORKLIFT_HEADING := 0.2
const FORKLIFT_SIZE := Vector3(1.12, 2.21, 3.3)
## The forklift's own load (part G of step 5 of #253): a pallet of cartons in dock 6's staging
## lane, which it carries to aisle 03 and back; drawn with its own seed so that the staged loads
## and the empties stay as they were.
const PUTAWAY := Vector2(-60.0, 16.3)
const PUTAWAY_LAYERS := 3
const PUTAWAY_SEED := 302
const JACK := Vector2(-47.2, 16.35)
const JACK_BODY := Vector3(0.6, 1.2, 0.4)
const PALLET := Vector3(1.016, 0.15, 1.219)
const CARTON := Vector3(0.52, 0.34, 0.39)
const COLUMNS := 2
const ROWS := 3
const WRAP := Color(0.9, 0.93, 0.95, 0.22)
const SEED := 225
const FORK_GAP := 0.1


static func build(shed: Node3D, floor_y: float) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = SEED
	var pallet := load(ART + "pallet.glb") as PackedScene
	var film := _film()
	var source := (load(ART + "carton.glb") as PackedScene).instantiate() as Node3D
	var carton := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	for index in range(LOADS.size()):
		var at := Vector3(LOADS[index].x, floor_y, LOADS[index].y)
		var stack := _pallet(shed, pallet, "Pallet%d" % (index + 1), at,
			random.randf_range(-0.025, 0.025))
		_cartons(stack, carton, LAYERS[index], random)
		var bottom := PALLET.y / 2.0
		var top := PALLET.y + LAYERS[index] * CARTON.y + 0.01
		Build.box(stack, Vector3(0.0, (bottom + top) / 2.0, 0.0), Vector3(COLUMNS * CARTON.x + 0.03,
			top - bottom, ROWS * CARTON.z + 0.04), film).name = "StretchWrap"
		_solid(stack, "LoadBody", Vector3(COLUMNS * CARTON.x + 0.03, top - FORK_GAP, PALLET.z),
			Vector3.UP * FORK_GAP)
	var putaway := _putaway(shed, pallet, carton, film, floor_y)
	source.free()
	for layer in range(EMPTY_COUNT):
		var at := Vector3(EMPTIES.x + random.randf_range(-0.02, 0.02),
			floor_y + layer * (PALLET.y - 0.002), EMPTIES.y + random.randf_range(-0.02, 0.02))
		_pallet(shed, pallet, "Pallet%d" % (LOADS.size() + layer + 1), at,
			random.randf_range(-0.05, 0.05))
	var empties := Node3D.new()
	empties.name = "EmptyPalletsBody"
	empties.position = Vector3(EMPTIES.x, floor_y, EMPTIES.y)
	shed.add_child(empties)
	_solid(empties, "StackBody", Vector3(PALLET.x, EMPTY_COUNT * PALLET.y, PALLET.z))
	var forklift := ForkliftTruck.new()
	shed.add_child(forklift)
	forklift.call("park", putaway)
	var jack := _place(shed, "pallet_jack.glb", "PalletJack", Vector3(JACK.x, floor_y, JACK.y), PI)
	_solid(jack, "JackBody", JACK_BODY, Vector3(0.0, 0.0, 0.6))


static func _putaway(shed: Node3D, pallet: PackedScene, carton: MeshInstance3D,
		film: Material, floor_y: float) -> Node3D:
	var random := RandomNumberGenerator.new()
	random.seed = PUTAWAY_SEED
	var stack := _pallet(shed, pallet, "PutawayLoad", Vector3(PUTAWAY.x, floor_y, PUTAWAY.y),
		0.0)
	_cartons(stack, carton, PUTAWAY_LAYERS, random)
	var bottom := PALLET.y / 2.0
	var top := PALLET.y + PUTAWAY_LAYERS * CARTON.y + 0.01
	Build.box(stack, Vector3(0.0, (bottom + top) / 2.0, 0.0), Vector3(COLUMNS * CARTON.x + 0.03,
		top - bottom, ROWS * CARTON.z + 0.04), film).name = "StretchWrap"
	_solid(stack, "LoadBody", Vector3(COLUMNS * CARTON.x + 0.03, top - FORK_GAP, PALLET.z),
		Vector3.UP * FORK_GAP)
	return stack


static func _pallet(shed: Node3D, scene: PackedScene, label: String, at: Vector3,
		yaw: float) -> Node3D:
	var pallet := scene.instantiate() as Node3D
	pallet.name = label
	pallet.position = at
	pallet.rotation.y = yaw
	shed.add_child(pallet)
	return pallet


static func _place(shed: Node3D, file: String, label: String, at: Vector3,
		heading: float) -> Node3D:
	var model := (load(ART + file) as PackedScene).instantiate() as Node3D
	model.name = label
	model.position = at
	model.rotation.y = heading
	shed.add_child(model)
	return model


static func _cartons(stack: Node3D, carton: MeshInstance3D, layers: int,
		random: RandomNumberGenerator) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = carton.mesh
	multimesh.instance_count = layers * COLUMNS * ROWS
	var index := 0
	for layer in range(layers):
		for column in range(COLUMNS):
			for row in range(ROWS):
				var offset := Vector3((column - (COLUMNS - 1) / 2.0) * CARTON.x,
					PALLET.y + layer * CARTON.y, (row - (ROWS - 1) / 2.0) * CARTON.z)
				offset += Vector3(random.randf_range(-0.006, 0.006), 0.0,
					random.randf_range(-0.006, 0.006))
				var spin := PI / 2.0 + (PI if random.randf() < 0.5 else 0.0) \
					+ random.randf_range(-0.015, 0.015)
				multimesh.set_instance_transform(index, Transform3D(Basis(Vector3.UP, spin),
					offset) * carton.transform)
				index += 1
	var cartons := MultiMeshInstance3D.new()
	cartons.name = "Cartons"
	cartons.multimesh = multimesh
	stack.add_child(cartons)


static func _solid(holder: Node3D, label: String, size: Vector3,
		offset: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name = label
	holder.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	collision.shape = shape
	collision.position = offset + Vector3.UP * size.y / 2.0
	body.add_child(collision)


static func _film() -> StandardMaterial3D:
	var film := StandardMaterial3D.new()
	film.albedo_color = WRAP
	film.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	film.roughness = 0.15
	film.metallic_specular = 0.7
	return film
