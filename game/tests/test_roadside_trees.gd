extends SceneTree
## The forest highway's Pacific Northwest roadside (#280): the trees nearest the road are its real
## kinds, placed where they grow, at their real sizes, without moving a single tree.
## T1 the kinds: red alder, young Douglas fir, western (here mountain) hemlock and western red
##    cedar each stand in the roadside band, and the code-built mature Douglas firs stay among
##    them.
## T2 where each grows: red alder and young firs take the open edge, the first 4 m into the
##    forest; hemlock, cedar and the mature firs, shade-tolerant, the 4 m behind it.
## T3 their sizes: each kind's height within its real range.
## T4 the trunks: every roadside tree inside the collision area has its trunk's collider, as
##    thick as the trunk its model has at breast height, 1.3 m up.
## T5 the alders bare: no leaves (no alpha-cut surface), their seed cones and catkins kept.
## T6 the foliage sways: every alpha-cut surface uses the forest's needle shader, with its wind.
## T7 the price: no model over 30,000 triangles.
## T8 nothing moved: as many trees, saplings and colliders as before (#280's baseline, less the
##    60 trees and 19 saplings on #267 part C's town plot, left out without moving any other:
##    every other collider kept its x, z and radius, 14 beside the plot raised or lowered up to
##    0.36 m by its levelling), with the colliders' centroid where it is.

const KINDS: Array[String] = ["red_alder", "young_fir", "mountain_hemlock", "western_red_cedar"]
const HEIGHTS := {"red_alder": Vector2(10.0, 25.0), "young_fir": Vector2(3.0, 12.0),
	"mountain_hemlock": Vector2(15.0, 35.0), "western_red_cedar": Vector2(18.0, 35.0)}
const EDGE := 4.0
const BAND := 8.0
const LEAST := 20
const NEEDLES := "res://features/environments/industrial_loop/conifer_needles.gdshader"
const MOST_TRIANGLES := 30000
const BASELINE := {"trees": 11759, "saplings": 6603, "colliders": 9768}
const CENTROID := Vector3(245.2233, 32.58152, -25.51315)
const TRUNK_MATCH := 0.15

var _checks: int = 0
var _failures: int = 0
var _app: Node
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
	_scratch = OS.get_temp_dir().path_join("blackridge-roadside-trees-%d.cfg" % OS.get_process_id())
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	var forest := _app.get_node("IndustrialLoop/RoadsideForest")
	var terrain: Node3D = forest.get("_terrain")
	var clearance: float = forest.get("_clearance")
	var placed: Dictionary = forest.get("species") if forest.get("species") != null else {}
	_check_kinds(placed, forest)
	_check_where(placed, terrain, clearance)
	_check_sizes(forest, placed)
	_check_trunks(forest, placed)
	_check_alders(forest)
	_check_foliage(forest)
	_check_price(forest)
	_check_unmoved(forest)
	_finish()


func _check_kinds(placed: Dictionary, forest: Node) -> void:
	var counts := {}
	for kind in KINDS:
		counts[kind] = (placed.get(kind, []) as Array).size()
	var mature: int = forest.get("roadside_mature") if forest.get("roadside_mature") != null else 0
	var enough := true
	for kind in KINDS:
		enough = enough and counts[kind] >= LEAST
	_check(enough and mature >= LEAST, "T1 the roadside has its real kinds: %s and %d mature "
		% [counts, mature] + "Douglas firs")


func _check_where(placed: Dictionary, terrain: Node3D, clearance: float) -> void:
	var edge := {}
	var behind := {}
	var edge_total := 0
	var behind_total := 0
	for kind: String in placed:
		for tree: Dictionary in placed[kind]:
			var at: Transform3D = tree["at"]
			var beyond: float = terrain.road_clearance(at.origin.x, at.origin.z) - clearance
			if beyond < EDGE:
				edge[kind] = int(edge.get(kind, 0)) + 1
				edge_total += 1
			elif beyond < BAND:
				behind[kind] = int(behind.get(kind, 0)) + 1
				behind_total += 1
	var pioneers := float(int(edge.get("red_alder", 0)) + int(edge.get("young_fir", 0))) \
		/ maxf(edge_total, 1)
	var shade := float(int(behind.get("mountain_hemlock", 0))
		+ int(behind.get("western_red_cedar", 0))) / maxf(behind_total, 1)
	var alders_behind := float(int(behind.get("red_alder", 0))) / maxf(behind_total, 1)
	_check(pioneers >= 0.6 and shade >= 0.5 and alders_behind < pioneers,
		"T2 alders and young firs take the open edge (%.0f%% of the first %.0f m), hemlock and "
		% [100.0 * pioneers, EDGE] + "cedar the band behind (%.0f%% of the species there)"
		% (100.0 * shade))


func _check_sizes(forest: Node, placed: Dictionary) -> void:
	var notes: Array[String] = []
	var inside := true
	for kind in KINDS:
		var tallest := 0.0
		var shortest := INF
		for tree: Dictionary in placed.get(kind, []):
			var height: float = forest.call("height_of", kind, tree["model"], tree["at"])
			tallest = maxf(tallest, height)
			shortest = minf(shortest, height)
		inside = inside and shortest <= tallest and shortest >= HEIGHTS[kind].x \
			and tallest <= HEIGHTS[kind].y
		notes.append("%s %.1f-%.1f m" % [kind, shortest, tallest])
	_check(inside, "T3 each kind within its real height (%s)" % ", ".join(notes))


func _check_trunks(forest: Node, placed: Dictionary) -> void:
	var shapes := {}
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape: CollisionShape3D in body.get_children():
				var key := Vector2i(roundi(shape.position.x * 10.0), roundi(shape.position.z * 10.0))
				shapes[key] = shape
	var area: Rect2 = forest.get("collision_area") if forest.get("collision_area") != null \
		else Rect2()
	var missing := 0
	var wrong := 0
	var checked := 0
	for kind: String in placed:
		for tree: Dictionary in placed[kind]:
			var at: Transform3D = tree["at"]
			var trunk: float = forest.call("trunk_of", kind, tree["model"])
			if not area.has_point(Vector2(at.origin.x, at.origin.z)):
				continue
			checked += 1
			var key := Vector2i(roundi(at.origin.x * 10.0), roundi(at.origin.z * 10.0))
			if not shapes.has(key):
				missing += 1
				continue
			var radius := ((shapes[key] as CollisionShape3D).shape as CylinderShape3D).radius
			var scale := at.basis.get_scale().x
			if absf(radius - trunk * scale) > trunk * scale * TRUNK_MATCH:
				wrong += 1
	_check(checked > 0 and missing == 0 and wrong == 0, "T4 every roadside tree in the "
		+ "collision area has its trunk's collider, as thick as its model's trunk (%d checked, "
		% checked + "%d missing, %d the wrong size)" % [missing, wrong])


func _check_alders(forest: Node) -> void:
	var meshes: Array = forest.call("meshes_of", "red_alder")
	var leaves := 0
	var names := {}
	for mesh: Mesh in meshes:
		for surface in range(mesh.get_surface_count()):
			var used := mesh.surface_get_material(surface)
			if used is BaseMaterial3D and (used as BaseMaterial3D).transparency \
					!= BaseMaterial3D.TRANSPARENCY_DISABLED:
				leaves += 1
			if used is ShaderMaterial:
				leaves += 1
			if used != null:
				names[used.resource_name] = true
	_check(not meshes.is_empty() and leaves == 0 and names.has("AlderCone")
		and names.has("AlderCatkin"), "T5 the alders are bare, with their seed cones and catkins "
		+ "(%d trees, materials %s)" % [meshes.size(), names.keys()])


func _check_foliage(forest: Node) -> void:
	var cut := 0
	var swaying := 0
	for kind in ["young_fir", "mountain_hemlock", "western_red_cedar"]:
		for mesh: Mesh in forest.call("meshes_of", kind):
			for surface in range(mesh.get_surface_count()):
				var used := mesh.surface_get_material(surface)
				if used is ShaderMaterial:
					cut += 1
					if (used as ShaderMaterial).shader.resource_path == NEEDLES:
						swaying += 1
				elif used is BaseMaterial3D and (used as BaseMaterial3D).transparency \
						!= BaseMaterial3D.TRANSPARENCY_DISABLED:
					cut += 1
	_check(cut > 0 and swaying == cut, "T6 every alpha-cut surface sways in the needles' wind "
		+ "(%d of %d)" % [swaying, cut])


func _check_price(forest: Node) -> void:
	var notes: Array[String] = []
	var heaviest := 0
	for kind in KINDS:
		for mesh: Mesh in forest.call("meshes_of", kind):
			var triangles := 0
			for surface in range(mesh.get_surface_count()):
				var indices: PackedInt32Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
				triangles += indices.size() / 3
			heaviest = maxi(heaviest, triangles)
			notes.append("%s %d" % [kind, triangles])
	_check(not notes.is_empty() and heaviest <= MOST_TRIANGLES,
		"T7 no model over %d triangles (%s)" % [MOST_TRIANGLES, ", ".join(notes)])


func _check_unmoved(forest: Node) -> void:
	var shapes := 0
	var sum := Vector3.ZERO
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape in body.get_children():
				shapes += 1
				sum += (shape as Node3D).position
	var centroid := sum / maxf(shapes, 1)
	var trees: int = forest.get("tree_count")
	var saplings: int = forest.get("sapling_count")
	_check(trees == BASELINE["trees"] and saplings == BASELINE["saplings"]
		and shapes == BASELINE["colliders"] and centroid.distance_to(CENTROID) < 0.01,
		"T8 nothing moved: %d trees, %d saplings, %d colliders, centroid %s" % [trees, saplings,
		shapes, centroid])


func _finish() -> void:
	print("ROADSIDE TREES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Roadside trees test finished within 120 s of game time")
	quit(1)
