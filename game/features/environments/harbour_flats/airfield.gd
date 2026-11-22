extends Node3D
## The airfield (Mission 3's step 5, part A, docs/PHASE_BRIEF.md, 2026-11-21, #359-#360), after
## Commons photos of William R. Fairchild airport at Port Angeles: on the harbour flats north of the
## waterfront, a general-aviation strip and its hangar. The runway (09/27) runs east-west, 18 m
## wide, white edge lights every 60 m along both sides (inset points, as seen at night) and green
## threshold bars at both ends; a windsock beside it. A taxiway joins it to the apron, where the
## PC-12 waits (helijah's "Pilatus PC 12/47", CC BY 4.0, repainted white as a private charter's; its
## airstair down, its beacon flashing red as before a start). The hangar is a steel portal frame
## clad in ribbed metal, its sliding door's leaves stacked aside to leave an opening wider than a
## PC-12's wings, high-bay lights inside and a small office in its back corner with a lit window. A
## chain-link fence with barbed wire (`chain_link_fence.gd`) closes it, with a keypad gate off the
## coastal road and a service gate on its south side; an access road runs from the coastal road to
## the gate.

const Build = preload("res://shared/components/mesh_builder.gd")
const Fence = preload("res://features/environments/industrial_loop/chain_link_fence.gd")
const SlidingGate = preload("res://features/environments/industrial_loop/sliding_gate.gd")
const PLANE = preload("art/pc12/pc12.glb")
const AREA := Rect2(760.0, -295.0, 530.0, 215.0)
const TOP := -0.1
const RUNWAY_FROM := Vector3(775.0, 0.0, -250.0)
const RUNWAY_TO := Vector3(1280.0, 0.0, -250.0)
const RUNWAY_WIDTH := 18.0
const EDGE_EVERY := 60.0
const APRON := Rect2(905.0, -178.0, 110.0, 48.0)
const TAXIWAY: Array[Vector3] = [Vector3(940.0, 0.0, -178.0), Vector3(940.0, 0.0, -241.0)]
const TAXI_WIDTH := 10.5
const HANGAR_AT := Vector3(960.0, 0.0, -112.0)
const HANGAR_SIZE := Vector3(32.0, 8.0, 26.0)
const RIDGE := 1.8
const DOOR_OPENING := Vector2(22.0, 6.8)
const BAY := 6.5
const OFFICE_SIZE := Vector3(6.0, 3.0, 4.5)
const PLANE_AT := Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(960.0, 0.0, -155.0))
const GATE := Vector3(760.0, 0.0, -150.0)
const GATE_WIDE := 7.0
const SERVICE_GATE := Vector3(990.0, 0.0, -80.0)
const SERVICE_WIDE := 5.0
## The gates' counterweight tail and travel, as the compound's (`compound.gd`).
const GATE_TAIL := 3.0
const GATE_SPEED := 0.6
const WINDSOCK := Vector3(1060.0, 0.0, -274.0)
const WHITE := Color(1.0, 0.95, 0.85)
const GREEN := Color(0.2, 1.0, 0.45)

var runway_from := RUNWAY_FROM
var runway_to := RUNWAY_TO
var runway_width := RUNWAY_WIDTH
var edge_lights: Array[Node3D] = []
var threshold_lights: Array[Node3D] = []
var runway_numbers: Array[String] = []
var windsock: Node3D
var apron := APRON
var taxiway := TAXIWAY
var door_opening := DOOR_OPENING
var hangar_at := HANGAR_AT
var hangar_size := HANGAR_SIZE
var hangar_lights: Array[Node3D] = []
var office: Node3D
var plane: Node3D
var fence_runs: Array = []
var gate := GATE
var service_gate := SERVICE_GATE
var keypad: Node3D
var _body: StaticBody3D
var _gates := {}
## The freight track from the coastal road along the flats to the service gate (step 5).
const TRACK: Array[Vector3] = [Vector3(726.0, 0.0, -40.0), Vector3(990.0, 0.0, -40.0),
	Vector3(990.0, 0.0, -78.0)]
var _beacon: OmniLight3D
var _clock := 0.0


## Builds it: `asphalt` the roads', `slab` the hangar's floor, `cladding` its walls, `metal` its
## frame and fittings, `concrete` the kerbs; `lamp_post` the valley road's lamp.
func build(asphalt: Material, slab: Material, cladding: Material, metal: Material,
		concrete: Material, lamp_post: Callable) -> void:
	_body = StaticBody3D.new()
	_body.name = "AirfieldBody"
	add_child(_body)
	_runway(asphalt)
	_apron_and_taxiway(asphalt)
	_windsock(metal)
	_hangar(slab, cladding, metal)
	_office(cladding)
	_plane()
	_fence(concrete, metal)
	_access(asphalt, lamp_post)


func inside(at: Vector3) -> bool:
	return AREA.has_point(Vector2(at.x, at.z))


func _strip(from: Vector3, to: Vector3, width: float, surface: Material, label: String) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var right := (to - from).normalized().cross(Vector3.UP) * width / 2.0
	var corners := [from - right, to - right, from + right, to + right]
	for index in [0, 1, 2, 2, 1, 3]:
		var at: Vector3 = corners[index]
		tool.set_color(Color(0.5, 0.0, 0.0))
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(at.x, at.z))
		tool.add_vertex(at + Vector3.UP * (TOP + 0.11))
	var strip := MeshInstance3D.new()
	strip.name = label
	strip.mesh = tool.commit()
	strip.material_override = surface
	add_child(strip)


func _runway(asphalt: Material) -> void:
	_strip(RUNWAY_FROM, RUNWAY_TO, RUNWAY_WIDTH, asphalt, "Runway")
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.86, 0.86, 0.84)
	paint.roughness = 0.75
	var along := (RUNWAY_TO - RUNWAY_FROM).normalized()
	var length := RUNWAY_FROM.distance_to(RUNWAY_TO)
	var dash := 0.0
	while dash < length - 60.0:
		var at := RUNWAY_FROM + along * (40.0 + dash)
		Build.box(self, at + Vector3.UP * (TOP + 0.12), Vector3(30.0, 0.01, 0.9), paint).name = \
			"CentreLine"
		dash += 50.0
	for end: Array in [[RUNWAY_FROM + along * 22.0, "09", -PI / 2.0],
			[RUNWAY_TO - along * 22.0, "27", PI / 2.0]]:
		var label := Label3D.new()
		label.name = "RunwayNumber" + String(end[1])
		label.text = end[1]
		label.font_size = 512
		label.pixel_size = 0.02
		label.modulate = Color(0.86, 0.86, 0.84)
		label.shaded = true
		add_child(label)
		label.position = (end[0] as Vector3) + Vector3.UP * (TOP + 0.125)
		label.rotation = Vector3(-PI / 2.0, float(end[2]), 0.0)
		runway_numbers.append(String(end[1]))
	var side := along.cross(Vector3.UP) * (RUNWAY_WIDTH / 2.0 + 1.0)
	var steps := ceili(length / EDGE_EVERY)
	for step in range(steps + 1):
		var at := RUNWAY_FROM + along * (length * step / steps)
		for sign in [-1.0, 1.0]:
			edge_lights.append(_inset(at + side * sign, WHITE, "EdgeLight"))
	for end in [RUNWAY_FROM, RUNWAY_TO]:
		for offset in [-6.0, -2.0, 2.0, 6.0]:
			threshold_lights.append(_inset(end + along.cross(Vector3.UP) * offset, GREEN,
				"ThresholdLight"))


## A runway light as seen at night: a small fitting with a bright glowing lens, no light cast.
func _inset(at: Vector3, colour: Color, label: String) -> Node3D:
	var fitting := Node3D.new()
	fitting.name = label
	add_child(fitting)
	fitting.position = at + Vector3.UP * TOP
	var lens := StandardMaterial3D.new()
	lens.albedo_color = colour
	lens.emission_enabled = true
	lens.emission = colour
	lens.emission_energy_multiplier = 6.0
	Build.cylinder(fitting, Vector3.UP * 0.2, 0.08, 0.4, lens)
	return fitting


func _apron_and_taxiway(asphalt: Material) -> void:
	var middle := APRON.get_center()
	_strip(Vector3(APRON.position.x, 0.0, middle.y), Vector3(APRON.end.x, 0.0, middle.y),
		APRON.size.y, asphalt, "Apron")
	_strip(TAXIWAY[0], TAXIWAY[1], TAXI_WIDTH, asphalt, "Taxiway")
	_strip(Vector3(HANGAR_AT.x, 0.0, APRON.end.y), Vector3(HANGAR_AT.x, 0.0, HANGAR_AT.z
		- HANGAR_SIZE.z / 2.0), DOOR_OPENING.x, asphalt, "HangarFront")


func _windsock(metal: Material) -> void:
	windsock = Node3D.new()
	windsock.name = "Windsock"
	add_child(windsock)
	windsock.position = WINDSOCK
	Build.cylinder(windsock, Vector3.UP * 3.0, 0.06, 6.0, metal)
	var sock := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.45
	cone.bottom_radius = 0.18
	cone.height = 3.6
	sock.mesh = cone
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(0.95, 0.38, 0.08)
	orange.roughness = 0.85
	sock.material_override = orange
	sock.rotation = Vector3(0.0, 0.0, -PI / 2.0 + 0.25)
	sock.position = Vector3(1.75, 5.6, 0.0)
	windsock.add_child(sock)
	var lamp := OmniLight3D.new()
	lamp.light_color = WHITE
	lamp.light_energy = 0.5
	lamp.omni_range = 5.0
	windsock.add_child(lamp)
	lamp.position = Vector3(0.0, 6.3, 0.0)


## A steel portal-frame hangar: floor, ribbed walls, a pitched roof on frames every BAY, the front's
## header over the door opening, the sliding door's leaves stacked aside, high-bay lights.
func _hangar(slab: Material, cladding: Material, metal: Material) -> void:
	var c := HANGAR_AT
	var half := HANGAR_SIZE / 2.0
	Build.box(self, c + Vector3(0.0, TOP + 0.05, 0.0), Vector3(HANGAR_SIZE.x, 0.1,
		HANGAR_SIZE.z), slab).name = "HangarFloor"
	_wall(c + Vector3(0.0, half.y, half.z), Vector3(HANGAR_SIZE.x, HANGAR_SIZE.y, 0.25), cladding)
	_wall(c + Vector3(-half.x, half.y, 0.0), Vector3(0.25, HANGAR_SIZE.y, HANGAR_SIZE.z), cladding)
	_wall(c + Vector3(half.x, half.y, 0.0), Vector3(0.25, HANGAR_SIZE.y, HANGAR_SIZE.z), cladding)
	var front := c.z - half.z
	var header := HANGAR_SIZE.y - DOOR_OPENING.y
	_wall(Vector3(c.x, DOOR_OPENING.y + header / 2.0, front), Vector3(HANGAR_SIZE.x, header, 0.25),
		cladding)
	var post := (HANGAR_SIZE.x - DOOR_OPENING.x) / 2.0
	for side in [-1.0, 1.0]:
		_wall(Vector3(c.x + side * (DOOR_OPENING.x + post) / 2.0, DOOR_OPENING.y / 2.0, front),
			Vector3(post, DOOR_OPENING.y, 0.25), cladding)
		for leaf in range(2):
			Build.box(self, Vector3(c.x + side * (DOOR_OPENING.x / 2.0 + post / 2.0),
				DOOR_OPENING.y / 2.0, front - 0.35 - leaf * 0.25), Vector3(post - 0.2,
				DOOR_OPENING.y - 0.1, 0.12), cladding).name = "DoorLeaf"
	var slope := atan2(RIDGE, half.x)
	var run := sqrt(half.x * half.x + RIDGE * RIDGE)
	for side in [-1.0, 1.0]:
		var roof := Build.box(self, c + Vector3(side * half.x / 2.0, HANGAR_SIZE.y + RIDGE / 2.0,
			0.0), Vector3(run, 0.15, HANGAR_SIZE.z + 0.6), cladding)
		roof.rotation.z = -side * slope
		roof.name = "Roof"
	var frames := int(HANGAR_SIZE.z / BAY)
	for index in range(frames + 1):
		var z := c.z - half.z + HANGAR_SIZE.z * index / frames
		for side in [-1.0, 1.0]:
			Build.box(self, Vector3(c.x + side * (half.x - 0.35), HANGAR_SIZE.y / 2.0, z),
				Vector3(0.3, HANGAR_SIZE.y, 0.45), metal).name = "Column"
			var rafter := Build.box(self, Vector3(c.x + side * half.x / 2.0, HANGAR_SIZE.y
				+ RIDGE / 2.0 - 0.45, z), Vector3(run, 0.55, 0.25), metal)
			rafter.rotation.z = -side * slope
			rafter.name = "Rafter"
	for row in [-1.0, 1.0]:
		for column in [-1.0, 0.0, 1.0]:
			var lamp := SpotLight3D.new()
			lamp.name = "HighBay"
			lamp.light_color = Color(0.92, 0.95, 1.0)
			lamp.light_energy = 12.0
			lamp.spot_range = 16.0
			lamp.spot_angle = 60.0
			add_child(lamp)
			lamp.position = c + Vector3(column * 9.0, HANGAR_SIZE.y + 0.4, row * 6.0)
			lamp.rotation.x = -PI / 2.0
			hangar_lights.append(lamp)


func _wall(at: Vector3, size: Vector3, cladding: Material) -> void:
	Build.box(self, at, size, cladding).name = "HangarWall"
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	_body.add_child(collision)


## The office in the hangar's back right corner: walls, a door way toward the floor, a lit window.
func _office(cladding: Material) -> void:
	var half := HANGAR_SIZE / 2.0
	var at := HANGAR_AT + Vector3(half.x - OFFICE_SIZE.x / 2.0 - 0.3, 0.0, half.z
		- OFFICE_SIZE.z / 2.0 - 0.3)
	office = Node3D.new()
	office.name = "Office"
	add_child(office)
	office.position = at
	var front := -OFFICE_SIZE.z / 2.0
	_wall(at + Vector3(-OFFICE_SIZE.x / 2.0, OFFICE_SIZE.y / 2.0, 0.0), Vector3(0.15,
		OFFICE_SIZE.y, OFFICE_SIZE.z), cladding)
	_wall(at + Vector3(-1.4, OFFICE_SIZE.y / 2.0, front), Vector3(OFFICE_SIZE.x - 2.8 - 1.0,
		OFFICE_SIZE.y, 0.15), cladding)
	_wall(at + Vector3(OFFICE_SIZE.x / 2.0 - 0.5, OFFICE_SIZE.y / 2.0, front), Vector3(1.0,
		OFFICE_SIZE.y, 0.15), cladding)
	Build.box(self, at + Vector3(0.0, OFFICE_SIZE.y + 0.05, 0.0), Vector3(OFFICE_SIZE.x, 0.1,
		OFFICE_SIZE.z), cladding).name = "OfficeCeiling"
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.25, 0.22, 0.17)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.88, 0.66)
	glass.emission_energy_multiplier = 1.4
	Build.box(office, Vector3(-1.4, 1.6, front - 0.09), Vector3(1.6, 1.0, 0.02), glass).name = \
		"OfficeWindow"
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.88, 0.66)
	lamp.light_energy = 1.0
	lamp.omni_range = 5.0
	office.add_child(lamp)
	lamp.position = Vector3(0.0, 2.6, 0.0)


func _plane() -> void:
	plane = PLANE.instantiate() as Node3D
	plane.name = "PC12"
	add_child(plane)
	plane.global_transform = PLANE_AT.translated(Vector3.UP * TOP)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 2.3, 13.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = PLANE_AT.translated(Vector3.UP * 1.3)
	_body.add_child(collision)
	for lamp: Array in [[Vector3(-8.1, 1.4, 0.4), Color(1.0, 0.08, 0.05)],
			[Vector3(8.1, 1.4, 0.4), Color(0.1, 1.0, 0.3)]]:
		var nav := OmniLight3D.new()
		nav.light_color = lamp[1]
		nav.light_energy = 0.6
		nav.omni_range = 3.0
		plane.add_child(nav)
		nav.position = lamp[0]
	_beacon = OmniLight3D.new()
	_beacon.light_color = Color(1.0, 0.08, 0.05)
	_beacon.omni_range = 9.0
	plane.add_child(_beacon)
	_beacon.position = Vector3(0.0, 4.4, 5.8)


func _fence(concrete: Material, metal: Material) -> void:
	var fence := Fence.new()
	var a := AREA
	var pieces := [
		[Vector2(a.position.x, a.position.y), Vector2(a.end.x - 6.0, a.position.y),
			Vector3.FORWARD],
		[Vector2(a.position.x, GATE.z - GATE_WIDE / 2.0), Vector2(a.position.x, a.position.y),
			Vector3.LEFT],
		[Vector2(a.position.x, a.end.y), Vector2(a.position.x, GATE.z + GATE_WIDE / 2.0),
			Vector3.LEFT],
		[Vector2(a.position.x, a.end.y), Vector2(SERVICE_GATE.x - SERVICE_WIDE / 2.0, a.end.y),
			Vector3.BACK],
		[Vector2(SERVICE_GATE.x + SERVICE_WIDE / 2.0, a.end.y), Vector2(a.end.x - 6.0, a.end.y),
			Vector3.BACK],
	]
	for piece: Array in pieces:
		var from: Vector2 = piece[0]
		var to: Vector2 = piece[1]
		fence.run(self, _body, Vector3(from.x, TOP, from.y), Vector3(to.x, TOP, to.y), piece[2])
		fence_runs.append({"from": from, "to": to})
	for opening: Array in [[GATE, GATE_WIDE, Vector3.FORWARD], [SERVICE_GATE, SERVICE_WIDE,
			Vector3.RIGHT]]:
		var at: Vector3 = opening[0]
		var wide: float = opening[1]
		var sliding := SlidingGate.new()
		sliding.name = "SlidingGate"
		add_child(sliding)
		sliding.position = Vector3(at.x, TOP, at.z)
		sliding.rotation.y = -PI / 2.0 if opening[2] == Vector3.FORWARD else 0.0
		sliding.call("build", wide, GATE_TAIL, concrete)
		_gates[at] = [sliding, 0.0, 0.0, wide]
	keypad = Node3D.new()
	keypad.name = "Keypad"
	add_child(keypad)
	keypad.position = GATE + Vector3(-3.4, 0.0, GATE_WIDE / 2.0 + 0.6)
	Build.box(keypad, Vector3.UP * 0.55, Vector3(0.2, 1.1, 0.2), concrete)
	var face := StandardMaterial3D.new()
	face.albedo_color = Color(0.1, 0.1, 0.1)
	face.emission_enabled = true
	face.emission = Color(0.4, 0.9, 0.5)
	face.emission_energy_multiplier = 0.6
	Build.box(keypad, Vector3(0.11, 1.15, 0.0), Vector3(0.02, 0.18, 0.12), face)


## The main gate and the service gate: open (slid aside, passable) or shut.
func open_gate() -> void:
	_slide(GATE, true)


func close_gate() -> void:
	_slide(GATE, false)


## Whether the main gate stands fully open (it slides at GATE_SPEED).
func gate_open() -> bool:
	return float(_gates[GATE][1]) >= float(_gates[GATE][3]) - 0.01


func open_service() -> void:
	_slide(SERVICE_GATE, true)


func service_open() -> bool:
	return float(_gates[SERVICE_GATE][1]) >= float(_gates[SERVICE_GATE][3]) - 0.01


func _slide(at: Vector3, open: bool) -> void:
	_gates[at][2] = float(_gates[at][3]) if open else 0.0


## Each gate's leaf toward where it was sent, its lamp flashing while it moves; the leaf's own
## body blocks the opening wherever it stands.
func _move_gates(delta: float) -> void:
	for at: Vector3 in _gates:
		var entry: Array = _gates[at]
		var was: float = entry[1]
		entry[1] = move_toward(was, float(entry[2]), GATE_SPEED * delta)
		var sliding := entry[0] as Node3D
		sliding.call("moving_now", not is_equal_approx(was, float(entry[1])))
		sliding.call("set_open", float(entry[1]))


func _access(asphalt: Material, lamp_post: Callable) -> void:
	_strip(Vector3(726.0, 0.0, GATE.z), GATE, 6.6, asphalt, "AirfieldRoad")
	_strip(GATE, Vector3(APRON.position.x, 0.0, GATE.z), 6.6, asphalt, "AirfieldDrive")
	lamp_post.call(Vector3(742.0, 0.0, GATE.z - 4.9), PI)
	var gravel := StandardMaterial3D.new()
	gravel.albedo_color = Color(0.36, 0.35, 0.33)
	gravel.roughness = 0.95
	for leg in range(TRACK.size() - 1):
		_strip(TRACK[leg], TRACK[leg + 1], 4.5, gravel, "FreightTrack")


func _physics_process(delta: float) -> void:
	_move_gates(delta)


func _process(delta: float) -> void:
	if _beacon == null:
		return
	_clock = fmod(_clock + delta, 1.2)
	_beacon.light_energy = 3.0 if _clock < 0.12 else 0.0
