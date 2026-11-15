extends Node
## The transfer shed's floor as a working dock's (docs/PHASE_BRIEF.md, step 5 of #253, part D;
## the author's choice, #294): one material for the dock floor and the drive-in lane
## (`shed_floor.gdshader`), Poly Haven's worn concrete floor under a map this script paints of
## where real wear lies, by world position, so nothing is projected onto Ethan, the jack or the
## loads. Sawn joints, filled with grey epoxy as forklift floors are (ACI 302.1R and 360R: 24-36
## times a 6 in slab's thickness apart, so 3.7-5.5 m, panels at most 1.5:1), between the docks
## every 4 m across and in seven equal panels from the dock face, none through the lift's pit;
## the lane's own joints in line with them. Over them, four maps:
## - grime: dark tyre marks on the forklift's ways (the cross-aisle, its turns into each aisle and
##   down them), rubber scuffs before each leveller and the lift's deck, oil under the parked
##   forklift;
## - gloss: the wheel paths burnished, and the oil;
## - wet: rain blown in at the open doors (dock 5, bay 9 and the side door), wet through 2 m in,
##   then wheel tracks and footprints drying out by 6 m;
## - patch: grey epoxy where a joint's edge spalled under the wheels.
## The same every build (a seeded draw); `marks()` hands out each mark painted, `joints()` each
## joint, since a headless run draws nothing.

const SHADER := preload("shed_floor.gdshader")
const Racking := preload("racking.gd")
const FLOOR_TEXTURES := "res://features/environments/depot_yard/polyhaven/textures/" \
	+ "concrete_floor_worn_001/concrete_floor_worn_001_%s_2k.jpg"
## The shed's floor (`transfer_building.gd`): the dock floor's slab from the office's end to the
## drive-in lane, round bay 9's lift pit, and the lane's, the dock face, the docks and the doors.
const DOCK := Rect2(-82.0, -9.75, 37.3, 29.5)
const LANE := Rect2(-44.7, -9.75, 4.45, 29.5)
const PIT := Rect2(-48.685, 17.29, 1.87, 2.46)
const MAP := Rect2(-82.0, -9.75, 41.75, 29.5)
const PER_METRE := 32
const FACE := 19.75
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0]
const LEVELLER := Vector2(2.0, 1.22)
const OPEN_DOCK := -64.0
const DOCK_OPENING := 2.74
const SIDE_DOOR := Vector2(-40.0, 17.475)
const SIDE_DOOR_WIDE := 0.95
const STAIR_FOOT := Vector2(-44.2, 15.6)
const JOINT_X: Array[float] = [-78.0, -74.0, -70.0, -66.0, -62.0, -58.0, -54.0, -50.0]
const PANELS_ALONG := 7
## The staged loads, the empty pallets, the desk, its chair and the stair (`dock_staging.gd`,
## `dock_station.gd`, `dock_access.gd`): nothing wears where they stand.
const LOAD_SIZE := Vector2(1.016, 1.219)
const LOADS: Array[Vector2] = [Vector2(-64.55, 16.45), Vector2(-63.45, 16.45),
	Vector2(-64.55, 15.15), Vector2(-63.45, 15.15), Vector2(-52.0, 16.6), Vector2(-47.2, 16.6),
	Vector2(-49.9, 18.95)]
const KEEP_CLEAR: Array[Rect2] = [Rect2(-45.8, 17.5, 1.0, 2.1), Rect2(-46.5, 18.1, 0.7, 0.9),
	Rect2(-44.7, 12.92, 1.0, 2.25)]
const FORKLIFT := Vector2(-63.2, 12.4)
const FORKLIFT_HEADING := 0.2
## The forklift's ways: the cross-aisle between its lines at z 10 and 14, a counterbalance truck's
## wheels 0.96 m apart, turning into an aisle about 2 m round; the walkway down the east aisle.
const CROSS_AISLE := Vector2(10.0, 14.0)
const CROSS_TRACK := 12.0
const WHEELS := 0.48
const TURN := 2.0
const AISLE_DEPTH := -8.0
const WALKWAY_WEST := -46.6
const TYRE := 0.09
const BURNISH := 0.35
const NEAR_WET := 2.0
const WET_REACH := 6.0
const SEED := 294

var material: ShaderMaterial
## The four maps the material reads: grime, gloss, wet and patch.
var maps: Array[Texture2D] = []

var _marks: Array = []
var _images: Array[Image] = []
var _draw := RandomNumberGenerator.new()
var _brushes := {}


func _init() -> void:
	paint()


## Paints the four maps and builds the material over them; the same every time.
func paint() -> void:
	_marks.clear()
	_brushes.clear()
	_draw.seed = SEED
	var size := Vector2i(roundi(MAP.size.x * PER_METRE), roundi(MAP.size.y * PER_METRE))
	_images.clear()
	for index in range(4):
		var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_LA8)
		image.fill(Color(0.0, 0.0, 0.0, 1.0))
		_images.append(image)
	_ways()
	_scuffs()
	_oil()
	_patches()
	_wet()
	maps.clear()
	for image in _images:
		image.convert(Image.FORMAT_L8)
		image.generate_mipmaps()
		maps.append(ImageTexture.create_from_image(image))
	_material()


## Each mark painted: its `kind` ("tyre", "scuff", "oil", "patch" or "wet"), its `centre` on the
## floor (x, z), its `radius` and its `strength`.
func marks() -> Array:
	return _marks


## Each joint, as its two ends on the floor (x, z).
func joints() -> Array:
	var found := []
	for x in JOINT_X:
		found.append({"from": Vector2(x, DOCK.position.y), "to": Vector2(x, DOCK.end.y)})
	for z in joint_z():
		found.append({"from": Vector2(DOCK.position.x, z), "to": Vector2(DOCK.end.x, z)})
		found.append({"from": Vector2(LANE.position.x, z), "to": Vector2(LANE.end.x, z)})
	return found


## The joints along the floor, from the back wall to the dock face.
static func joint_z() -> Array[float]:
	var found: Array[float] = []
	for index in range(1, PANELS_ALONG):
		found.append(DOCK.position.y + DOCK.size.y * index / PANELS_ALONG)
	return found


func _material() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("floor_color", load(FLOOR_TEXTURES % "diff"))
	material.set_shader_parameter("floor_normal", load(FLOOR_TEXTURES % "nor_gl"))
	material.set_shader_parameter("floor_arm", load(FLOOR_TEXTURES % "arm"))
	for index in range(4):
		material.set_shader_parameter(["grime_map", "gloss_map", "wet_map", "patch_map"][index],
			maps[index])
	material.set_shader_parameter("map_rect", Vector4(MAP.position.x, MAP.position.y,
		MAP.size.x, MAP.size.y))
	material.set_shader_parameter("joint_rect", Vector4(DOCK.position.x, DOCK.position.y,
		MAP.end.x, MAP.end.y))
	material.set_shader_parameter("joint_x", PackedFloat32Array(JOINT_X))
	material.set_shader_parameter("joint_x_count", JOINT_X.size())
	material.set_shader_parameter("joint_z", PackedFloat32Array(joint_z()))
	material.set_shader_parameter("joint_z_count", joint_z().size())


## Tyre marks and burnished paths on the cross-aisle, each turn into an aisle and down it.
func _ways() -> void:
	var rows := Racking.rows(Racking.frame_lines())
	var paths: Array[PackedVector2Array] = [PackedVector2Array([Vector2(DOCK.position.x + 1.0,
		CROSS_TRACK), Vector2(WALKWAY_WEST + 0.2, CROSS_TRACK)])]
	for index in range(rows.size()):
		var west := rows[index].y + Racking.OVERHANG
		var east := rows[index + 1].x - Racking.OVERHANG if index + 1 < rows.size() \
			else WALKWAY_WEST
		var middle := (west + east) / 2.0
		var side := 1.0 if index % 2 == 0 and index + 1 < rows.size() else -1.0
		var path := PackedVector2Array()
		var centre := Vector2(middle + side * TURN, CROSS_AISLE.x)
		for step in range(13):
			var angle := PI / 2.0 + PI / 2.0 * step / 12.0
			path.append(centre + Vector2(side * cos(angle), sin(angle)) * TURN)
		path.append(Vector2(middle, AISLE_DEPTH))
		paths.append(path)
	for path in paths:
		_along(path, 0.0, BURNISH, 0.05, 1)
		for wheel: float in [-WHEELS, WHEELS]:
			for pass_index in range(4):
				_along(path, wheel + _draw.randf_range(-0.06, 0.06), TYRE,
					_draw.randf_range(0.05, 0.12), 0)


## Rubber scuffs before each leveller and the lift's deck, where loads are dragged and turned.
func _scuffs() -> void:
	var zones: Array[Rect2] = [Rect2(PIT.position.x - 0.3, PIT.position.y - 1.0, PIT.size.x + 0.6,
		1.0)]
	for x in DOCKS:
		zones.append(Rect2(x - LEVELLER.x / 2.0 - 0.1, FACE - LEVELLER.y - 1.0,
			LEVELLER.x + 0.2, 1.0))
	for zone in zones:
		for count in range(14):
			var start := zone.position + Vector2(_draw.randf() * zone.size.x,
				_draw.randf() * zone.size.y)
			var heading := Vector2.from_angle(_draw.randf() * TAU) * 0.06
			var radius := _draw.randf_range(0.04, 0.07)
			var strength := _draw.randf_range(0.3, 0.6)
			for step in range(_draw.randi_range(2, 6)):
				_stamp(0, start + heading * step, radius, strength, "scuff")


## Oil under the parked forklift: today's drip under its middle and older, fainter ones by it.
func _oil() -> void:
	var turn := Basis(Vector3.UP, FORKLIFT_HEADING)
	var drips: Array[Vector3] = [Vector3(0.0, 0.18, 0.35)]
	for count in range(5):
		drips.append(Vector3(_draw.randf_range(-0.3, 0.3), _draw.randf_range(0.04, 0.1),
			_draw.randf_range(-1.0, 1.0)))
	for drip in drips:
		var local := turn * Vector3(drip.x, 0.0, drip.z)
		var at := FORKLIFT + Vector2(local.x, local.z)
		var strength := 0.75 if drip.y > 0.15 else _draw.randf_range(0.3, 0.55)
		_stamp(0, at, drip.y, strength, "oil")
		_stamp(1, at, drip.y, strength, "")


## Grey epoxy where joints spalled: on the joints the forklift's wheels cross most, each repair
## sawn square along its joint, as such repairs are cut out and filled.
func _patches() -> void:
	var count := 0
	while count < 16:
		var on_x := _draw.randf() < 0.5
		var at: Vector2
		var along: Vector2
		if on_x:
			at = Vector2(JOINT_X[_draw.randi() % JOINT_X.size()], _draw.randf_range(CROSS_AISLE.x,
				FACE - 0.3))
			along = Vector2(0.0, 1.0)
		else:
			var zs := joint_z()
			at = Vector2(_draw.randf_range(DOCK.position.x + 0.5, LANE.end.x - 0.3),
				zs[_draw.randi_range(zs.size() - 2, zs.size() - 1)])
			along = Vector2(1.0, 0.0)
		var length := _draw.randf_range(0.2, 0.5)
		var wide := _draw.randf_range(0.08, 0.16)
		if not _free(at) or not _free(at + along * length / 2.0) \
				or not _free(at - along * length / 2.0):
			continue
		var size := along * length + along.orthogonal().abs() * wide
		var corner := at - size / 2.0
		_images[3].fill_rect(Rect2i(_pixel(corner), _pixel(corner + size) - _pixel(corner)),
			Color(1.0, 1.0, 1.0, 1.0))
		_marks.append({"kind": "patch", "centre": at, "radius": length / 2.0, "strength": 1.0})
		count += 1


## Rain blown in at the open doors: wet through 2 m, then tracks and footprints drying by 6 m.
func _wet() -> void:
	var doors: Array[Array] = [[Vector2(OPEN_DOCK - DOCK_OPENING / 2.0, FACE),
		Vector2(OPEN_DOCK + DOCK_OPENING / 2.0, FACE)], [Vector2(PIT.position.x, FACE),
		Vector2(PIT.end.x, FACE)], [SIDE_DOOR - Vector2(0.0, SIDE_DOOR_WIDE / 2.0),
		SIDE_DOOR + Vector2(0.0, SIDE_DOOR_WIDE / 2.0)]]
	for door in doors:
		var tried := 0
		var placed := 0
		while placed < 40 and tried < 400:
			tried += 1
			var on := (door[0] as Vector2).lerp(door[1], _draw.randf())
			var inward := Vector2(-1.0, 0.0) if door == doors[2] else Vector2(0.0, -1.0)
			var at := on + inward * _draw.randf() * NEAR_WET \
				+ inward.orthogonal() * _draw.randf_range(-1.0, 1.0)
			if _to_door(at, door) > NEAR_WET - 0.3 or not _free(at):
				continue
			_stamp(2, at, _draw.randf_range(0.25, 0.45), _draw.randf_range(0.6, 0.9), "wet")
			placed += 1
	_tracks(PackedVector2Array([Vector2(OPEN_DOCK - 1.9, FACE - 1.3),
		Vector2(OPEN_DOCK - 2.3, 13.8)]), doors[0], 0.12)
	_tracks(PackedVector2Array([Vector2(OPEN_DOCK + 1.9, FACE - 1.3),
		Vector2(OPEN_DOCK + 2.3, 13.8)]), doors[0], 0.12)
	_tracks(PackedVector2Array([Vector2(PIT.position.x + 0.15, PIT.position.y - 0.1),
		Vector2(PIT.position.x - 0.4, 13.8)]), doors[1], 0.1)
	_footprints(PackedVector2Array([SIDE_DOOR + Vector2(-0.3, 0.0), Vector2(-42.6, 16.9),
		STAIR_FOOT]), doors[2])


func _tracks(path: PackedVector2Array, door: Array, radius: float) -> void:
	for wheel: float in [-0.3, 0.3]:
		var points := _points(path, wheel, radius * 1.5)
		for point in points:
			var strength := _drying(_to_door(point, door))
			if strength > 0.02 and _free(point):
				_stamp(2, point, radius, strength, "wet")


func _footprints(path: PackedVector2Array, door: Array) -> void:
	var points := _points(path, 0.0, 0.33)
	for index in range(points.size()):
		var ahead := points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		var side := ahead.normalized().orthogonal() * (0.09 if index % 2 == 0 else -0.09)
		var at := points[index] + side
		var strength := _drying(_to_door(at, door))
		if strength > 0.02 and _free(at):
			_stamp(2, at, 0.06, strength, "wet")
			_stamp(2, at + ahead.normalized() * 0.1, 0.05, strength * 0.8, "wet")


## How wet a track is this far in from its door: drying out by WET_REACH.
func _drying(distance: float) -> float:
	return 0.75 * pow(clampf(1.0 - distance / WET_REACH, 0.0, 1.0), 1.3)


## A wheel's mark along `path`, `offset` to its left, in the grime (0) or gloss (1) map.
func _along(path: PackedVector2Array, offset: float, radius: float, strength: float,
		channel: int) -> void:
	for point in _points(path, offset, radius):
		_stamp(channel, point, radius, strength, "tyre")


## Points every `step` along `path`, `offset` to its left.
func _points(path: PackedVector2Array, offset: float, step: float) -> PackedVector2Array:
	var found := PackedVector2Array()
	for index in range(path.size() - 1):
		var from := path[index]
		var to := path[index + 1]
		var side := (to - from).normalized().orthogonal() * offset
		var count := maxi(ceili(from.distance_to(to) / step), 1)
		for step_index in range(count):
			found.append(from.lerp(to, float(step_index) / count) + side)
	return found


func _stamp(channel: int, at: Vector2, radius: float, strength: float, kind: String) -> void:
	if not _free(at):
		return
	var pixels := maxi(ceili(radius * PER_METRE), 1)
	var key := Vector2i(pixels, roundi(strength * 100.0))
	if not _brushes.has(key):
		_brushes[key] = _brush(pixels, key.y / 100.0)
	var brush: Image = _brushes[key]
	var centre := _pixel(at)
	_images[channel].blend_rect(brush, Rect2i(Vector2i.ZERO, brush.get_size()),
		centre - Vector2i(pixels, pixels))
	if kind != "":
		_marks.append({"kind": kind, "centre": at, "radius": radius, "strength": strength})


## The map's pixel under a point on the floor.
func _pixel(at: Vector2) -> Vector2i:
	return Vector2i(roundi((at.x - MAP.position.x) * PER_METRE),
		roundi((at.y - MAP.position.y) * PER_METRE))


## A soft round brush `pixels` in radius: white, its alpha `strength` at its middle falling to 0.
func _brush(pixels: int, strength: float) -> Image:
	var side := pixels * 2 + 1
	var brush := Image.create_empty(side, side, false, Image.FORMAT_LA8)
	for y in range(side):
		for x in range(side):
			var reach := Vector2(x - pixels, y - pixels).length() / (pixels + 0.5)
			var alpha := strength * clampf(1.0 - reach * reach, 0.0, 1.0)
			brush.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return brush


## Whether a point is on the floor, out of the pit and clear of what stands on it.
func _free(at: Vector2) -> bool:
	if not (DOCK.has_point(at) or LANE.has_point(at)) or PIT.has_point(at):
		return false
	for load in LOADS:
		if Rect2(load - LOAD_SIZE / 2.0, LOAD_SIZE).has_point(at):
			return false
	for rect in KEEP_CLEAR:
		if rect.has_point(at):
			return false
	return true


func _to_door(point: Vector2, door: Array) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, door[0], door[1]))
