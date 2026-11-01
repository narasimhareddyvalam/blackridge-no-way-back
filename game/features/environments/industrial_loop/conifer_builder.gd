extends RefCounted

const BARK_TILE := 2.0
const CARD_ROLL := 65.0
const DEADWOOD_START := 1.3
const DEADWOOD_SEED := 7919
const MATURE_CROWN := Vector2(0.3, 0.45)


static func build(height: float, spread: float, seed_value: int, detail: float,
		bark: Material, needles: Material, crown: Vector2 = MATURE_CROWN) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh := ArrayMesh.new()
	var stem := height * (0.85 if height < 6.0 else 1.0)
	_add_trunk(mesh, stem, trunk_radius(height), 8 if detail >= 1.0 else 5, bark)
	_add_crown(mesh, height, _crown_start(height, rng, crown), spread, rng, detail, needles)
	return mesh


static func build_deadwood(height: float, seed_value: int, deadwood: Material) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh := ArrayMesh.new()
	_add_deadwood(mesh, _crown_start(height, rng, MATURE_CROWN), seed_value, deadwood)
	return mesh


static func trunk_radius(height: float) -> float:
	if height < 6.0:
		return 0.008 * height + 0.002
	return 0.012 * height + 0.08 * clampf(height / 12.0, 0.1, 1.0)


static func _crown_start(height: float, rng: RandomNumberGenerator, crown: Vector2) -> float:
	return height * rng.randf_range(crown.x, crown.y)


static func _add_trunk(mesh: ArrayMesh, height: float, radius: float, sides: int,
		bark: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 6
	var wrap := TAU * radius / BARK_TILE
	var leader := 0.015 * minf(1.0, height / 8.0)
	var taper := 0.85 if height >= 6.0 else 0.95
	for ring in range(rings):
		var y0 := height * float(ring) / rings
		var y1 := height * float(ring + 1) / rings
		var r0 := radius * (1.0 - taper * y0 / height) + leader
		var r1 := radius * (1.0 - taper * y1 / height) + leader
		for side in range(sides):
			var a0 := TAU * side / sides
			var a1 := TAU * (side + 1) / sides
			var u0 := wrap * side / sides
			var u1 := wrap * (side + 1) / sides
			var corners := [[a0, y0, r0, u0], [a1, y0, r0, u1], [a1, y1, r1, u1],
				[a0, y0, r0, u0], [a1, y1, r1, u1], [a0, y1, r1, u0]]
			for corner: Array in corners:
				var angle: float = corner[0]
				var outward := Vector3(cos(angle), 0.0, sin(angle))
				tool.set_normal(outward)
				tool.set_uv(Vector2(corner[3], corner[1] / BARK_TILE))
				tool.add_vertex(outward * corner[2] + Vector3.UP * corner[1])
	tool.generate_tangents()
	tool.set_material(bark)
	tool.commit(mesh)


static func _add_crown(mesh: ArrayMesh, height: float, start: float, spread: float,
		rng: RandomNumberGenerator, detail: float, needles: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var youth := minf(1.0, height / 8.0)
	var young := height < 6.0
	var spacing := 0.55 * minf(1.0, height / 6.0) * (0.8 if young else 1.0) / detail
	var per_whorl := (5 if detail >= 1.0 else 3) + (2 if young else 0)
	var widen := 1.0 if detail >= 1.0 else 1.3
	var y := start
	while y < height - minf(0.8, height * 0.25):
		var t := (y - start) / (height - start)
		var reach := (spread * pow(1.0 - t, 0.85) * rng.randf_range(0.85, 1.12) + 0.45 * youth) \
			* widen
		var droop := lerpf(lerpf(-4.0, 22.0, t), lerpf(-24.0, 10.0, t), youth)
		var pitch := deg_to_rad(droop + rng.randf_range(-6.0, 6.0))
		var offset := rng.randf() * TAU
		for index in range(per_whorl):
			var yaw := offset + TAU * index / per_whorl + rng.randf_range(-0.35, 0.35)
			_add_branch(tool, Vector3(0.0, y, 0.0), yaw, pitch, reach, rng)
		y += spacing * rng.randf_range(0.8, 1.2)
	_add_top(tool, height)
	tool.generate_tangents()
	tool.set_material(needles)
	tool.commit(mesh)


static func _add_deadwood(mesh: ArrayMesh, crown: float, seed_value: int,
		deadwood: Material) -> void:
	if crown - 0.3 <= DEADWOOD_START:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + DEADWOOD_SEED
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := DEADWOOD_START
	while y < crown - 0.3:
		var t := (y - DEADWOOD_START) / (crown - DEADWOOD_START)
		for index in range(rng.randi_range(2, 4)):
			var pitch := deg_to_rad(rng.randf_range(-20.0, 10.0))
			var reach := rng.randf_range(0.45, 0.9) * lerpf(1.0, 1.7, t)
			_add_branch(tool, Vector3(0.0, y, 0.0), rng.randf() * TAU, pitch, reach, rng)
		y += rng.randf_range(0.25, 0.45)
	tool.generate_tangents()
	tool.set_material(deadwood)
	tool.commit(mesh)


static func _add_branch(tool: SurfaceTool, base: Vector3, yaw: float, pitch: float,
		reach: float, rng: RandomNumberGenerator) -> void:
	var direction := Vector3(cos(yaw) * cos(pitch), sin(pitch), sin(yaw) * cos(pitch))
	var side := direction.cross(Vector3.UP).normalized()
	var tip := base + direction * reach + Vector3.DOWN * reach * 0.12
	var flip := rng.randf() < 0.5
	for roll: float in [0.0, deg_to_rad(CARD_ROLL)]:
		var across := side.rotated(direction, roll) * reach * 0.25
		_card(tool, base, tip, across, flip)


static func _add_top(tool: SurfaceTool, height: float) -> void:
	var scale := minf(1.0, height / 6.0)
	var base := Vector3(0.0, height - minf(1.9, height * 0.4), 0.0)
	var tip := Vector3(0.0, height + 0.25 * scale, 0.0)
	for across: Vector3 in [Vector3(0.45 * scale, 0.0, 0.0), Vector3(0.0, 0.0, 0.45 * scale)]:
		_card(tool, base, tip, across, false)


static func _card(tool: SurfaceTool, base: Vector3, tip: Vector3, across: Vector3,
		flip: bool) -> void:
	var v0 := 1.0 if flip else 0.0
	var v1 := 0.0 if flip else 1.0
	var corners := [[base - across, Vector2(0.0, v0)], [base + across, Vector2(0.0, v1)],
		[tip + across, Vector2(1.0, v1)], [base - across, Vector2(0.0, v0)],
		[tip + across, Vector2(1.0, v1)], [tip - across, Vector2(1.0, v0)]]
	for corner: Array in corners:
		var point: Vector3 = corner[0]
		var outward := Vector3(point.x, 0.0, point.z)
		var normal := Vector3.UP
		if outward.length() > 0.05:
			normal = (outward.normalized() * 0.8 + Vector3.UP * 0.6).normalized()
		tool.set_normal(normal)
		tool.set_uv(corner[1])
		tool.add_vertex(point)
