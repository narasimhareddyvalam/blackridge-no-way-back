extends AnimatableBody3D

signal passed

const Build = preload("res://shared/components/mesh_builder.gd")
const BODY_ART = preload("res://features/vehicles/freight_van/art/body.glb")
const DOOR_ART = preload("res://features/vehicles/freight_van/art/door.glb")
const TIRE_ART = preload("res://features/vehicles/freight_van/art/tire.glb")
const LOW_BEAM = preload("res://features/vehicles/freight_van/art/low_beam_pattern.png")
const HIGH_BEAM = preload("res://features/vehicles/freight_van/art/high_beam_pattern.png")
const SPACING := 2.0
const CRUISE := 11.1
const BEND_GRIP := 2.5
const LOOK_AHEAD := 15.0
const ACCELERATION := 2.0
const BRAKING := 6.0
const EASE := 3.0
const KEEP_RIGHT := 0.95
const CLEARANCE := 2.55
const LENGTH := 5.3
const BUMPERS := 4.7
const STOP_GAP := 2.5
const LAMPS: Array[Vector3] = [Vector3(-0.86, 1.18, -2.44), Vector3(0.86, 1.18, -2.44)]
const WHEELS: Array[Vector3] = [Vector3(-1.15, 0.48, -1.52), Vector3(1.15, 0.48, -1.52),
	Vector3(-1.15, 0.48, 1.85), Vector3(1.15, 0.48, 1.85)]
const LOW_RANGE := 120.0
const HIGH_RANGE := 220.0
const HIGH_POWER := 3.2
const SEES := 150.0
const FLASHES := 2
const FLASH_SECONDS := 0.35
const FLARE_SIZE := 0.045
const FLARE_LEVEL := 6.0
const FLARE_FALLOFF := 30.0
const PAINT := Color("2b3238")
const LENS_GLOW := 30.0

var road: RefCounted
var opponent: Node3D
var lamps: Array[SpotLight3D] = []
var high_beams: bool = false
var speed: float = CRUISE
var distance: float = 0.0
var end_distance: float = 0.0
var _flares: Array[MeshInstance3D] = []
var _flare_material := StandardMaterial3D.new()
var _wheels: Array[Node3D] = []
var _flash_time: float = -1.0
var _flashed: bool = false
var _passed: bool = false


func configure(ghat_road: RefCounted, player: Node3D, start_index: int, end_index: int) -> void:
	road = ghat_road
	opponent = player
	distance = start_index * SPACING
	end_distance = end_index * SPACING
	collision_layer = 3
	collision_mask = 0
	sync_to_physics = false
	_build()
	global_transform = _pose()


func beam_power() -> float:
	return HIGH_POWER if high_beams else 1.0


func _build() -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.8, 5.3)
	collision.shape = box
	collision.position = Vector3(0.0, 1.55, 0.3)
	add_child(collision)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = PAINT
	paint.roughness = 0.34
	for art: PackedScene in [BODY_ART, DOOR_ART]:
		var part := art.instantiate()
		add_child(part)
		for mesh: MeshInstance3D in part.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var material := mesh.mesh.surface_get_material(surface)
				if material != null and material.resource_name.ends_with("Paint"):
					mesh.set_surface_override_material(surface, paint)
	for spot in WHEELS:
		var pivot := Node3D.new()
		pivot.position = spot
		add_child(pivot)
		pivot.add_child(TIRE_ART.instantiate())
		_wheels.append(pivot)
	var lens := Build.luminous(Color("e9ebdc"), LENS_GLOW)
	var tail := Build.luminous(Color("68251e"))
	var halo := GradientTexture2D.new()
	halo.gradient = Gradient.new()
	halo.gradient.set_color(0, Color(1.0, 0.97, 0.9, 1.0))
	halo.gradient.set_color(1, Color(1.0, 0.9, 0.75, 0.0))
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(0.5, 0.0)
	_flare_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flare_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flare_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flare_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_flare_material.fixed_size = true
	_flare_material.albedo_texture = halo
	_flare_material.disable_fog = true
	var flare := QuadMesh.new()
	flare.size = Vector2.ONE * FLARE_SIZE
	for at in LAMPS:
		Build.box(self, at + Vector3(0.0, 0.0, 0.03), Vector3(0.24, 0.07, 0.02), lens)
		Build.box(self, Vector3(at.x * 1.2, 1.35, 2.91), Vector3(0.18, 0.36, 0.06), tail)
		var lamp := SpotLight3D.new()
		lamp.position = at
		lamp.rotation_degrees.x = -2.0
		lamp.light_color = Color("fff0db")
		lamp.light_energy = 650.0
		lamp.spot_angle = 35.0
		lamp.spot_angle_attenuation = 0.2
		lamp.spot_attenuation = 1.0
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 5
		add_child(lamp)
		lamps.append(lamp)
		var glow := Build.instance(self, at, flare, _flare_material)
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_flares.append(glow)
	_set_high(false)


func _physics_process(delta: float) -> void:
	var target := minf(CRUISE, _bend_speed())
	var room := _room_ahead()
	target = minf(target, sqrt(2.0 * EASE * maxf(room - STOP_GAP, 0.0)))
	speed = move_toward(speed, target, (ACCELERATION if target > speed else BRAKING) * delta)
	distance -= speed * delta
	global_transform = _pose()
	for wheel in _wheels:
		wheel.rotation.x -= speed * delta / 0.46
	_signal_high_beams(delta)
	if not _passed and to_local(opponent.global_position).z > LENGTH:
		_passed = true
		passed.emit()
	if distance <= end_distance:
		queue_free()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for index in range(lamps.size()):
		var lamp := lamps[index]
		var to_camera := camera.global_position - lamp.global_position
		var facing := maxf(0.0, (-lamp.global_basis.z).dot(to_camera.normalized()))
		var level := beam_power() * pow(facing, 4.0) * FLARE_LEVEL / (
			1.0 + pow(to_camera.length() / FLARE_FALLOFF, 2.0))
		_flares[index].global_position = lamp.global_position + to_camera.normalized() * 0.5
		_flares[index].visible = level > 0.01
		_flare_material.albedo_color = Color(level, level * 0.96, level * 0.88)


func _pose() -> Transform3D:
	var centre := _point_at(distance)
	var ahead := _point_at(distance - 3.0) - _point_at(distance + 3.0)
	var heading := ahead.normalized()
	var right := heading.cross(Vector3.UP).normalized()
	var at := centre + right * (_half_width_at(distance) - KEEP_RIGHT)
	return Transform3D(Basis.looking_at(heading, Vector3.UP), at)


func _point_at(along: float) -> Vector3:
	var points: PackedVector3Array = road.points
	var index := clampi(int(along / SPACING), 0, points.size() - 2)
	return points[index].lerp(points[index + 1], clampf(along / SPACING - index, 0.0, 1.0))


func _half_width_at(along: float) -> float:
	var widths: PackedFloat32Array = road.half_widths
	var index := clampi(int(along / SPACING), 0, widths.size() - 2)
	return lerpf(widths[index], widths[index + 1], clampf(along / SPACING - index, 0.0, 1.0))


func _bend_speed() -> float:
	var here := _point_at(distance + 2.0) - _point_at(distance - 2.0)
	var later := _point_at(distance - LOOK_AHEAD + 2.0) - _point_at(distance - LOOK_AHEAD - 2.0)
	var turn := absf(Vector2(here.x, here.z).angle_to(Vector2(later.x, later.z)))
	if turn < 0.01:
		return CRUISE
	return sqrt(BEND_GRIP * LOOK_AHEAD / turn)


func _room_ahead() -> float:
	var local := to_local(opponent.global_position)
	if local.z > 0.0 or absf(local.x) > CLEARANCE:
		return INF
	return -local.z - BUMPERS


func _signal_high_beams(delta: float) -> void:
	var to_player := opponent.global_position - global_position
	var sees := to_player.length() < SEES and (-global_basis.z).dot(to_player.normalized()) > 0.85
	if not _flashed and sees and opponent.get("headlights_on") and opponent.get("high_beams"):
		_flashed = true
		_flash_time = 0.0
	if _flash_time < 0.0:
		return
	_flash_time += delta
	var phase := int(_flash_time / FLASH_SECONDS)
	_set_high(phase < FLASHES * 2 and phase % 2 == 0)
	if phase >= FLASHES * 2:
		_flash_time = -1.0


func _set_high(value: bool) -> void:
	high_beams = value
	for lamp in lamps:
		lamp.light_projector = HIGH_BEAM if value else LOW_BEAM
		lamp.spot_range = HIGH_RANGE if value else LOW_RANGE
