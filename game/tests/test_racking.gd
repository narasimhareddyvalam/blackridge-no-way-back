extends SceneTree
## Part A of #267 (docs/PHASE_BRIEF.md, "step 5 brought forward"): the transfer shed's selective
## pallet racking, read from the shed as the running game builds it on Mission 2's start save:
## its rows, frames, beams and decks at their makers' sizes, its aisles for a counterbalance
## forklift, its guards and aisle boards, solid, inside the free floor behind the cross-aisle and
## under the shed's lights and roof. A headless run draws nothing, so the look is not checked.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const INCH := 0.0254
const FLOOR := 1.3
const FREE := Rect2(-82.0, -9.75, 37.24, 19.75)
const BACK_WALL := -9.75
const FROM_WALL := 0.3
const CROSS_AISLE := 10.0
const BEFORE_CROSS := 1.5
const ROWS := 6
const BAYS := 7
const FRAME_TALL := 240 * INCH
const FRAME_DEEP := 42 * INCH
const POST := 3 * INCH
const BEAM_CLEAR := 96 * INCH
## A step beam's height; its origin is its lower outer edge (`build_racking.py`).
const BEAM_TALL := 4 * INCH
const LEVELS: Array[float] = [60 * INCH, 120 * INCH, 180 * INCH]
const OVERHANG := 3 * INCH
const FLUE := 6 * INCH
const AISLE := 150 * INCH
const SIGN_HEIGHT := Vector2(2.0, 2.8)
const LIGHTS_AT := 8.4
const UNDER_LIGHTS := 0.5
const ROOF_UNDERSIDE := 9.0
const SPRINKLER_CLEAR := 18 * INCH
const NEAR := 0.003
## The stock: GMA 48 x 40 in pallets, 3 in (76 mm) clear of the posts and of each other, loads
## 4 in under the beam above, the racks mostly full.
const PALLET := Vector3(48 * INCH, 0.146, 40 * INCH)
const CLEAR := 3 * INCH
const HEADROOM := 4 * INCH
const PLACES := 11 * 7 * 4 * 2
const FULL := 0.7
## The floor's lines, the roof's joists and liner, the lights and the services, as the photo has
## them: 4 in lines; long-span joists every 2.06 m under the deck from wall to wall; the
## staging lanes' row of lights kept and three fixtures down each aisle, each clear of the
## joists; ducts and sprinkler mains above the racks, the heads 18 in over the stock.
const LINE_WIDE := 4 * INCH
const SHED_X := Vector2(-89.75, -40.25)
const SHED_Z := Vector2(-9.75, 19.75)
const RIDGE_Z := 5.0
const EAVES := 9.0
const PITCH := 5.0
const JOIST_SPACING := 2.07
const LIGHT_CLEAR := 0.3
const STAGING_ROW := 15.0
const STAGING_XS: Array[float] = [-78.0, -70.0, -62.0, -54.0, -46.0]
const AISLE_LIGHTS := 3
const LOADS: Array[String] = ["BoardBundle060", "BoardBundle090", "BoardBundle110",
	"CartonStack3", "CartonStack2"]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _racking: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-racking-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_racking = shed.get_node_or_null("Building/Racking") as Node3D if shed != null else null
	_check(_racking != null, "R0: the transfer shed has its racking (Building/Racking)")
	if _racking != null:
		_check_racking()
	_finish()


func _check_racking() -> void:
	var frames := _instances("Frames")
	var beams := _instances("Beams")
	var decks := _instances("Decks")
	var lines := _frame_lines(frames)
	var singles := 0
	var doubles := 0
	var index := 0
	while index < lines.size():
		if index + 1 < lines.size() and lines[index + 1] - lines[index] < FRAME_DEEP + 0.2:
			doubles += 1
			index += 2
		else:
			singles += 1
			index += 1
	var per_line := frames.size() / maxi(1, lines.size())
	var levels := _beam_tops(beams)
	var spans := _spans(frames)
	var sized := lines.size() == 11 and singles == 1 and doubles == 5 \
		and per_line == BAYS + 1 and frames.size() == lines.size() * (BAYS + 1) \
		and beams.size() == lines.size() * BAYS * LEVELS.size() * 2 \
		and decks.size() == lines.size() * BAYS * LEVELS.size() * 2 \
		and _matches(levels, LEVELS) and spans.size() == 1 \
		and absf(spans[0] - BEAM_CLEAR) < NEAR and _frame_size(frames)
	_check(sized and singles + doubles == ROWS, ("R1: %d rows of %d bays, one single and five "
		+ "back to back (%d single, %d double, %d frame lines of %d frames), each frame 20 ft "
		+ "tall and 42 in deep, beams 96 in clear (%s) at 60, 120 and 180 in (%s), two decks "
		+ "a level (%d beams, %d decks)") % [ROWS, BAYS, singles, doubles, lines.size(),
		per_line, ", ".join(spans.map(func(s: float) -> String: return "%.3f" % s)),
		", ".join(levels.map(func(h: float) -> String: return "%.3f" % h)), beams.size(),
		decks.size()])
	var box := _footprint(frames)
	var inside := FREE.encloses(Rect2(box.position.x, box.position.z, box.size.x, box.size.z)) \
		and absf(box.position.y - FLOOR) < NEAR and box.position.z >= BACK_WALL + FROM_WALL - NEAR \
		and _ends(frames) <= CROSS_AISLE - BEFORE_CROSS
	_check(inside, ("R2: the rows stand on the dock floor (%.3f m) inside the free floor behind "
		+ "the cross-aisle (x %.2f to %.2f, z %.2f to %.2f), %.2f m off the back wall and "
		+ "ending %.2f m before the cross-aisle's line") % [box.position.y, box.position.x,
		box.end.x, box.position.z, box.end.z, box.position.z - BACK_WALL,
		CROSS_AISLE - _ends(frames)])
	var aisles := _aisles(lines)
	var narrowest := INF
	for width in aisles:
		narrowest = minf(narrowest, width)
	var signs := _signs()
	_check(aisles.size() >= 5 and narrowest >= AISLE - NEAR and signs == "", ("R3: the aisles "
		+ "between the rows leave a counterbalance forklift its 12.5 ft (%.2f m) between the "
		+ "loads' faces (narrowest %.2f m of %d), and each aisle's entrance has its numbered "
		+ "board, 01 to 06, facing the cross-aisle at 2.0 to 2.8 m (%s)") % [AISLE, narrowest,
		aisles.size(), "so" if signs == "" else signs])
	var guards := _guards(frames, lines)
	_check(guards == "", "R4: a yellow guard across each row's end at the cross-aisle and a "
		+ "post protector on every post facing an aisle (%s)" % ("so" if guards == "" else guards))
	var solid := _solid_and_open(lines)
	_check(solid == "", "R5: the rows are solid and the aisles clear from the floor to 2 m (%s)" % (
		"so" if solid == "" else solid))
	var top := box.end.y
	var stock := _stock(lines)
	_check(stock == "", "R7: the racks hold stock as real ones do (%s)" % ("every load on its "
		+ "own pallet, each pallet on the floor or a beam level within its 3 in overhang, 3 in "
		+ "clear of the posts and its neighbour, each load 4 in under the beam above, at least "
		+ "70% of the 616 places full, nothing named as the mission's pallets" if stock == ""
		else stock))
	var lined := _lines(lines)
	_check(lined == "", "R8: the floor is lined as the photo's: yellow 4 in lines down both sides "
		+ "of every aisle and a white walkway down the aisle by the rail (%s)" % ("so"
		if lined == "" else lined))
	var roofed := _roof(lines)
	_check(roofed == "", ("R9: long-span joists every %.2f m or less span the shed from wall to "
		+ "wall under its deck, under a white liner; the staging lanes' row of five lights stays "
		+ "and three hang down each aisle, each at least %.1f m from a joist, all under the "
		+ "roof (%s)") % [JOIST_SPACING, LIGHT_CLEAR, "so" if roofed == "" else roofed])
	var served := _services()
	_check(served == "", "R10: ducts and sprinkler mains run the shed's width above the racks, "
		+ "the sprinkler heads at least NFPA 13's 18 in over the stock (%s)" % ("so"
		if served == "" else served))
	top = maxf(top, _stock_top())
	_check(top <= LIGHTS_AT - UNDER_LIGHTS and top <= ROOF_UNDERSIDE - SPRINKLER_CLEAR, ("R6: "
		+ "the racking's top, %.2f m, is at least %.1f m under the lights at %.1f m and NFPA "
		+ "13's 18 in under the roof") % [top, UNDER_LIGHTS, LIGHTS_AT])


func _stock(lines: Array[float]) -> String:
	var faults: Array[String] = []
	var pallets := _instances("Pallets")
	var loads: Array[Array] = []
	for name in LOADS:
		var mesh := _mesh(name)
		for each in _instances(name):
			loads.append([each, mesh])
	if pallets.size() < PLACES * FULL:
		faults.append("%d of %d places full" % [pallets.size(), PLACES])
	var bays: Array[float] = []
	for k in range(BAYS):
		bays.append(_first_z(lines) + k * (BEAM_CLEAR + POST) + POST / 2.0)
	for pallet in pallets:
		var at := pallet.origin
		var on := absf(at.y - FLOOR) < NEAR
		for level in LEVELS:
			on = on or absf(at.y - (FLOOR + level)) < NEAR
		var line := INF
		for x in lines:
			if absf(x - at.x) < absf(line - at.x):
				line = x
		var over := absf(at.x - line) + PALLET.x / 2.0 - FRAME_DEEP / 2.0
		var bay := -INF
		for from in bays:
			if at.z > from:
				bay = from
		var to_post := minf(at.z - PALLET.z / 2.0 - bay, bay + BEAM_CLEAR - at.z - PALLET.z / 2.0)
		if not on or over > OVERHANG + 0.015 or to_post < CLEAR - 0.012:
			faults.append("pallet at (%.2f, %.2f, %.2f): %s" % [at.x, at.y, at.z,
				"off its level" if not on else ("over %.3f m" % over if over > OVERHANG + 0.015
				else "%.3f m to a post" % to_post)])
	for index in pallets.size():
		for other in range(index + 1, pallets.size()):
			var a := pallets[index].origin
			var b := pallets[other].origin
			if absf(a.x - b.x) < 0.1 and absf(a.y - b.y) < 0.01 \
					and absf(a.z - b.z) - PALLET.z < CLEAR - 0.012:
				faults.append("pallets at z %.2f and %.2f too close" % [a.z, b.z])
	for entry in loads:
		var load: Transform3D = entry[0]
		var mesh: Mesh = entry[1]
		var top := load.origin.y + mesh.get_aabb().end.y
		var under := INF
		for level in LEVELS:
			var beam_bottom := FLOOR + level - BEAM_TALL
			if beam_bottom > load.origin.y:
				under = minf(under, beam_bottom)
		var seated := pallets.any(func(p: Transform3D) -> bool:
			return Vector2(p.origin.x - load.origin.x, p.origin.z - load.origin.z).length() < 0.03 \
				and absf(p.origin.y + PALLET.y - load.origin.y) < NEAR)
		if not seated or top > under - HEADROOM + NEAR:
			faults.append("load at (%.2f, %.2f, %.2f): %s" % [load.origin.x, load.origin.y,
				load.origin.z, "on no pallet" if not seated else "%.3f m under the beam" % (
				under - top)])
	var named := 0
	for found in _racking.find_children("Pallet*", "", true, false):
		if String(found.name).trim_prefix("Pallet").is_valid_int():
			named += 1
	if named > 0:
		faults.append("%d nodes named as the mission's pallets" % named)
	return "; ".join(faults.slice(0, 4))


func _underside(z: float) -> float:
	return EAVES + ((SHED_Z.y - SHED_Z.x) / 2.0 + 0.25 - absf(z - RIDGE_Z)) * tan(deg_to_rad(PITCH))


func _lines(lines: Array[float]) -> String:
	var faults: Array[String] = []
	var marks: Array[AABB] = []
	for found in _racking.find_children("AisleLine*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		marks.append(mesh.global_transform * mesh.get_aabb())
		var paint := mesh.get_active_material(0) as BaseMaterial3D
		if paint == null or paint.albedo_color.b > 0.3 or paint.albedo_color.r < 0.7:
			faults.append("%s not yellow" % mesh.name)
	var row_faces: Array[Vector2] = []
	var index := 0
	while index < lines.size():
		var last := index + 1 if index + 1 < lines.size() \
			and lines[index + 1] - lines[index] < FRAME_DEEP + 0.2 else index
		row_faces.append(Vector2(lines[index] - FRAME_DEEP / 2.0 - OVERHANG,
			lines[last] + FRAME_DEEP / 2.0 + OVERHANG))
		index = last + 1
	var wanted := 0
	for row in row_faces.size():
		for edge: float in ([row_faces[row].y] if row == 0 else [row_faces[row].x,
				row_faces[row].y]):
			wanted += 1
			var near := marks.filter(func(box: AABB) -> bool:
				return absf(box.get_center().x - edge) < 0.3 and box.size.z > 15.0)
			if near.size() != 1:
				faults.append("%d lines by the face at x %.2f" % [near.size(), edge])
				continue
			var mark: AABB = near[0]
			if absf(mark.size.x - LINE_WIDE) > 0.005 or absf(mark.end.y - FLOOR) > 0.008 \
					or mark.end.y < FLOOR:
				faults.append("the line at x %.2f %.3f m wide, %.3f m up" % [edge, mark.size.x,
					mark.end.y - FLOOR])
	if marks.size() != wanted:
		faults.append("%d yellow lines for %d aisle faces" % [marks.size(), wanted])
	var walkway := _racking.find_children("WalkwayLine*", "MeshInstance3D", true, false)
	if walkway.size() < 2:
		faults.append("%d walkway lines" % walkway.size())
	for found in walkway:
		var paint := (found as MeshInstance3D).get_active_material(0) as BaseMaterial3D
		if paint == null or paint.albedo_color.b < 0.8:
			faults.append("%s not white" % found.name)
	return "; ".join(faults.slice(0, 4))


func _roof(lines: Array[float]) -> String:
	var faults: Array[String] = []
	var shed := _racking.get_parent().get_parent() as Node3D
	var joists: Array[float] = []
	for joist in _instances("Joists"):
		joists.append(joist.origin.x)
	joists.sort()
	if joists.size() < 20:
		faults.append("%d joists" % joists.size())
	else:
		if joists[0] - SHED_X.x > JOIST_SPACING or SHED_X.y - joists[-1] > JOIST_SPACING:
			faults.append("the joists end %.2f and %.2f m from the gables" % [joists[0] - SHED_X.x,
				SHED_X.y - joists[-1]])
		for index in range(joists.size() - 1):
			if joists[index + 1] - joists[index] > JOIST_SPACING:
				faults.append("joists %.2f m apart" % (joists[index + 1] - joists[index]))
				break
		var mesh := _mesh("Joists")
		var span := mesh.get_aabb()
		var joist := _instances("Joists")[0]
		var box := joist * span
		if absf(box.position.z - SHED_Z.x) > 0.06 or absf(box.end.z - SHED_Z.y) > 0.06:
			faults.append("a joist spans z %.2f to %.2f" % [box.position.z, box.end.z])
		if box.end.y > _underside(RIDGE_Z) + 0.01 or box.end.y < _underside(RIDGE_Z) - 0.15:
			faults.append("a joist's top %.2f m, the deck %.2f m" % [box.end.y,
				_underside(RIDGE_Z)])
	var liner := _racking.find_children("RoofLiner*", "MeshInstance3D", true, false)
	if liner.size() != 2:
		faults.append("%d liner slopes" % liner.size())
	var lights := shed.find_children("BayLight*", "Light3D", true, false)
	var staging := lights.filter(func(node: Node) -> bool:
		return absf((node as Node3D).global_position.z - STAGING_ROW) < 0.05)
	if staging.size() != STAGING_XS.size():
		faults.append("%d lights over the staging lanes" % staging.size())
	var centres := _aisle_centres(lines)
	for centre in centres:
		var down := lights.filter(func(node: Node) -> bool:
			return absf((node as Node3D).global_position.x - centre) < 0.05)
		if down.size() != AISLE_LIGHTS:
			faults.append("%d lights down the aisle at x %.2f" % [down.size(), centre])
	for node in lights:
		var at := (node as Node3D).global_position
		var nearest := INF
		for x in joists:
			nearest = minf(nearest, absf(x - at.x))
		if nearest < LIGHT_CLEAR or at.y > _underside(at.z) - 0.2:
			faults.append("%s %.2f m from a joist, %.2f m under the roof" % [node.name, nearest,
				_underside(at.z) - at.y])
	return "; ".join(faults.slice(0, 4))


func _aisle_centres(lines: Array[float]) -> Array[float]:
	var centres: Array[float] = []
	var faces: Array[Vector2] = []
	var index := 0
	while index < lines.size():
		var last := index + 1 if index + 1 < lines.size() \
			and lines[index + 1] - lines[index] < FRAME_DEEP + 0.2 else index
		faces.append(Vector2(lines[index] - FRAME_DEEP / 2.0 - OVERHANG,
			lines[last] + FRAME_DEEP / 2.0 + OVERHANG))
		index = last + 1
	for row in range(faces.size() - 1):
		centres.append((faces[row].y + faces[row + 1].x) / 2.0)
	return centres


func _services() -> String:
	var faults: Array[String] = []
	var stock := _stock_top()
	var rack_top := FLOOR + FRAME_TALL
	for name in ["Ducts", "SprinklerMains"]:
		var runs := _instances(name)
		if runs.is_empty():
			faults.append("no %s" % name)
			continue
		var mesh := _mesh(name)
		var west := INF
		var east := -INF
		var low := INF
		for run in runs:
			var box := run * mesh.get_aabb()
			west = minf(west, box.position.x)
			east = maxf(east, box.end.x)
			low = minf(low, box.position.y)
		if west > SHED_X.x + 8.5 or east < -44.76:
			faults.append("%s from x %.2f to %.2f" % [name, west, east])
		if low < rack_top + 0.3:
			faults.append("%s %.2f m over the racks' top" % [name, low - rack_top])
	var heads := _instances("SprinklerHeads")
	if heads.is_empty():
		faults.append("no sprinkler heads")
	for head in heads:
		if head.origin.y - stock < SPRINKLER_CLEAR:
			faults.append("a head %.2f m over the stock" % (head.origin.y - stock))
			break
	return "; ".join(faults.slice(0, 4))


func _stock_top() -> float:
	var top := -INF
	for name in LOADS:
		var mesh := _mesh(name)
		for each in _instances(name):
			top = maxf(top, each.origin.y + mesh.get_aabb().end.y)
	return top


func _mesh(name: String) -> Mesh:
	var node := _racking.get_node_or_null(name) as MultiMeshInstance3D
	return node.multimesh.mesh if node != null and node.multimesh != null else null


func _first_z(lines: Array[float]) -> float:
	var first := INF
	for frame in _instances("Frames"):
		first = minf(first, frame.origin.z)
	return first


## The world transforms of `name`'s instances under the racking: the multi-mesh's own count,
## each where the racking placed it (a headless run's renderer keeps no instance transforms).
func _instances(name: String) -> Array[Transform3D]:
	var found: Array[Transform3D] = []
	var node := _racking.get_node_or_null(name) as MultiMeshInstance3D
	if node == null or node.multimesh == null:
		return found
	var placed: Array[Transform3D] = _racking.call("placements", name)
	if placed.size() != node.multimesh.instance_count:
		return found
	for each in placed:
		found.append(node.global_transform * each)
	return found


## The rows' frame lines: each distinct x a frame stands at, west to east.
func _frame_lines(frames: Array[Transform3D]) -> Array[float]:
	var xs: Array[float] = []
	for frame in frames:
		if not xs.any(func(x: float) -> bool: return absf(x - frame.origin.x) < 0.01):
			xs.append(frame.origin.x)
	xs.sort()
	return xs


func _beam_tops(beams: Array[Transform3D]) -> Array[float]:
	var tops: Array[float] = []
	for beam in beams:
		var top := beam.origin.y + BEAM_TALL - FLOOR
		if not tops.any(func(t: float) -> bool: return absf(t - top) < 0.005):
			tops.append(top)
	tops.sort()
	return tops


func _matches(found: Array[float], wanted: Array[float]) -> bool:
	if found.size() != wanted.size():
		return false
	for index in found.size():
		if absf(found[index] - wanted[index]) > NEAR:
			return false
	return true


## The clear spans between neighbouring frames along each line.
func _spans(frames: Array[Transform3D]) -> Array[float]:
	var spans: Array[float] = []
	for frame in frames:
		var next := INF
		for other in frames:
			if absf(other.origin.x - frame.origin.x) < 0.01 and other.origin.z > frame.origin.z:
				next = minf(next, other.origin.z - frame.origin.z)
		if next < INF:
			var clear := next - POST
			if not spans.any(func(s: float) -> bool: return absf(s - clear) < NEAR):
				spans.append(clear)
	return spans


## A frame 20 ft tall, and 42 in deep: a back-to-back row's frames stand 42 in plus its 6 in
## flue apart, middle to middle (the frame's own box is deeper, by its base plates' 1.5 in
## each way past the posts, as real footplates are).
func _frame_size(frames: Array[Transform3D]) -> bool:
	var mesh := (_racking.get_node("Frames") as MultiMeshInstance3D).multimesh.mesh
	var lines := _frame_lines(frames)
	var paired := false
	for index in range(lines.size() - 1):
		var apart := lines[index + 1] - lines[index]
		if apart < FRAME_DEEP + 0.2:
			paired = true
			if absf(apart - (FRAME_DEEP + FLUE)) > NEAR:
				return false
	return absf(mesh.get_aabb().size.y - FRAME_TALL) < NEAR and paired


func _footprint(frames: Array[Transform3D]) -> AABB:
	var mesh := (_racking.get_node("Frames") as MultiMeshInstance3D).multimesh.mesh
	var box := AABB()
	var first := true
	for frame in frames:
		var part := frame * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _ends(frames: Array[Transform3D]) -> float:
	var end := -INF
	var guards := _instances("EndGuards")
	var mesh := (_racking.get_node("EndGuards") as MultiMeshInstance3D).multimesh.mesh \
		if not guards.is_empty() else null
	for frame in frames:
		end = maxf(end, frame.origin.z + POST / 2.0)
	for guard in guards:
		end = maxf(end, (guard * mesh.get_aabb()).end.z)
	var single := _racking.get_node_or_null("EndGuardSingle") as MeshInstance3D
	if single != null:
		end = maxf(end, (single.global_transform * single.get_aabb()).end.z)
	return end


## The widths between the loads' faces of neighbouring rows.
func _aisles(lines: Array[float]) -> Array[float]:
	var faces: Array[Vector2] = []
	var index := 0
	while index < lines.size():
		var last := index + 1 if index + 1 < lines.size() \
			and lines[index + 1] - lines[index] < FRAME_DEEP + 0.2 else index
		faces.append(Vector2(lines[index] - FRAME_DEEP / 2.0 - OVERHANG,
			lines[last] + FRAME_DEEP / 2.0 + OVERHANG))
		index = last + 1
	var widths: Array[float] = []
	for row in range(faces.size() - 1):
		widths.append(faces[row + 1].x - faces[row].y)
	return widths


func _signs() -> String:
	var faults: Array[String] = []
	for number in range(1, 7):
		var sign := _racking.get_node_or_null("AisleSign%02d" % number) as Node3D
		if sign == null:
			faults.append("no board %02d" % number)
			continue
		var height := sign.global_position.y - FLOOR
		var facing := sign.global_basis.z.normalized().dot(Vector3.BACK)
		if height < SIGN_HEIGHT.x or height > SIGN_HEIGHT.y or facing < 0.99:
			faults.append("%02d at %.2f m facing %.2f" % [number, height, facing])
	var xs: Array[float] = []
	for number in range(1, 7):
		var sign := _racking.get_node_or_null("AisleSign%02d" % number) as Node3D
		if sign != null:
			xs.append(sign.global_position.x)
	for index in range(xs.size() - 1):
		if xs[index + 1] <= xs[index]:
			faults.append("not numbered west to east")
	return "; ".join(faults)


func _guards(frames: Array[Transform3D], lines: Array[float]) -> String:
	var faults: Array[String] = []
	var ends := _instances("EndGuards")
	var single := _racking.get_node_or_null("EndGuardSingle") as Node3D
	if ends.size() != ROWS - 1 or single == null:
		faults.append("%d end guards and %s single's for %d rows" % [ends.size(),
			"a" if single != null else "no", ROWS])
	var guards := _instances("PostGuards")
	var faces := _aisle_faces(lines)
	var wanted := 0
	for frame in frames:
		for side: float in [-1.0, 1.0]:
			var x := frame.origin.x + side * (FRAME_DEEP / 2.0 - POST / 2.0)
			var face := frame.origin.x + side * FRAME_DEEP / 2.0
			var facing := false
			for each in faces:
				if absf(each - face) < 0.01:
					facing = true
			if not facing:
				continue
			wanted += 1
			var at := Vector3(x, FLOOR, frame.origin.z)
			var guarded := false
			for guard in guards:
				if Vector2(guard.origin.x - at.x, guard.origin.z - at.z).length() < 0.02 \
						and absf(guard.origin.y - FLOOR) < NEAR:
					guarded = true
			if not guarded:
				faults.append("no protector at (%.2f, %.2f)" % [at.x, at.z])
	if wanted == 0:
		faults.append("no posts face an aisle")
	return "; ".join(faults.slice(0, 4))


## The x of every frame face that looks onto an aisle (not the flue between a back-to-back
## row's frames, nor the face against the office wall).
func _aisle_faces(lines: Array[float]) -> Array[float]:
	var faces: Array[float] = []
	for index in lines.size():
		for side: float in [-1.0, 1.0]:
			var face := lines[index] + side * FRAME_DEEP / 2.0
			var flue := false
			for other in lines:
				var apart := other - lines[index]
				if absf(apart) > 0.01 and absf(apart) < FRAME_DEEP + 0.2 and signf(apart) == side:
					flue = true
			if not flue and face > FREE.position.x + 0.5:
				faces.append(face)
	return faces


func _solid_and_open(lines: Array[float]) -> String:
	var faults: Array[String] = []
	var space := _app.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.1
	query.shape = ball
	query.collision_mask = 1
	for x in lines:
		query.transform = Transform3D(Basis.IDENTITY, Vector3(x, FLOOR + 1.0, 0.0))
		if space.intersect_shape(query, 1).is_empty():
			faults.append("row at x %.2f not solid" % x)
	var aisles := _aisles(lines)
	var index := 0
	var row_faces: Array[float] = []
	while index < lines.size():
		var last := index + 1 if index + 1 < lines.size() \
			and lines[index + 1] - lines[index] < FRAME_DEEP + 0.2 else index
		row_faces.append(lines[last] + FRAME_DEEP / 2.0 + OVERHANG)
		index = last + 1
	for row in aisles.size():
		var middle := row_faces[row] + aisles[row] / 2.0
		for height: float in [0.3, 1.0, 1.9]:
			for z: float in [-6.0, 0.0, 6.0]:
				query.transform = Transform3D(Basis.IDENTITY, Vector3(middle, FLOOR + height, z))
				if not space.intersect_shape(query, 1).is_empty():
					faults.append("aisle %d blocked at (%.2f, %.1f, %.1f)" % [row + 1, middle,
						height, z])
	return "; ".join(faults.slice(0, 4))


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The racking's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("RACKING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
