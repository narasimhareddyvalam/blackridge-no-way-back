extends RefCounted

enum Section { VALLEY, CLIMB, CLIMB_HAIRPIN, TOP, DESCENT, DESCENT_HAIRPIN }

const SPACING := 2.0
const SUMMIT := 62.0
const CREST := 2.5
const HAIRPIN_EFFORT := 0.35
const SMOOTHING := 21
const HALF_WIDTH := 2.25
const HAIRPIN_EXTRA := 1.0
const VERGE := 1.15
const WAYPOINTS: Array = [
	[Vector2(560, 130), 180.0, Section.VALLEY, 0.38],
	[Vector2(455, 128), 180.0, Section.VALLEY, 0.40],
	[Vector2(402, 82), 250.0, Section.CLIMB, 0.38],
	[Vector2(360, 56), 196.0, Section.CLIMB, 0.38],
	[Vector2(298, 46), 190.0, Section.CLIMB_HAIRPIN, 0.68],
	[Vector2(304, 16), 350.0, Section.CLIMB, 0.38],
	[Vector2(392, 2), 352.0, Section.CLIMB, 0.38],
	[Vector2(468, -8), 346.0, Section.CLIMB_HAIRPIN, 0.70],
	[Vector2(466, -38), 192.0, Section.CLIMB, 0.36],
	[Vector2(418, -46), 172.0, Section.CLIMB, 0.36],
	[Vector2(360, -58), 196.0, Section.CLIMB_HAIRPIN, 0.66],
	[Vector2(364, -84), 348.0, Section.CLIMB, 0.38],
	[Vector2(444, -98), 344.0, Section.CLIMB_HAIRPIN, 0.74, 2.5],
	[Vector2(438, -130), 194.0, Section.CLIMB, 0.38],
	[Vector2(372, -138), 184.0, Section.CLIMB, 0.38],
	[Vector2(318, -152), 200.0, Section.CLIMB, 0.38],
	[Vector2(236, -188), 192.0, Section.TOP, 0.38],
	[Vector2(150, -206), 172.0, Section.TOP, 0.38],
	[Vector2(90, -196), 164.0, Section.DESCENT, 0.38],
	[Vector2(22, -176), 160.0, Section.DESCENT_HAIRPIN, 0.70],
	[Vector2(30, -146), 16.0, Section.DESCENT, 0.38],
	[Vector2(150, -120), 12.0, Section.DESCENT_HAIRPIN, 0.72],
	[Vector2(144, -90), 190.0, Section.DESCENT, 0.38],
	[Vector2(70, -80), 176.0, Section.DESCENT, 0.38],
	[Vector2(-10, -66), 166.0, Section.DESCENT_HAIRPIN, 0.68],
	[Vector2(-2, -38), 12.0, Section.DESCENT, 0.38],
	[Vector2(80, -24), 6.0, Section.DESCENT, 0.38],
	[Vector2(150, -12), 16.0, Section.DESCENT_HAIRPIN, 0.70],
	[Vector2(146, 18), 186.0, Section.DESCENT, 0.40],
	[Vector2(64, 40), 160.0, Section.VALLEY, 0.40],
	[Vector2(10, 68), 180.0, Section.VALLEY, 0.38],
	[Vector2(-62, 72), 180.0, Section.VALLEY, 0.40],
	[Vector2(-108, 120), 90.0, Section.VALLEY, 0.40],
	[Vector2(-60, 168), 0.0, Section.VALLEY, 0.38],
	[Vector2(150, 172), 0.0, Section.VALLEY, 0.38],
	[Vector2(330, 166), 356.0, Section.VALLEY, 0.38],
	[Vector2(520, 170), 0.0, Section.VALLEY, 0.40],
	[Vector2(610, 150), 270.0, Section.VALLEY, 0.42],
]

var points := PackedVector3Array()
var half_widths := PackedFloat32Array()
var sections := PackedByteArray()
var laybys := PackedFloat32Array()
var length: float = 0.0


func _init() -> void:
	var flat := PackedVector2Array()
	for index in range(WAYPOINTS.size()):
		var here: Array = WAYPOINTS[index]
		var there: Array = WAYPOINTS[(index + 1) % WAYPOINTS.size()]
		for point in _curve(here, there):
			flat.append(point)
			sections.append(here[2])
			laybys.append(here[4] if here.size() > 4 else 0.0)
	_resample(flat)
	_elevate()
	_widen()


func is_hairpin(index: int) -> bool:
	return sections[index] in [Section.CLIMB_HAIRPIN, Section.DESCENT_HAIRPIN]


func heading_at(index: int) -> float:
	var ahead := points[(index + 1) % points.size()] - points[index]
	return atan2(-ahead.x, -ahead.z)


func grade_at(index: int) -> float:
	var ahead := points[(index + 1) % points.size()] - points[index]
	return ahead.y / maxf(Vector2(ahead.x, ahead.z).length(), 0.001)


func _curve(here: Array, there: Array) -> PackedVector2Array:
	var start: Vector2 = here[0]
	var end: Vector2 = there[0]
	var reach: float = start.distance_to(end) * here[3]
	var lead := start + Vector2.from_angle(deg_to_rad(here[1])) * reach
	var trail := end - Vector2.from_angle(deg_to_rad(there[1])) * reach
	var result := PackedVector2Array()
	var steps := 600
	for step in range(steps):
		result.append(start.bezier_interpolate(lead, trail, end, float(step) / steps))
	return result


func _resample(flat: PackedVector2Array) -> void:
	var raw_sections := sections.duplicate()
	var raw_laybys := laybys.duplicate()
	sections = PackedByteArray()
	laybys = PackedFloat32Array()
	var travelled := 0.0
	var next_mark := 0.0
	for index in range(flat.size()):
		var a := flat[index]
		var b := flat[(index + 1) % flat.size()]
		var step := a.distance_to(b)
		while next_mark <= travelled + step and step > 0.0:
			var at := a.lerp(b, (next_mark - travelled) / step)
			points.append(Vector3(at.x, 0.0, at.y))
			sections.append(raw_sections[index])
			laybys.append(raw_laybys[index])
			next_mark += SPACING
		travelled += step
	length = travelled


func _elevate() -> void:
	var effort := PackedFloat32Array()
	effort.resize(points.size())
	var climb_total := 0.0
	var descent_total := 0.0
	for index in range(points.size()):
		var weight := HAIRPIN_EFFORT if is_hairpin(index) else 1.0
		match sections[index]:
			Section.CLIMB, Section.CLIMB_HAIRPIN:
				climb_total += weight
				effort[index] = climb_total
			Section.DESCENT, Section.DESCENT_HAIRPIN:
				descent_total += weight
				effort[index] = descent_total
	var top_first := sections.find(Section.TOP)
	var top_count := sections.count(Section.TOP)
	var raw := PackedFloat32Array()
	raw.resize(points.size())
	for index in range(points.size()):
		match sections[index]:
			Section.CLIMB, Section.CLIMB_HAIRPIN:
				raw[index] = SUMMIT * effort[index] / climb_total
			Section.DESCENT, Section.DESCENT_HAIRPIN:
				raw[index] = SUMMIT * (1.0 - effort[index] / descent_total)
			Section.TOP:
				raw[index] = SUMMIT + CREST * sin(PI * float(index - top_first) / top_count)
	var half := SMOOTHING / 2
	for index in range(points.size()):
		var total := 0.0
		for offset in range(-half, half + 1):
			total += raw[posmod(index + offset, points.size())]
		points[index].y = total / SMOOTHING


func _widen() -> void:
	half_widths.resize(points.size())
	var reach := 6
	for index in range(points.size()):
		var near := 0.0
		var lay := 0.0
		for offset in range(-reach, reach + 1):
			var other := posmod(index + offset, points.size())
			if is_hairpin(other):
				near += 1.0
			lay += laybys[other]
		half_widths[index] = HALF_WIDTH + HAIRPIN_EXTRA * smoothstep(0.0, 1.0,
			near / (2 * reach + 1) * 2.0) + lay / (2 * reach + 1)


func is_layby(index: int) -> bool:
	return laybys[index] > 0.0
