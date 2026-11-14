extends SceneTree
## #270-#278 (docs/PHASE_BRIEF.md): the wet ground of the rainy night, read from the running
## game on Mission 2's start save: the road, the freight depot's yard and the dock apron drawn by
## `wet_ground.gdshader`, drenched, their puddles rippled and reflecting, the whole wet film
## reflecting too; the road telling the shader where across it each point is, so water lies at
## its edges and in its wheel paths; the apron draining to its slot drain, its 15 ft joints; the
## lamps' cones lit four times brighter by the rain in them. A headless run draws nothing, so the
## look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const WET := "res://features/environments/industrial_loop/wet_ground.gdshader"
const POROSITY := {"road": 0.7, "yard": 0.7, "apron": 0.5}
const PUDDLES := 0.08
const APRON_DRAIN := Vector2(-90.0, 35.0)
const JOINTS := 180 * 0.0254
const SCATTERING := 0.016

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-wet-%d-%d.cfg" % [OS.get_process_id(),
		Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(START_SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	var world := _app.get_node("IndustrialLoop") as Node3D
	var grounds := {"road": null, "yard": null, "apron": null}
	var meshes := {}
	for found in world.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var paint := mesh.get_active_material(0) as ShaderMaterial
		if paint == null or paint.shader == null or paint.shader.resource_path != WET:
			continue
		var key := "road" if mesh.get_aabb().size.y > 10.0 else ("yard" if mesh.name == "DepotYard"
			else ("apron" if mesh.name == "DockApron" else ""))
		if key != "":
			grounds[key] = paint
			meshes[key] = mesh
	var faults: Array[String] = []
	for key: String in grounds:
		var paint: ShaderMaterial = grounds[key]
		if paint == null:
			faults.append("no wet %s" % key)
			continue
		var wet: Variant = paint.get_shader_parameter("wetness")
		var porous: Variant = paint.get_shader_parameter("porosity")
		var rippled: Variant = paint.get_shader_parameter("puddle_roughness")
		var mirrors: Variant = paint.get_shader_parameter("puddle_reflections")
		var film: Variant = paint.get_shader_parameter("film_reflections")
		if (wet != null and float(wet) < 0.9) or porous == null \
				or absf(float(porous) - float(POROSITY[key])) > 0.001 \
				or (rippled != null and absf(float(rippled) - PUDDLES) > 0.001) \
				or mirrors == false or film == false or paint.get_shader_parameter("rain_ripples") == null:
			faults.append("%s: wet %s, porous %s, puddles %s, reflections %s and %s" % [key, wet,
				porous, rippled, mirrors, film])
	_check(faults.is_empty(), ("G1: the road, the depot yard and the dock apron are drawn wet by "
		+ "wet_ground.gdshader: drenched, asphalt 0.7 and concrete 0.5 porous, their puddles "
		+ "rippled (%.2f) and reflecting, the whole wet film reflecting, the rain's ripples drawn "
		+ "(%s)") % [PUDDLES, "so" if faults.is_empty() else "; ".join(faults)])
	var uniforms := (load(WET) as Shader).get_shader_uniform_list().map(func(u: Dictionary) -> String:
		return String(u["name"]))
	var defaults := true
	for name in ["puddle_roughness", "film_reflections", "puddle_reflections", "slab", "drain",
			"joint_spacing", "porosity", "wetness", "rain_intensity"]:
		defaults = defaults and uniforms.has(name)
	var code := (load(WET) as Shader).code
	var rough := RegEx.create_from_string("uniform float puddle_roughness[^=]*= ([0-9.]+);")
	var film := RegEx.create_from_string("uniform bool film_reflections = (true|false);")
	var rough_found := rough.search(code)
	var film_found := film.search(code)
	defaults = defaults and rough_found != null \
		and is_equal_approx(rough_found.get_string(1).to_float(), PUDDLES) \
		and film_found != null and film_found.get_string(1) == "true"
	_check(defaults, "G2: the shader compiles with its drainage, puddle and reflection settings, "
		+ "its puddles rippled and its film reflecting by default")
	var road := meshes.get("road") as MeshInstance3D
	var placed := false
	if road != null:
		var arrays := road.mesh.surface_get_arrays(0)
		var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] \
			!= null else PackedColorArray()
		var low := 1.0
		var high := 0.0
		var widest := 0.0
		for colour in colours:
			low = minf(low, colour.r)
			high = maxf(high, colour.r)
			widest = maxf(widest, colour.g * 8.0)
		placed = colours.size() > 0 and low < 0.01 and high > 0.99 and widest > 2.2 \
			and widest < 6.0
	_check(placed, "G3: the road tells the shader where across it each point is (0 at its left "
		+ "edge, 1 at its right) and its half width, so water lies at its edges and in its wheel "
		+ "paths")
	var apron: ShaderMaterial = grounds["apron"]
	var drains := apron != null and bool(apron.get_shader_parameter("slab")) \
		and Vector2((apron.get_shader_parameter("drain") as Vector4).x,
		(apron.get_shader_parameter("drain") as Vector4).y).distance_to(APRON_DRAIN) < 0.01 \
		and float(apron.get_shader_parameter("drain_reach")) > 0.0 \
		and absf(float(apron.get_shader_parameter("joint_spacing")) - JOINTS) < 0.001
	_check(drains, "G4: the dock apron drains to the slot drain along its outer edge and holds "
		+ "water in its saw-cut joints every 15 ft")
	var mists := 0
	var bright := 0
	for found in world.find_children("Mist", "MeshInstance3D", true, false):
		var air := (found as MeshInstance3D).material_override as ShaderMaterial
		if air == null:
			air = (found as MeshInstance3D).get_active_material(0) as ShaderMaterial
		if air != null:
			mists += 1
			var scattering: Variant = air.get_shader_parameter("scattering")
			if scattering != null and is_equal_approx(float(scattering), SCATTERING):
				bright += 1
	_check(mists > 0 and bright == mists, ("G5: every lamp's cone is lit by the rain in it four "
		+ "times its old haze (%d of %d)") % [bright, mists])
	_finish()


func _timeout() -> void:
	_check(false, "The wet ground's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("WET GROUND RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
