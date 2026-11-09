extends Node3D
## The transfer shed's way in (docs/PHASE_BRIEF.md, Phase 2 step 2b): the spur north from the
## valley road, the security fence round the shed's yard, the guard booth and the boom barrier.
## The guard is a stand-in (decision D6): a timed check of the run sheet, labelled so, until
## Assignment 9's technique replaces it. The barrier, like a real one on its safety loop, never
## comes down while a vehicle is under its arm.

signal run_sheet_checked

const Build = preload("res://shared/components/mesh_builder.gd")
const ChainLink = preload("chain_link.gdshader")
const Retroreflector = preload("retroreflector.gdshader")
const LANE_X := -71.0
const LANE_WIDTH := 6.0
const GATE_Z := 55.0
const STOP_LINE_OUT := 2.5
const BUILDING_FRONT_Z := 37.5
const DOCK_FRONT_Z := 39.9
const CORNER_RADIUS := 6.0
const COLUMN_STEP := 0.5
const SURFACE_HEIGHT := 0.02
const FENCE_HEIGHT := 2.4
const POST_SPACING := 3.0
const BARB_ARM := 0.45
const ARM_LENGTH := 6.4
const ARM_PIVOT_HEIGHT := 0.9
const RAISE_SECONDS := 4.0
const CHECK_SECONDS := 3.0
const BOOTH := Vector3(2.5, 2.7, 2.0)
const BOOTH_GAP := 0.6
const CLEAR_BEHIND := 1.0
const SWEEP_HALF_DEPTH := 0.3
const APRON_PLOT := Rect2(LANE_X - 23.0, BUILDING_FRONT_Z, 46.0, GATE_Z + 2.0 - BUILDING_FRONT_Z)
const SPUR_PLOT := Rect2(LANE_X - LANE_WIDTH / 2.0 - CORNER_RADIUS - 1.0, GATE_Z,
	LANE_WIDTH + CORNER_RADIUS * 2.0 + 2.0, 20.0)

var lamp_at := Vector3(LANE_X + LANE_WIDTH / 2.0 + 1.6, 0.0, GATE_Z + 3.0)
var clearings: Array[Rect2] = [APRON_PLOT, SPUR_PLOT]
var vehicle: Node3D

var _angle: float = 0.0
var _target: float = 0.0
var _check_left: float = -1.0
var _arm: AnimatableBody3D
var _vehicle_front := Vector3.ZERO
var _vehicle_rear := Vector3.ZERO
var _fence_body: StaticBody3D
var _paint := Build.material(Color("d8d5cb"), 0.55)


static func road_opening() -> Vector3:
	return Vector3(LANE_X, GATE_Z + 16.0, LANE_WIDTH / 2.0 + CORNER_RADIUS + 1.5)


static func flat_plots() -> Array[Rect2]:
	return [APRON_PLOT, SPUR_PLOT]


func build(road: RefCounted, building_width: float, surface: Material, concrete: Material,
		metal: Material, wall: Material) -> void:
	_spur(road, surface)
	_markings()
	_fence_body = StaticBody3D.new()
	_fence_body.name = "Fence"
	add_child(_fence_body)
	var west := LANE_X - building_width / 2.0
	var east := LANE_X + building_width / 2.0
	var booth_west := LANE_X - LANE_WIDTH / 2.0 - BOOTH_GAP - BOOTH.x
	var rest_x := LANE_X - LANE_WIDTH / 2.0 - 0.3 + ARM_LENGTH + 0.3
	_fence(Vector3(west, 0.0, BUILDING_FRONT_Z), Vector3(west, 0.0, GATE_Z), Vector3.LEFT, metal)
	_fence(Vector3(east, 0.0, BUILDING_FRONT_Z), Vector3(east, 0.0, GATE_Z), Vector3.RIGHT, metal)
	_fence(Vector3(west, 0.0, GATE_Z), Vector3(booth_west, 0.0, GATE_Z), Vector3.BACK, metal)
	_fence(Vector3(rest_x + 0.3, 0.0, GATE_Z), Vector3(east, 0.0, GATE_Z), Vector3.BACK, metal)
	_booth(concrete, metal, wall)
	_barrier(metal, rest_x)


func watch(body: Node3D) -> void:
	vehicle = body
	_vehicle_front = Vector3.ZERO
	_vehicle_rear = Vector3.ZERO
	for child in body.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			var shape := child as CollisionShape3D
			var half := ((shape.shape as BoxShape3D).size * 0.5)
			_vehicle_front = shape.position + Vector3(0.0, 0.0, -half.z)
			_vehicle_rear = shape.position + Vector3(0.0, 0.0, half.z)
			return


func barrier_open() -> bool:
	return _angle >= 89.0


func barrier_angle() -> float:
	return _angle


func checking() -> bool:
	return _check_left >= 0.0


func at_stop(front: Vector3) -> bool:
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < GATE_Z + STOP_LINE_OUT + 6.0 \
		and absf(front.x - LANE_X) < LANE_WIDTH / 2.0 + 1.0


func vehicle_at_stop() -> bool:
	return is_instance_valid(vehicle) and at_stop(vehicle.to_global(_vehicle_front))


func vehicle_near() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_vehicle_front)
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < GATE_Z + 25.0 \
		and absf(front.x - LANE_X) < LANE_WIDTH / 2.0 + CORNER_RADIUS


func vehicle_through() -> bool:
	if not is_instance_valid(vehicle):
		return false
	return maxf(vehicle.to_global(_vehicle_front).z, vehicle.to_global(_vehicle_rear).z) \
		< GATE_Z - SWEEP_HALF_DEPTH and absf(vehicle.global_position.x - LANE_X) < 30.0


func hand_run_sheet() -> bool:
	if checking() or _target > 0.0:
		return false
	_check_left = CHECK_SECONDS
	return true


func reset() -> void:
	_check_left = -1.0
	_target = 0.0
	_angle = 0.0
	if _arm != null:
		_arm.rotation.z = 0.0


func _physics_process(delta: float) -> void:
	if _check_left >= 0.0:
		_check_left -= delta
		if _check_left < 0.0:
			_check_left = -1.0
			_target = 90.0
			run_sheet_checked.emit()
	if is_instance_valid(vehicle):
		var front := vehicle.to_global(_vehicle_front)
		var rear := vehicle.to_global(_vehicle_rear)
		var in_lane := absf(vehicle.global_position.x - LANE_X) < ARM_LENGTH
		var under := in_lane and minf(front.z, rear.z) < GATE_Z + SWEEP_HALF_DEPTH \
			and maxf(front.z, rear.z) > GATE_Z - SWEEP_HALF_DEPTH
		if under and _target == 0.0 and _angle > 0.0:
			_target = 90.0
		elif _target == 90.0 and _angle >= 90.0 and not under \
				and maxf(front.z, rear.z) < GATE_Z - CLEAR_BEHIND:
			_target = 0.0
	_angle = move_toward(_angle, _target, 90.0 / RAISE_SECONDS * delta)
	if _arm != null:
		_arm.rotation.z = deg_to_rad(_angle)


func _road_edge_z(road: RefCounted, x: float) -> float:
	var points: PackedVector3Array = road.points
	var count := points.size()
	var best := INF
	var edge := PackedVector3Array()
	for index in range(count):
		var at := points[index]
		if absf(at.x - x) > 30.0 or absf(at.z - GATE_Z) > 40.0:
			edge.append(Vector3.INF)
			continue
		var along := points[(index + 1) % count] - points[(index - 1 + count) % count]
		var side := Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)
		var reach: Vector3 = side * float(road.half_widths[index])
		edge.append(at - reach if (at - reach).z < (at + reach).z else at + reach)
	for index in range(edge.size() - 1):
		var a := edge[index]
		var b := edge[index + 1]
		if not a.is_finite() or not b.is_finite() or is_equal_approx(a.x, b.x):
			continue
		if (a.x - x) * (b.x - x) > 0.0:
			continue
		var z := lerpf(a.z, b.z, (x - a.x) / (b.x - a.x))
		if z > GATE_Z and z < best:
			best = z
	return best


func _spur(road: RefCounted, surface: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LANE_WIDTH / 2.0
	var groups: Array[Array] = [
		[LANE_X - half - CORNER_RADIUS, LANE_X - half, -1.0],
		[LANE_X - half, LANE_X + half, 0.0],
		[LANE_X + half, LANE_X + half + CORNER_RADIUS, 1.0],
	]
	var first := 0
	for group in groups:
		var columns := int(round((float(group[1]) - float(group[0])) / COLUMN_STEP))
		for step in range(columns + 1):
			var x := float(group[0]) + step * COLUMN_STEP
			var edge := _road_edge_z(road, x)
			var north := DOCK_FRONT_Z
			if float(group[2]) != 0.0:
				var out := absf(x - LANE_X) - half
				var inner := CORNER_RADIUS - out
				north = edge - (CORNER_RADIUS - sqrt(maxf(CORNER_RADIUS * CORNER_RADIUS
					- inner * inner, 0.0)))
			for corner: Vector3 in [Vector3(x, 0.002, edge), Vector3(x, SURFACE_HEIGHT,
					minf(edge - 0.6, maxf(north, edge - 0.6))), Vector3(x, SURFACE_HEIGHT, north)]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(corner.x, corner.z))
				tool.add_vertex(corner)
		for step in range(columns):
			for row in range(2):
				var top := first + step * 3 + row
				var next := top + 3
				for index: int in [top, top + 1, next, top + 1, next + 1, next]:
					tool.add_index(index)
		first += (columns + 1) * 3
	tool.generate_tangents()
	var ground := Build.instance(self, Vector3.ZERO, tool.commit(), surface)
	ground.name = "Spur"
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _markings() -> void:
	var line_z := GATE_Z + STOP_LINE_OUT
	Build.box(self, Vector3(LANE_X, SURFACE_HEIGHT + 0.004, line_z),
		Vector3(LANE_WIDTH - 0.4, 0.008, 0.3), _paint).name = "StopLine"
	var word := Build.text(self, "STOP", Vector3(LANE_X, SURFACE_HEIGHT + 0.006, line_z + 2.2),
		400, Color("d8d5cb"))
	word.name = "StopWord"
	word.rotation.x = -PI / 2.0
	word.shaded = true
	word.double_sided = false
	word.pixel_size = 0.004


func _fence(from: Vector3, to: Vector3, outward: Vector3, metal: Material) -> void:
	var length := from.distance_to(to)
	if length < 0.3:
		return
	var along := (to - from) / length
	var bays := maxi(ceili(length / POST_SPACING), 1)
	var link := ShaderMaterial.new()
	link.shader = ChainLink
	var lean := (outward + Vector3.UP).normalized()
	var lean_basis := Basis(along, lean, along.cross(lean))
	for bay in range(bays + 1):
		var at := from + along * (length * bay / bays)
		Build.cylinder(self, at + Vector3.UP * (FENCE_HEIGHT + 0.05) / 2.0, 0.03,
			FENCE_HEIGHT + 0.05, metal)
		var arm := Build.box(self, at + Vector3.UP * FENCE_HEIGHT + lean * BARB_ARM / 2.0,
			Vector3(0.03, BARB_ARM, 0.03), metal)
		arm.basis = lean_basis
	var middle := (from + to) / 2.0
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	var rail := Build.box(self, middle + Vector3.UP * FENCE_HEIGHT, Vector3(length, 0.042, 0.042),
		metal)
	rail.basis = basis
	var bottom := Build.box(self, middle + Vector3.UP * 0.08, Vector3(length, 0.006, 0.006), metal)
	bottom.basis = basis
	var quad := QuadMesh.new()
	quad.size = Vector2(length, FENCE_HEIGHT - 0.08)
	var panel := Build.instance(self, middle + Vector3.UP * (FENCE_HEIGHT / 2.0 + 0.02), quad,
		link)
	panel.basis = basis
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for strand in range(1, 4):
		var lift := BARB_ARM * strand / 3.0 * 0.7071
		var strand_at := middle + Vector3.UP * (FENCE_HEIGHT + lift) + outward * lift
		var wire := Build.box(self, strand_at, Vector3(length, 0.006, 0.006), metal)
		wire.basis = basis
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, FENCE_HEIGHT + 0.4, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(basis, middle + Vector3.UP * (FENCE_HEIGHT + 0.4) / 2.0)
	_fence_body.add_child(collision)


func _booth(concrete: Material, metal: Material, wall: Material) -> void:
	var booth := Node3D.new()
	booth.name = "GuardBooth"
	booth.position = Vector3(LANE_X - LANE_WIDTH / 2.0 - BOOTH_GAP - BOOTH.x / 2.0, 0.0, GATE_Z)
	add_child(booth)
	var plinth := 0.15
	Build.box(booth, Vector3(0, plinth / 2.0, 0), Vector3(BOOTH.x + 0.3, plinth, BOOTH.z + 0.3),
		concrete, true)
	var sill := 1.05
	var head := 2.25
	var lit := Build.luminous(Color(1.0, 0.86, 0.66) * 0.42)
	var frame := Build.material(Color("c9c7bf"), 0.5)
	for side: Array in [[Vector3(0, 0, 1), BOOTH.x], [Vector3(0, 0, -1), BOOTH.x],
			[Vector3(1, 0, 0), BOOTH.z], [Vector3(-1, 0, 0), BOOTH.z]]:
		var normal: Vector3 = side[0]
		var width: float = side[1]
		var across := normal.cross(Vector3.UP)
		var face := normal * ((BOOTH.z if normal.z != 0.0 else BOOTH.x) / 2.0)
		var basis := Basis(across, Vector3.UP, normal)
		var lower := Build.box(booth, face + Vector3.UP * (plinth + (sill - plinth) / 2.0),
			Vector3(width, sill - plinth, 0.1), wall, true)
		lower.basis = basis
		var upper := Build.box(booth, face + Vector3.UP * (head + (BOOTH.y - head) / 2.0),
			Vector3(width, BOOTH.y - head, 0.1), wall)
		upper.basis = basis
		var glass := Build.box(booth, face + Vector3.UP * (sill + head) / 2.0,
			Vector3(width - 0.16, head - sill, 0.02), lit)
		glass.basis = basis
		for end in [-1.0, 1.0]:
			Build.box(booth, face + across * end * (width / 2.0 - 0.04)
				+ Vector3.UP * (sill + head) / 2.0, Vector3(0.08, head - sill, 0.12), frame)
	Build.box(booth, Vector3(0, BOOTH.y + 0.08, 0), Vector3(BOOTH.x + 0.5, 0.16, BOOTH.z + 0.5),
		metal)
	var light := OmniLight3D.new()
	light.position = Vector3(0, BOOTH.y - 0.25, 0)
	light.light_color = Color(1.0, 0.86, 0.68)
	light.light_energy = 0.7
	light.omni_range = 4.5
	light.shadow_enabled = false
	booth.add_child(light)
	var sign := Build.text(booth, "STOP  -  REPORT TO GATEHOUSE",
		Vector3(BOOTH.x / 2.0 + 0.06, BOOTH.y - 0.22, 0), 28, Color("e3d5af"))
	sign.rotation.y = PI / 2.0
	sign.shaded = true


func _barrier(metal: Material, rest_x: float) -> void:
	var post_x := LANE_X - LANE_WIDTH / 2.0 - 0.3
	var cabinet := Build.material(Color("d6d3ca"), 0.45)
	Build.box(self, Vector3(post_x, 0.5, GATE_Z), Vector3(0.32, 1.0, 0.32), cabinet, true) \
		.name = "BarrierCabinet"
	Build.cylinder(self, Vector3(rest_x, 0.42, GATE_Z), 0.04, 0.84, metal).name = "ArmRest"
	_arm = AnimatableBody3D.new()
	_arm.name = "BarrierArm"
	_arm.sync_to_physics = true
	_arm.position = Vector3(post_x + 0.16, ARM_PIVOT_HEIGHT, GATE_Z)
	add_child(_arm)
	var bands := ShaderMaterial.new()
	bands.shader = Retroreflector
	bands.set_shader_parameter("sheeting", Vector3(0.88, 0.88, 0.86))
	bands.set_shader_parameter("stripe_colour", Vector3(0.62, 0.04, 0.03))
	bands.set_shader_parameter("stripe_slope", 100.0)
	bands.set_shader_parameter("stripe_width", 0.8 * 100.0 / (2.0 * sqrt(2.0)))
	var size := Vector3(ARM_LENGTH, 0.1, 0.06)
	Build.box(_arm, Vector3(ARM_LENGTH / 2.0, 0, 0), size, bands)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(ARM_LENGTH / 2.0, 0, 0)
	_arm.add_child(collision)
