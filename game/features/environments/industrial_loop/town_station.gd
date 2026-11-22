extends Node3D
## The south valley road's gas station and main street (#267, part C; the place the author's,
## #268): a small American town's edge at night, on a level plot south of the road.
##
## The gas station, as US stations are built (the American Petroleum Institute's and NFPA 30A's
## layouts, typical canopy dimensions): a canopy 18 x 9 m, its underside 4.6 m up (US canopies are
## built 14 ft 6 in to 16 ft clear, 4.42-4.88 m), white with a red band, on four steel columns
## standing on two concrete pump islands 10 x 1.2 m, 0.15 m high, their noses painted safety yellow
## and guarded by bollards (6 in, 168 mm pipe filled with concrete, 1 m high), 4 m apart so a lane
## runs between them; two dispensers to an island (SavinienBerault's unbranded two-hose pump,
## REGULAR and DIESEL, CC BY), the warning label every US column carries; eight recessed LED
## downlights in the canopy, cool white, lighting the forecourt as brightly as stations are
## (several times a street's light). Two driveways from the road, 8 m wide.
## The store: 13 x 7 m, 4 m to its parapet, painted plaster, its storefront glass lit from inside,
## GROCERY on its lit fascia and OPEN 24 HOURS in its window. On the sidewalk before it: a pedestal
## payphone (evan4129's scan, CC BY), a newspaper box, a bench, a bin, an outdoor ice merchandiser
## and a propane exchange cage of eight cylinders (Poly Haven's Propane Tank, CC0), and at the
## forecourt's east edge the air and water machine.
## The price sign: a pylon by the road, its cabinet facing along the road both ways, GAS over
## REGULAR, PLUS and DIESEL in red LED digits (`town_signs.png`, tools/art/make_town_signs.py).
## Main street: three shops in a row, closed at night behind their roller shutters (Poly Haven's
## painted metal shutter), each with its faded fascia board (HARDWARE, LAUNDROMAT, BARBER) and a
## security light over its door; parking before them, two cars parked: the early-1980s sedan
## (Daniel Zhabotinsky's "Fairheaven LT '80", CC BY) and Poly Haven's covered car.
## Every piece a van or a man could walk into is solid. No sign carries a real brand.

const Build = preload("res://shared/components/mesh_builder.gd")
const SIGNS = preload("art/town/town_signs.png")
const CAGE_MESH = preload("art/town/cage_mesh.png")
const INTERIOR = preload("art/town/store_interior.png")
const PUMP = preload("art/town/gas_pump.glb")
const PAYPHONE = preload("art/town/payphone.glb")
const SEDAN = preload("art/town/sedan.glb")
const DEPOT_MODELS := "res://features/environments/depot_yard/polyhaven/models/%s/%s.gltf"
const LOOP_MODELS := "res://features/environments/industrial_loop/polyhaven/models/%s/%s.gltf"
const PLASTER := "res://features/environments/industrial_loop/polyhaven/textures/" \
	+ "painted_plaster_wall/painted_plaster_wall_%s_2k.jpg"
const BRICK := "res://features/environments/industrial_loop/polyhaven/textures/" \
	+ "painted_brick/painted_brick_%s_2k.jpg"
const SHUTTER := "res://features/environments/depot_yard/polyhaven/textures/" \
	+ "painted_metal_shutter/painted_metal_shutter_%s_2k.jpg"

const PLOT := Rect2(-4.0, 174.0, 58.0, 22.0)
const CANOPY := Rect2(6.0, 176.5, 18.0, 9.0)
const CANOPY_UNDER := 4.6
const FASCIA := 0.9
const ISLANDS: Array[Rect2] = [Rect2(10.0, 178.2, 10.0, 1.2), Rect2(10.0, 183.4, 10.0, 1.2)]
const ISLAND_HIGH := 0.15
const COLUMN := 0.35
const COLUMNS_X: Array[float] = [10.6, 19.4]
const PUMPS_X: Array[float] = [12.6, 17.4]
const PUMP_BODY := Vector3(0.63, 1.9, 0.9)
const BOLLARDS_X: Array[float] = [10.15, 19.85]
const BOLLARD := Vector2(0.084, 1.0)
const DOWNLIGHTS_X: Array[float] = [8.4, 12.8, 17.2, 21.6]
const DOWNLIGHTS_Z: Array[float] = [178.8, 183.2]
const DOWNLIGHT_ENERGY := 15.0
const DOWNLIGHT_COLOUR := Color(0.95, 0.96, 1.0)
const DRIVEWAYS: Array[Vector2] = [Vector2(0.0, 8.0), Vector2(22.0, 30.0)]
const DRIVE_PATH: Array[Vector2] = [Vector2(4.0, 171.0), Vector2(4.0, 181.4),
	Vector2(26.0, 181.4), Vector2(26.0, 171.0)]
const SIDEWALK := Rect2(-2.0, 187.6, 55.0, 1.4)
const KERB := 0.15
const STORE := Rect2(-2.0, 189.0, 13.0, 7.0)
const STORE_HIGH := 4.0
const SHOPS: Array[Rect2] = [Rect2(32.0, 189.0, 7.0, 7.0), Rect2(39.0, 189.0, 7.0, 7.0),
	Rect2(46.0, 189.0, 7.0, 7.0)]
const SHOP_HIGH := 4.6
const SHUTTER_OPENING := Vector2(4.6, 3.0)
const BAYS_FROM := 32.0
const BAY := 2.7
const BAY_DEEP := 5.6
const CARS: Array[int] = [1, 4]
const PRICE_SIGN := Vector3(29.0, 0.0, 175.5)
const PRICE_PANEL := Vector2(1.6, 0.8)
const PRICE_POSTS_Z: Array[float] = [-0.75, 0.75]
const PRICE_FROM := 3.2
const PRICES: Array[String] = ["REGULAR 3.59 9/10", "PLUS 3.89 9/10", "DIESEL 4.19 9/10"]
const SIGN_WORDS: Array[String] = ["GAS", "REGULAR", "PLUS", "DIESEL", "GROCERY", "ICE",
	"PROPANE EXCHANGE", "NEWSPAPERS", "HARDWARE", "LAUNDROMAT", "BARBER", "AIR WATER",
	"OPEN 24 HOURS", "STOP ENGINE NO SMOKING"]
## The atlas cells (`town_signs.png`, four by four).
const CELLS := {"gas": 0, "regular": 1, "plus": 2, "diesel": 3, "grocery": 4, "ice": 5,
	"propane": 6, "newspapers": 7, "hardware": 8, "laundromat": 9, "barber": 10, "air": 11,
	"open": 12, "warning": 13, "plain": 14}
const SHOP_SIGNS: Array[String] = ["hardware", "laundromat", "barber"]
const PAINT_WHITE := Color(0.9, 0.9, 0.88)
const PAINT_RED := Color(0.6, 0.07, 0.05)
const SAFETY_YELLOW := Color(0.95, 0.75, 0.05)
const STEEL := Color(0.42, 0.44, 0.46)
const LINE_WHITE := Color(0.82, 0.82, 0.8)
const INSIDE_GLOW := Color(1.0, 0.92, 0.78)
const SECURITY_COLOUR := Color(1.0, 0.8, 0.55)

var _terrain: Node3D
var _concrete := Build.material(Color(0.4, 0.4, 0.39), 0.85)
var _asphalt := Build.material(Color(0.12, 0.12, 0.13), 0.55)
var _steel := Build.material(STEEL, 0.45)


func build(terrain: Node3D) -> void:
	_terrain = terrain
	_ground()
	_canopy()
	_islands()
	_store()
	_street_furniture()
	_price_sign()
	_shops()
	_parking()


func _height(x: float, z: float) -> float:
	return _terrain.height_at(x, z) if _terrain != null else 0.0


func _ground() -> void:
	var level := _height(PLOT.get_center().x, PLOT.get_center().y)
	var forecourt := Rect2(PLOT.position.x, PLOT.position.y, PLOT.size.x,
		SIDEWALK.position.y - PLOT.position.y)
	Build.box(self, Vector3(forecourt.get_center().x, level + 0.01, forecourt.get_center().y),
		Vector3(forecourt.size.x, 0.02, forecourt.size.y), _asphalt).name = "Forecourt"
	Build.box(self, Vector3(CANOPY.get_center().x, level + 0.025, CANOPY.get_center().y),
		Vector3(CANOPY.size.x, 0.02, CANOPY.size.y), _concrete).name = "CanopySlab"
	for index in range(DRIVEWAYS.size()):
		var span := DRIVEWAYS[index]
		var middle := (span.x + span.y) / 2.0
		var edge := _road_edge(middle)
		var deep := PLOT.position.y - edge
		Build.box(self, Vector3(middle, level + 0.015, edge + deep / 2.0),
			Vector3(span.y - span.x, 0.03, deep), _concrete).name = "Driveway%d" % (index + 1)


func _road_edge(x: float) -> float:
	var z := PLOT.position.y
	while z > PLOT.position.y - 6.0 and _terrain != null \
			and float(_terrain.road_clearance(x, z)) > 2.25:
		z -= 0.1
	return z


func _canopy() -> void:
	var top := _height(CANOPY.get_center().x, CANOPY.get_center().y) + CANOPY_UNDER
	var deck := Build.box(self, Vector3(CANOPY.get_center().x, top + FASCIA / 2.0,
		CANOPY.get_center().y), Vector3(CANOPY.size.x, FASCIA, CANOPY.size.y),
		Build.material(PAINT_WHITE, 0.5))
	deck.name = "CanopyDeck"
	for side in [-1.0, 1.0]:
		Build.box(deck, Vector3(0.0, -0.05, side * (CANOPY.size.y / 2.0 + 0.005)),
			Vector3(CANOPY.size.x + 0.02, 0.22, 0.01), Build.material(PAINT_RED, 0.5))
		Build.box(deck, Vector3(side * (CANOPY.size.x / 2.0 + 0.005), -0.05, 0.0),
			Vector3(0.01, 0.22, CANOPY.size.y + 0.02), Build.material(PAINT_RED, 0.5))
	var count := 0
	for x in DOWNLIGHTS_X:
		for z in DOWNLIGHTS_Z:
			count += 1
			Build.box(self, Vector3(x, top - 0.006, z), Vector3(0.6, 0.01, 0.6),
				Build.luminous(DOWNLIGHT_COLOUR, 3.0))
			var light := SpotLight3D.new()
			light.name = "Downlight%d" % count
			light.position = Vector3(x, top - 0.05, z)
			light.rotation_degrees.x = -90.0
			light.light_color = DOWNLIGHT_COLOUR
			light.light_energy = DOWNLIGHT_ENERGY
			light.spot_range = 9.0
			light.spot_angle = 62.0
			light.spot_angle_attenuation = 0.8
			light.shadow_enabled = false
			add_child(light)
	var index := 0
	for island in ISLANDS:
		for x in COLUMNS_X:
			index += 1
			var foot := _height(x, island.get_center().y) + ISLAND_HIGH
			var column := _solid_box("Column%d" % index, Vector3(x, foot, island.get_center().y),
				Vector3(COLUMN, top - foot, COLUMN), Build.material(PAINT_WHITE, 0.55))
			for face in [-1.0, 1.0]:
				_sign(column, "warning", Vector3(0.0, 1.5 - (top - foot) / 2.0,
					face * (COLUMN / 2.0 + 0.003)), Vector2(0.3, 0.15), 0.0 if face > 0 else PI)


func _islands() -> void:
	var pumps := 0
	var bollards := 0
	for index in range(ISLANDS.size()):
		var island := ISLANDS[index]
		var ground := _height(island.get_center().x, island.get_center().y)
		var body := _solid_box("Island%d" % (index + 1), Vector3(island.get_center().x, ground,
			island.get_center().y), Vector3(island.size.x, ISLAND_HIGH, island.size.y), _concrete)
		for end in [-1.0, 1.0]:
			Build.box(body, Vector3(end * (island.size.x / 2.0 - 0.2), ISLAND_HIGH / 2.0 + 0.002,
				0.0), Vector3(0.4, 0.01, island.size.y + 0.004), Build.material(SAFETY_YELLOW, 0.6))
		for x in PUMPS_X:
			pumps += 1
			var pump := PUMP.instantiate() as Node3D
			pump.name = "Dispenser%d" % pumps
			add_child(pump)
			pump.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0 if index == 0
				else -PI / 2.0), Vector3(x, ground + ISLAND_HIGH, island.get_center().y))
			_body(pump, "Dispenser%dBody" % pumps, Vector3(PUMP_BODY.z, PUMP_BODY.y,
				PUMP_BODY.x), Vector3.UP * PUMP_BODY.y / 2.0)
		for x in BOLLARDS_X:
			bollards += 1
			var at := Vector3(x, ground + ISLAND_HIGH, island.get_center().y)
			var post := Build.cylinder(self, at + Vector3.UP * BOLLARD.y / 2.0, BOLLARD.x,
				BOLLARD.y, Build.material(SAFETY_YELLOW, 0.5))
			post.name = "Bollard%d" % bollards
			_cylinder_body(post, BOLLARD.x, BOLLARD.y)


func _store() -> void:
	var ground := _height(STORE.get_center().x, STORE.get_center().y) + KERB
	var store := _solid_box("Store", Vector3(STORE.get_center().x, ground, STORE.get_center().y),
		Vector3(STORE.size.x, STORE_HIGH, STORE.size.y), _textured(PLASTER, 2.0, Color.WHITE))
	var front := -STORE.size.y / 2.0 - 0.01
	var middle := 0.0
	var foot := -STORE_HIGH / 2.0
	var inside := StandardMaterial3D.new()
	inside.albedo_color = Color(0.05, 0.05, 0.06)
	inside.roughness = 0.08
	inside.metallic_specular = 0.6
	inside.emission_enabled = true
	inside.emission_texture = INTERIOR
	inside.emission_energy_multiplier = 0.55
	var windows := Build.box(store, Vector3(middle - 1.6, foot + 1.55, front),
		Vector3(8.6, 2.1, 0.02), inside)
	windows.name = "StoreWindow"
	for mullion in range(5):
		Build.box(windows, Vector3(-4.3 + mullion * 2.15, 0.0, -0.01), Vector3(0.08, 2.1, 0.02),
			Build.material(Color(0.1, 0.1, 0.1), 0.4))
	Build.box(store, Vector3(middle + 4.4, foot + 1.1, front),
		Vector3(1.2, 2.2, 0.02), inside).name = "StoreDoor"
	var fascia := _sign(store, "grocery", Vector3(middle, foot + 3.2, front - 0.02),
		Vector2(5.0, 0.8), PI, 1.2)
	fascia.name = "StoreFascia"
	_sign(store, "open", Vector3(middle - 4.2, foot + 2.2, front - 0.03),
		Vector2(1.0, 0.5), PI, 1.6)
	var spill := OmniLight3D.new()
	spill.name = "StoreSpill"
	spill.position = Vector3(middle - 1.0, foot + 2.0, front - 1.0)
	spill.light_color = INSIDE_GLOW
	spill.light_energy = 1.2
	spill.omni_range = 7.0
	spill.shadow_enabled = false
	store.add_child(spill)
	var box := (load(LOOP_MODELS % ["utility_box_02", "utility_box_02"]) as PackedScene) \
		.instantiate() as Node3D
	box.name = "UtilityBox"
	add_child(box)
	box.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0),
		Vector3(STORE.position.x - 0.5, _height(STORE.position.x - 0.5, 192.0), 192.0))
	_body(box, "UtilityBoxBody", Vector3(0.43, 1.12, 0.92), Vector3.UP * 0.56)


func _street_furniture() -> void:
	var ground := _height(SIDEWALK.get_center().x, SIDEWALK.get_center().y)
	Build.box(self, Vector3(SIDEWALK.get_center().x, ground + KERB / 2.0, SIDEWALK.get_center().y),
		Vector3(SIDEWALK.size.x, KERB, SIDEWALK.size.y), _concrete).name = "Sidewalk"
	var walk := ground + KERB
	var row := SIDEWALK.get_center().y + 0.15
	var phone := PAYPHONE.instantiate() as Node3D
	phone.name = "Payphone"
	add_child(phone)
	phone.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(-1.2, walk, row))
	_body(phone, "PayphoneBody", Vector3(0.5, 2.0, 0.5), Vector3.UP)
	_newspaper_box(Vector3(0.1, walk, row))
	_bench(Vector3(2.7, walk, row + 0.1))
	_bin(Vector3(6.2, walk, row))
	_ice_chest(Vector3(9.4, walk, row + 0.05))
	_propane_cage(Vector3(12.2, walk, row + 0.05))
	_air_water(Vector3(24.5, walk, row))


func _newspaper_box(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "NewspaperBox"
	add_child(holder)
	holder.position = at
	var paint := Build.material(Color(0.12, 0.28, 0.42), 0.45)
	Build.box(holder, Vector3(0.0, 0.3, 0.0), Vector3(0.12, 0.6, 0.12), _steel)
	Build.box(holder, Vector3(0.0, 0.6 + 0.24, 0.0), Vector3(0.5, 0.48, 0.42), paint)
	Build.box(holder, Vector3(0.0, 0.88, -0.212), Vector3(0.38, 0.22, 0.01),
		Build.material(Color(0.6, 0.62, 0.62), 0.1))
	_sign(holder, "newspapers", Vector3(0.0, 1.05, -0.213), Vector2(0.4, 0.1), PI)
	_body(holder, "NewspaperBoxBody", Vector3(0.5, 1.08, 0.42), Vector3.UP * 0.54)


func _bench(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Bench"
	add_child(holder)
	holder.position = at
	var wood := _textured(LOOP_MODELS.get_base_dir().get_base_dir() + "/textures/" \
		+ "weathered_plank_siding/weathered_plank_siding_%s_2k.jpg", 1.0, Color(0.8, 0.75, 0.7))
	for end in [-0.8, 0.8]:
		Build.box(holder, Vector3(end, 0.225, 0.0), Vector3(0.06, 0.45, 0.5), _steel)
		Build.box(holder, Vector3(end, 0.62, 0.22), Vector3(0.06, 0.8, 0.05), _steel)
	for slat in range(3):
		Build.box(holder, Vector3(0.0, 0.45, -0.16 + slat * 0.16), Vector3(1.8, 0.04, 0.12), wood)
	for slat in range(2):
		Build.box(holder, Vector3(0.0, 0.66 + slat * 0.16, 0.24), Vector3(1.8, 0.11, 0.03), wood)
	_body(holder, "BenchBody", Vector3(1.8, 0.9, 0.55), Vector3.UP * 0.45)


func _bin(at: Vector3) -> void:
	var bin := (load(DEPOT_MODELS % ["metal_trash_can", "metal_trash_can"]) as PackedScene) \
		.instantiate() as Node3D
	bin.name = "Bin"
	add_child(bin)
	for child in bin.find_children("*", "Node3D", true, false):
		if not String(child.name).contains("rust") and child is MeshInstance3D:
			(child as Node3D).visible = false
	var centre := Vector3.ZERO
	var count := 0
	for child in bin.find_children("*rust*", "MeshInstance3D", true, false):
		centre += (child as MeshInstance3D).transform.origin
		count += 1
	centre /= maxf(count, 1)
	bin.global_transform = Transform3D(Basis.IDENTITY, at - Vector3(centre.x, 0.0, centre.z)
		+ Vector3.UP * 0.072)
	var body := StaticBody3D.new()
	body.name = "BinBody"
	var shape := CollisionShape3D.new()
	var round := CylinderShape3D.new()
	round.radius = 0.3
	round.height = 0.98
	shape.shape = round
	shape.position = Vector3(centre.x, 0.49 - 0.072, centre.z)
	body.add_child(shape)
	bin.add_child(body)


func _ice_chest(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "IceChest"
	add_child(holder)
	holder.position = at
	var white := Build.material(Color(0.92, 0.93, 0.94), 0.35)
	Build.box(holder, Vector3(0.0, 0.67, 0.0), Vector3(1.52, 1.18, 0.78), white)
	Build.box(holder, Vector3(0.0, 0.06, 0.0), Vector3(1.48, 0.12, 0.74),
		Build.material(Color(0.12, 0.12, 0.13), 0.6))
	for door in [-0.37, 0.37]:
		Build.box(holder, Vector3(door, 0.7, -0.395), Vector3(0.7, 0.95, 0.01),
			Build.material(Color(0.88, 0.89, 0.9), 0.3))
		Build.box(holder, Vector3(door + (0.3 if door < 0 else -0.3), 0.75, -0.405),
			Vector3(0.04, 0.25, 0.02), _steel)
	_sign(holder, "ice", Vector3(0.0, 1.05, -0.402), Vector2(1.0, 0.5), PI)
	_body(holder, "IceChestBody", Vector3(1.52, 1.26, 0.78), Vector3.UP * 0.63)


func _propane_cage(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "PropaneCage"
	add_child(holder)
	holder.position = at
	var size := Vector3(1.25, 1.65, 0.8)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			Build.box(holder, Vector3(x * size.x / 2.0, size.y / 2.0, z * size.z / 2.0),
				Vector3(0.04, size.y, 0.04), _steel)
	var mesh := StandardMaterial3D.new()
	mesh.albedo_texture = CAGE_MESH
	mesh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mesh.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.metallic = 0.8
	mesh.roughness = 0.45
	mesh.uv1_triplanar = true
	mesh.uv1_world_triplanar = true
	mesh.uv1_scale = Vector3.ONE / 0.05
	for face: Array in [[Vector3(0, 0, -1), Vector2(size.x, size.y)], [Vector3(0, 0, 1),
			Vector2(size.x, size.y)], [Vector3(-1, 0, 0), Vector2(size.z, size.y)],
			[Vector3(1, 0, 0), Vector2(size.z, size.y)], [Vector3(0, 1, 0), Vector2(size.x,
			size.z)]]:
		var normal: Vector3 = face[0]
		var span: Vector2 = face[1]
		var panel := Build.box(holder, Vector3(normal.x * size.x / 2.0, size.y / 2.0 + normal.y
			* size.y / 2.0, normal.z * size.z / 2.0), Vector3(span.x if normal.x == 0.0 else 0.01,
			span.y if normal.y == 0.0 else 0.01, (span.x if normal.y != 0.0 else 0.01)
			if normal.z == 0.0 else 0.01), mesh)
		if normal.y != 0.0:
			panel.mesh.size = Vector3(size.x, 0.01, size.z)
	for shelf in [0.05, 0.85]:
		Build.box(holder, Vector3(0.0, shelf, 0.0), Vector3(size.x, 0.03, size.z), _steel)
	var tank := load(LOOP_MODELS % ["propane_tank", "propane_tank"]) as PackedScene
	var count := 0
	for shelf in [0.065, 0.865]:
		for x in [-0.45, -0.15, 0.15, 0.45]:
			count += 1
			var cylinder := tank.instantiate() as Node3D
			cylinder.name = "Cylinder%d" % count
			holder.add_child(cylinder)
			cylinder.position = Vector3(x, shelf, 0.12 if count % 2 else -0.1)
			cylinder.rotation.y = count * 1.3
	_sign(holder, "propane", Vector3(0.0, size.y + 0.25, -size.z / 2.0 - 0.01),
		Vector2(1.0, 0.5), PI)
	_body(holder, "PropaneCageBody", size + Vector3(0.0, 0.5, 0.0), Vector3.UP * 1.07)


func _air_water(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "AirWater"
	add_child(holder)
	holder.position = at
	Build.box(holder, Vector3(0.0, 0.4, 0.0), Vector3(0.12, 0.8, 0.12), _steel)
	Build.box(holder, Vector3(0.0, 1.05, 0.0), Vector3(0.5, 0.6, 0.35),
		Build.material(Color(0.62, 0.08, 0.06), 0.45))
	_sign(holder, "air", Vector3(0.0, 1.1, -0.177), Vector2(0.44, 0.22), PI)
	Build.cylinder(holder, Vector3(0.3, 0.95, 0.0), 0.12, 0.05, Build.material(Color(0.05, 0.05,
		0.05), 0.8)).rotation.z = PI / 2.0
	_body(holder, "AirWaterBody", Vector3(0.5, 1.35, 0.35), Vector3.UP * 0.675)


func _price_sign() -> void:
	var ground := _height(PRICE_SIGN.x, PRICE_SIGN.z)
	var holder := Node3D.new()
	holder.name = "PriceSign"
	add_child(holder)
	holder.position = Vector3(PRICE_SIGN.x, ground, PRICE_SIGN.z)
	var charcoal := Build.material(Color(0.14, 0.15, 0.16), 0.5)
	for post_z in PRICE_POSTS_Z:
		Build.box(holder, Vector3(0.0, PRICE_FROM / 2.0, post_z), Vector3(0.2, PRICE_FROM, 0.2),
			_steel)
	var tall := PRICE_PANEL.y * 4.0 + 0.2
	Build.box(holder, Vector3(0.0, PRICE_FROM + tall / 2.0, 0.0), Vector3(0.4, tall,
		PRICE_PANEL.x + 0.2), charcoal)
	var cells := ["gas", "regular", "plus", "diesel"]
	for face in [-1.0, 1.0]:
		for index in range(cells.size()):
			_sign(holder, cells[index], Vector3(face * 0.205, PRICE_FROM + tall - 0.1
				- PRICE_PANEL.y * (index + 0.5), 0.0), PRICE_PANEL, face * PI / 2.0, 1.4)
	var body := StaticBody3D.new()
	body.name = "PriceSignBody"
	holder.add_child(body)
	for post_z in PRICE_POSTS_Z:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.2, PRICE_FROM, 0.2)
		shape.shape = box
		shape.position = Vector3(0.0, PRICE_FROM / 2.0, post_z)
		body.add_child(shape)


func _shops() -> void:
	var walls := [_textured(BRICK, 1.8, Color(0.85, 0.85, 0.85)),
		_textured(PLASTER, 2.0, Color(0.85, 0.8, 0.72)), _textured(PLASTER, 2.0,
		Color(0.7, 0.72, 0.74))]
	var shutter := _textured(SHUTTER, 1.0, Color(0.8, 0.8, 0.8))
	for index in range(SHOPS.size()):
		var plot := SHOPS[index]
		var ground := _height(plot.get_center().x, plot.get_center().y) + KERB
		var shop := _solid_box("Shop%d" % (index + 1), Vector3(plot.get_center().x, ground,
			plot.get_center().y), Vector3(plot.size.x - 0.05, SHOP_HIGH, plot.size.y),
			walls[index])
		var front := plot.position.y - 0.02
		var door := Build.box(shop, Vector3(0.0, SHUTTER_OPENING.y / 2.0 - SHOP_HIGH / 2.0,
			-plot.size.y / 2.0 - 0.02),
			Vector3(SHUTTER_OPENING.x, SHUTTER_OPENING.y, 0.04), shutter)
		door.name = "Shutter%d" % (index + 1)
		door.set_meta("covers", 1.0)
		Build.box(shop, Vector3(0.0, SHUTTER_OPENING.y + 0.2 - SHOP_HIGH / 2.0,
			-plot.size.y / 2.0 - 0.1),
			Vector3(SHUTTER_OPENING.x + 0.3, 0.4, 0.2), Build.material(Color(0.3, 0.3, 0.3), 0.5))
		_sign(self, SHOP_SIGNS[index], Vector3(plot.get_center().x, ground + SHOP_HIGH - 0.6,
			front - 0.01), Vector2(3.2, 0.8), PI, 0.0)
		var lamp := (load(DEPOT_MODELS % ["security_light", "security_light"]) as PackedScene) \
			.instantiate() as Node3D
		lamp.name = "SecurityLight%d" % (index + 1)
		add_child(lamp)
		lamp.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(plot.get_center().x
			+ SHUTTER_OPENING.x / 2.0 + 0.6, ground + 3.4, front - 0.02))
		var light := SpotLight3D.new()
		light.name = "ShopLight%d" % (index + 1)
		light.position = Vector3(SHUTTER_OPENING.x / 2.0 + 0.6, 3.3 - SHOP_HIGH / 2.0,
			-plot.size.y / 2.0 - 0.25)
		light.rotation_degrees.x = -70.0
		light.rotation_degrees.y = 180.0
		light.light_color = SECURITY_COLOUR
		light.light_energy = 6.0
		light.spot_range = 8.0
		light.spot_angle = 55.0
		light.shadow_enabled = false
		shop.add_child(light)


func _parking() -> void:
	var ground := _height(BAYS_FROM, SIDEWALK.position.y - BAY_DEEP / 2.0)
	var paint := Build.material(LINE_WHITE, 0.7)
	for line in range(8):
		Build.box(self, Vector3(BAYS_FROM + line * BAY, ground + 0.025, SIDEWALK.position.y
			- BAY_DEEP / 2.0), Vector3(0.1, 0.005, BAY_DEEP), paint)
	var models := [SEDAN, load(DEPOT_MODELS % ["covered_car", "covered_car"]) as PackedScene]
	for index in range(CARS.size()):
		var x := BAYS_FROM + (CARS[index] + 0.5) * BAY
		var z := SIDEWALK.position.y - BAY_DEEP / 2.0 - 0.1
		var car := (models[index] as PackedScene).instantiate() as Node3D
		car.name = "ParkedCar%d" % (index + 1)
		add_child(car)
		car.global_transform = Transform3D(Basis(Vector3.UP, PI if index == 0 else PI / 2.0),
			Vector3(x, ground + 0.02, z))
		var size := _extent(car)
		_body(car, "ParkedCar%dBody" % (index + 1), size["size"], size["centre"])


func _extent(model: Node3D) -> Dictionary:
	var low := Vector3.INF
	var high := -Vector3.INF
	var inverse := model.global_transform.affine_inverse()
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var box := inverse * mesh.global_transform * mesh.get_aabb()
		low = low.min(box.position)
		high = high.max(box.end)
	return {"size": high - low, "centre": (low + high) / 2.0}


func _solid_box(label: String, foot: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := Build.box(self, foot + Vector3.UP * size.y / 2.0, size, surface)
	mesh.name = label
	_body(mesh, label + "Body", size, Vector3.ZERO)
	return mesh


func _body(parent: Node3D, label: String, size: Vector3, centre: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = centre
	body.add_child(shape)
	parent.add_child(body)


func _cylinder_body(parent: Node3D, radius: float, tall: float) -> void:
	var body := StaticBody3D.new()
	body.name = String(parent.name) + "Body"
	var shape := CollisionShape3D.new()
	var round := CylinderShape3D.new()
	round.radius = radius
	round.height = tall
	shape.shape = round
	body.add_child(shape)
	parent.add_child(body)


func _sign(parent: Node3D, cell: String, at: Vector3, size: Vector2, yaw: float,
		glow: float = 0.0) -> MeshInstance3D:
	var index: int = CELLS[cell]
	var material := StandardMaterial3D.new()
	material.albedo_texture = SIGNS
	material.uv1_scale = Vector3(0.25, 0.25, 1.0)
	material.uv1_offset = Vector3((index % 4) * 0.25, (index / 4) * 0.25, 0.0)
	material.roughness = 0.6
	if glow > 0.0:
		material.emission_enabled = true
		material.emission_texture = SIGNS
		material.emission_energy_multiplier = glow
	var quad := QuadMesh.new()
	quad.size = size
	var mesh := Build.instance(parent, at, quad, material)
	mesh.rotation.y = yaw
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


func _textured(pattern: String, tile: float, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(pattern % "diff")
	material.albedo_color = tint
	if ResourceLoader.exists(pattern % "nor_gl"):
		material.normal_enabled = true
		material.normal_texture = load(pattern % "nor_gl")
	material.roughness = 0.85
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / tile
	return material
