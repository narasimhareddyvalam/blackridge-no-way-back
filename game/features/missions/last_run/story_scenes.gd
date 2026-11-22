extends RefCounted
## Mission 3's story scenes (step 4, docs/PHASE_BRIEF.md, 2026-11-21, #359-#360; GAME_STORY's Acts
## III-IV), in the cutscenes' neo-noir look (#357): the confrontation at the depot, the recording,
## and the reconciliation at the viewpoint. Each is its shots (worked out from where Maya and Ethan
## stand) and its lines, [seconds from the start, speaker, words, seconds shown]. Every word is a
## draft by Claude Code at the author's word (#359), for the author's review; N03 (how the recording
## is made and believed) is answered as a draft: Maya recorded Adrian's call herself, and the
## records match the nights Ethan drove.

const CONFRONTATION_LINES: Array = [
	[2.0, "ETHAN", "Whose phone was that, Maya? Your number's in it.", 3.6],
	[6.0, "MAYA", "I routed your jobs. Every one of them.", 3.0],
	[9.5, "ETHAN", "They tried to kill me tonight.", 2.5],
	[12.5, "MAYA", "I know. I'm married, Ethan. To Adrian Vale.", 3.4],
	[16.4, "ETHAN", "Vale. Vale Freight.", 2.0],
	[18.8, "MAYA", "We have a daughter. Lily. She's five.", 3.0],
	[22.2, "ETHAN", "Five years. And you never said a word.", 3.0],
	[25.6, "MAYA", "He has her. If I don't do what he says...", 3.2],
	[29.2, "ETHAN", "So you chose. Her over me.", 2.6],
	[32.2, "MAYA", "That's not what this is. Please. Listen to it. Then decide.", 3.6],
	[36.4, "ETHAN", "I raised you, Maya.", 2.4],
	[39.2, "ETHAN", "Don't call me.", 2.0],
]
const RECONCILIATION_LINES: Array = [
	[2.0, "MAYA", "I'm not asking you to forgive me.", 2.8],
	[5.2, "MAYA", "I thought about it. For a second, I thought about saying yes.", 3.4],
	[9.0, "ETHAN", "I heard.", 1.6],
	[11.0, "ETHAN", "I heard you say no, too.", 2.4],
	[13.8, "ETHAN", "I forgive you, Maya. Trusting you again will take longer.", 3.6],
	[17.8, "MAYA", "That's fair.", 1.6],
	[19.8, "MAYA", "He knows I turned. He's taking Lily tonight. A private plane, from the "
		+ "airfield.", 4.0],
	[24.4, "ETHAN", "Then we bring her home.", 2.4],
	[27.2, "MAYA", "Bring her home. And come home yourself.", 3.0],
]
## At the service gate (step 7): Adrian comes through it behind Ethan, Lily already with Maya. He
## draws at DRAW_AT and Ethan fires at SHOT_AT; the black shot hides the fall; after it only his
## pistol on the wet ground, fallen ahead of him, and his shoes behind it are seen. Every word a draft (#359); nothing in them says how
## Adrian learned of the hit (N02 stays open).
const GATE_LINES: Array = [
	[1.0, "MAYA", "Ethan.", 1.4],
	[2.9, "ADRIAN", "Maya.", 1.4],
	[7.0, "ADRIAN", "Eleven years I built that company. You gave it away in a week.", 3.6],
	[11.0, "ADRIAN", "And you brought him into it.", 2.0],
	[13.6, "ETHAN", "It's over, Adrian. Let them go home.", 2.8],
	[16.8, "ETHAN", "Keep your hands where I can see them.", 2.4],
	[19.4, "MAYA", "Lily. Look at me. Only at me.", 2.8],
	[23.0, "ADRIAN", "She's my daughter.", 1.4],
	[24.1, "ETHAN", "Don't!", 0.6],
	[27.5, "MAYA", "Ethan...", 1.6],
	[29.8, "ETHAN", "Take her to the car. Don't let her look.", 3.0],
]
const ADRIAN_TALKS: Array = [[2.9, 4.3], [7.0, 13.0], [23.0, 23.4]]
const DRAW_AT := 23.4
const AIM_AT := 23.5
const SHOT_AT := 24.3
const FALL_AT := 25.0
## After it (step 8; GAME_STORY's "Resolution"): Maya and Lily together, Ethan and Maya speak
## openly about the past, his sacrifices a bond and a burden, and he means to tell the police all of
## it, the collision included, as police lights come up the freight track. Then two cards: N05's
## draft (he told them everything that night; the outcome left off-screen) and the time cut, a
## beat of black between them. Every
## word a draft (#359).
const REUNION_LINES: Array = [
	[1.5, "LILY", "Mommy, can we go home now?", 2.4],
	[4.4, "MAYA", "Soon, baby. Soon.", 2.0],
	[7.4, "MAYA", "You gave up so much for me, Ethan. All those years.", 3.2],
	[11.0, "MAYA", "I never knew how to carry that. So I hid from it.", 3.2],
	[14.6, "ETHAN", "It was never yours to carry.", 2.4],
	[17.6, "ETHAN", "When they get here, I'm telling them everything. The hill road too.", 3.6],
	[21.8, "MAYA", "Then I'll be right there with you.", 2.6],
]
const STATEMENT := ["HE TOLD THEM EVERYTHING", "THAT NIGHT. THE HILL ROAD INCLUDED."]
const LATER := ["SIX MONTHS LATER", "BLACKRIDGE"]
## The recording and the records on Maya's phone (step 4; N03's draft).
const RECORDING := "MAYA'S PHONE  ·  VOICE MEMO  ·  19 NOV 23:14  ·  1:52\n\n" \
	+ "ADRIAN: Bring him to berth 2. One more run. Lily comes home after.\n" \
	+ "MAYA: You said she'd come home last time.\n" \
	+ "ADRIAN: This time it's him or her. Choose.\n" \
	+ "MAYA: ...\n" \
	+ "MAYA: No.\n" \
	+ "ADRIAN: You'd pick your brother over your own daughter?\n" \
	+ "MAYA: I won't buy her life with his. And I won't leave her with you.\n\n" \
	+ "VALE FREIGHT DISPATCH, FORWARDED TO HERSELF\n" \
	+ "18 NOV 23:58  BR 048's route changed off the compound run (by M. VALE)\n" \
	+ "21 NOV 00:40  patrol warning sent to BR 048 from a prepaid number (paid by M. VALE)\n" \
	+ "21 NOV 01:05  berth 2 pickup put back two hours (by M. VALE)\n\n" \
	+ "The dates are the nights you drove."
const RECORDING_NOTE := "She said no. And she kept getting you out."
const MAYA_TEXT := "The viewpoint on the hill road. Please. I'll be there."
const KEY := Color(1.0, 0.78, 0.55)
const RIM := Color(0.55, 0.7, 1.0)


static func _look(eye: Vector3, at: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)


## The confrontation (about 44 s and a card), Maya standing at `maya_at` facing `ethan_at`.
static func confrontation(maya_at: Vector3, ethan_at: Vector3, van_at: Vector3) -> Array:
	var face_m := maya_at + Vector3.UP * 1.6
	var face_e := ethan_at + Vector3.UP * 1.65
	var across := (ethan_at - maya_at).normalized()
	var side := across.cross(Vector3.UP)
	return [
		{"name": "confrontation_wide", "seconds": 6.0, "fov": Vector2(38.0, 34.0),
			"exposure": 1.4, "gamma": 0.75, "from": _look(van_at + side * 9.0 + Vector3(0.0, 3.0,
			0.0) - across * 4.0, maya_at.lerp(van_at, 0.5) + Vector3.UP),
			"to": _look(van_at + side * 7.5 + Vector3(0.0, 2.4, 0.0) - across * 3.0,
			maya_at.lerp(van_at, 0.5) + Vector3.UP)},
		{"name": "confrontation_ethan", "seconds": 7.0, "fov": Vector2(30.0, 28.0),
			"exposure": 1.3, "gamma": 0.8, "lights": [{"at": face_e - across * 0.9 + side * 0.6,
			"colour": KEY, "energy": 1.0, "range": 3.0}],
			"from": _look(face_m - across * 0.6 + side * 0.45, face_e),
			"to": _look(face_m - across * 0.5 + side * 0.4, face_e)},
		{"name": "confrontation_maya", "seconds": 10.0, "fov": Vector2(28.0, 26.0),
			"exposure": 1.3, "gamma": 0.8, "lights": [{"at": face_m + across * 0.9 - side * 0.6,
			"colour": KEY, "energy": 1.0, "range": 3.0}, {"at": face_m - across * 0.7
			+ Vector3.UP * 0.4, "colour": RIM, "energy": 2.0, "range": 3.0}],
			"from": _look(face_e + across * 0.6 - side * 0.45, face_m),
			"to": _look(face_e + across * 0.5 - side * 0.4, face_m)},
		{"name": "confrontation_two", "seconds": 12.0, "fov": Vector2(34.0, 32.0),
			"exposure": 1.35, "gamma": 0.78,
			"from": _look(maya_at.lerp(ethan_at, 0.5) + side * 4.5 + Vector3.UP * 1.5,
			maya_at.lerp(ethan_at, 0.5) + Vector3.UP * 1.4),
			"to": _look(maya_at.lerp(ethan_at, 0.5) + side * 4.0 + Vector3.UP * 1.45,
			maya_at.lerp(ethan_at, 0.5) + Vector3.UP * 1.4)},
		{"name": "confrontation_leave", "seconds": 7.0, "fov": Vector2(40.0, 36.0),
			"exposure": 1.4, "gamma": 0.75, "from": _look(maya_at - across * 3.0 + Vector3.UP * 1.7,
			ethan_at + Vector3.UP * 1.2), "to": _look(maya_at - across * 3.5 + Vector3.UP * 1.9,
			van_at + Vector3.UP * 1.2)},
		{"name": "confrontation_days", "seconds": 4.0, "black": true,
			"card": ["TWO DAYS LATER", "BLACKRIDGE"], "from": _look(van_at + Vector3.UP * 4.0,
			van_at), "to": _look(van_at + Vector3.UP * 4.0, van_at)},
	]


## The reconciliation at the viewpoint (about 34 s), the valley's lights below.
static func reconciliation(maya_at: Vector3, ethan_at: Vector3, valley: Vector3) -> Array:
	var face_m := maya_at + Vector3.UP * 1.6
	var face_e := ethan_at + Vector3.UP * 1.65
	var across := (ethan_at - maya_at).normalized()
	var side := across.cross(Vector3.UP)
	return [
		{"name": "reconciliation_wide", "seconds": 6.0, "fov": Vector2(44.0, 40.0),
			"exposure": 1.5, "gamma": 0.72, "from": _look(maya_at.lerp(ethan_at, 0.5) - side * 9.0
			+ Vector3.UP * 2.5, valley), "to": _look(maya_at.lerp(ethan_at, 0.5) - side * 8.0
			+ Vector3.UP * 2.2, maya_at.lerp(ethan_at, 0.5) + Vector3.UP)},
		{"name": "reconciliation_maya", "seconds": 9.0, "fov": Vector2(28.0, 26.0),
			"exposure": 1.3, "gamma": 0.8, "lights": [{"at": face_m + across * 0.9 - side * 0.6,
			"colour": KEY, "energy": 0.9, "range": 3.0}],
			"from": _look(face_e + across * 0.6 - side * 0.4, face_m),
			"to": _look(face_e + across * 0.5 - side * 0.35, face_m)},
		{"name": "reconciliation_ethan", "seconds": 8.0, "fov": Vector2(28.0, 26.0),
			"exposure": 1.3, "gamma": 0.8, "lights": [{"at": face_e - across * 0.9 + side * 0.6,
			"colour": KEY, "energy": 0.9, "range": 3.0}],
			"from": _look(face_m - across * 0.6 + side * 0.4, face_e),
			"to": _look(face_m - across * 0.5 + side * 0.35, face_e)},
		{"name": "reconciliation_two", "seconds": 11.0, "fov": Vector2(36.0, 34.0),
			"exposure": 1.4, "gamma": 0.76, "from": _look(maya_at.lerp(ethan_at, 0.5) + side * 5.0
			+ Vector3.UP * 1.5, maya_at.lerp(ethan_at, 0.5) + Vector3.UP * 1.4),
			"to": _look(maya_at.lerp(ethan_at, 0.5) + side * 6.5 + Vector3.UP * 2.2, valley)},
	]


## The confrontation at the service gate (about 33 s): Adrian walks from `adrian_from` to
## `adrian_at`, Ethan at `ethan_at` between him and Maya at `maya_at` with Lily.
static func gate_confrontation(maya_at: Vector3, ethan_at: Vector3, adrian_at: Vector3,
		adrian_from: Vector3) -> Array:
	var toward := Vector3(adrian_at.x - ethan_at.x, 0.0, adrian_at.z - ethan_at.z).normalized()
	var side := toward.cross(Vector3.UP)
	var face_e := ethan_at + Vector3.UP * 1.65
	var face_a := adrian_at + Vector3.UP * 1.68
	var middle := ethan_at.lerp(adrian_at, 0.5)
	return [
		{"name": "gate_wide", "seconds": 6.0, "fov": Vector2(40.0, 36.0), "exposure": 1.45,
			"gamma": 0.74, "from": _look(maya_at - toward * 2.5 + side * 1.4 + Vector3.UP * 1.7,
			ethan_at.lerp(adrian_from, 0.6) + Vector3.UP * 1.3), "to": _look(maya_at
			- toward * 2.0 + side * 1.2 + Vector3.UP * 1.65, ethan_at.lerp(adrian_at, 0.7)
			+ Vector3.UP * 1.3)},
		{"name": "gate_adrian", "seconds": 7.0, "fov": Vector2(30.0, 27.0), "exposure": 1.3,
			"gamma": 0.8, "lights": [{"at": face_a - toward * 0.9 - side * 0.7, "colour": KEY,
			"energy": 1.0, "range": 3.0}, {"at": face_a + toward * 0.8 + Vector3.UP * 0.4,
			"colour": RIM, "energy": 2.0, "range": 3.0}],
			"from": _look(face_e - toward * 0.7 + side * 0.45, face_a),
			"to": _look(face_e - toward * 0.6 + side * 0.4, face_a)},
		{"name": "gate_ethan", "seconds": 6.0, "fov": Vector2(30.0, 27.0), "exposure": 1.3,
			"gamma": 0.8, "lights": [{"at": face_e + toward * 0.9 + side * 0.6, "colour": KEY,
			"energy": 1.0, "range": 3.0}],
			"from": _look(face_a + toward * 0.7 - side * 0.45, face_e),
			"to": _look(face_a + toward * 0.6 - side * 0.4, face_e)},
		{"name": "gate_maya_lily", "seconds": 4.0, "fov": Vector2(34.0, 32.0), "exposure": 1.35,
			"gamma": 0.78, "lights": [{"at": maya_at + Vector3.UP * 1.6 + toward * 1.2
			- side * 0.6, "colour": KEY, "energy": 1.0, "range": 3.5}, {"at": maya_at
			+ Vector3.UP * 1.8 - toward * 0.8, "colour": RIM, "energy": 1.5, "range": 3.0}],
			"from": _look(maya_at + toward * 3.8 - side * 1.6 + Vector3.UP * 1.35, maya_at
			+ Vector3.UP * 1.15 - side * 0.3), "to": _look(maya_at + toward * 3.5 - side * 1.5
			+ Vector3.UP * 1.3, maya_at + Vector3.UP * 1.15 - side * 0.3)},
		{"name": "gate_draw", "seconds": 2.0, "fov": Vector2(46.0, 44.0), "exposure": 1.4,
			"gamma": 0.76, "from": _look(middle - side * 8.0 - toward * 6.0 + Vector3.UP * 1.8,
			middle + Vector3.UP * 1.2), "to": _look(middle - side * 7.6 - toward * 5.7
			+ Vector3.UP * 1.75, middle + Vector3.UP * 1.2)},
		{"name": "gate_black", "seconds": 1.5, "black": true, "from": _look(middle - side * 7.6
			- toward * 5.7 + Vector3.UP * 1.75, middle + Vector3.UP * 1.2), "to": _look(middle
			- side * 7.6 - toward * 5.7 + Vector3.UP * 1.75, middle + Vector3.UP * 1.2)},
		{"name": "gate_after", "seconds": 8.5, "fov": Vector2(28.0, 26.0), "exposure": 1.35,
			"gamma": 0.78, "lights": [{"at": adrian_at - toward * 0.9 - side * 0.6 + Vector3.UP
			* 0.7, "colour": KEY, "energy": 0.9, "range": 2.2}], "from": _look(adrian_at - toward * 1.9 - side * 0.8 + Vector3.UP
			* 1.15, adrian_at - toward * 0.3 - side * 0.3), "to": _look(adrian_at
			- toward * 1.75 - side * 0.75 + Vector3.UP * 1.1, adrian_at - toward * 0.3
			- side * 0.3)},
	]


## The reunion at the service gate (about 27 s and two cards): Maya and Lily at `maya_at`, Ethan
## coming from `ethan_at`, police lights coming from `police_from`.
static func reunion(maya_at: Vector3, ethan_at: Vector3, police_from: Vector3) -> Array:
	var across := Vector3(ethan_at.x - maya_at.x, 0.0, ethan_at.z - maya_at.z).normalized()
	var side := across.cross(Vector3.UP)
	var close := maya_at + across * 1.2
	var face_m := maya_at + Vector3.UP * 1.6
	var face_e := close + Vector3.UP * 1.65
	return [
		{"name": "reunion_wide", "seconds": 8.0, "fov": Vector2(38.0, 34.0), "exposure": 1.45,
			"gamma": 0.74, "from": _look(maya_at + side * 6.5 + across * 2.0 + Vector3.UP * 1.8,
			maya_at.lerp(ethan_at, 0.4) + Vector3.UP * 1.1), "to": _look(maya_at + side * 5.5
			+ across * 1.6 + Vector3.UP * 1.7, maya_at.lerp(close, 0.5) + Vector3.UP * 1.1)},
		{"name": "reunion_maya", "seconds": 8.0, "fov": Vector2(28.0, 26.0), "exposure": 1.3,
			"gamma": 0.8, "lights": [{"at": face_m + across * 0.9 - side * 0.6, "colour": KEY,
			"energy": 0.9, "range": 3.0}],
			"from": _look(face_e + across * 0.5 - side * 0.4, face_m),
			"to": _look(face_e + across * 0.4 - side * 0.35, face_m)},
		{"name": "reunion_ethan", "seconds": 7.0, "fov": Vector2(28.0, 26.0), "exposure": 1.3,
			"gamma": 0.8, "lights": [{"at": face_e - across * 0.9 + side * 0.6, "colour": KEY,
			"energy": 0.9, "range": 3.0}],
			"from": _look(face_m - across * 0.5 + side * 0.4, face_e),
			"to": _look(face_m - across * 0.4 + side * 0.35, face_e)},
		{"name": "reunion_lights", "seconds": 4.5, "fov": Vector2(40.0, 38.0), "exposure": 1.45,
			"gamma": 0.74, "from": _look(maya_at - across * 3.0 + side * 2.0 + Vector3.UP * 1.6,
			police_from.lerp(maya_at, 0.5) + Vector3.UP * 1.0), "to": _look(maya_at - across * 2.8
			+ side * 1.9 + Vector3.UP * 1.6, police_from.lerp(maya_at, 0.6) + Vector3.UP * 1.0)},
		{"name": "reunion_statement", "seconds": 5.5, "black": true, "card": STATEMENT,
			"from": _look(maya_at + Vector3.UP * 4.0, maya_at), "to": _look(maya_at + Vector3.UP
			* 4.0, maya_at)},
		{"name": "reunion_beat", "seconds": 1.0, "black": true, "from": _look(maya_at
			+ Vector3.UP * 4.0, maya_at), "to": _look(maya_at + Vector3.UP * 4.0, maya_at)},
		{"name": "reunion_later", "seconds": 4.5, "black": true, "card": LATER,
			"from": _look(maya_at + Vector3.UP * 4.0, maya_at), "to": _look(maya_at + Vector3.UP
			* 4.0, maya_at)},
	]
