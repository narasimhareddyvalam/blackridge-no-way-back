extends SceneTree
## No tree's branches over the road (#469): filmed at 4K, Mission 1's van drove through firs whose
## low boughs reached over the lane at windshield height (about 1:21 and 2:27 of the pitch film,
## samples 112-125 and 546-570), their trunks 2.6-3 m past the verge with crowns 3.4 m across.
## C1 every forest tree's reach below the cab's roof (4.5 m), times its size, ends at least
##    0.5 m outside the road's verge (`road_clearance`), so nothing hangs over the asphalt.
##    The code-built firs reach their crown's base radius (`VARIANTS`); the modelled kinds the
##    farthest vertex of their mesh below 4.5 m.
## C2 the edge keeps its trees: red alder and young fir still stand in the first 4 m.
## C3 every modelled tree in the collision area has its trunk drawn on its collider (within
##    0.1 m): one young fir
##    model (`young_firs.glb`, model 1, near and far) was built 6.3 m off its origin, so that fir
##    stood 6 m from its trunk collider, on the road, where the van drove through it.
## The forest is the one the game builds (seed 42019, `industrial_loop.gd`'s `_forest`).

const SEED := 42019
const CAB_TOP := 4.5
const GAP := 0.5
const LEAST_EDGE := 100

var _checks: int = 0
var _failures: int = 0
var _app: Node
var _scratch: String


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		print("FAIL: %s" % description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-road-canopy-%d.cfg" % OS.get_process_id())
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	var forest := _app.get_node("IndustrialLoop/RoadsideForest")
	var terrain: Node3D = forest.get("_terrain")
	var variants: Array = forest.get("VARIANTS")
	var models: Dictionary = forest.get("_models")
	var reaches := {}
	var trunks := {}
	for kind: String in models:
		reaches[kind] = []
		trunks[kind] = []
		for model: Dictionary in models[kind]:
			var axis := _trunk_axis(model["mesh"] as ArrayMesh)
			trunks[kind].append(axis)
			reaches[kind].append(_low_reach(model["mesh"] as ArrayMesh, axis))
	var area: Rect2 = forest.get("collision_area")
	var colliders := {}
	for body in forest.get_children():
		if body is StaticBody3D:
			for shape in body.get_children():
				var p: Vector3 = (shape as Node3D).position
				var cell := Vector2i(floori(p.x), floori(p.z))
				if not colliders.has(cell):
					colliders[cell] = []
				colliders[cell].append(Vector2(p.x, p.z))
	var tiles: Dictionary = forest.call("_scatter", SEED, area)
	var over := 0
	var worst := INF
	var worst_at := Vector3.ZERO
	var edge := 0
	var misplaced := 0
	var farthest := 0.0
	var clearance: float = forest.get("_clearance")
	for tile: Vector2i in tiles:
		var centre: Vector2 = forest.call("_tile_centre", tile)
		for variant in range(variants.size()):
			for placed: Transform3D in tiles[tile]["transforms"][variant]:
				var reach: float = (variants[variant] as Vector2).y * placed.basis.get_scale().x
				var at := Vector3(centre.x + placed.origin.x, placed.origin.y,
					centre.y + placed.origin.z)
				var spare: float = terrain.road_clearance(at.x, at.z) - reach
				if spare < GAP:
					over += 1
					if over <= 40:
						print("OVER fir v%d at %s clearance %.2f reach %.2f" % [variant,
							at.snapped(Vector3.ONE * 0.1), spare + reach, reach])
				if spare < worst:
					worst = spare
					worst_at = at
		for key: String in tiles[tile]["species"]:
			var parts := key.split(":")
			for placed: Transform3D in tiles[tile]["species"][key]:
				var reach: float = reaches[parts[0]][int(parts[1])] * placed.basis.get_scale().x
				var axis: Vector3 = trunks[parts[0]][int(parts[1])]
				var drawn := placed * axis
				var at := Vector3(centre.x + drawn.x, placed.origin.y, centre.y + drawn.z)
				if area.has_point(Vector2(at.x, at.z)):
					var off := _nearest_collider(colliders, Vector2(at.x, at.z))
					if off > 0.1:
						misplaced += 1
						farthest = maxf(farthest, off)
				var beyond: float = terrain.road_clearance(at.x, at.z)
				var spare: float = beyond - reach
				if spare < GAP:
					over += 1
					if over <= 40:
						print("OVER %s at %s clearance %.2f reach %.2f" % [key,
							at.snapped(Vector3.ONE * 0.1), beyond, reach])
				if spare < worst:
					worst = spare
					worst_at = at
				if parts[0] in ["red_alder", "young_fir"] and beyond - clearance < 4.0:
					edge += 1
	_check(over == 0, "C1 no tree reaches over the road below %.1f m: %d reach within %.1f m "
		% [CAB_TOP, over, GAP] + "of the verge (worst %.2f m at %s)" % [worst,
		worst_at.snapped(Vector3.ONE * 0.1)])
	_check(misplaced == 0, "C3 every modelled trunk drawn on its collider: %d off by over 0.1 m "
		% misplaced + "(farthest %.2f m)" % farthest)
	_check(edge >= LEAST_EDGE, "C2 the edge keeps its alders and young firs: %d in the first 4 m"
		% edge)
	_finish()


## How far a point is from the nearest trunk collider (within 2 m; INF beyond).
func _nearest_collider(colliders: Dictionary, at: Vector2) -> float:
	var best := INF
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			for c: Vector2 in colliders.get(Vector2i(floori(at.x) + dx, floori(at.y) + dz), []):
				best = minf(best, c.distance_to(at))
	return best


## The trunk's axis in the mesh: the middle of its footprint (its bounds in x and z). For the
## models whose bark shows at breast height this is within 0.25 m of the bark's middle there.
func _trunk_axis(mesh: ArrayMesh) -> Vector3:
	var box := mesh.get_aabb()
	var middle := box.position + box.size * 0.5
	return Vector3(middle.x, 0.0, middle.z)


## The farthest a mesh's vertices reach from its trunk's axis below the cab's roof.
func _low_reach(mesh: ArrayMesh, axis: Vector3) -> float:
	var reach := 0.0
	for surface in range(mesh.get_surface_count()):
		var points: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point in points:
			if point.y < CAB_TOP:
				reach = maxf(reach, Vector2(point.x - axis.x, point.z - axis.z).length())
	return reach


func _finish() -> void:
	print("ROAD CANOPY RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)


func _timeout() -> void:
	_check(false, "Road canopy test finished within 300 s of game time")
	_finish()
