extends Node3D
## The bigger depot's ground (docs/PHASE_BRIEF.md, Phase 2 step 2c revised, part 1): the platform
## cut level into the hill, and the concrete walls that hold the cut, each as high as the ground
## 3 m behind it. The terrain flattens FLAT grown by 2 m, which reaches the grid points on the
## walls' lines, so no slope shows in front of a wall.

const Build = preload("res://shared/components/mesh_builder.gd")
const PLATFORM := Rect2(-92.0, -13.0, 66.0, 68.0)
const FLAT := Rect2(-90.0, -12.0, 62.0, 66.0)
const CLEARING := Rect2(-96.0, -17.0, 74.0, 76.0)
const THICKNESS := 0.4
const CAP := 0.2
const STEP := 2.0
const BEHIND := 3.0
const LOWEST := 0.25

var _runs: Array[Dictionary] = []


static func flat_plots() -> Array[Rect2]:
	return [FLAT]


func build(terrain: Node3D, concrete: Material) -> void:
	var back := PLATFORM.position.y - THICKNESS / 2.0
	var highest := 0.0
	var x := PLATFORM.position.x
	while x <= PLATFORM.end.x + 0.01:
		highest = maxf(highest, _ground(terrain, x, PLATFORM.position.y - BEHIND))
		x += 0.5
	var top := highest + CAP
	var west := PLATFORM.position.x - THICKNESS
	var east := PLATFORM.end.x + THICKNESS
	Build.box(self, Vector3((west + east) / 2.0, top / 2.0, back), Vector3(east - west, top,
		THICKNESS), concrete, true).name = "CutWallNorth"
	_runs.append({"from": Vector3(west, top, back), "to": Vector3(east, top, back),
		"outward": Vector3.FORWARD})
	_side(terrain, concrete, PLATFORM.position.x - THICKNESS / 2.0, -1.0, "CutWallWest")
	_side(terrain, concrete, PLATFORM.end.x + THICKNESS / 2.0, 1.0, "CutWallEast")


func top_runs() -> Array[Dictionary]:
	return _runs


func _side(terrain: Node3D, concrete: Material, line_x: float, out: float, name: String) -> void:
	var behind := line_x + out * (BEHIND - THICKNESS / 2.0)
	var z := PLATFORM.position.y
	while z < PLATFORM.end.y - 0.01:
		var ground := 0.0
		for along: float in [0.0, 0.5, 1.0, 1.5, 2.0]:
			ground = maxf(ground, _ground(terrain, behind, z + along))
		if ground >= LOWEST:
			var top := ground + CAP
			Build.box(self, Vector3(line_x, top / 2.0, z + STEP / 2.0), Vector3(THICKNESS, top,
				STEP), concrete, true).name = name
			_runs.append({"from": Vector3(line_x, top, z), "to": Vector3(line_x, top, z + STEP),
				"outward": Vector3(out, 0.0, 0.0)})
		z += STEP


func _ground(terrain: Node3D, x: float, z: float) -> float:
	return float(terrain.call("height_at", x, z))
