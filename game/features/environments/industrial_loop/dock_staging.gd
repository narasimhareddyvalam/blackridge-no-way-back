extends RefCounted
## The staged loads behind the transfer shed's open docks (docs/PHASE_BRIEF.md, Phase 2 step 2c
## revised, part 2): American 48 x 40 in pallets of Poly Haven cartons in stretch wrap, four in
## dock 5's staging lane and two at bay 9; Kamran Mughal's forklift in the aisle behind dock 5,
## its forks down; FFeller's pallet jack under bay 9's second load; and a stack of empty pallets
## on the pier between dock 8 and bay 9. None of it is solid: the inside is seen from the yard.

const Build = preload("res://shared/components/mesh_builder.gd")
const ART := "res://features/environments/industrial_loop/art/depot/"
const LOADS: Array[Vector2] = [Vector2(-64.55, 16.45), Vector2(-63.45, 16.45),
	Vector2(-64.55, 15.15), Vector2(-63.45, 15.15), Vector2(-48.3, 16.6), Vector2(-47.2, 16.6)]
const LAYERS: Array[int] = [3, 3, 2, 3, 3, 2]
const EMPTIES := Vector2(-49.9, 18.95)
const EMPTY_COUNT := 5
const FORKLIFT := Vector2(-63.2, 12.4)
const FORKLIFT_HEADING := 0.2
const JACK := Vector2(-47.2, 16.35)
const PALLET_HEIGHT := 0.15
const CARTON := Vector3(0.52, 0.34, 0.39)
const COLUMNS := 2
const ROWS := 3
const WRAP := Color(0.9, 0.93, 0.95, 0.22)
const SEED := 225


static func build(shed: Node3D, floor_y: float) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = SEED
	var pallet := load(ART + "pallet.glb") as PackedScene
	var film := _film()
	var spots: Array[Transform3D] = []
	for index in range(LOADS.size()):
		var at := Vector3(LOADS[index].x, floor_y, LOADS[index].y)
		var yaw := random.randf_range(-0.025, 0.025)
		_pallet(shed, pallet, "Pallet%d" % (index + 1), at, yaw)
		spots.append_array(_cartons(at + Vector3.UP * PALLET_HEIGHT, yaw, LAYERS[index], random))
		var bottom := PALLET_HEIGHT / 2.0
		var top := PALLET_HEIGHT + LAYERS[index] * CARTON.y + 0.01
		var wrap := Build.box(shed, at + Vector3(0.0, (bottom + top) / 2.0, 0.0), Vector3(
			COLUMNS * CARTON.x + 0.03, top - bottom, ROWS * CARTON.z + 0.04), film)
		wrap.rotation.y = yaw
		wrap.name = "StretchWrap"
	for layer in range(EMPTY_COUNT):
		var at := Vector3(EMPTIES.x + random.randf_range(-0.02, 0.02),
			floor_y + layer * (PALLET_HEIGHT - 0.002), EMPTIES.y + random.randf_range(-0.02, 0.02))
		_pallet(shed, pallet, "Pallet%d" % (LOADS.size() + layer + 1), at,
			random.randf_range(-0.05, 0.05))
	_add_cartons(shed, spots)
	_place(shed, "forklift.glb", "Forklift", Vector3(FORKLIFT.x, floor_y, FORKLIFT.y),
		FORKLIFT_HEADING)
	_place(shed, "pallet_jack.glb", "PalletJack", Vector3(JACK.x, floor_y, JACK.y), PI)


static func _pallet(shed: Node3D, scene: PackedScene, name: String, at: Vector3,
		yaw: float) -> void:
	var pallet := scene.instantiate() as Node3D
	pallet.name = name
	pallet.position = at
	pallet.rotation.y = yaw
	shed.add_child(pallet)


static func _place(shed: Node3D, file: String, name: String, at: Vector3, heading: float) -> void:
	var model := (load(ART + file) as PackedScene).instantiate() as Node3D
	model.name = name
	model.position = at
	model.rotation.y = heading
	shed.add_child(model)


static func _cartons(base: Vector3, yaw: float, layers: int,
		random: RandomNumberGenerator) -> Array[Transform3D]:
	var spots: Array[Transform3D] = []
	var turn := Basis(Vector3.UP, yaw)
	for layer in range(layers):
		for column in range(COLUMNS):
			for row in range(ROWS):
				var offset := Vector3((column - (COLUMNS - 1) / 2.0) * CARTON.x, layer * CARTON.y,
					(row - (ROWS - 1) / 2.0) * CARTON.z)
				offset += Vector3(random.randf_range(-0.006, 0.006), 0.0,
					random.randf_range(-0.006, 0.006))
				var spin := PI / 2.0 + (PI if random.randf() < 0.5 else 0.0) \
					+ random.randf_range(-0.015, 0.015)
				spots.append(Transform3D(turn * Basis(Vector3.UP, spin), base + turn * offset))
	return spots


static func _add_cartons(shed: Node3D, spots: Array[Transform3D]) -> void:
	var source := (load(ART + "carton.glb") as PackedScene).instantiate() as Node3D
	var part := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = part.mesh
	multimesh.instance_count = spots.size()
	for index in range(spots.size()):
		multimesh.set_instance_transform(index, spots[index] * part.transform)
	source.free()
	var cartons := MultiMeshInstance3D.new()
	cartons.name = "Cartons"
	cartons.multimesh = multimesh
	shed.add_child(cartons)


static func _film() -> StandardMaterial3D:
	var film := StandardMaterial3D.new()
	film.albedo_color = WRAP
	film.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	film.roughness = 0.15
	film.metallic_specular = 0.7
	return film
