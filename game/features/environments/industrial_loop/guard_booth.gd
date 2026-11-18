extends Node3D
## A gatehouse booth with its guard, as the transfer shed's (`transfer_shed.gd`'s `_booth`,
## `_room` and `_seat_guard`, the same parts and sizes): a steel booth 2.5 x 2.7 x 2.0 m on a
## concrete plinth, glazed all round above a 1.05 m sill, its sliding service window toward +x,
## lit by an LED panel; a counter with a monitor showing the cameras, a keyboard, a phone and a
## logbook; the guard seated on a swivel chair facing the window, a stand-in (D6), her head
## turning to what she looks at. Shared by the warehouse compound (Mission 2's step 5); the shed
## keeps its own copy for now, so as not to change its bodies.

const Build = preload("res://shared/components/mesh_builder.gd")
const SIZE := Vector3(2.5, 2.7, 2.0)
const LIGHT := Color(1.0, 0.86, 0.68)
const PLINTH := 0.15
const SILL := 1.05
const HEAD := 2.25
const COUNTER_HEIGHT := 0.88
const SEAT_HEIGHT := 0.64
const SEAT := Vector3(0.3, 0.0, 0.35)
const SCREEN_GLOW := Color(0.62, 0.72, 0.85)

var guard: Node3D
var screen: Node3D
var logbook: Node3D
var _look: Marker3D


## The booth, its room and `guard_scene`'s guard seated in it (her clip `seated`), with
## `sign_text` over the service window.
func build(concrete: Material, metal: Material, wall: Material, guard_scene: PackedScene,
		guard_name: String, sign_text: String) -> void:
	var body := StaticBody3D.new()
	body.name = "BoothBody"
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = SIZE + Vector3(0.3, 0.0, 0.3)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3.UP * SIZE.y / 2.0
	body.add_child(collision)
	Build.box(self, Vector3(0, PLINTH / 2.0, 0), Vector3(SIZE.x + 0.3, PLINTH, SIZE.z + 0.3),
		concrete)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.82, 0.88, 0.9, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.04
	glass.metallic_specular = 0.5
	var frame := Build.material(Color("c9c7bf"), 0.5)
	var lining := Build.material(Color(0.55, 0.56, 0.55), 0.6)
	var names := {Vector3(0, 0, 1): "GlassSouth", Vector3(0, 0, -1): "GlassNorth",
		Vector3(1, 0, 0): "ServiceWindow", Vector3(-1, 0, 0): "GlassWest"}
	for normal: Vector3 in names:
		var width := SIZE.x if normal.z != 0.0 else SIZE.z
		var across := normal.cross(Vector3.UP)
		var face := normal * ((SIZE.z if normal.z != 0.0 else SIZE.x) / 2.0)
		var basis := Basis(across, Vector3.UP, normal)
		var lower := Build.box(self, face + Vector3.UP * (PLINTH + (SILL - PLINTH) / 2.0),
			Vector3(width, SILL - PLINTH, 0.1), wall)
		lower.basis = basis
		var upper := Build.box(self, face + Vector3.UP * (HEAD + (SIZE.y - HEAD) / 2.0),
			Vector3(width, SIZE.y - HEAD, 0.1), wall)
		upper.basis = basis
		for band: Vector2 in [Vector2(PLINTH, SILL), Vector2(HEAD, SIZE.y)]:
			var inside := Build.box(self, face - normal * 0.055 + Vector3.UP * (band.x + band.y)
				/ 2.0, Vector3(width - 0.22, band.y - band.x, 0.01), lining)
			inside.basis = basis
		var pane := Build.box(self, face + Vector3.UP * (SILL + HEAD) / 2.0,
			Vector3(width - 0.16, HEAD - SILL, 0.02), glass)
		pane.basis = basis
		pane.name = names[normal]
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for end in [-1.0, 1.0]:
			Build.box(self, face + across * end * (width / 2.0 - 0.04)
				+ Vector3.UP * (SILL + HEAD) / 2.0, Vector3(0.08, HEAD - SILL, 0.12), frame)
		if normal.x > 0.0:
			var mullion := Build.box(self, face + Vector3.UP * (SILL + HEAD) / 2.0,
				Vector3(0.05, HEAD - SILL, 0.1), frame)
			mullion.basis = basis
			mullion.name = "SlidingWindowMullion"
	Build.box(self, Vector3(0, SIZE.y + 0.08, 0), Vector3(SIZE.x + 0.5, 0.16, SIZE.z + 0.5), metal)
	_room(lining)
	var dark := Build.material(Color(0.03, 0.03, 0.035), 0.4)
	_seat(guard_scene, guard_name, dark)
	var sign := Build.text(self, sign_text, Vector3(SIZE.x / 2.0 + 0.06, SIZE.y - 0.22, 0), 28,
		Color("e3d5af"))
	sign.rotation.y = PI / 2.0
	sign.shaded = true
	sign.double_sided = false


## Turns the guard's head toward `at`, over 0.6 s.
func look_at_point(at: Vector3) -> void:
	if _look != null:
		_look.global_position = at


func _room(lining: Material) -> void:
	var inner := Vector2(SIZE.x - 0.2, SIZE.z - 0.2)
	Build.box(self, Vector3(0, PLINTH + 0.005, 0), Vector3(inner.x, 0.01, inner.y),
		Build.material(Color(0.08, 0.08, 0.085), 0.55)).name = "Floor"
	Build.box(self, Vector3(0, SIZE.y - 0.005, 0), Vector3(inner.x, 0.01, inner.y), lining) \
		.name = "Ceiling"
	var panel_at := Vector3(0.2, SIZE.y - 0.016, SEAT.z * 0.5)
	Build.box(self, panel_at, Vector3(0.6, 0.012, 0.6), Build.luminous(LIGHT * 0.9)).name = \
		"LedPanel"
	var light := OmniLight3D.new()
	light.name = "BoothLight"
	light.position = panel_at - Vector3(0, 0.08, 0)
	light.light_color = LIGHT
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.shadow_enabled = true
	add_child(light)
	var laminate := Build.material(Color(0.58, 0.56, 0.52), 0.45)
	var dark := Build.material(Color(0.03, 0.03, 0.035), 0.4)
	var depth := 0.55
	var counter_x := SIZE.x / 2.0 - 0.1 - depth / 2.0
	var top := PLINTH + COUNTER_HEIGHT
	Build.box(self, Vector3(counter_x, top - 0.015, 0), Vector3(depth, 0.03, 1.6), laminate) \
		.name = "Counter"
	for end in [-1.0, 1.0]:
		Build.box(self, Vector3(counter_x, PLINTH + (COUNTER_HEIGHT - 0.03) / 2.0, end * 0.785),
			Vector3(depth, COUNTER_HEIGHT - 0.03, 0.03), laminate).name = "CounterSide"
	var monitor := Node3D.new()
	monitor.name = "Monitor"
	monitor.position = Vector3(counter_x + 0.05, top, SEAT.z - 0.75)
	add_child(monitor)
	var towards := Vector3(SEAT.x - monitor.position.x, 0.0, SEAT.z - monitor.position.z)
	towards = towards.normalized()
	monitor.basis = Basis(Vector3.UP.cross(towards).normalized(), Vector3.UP, towards)
	Build.box(monitor, Vector3(0, 0.01, -0.03), Vector3(0.22, 0.02, 0.18), dark)
	Build.box(monitor, Vector3(0, 0.12, -0.03), Vector3(0.06, 0.22, 0.04), dark)
	Build.box(monitor, Vector3(0, 0.38, 0), Vector3(0.55, 0.33, 0.04), dark)
	screen = Build.box(monitor, Vector3(0, 0.38, 0.021), Vector3(0.52, 0.29, 0.002), _cctv())
	screen.name = "Screen"
	var glow := OmniLight3D.new()
	glow.name = "MonitorGlow"
	glow.position = Vector3(0, 0.38, 0.15)
	glow.light_color = SCREEN_GLOW
	glow.light_energy = 0.35
	glow.omni_range = 1.2
	glow.shadow_enabled = false
	monitor.add_child(glow)
	Build.box(self, Vector3(counter_x - 0.08, top + 0.01, SEAT.z - 0.45),
		Vector3(0.14, 0.02, 0.44), dark).name = "Keyboard"
	Build.box(self, Vector3(counter_x + 0.05, top + 0.035, -0.72), Vector3(0.2, 0.07, 0.22),
		dark).name = "Phone"
	logbook = Build.box(self, Vector3(counter_x + 0.06, top + 0.008, SEAT.z),
		Vector3(0.3, 0.016, 0.42), Build.material(Color(0.78, 0.76, 0.7), 0.8))
	logbook.name = "Logbook"


func _seat(guard_scene: PackedScene, guard_name: String, dark: Material) -> void:
	var fabric := Build.material(Color(0.06, 0.06, 0.07), 0.85)
	var chair := Node3D.new()
	chair.name = "Chair"
	chair.position = Vector3(SEAT.x - 0.06, PLINTH, SEAT.z)
	add_child(chair)
	Build.box(chair, Vector3(0, SEAT_HEIGHT - 0.03, 0), Vector3(0.44, 0.06, 0.44), fabric) \
		.name = "Seat"
	Build.box(chair, Vector3(-0.24, SEAT_HEIGHT + 0.3, 0), Vector3(0.05, 0.42, 0.4), fabric) \
		.name = "Back"
	Build.box(chair, Vector3(-0.2, SEAT_HEIGHT + 0.05, 0), Vector3(0.05, 0.1, 0.05), dark)
	Build.cylinder(chair, Vector3(0, SEAT_HEIGHT / 2.0, 0), 0.025, SEAT_HEIGHT - 0.12, dark) \
		.name = "Column"
	for spoke in range(5):
		var turn := TAU * spoke / 5.0
		var leg := Build.box(chair, Vector3(cos(turn), 0.0, sin(turn)) * 0.14 + Vector3.UP * 0.05,
			Vector3(0.28, 0.025, 0.04), dark)
		leg.rotation.y = -turn
	guard = guard_scene.instantiate() as Node3D
	guard.name = guard_name
	guard.set_meta("stand_in", true)
	guard.position = Vector3(SEAT.x, PLINTH, SEAT.z)
	guard.rotation.y = PI / 2.0
	add_child(guard)
	var player := guard.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.play("SitIdle")
	var skeleton := guard.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var head := skeleton.find_bone("Bip01 Head")
	var rest := (skeleton.global_basis * skeleton.get_bone_global_rest(head).basis) \
		.orthonormalized()
	var front := guard.global_basis.z.normalized()
	var best := 0.0
	var axis := 0
	var upward := 0.0
	var turn_axis := 0
	for index in range(3):
		var along := rest[index].dot(front)
		if absf(along) > best:
			best = absf(along)
			axis = index * 2 + (0 if along > 0.0 else 1)
		if absf(rest[index].dot(Vector3.UP)) > upward:
			upward = absf(rest[index].dot(Vector3.UP))
			turn_axis = index
	_look = Marker3D.new()
	_look.name = "GuardLook"
	add_child(_look)
	_look.global_position = screen.global_position
	var look := LookAtModifier3D.new()
	look.name = "GuardHead"
	look.bone_name = "Bip01 Head"
	look.forward_axis = axis as SkeletonModifier3D.BoneAxis
	look.primary_rotation_axis = turn_axis as Vector3.Axis
	look.duration = 0.6
	look.transition_type = Tween.TRANS_SINE
	look.ease_type = Tween.EASE_IN_OUT
	skeleton.add_child(look)
	look.target_node = look.get_path_to(_look)


func _cctv() -> StandardMaterial3D:
	var image := Image.create(64, 36, false, Image.FORMAT_RGB8)
	image.fill(Color(0.02, 0.02, 0.025))
	var tones: Array[Color] = [Color(0.22, 0.26, 0.3), Color(0.16, 0.19, 0.21),
		Color(0.25, 0.25, 0.27), Color(0.12, 0.15, 0.18)]
	for pane in range(4):
		var left := 1 + (pane % 2) * 32
		var high := 1 + floori(pane / 2.0) * 18
		for y in range(16):
			for x in range(30):
				image.set_pixel(left + x, high + y, tones[pane] * (0.75 + 0.25 * y / 16.0))
	var glow := Build.luminous(Color(1.4, 1.5, 1.6))
	glow.albedo_texture = ImageTexture.create_from_image(image)
	return glow
