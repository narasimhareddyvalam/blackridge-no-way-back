extends SceneTree
## The container yard as real depots are (the audit, #351, after Commons photos; the author's
## choices): every box marked as ISO 6346 has it, its owner code and serial with a check digit
## that checks, its size-type code (22G1, 42G1, 45G1) and its weights, its line's name on its
## sides, no two boxes alike, and weathered, each its own; a container top-loader parked by the
## stacks, its spreader drawn in to 20 ft, out of the van's way; and the high masts lit by real
## flood heads, four a mast, lighting the lane.

const PAINT_SHADER := "res://features/environments/industrial_loop/art/container_yard/container_paint.gdshader"
const TOP_LOADER := "res://features/environments/industrial_loop/art/container_yard/top_loader/top_loader.glb"
const SIZE_TYPE := {"Container20": "22G1", "Container40": "42G1", "Container40HC": "45G1"}
const VAN_WAY: Array[Rect2] = [Rect2(97.0, 142.0, 6.0, 16.0), Rect2(93.0, 134.0, 14.0, 8.5)]
const LANE_POINTS: Array[Vector3] = [Vector3(100.0, 0.0, 150.0), Vector3(100.0, 0.0, 140.0),
	Vector3(95.0, 0.0, 136.0), Vector3(105.0, 0.0, 145.0)]
const SPREADER_IN := 6.4
const FLOODS_A_MAST := 4
const FORBIDDEN: Array[String] = ["VALE", "BLACKRIDGE"]

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
	_scratch = OS.get_temp_dir().path_join("blackridge-yard-realism-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	_markings(yard)
	_wear(yard)
	_top_loader(yard)
	_floods(yard)
	_finish()


## ISO 6346's check digit: letters valued from A = 10, skipping multiples of 11.
static func check_digit(code: String) -> int:
	var values := {}
	var value := 10
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		if value % 11 == 0:
			value += 1
		values[letter] = value
		value += 1
	var total := 0
	for index in range(10):
		var character := code[index]
		var worth: int = values[character] if values.has(character) else int(character)
		total += worth * int(pow(2, index))
	return total % 11 % 10


func _markings(yard: Node3D) -> void:
	var marks: Array = yard.call("placements", "Markings") if yard.has_method("placements") \
		else []
	var kinds: Array = yard.call("container_kinds")
	var valid := marks.size() == kinds.size() and not marks.is_empty()
	var seen := {}
	var bad: Array[String] = []
	for index in range(marks.size()):
		var mark: Dictionary = marks[index]
		var code := String(mark.get("code", ""))
		var ok := code.length() == 11 and code[3] == "U" and int(code[10]) == check_digit(code)
		ok = ok and String(mark.get("size_type", "")) == SIZE_TYPE.get(kinds[index], "?")
		ok = ok and not seen.has(code)
		for word in FORBIDDEN:
			ok = ok and not String(mark.get("line", "")).to_upper().contains(word)
		if not ok:
			bad.append(code)
		seen[code] = true
	_check(valid and bad.is_empty(), ("Y1: every box marked as ISO 6346 has it: owner code, serial "
		+ "and a check digit that checks, its size-type code for its kind, none twice, no story "
		+ "names (%d boxes, wrong: %s)") % [marks.size(), bad.slice(0, 5)])
	var painted := true
	for many in yard.find_children("Container*", "MultiMeshInstance3D", true, false):
		var multi := (many as MultiMeshInstance3D).multimesh
		var shader_ok := false
		for surface in range(multi.mesh.get_surface_count()):
			var material := multi.mesh.surface_get_material(surface) as ShaderMaterial
			if material != null and material.shader != null \
					and material.shader.resource_path == PAINT_SHADER \
					and material.get_shader_parameter("door_marks") is Texture2D \
					and material.get_shader_parameter("line_names") is Texture2D:
				shader_ok = true
		painted = painted and shader_ok and multi.use_custom_data
	_check(painted, "Y2: the boxes' paint draws each one's markings on its doors and its line's "
		+ "name and code on its sides, from its own instance data")


## Each box's wear seed, as the yard hands it to its paint (its instance data; a headless run
## keeps no instance data, so the yard's record of it).
func _wear(yard: Node3D) -> void:
	var seeds := {}
	var marks: Array = yard.call("placements", "Markings") if yard.has_method("placements") \
		else []
	for mark: Dictionary in marks:
		if mark.has("wear"):
			seeds["%.4f" % float(mark["wear"])] = true
	_check(not marks.is_empty() and seeds.size() >= marks.size() * 0.9, ("Y3: each box weathered "
		+ "its own way (%d wear patterns among %d boxes)") % [seeds.size(), marks.size()])


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _top_loader(yard: Node3D) -> void:
	var loader := yard.get_node_or_null("TopLoader") as Node3D
	var model := loader != null and loader.find_children("*", "Node3D", true, false).any(
		func(node: Node) -> bool: return String(node.scene_file_path) == TOP_LOADER)
	var box := _box(loader) if loader != null else AABB()
	var footprint := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var clear := loader != null
	for way in VAN_WAY:
		clear = clear and not footprint.intersects(way)
	for rect: Rect2 in yard.call("footprints"):
		if rect.size.x > 5.0 and rect.get_center().distance_to(footprint.get_center()) > 1.0:
			clear = clear and not footprint.grow(-0.2).intersects(rect)
	var grounded := loader != null and absf(box.position.y - 0.02) < 0.06
	var spreader := yard.find_child("Spreader*", true, false) as Node3D
	var drawn_in := spreader != null and minf(_box(spreader).size.x, _box(spreader).size.z) \
		<= SPREADER_IN and maxf(_box(spreader).size.x, _box(spreader).size.z) <= SPREADER_IN
	var solid := loader != null and not loader.find_children("*", "CollisionShape3D", true,
		false).is_empty()
	_check(model and clear and grounded and drawn_in and solid, ("Y4: a container top-loader "
		+ "(a real model) parked on the paving by the stacks, its spreader drawn in to 20 ft, solid "
		+ "and out of the van's way (model %s, clear %s, grounded %s, spreader in %s)")
		% [model, clear, grounded, drawn_in])


func _floods(yard: Node3D) -> void:
	var heads := yard.find_children("FloodHead*", "Node3D", true, false)
	var masts: Array = yard.get("MASTS") if "MASTS" in yard else []
	var per_mast := {}
	var lit_points := {}
	for head: Node3D in heads:
		var light := head.find_child("FloodLight", true, false) as SpotLight3D
		if light == null:
			continue
		var nearest := -1
		for index in range(masts.size()):
			var mast: Vector3 = masts[index]
			if Vector2(head.global_position.x - mast.x, head.global_position.z - mast.z) \
					.length() < 1.5 and head.global_position.y > 15.0:
				nearest = index
		if nearest < 0:
			continue
		per_mast[nearest] = int(per_mast.get(nearest, 0)) + 1
		for point in LANE_POINTS:
			var to := point - light.global_position
			var angle := rad_to_deg((-light.global_basis.z).angle_to(to))
			if angle <= light.spot_angle and to.length() <= light.spot_range:
				lit_points[point] = true
	var each := masts.size() > 0 and per_mast.size() == masts.size() \
		and per_mast.values().all(func(count: int) -> bool: return count >= FLOODS_A_MAST)
	_check(each and lit_points.size() == LANE_POINTS.size(), ("Y5: each high mast carries %d "
		+ "flood heads at its top, each with its light, and they light the lane (%s, %d of %d "
		+ "lane points)") % [FLOODS_A_MAST, per_mast, lit_points.size(), LANE_POINTS.size()])


func _finish() -> void:
	print("YARD REALISM RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The yard's realism checks finish within 120 s")
	quit(1)
