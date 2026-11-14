extends Node3D
## The transfer shed's selective pallet racking (#267, docs/PHASE_BRIEF.md "step 5 brought
## forward", part A), as the author's photo of a warehouse aisle has it: teardrop racking of
## 20 ft frames 42 in deep and 96 in beams at 60, 120 and 180 in (`build_racking.py`), in six
## rows on the dock floor behind the cross-aisle, running at right angles to the dock face so
## that their aisles open onto it: one single row along the office's wall and five back to back
## with a 6 in flue, seven bays each, 0.3 m off the back wall, their aisles 12.5 ft between the
## loads' faces for a counterbalance forklift. Each row's end at the cross-aisle has its yellow
## guard, every post facing an aisle its protector, each aisle its numbered board on the post at
## its entrance, every beam facing an aisle its location labels. The stock as the photo's: on
## GMA 48 x 40 in pallets, two to a bay a level, 4 in clear of the posts and each other, set a
## little off true as forklifts leave them; wrapped cartons mostly on the floor, bundles of flat
## board mostly above, some places empty; the same every run (a seeded draw). And the fit-out
## round them that the photo shows: yellow 4 in lines down every aisle and a white walkway by the
## rail; long-span joists every 2.06 m across the 29.5 m span under a white liner
## (`build_shed_services.py`); white spiral ducts and red sprinkler mains with pendent heads
## above the racks; three linear LED high-bays down each aisle, between the joists. Each part is
## drawn as one multi-mesh; each row is one solid box.

const Parts := preload("res://features/environments/industrial_loop/art/racking/racking.glb")
const Services := preload(
	"res://features/environments/industrial_loop/art/racking/shed_services.glb")
const INCH := 0.0254
const FLOOR := 1.3
const FRAME_TALL := 240 * INCH
const FRAME_DEEP := 42 * INCH
const POST := 3 * INCH
const BEAM_CLEAR := 96 * INCH
const BAY := BEAM_CLEAR + POST
const BEAM_TALL := 4 * INCH
const DECK_STEP := 0.016
const LEVELS: Array[float] = [60 * INCH, 120 * INCH, 180 * INCH]
const FLUE := 6 * INCH
const OVERHANG := 3 * INCH
const AISLE := 150 * INCH
const BAYS := 7
const DOUBLES := 5
## The single row's west face, 0.15 m off the office's wall, and the first frames' middle, their
## base plates (4 in along the row) 0.3 m off the back wall.
const WEST := -81.85
const BASE_ALONG := 4 * INCH
const FIRST_Z := -9.75 + 0.3 + BASE_ALONG / 2.0
const END_GUARD_OUT := 0.0
const SIGN_HEIGHT := 2.4
const SIGN_OUT := 0.012
const LABEL_DOWN := 0.05
const LABEL_OUT := 0.001
## A frame, deck or spacer turned so that its depth (its own z) runs across the row (the
## world's x).
const ACROSS := Basis(Vector3.UP, PI / 2.0)
const PALLET_TALL := 0.146
const PALLET_WIDE := 40 * INCH
const SLOTS: Array[float] = [0.25, 0.75]
const SEED := 267
const OFF_TRUE := 0.01
const TURN_OFF := 1.0
## What each place holds, by its level: (load, share) drawn in turn; what is left is empty.
const FLOOR_STOCK: Array[Array] = [["CartonStack3", 0.55], ["BoardBundle090", 0.12],
	["CartonStack2", 0.1]]
const UPPER_STOCK: Array[Array] = [["BoardBundle110", 0.25], ["BoardBundle090", 0.25],
	["BoardBundle060", 0.12], ["CartonStack3", 0.1], ["CartonStack2", 0.08]]
const WRAPS := {"CartonStack3": "Wrap3", "CartonStack2": "Wrap2"}
const LINE_WIDE := 4 * INCH
const LINE_IN := 0.1
const PAINT_UP := 0.003
const YELLOW := Color(0.95, 0.75, 0.05)
const WHITE := Color(0.95, 0.95, 0.95)
const WALKWAY: Array[float] = [-46.6, -45.4]
const CROSS_LINE := 10.0
## The shed's shell (`transfer_building.gd`): its inner faces, its eaves and ridge, its pitch.
const SHED_X := Vector2(-89.75, -40.25)
const SHED_Z := Vector2(-9.75, 19.75)
const EAVES := 9.0
const RIDGE_Z := 5.0
const HALF_BUILDING := 15.0
const PITCH := deg_to_rad(5.0)
const LINER_DOWN := 0.02
const JOIST_FIRST := -87.781
const JOIST_STEP := 2.0625
const JOISTS := 24
const JOIST_DEEP := 1.25
const DUCT_ZS: Array[float] = [11.5, -3.0]
const DUCT := Vector3(-88.0, 0.3, 3.0)
const DUCT_RUNS := 15
const MAIN_ZS: Array[float] = [2.0, -6.5]
const MAIN := Vector3(-89.5, 0.0572, 120 * INCH)
const MAIN_RUNS := 16
const MAIN_DOWN := 0.2
const HEAD_DROP := 0.22
const AISLE_LIGHT_ZS: Array[float] = [-6.0, 0.0, 6.0]
const LIGHT_AT := 8.4
const LIGHT_COLOUR := Color(0.94, 0.97, 1.0)
const FIRST_AISLE_LIGHT := 6
## The aisle lights reach the floor, 7.1 m under their lenses, with a little to spare.
const LIGHT_REACH := 8.5
## Parts too small to see far off stop being drawn beyond these distances: under a pixel there at
## 1280 x 800 (a 0.1 m label at 25 m is about two pixels tall).
const SMALL_PARTS := {"Labels": 25.0, "Spacers": 30.0, "FixtureChains": 30.0,
	"DuctHangers": 30.0, "SprinklerHeads": 30.0}

var _meshes := {}
var _placed := {}
var _body: StaticBody3D


func build() -> void:
	var parts := Parts.instantiate() as Node3D
	for found in parts.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	parts.free()
	_body = StaticBody3D.new()
	_body.name = "RackBody"
	add_child(_body)
	var lines := frame_lines()
	var frames: Array[Transform3D] = []
	var beams: Array[Transform3D] = []
	var decks: Array[Transform3D] = []
	var guards: Array[Transform3D] = []
	var spacers: Array[Transform3D] = []
	var labels: Array[Array] = [[], [], [], []]
	var aisle_faces := _aisle_faces(lines)
	for x: float in lines:
		for k in range(BAYS + 1):
			var z := FIRST_Z + k * BAY
			frames.append(Transform3D(ACROSS, Vector3(x, FLOOR, z)))
			for side: float in [-1.0, 1.0]:
				if _faces_aisle(x + side * FRAME_DEEP / 2.0, aisle_faces):
					guards.append(Transform3D(Basis(Vector3.UP, PI / 2.0 * side), Vector3(
						x + side * (FRAME_DEEP / 2.0 - POST / 2.0), FLOOR, z)))
		for k in range(BAYS):
			var from := FIRST_Z + k * BAY + POST / 2.0
			for level in LEVELS:
				for side: float in [-1.0, 1.0]:
					var face := x + side * FRAME_DEEP / 2.0
					var turn := PI / 2.0 * side
					var start := from + BEAM_CLEAR if side > 0.0 else from
					beams.append(Transform3D(Basis(Vector3.UP, turn), Vector3(face,
						FLOOR + level - BEAM_TALL, start)))
					if _faces_aisle(face, aisle_faces):
						var variant := (k * 7 + LEVELS.find(level) * 3 + int(x * 10.0)) % 4
						labels[absi(variant)].append(Transform3D(Basis(Vector3.UP, turn),
							Vector3(face + side * LABEL_OUT, FLOOR + level - LABEL_DOWN,
							from + BEAM_CLEAR / 2.0)))
				for quarter: float in [0.25, 0.75]:
					decks.append(Transform3D(ACROSS, Vector3(x,
						FLOOR + level - DECK_STEP, from + BEAM_CLEAR * quarter)))
	for row in rows(lines):
		var span: Vector2 = row
		var middle := (span.x + span.y) / 2.0
		var last_z := FIRST_Z + BAYS * BAY + POST / 2.0
		_solid(Vector3(middle, FLOOR + FRAME_TALL / 2.0, (FIRST_Z - POST / 2.0 + last_z) / 2.0),
			Vector3(span.y - span.x + OVERHANG * 2.0, FRAME_TALL, last_z - FIRST_Z + POST))
		if span.y - span.x > FRAME_DEEP + 0.01:
			for k in range(BAYS + 1):
				for height: float in [FRAME_TALL * 0.4, FRAME_TALL * 0.8]:
					spacers.append(Transform3D(ACROSS, Vector3(middle, FLOOR + height,
						FIRST_Z + k * BAY)))
	_many("Frames", "RackFrame", frames)
	_many("Beams", "RackBeam", beams)
	_many("Decks", "RackDeck", decks)
	_many("PostGuards", "PostGuard", guards)
	_many("Spacers", "RowSpacer", spacers)
	for variant in range(4):
		var placed: Array[Transform3D] = []
		placed.assign(labels[variant])
		_many("Labels" + "ABCD"[variant], "BayLabel" + "ABCD"[variant], placed)
	_end_guards(lines)
	_signs(lines)
	_stock(lines)
	_floor_lines(lines)
	var services := Services.instantiate() as Node3D
	for found in services.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	services.free()
	_roof()
	_services()
	_aisle_lights(lines)


func _stock(lines: Array[float]) -> void:
	var draw := RandomNumberGenerator.new()
	draw.seed = SEED
	var pallets: Array[Transform3D] = []
	var loads := {}
	for x: float in lines:
		for k in range(BAYS):
			var from := FIRST_Z + k * BAY + POST / 2.0
			var heights: Array[float] = [0.0]
			heights.append_array(LEVELS)
			for level in heights:
				for slot in SLOTS:
					var load := _pick(draw, FLOOR_STOCK if level == 0.0 else UPPER_STOCK)
					var off := Vector3(draw.randf_range(-OFF_TRUE, OFF_TRUE), 0.0,
						draw.randf_range(-OFF_TRUE, OFF_TRUE))
					var turn := Basis(Vector3.UP, deg_to_rad(draw.randf_range(-TURN_OFF,
						TURN_OFF))) * ACROSS
					if load == "":
						continue
					var at := Vector3(x, FLOOR + level, from + BEAM_CLEAR * slot) + off
					pallets.append(Transform3D(turn, at))
					var on := Transform3D(turn, at + Vector3.UP * PALLET_TALL)
					for part in [load, WRAPS.get(load, "")]:
						if part != "":
							if not loads.has(part):
								loads[part] = [] as Array[Transform3D]
							(loads[part] as Array[Transform3D]).append(on)
	_many("Pallets", "RackPallet", pallets)
	for part: String in loads:
		_many(part, part, loads[part])


func _pick(draw: RandomNumberGenerator, stock: Array[Array]) -> String:
	var roll := draw.randf()
	for entry in stock:
		roll -= float(entry[1])
		if roll < 0.0:
			return String(entry[0])
	return ""


## The deck's underside over `z`: the eaves' height rising 5 degrees to the ridge.
static func underside(z: float) -> float:
	return EAVES + (HALF_BUILDING - absf(z - RIDGE_Z)) * tan(PITCH)


## The middle of every aisle, west to east: between the rows' loads, and by the rail.
static func aisle_middles(lines: Array[float]) -> Array[float]:
	var found := rows(lines)
	var middles: Array[float] = []
	for index in found.size():
		var east := found[index].y + OVERHANG
		var next := found[index + 1].x - OVERHANG if index + 1 < found.size() else -44.76
		middles.append((east + next) / 2.0)
	return middles


func _floor_lines(lines: Array[float]) -> void:
	var yellow := _paint(YELLOW, 0.6)
	var from := FIRST_Z - POST
	var to := CROSS_LINE - 0.05
	var count := 0
	var found := rows(lines)
	for index in found.size():
		var edges: Array[float] = [found[index].y + OVERHANG + LINE_IN]
		if index > 0:
			edges.push_front(found[index].x - OVERHANG - LINE_IN)
		for x in edges:
			count += 1
			_stripe("AisleLine%d" % count, x, from, to, yellow)
	var white := _paint(WHITE, 0.6)
	for index in WALKWAY.size():
		_stripe("WalkwayLine%d" % (index + 1), WALKWAY[index], from, to, white)


func _stripe(label: String, x: float, from: float, to: float, paint: Material) -> void:
	var line := MeshInstance3D.new()
	line.name = label
	var mesh := BoxMesh.new()
	mesh.size = Vector3(LINE_WIDE, PAINT_UP, to - from)
	line.mesh = mesh
	line.material_override = paint
	add_child(line)
	line.global_position = Vector3(x, FLOOR + PAINT_UP / 2.0, (from + to) / 2.0)


func _roof() -> void:
	var joists: Array[Transform3D] = []
	for index in JOISTS:
		joists.append(Transform3D(Basis.IDENTITY, Vector3(JOIST_FIRST + index * JOIST_STEP,
			EAVES, RIDGE_Z)))
	_many("Joists", "RoofJoist", joists)
	var liner := _paint(Color(0.9, 0.9, 0.88), 0.85)
	for side: float in [-1.0, 1.0]:
		var wall := SHED_Z.y if side > 0.0 else SHED_Z.x
		var run := absf(wall - RIDGE_Z)
		var sheet := MeshInstance3D.new()
		sheet.name = "RoofLiner" + ("South" if side > 0.0 else "North")
		var mesh := BoxMesh.new()
		mesh.size = Vector3(SHED_X.y - SHED_X.x, 0.01, run / cos(PITCH))
		sheet.mesh = mesh
		sheet.material_override = liner
		add_child(sheet)
		var middle := (wall + RIDGE_Z) / 2.0
		sheet.global_transform = Transform3D(Basis(Vector3.RIGHT, PITCH * side), Vector3(
			(SHED_X.x + SHED_X.y) / 2.0, underside(middle) - LINER_DOWN, middle))


func _services() -> void:
	var ducts: Array[Transform3D] = []
	var hangers: Array[Transform3D] = []
	for z in DUCT_ZS:
		var chord := underside(z) - JOIST_DEEP
		var centre := chord - 0.03 - DUCT.y
		for index in DUCT_RUNS:
			ducts.append(Transform3D(Basis.IDENTITY, Vector3(DUCT.x + index * DUCT.z, centre, z)))
		for index in JOISTS:
			var x := JOIST_FIRST + index * JOIST_STEP
			if x > DUCT.x and x < DUCT.x + DUCT_RUNS * DUCT.z:
				var top := centre + DUCT.y
				hangers.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, chord - top, 1.0)),
					Vector3(x, top, z)))
	_many("Ducts", "DuctRun", ducts)
	_many("DuctHangers", "DuctHanger", hangers)
	var mains: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	for z in MAIN_ZS:
		var centre := underside(z) - MAIN_DOWN
		for index in MAIN_RUNS:
			var x := MAIN.x + index * MAIN.z
			mains.append(Transform3D(Basis.IDENTITY, Vector3(x, centre, z)))
			heads.append(Transform3D(Basis.IDENTITY, Vector3(x + MAIN.z / 2.0,
				centre - MAIN.y - HEAD_DROP, z)))
	_many("SprinklerMains", "SprinklerMain", mains)
	_many("SprinklerHeads", "SprinklerHead", heads)


func _aisle_lights(lines: Array[float]) -> void:
	var fixtures: Array[Transform3D] = []
	var chains: Array[Transform3D] = []
	var count := FIRST_AISLE_LIGHT
	for x in aisle_middles(lines):
		for z in AISLE_LIGHT_ZS:
			var at := Vector3(x, LIGHT_AT, z)
			fixtures.append(Transform3D(Basis.IDENTITY, at))
			var hang := underside(z) - (LIGHT_AT + 0.08)
			for end: float in [-0.5, 0.5]:
				chains.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, hang, 1.0)),
					at + Vector3(0.0, 0.08, end)))
			var light := SpotLight3D.new()
			light.name = "BayLight%d" % count
			count += 1
			add_child(light)
			light.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0),
				at - Vector3(0.0, 0.02, 0.0))
			light.light_color = LIGHT_COLOUR
			light.light_energy = 4.5
			light.spot_angle = 60.0
			light.spot_range = LIGHT_REACH
			light.shadow_enabled = false
	var lens := StandardMaterial3D.new()
	lens.albedo_color = LIGHT_COLOUR
	lens.emission_enabled = true
	lens.emission = LIGHT_COLOUR
	lens.emission_energy_multiplier = 3.0
	var mesh := (_meshes["LinearHighBay"] as Mesh).duplicate() as ArrayMesh
	if mesh != null and mesh.get_surface_count() > 1:
		mesh.surface_set_material(1, lens)
		_meshes["LinearHighBay"] = mesh
	_many("AisleFixtures", "LinearHighBay", fixtures)
	_many("FixtureChains", "FixtureChain", chains)


func _paint(colour: Color, roughness: float) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = roughness
	return paint


## The x of every frame line, west to east: the single row, then each back-to-back pair.
static func frame_lines() -> Array[float]:
	var lines: Array[float] = [WEST + FRAME_DEEP / 2.0]
	var face := WEST + FRAME_DEEP + OVERHANG + AISLE + OVERHANG
	for row in range(DOUBLES):
		lines.append(face + FRAME_DEEP / 2.0)
		lines.append(face + FRAME_DEEP + FLUE + FRAME_DEEP / 2.0)
		face += FRAME_DEEP * 2.0 + FLUE + OVERHANG + AISLE + OVERHANG
	return lines


## Each row's west and east frame faces.
static func rows(lines: Array[float]) -> Array[Vector2]:
	var found: Array[Vector2] = [Vector2(lines[0] - FRAME_DEEP / 2.0, lines[0] + FRAME_DEEP / 2.0)]
	for index in range(1, lines.size(), 2):
		found.append(Vector2(lines[index] - FRAME_DEEP / 2.0, lines[index + 1] + FRAME_DEEP / 2.0))
	return found


## The faces that look onto an aisle: every row's east face, and every west face but the single
## row's, which stands against the office's wall.
func _aisle_faces(lines: Array[float]) -> Array[float]:
	var faces: Array[float] = []
	var found := rows(lines)
	for index in found.size():
		if index > 0:
			faces.append(found[index].x)
		faces.append(found[index].y)
	return faces


func _faces_aisle(face: float, faces: Array[float]) -> bool:
	for each in faces:
		if absf(each - face) < 0.001:
			return true
	return false


func _end_guards(lines: Array[float]) -> void:
	var doubles: Array[Transform3D] = []
	var end_z := FIRST_Z + BAYS * BAY + POST / 2.0 + END_GUARD_OUT
	for row in rows(lines):
		var at := Transform3D(Basis.IDENTITY, Vector3((row.x + row.y) / 2.0, FLOOR, end_z))
		if row.y - row.x > FRAME_DEEP + 0.01:
			doubles.append(at)
		else:
			var single := MeshInstance3D.new()
			single.name = "EndGuardSingle"
			single.mesh = _meshes["RowEndGuardSingle"]
			add_child(single)
			single.global_transform = at
	_many("EndGuards", "RowEndGuardDouble", doubles)


func _signs(lines: Array[float]) -> void:
	var found := rows(lines)
	var end_z := FIRST_Z + BAYS * BAY + POST / 2.0
	for index in found.size():
		var sign := MeshInstance3D.new()
		sign.name = "AisleSign%02d" % (index + 1)
		sign.mesh = _meshes[String(sign.name)]
		add_child(sign)
		var post_x := found[index].y - POST / 2.0
		sign.global_transform = Transform3D(Basis.IDENTITY, Vector3(post_x, FLOOR + SIGN_HEIGHT,
			end_z + SIGN_OUT))


## Where the instances of the multi-mesh `label` stand, in the shed's frame: what it was given
## (a headless run's renderer keeps no instance transforms to read back).
func placements(label: String) -> Array[Transform3D]:
	var found: Array[Transform3D] = []
	found.assign(_placed.get(label, []))
	return found


func _many(label: String, part: String, placed: Array[Transform3D]) -> void:
	_placed[label] = placed.duplicate()
	var node := MultiMeshInstance3D.new()
	node.name = label
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _meshes[part]
	multimesh.instance_count = placed.size()
	for index in placed.size():
		multimesh.set_instance_transform(index, placed[index])
	node.multimesh = multimesh
	for prefix: String in SMALL_PARTS:
		if label.begins_with(prefix):
			node.visibility_range_end = SMALL_PARTS[prefix]
	add_child(node)


func _solid(at: Vector3, size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = at
	_body.add_child(shape)
