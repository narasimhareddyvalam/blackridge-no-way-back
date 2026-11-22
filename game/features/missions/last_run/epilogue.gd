extends Node
## The game's ending (Mission 3's step 8, docs/PHASE_BRIEF.md, 2026-11-22, #359-#360; GAME_STORY's
## "Resolution" and "Final cinematic"; C04, C42): six months later, the family's modest home on the
## outskirts in late-afternoon sun. It is a world of its own (`world`, drawn in a SubViewport over
## the whole screen), so the night, its rain, its fog and its grade are left as they are: a sky, a
## low warm sun, the house (strielecki's "Suburban House V2", CC BY 4.0), lawn, a concrete drive and
## the street, cedars and alders, moving boxes by the door, Ethan's van in the drive.
##
## The scene, as GAME_STORY writes it: they finish unpacking; Maya tells Ethan he no longer has to
## look after her, and he answers in the story's words; Lily interrupts in hers; he takes the keys
## and they leave laughing, the drive's own music under the van as it goes down the road. The
## camera stays on the empty driveway longer than expected and the music fades; slowly the frame
## finds a black sedan across the street and, through its windshield, a man photographing the
## house, his phone held up before his face and the glass's daylight glare over him (his face
## never seen); his phone's four messages, word for word; he lowers it,
## starts the engine and drives away. Absolute black, held two beats; only then the title. Nothing
## else is shown or said. The night's engines and rain are muted while it plays.

signal finished

const HOUSE = preload("art/house/family_house.glb")
const VAN = preload("res://features/vehicles/freight_van/art/iveco/iveco_exterior.glb")
const SEDAN = preload("res://features/environments/industrial_loop/art/town/sedan.glb")
const ETHAN = preload("res://features/characters/ethan/ethan.glb")
const MAYA = preload("res://features/characters/maya/maya.glb")
const LILY = preload("res://features/characters/lily/lily.glb")
const WATCHER = preload("res://features/characters/syndicate_man/syndicate_man.glb")
const CARTON = preload("res://features/environments/industrial_loop/art/depot/carton.glb")
const CEDAR = preload("res://features/environments/industrial_loop/art/trees/western_red_cedar.glb")
const ALDER = preload("res://features/environments/industrial_loop/art/trees/red_alder.glb")
const FIR = preload("res://features/environments/industrial_loop/art/trees/young_firs.glb")
const HEMLOCK = preload(
	"res://features/environments/industrial_loop/art/trees/mountain_hemlock.glb")
const MUSIC = preload("res://features/audio/first_drive/music.wav")
const ENGINE = preload("res://features/audio/first_drive/engine.wav")
const GRASS = preload("res://features/environments/industrial_loop/polyhaven/textures/"
	+ "leafy_grass/leafy_grass_diff_1k.jpg")
const ASPHALT = preload(
	"res://features/environments/depot_yard/polyhaven/textures/asphalt_02/asphalt_02_diff_2k.jpg")
const CONCRETE = preload("res://features/environments/depot_yard/polyhaven/textures/"
	+ "concrete_floor_worn_001/concrete_floor_worn_001_diff_2k.jpg")
const LETTERING = preload("res://features/ui/driving_hud/fonts/BarlowCondensed-SemiBold.ttf")
const AimArms = preload("res://features/weapons/pistol/aim_arms.gd")
## The watcher's shoulders as he sits, and his arms raised to hold the phone before his face.
const SEATED_SHOULDERS := 1.12
const PHONE_UP := 0.22
const MUTED: Array[String] = ["Vehicle", "Ambience", "Music"]
const TITLE := "BLACKRIDGE: NO WAY BACK"
## Where things stand: the house's front along z = 0 facing -z, the drive on its -x side, the
## street's middle at STREET_Z; the sedan across it, facing -x as cars on that side park.
const HOUSE_AT := Vector3(-6.7, 0.38, 0.0)
const STREET_Z := -24.0
const STREET_WIDE := 7.5
const DRIVE_X := -9.5
const VAN_AT := Vector3(-9.5, 0.0, -6.5)
const PORCH := Vector3(4.6, 0.0, -1.7)
const SEDAN_AT := Vector3(16.0, 0.0, -26.6)
## The watcher in the sedan's driver's seat (the car's left, the model facing its +z), from the
## car.
const SEAT := Vector3(0.38, 0.16, -0.25)
## The story's words (GAME_STORY), and the phone's four messages, word for word.
const LINES: Array = [
	[8.0, "MAYA", "You don't have to look after me anymore, Ethan.", 3.2],
	[11.8, "ETHAN", "This time, it's not about looking after you. It's about being a family.", 4.2],
	[17.6, "LILY", "Uncle Ethan! You promised we'd go for a drive!", 3.2],
]
const MESSAGES: Array = [[56.5, true, "Found them."], [58.6, false, "All three?"],
	[60.6, true, "Yes."], [64.0, false, "Don't approach them. Not yet."]]
const BLACK_AT := 73.0
const TITLE_AT := 75.2
const END_AT := 81.5

var playing := false
var world: Node3D
var _viewport: SubViewport
var _layer: CanvasLayer
var _black: ColorRect
var _subtitle: Label
var _phone: PanelContainer
var _messages: VBoxContainer
var _title: Label
var _camera: Camera3D
var _clock := 0.0
var _shots: Array = []
var _ethan: Node3D
var _maya: Node3D
var _lily: Node3D
var _van: Node3D
var _sedan: Node3D
var _screen: MeshInstance3D
var _arms: Node3D
var _music: AudioStreamPlayer
var _engine: AudioStreamPlayer
var _texts: Array[String] = []
var _shown: Array[String] = []
var _moves: Array = []


## Plays it over the whole screen, at `size` pixels.
func play(size: Vector2i) -> void:
	_build(size)
	for bus in MUTED:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
	_clock = 0.0
	playing = true
	_place_people()
	set_process(true)


## Every word on screen so far, in the order shown.
func texts_now() -> Array[String]:
	return _shown.duplicate()


func is_black() -> bool:
	return _black != null and _black.visible and _clock >= BLACK_AT


func title_shown() -> bool:
	return _title != null and _title.visible


func _ready() -> void:
	set_process(false)


func _build(size: Vector2i) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(holder)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.size = size
	_viewport.msaa_3d = Viewport.MSAA_2X
	holder.add_child(_viewport)
	world = Node3D.new()
	world.name = "Home"
	_viewport.add_child(world)
	_light_the_world()
	_lay_out()
	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.far = 900.0
	world.add_child(_camera)
	_camera.make_current()
	_shots = _shot_list()
	_overlay()


func _light_the_world() -> void:
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.36, 0.52, 0.74)
	sky.sky_horizon_color = Color(0.86, 0.78, 0.66)
	sky.ground_horizon_color = Color(0.62, 0.58, 0.5)
	sky.ground_bottom_color = Color(0.22, 0.2, 0.18)
	sky.sun_angle_max = 20.0
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.ssao_enabled = true
	var setting := WorldEnvironment.new()
	setting.environment = environment
	world.add_child(setting)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.light_color = Color(1.0, 0.87, 0.7)
	sun.light_energy = 2.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	world.add_child(sun)
	sun.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(-115.0), 0.0)


func _material(texture: Texture2D, tile: float, rough: float) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_texture = texture
	surface.uv1_scale = Vector3(tile, tile, tile)
	surface.uv1_triplanar = true
	surface.roughness = rough
	return surface


func _lawn() -> StandardMaterial3D:
	var lawn := _material(GRASS, 0.25, 0.95)
	lawn.albedo_color = Color(0.62, 0.78, 0.5)
	return lawn


func _slab(at: Vector3, size: Vector3, surface: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var slab := MeshInstance3D.new()
	slab.mesh = mesh
	slab.material_override = surface
	world.add_child(slab)
	slab.position = at


func _lay_out() -> void:
	_slab(Vector3(0.0, -0.05, -20.0), Vector3(300.0, 0.1, 300.0), _lawn())
	var asphalt := _material(ASPHALT, 0.2, 0.8)
	var concrete := _material(CONCRETE, 0.35, 0.85)
	_slab(Vector3(0.0, 0.01, STREET_Z), Vector3(300.0, 0.06, STREET_WIDE), asphalt)
	for side in [-1.0, 1.0]:
		_slab(Vector3(0.0, 0.07, STREET_Z + side * (STREET_WIDE / 2.0 + 0.1)), Vector3(300.0, 0.15,
			0.2), concrete)
	var drive_from := -1.0
	var drive_to := STREET_Z + STREET_WIDE / 2.0
	_slab(Vector3(DRIVE_X, 0.03, (drive_from + drive_to) / 2.0), Vector3(3.8, 0.08, drive_from
		- drive_to), concrete)
	_slab(Vector3(PORCH.x, 0.02, (PORCH.z + drive_to) / 2.0 + 2.0), Vector3(1.2, 0.06, PORCH.z
		- drive_to - 4.0), concrete)
	var house := HOUSE.instantiate() as Node3D
	world.add_child(house)
	house.position = HOUSE_AT
	for spot: Array in [[CEDAR, Vector3(-16.0, 0.0, 6.0), 0.3],
			[CEDAR, Vector3(13.0, 0.0, 9.0), 1.7], [ALDER, Vector3(-14.5, 0.0, -10.0), 2.4], [ALDER, Vector3(11.0, 0.0, -12.0), 0.8],
			[CEDAR, Vector3(30.0, 0.0, -40.0), 1.1], [CEDAR, Vector3(-4.0, 0.0, -42.0), 2.9],
			[ALDER, Vector3(22.0, 0.0, -36.0), 0.2]]:
		var tree := _tree(spot[0])
		tree.position = spot[1]
		tree.rotation.y = spot[2]
	var forest: Array[PackedScene] = [CEDAR, FIR, HEMLOCK, CEDAR, FIR]
	for index in range(64):
		var turn := TAU * index / 64.0 + sin(index * 7.3) * 0.04
		var reach := 46.0 + fmod(index * 13.7, 22.0)
		var at := Vector3(cos(turn) * reach, 0.0, -14.0 + sin(turn) * reach)
		if absf(at.z - STREET_Z) < 7.0:
			continue
		var tree := _tree(forest[index % forest.size()])
		tree.position = at
		tree.rotation.y = index * 1.9
	for box: Array in [[Vector3(5.6, 0.0, -2.1), 0.1], [Vector3(6.1, 0.0, -2.5), 0.5],
			[Vector3(5.8, 0.3, -2.2), 0.3], [Vector3(3.4, 0.0, -2.3), 1.2]]:
		var carton := CARTON.instantiate() as Node3D
		world.add_child(carton)
		carton.position = box[0]
		carton.rotation.y = box[1]
	_van = VAN.instantiate() as Node3D
	world.add_child(_van)
	_van.position = VAN_AT
	_sedan = SEDAN.instantiate() as Node3D
	world.add_child(_sedan)
	_sedan.position = SEDAN_AT
	_sedan.rotation.y = -PI / 2.0
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.03, 0.03, 0.035)
	paint.metallic = 0.6
	paint.roughness = 0.25
	for mesh: MeshInstance3D in _sedan.find_children("*", "MeshInstance3D", true, false):
		for index in range(mesh.mesh.get_surface_count()):
			var own := mesh.get_active_material(index)
			if own != null and own.resource_name.begins_with("Fairheaven_LT80_Body"):
				mesh.set_surface_override_material(index, paint)
	var watcher := WATCHER.instantiate() as Node3D
	_sedan.add_child(watcher)
	watcher.position = SEAT
	_play(watcher, "Sit")
	_arms = AimArms.new()
	watcher.add_child(_arms)
	_arms.call("setup", watcher.find_children("*", "Skeleton3D", true, false)[0],
		SEATED_SHOULDERS)
	(_arms.get("pistol") as Node3D).queue_free()
	_arms.set("pistol", null)
	_arms.set("pitch", PHONE_UP)
	var body := MeshInstance3D.new()
	var case := BoxMesh.new()
	case.size = Vector3(0.075, 0.155, 0.009)
	body.mesh = case
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.02, 0.02, 0.025)
	black.roughness = 0.3
	body.material_override = black
	(_arms.get("grip") as Node3D).add_child(body)
	body.position = Vector3(0.0, 0.06, 0.02)
	body.rotation.x = deg_to_rad(-75.0)
	_screen = MeshInstance3D.new()
	var glass := QuadMesh.new()
	glass.size = Vector2(0.065, 0.14)
	_screen.mesh = glass
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(0.8, 0.88, 1.0)
	glow.emission_energy_multiplier = 1.5
	glow.albedo_color = Color.BLACK
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	_screen.material_override = glow
	body.add_child(_screen)
	_screen.position = Vector3(0.0, 0.0, -0.006)
	_screen.rotation.y = PI
	_screen.visible = false
	var glare := MeshInstance3D.new()
	var sheet := QuadMesh.new()
	sheet.size = Vector2(1.18, 0.5)
	glare.mesh = sheet
	var sky := StandardMaterial3D.new()
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sky.albedo_color = Color(0.86, 0.89, 0.93, 0.12)
	sky.cull_mode = BaseMaterial3D.CULL_DISABLED
	glare.material_override = sky
	_sedan.add_child(glare)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.8, 0.85, 0.95)
	fill.light_energy = 0.45
	fill.omni_range = 1.8
	_sedan.add_child(fill)
	fill.position = Vector3(0.0, 1.15, 0.4)
	glare.position = Vector3(0.0, 1.13, 0.98)
	glare.rotation.x = deg_to_rad(-58.0)
	_ethan = _person(ETHAN)
	_maya = _person(MAYA)
	_lily = _person(LILY)
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	_music.volume_db = -10.0
	add_child(_music)
	_engine = AudioStreamPlayer.new()
	_engine.stream = ENGINE
	_engine.volume_db = -18.0
	add_child(_engine)


## One tree: its file's first full mesh only (each holds a far stand-in, and the fir and alder
## files several trees side by side, which the forest's own code picks between).
func _tree(scene: PackedScene) -> Node3D:
	var tree := scene.instantiate() as Node3D
	world.add_child(tree)
	var kept := false
	for mesh: MeshInstance3D in tree.find_children("*", "MeshInstance3D", true, false):
		var keep := not kept and not String(mesh.name).ends_with("Far")
		mesh.visible = keep
		if keep:
			kept = true
			mesh.position = Vector3(0.0, mesh.position.y, 0.0)
	return tree


func _person(scene: PackedScene) -> Node3D:
	var person := scene.instantiate() as Node3D
	world.add_child(person)
	_play(person, "Idle")
	return person


func _play(person: Node3D, clip: String) -> void:
	var player := person.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	if player.current_animation != clip and player.has_animation(clip):
		player.play(clip, 0.3)


## Where each of them starts: Maya on the porch, Lily on the lawn, Ethan coming from the van with
## a box's last trip.
func _place_people() -> void:
	_stand(_maya, PORCH, Vector3(3.0, 0.0, -4.0))
	_stand(_lily, Vector3(2.4, 0.0, -4.6), PORCH)
	_stand(_ethan, VAN_AT + Vector3(1.6, 0.0, 1.2), PORCH)
	_moves = [
		[0.5, _ethan, [Vector3(-4.0, 0.0, -4.0), Vector3(3.9, 0.0, -3.1)], 1.6, PORCH],
		[18.2, _lily, [Vector3(3.3, 0.0, -3.9)], 1.2, Vector3(3.9, 0.0, -3.1)],
		[22.5, _ethan, [Vector3(-3.0, 0.0, -4.6), VAN_AT + Vector3(1.4, 0.0, 0.6)], 1.6,
			VAN_AT],
		[22.8, _lily, [Vector3(-3.4, 0.0, -5.4), VAN_AT + Vector3(1.4, 0.0, -0.8)], 1.6, VAN_AT],
		[23.4, _maya, [Vector3(2.0, 0.0, -3.4), Vector3(-3.6, 0.0, -5.0), VAN_AT
			+ Vector3(1.4, 0.0, -1.9)], 1.5, VAN_AT],
	]


func _stand(person: Node3D, at: Vector3, face: Vector3) -> void:
	person.position = at
	var to := face - at
	person.rotation.y = atan2(to.x, to.z)


## Each shot: [from, until, camera from, camera to, look from, look to, fov].
func _shot_list() -> Array:
	var drive_end := Vector3(DRIVE_X, 0.0, STREET_Z + STREET_WIDE / 2.0)
	var front := SEDAN_AT + Vector3(-4.3, 1.22, 0.1)
	var face := SEDAN_AT + Vector3(0.2, 1.17, 0.38)
	return [
		[0.0, 7.0, Vector3(-18.0, 3.2, -22.0), Vector3(-15.0, 2.8, -20.0), Vector3(0.0, 2.0, -2.0),
			Vector3(1.0, 1.8, -2.0), 42.0],
		[7.0, 17.0, Vector3(1.8, 1.65, -6.2), Vector3(2.0, 1.62, -5.9), Vector3(4.3, 1.4, -2.4),
			Vector3(4.3, 1.4, -2.4), 32.0],
		[17.0, 22.0, Vector3(6.6, 1.2, -6.4), Vector3(6.4, 1.2, -6.2), Vector3(3.6, 1.0, -3.4),
			Vector3(3.6, 1.1, -3.3), 34.0],
		[22.0, 27.0, Vector3(4.0, 2.0, -12.0), Vector3(2.5, 2.0, -12.5), Vector3(-6.0, 1.2, -5.5),
			Vector3(-8.0, 1.2, -6.0), 40.0],
		[27.0, 35.0, Vector3(-2.0, 1.6, -14.0), Vector3(-2.0, 1.6, -14.0), VAN_AT + Vector3(0.0,
			1.0, 0.0), Vector3(40.0, 1.0, -22.0), 44.0],
		[35.0, 43.0, Vector3(1.0, 1.6, -16.0), Vector3(1.0, 1.6, -16.0),
			Vector3(DRIVE_X, 0.6, -6.0), Vector3(DRIVE_X, 0.6, -6.0), 40.0],
		[43.0, 50.0, Vector3(1.0, 1.6, -16.0), Vector3(1.4, 1.6, -16.4), Vector3(DRIVE_X, 0.6,
			-6.0), SEDAN_AT + Vector3(0.0, 0.9, 0.0), 40.0],
		[50.0, 56.0, front, front + Vector3(0.5, -0.02, 0.05), face, face, 26.0],
		[56.0, 68.0, front + Vector3(0.5, -0.02, 0.05), front + Vector3(0.9, -0.04, 0.08), face,
			face, 24.0],
		[68.0, 73.0, Vector3(4.0, 1.7, -20.0), Vector3(4.0, 1.7, -20.0),
			SEDAN_AT + Vector3(0.0, 0.9, 0.0), SEDAN_AT + Vector3(-12.0, 0.9, 0.0), 40.0],
		[73.0, END_AT, drive_end, drive_end, drive_end + Vector3(0.0, 0.0, 1.0),
			drive_end + Vector3(0.0, 0.0, 1.0), 40.0],
	]


func _overlay() -> void:
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		if top:
			bar.offset_bottom = 132.0
		else:
			bar.anchor_top = 1.0
			bar.anchor_bottom = 1.0
			bar.offset_top = -132.0
		_layer.add_child(bar)
	_subtitle = _label(24, Color(0.95, 0.95, 0.92))
	_subtitle.anchor_left = 0.0
	_subtitle.anchor_right = 1.0
	_subtitle.anchor_top = 1.0
	_subtitle.anchor_bottom = 1.0
	_subtitle.offset_top = -118.0
	_subtitle.offset_bottom = -70.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer.add_child(_subtitle)
	_phone = PanelContainer.new()
	var face := StyleBoxFlat.new()
	face.bg_color = Color(0.04, 0.045, 0.05, 0.94)
	face.set_corner_radius_all(18)
	face.set_content_margin_all(18)
	_phone.add_theme_stylebox_override("panel", face)
	_phone.anchor_left = 0.5
	_phone.anchor_right = 0.5
	_phone.anchor_top = 0.5
	_phone.anchor_bottom = 0.5
	_phone.offset_left = -170.0
	_phone.offset_right = 170.0
	_phone.offset_top = -150.0
	_phone.offset_bottom = 150.0
	_phone.visible = false
	_layer.add_child(_phone)
	_messages = VBoxContainer.new()
	_messages.add_theme_constant_override("separation", 10)
	_phone.add_child(_messages)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.visible = true
	_layer.add_child(_black)
	_title = _label(54, Color(0.93, 0.92, 0.88))
	_title.text = TITLE
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.visible = false
	_layer.add_child(_title)


func _label(size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", LETTERING)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _process(delta: float) -> void:
	if not playing:
		return
	_clock += delta
	_black.visible = _clock < 0.8 or _clock >= BLACK_AT
	_frame_camera()
	_walk(delta)
	_say()
	_drive(delta)
	_watch()
	if _clock >= TITLE_AT and not _title.visible:
		_title.visible = true
		_note(TITLE)
	if _clock >= END_AT:
		_end()


func _frame_camera() -> void:
	for shot: Array in _shots:
		if _clock >= float(shot[0]) and _clock < float(shot[1]):
			var share := smoothstep(float(shot[0]), float(shot[1]), _clock)
			var eye: Vector3 = (shot[2] as Vector3).lerp(shot[3], share)
			var look: Vector3 = (shot[4] as Vector3).lerp(shot[5], share)
			if eye.distance_to(look) > 0.01:
				_camera.look_at_from_position(eye, look)
			_camera.fov = float(shot[6])
			return


func _walk(delta: float) -> void:
	for move: Array in _moves:
		if _clock < float(move[0]):
			continue
		var person := move[1] as Node3D
		var points: Array = move[2]
		if points.is_empty():
			continue
		var target: Vector3 = points[0]
		var to := Vector3(target.x - person.position.x, 0.0, target.z - person.position.z)
		if to.length() < 0.05:
			points.remove_at(0)
			if points.is_empty():
				_play(person, "Idle")
				var face: Vector3 = move[4]
				var look := face - person.position
				person.rotation.y = atan2(look.x, look.z)
			continue
		person.position += to.normalized() * minf(to.length(), float(move[3]) * delta)
		person.rotation.y = lerp_angle(person.rotation.y, atan2(to.x, to.z), 1.0 - exp(-8.0
			* delta))
		_play(person, "Walk")


func _say() -> void:
	var line_now := ""
	for line: Array in LINES:
		if _clock >= float(line[0]) and _clock < float(line[0]) + float(line[3]):
			line_now = "%s: %s" % [line[1], line[2]]
			if String(line[1]) == "MAYA":
				_play(_maya, "TalkSad")
	if _clock > 11.5 and _clock < 22.0:
		_play(_maya, "Idle")
	_subtitle.text = line_now
	if line_now != "":
		_note(line_now)
	_phone.visible = _clock >= 56.0 and _clock < 68.0
	for message: Array in MESSAGES:
		if _clock >= float(message[0]) and _messages.get_child_count() < MESSAGES.find(message) + 1:
			_messages.add_child(_bubble(String(message[2]), bool(message[1])))
			_note(String(message[2]))


func _bubble(words: String, mine: bool) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	var bubble := PanelContainer.new()
	var face := StyleBoxFlat.new()
	face.bg_color = Color(0.2, 0.42, 0.85) if mine else Color(0.22, 0.23, 0.25)
	face.set_corner_radius_all(14)
	face.content_margin_left = 12
	face.content_margin_right = 12
	face.content_margin_top = 7
	face.content_margin_bottom = 7
	bubble.add_theme_stylebox_override("panel", face)
	var label := _label(21, Color.WHITE)
	label.text = words
	bubble.add_child(label)
	row.add_child(bubble)
	return row


func _note(text: String) -> void:
	if not _shown.has(text):
		_shown.append(text)


## The van down the drive and away along the street, the drive's music under it; the cast in it.
func _drive(delta: float) -> void:
	if _clock >= 27.0 and _ethan.visible:
		for person in [_ethan, _maya, _lily]:
			person.visible = false
		_music.play()
	if _clock >= 27.6 and _clock < 36.0:
		var path: Array[Vector3] = [VAN_AT, Vector3(DRIVE_X, 0.0, STREET_Z + 1.9), Vector3(DRIVE_X
			+ 6.0, 0.0, STREET_Z + 1.9), Vector3(80.0, 0.0, STREET_Z + 1.9)]
		var speed := minf(2.0 + (_clock - 27.6) * 2.2, 13.0)
		_follow(_van, path, speed * delta)
	if _clock >= 39.0 and _clock < 43.0:
		_music.volume_db = lerpf(-10.0, -60.0, (_clock - 39.0) / 4.0)
	elif _clock >= 43.0 and _music.playing:
		_music.stop()


func _follow(car: Node3D, path: Array[Vector3], step: float) -> void:
	var best := 1
	for index in range(1, path.size()):
		var a := path[index - 1]
		var b := path[index]
		var along := (car.position - a).dot((b - a).normalized())
		if along < a.distance_to(b) - 0.2:
			best = index
			break
	var target := path[best]
	var to := Vector3(target.x - car.position.x, 0.0, target.z - car.position.z)
	if to.length() < 0.01:
		return
	car.position += to.normalized() * minf(step, to.length())
	var yaw := atan2(-to.x, -to.z)
	car.rotation.y = lerp_angle(car.rotation.y, yaw, 0.12)


## The man photographing the house (his phone's glow at his face), then the engine, and away.
func _watch() -> void:
	var up := _clock >= 51.0 and _clock < 67.5
	_screen.visible = up
	_arms.set("wanted", 1.0 if up else 0.0)
	if _clock >= 68.4 and not _engine.playing and _clock < 70.0:
		_engine.play()
	if _clock >= 69.5 and _clock < BLACK_AT:
		var away := minf((_clock - 69.5) * 1.8, 8.0)
		_sedan.position = SEDAN_AT + Vector3(-away * (_clock - 69.5) * 0.5, 0.0, 0.0)


func _end() -> void:
	playing = false
	set_process(false)
	for bus in MUTED:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), false)
	_music.stop()
	_engine.stop()
	_layer.visible = false
	_viewport.queue_free()
	finished.emit()
