extends RefCounted
## Mission 2's opening (#358, step 8; GAME_STORY's Act I, "Days later, Ethan is offered a
## better-paying freight route"; S5 decided by Claude Code at the author's word, a draft: the
## windshield replaced), in the cutscenes' neo-noir look (#357): DAYS LATER on black; the depot's
## forecourt in the rain, the van under its lamps, the camera drifting in; close on the new
## windshield, beaded and clean where the crack was; and THE WRONG CARGO filling the screen on
## black (the mission's name, C35, never the game's title, C04), the camera then high over the van
## sweeping down to the cab. Each cut dips through black; each place is worked out from the van.

const CARD := ["DAYS LATER", "BLACKRIDGE FREIGHT DEPOT"]
const TITLE := ["THE WRONG CARGO", "MISSION TWO"]


static func _look(eye: Vector3, at: Vector3) -> Transform3D:
	var up := Vector3.UP if absf((at - eye).normalized().y) < 0.98 else Vector3.FORWARD
	return Transform3D(Basis.looking_at(at - eye, up), eye)


static func shots(van: Node3D) -> Array:
	var body := van.to_global(Vector3(0.0, 1.2, 0.0))
	var glass := van.to_global(Vector3(0.0, 1.65, -1.75))
	var high := van.to_global(Vector3(-9.0, 9.0, -14.0))
	return [
		{"name": "days_later", "seconds": 4.0, "black": true, "card": CARD,
			"from": _look(high, body), "to": _look(high, body)},
		{"name": "depot", "seconds": 6.0, "fov": Vector2(42.0, 36.0), "exposure": 1.4,
			"gamma": 0.7,
			"from": _look(van.to_global(Vector3(-11.0, 4.5, -16.0)), body),
			"to": _look(van.to_global(Vector3(-8.5, 3.6, -13.0)), body)},
		{"name": "new_glass", "seconds": 5.0, "fov": Vector2(30.0, 28.0), "exposure": 1.3,
			"gamma": 0.75,
			"from": _look(van.to_global(Vector3(0.9, 1.9, -4.6)), glass),
			"to": _look(van.to_global(Vector3(0.6, 1.85, -4.2)), glass)},
		{"name": "title", "seconds": 8.0, "fov": Vector2(40.0, 40.0), "full_card": TITLE,
			"hold": 3.6, "exposure": 1.2, "gamma": 0.8,
			"from": _look(high, body), "to": "player"},
	]
