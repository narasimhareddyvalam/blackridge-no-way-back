extends Node3D
## Bay 9's dock lift (docs/PHASE_BRIEF.md, step 2d, rule G1): a scissor lift in a pit behind the
## van bay's door, as real sites fit for vans, whose floors stand below a truck dock. Its steel
## deck, 1.83 x 2.44 m (6 x 8 ft), rests flush with the dock floor, its edges painted in yellow and
## black stripes; its bridge lip hangs folded under the deck's outer end. The node's origin is the
## deck's top centre; step 2e moves it between the dock floor and the van's.

const Build = preload("res://shared/components/mesh_builder.gd")
const DECK := Vector3(1.83, 0.12, 2.44)
const EDGE := 0.08
const PAINT := 0.002
const LIP := Vector3(1.5, 0.4, 0.025)
const STRIPES := "res://features/environments/industrial_loop/art/depot/hazard_stripes.png"


func build() -> void:
	var steel := Build.material(Color(0.3, 0.32, 0.34), 0.45)
	steel.metallic = 0.6
	var deck := Build.box(self, Vector3(0.0, -DECK.y / 2.0, 0.0), DECK, steel)
	deck.name = "Platform"
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load(STRIPES)
	paint.roughness = 0.7
	paint.uv1_triplanar = true
	paint.uv1_world_triplanar = true
	paint.uv1_scale = Vector3.ONE * 2.0
	for side: float in [-1.0, 1.0]:
		Build.box(self, Vector3(side * (DECK.x - EDGE) / 2.0, PAINT / 2.0, 0.0), Vector3(EDGE,
			PAINT, DECK.z), paint).name = "EdgeStripe"
		Build.box(self, Vector3(0.0, PAINT / 2.0, side * (DECK.z - EDGE) / 2.0), Vector3(
			DECK.x - EDGE * 2.0, PAINT, EDGE), paint).name = "EdgeStripe"
	Build.box(self, Vector3(0.0, -DECK.y - LIP.y / 2.0, DECK.z / 2.0 - LIP.z), LIP, steel).name = \
		"BridgeLip"
