extends SceneTree
## The van's tail lamps lit as a real van's are (#343, #344): each a whole lamp, its glossy red
## lens showing its prisms and glowing deep red through them with the engine on (a mask of the
## lens's own red sections), the stop at least five times the tail (UN Regulation 7), the clear
## section's chrome reflector flashing amber for its own side's indicator and shining white in
## reverse; the pieces the converter once cut from the red lens wearing the same lamp, so no gaps;
## unlit with the engine off. The brake and indicator are the real keys.

const SHADER := "res://features/vehicles/freight_van/tail_lamp.gdshader"
const MASKS := "res://features/vehicles/freight_van/art/iveco/tail_lamp_masks.png"
const LENS := "res://features/vehicles/freight_van/art/iveco/iveco_exterior_Window_baseColor.webp"
const PIECES: Array[String] = ["TailLamps", "RearIndicatorLeft", "RearIndicatorRight"]
## A face is red lens when its texture is red (its red at least this, and this many times its green
## and blue), chrome reflector when it is solid neutral grey, cover when it is see-through; a mask
## is lit over 0.4.
const RED_LEAST := 0.35
const RED_OVER := 1.8
const LIT := 0.4
const MOST := 0.95
const CHROME_MOST := 0.9
const STOP_OVER_TAIL := 5.0
const FLASHING := 1.5

var _checks := 0
var _failures := 0
var _app: Node3D
var _van: CharacterBody3D
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
	_scratch = OS.get_temp_dir().path_join("blackridge-tail-lamps-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	await process_frame
	_app.call("_resume")
	await _wait_physics(10)
	var meshes: Array[MeshInstance3D] = []
	for label in PIECES:
		var found := _van.find_child(label, true, false) as MeshInstance3D
		if found != null:
			meshes.append(found)
	var lamp := meshes[0].material_override as ShaderMaterial if not meshes.is_empty() else null
	var shared := meshes.size() == 3 and lamp != null and meshes.all(
		func(mesh: MeshInstance3D) -> bool: return mesh.material_override == lamp)
	var drawn := lamp != null and lamp.shader != null and lamp.shader.resource_path == SHADER \
		and _path(lamp, "lens") == LENS and _path(lamp, "masks") == MASKS
	_check(bool(_van.get("engine_on")) and shared and drawn, ("T2: the tail lamps' lens and the "
		+ "two pieces the converter cut from its red lens wear one lamp, drawn by the lamp shader "
		+ "with the lens's own texture and its masks, so the lamps are whole (shared %s, drawn %s)")
		% [shared, drawn])
	var faces := _faces(meshes)
	_check(faces[0] >= MOST and faces[1] >= MOST and faces[2] >= CHROME_MOST and faces[3] >= MOST,
		("T3: the red lens glows through its own prisms (%.0f%% of its red faces in the red mask, "
		+ "%.0f%% of the rest out of it); the clear section's chrome reflector takes the amber and "
		+ "the white (%.0f%% of its faces), the red lens and the clear cover never (%.0f%% out)")
		% [faces[0] * 100.0, faces[1] * 100.0, faces[2] * 100.0, faces[3] * 100.0])
	var tail := _level(lamp, "red")
	await _hold("brake", true)
	await _wait_physics(5)
	var stop := _level(lamp, "red")
	await _hold("brake", false)
	await _wait_physics(5)
	_check(tail > 0.0 and stop >= STOP_OVER_TAIL * tail - 0.0001, ("T4: the engine on, the red "
		+ "lens glows (%.2f), and braking (the brake key held) at least five times as bright "
		+ "(%.2f)") % [tail, stop])
	await _hold("indicator_left", true)
	await _hold("indicator_left", false)
	var left_most := 0.0
	var right_most := 0.0
	var time := 0.0
	while time < FLASHING:
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		left_most = maxf(left_most, _level(lamp, "amber_left"))
		right_most = maxf(right_most, _level(lamp, "amber_right"))
	await _hold("indicator_left", true)
	await _hold("indicator_left", false)
	_check(left_most > 0.0 and right_most == 0.0, ("T5: the left indicator (its key) flashes the "
		+ "left lamp's clear section amber (%.2f at its brightest) and leaves the right's dark "
		+ "(%.2f)") % [left_most, right_most])
	_van.set("gear", -1)
	await _wait_physics(5)
	var reverse := _level(lamp, "reverse")
	_van.set("gear", 1)
	await _wait_physics(5)
	_check(reverse > 0.0 and _level(lamp, "reverse") == 0.0, ("T6: in reverse the clear sections "
		+ "shine white (%.2f), and not in drive") % reverse)
	_van.call("switch_off")
	await _wait_physics(5)
	_check(lamp != null and _level(lamp, "red") == 0.0 and _level(lamp, "amber_left") == 0.0
		and _level(lamp, "amber_right") == 0.0 and _level(lamp, "reverse") == 0.0,
		"T1: with the engine off the tail lamps are unlit, the lens still there to see")
	_finish()


func _level(lamp: ShaderMaterial, name: String) -> float:
	if lamp == null:
		return 0.0
	var value: Variant = lamp.get_shader_parameter(name)
	return float(value) if value != null else 0.0


func _path(lamp: ShaderMaterial, name: String) -> String:
	var texture := lamp.get_shader_parameter(name) as Texture2D
	return texture.resource_path if texture != null else ""


## Shares of the lamps' faces: red faces in the red mask, other faces out of it, chrome faces in
## the clear mask, and red and cover faces out of it.
func _faces(meshes: Array[MeshInstance3D]) -> Array[float]:
	var lens_texture := load(LENS) as Texture2D
	var mask_texture := load(MASKS) as Texture2D if ResourceLoader.exists(MASKS) else null
	if lens_texture == null or mask_texture == null:
		return [0.0, 0.0, 0.0, 0.0]
	var lens := lens_texture.get_image()
	var mask := mask_texture.get_image()
	if lens.is_compressed():
		lens.decompress()
	if mask.is_compressed():
		mask.decompress()
	var counts := [0, 0, 0, 0, 0, 0, 0, 0]
	for mesh in meshes:
		var arrays := mesh.mesh.surface_get_arrays(0)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for face in range(indices.size() / 3):
			var uv := (uvs[indices[face * 3]] + uvs[indices[face * 3 + 1]]
				+ uvs[indices[face * 3 + 2]]) / 3.0
			var colour := _sample(lens, uv)
			var masks := _sample(mask, uv)
			var red := colour.r >= RED_LEAST and colour.r >= RED_OVER * colour.g \
				and colour.r >= RED_OVER * colour.b
			var chrome := not red and colour.a > 0.5 and absf(colour.r - colour.g) < 0.05 \
				and absf(colour.r - colour.b) < 0.05 and colour.r > 0.27 and colour.r < 0.75
			counts[0 if red else 2] += 1
			counts[1 if red else 3] += 1 if (masks.r > LIT) == red else 0
			if chrome:
				counts[4] += 1
				counts[5] += 1 if masks.g > LIT else 0
			else:
				counts[6] += 1
				counts[7] += 1 if masks.g <= LIT else 0
	return [float(counts[1]) / maxi(counts[0], 1), float(counts[3]) / maxi(counts[2], 1),
		float(counts[5]) / maxi(counts[4], 1), float(counts[7]) / maxi(counts[6], 1)]


func _sample(image: Image, uv: Vector2) -> Color:
	var at := Vector2i(int(fposmod(uv.x, 1.0) * (image.get_width() - 1)),
		int(fposmod(uv.y, 1.0) * (image.get_height() - 1)))
	return image.get_pixelv(at)


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
	await process_frame


func _wait_physics(count: int) -> void:
	for step in range(count):
		await physics_frame


func _finish() -> void:
	print("TAIL LAMPS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The tail lamp test finished within 120 s of game time")
	quit(1)
