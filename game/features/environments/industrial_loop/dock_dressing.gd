extends RefCounted
## A dock door dressed as real ones are (the audit, #352, after Commons photos of working docks),
## shared by the transfer shed (`transfer_building.gd`) and the compound's warehouses
## (`warehouse.gd`): its number on a white plate above it and painted big on its door; a hi-vis
## band of orange and white diagonal stripes along its door's bottom; a hooded red-over-green
## traffic light beside it at a driver's eye, its caution sign under it, both on a wall bracket; and its seal's pads black
## rubber, their guide stripes yellow. Each building lights its own signals (its `_show`).

const Build = preload("res://shared/components/mesh_builder.gd")
const Retroreflector = preload("retroreflector.gdshader")
const OPENING := Vector2(2.74, 3.05)
## The number plate above the seal's head and the dock light, 1.0 m over the opening; the door's
## own number 0.95 m up its panel, under its windows, over its band.
const PLATE := Vector3(0.52, 0.38, 0.03)
const PLATE_ABOVE := 1.0
const PAINTED_UP := 0.95
const PAINTED_SIZE := 64
const DOOR_FACE := 0.066
const BAND := Vector2(2.62, 0.32)
const BAND_STRIPE := 0.09
## The signal's housing and its two 170 mm lenses, each under a visor.
const HOUSING := Vector3(0.26, 0.56, 0.14)
const LENS_RADIUS := 0.085
const LENS_APART := 0.13
const SIGN := Vector3(0.36, 0.46, 0.012)
const SIGN_BELOW := 0.6
const SIGN_WORDS := "CAUTION\nBACK IN OR\nPULL OUT ON\nGREEN LIGHT\nONLY"
## Neighbouring seals leave 0.19 m of wall, so the light and its sign stand on a wall bracket clear
## in front of the seals' pads (0.46 m deep).
const STAND_OFF := 0.52
const SEAL_STRIPE_SURFACE := 3


## The door's own number painted on its panel and its hi-vis band, on its model (the holder's first
## child), so they rise with it when it is open.
static func door(holder: Node3D, number: int) -> void:
	var panel := holder.get_child(0) as Node3D
	var painted := Build.text(panel, str(number), Vector3(0.0, PAINTED_UP, DOOR_FACE + 0.002),
		PAINTED_SIZE, Color(0.2, 0.2, 0.21))
	painted.name = "PaintedNumber"
	painted.shaded = true
	painted.double_sided = false
	var stripes := ShaderMaterial.new()
	stripes.shader = Retroreflector
	stripes.set_shader_parameter("sheeting", Vector3(0.92, 0.92, 0.9))
	stripes.set_shader_parameter("stripe_colour", Vector3(0.95, 0.32, 0.05))
	stripes.set_shader_parameter("stripe_slope", 1.0)
	stripes.set_shader_parameter("stripe_width", BAND_STRIPE)
	stripes.set_shader_parameter("return_peak", 60.0)
	var band := Build.box(panel, Vector3(0.0, BAND.y / 2.0 + 0.03, DOOR_FACE), Vector3(BAND.x,
		BAND.y, 0.004), stripes)
	band.name = "HiVisBand"


## The door's number on a white plate above its opening, `face` the wall's outer face (z).
static func plate(parent: Node3D, number: int, x: float, sill: float, face: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "NumberPlate%d" % number
	holder.position = Vector3(x, sill + OPENING.y + PLATE_ABOVE + PLATE.y / 2.0, face
		+ PLATE.z / 2.0)
	parent.add_child(holder)
	Build.box(holder, Vector3.ZERO, PLATE, Build.material(Color(0.92, 0.92, 0.9), 0.5)) \
		.name = "Plate"
	var digits := Build.text(holder, str(number), Vector3(0.0, -0.01, PLATE.z / 2.0 + 0.002), 30,
		Color(0.03, 0.03, 0.03))
	digits.name = "Number"
	digits.shaded = true
	digits.double_sided = false
	return holder


## A dock's traffic light, `label`, at `at`, facing +z: a black housing, a red lens over a green,
## each 170 mm under its visor; its lenses "Red" and "Green" for its building to light.
static func traffic_light(parent: Node3D, label: String, at: Vector3, red: Material,
		green: Material) -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	holder.position = at + Vector3(0.0, 0.0, STAND_OFF)
	parent.add_child(holder)
	var body := Build.material(Color(0.06, 0.06, 0.06), 0.6)
	Build.box(holder, Vector3.ZERO, HOUSING, body).name = "Housing"
	Build.box(holder, Vector3(0.0, 0.0, -(STAND_OFF + HOUSING.z / 2.0) / 2.0), Vector3(0.05, 0.05,
		STAND_OFF - HOUSING.z / 2.0 + 0.02), body).name = "Bracket"
	var lenses := {"Red": [LENS_APART, red], "Green": [-LENS_APART, green]}
	var index := 0
	for name: String in lenses:
		var y: float = lenses[name][0]
		var lens := Build.cylinder(holder, Vector3(0.0, y, HOUSING.z / 2.0 + 0.006), LENS_RADIUS,
			0.012, lenses[name][1])
		lens.rotation.x = PI / 2.0
		lens.name = name
		var visor := Build.box(holder, Vector3(0.0, y + LENS_RADIUS + 0.008, HOUSING.z / 2.0
			+ 0.06), Vector3(LENS_RADIUS * 2.3, 0.01, 0.12), body)
		visor.rotation.x = -0.18
		visor.name = "Visor%d" % index
		index += 1
	return holder


## The caution sign under a dock's light, `at` the light's place.
static func caution_sign(parent: Node3D, number: int, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = "CautionSign%d" % number
	holder.position = at + Vector3(0.0, -SIGN_BELOW, STAND_OFF - 0.04)
	parent.add_child(holder)
	Build.box(holder, Vector3(0.0, 0.0, -(STAND_OFF - 0.04) / 2.0), Vector3(0.04, 0.04,
		STAND_OFF - 0.06), Build.material(Color(0.06, 0.06, 0.06), 0.6)).name = "Bracket"
	Build.box(holder, Vector3.ZERO, SIGN, Build.material(Color(0.95, 0.78, 0.08), 0.5)) \
		.name = "Placard"
	var words := Build.text(holder, SIGN_WORDS, Vector3(0.0, 0.0, SIGN.z / 2.0 + 0.002), 7,
		Color(0.03, 0.03, 0.03))
	words.name = "Words"
	words.shaded = true
	words.double_sided = false
	words.line_spacing = -2.0
	return holder


## The seal's pads black rubber, scuffed matt, and their guide stripes yellow.
static func seal(pads: Node3D) -> void:
	var rubber := Build.material(Color(0.035, 0.035, 0.035), 0.88)
	var stripe := Build.material(Color(0.95, 0.72, 0.06), 0.6)
	for mesh: MeshInstance3D in pads.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, stripe if surface == SEAL_STRIPE_SURFACE
				else rubber)
