extends SceneTree

const MirrorGlass = preload("res://features/vehicles/freight_van/mirror_glass.gd")
const MIRROR_SHADER := "res://features/vehicles/freight_van/mirror_glass.gdshader"
const SHINE := "res://features/vehicles/freight_van/art/iveco/iveco_exterior_Front_door_metallicRoughness.webp"
const DOORS: Array[String] = ["DriverDoor", "PassengerDoor"]
const HEADS: Array[String] = ["DriverMirrorHead", "PassengerMirrorHead"]
const PASSENGER_IN_SIGHT := 58
const PASSENGER_FACING := 50.0
const MIRROR_LAYER := 8
const TILE := 1.8

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-mirrors-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	_app.call("_resume")
	await _ticks(5)
	_check_fit()
	await _check_layers()
	_check_hdr()
	_check_aim()
	_check_passenger_in_sight()
	await _check_door()
	await _check_rates()
	_check_moon()
	await _check_tail_glow()
	_check_gravel()
	_finish()


func _check_fit() -> void:
	var shine := Image.load_from_file(ProjectSettings.globalize_path(SHINE))
	var iveco := _presentation.find_child("Iveco", true, false) as Node3D
	for index in range(DOORS.size()):
		var door := iveco.get_node(DOORS[index]) as MeshInstance3D
		var carrier := iveco.get_node_or_null(HEADS[index]) as MeshInstance3D
		if carrier == null:
			carrier = door
		var place := iveco.global_transform.affine_inverse() * door.global_transform
		var truth := MirrorGlass.select(carrier, place, shine)
		var surfaces := _surfaces(index)
		var counts := PackedStringArray()
		var fits := surfaces.size() == 2 and truth.get_surface_count() == 2
		var gaps: Array[float] = []
		for piece in range(mini(surfaces.size(), truth.get_surface_count())):
			var real: PackedVector3Array = truth.surface_get_arrays(piece)[Mesh.ARRAY_VERTEX]
			var copy: PackedVector3Array = surfaces[piece].mesh.surface_get_arrays(0)[
				Mesh.ARRAY_VERTEX]
			counts.append("%d" % (real.size() / 3))
			fits = fits and real.size() == copy.size() and real.size() > 90
			if real.size() != copy.size():
				continue
			for vertex in range(real.size()):
				var gap := (surfaces[piece].global_transform * copy[vertex]).distance_to(
					carrier.global_transform * real[vertex])
				gaps.append(gap)
				fits = fits and gap > 0.001 and gap < 0.003
		var largest: float = gaps.max() if not gaps.is_empty() else INF
		_check(fits, "The %s mirror shows its reflection on the Iveco's own glass: %s main and "
			% ["left" if index == 0 else "right", counts[0] if counts.size() > 0 else "0"]
			+ "%s wide-angle triangles, at most %.1f mm in front of it"
			% [counts[1] if counts.size() > 1 else "0", largest * 1000.0])


func _check_layers() -> void:
	var camera: Camera3D = _presentation.get("driving_camera")
	var only_driver := camera.cull_mask & MIRROR_LAYER != 0
	var count := 0
	for index in range(2):
		for surface in _surfaces(index):
			only_driver = only_driver and surface.layers == MIRROR_LAYER
			count += 1
	for other: Camera3D in _presentation.get("mirror_cameras"):
		only_driver = only_driver and other.cull_mask & MIRROR_LAYER == 0
	var iveco := _presentation.find_child("Iveco", true, false) as Node3D
	for door_name in DOORS:
		only_driver = only_driver and (iveco.get_node(door_name) as GeometryInstance3D).layers == 2
	var screens := 0
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var surface := (found as MeshInstance3D).material_override as ShaderMaterial
		if surface == null or surface.get_shader_parameter("display") == null:
			continue
		for view: SubViewport in _presentation.get("mirrors"):
			if surface.get_shader_parameter("display") == view.get_texture():
				screens += 1
	_van.set("occupied", false)
	await _ticks(2)
	var hidden := true
	for index in range(2):
		for surface in _surfaces(index):
			hidden = hidden and not surface.visible
	_van.set("occupied", true)
	await _ticks(2)
	for index in range(2):
		for surface in _surfaces(index):
			hidden = hidden and surface.visible
	_check(only_driver and hidden and count == 4 and screens == 0, "From outside the mirrors are "
		+ "the van's own dark glass, not screens: the %d reflections draw only for the " % count
		+ "driver's eye, and only while he sits in the seat")


func _check_hdr() -> void:
	var views: Array = _presentation.get("mirrors")
	var hdr := views.size() == 2
	var reflectance := 0.0
	var pixels := 0
	for index in range(views.size()):
		var view: SubViewport = views[index]
		var camera := view.get_camera_3d()
		var environment := camera.environment if camera != null else null
		pixels = maxi(view.size.x, view.size.y)
		hdr = hdr and view.use_hdr_2d and environment != null \
			and environment.tonemap_mode == Environment.TONE_MAPPER_LINEAR and pixels >= 600
		for surface in _surfaces(index):
			var material := surface.material_override as ShaderMaterial
			hdr = hdr and material.shader.resource_path == MIRROR_SHADER \
				and material.get_shader_parameter("reflection") == view.get_texture()
			if environment != null:
				reflectance = float(material.get_shader_parameter("gain")) \
					* environment.tonemap_exposure
		hdr = hdr and reflectance > 0.4 and reflectance < 0.9
	_check(hdr, "Lamps behind stay bright and the dark stays dark: each mirror renders in HDR at "
		+ "%d pixels, tone-mapped once, reflecting %.0f%% like chrome glass" % [pixels,
		reflectance * 100.0])


func _check_aim() -> void:
	var main := _angles(0, 0)
	var wide := _angles(0, 1)
	for index in range(2):
		var glass := _angles(index, 0)
		var set: bool = not glass.is_empty() and glass.across.x < -1.8 and glass.across.x > -10.0 \
			and glass.across.y > 8.0 and glass.up.y > 0.0 and glass.up.x < -10.0
		var inner: float = glass.across.x if not glass.is_empty() else 0.0
		_check(set, "The %s mirror is set as a driver sets it: from %.1f degrees %s the van's "
			% ["driver's" if index == 0 else "passenger's", absf(inner),
			"inside" if inner < 0.0 else "outside"] + "side, so the side shows along its inner "
			+ "edge, to %.1f outside, with the horizon in its upper part"
			% (glass.across.y if not glass.is_empty() else 0.0))
	var spread: bool = not main.is_empty() and not wide.is_empty() \
		and wide.across.y - wide.across.x > 2.0 * (main.across.y - main.across.x) \
		and (wide.up.x + wide.up.y) < (main.up.x + main.up.y)
	_check(spread, "The wide-angle glass below shows a wider, smaller view of the van's side and "
		+ "the ground: %.1f degrees across, against %.1f for the main glass" % [
		(wide.across.y - wide.across.x) if not wide.is_empty() else 0.0,
		(main.across.y - main.across.x) if not main.is_empty() else 0.0])


func _angles(index: int, piece: int) -> Dictionary:
	var surfaces := _surfaces(index)
	var views: Array = _presentation.get("mirrors")
	if surfaces.size() < 2 or views.size() < 2:
		return {}
	var view: SubViewport = views[index]
	var camera := view.get_camera_3d()
	var arrays := surfaces[piece].mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var outward := -1.0 if index == 0 else 1.0
	var across := Vector2(INF, -INF)
	var up := Vector2(INF, -INF)
	for uv in uvs:
		var ray := camera.project_ray_normal(uv * Vector2(view.size))
		var local := _van.global_basis.inverse() * ray
		var side := rad_to_deg(atan2(outward * local.x, local.z))
		var height := rad_to_deg(asin(clampf(local.y, -1.0, 1.0)))
		across = Vector2(minf(across.x, side), maxf(across.y, side))
		up = Vector2(minf(up.x, height), maxf(up.y, height))
	return {"across": across, "up": up}


func _check_passenger_in_sight() -> void:
	var camera: Camera3D = _presentation.get("driving_camera")
	var eye := camera.global_position
	var targets: Array[Vector3] = []
	var facing := 0.0
	for surface in _surfaces(1):
		var points := surface.mesh.get_faces()
		var normal := Vector3.ZERO
		var centre := Vector3.ZERO
		for index in range(0, points.size(), 3):
			var a := surface.global_transform * points[index]
			var b := surface.global_transform * points[index + 1]
			var c := surface.global_transform * points[index + 2]
			targets.append((a + b + c) / 3.0)
			normal += -(b - a).cross(c - a)
			centre += (a + b + c) / 3.0
		if surface.name == "MainGlass":
			centre /= points.size() / 3.0
			facing = rad_to_deg(normal.normalized().angle_to(eye - centre))
	var reach := AABB(eye, Vector3.ZERO)
	for target in targets:
		reach = reach.expand(target)
	reach = reach.grow(0.05)
	var faces: Array[PackedVector3Array] = []
	for found in _presentation.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		if part.mesh == null or not part.is_visible_in_tree() or part.material_override is ShaderMaterial \
				or (part.layers & camera.cull_mask) == 0 or _see_through(part):
			continue
		var triangles := part.mesh.get_faces()
		for index in range(0, triangles.size(), 3):
			var face := PackedVector3Array([part.global_transform * triangles[index],
				part.global_transform * triangles[index + 1], part.global_transform * triangles[index + 2]])
			if AABB(face[0], Vector3.ZERO).expand(face[1]).expand(face[2]).intersects(reach):
				faces.append(face)
	var seen := 0
	for target in targets:
		var from := target + (eye - target).normalized() * 0.003
		var direction := (eye - from).normalized()
		var blocked := false
		for face in faces:
			if Geometry3D.ray_intersects_triangle(from, direction, face[0], face[1], face[2]) != null \
					and from.distance_to(Geometry3D.ray_intersects_triangle(from, direction, face[0],
					face[1], face[2])) < from.distance_to(eye):
				blocked = true
				break
		if not blocked:
			seen += 1
	_check(seen >= PASSENGER_IN_SIGHT and facing > 0.0 and facing < PASSENGER_FACING,
		"The passenger mirror is turned toward the driver, so it shows through the window's front "
		+ "corner: %d of its %d glass triangles in sight from the seat, " % [seen, targets.size()]
		+ "seen %.0f degrees off its face" % facing)


func _see_through(part: MeshInstance3D) -> bool:
	for surface in range(part.mesh.get_surface_count()):
		var material := part.get_active_material(surface) as BaseMaterial3D
		if material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return true
	return false


func _check_door() -> void:
	var glass: Node3D = _presentation.get("_door_glass")
	var surfaces := _surfaces(0)
	var views: Array = _presentation.get("mirrors")
	if surfaces.is_empty() or views.is_empty():
		_check(false, "The driver's mirror swings with the door, glass and view together")
		return
	var camera := (views[0] as SubViewport).get_camera_3d()
	var shut := glass.global_transform.affine_inverse() * camera.global_transform
	var facing := camera.global_basis.z
	_van.set("driver_door", 1.0)
	await _ticks(3)
	var opened := glass.global_transform.affine_inverse() * camera.global_transform
	var turned := rad_to_deg(facing.angle_to(camera.global_basis.z))
	_van.set("driver_door", 0.0)
	await _ticks(3)
	var together := glass.is_ancestor_of(surfaces[0]) and glass.is_ancestor_of(surfaces[1]) \
		and opened.origin.distance_to(shut.origin) < 0.001 and turned > 25.0
	_check(together, "The driver's mirror swings with the door, glass and view together "
		+ "(%.0f degrees)" % turned)


func _check_rates() -> void:
	var counts: Variant = _presentation.get("mirror_updates")
	if not counts is Array or (counts as Array).size() < 2:
		_check(false, "The driver's mirror updates 30 times a second and the passenger's 15")
		return
	var before: Array[int] = [counts[0], counts[1]]
	await _ticks(120)
	var after: Array = _presentation.get("mirror_updates")
	var driver: int = after[0] - before[0]
	var passenger: int = after[1] - before[1]
	_check(absi(driver - 60) <= 1 and absi(passenger - 30) <= 1,
		"The driver's mirror updates 30 times a second and the passenger's 15 (%d and %d in "
		% [driver, passenger] + "2.0 s); today's mirrors shared 45 between them")


func _check_moon() -> void:
	var moon: DirectionalLight3D = null
	for light in _app.find_children("*", "DirectionalLight3D", true, false):
		moon = light as DirectionalLight3D
	var camera: Camera3D = _presentation.get("driving_camera")
	var world := _van.get_world_3d().environment
	var skipped := moon != null and moon.shadow_enabled and moon.layers & camera.cull_mask != 0
	var views: Array = _presentation.get("mirrors")
	for view: SubViewport in views:
		var mirror := view.get_camera_3d()
		skipped = skipped and mirror.cull_mask & moon.layers == 0 and mirror.environment != null \
			and world != null and mirror.environment.ambient_light_energy \
			> world.ambient_light_energy
	_check(skipped and views.size() == 2, "The mirror cameras skip the moon and its shadow pass, "
		+ "with a soft fill in its place; the driver's own view keeps the moonlight and its shadows")


func _check_tail_glow() -> void:
	var glows: Array[SpotLight3D] = []
	for found in _van.find_children("TailGlow*", "SpotLight3D", true, false):
		glows.append(found as SpotLight3D)
	var red := glows.size() == 2
	for glow in glows:
		var aim := _van.global_basis.inverse() * -glow.global_basis.z
		red = red and aim.z > 0.8 and glow.light_color.r > 0.9 and glow.light_color.g < 0.2 \
			and not glow.shadow_enabled
	await _ticks(2)
	var running := _lit(glows)
	Input.action_press("brake")
	await _ticks(3)
	var braking := _lit(glows)
	Input.action_release("brake")
	_van.set("engine_on", false)
	await _ticks(3)
	var dark := _lit(glows)
	_van.set("engine_on", true)
	await _ticks(3)
	_check(red and running > 0.0 and braking > 2.0 * running and dark == 0.0,
		"The tail lamps cast a faint red glow on the road behind (%.1f), brighter when braking "
		% running + "(%.1f), and none with the engine off" % braking)


func _lit(glows: Array[SpotLight3D]) -> float:
	var total := 0.0
	for glow in glows:
		if glow.is_visible_in_tree():
			total += glow.light_energy
	return total


func _check_gravel() -> void:
	var grounds := 0
	var real_size := true
	var world := _app.get_node("IndustrialLoop")
	for node in world.get_children():
		if not node is MeshInstance3D or not (node as MeshInstance3D).mesh is BoxMesh:
			continue
		var surface := (node as MeshInstance3D).material_override as BaseMaterial3D
		if surface == null or surface.albedo_texture == null \
				or not surface.albedo_texture.resource_path.contains("leaf_scattered_gravel"):
			continue
		grounds += 1
		real_size = real_size and surface.uv1_triplanar and surface.uv1_world_triplanar \
			and absf(surface.uv1_scale.x - 1.0 / TILE) < 0.001
	_check(grounds == 2 and real_size, "The lumber yard's and the forecourt's gravel lies at real "
		+ "size, %.1f m to a tile, projected in metres (%d surfaces)" % [TILE, grounds])


func _surfaces(index: int) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	var views: Array = _presentation.get("mirrors")
	if index >= views.size():
		return found
	var texture := (views[index] as SubViewport).get_texture()
	for node in _presentation.find_children("*", "MeshInstance3D", true, false):
		var surface := (node as MeshInstance3D).material_override as ShaderMaterial
		if surface != null and surface.get_shader_parameter("reflection") == texture:
			found.append(node as MeshInstance3D)
	return found


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame


func _finish() -> void:
	print("MIRRORS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Mirror test finished within 100 s of game time")
	quit(1)
