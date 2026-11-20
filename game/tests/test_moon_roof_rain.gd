extends SceneTree
## The rain lands on the van's moon roof, not in its cab (#330): the converter cuts the moon
## roof's opening through the roof, and its glass is see-through, which a lamp rain's height-field
## collider never takes, so a collider of its own, as the windshield has, lies under the glass.
## Its top face is just over the glass, it covers the whole opening, it rides with the van, it
## stops every lamp's rain and its splashes, and it leaves the passenger blade's water alone.

const VanParticles = preload("res://features/vehicles/freight_van/van_particles.gd")
const SKIN_MOST := 0.01
const DEPTH_LEAST := 0.2

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-moon-roof-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var van := _app.get_node("FreightVan") as Node3D
	var glass := van.find_child("MoonRoofGlass", true, false) as MeshInstance3D
	var corners := _corners(glass)
	var found: GPUParticlesCollisionBox3D = null
	for node in van.find_children("*", "GPUParticlesCollisionBox3D", true, false):
		if _covers(node as GPUParticlesCollisionBox3D, corners):
			found = node
	_check(found != null, ("R1: a collider in the van covers the whole moon roof opening, its top "
		+ "face no more than %.0f mm over the glass and at least %.1f m deep, so a drop falling "
		+ "8.5 m/s cannot pass it in a tick") % [SKIN_MOST * 1000.0, DEPTH_LEAST])
	var mask := found.cull_mask if found != null else 0
	var lamps := _app.get_node("IndustrialLoop/LampRain") as Node3D
	var rains := lamps.find_children("LampRain", "GPUParticles3D", true, false)
	var splashes := lamps.find_children("LampSplash", "GPUParticles3D", true, false)
	var stops := not rains.is_empty() and (rains + splashes).all(
		func(rain: GPUParticles3D) -> bool: return mask & rain.layers != 0)
	_check(stops, ("R2: it stops every lamp's rain and splashes (%d rain volumes)")
		% rains.size())
	_check(found != null and mask & VanParticles.PASSENGER_LAYER == 0,
		"R3: it leaves the passenger blade's water alone, as the windshield's colliders do")
	van.call("recover", Transform3D(Basis(Vector3.UP, 1.1), Vector3(-47.75, 0.1, 23.0)))
	await physics_frame
	await physics_frame
	_check(found != null and _covers(found, _corners(glass)),
		"R4: it rides with the van: still over the opening after the van is moved and turned")
	_finish()


## The glass's four corners in the world.
func _corners(glass: MeshInstance3D) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	if glass == null:
		return corners
	var half := (glass.mesh as QuadMesh).size * 0.5
	for x in [-half.x, half.x]:
		for y in [-half.y, half.y]:
			corners.append(glass.global_transform * Vector3(x, y, 0.0))
	return corners


func _covers(box: GPUParticlesCollisionBox3D, corners: Array[Vector3]) -> bool:
	if corners.is_empty() or box.size.y < DEPTH_LEAST:
		return false
	var half := box.size * 0.5
	for corner in corners:
		var local := box.global_transform.affine_inverse() * corner
		if absf(local.x) > half.x or absf(local.z) > half.z:
			return false
		if local.y > half.y or local.y < half.y - SKIN_MOST:
			return false
	return true


func _finish() -> void:
	print("MOON ROOF RAIN RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The moon roof rain test finished within 120 s of game time")
	quit(1)
