extends RefCounted
## Mission 1's opening cutscene (#357; GAME_STORY's prologue, "a long, lonely drive through
## Blackridge in cold rain", C35; the author's storyboard, take 2): the studio card on black; a
## street lamp's amber in the wet road, the camera rising from the asphalt to the lamp; straight
## down on the hill road's sharpest hairpin, rising and turning, BLACKRIDGE 23:41; low at the kerb
## of the empty zebra crossing, creeping forward; out of the empty shelter at the road, held a beat
## too long (nobody there: GAME_STORY's "no visible witness"); Ethan's face under the office lamp,
## lit by a warm key and a cool rim; from the dark cab through the wet windshield, Ethan a blur
## beyond it; and NIGHT FREIGHT filling the screen on black (the mission's name, C35, never the
## game's title, C04), then the camera high over him small beside the van sweeping down to the
## player's own camera behind him at the clipboard. Each cut dips through black. Each shot's place is worked out from the world as it stands.

const STUDIO := ["NRVALAM WORKS", "PRESENTS"]
const PLACE := ["BLACKRIDGE", "23:41"]
const TITLE := ["NIGHT FREIGHT", "MISSION ONE"]
const KEY := Color(1.0, 0.78, 0.55)
const RIM := Color(0.55, 0.7, 1.0)


static func _look(eye: Vector3, at: Vector3) -> Transform3D:
	var up := Vector3.UP if absf((at - eye).normalized().y) < 0.98 else Vector3.FORWARD
	return Transform3D(Basis.looking_at(at - eye, up), eye)


static func shots(world: Node3D, van: Node3D, driver: Node3D) -> Array:
	var points: PackedVector3Array = world.get("road_points")
	var rain := world.get("lamp_rain") as Node3D
	var lamp_head := points[0] + Vector3.UP * 6.0
	for volume: Node3D in rain.get("volumes"):
		if String(volume.name).begins_with("LampRainStreet"):
			lamp_head = volume.global_position
			break
	var lamp_foot := Vector3(lamp_head.x, 0.0, lamp_head.z)
	var near := 0
	for index in range(points.size() - 5):
		if points[index].distance_to(lamp_foot) < points[near].distance_to(lamp_foot):
			near = index
	var along := (points[near + 4] - points[near]).normalized()
	var road_level := points[near] - along * 7.0 + Vector3.UP * 0.16
	var sharpest := 10
	var turn := 0.0
	for index in range(10, points.size() - 10):
		var before := (points[index] - points[index - 8]).normalized()
		var after := (points[index + 8] - points[index]).normalized()
		if before.angle_to(after) > turn:
			turn = before.angle_to(after)
			sharpest = index
	var hairpin := points[sharpest]
	var stop := world.get("crossing") as Node3D
	var centre: Vector3 = stop.get("centre")
	var right: Vector3 = stop.get("right")
	var forward: Vector3 = stop.get("forward")
	var kerb: Vector3 = stop.get("kerb")
	var face := driver.global_position + Vector3.UP * 1.62
	var toward := van.global_position - driver.global_position
	toward.y = 0.0
	toward = toward.normalized()
	var side := toward.cross(Vector3.UP)
	var cab_eye := van.to_global(Vector3(-0.45, 1.8, -0.72))
	var crane_at := driver.global_position.lerp(van.global_position, 0.45)
	var crane_high := driver.global_position - toward * 6.0 + side * 3.0 + Vector3.UP * 13.0
	var crossing_eye := centre - right * 4.6 + forward * 6.0 + Vector3.UP * 0.3
	var crossing_at := centre + right * 1.0 + Vector3.UP * 0.6
	var shelter_eye := kerb + right * 2.2 + Vector3.UP * 1.2 - forward * 0.6
	var shelter_at := centre - right * 2.0 + Vector3.UP * 0.8
	return [
		{"name": "studio", "seconds": 4.0, "black": true, "card": STUDIO,
			"from": _look(road_level, lamp_head), "to": _look(road_level, lamp_head)},
		{"name": "lamp_in_the_water", "seconds": 7.0, "fov": Vector2(30.0, 30.0), "focus": 12.0,
			"exposure": 1.3, "gamma": 0.8,
			"from": _look(road_level, points[near] - along * 2.5 + Vector3.UP * 0.25),
			"to": _look(road_level + Vector3.UP * 0.5, lamp_head)},
		{"name": "hill_road", "seconds": 7.0, "fov": Vector2(50.0, 46.0), "caption": PLACE,
			"exposure": 1.9, "gamma": 0.5,
			"from": _look(hairpin + Vector3(6.0, 48.0, 10.0), hairpin),
			"to": _look(hairpin + Vector3(-9.0, 60.0, 6.0), hairpin)},
		{"name": "crossing", "seconds": 6.0, "fov": Vector2(24.0, 24.0), "exposure": 1.5,
			"gamma": 0.6,
			"from": _look(crossing_eye, crossing_at),
			"to": _look(crossing_eye + (crossing_at - crossing_eye).normalized() * 1.2,
				crossing_at)},
		{"name": "empty_shelter", "seconds": 6.0, "fov": Vector2(34.0, 33.0), "exposure": 1.5,
			"gamma": 0.6,
			"from": _look(shelter_eye, shelter_at),
			"to": _look(shelter_eye + (shelter_at - shelter_eye).normalized() * 0.4, shelter_at)},
		{"name": "ethan", "seconds": 6.0, "fov": Vector2(26.0, 25.0),
			"lights": [
				{"at": face + toward * 0.8 - side * 0.9 + Vector3.UP * 0.25, "colour": KEY,
					"energy": 1.2, "range": 3.0},
				{"at": face - toward * 0.8 + side * 0.6 + Vector3.UP * 0.35, "colour": RIM,
					"energy": 2.5, "range": 3.0}],
			"from": _look(face + toward * 0.75 - side * 0.25 + Vector3.DOWN * 0.05,
				face + Vector3.UP * 0.04),
			"to": _look(face + toward * 0.65 - side * 0.22 + Vector3.DOWN * 0.05,
				face + Vector3.UP * 0.04)},
		{"name": "van_waits", "seconds": 5.0, "fov": Vector2(40.0, 38.0),
			"from": _look(cab_eye, driver.global_position + Vector3.UP * 1.3),
			"to": _look(cab_eye + Vector3(0.0, 0.03, 0.0), driver.global_position
				+ Vector3.UP * 1.3)},
		{"name": "title", "seconds": 8.0, "fov": Vector2(40.0, 40.0), "full_card": TITLE,
			"hold": 3.6, "exposure": 1.2, "gamma": 0.8,
			"from": _look(crane_high, crane_at), "to": "player"},
	]
