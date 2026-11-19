extends Node3D
## The container yard behind the valley road (docs/PHASE_BRIEF.md, Mission 2's step 4; the
## author's choices, #311-#312): an unattended night yard. Paved, fenced round in 2.4 m chain-link
## with barbed wire (`chain_link_fence.gd`), entered from the road by a short driveway through a
## cantilever sliding gate that a keypad on a gooseneck pedestal opens, 4 m before it on the
## driver's side, with its stop line, a camera on a pole and its signs. Inside, ISO containers
## (`build_containers.py`: 20 ft, 40 ft and 40 ft high cube, in faded plain colours, no shipping
## line's name) stand in two blocks two and three high, their doors to the lane between them,
## 16 m wide, under two high-mast lights. On the lane's west side a marked bay where Ethan leaves
## the van and its sealed load; across it, nose to the gate, the dark van: our Iveco in charcoal
## (D3). The swap (`swap()`): his van is left where it stopped as a parked copy holding the load,
## and the van he drives is moved to the dark van's place in its paint, empty, so one van is ever
## drivable. `placements()` and the rest hand out what was placed, since a headless run draws
## nothing.

const Build = preload("res://shared/components/mesh_builder.gd")
const Fence = preload("chain_link_fence.gd")
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const PARTS := preload(
	"res://features/environments/industrial_loop/art/container_yard/containers.glb")
const IVECO := preload("res://features/vehicles/freight_van/art/iveco/iveco_exterior.glb")
const ART := "res://features/environments/industrial_loop/art/fitout/"
const BEEP := preload("res://features/audio/shed/scanner_beep.wav")
const MOTOR := preload("res://features/audio/shed/forklift_pump.wav")
const GROUND := 0.0
const PAVING_TOP := 0.02
const YARD := Rect2(64.0, 132.0, 72.0, 26.0)
const GATE_X := 100.0
const GATE_WIDE := 6.0
const DRIVEWAY := Rect2(97.0, 158.0, 6.0, 11.5)
## The keypad on the driver's (west) side of a van coming in, 4 m before the gate, and its line.
const KEYPAD := Vector3(98.0, GROUND, 162.0)
const KEYPAD_UP := 1.1
const STOP_Z := 162.5
const STOP_WITHIN := 2.5
const CODE := "4719"
const KEY_SECONDS := 0.35
## A high-speed cantilever gate operator: 2 ft/s (0.6 m/s); the van can pass once it has 3 m.
const GATE_SPEED := 0.6
const PASSABLE := 3.0
## The leaf's counterweight tail, which runs behind the fence to the west, the way it opens.
const TAIL := 3.0
const CLEAR_BEHIND := 2.0
## The free-exit loop in the lane 1.5 m inside the gate's line (the audit's first fix, #322): a
## vehicle over it (any part) facing out within 45 degrees opens the gate, which shuts once the whole vehicle
## is 2 m beyond the line, or once it has backed 2 m off the loop into the yard again.
const EXIT_LOOP := Rect2(GATE_X - GATE_WIDE / 2.0, YARD.end.y - 5.0, GATE_WIDE, 3.5)
const FACING_OUT := 0.7071
const LANE := Rect2(92.0, 132.5, 16.0, 25.5)
const BAY := Rect2(93.6, 134.6, 2.8, 6.8)
const BAY_POSE := Transform3D(Basis.IDENTITY, Vector3(95.0, 0.1, 138.0))
const IN_BAY := Rect2(94.2, 135.5, 1.6, 5.0)
const SQUARE_IN_BAY := deg_to_rad(15.0)
const DARK_VAN_POSE := Transform3D(Basis(Vector3.UP, PI), Vector3(104.5, 0.1, 140.0))
const DARK := Color(0.2, 0.21, 0.22)
## His hand at the driver's (left) door: 1.1 m out from the van's middle, 1.3 m ahead of it.
const DRIVER_DOOR := Vector3(-1.1, 0.0, -1.3)
const AT_DOOR := 1.2
## The two blocks: their containers' kinds, cells and heights, drawn from a seed.
const SIZES := {"Container20": Vector3(6.058, 2.591, 2.438),
	"Container40": Vector3(12.192, 2.591, 2.438), "Container40HC": Vector3(12.192, 2.896, 2.438)}
const ROW_PITCH := 2.84
const ROWS := 7
const FIRST_ROW := 135.0
const WEST_CELLS: Array[Array] = [["Container40", 72.2], ["Container40", 84.7]]
const EAST_CELLS: Array[Array] = [["Container40", 115.7], ["Container20", 125.2],
	["Container20", 131.6]]
const MOST_HIGH := 3
const SEED := 312
const COLOURS: Array[Color] = [Color(0.5, 0.17, 0.12), Color(0.16, 0.3, 0.48),
	Color(0.2, 0.36, 0.25), Color(0.48, 0.48, 0.46), Color(0.78, 0.78, 0.74),
	Color(0.4, 0.13, 0.16), Color(0.56, 0.33, 0.14), Color(0.15, 0.37, 0.38)]
const MASTS: Array[Vector3] = [Vector3(91.3, GROUND, 156.8), Vector3(108.7, GROUND, 133.4)]
const MAST_TALL := 18.0
const CAMERA_POLE := Vector3(104.3, GROUND, 157.4)

signal key_beeped
signal swapped(left: Node3D)

var vehicle: CharacterBody3D

var _placed := {}
var _kinds: Array[String] = []
var _fence_runs: Array = []
var _footprints: Array[Rect2] = []
var _body: StaticBody3D
var _gate: AnimatableBody3D
var _gate_open := 0.0
var _gate_target := 0.0
var _keys_left := 0
var _key_timer := 0.0
var _window_down := false
var _exiting := false
var _beep: AudioStreamPlayer3D
var _motor: AudioStreamPlayer3D
var _dark_van: Node3D
var _left: Node3D
var _van_box := Vector3(2.0, 2.5, 6.0)
var _van_box_at := Vector3(0.0, 1.25, 0.0)
var _front := Vector3(0.0, 0.0, -3.0)
var _rear := Vector3(0.0, 0.0, 3.0)


func build(surface: Material) -> void:
	_body = StaticBody3D.new()
	_body.name = "YardBody"
	add_child(_body)
	_paving(surface)
	_boundary()
	_gate_and_keypad()
	_containers()
	_lights()
	_bay_lines()
	_dark_van = _parked_iveco("DarkVan", DARK_VAN_POSE, DARK)


## The van Ethan drives: its box, front and rear, read from its collision shape.
func watch(van: CharacterBody3D) -> void:
	vehicle = van
	for child in van.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			var shape := child as CollisionShape3D
			_van_box = (shape.shape as BoxShape3D).size
			_van_box_at = shape.position
			_front = shape.position + Vector3(0.0, 0.0, -_van_box.z / 2.0)
			_rear = shape.position + Vector3(0.0, 0.0, _van_box.z / 2.0)
			var parked := _dark_van.get_node("DarkVanBody").get_child(0) as CollisionShape3D
			(parked.shape as BoxShape3D).size = _van_box
			parked.position = _van_box_at
			return


## As a night begins: the gate shut, the dark van in its place and no van left.
func reset() -> void:
	_gate_open = 0.0
	_gate_target = 0.0
	_keys_left = 0
	_window_down = false
	_exiting = false
	_place_gate()
	if _left != null:
		_left.queue_free()
		_left = null
	_dark_van.visible = true
	_dark_body(true)


func placements(label: String) -> Array:
	return (_placed.get(label, []) as Array).duplicate()


## Each container's kind, in the order of `placements("Containers")`.
func container_kinds() -> Array[String]:
	return _kinds.duplicate()


## The fence's runs on the ground, each {"from", "to"}.
func fence_runs() -> Array:
	return _fence_runs.duplicate()


## Everything standing in the yard, as rectangles on the ground (x, z).
func footprints() -> Array[Rect2]:
	return _footprints.duplicate()


func gate_open() -> bool:
	return _gate_open >= GATE_WIDE - 0.01


func gate_shut() -> bool:
	return _gate_open <= 0.01


func gate_opening() -> float:
	return _gate_open


func keying() -> bool:
	return _keys_left > 0


func vehicle_near() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_front)
	return front.z > YARD.end.y and front.z < DRIVEWAY.end.y + 20.0 \
		and absf(front.x - GATE_X) < 25.0


## Whether the van stands with its driver's window at the keypad, on the line.
func vehicle_at_stop() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_front)
	return absf(front.z - STOP_Z) < STOP_WITHIN and absf(front.x - GATE_X) < GATE_WIDE / 2.0


## Whether the whole van is inside the yard, past the gate.
func vehicle_through() -> bool:
	if not is_instance_valid(vehicle):
		return false
	return maxf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z) < YARD.end.y \
		and YARD.has_point(Vector2(vehicle.global_position.x, vehicle.global_position.z))


## Ethan keys the code in from the driver's seat: his window down, a beep a key, then the gate.
func key_in() -> bool:
	if keying() or _gate_target > 0.0:
		return false
	_keys_left = CODE.length()
	_key_timer = KEY_SECONDS
	if is_instance_valid(vehicle) and float(vehicle.get("left_window_target")) < 0.5:
		vehicle.set("left_window_target", 1.0)
		_window_down = true
	return true


## Whether the van stands parked in the marked bay, square to it.
func in_bay() -> bool:
	if not is_instance_valid(vehicle) or absf(float(vehicle.get("speed"))) > 0.1:
		return false
	var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
	return IN_BAY.has_point(at) and vehicle.global_basis.z.normalized().angle_to(Vector3.BACK) \
		<= SQUARE_IN_BAY


## Whether `at` (Ethan on foot) is at the dark van's driver's door.
func at_dark_door(at: Vector3) -> bool:
	return _dark_van.visible and Vector2(at.x, at.z).distance_to(_flat(DARK_VAN_POSE
		* DRIVER_DOOR)) <= AT_DOOR


## The swap: his van left where it stopped as a parked copy with its load and seal, and the van
## he drives moved to the dark van's place in its paint, empty and unsealed. Returns the copy.
func swap(van: CharacterBody3D) -> Node3D:
	var presentation := van.get_node("VanPresentation")
	var exterior := presentation.call("exterior") as Node3D
	_left = Node3D.new()
	_left.name = "LeftVan"
	add_child(_left)
	_left.global_transform = van.global_transform
	var copy := IVECO.instantiate() as Node3D
	copy.name = "Iveco"
	_left.add_child(copy)
	copy.global_transform = exterior.global_transform
	Presentation.paint_model(copy, presentation.call("paint") as Color)
	_left.set_meta("seal_number", str(van.get("seal_number")))
	_left.set_meta("sealed", bool(van.get("sealed")))
	var holder := van.call("body") as Node3D
	for child in holder.get_children():
		if child.has_meta("strapped") or String(child.name).begins_with("Pallet"):
			(child as Node3D).reparent(_left, true)
	var solid := StaticBody3D.new()
	solid.name = "LeftVanBody"
	_left.add_child(solid)
	var shape := BoxShape3D.new()
	shape.size = _van_box
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = _van_box_at
	solid.add_child(collision)
	van.call("unload")
	van.call("recover", DARK_VAN_POSE)
	presentation.call("set_paint", DARK)
	_dark_van.visible = false
	_dark_body(false)
	swapped.emit(_left)
	return _left


## As a reload at Mission 2's stage 2 finds it: his van in the bay with its load, sealed `seal`,
## and the van he drives the dark one, in its place. `load_van` puts the load in `van` first.
func restore_swapped(van: CharacterBody3D, load_van: Callable) -> void:
	van.call("recover", BAY_POSE)
	load_van.call()
	swap(van)


func left_van() -> Node3D:
	return _left


func _physics_process(delta: float) -> void:
	if _keys_left > 0:
		_key_timer -= delta
		if _key_timer <= 0.0:
			_keys_left -= 1
			_key_timer = KEY_SECONDS
			_beep.play()
			key_beeped.emit()
			if _keys_left == 0:
				_gate_target = GATE_WIDE
	elif _gate_target == 0.0 and _on_exit_loop():
		_gate_target = GATE_WIDE
		_exiting = true
	elif _gate_target > 0.0 and gate_open() and _behind_the_gate():
		_gate_target = 0.0
		_exiting = false
	var moving := not is_equal_approx(_gate_open, _gate_target)
	_gate_open = move_toward(_gate_open, _gate_target, GATE_SPEED * delta)
	_place_gate()
	if moving and not _motor.playing:
		_motor.play()
	elif not moving and _motor.playing:
		_motor.stop()
	if _window_down and gate_open() and is_instance_valid(vehicle):
		_window_down = false
		vehicle.set("left_window_target", 0.0)


## Whether a vehicle leaving opens the gate from inside: its front on the free-exit loop, facing
## out.
func exiting() -> bool:
	return _exiting


func _on_exit_loop() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_front)
	var rear := vehicle.to_global(_rear)
	var over := false
	for step in range(9):
		var at := front.lerp(rear, step / 8.0)
		over = over or EXIT_LOOP.has_point(Vector2(at.x, at.z))
	return over and (-vehicle.global_basis.z.normalized()).z > FACING_OUT


func _behind_the_gate() -> bool:
	if not is_instance_valid(vehicle):
		return true
	var nearest := maxf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z)
	var outside := minf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z)
	if _exiting:
		return outside > YARD.end.y + CLEAR_BEHIND or nearest < EXIT_LOOP.position.y - 2.0
	return nearest < YARD.end.y - CLEAR_BEHIND or outside > STOP_Z + 6.0


func _paving(surface: Material) -> void:
	for rect: Rect2 in [YARD, DRIVEWAY]:
		var slab := Build.box(self, Vector3(rect.get_center().x, PAVING_TOP / 2.0,
			rect.get_center().y), Vector3(rect.size.x, PAVING_TOP, rect.size.y), surface)
		slab.name = "YardPaving"


func _boundary() -> void:
	var fence := Fence.new()
	var west := GATE_X - GATE_WIDE / 2.0
	var east := GATE_X + GATE_WIDE / 2.0
	var runs: Array[Array] = [
		[Vector2(YARD.position.x, YARD.end.y), Vector2(west, YARD.end.y), Vector3.BACK],
		[Vector2(east, YARD.end.y), Vector2(YARD.end.x, YARD.end.y), Vector3.BACK],
		[Vector2(YARD.end.x, YARD.end.y), Vector2(YARD.end.x, YARD.position.y), Vector3.RIGHT],
		[Vector2(YARD.end.x, YARD.position.y), Vector2(YARD.position.x, YARD.position.y),
			Vector3.FORWARD],
		[Vector2(YARD.position.x, YARD.position.y), Vector2(YARD.position.x, YARD.end.y),
			Vector3.LEFT]]
	for run in runs:
		var from: Vector2 = run[0]
		var to: Vector2 = run[1]
		fence.run(self, _body, Vector3(from.x, GROUND, from.y), Vector3(to.x, GROUND, to.y),
			run[2])
		_fence_runs.append({"from": from, "to": to})


func _gate_and_keypad() -> void:
	var fence := Fence.new()
	_gate = AnimatableBody3D.new()
	_gate.name = "Gate"
	add_child(_gate)
	var leaf := GATE_WIDE + TAIL
	var middle := (GATE_WIDE - TAIL) / 2.0
	Build.box(_gate, Vector3(middle, 0.15, 0.0), Vector3(leaf, 0.12, 0.08),
		fence.galvanised).name = "GateBottom"
	Build.box(_gate, Vector3(middle, Fence.HEIGHT, 0.0), Vector3(leaf, 0.08, 0.08),
		fence.galvanised).name = "GateTop"
	for x: float in [-TAIL, 0.0, GATE_WIDE]:
		Build.box(_gate, Vector3(x, Fence.HEIGHT / 2.0, 0.0), Vector3(0.08, Fence.HEIGHT, 0.08),
			fence.galvanised).name = "GateStile"
	var quad := QuadMesh.new()
	quad.size = Vector2(leaf, Fence.HEIGHT - 0.2)
	Build.instance(_gate, Vector3(middle, Fence.HEIGHT / 2.0 + 0.1, 0.0), quad,
		fence.link).name = "GateMesh"
	var shape := BoxShape3D.new()
	shape.size = Vector3(GATE_WIDE, Fence.HEIGHT, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(GATE_WIDE / 2.0, Fence.HEIGHT / 2.0, 0.0)
	_gate.add_child(collision)
	_place_gate()
	for x: float in [GATE_X - GATE_WIDE / 2.0 - 2.0, GATE_X - GATE_WIDE / 2.0 - 7.0]:
		Build.box(self, Vector3(x, 0.4, YARD.end.y - 0.2), Vector3(0.15, 0.8, 0.15),
			fence.galvanised).name = "GateRollerPost"
	var steel := Build.material(Color(0.25, 0.26, 0.27), 0.45)
	steel.metallic = 0.6
	Build.box(self, KEYPAD + Vector3.UP * 0.5, Vector3(0.08, 1.0, 0.08), steel).name = \
		"KeypadPedestal"
	var neck := Build.box(self, KEYPAD + Vector3(0.18, 1.0, 0.0), Vector3(0.4, 0.06, 0.06), steel)
	neck.name = "KeypadNeck"
	var keypad := Build.box(self, KEYPAD + Vector3(0.38, KEYPAD_UP, 0.0), Vector3(0.06, 0.22,
		0.16), Build.material(Color(0.1, 0.1, 0.11), 0.5))
	keypad.name = "Keypad"
	_beep = AudioStreamPlayer3D.new()
	_beep.name = "KeypadBeep"
	_beep.stream = BEEP
	_beep.pitch_scale = 0.6
	_beep.bus = "Ambience"
	_beep.volume_db = -6.0
	add_child(_beep)
	_beep.global_position = keypad.global_position
	_motor = AudioStreamPlayer3D.new()
	_motor.name = "GateMotor"
	_motor.stream = MOTOR
	_motor.pitch_scale = 0.55
	_motor.bus = "Ambience"
	_motor.volume_db = -14.0
	add_child(_motor)
	_motor.global_position = Vector3(GATE_X - GATE_WIDE / 2.0 - 1.0, 0.5, YARD.end.y - 0.4)
	var white := Build.material(Color(0.92, 0.92, 0.9), 0.6)
	Build.box(self, Vector3(GATE_X, PAVING_TOP + 0.003, STOP_Z), Vector3(GATE_WIDE - 0.4, 0.004,
		0.3), white).name = "StopLine"
	_footprints.append(Rect2(KEYPAD.x - 0.1, KEYPAD.z - 0.1, 0.2, 0.2))
	_solid_box(KEYPAD + Vector3.UP * 0.5, Vector3(0.12, 1.0, 0.12))
	Build.box(self, CAMERA_POLE + Vector3.UP * 2.5, Vector3(0.1, 5.0, 0.1), steel).name = \
		"CameraPole"
	Build.box(self, CAMERA_POLE + Vector3(-0.25, 4.9, 0.25), Vector3(0.14, 0.12, 0.3),
		Build.material(Color(0.85, 0.85, 0.82), 0.4)).name = "Camera"
	_footprints.append(Rect2(CAMERA_POLE.x - 0.1, CAMERA_POLE.z - 0.1, 0.2, 0.2))
	_solid_box(CAMERA_POLE + Vector3.UP * 2.5, Vector3(0.1, 5.0, 0.1))
	for sign_item: Array in [["no_entry", GATE_X + GATE_WIDE / 2.0 + 1.5],
			["speed_limit", GATE_X - GATE_WIDE / 2.0 - 1.5]]:
		var plate := MeshInstance3D.new()
		plate.name = "Sign_" + String(sign_item[0])
		var face := QuadMesh.new()
		face.size = Vector2(0.45, 0.56)
		plate.mesh = face
		var paint := StandardMaterial3D.new()
		paint.albedo_texture = load(ART + "%s.png" % sign_item[0]) as Texture2D
		plate.material_override = paint
		add_child(plate)
		plate.global_position = Vector3(float(sign_item[1]), 1.6, YARD.end.y + 0.06)


func _place_gate() -> void:
	if _gate != null:
		_gate.global_position = Vector3(GATE_X - GATE_WIDE / 2.0 - _gate_open, GROUND,
			YARD.end.y - 0.25)


func _containers() -> void:
	var draw := RandomNumberGenerator.new()
	draw.seed = SEED
	var parts := PARTS.instantiate() as Node3D
	var meshes := {}
	for found in parts.find_children("*", "MeshInstance3D", true, false):
		meshes[String(found.name)] = (found as MeshInstance3D).mesh
	parts.free()
	var placed := {}
	var all: Array[Transform3D] = []
	for block: Array in [[WEST_CELLS, 0.0], [EAST_CELLS, PI]]:
		for row in range(ROWS):
			var z := FIRST_ROW + row * ROW_PITCH
			for cell: Array in block[0]:
				var kind := String(cell[0])
				if kind == "Container40" and draw.randf() < 0.3:
					kind = "Container40HC"
				var high := draw.randi_range(2, MOST_HIGH)
				var size: Vector3 = SIZES[kind]
				var y := GROUND + PAVING_TOP
				for level in range(high):
					var at := Transform3D(Basis(Vector3.UP, float(block[1])), Vector3(float(cell[1]),
						y, z))
					if not placed.has(kind):
						placed[kind] = []
					(placed[kind] as Array).append([at, COLOURS[draw.randi() % COLOURS.size()]])
					all.append(at)
					_kinds.append(kind)
					y += size.y
				var rect := Rect2(float(cell[1]) - size.x / 2.0, z - size.z / 2.0, size.x, size.z)
				_footprints.append(rect)
				_solid_box(Vector3(float(cell[1]), (GROUND + PAVING_TOP + y) / 2.0, z),
					Vector3(size.x, y - GROUND - PAVING_TOP, size.z))
	_placed["Containers"] = all
	for kind: String in placed:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = _tinted(meshes[kind] as Mesh)
		multi.instance_count = (placed[kind] as Array).size()
		for index in range(multi.instance_count):
			var entry: Array = placed[kind][index]
			multi.set_instance_transform(index, entry[0])
			multi.set_instance_color(index, entry[1])
		var many := MultiMeshInstance3D.new()
		many.name = kind + "s"
		many.multimesh = multi
		add_child(many)


## The containers' mesh with its paint taking each one's colour from its instance.
func _tinted(mesh: Mesh) -> Mesh:
	var copy := mesh.duplicate() as Mesh
	for index in range(copy.get_surface_count()):
		var made := copy.surface_get_material(index) as BaseMaterial3D
		if made != null and made.resource_name == "paint":
			var paint := made.duplicate() as BaseMaterial3D
			paint.vertex_color_use_as_albedo = true
			copy.surface_set_material(index, paint)
	return copy


func _lights() -> void:
	var steel := Build.material(Color(0.55, 0.56, 0.56), 0.5)
	steel.metallic = 0.6
	for index in range(MASTS.size()):
		var at := MASTS[index]
		Build.cylinder(self, at + Vector3.UP * MAST_TALL / 2.0, 0.16, MAST_TALL, steel).name = \
			"HighMast"
		_solid_box(at + Vector3.UP * 1.0, Vector3(0.4, 2.0, 0.4))
		_footprints.append(Rect2(at.x - 0.2, at.z - 0.2, 0.4, 0.4))
		var aim := Vector3(GATE_X, 0.0, YARD.get_center().y) - at
		var heading := atan2(aim.x, aim.z)
		for side: float in [-0.5, 0.5]:
			var light := SpotLight3D.new()
			light.name = "MastLight%d" % (index * 2 + (0 if side < 0.0 else 1))
			add_child(light)
			var head := at + Vector3.UP * MAST_TALL + Basis(Vector3.UP, heading + side) \
				* Vector3(0.0, 0.0, 0.6)
			light.global_position = head
			light.look_at(head + Basis(Vector3.UP, heading + side) * Vector3(0.0, -MAST_TALL
				* 0.9, 16.0), Vector3.UP)
			light.light_color = Color(1.0, 0.86, 0.66)
			light.light_energy = 6.0
			light.spot_angle = 50.0
			light.spot_range = 45.0
			light.shadow_enabled = false
			Build.box(self, head, Vector3(0.6, 0.25, 0.5), steel).name = "MastLamp"


func _bay_lines() -> void:
	var white := Build.material(Color(0.92, 0.92, 0.9), 0.6)
	var bay := BAY
	for edge: Array in [[Vector2(bay.position.x, bay.get_center().y), Vector2(0.1, bay.size.y)],
			[Vector2(bay.end.x, bay.get_center().y), Vector2(0.1, bay.size.y)],
			[Vector2(bay.get_center().x, bay.position.y), Vector2(bay.size.x, 0.1)]]:
		var at: Vector2 = edge[0]
		var size: Vector2 = edge[1]
		Build.box(self, Vector3(at.x, PAVING_TOP + 0.003, at.y), Vector3(size.x, 0.004, size.y),
			white).name = "BayLine"


func _parked_iveco(label: String, pose: Transform3D, colour: Color) -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	add_child(holder)
	holder.global_transform = pose
	var model := IVECO.instantiate() as Node3D
	model.name = "Iveco"
	holder.add_child(model)
	model.position = Presentation.IVECO_PLACE
	Presentation.paint_model(model, colour)
	var solid := StaticBody3D.new()
	solid.name = label + "Body"
	holder.add_child(solid)
	var shape := BoxShape3D.new()
	shape.size = _van_box
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = _van_box_at
	solid.add_child(collision)
	return holder


func _dark_body(on: bool) -> void:
	var solid := _dark_van.get_node_or_null("DarkVanBody") as StaticBody3D
	if solid != null:
		solid.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		(solid.get_child(0) as CollisionShape3D).disabled = not on


func _solid_box(centre: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = centre
	_body.add_child(collision)


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)
