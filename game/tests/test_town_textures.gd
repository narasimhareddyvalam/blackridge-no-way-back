extends SceneTree
## The town station's textured surfaces carry their textures (found recording Mission 2, #451:
## the log read "Resource file not found: .../polyhaven/models/textures/weathered_plank_siding/
## weathered_plank_siding_diff_2k.jpg"; the bench's slats were built from a path one folder too
## deep, so they drew untextured). T1: every world-mapped (triplanar) material in the town has its
## colour texture; T2: the bench's slats have their wood's colour and normal textures.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-town-textures-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	var town := app.get_node("IndustrialLoop").find_child("TownStation", true, false) as Node3D
	var untextured: Array[String] = []
	for mesh: MeshInstance3D in town.find_children("*", "MeshInstance3D", true, false):
		var material := _material(mesh)
		if material != null and material.uv1_triplanar and material.albedo_texture == null:
			untextured.append(String(town.get_path_to(mesh)))
	_check(untextured.is_empty(), "T1 every world-mapped surface in the town is textured "
		+ "(untextured: %s)" % ", ".join(untextured.slice(0, 6)))
	var bench := town.find_child("Bench", true, false) as Node3D
	var slats := 0
	var wood := 0
	for mesh: MeshInstance3D in bench.find_children("*", "MeshInstance3D", true, false):
		var material := _material(mesh)
		if material != null and material.uv1_triplanar:
			slats += 1
			if material.albedo_texture != null and material.normal_texture != null:
				wood += 1
	_check(slats > 0 and wood == slats, "T2 the bench's %d slats have the wood's colour and "
		% slats + "normal textures (%d do)" % wood)
	print("TOWN TEXTURES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)


func _material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var material := mesh.material_override
	if material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
		material = mesh.get_active_material(0)
	return material as StandardMaterial3D
