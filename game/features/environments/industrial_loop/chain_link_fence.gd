extends RefCounted
## A run of 2.4 m chain-link security fence, as the transfer shed's (`transfer_shed.gd`'s `_fence`,
## the same parts and sizes): galvanised posts every 3 m with a barbed-wire arm leaning out at 45
## degrees, a top rail, a bottom tension wire, the chain-link mesh (`chain_link.gdshader`) and
## three barbed strands on the arms, solid to the top of the arms. Shared by the container yard
## (Mission 2's step 4); the shed keeps its own copy for now, so as not to change its bodies.

const Build = preload("res://shared/components/mesh_builder.gd")
const ChainLink = preload("chain_link.gdshader")
const ThinWire = preload("thin_wire.gdshader")
const HEIGHT := 2.4
const POST_SPACING := 3.0
const BARB_ARM := 0.45
const WIRE_GLINT := 0.12

var galvanised := Build.material(Color(0.6, 0.62, 0.62), 0.5)
var wire := ShaderMaterial.new()
var link := ShaderMaterial.new()


func _init() -> void:
	galvanised.metallic = 0.5
	wire.shader = ThinWire
	link.shader = ChainLink
	link.set_shader_parameter("zinc_reflectance", WIRE_GLINT)


## A run from `from` to `to` on the ground, its arms leaning toward `outward`; its body's shape
## goes in `body`. Returns its posts' places.
func run(parent: Node3D, body: StaticBody3D, from: Vector3, to: Vector3, outward: Vector3) \
		-> Array[Vector3]:
	var posts: Array[Vector3] = []
	var length := from.distance_to(to)
	if length < 0.3:
		return posts
	var along := (to - from) / length
	var bays := maxi(ceili(length / POST_SPACING), 1)
	var lean := (outward + Vector3.UP).normalized()
	var lean_basis := Basis(along, lean, along.cross(lean))
	for bay in range(bays + 1):
		var at := from + along * (length * bay / bays)
		posts.append(at)
		Build.cylinder(parent, at + Vector3.UP * (HEIGHT + 0.05) / 2.0, 0.03, HEIGHT + 0.05,
			galvanised).name = "FencePost"
		var arm := Build.box(parent, at + Vector3.UP * HEIGHT + lean * BARB_ARM / 2.0,
			Vector3(0.03, BARB_ARM, 0.03), galvanised)
		arm.basis = lean_basis
		arm.name = "BarbArm"
	var middle := (from + to) / 2.0
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	var rail := Build.box(parent, middle + Vector3.UP * HEIGHT, Vector3(length, 0.042, 0.042),
		galvanised)
	rail.basis = basis
	var bottom := Build.box(parent, middle + Vector3.UP * 0.08, Vector3(length, 0.006, 0.006), wire)
	bottom.basis = basis
	bottom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(length, HEIGHT - 0.08)
	var panel := Build.instance(parent, middle + Vector3.UP * (HEIGHT / 2.0 + 0.02), quad, link)
	panel.basis = basis
	panel.name = "ChainLink"
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for strand in range(1, 4):
		var lift := BARB_ARM * strand / 3.0 * 0.7071
		var at := middle + Vector3.UP * (HEIGHT + lift) + outward * lift
		var barb := Build.box(parent, at, Vector3(length, 0.006, 0.006), wire)
		barb.basis = basis
		barb.name = "BarbStrand"
		barb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, HEIGHT + 0.4, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(basis, middle + Vector3.UP * (HEIGHT + 0.4) / 2.0)
	body.add_child(collision)
	return posts
