extends Node3D
## The waterfront (Mission 3's step 3, part A, docs/PHASE_BRIEF.md, 2026-11-21, #359-#360): a small
## container terminal on the harbour flats, after Commons photos of Dublin's South Quays at night
## and a Liebherr mobile harbour crane. From the coastal road an access road runs east to its gate,
## which stands open beside a lit gatehouse; a chain-link fence (`chain_link_fence.gd`) closes it
## but on the quay. Inside on its slab, four blocks of containers stacked two to four high (the
## container yard's own boxes, `container_yard.gd`'s `stack`) leave a lane from the gate to the
## quay; the mobile harbour crane (TGVMisterH's "Harbor crane", CC BY 4.0) stands on the apron by
## berth 2, its boom out over the water; four 30 m high masts light it in warm sodium-coloured
## flood, rain falling in it; cast-iron mooring bollards line the quay's edge and rubber fenders
## hang on its wall; berth 2 is painted at the quay's edge, where the dispatcher sends the van.

const Build = preload("res://shared/components/mesh_builder.gd")
const Fence = preload("res://features/environments/industrial_loop/chain_link_fence.gd")
const CRANE = preload("art/harbour_crane/harbour_crane.glb")
const TERMINAL := Rect2(840.0, 160.0, 160.0, 150.0)
const QUAY_X := 1000.0
const SLAB_TOP := -0.1
const GATE := Vector3(840.0, 0.0, 200.0)
const GATE_WIDE := 7.0
const ACCESS: Array[Vector3] = [Vector3(726.0, 0.0, 200.0), Vector3(840.0, 0.0, 200.0)]
const GATEHOUSE := Vector3(835.5, 0.0, 192.5)
const GATEHOUSE_SIZE := Vector3(2.6, 2.6, 2.4)
## Berth 2: the bay the van stops in, parallel to the quay's edge, and its painted name.
const BERTH := Vector3(992.0, 0.0, 232.0)
const BERTH_SIZE := Vector2(3.4, 8.0)
## The container blocks: each three boxes long along x and ROWS deep along z from its corner.
const BLOCKS: Array[Vector2] = [Vector2(860.0, 172.0), Vector2(915.0, 172.0),
	Vector2(860.0, 268.0), Vector2(915.0, 268.0)]
const ROWS := 7
const ROW_PITCH := 2.84
const BOX_GAP := 0.3
const CRANE_AT := Vector3(982.0, 0.0, 262.0)
const CRANE_BASE := Vector3(9.0, 3.0, 9.0)
const MASTS: Array[Vector3] = [Vector3(868.0, 0.0, 230.0), Vector3(930.0, 0.0, 230.0),
	Vector3(985.0, 0.0, 180.0), Vector3(985.0, 0.0, 290.0)]
const MAST_TALL := 30.0
const SODIUM := Color(1.0, 0.72, 0.4)
const MAST_ENERGY := 45.0
const MAST_REACH := 85.0
const MAST_FLOODS := 3
## Where the masts' rain shows: the high-flood rain (`lamp_rain_flood_high.tscn`) falls from about
## 9 m, so it fills the lower part of each beam, where a man on the slab sees rain lit.
const RAIN_FROM := 9.0
const BOLLARD_EVERY := 15.0
const SEA_LEVEL := -2.6

var gate := GATE
var berth := BERTH
var fence_runs: Array = []
var stacks: Array = []
var crane: Node3D
## Where the crane's base stands on the apron.
var crane_base := CRANE_AT
var masts: Array[Node3D] = []
var bollards: Array[Node3D] = []
var fenders: Array[Node3D] = []
var terminal := TERMINAL
var _body: StaticBody3D


## Builds it: `slab` the yards' paving, `asphalt` the roads', `concrete` and `metal` its fittings,
## `yard` the container yard (for its boxes), `rain` the world's lamp rain, `lamp_post` the valley
## road's lamp (`(at, heading) -> Node3D`).
func build(slab: Material, asphalt: Material, concrete: Material, metal: Material, yard: Node3D,
		rain: Node, lamp_post: Callable) -> void:
	_body = StaticBody3D.new()
	_body.name = "WaterfrontBody"
	add_child(_body)
	_paving(slab)
	_access(asphalt, lamp_post)
	_fence()
	_gatehouse(concrete, metal)
	_containers(yard)
	_crane()
	_masts(metal, rain)
	_quay_edge(metal)
	_berth()


func inside(at: Vector3) -> bool:
	return TERMINAL.has_point(Vector2(at.x, at.z))


func _paving(slab: Material) -> void:
	var plane := PlaneMesh.new()
	plane.size = TERMINAL.size
	var paving := Build.instance(self, Vector3(TERMINAL.get_center().x, SLAB_TOP,
		TERMINAL.get_center().y), plane, slab)
	paving.name = "Slab"


func _access(asphalt: Material, lamp_post: Callable) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := ACCESS[0]
	var b := ACCESS[1]
	var right := (b - a).normalized().cross(Vector3.UP)
	var half := 3.3
	var corners := [a - right * half, b - right * half, a + right * half, b + right * half]
	var across := [0.0, 0.0, 1.0, 1.0]
	for index in [0, 1, 2, 2, 1, 3]:
		tool.set_color(Color(across[index], half / 8.0, 0.0))
		tool.set_normal(Vector3.UP)
		var at: Vector3 = corners[index]
		tool.set_uv(Vector2(at.x, at.z))
		tool.add_vertex(at + Vector3.UP * 0.005)
	var road := MeshInstance3D.new()
	road.name = "AccessRoad"
	road.mesh = tool.commit()
	road.material_override = asphalt
	add_child(road)
	for x in [766.0, 806.0]:
		lamp_post.call(Vector3(x, 0.0, ACCESS[0].z - half - 1.6), 0.0)


func _fence() -> void:
	var fence := Fence.new()
	var west := TERMINAL.position.x
	var south := TERMINAL.position.y
	var north := TERMINAL.end.y
	var pieces := [
		[Vector2(QUAY_X - 2.0, south), Vector2(west, south), Vector3.FORWARD],
		[Vector2(west, south), Vector2(west, GATE.z - GATE_WIDE / 2.0), Vector3.LEFT],
		[Vector2(west, GATE.z + GATE_WIDE / 2.0), Vector2(west, north), Vector3.LEFT],
		[Vector2(west, north), Vector2(QUAY_X - 2.0, north), Vector3.BACK],
	]
	for piece: Array in pieces:
		var a: Vector2 = piece[0]
		var b: Vector2 = piece[1]
		fence.run(self, _body, Vector3(a.x, SLAB_TOP, a.y), Vector3(b.x, SLAB_TOP, b.y), piece[2])
		fence_runs.append({"from": a, "to": b})
	var leaf := Build.box(self, Vector3(west - 0.35, 1.2, GATE.z + GATE_WIDE / 2.0 + 3.6),
		Vector3(0.08, 2.2, GATE_WIDE), fence.galvanised)
	leaf.name = "GateLeafOpen"


func _gatehouse(concrete: Material, metal: Material) -> void:
	var cladding := Build.material(Color(0.32, 0.34, 0.33), 0.7)
	var walls := Build.box(self, GATEHOUSE + Vector3.UP * GATEHOUSE_SIZE.y / 2.0, GATEHOUSE_SIZE,
		cladding)
	walls.name = "Gatehouse"
	Build.box(self, GATEHOUSE + Vector3.UP * (GATEHOUSE_SIZE.y + 0.08),
		GATEHOUSE_SIZE + Vector3(0.5, 0.16 - GATEHOUSE_SIZE.y, 0.5), metal).name = "GatehouseRoof"
	var window := StandardMaterial3D.new()
	window.albedo_color = Color(0.2, 0.18, 0.14)
	window.emission_enabled = true
	window.emission = Color(1.0, 0.86, 0.6)
	window.emission_energy_multiplier = 1.2
	Build.box(self, GATEHOUSE + Vector3(GATEHOUSE_SIZE.x / 2.0 + 0.01, 1.55, 0.0),
		Vector3(0.02, 0.9, 1.4), window).name = "GatehouseWindow"
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.6)
	lamp.light_energy = 0.35
	lamp.omni_range = 4.0
	add_child(lamp)
	lamp.position = GATEHOUSE + Vector3(GATEHOUSE_SIZE.x / 2.0 + 1.0, 1.8, 0.0)
	var shape := BoxShape3D.new()
	shape.size = GATEHOUSE_SIZE
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = GATEHOUSE + Vector3.UP * GATEHOUSE_SIZE.y / 2.0
	_body.add_child(collision)


func _containers(yard: Node3D) -> void:
	var draw := RandomNumberGenerator.new()
	draw.seed = 35903
	for corner in BLOCKS:
		for row in range(ROWS):
			var z := corner.y + row * ROW_PITCH
			var x := corner.x
			for slot in range(3):
				var kind := "Container40HC" if draw.randf() < 0.3 else "Container40"
				var length := 12.192
				var high := draw.randi_range(2, 4)
				stacks.append([kind, Transform3D(Basis.IDENTITY, Vector3(x + length / 2.0, SLAB_TOP,
					z)), high])
				x += length + BOX_GAP
	yard.call("stack", self, _body, stacks, 35903)


func _crane() -> void:
	crane = CRANE.instantiate() as Node3D
	crane.name = "HarbourCrane"
	add_child(crane)
	crane.rotation.y = PI / 2.0
	crane.position = Vector3.UP * SLAB_TOP
	var house := _part(crane, "Crane_Installations_Mat")
	var middle := house.get_center() if house.size != Vector3.ZERO else Vector3.ZERO
	crane.position += Vector3(CRANE_AT.x - middle.x, 0.0, CRANE_AT.z - middle.z)
	var shape := BoxShape3D.new()
	shape.size = CRANE_BASE
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = CRANE_AT + Vector3.UP * CRANE_BASE.y / 2.0
	_body.add_child(collision)
	for height in [36.0, 20.0]:
		var warning := OmniLight3D.new()
		warning.light_color = Color(1.0, 0.1, 0.05)
		warning.light_energy = 1.2
		warning.omni_range = 4.0
		add_child(warning)
		warning.position = CRANE_AT + Vector3(0.0, height, 0.0)


## The world box of the crane's part painted with `material` (its machinery house), to stand it by.
func _part(model: Node3D, material: String) -> AABB:
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		for index in range(mesh.mesh.get_surface_count()):
			var made := mesh.mesh.surface_get_material(index)
			if made != null and made.resource_name == material:
				return mesh.global_transform * mesh.get_aabb()
	return AABB()


## A high mast as ports use: a tapered galvanised pole and at its top a ring of floods.
func _masts(metal: Material, rain: Node) -> void:
	for index in range(MASTS.size()):
		var at := MASTS[index]
		var mast := Node3D.new()
		mast.name = "HighMast%d" % (index + 1)
		add_child(mast)
		mast.position = at
		var pole := MeshInstance3D.new()
		var taper := CylinderMesh.new()
		taper.top_radius = 0.16
		taper.bottom_radius = 0.38
		taper.height = MAST_TALL
		pole.mesh = taper
		pole.material_override = metal
		pole.position = Vector3.UP * MAST_TALL / 2.0
		mast.add_child(pole)
		var ring := MeshInstance3D.new()
		var crown := CylinderMesh.new()
		crown.top_radius = 1.2
		crown.bottom_radius = 1.2
		crown.height = 0.5
		ring.mesh = crown
		ring.material_override = metal
		ring.position = Vector3.UP * MAST_TALL
		mast.add_child(ring)
		for turn in range(MAST_FLOODS):
			var light := SpotLight3D.new()
			light.light_color = SODIUM
			light.light_energy = MAST_ENERGY
			light.spot_range = MAST_REACH
			light.spot_angle = 68.0
			light.spot_attenuation = 1.2
			light.shadow_enabled = index == 0 and turn == 0
			mast.add_child(light)
			light.position = Vector3(0.0, MAST_TALL - 0.4, 0.0)
			var heading := TAU * turn / MAST_FLOODS + index
			var aim := Vector3(cos(heading), 0.0, sin(heading)) * 16.0
			light.look_at(mast.global_position + aim, Vector3.UP)
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.8, 3.0, 0.8)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = at + Vector3.UP * 1.5
		_body.add_child(collision)
		masts.append(mast)
		rain.call("add_volume", rain.get_script().get_script_constant_map()["FLOOD_HIGH"],
			Transform3D(Basis.IDENTITY, at + Vector3(0.0, RAIN_FROM, 0.0)))


## Cast-iron mooring bollards along the quay's edge every BOLLARD_EVERY, and rubber cylinder
## fenders hung on its wall between them.
func _quay_edge(metal: Material) -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.05, 0.05, 0.055)
	iron.roughness = 0.6
	iron.metallic = 0.4
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.03, 0.03, 0.03)
	rubber.roughness = 0.85
	var z := TERMINAL.position.y + 6.0
	while z < TERMINAL.end.y - 4.0:
		var post := Node3D.new()
		post.name = "Bollard"
		add_child(post)
		post.position = Vector3(QUAY_X - 0.9, SLAB_TOP, z)
		Build.cylinder(post, Vector3.UP * 0.3, 0.17, 0.6, iron)
		Build.cylinder(post, Vector3.UP * 0.62, 0.24, 0.08, iron)
		bollards.append(post)
		var shape := CylinderShape3D.new()
		shape.radius = 0.24
		shape.height = 0.7
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = post.position + Vector3.UP * 0.35
		_body.add_child(collision)
		var fender := MeshInstance3D.new()
		var roll := CylinderMesh.new()
		roll.top_radius = 0.3
		roll.bottom_radius = 0.3
		roll.height = 1.8
		fender.mesh = roll
		fender.material_override = rubber
		fender.name = "Fender"
		add_child(fender)
		fender.position = Vector3(QUAY_X + 0.6, SLAB_TOP - 1.3, z + BOLLARD_EVERY / 2.0)
		fenders.append(fender)
		z += BOLLARD_EVERY


func _berth() -> void:
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(0.85, 0.68, 0.1)
	yellow.roughness = 0.7
	var half := BERTH_SIZE / 2.0
	for side in [[Vector3(-half.x, 0.0, 0.0), Vector3(0.12, 0.01, BERTH_SIZE.y)],
			[Vector3(half.x, 0.0, 0.0), Vector3(0.12, 0.01, BERTH_SIZE.y)],
			[Vector3(0.0, 0.0, -half.y), Vector3(BERTH_SIZE.x, 0.01, 0.12)],
			[Vector3(0.0, 0.0, half.y), Vector3(BERTH_SIZE.x, 0.01, 0.12)]]:
		Build.box(self, BERTH + side[0] + Vector3.UP * (SLAB_TOP + 0.01), side[1], yellow).name = \
			"BerthLine"
	var name_plate := Label3D.new()
	name_plate.name = "BerthName"
	name_plate.text = "BERTH 2"
	name_plate.font_size = 220
	name_plate.pixel_size = 0.004
	name_plate.modulate = Color(0.85, 0.68, 0.1)
	name_plate.shaded = true
	name_plate.double_sided = false
	add_child(name_plate)
	name_plate.position = BERTH + Vector3(-half.x - 1.6, SLAB_TOP + 0.015, 0.0)
	name_plate.rotation = Vector3(-PI / 2.0, PI / 2.0, 0.0)
