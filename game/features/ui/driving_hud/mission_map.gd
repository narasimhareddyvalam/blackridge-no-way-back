extends Control
## The mission map (#356; the author's choices: a map with the route, then "Frameless 3D", after
## GTA VI's qualities): the district in 3D at the bottom left, faded into the screen at its edges.
## It is its own small world (`viewport`, never drawn by the game's cameras): the ground the baked
## top-down map (`art/mission_map_ground.png`, `tools/art/bake_mission_map.py`) at the world's real
## bounds, and every building a block at its own height (`set_world`), lit from high and far by
## one light (an omni, not a directional light, so nothing in the game takes it for the moon); a camera tilted down looks
## at the player from behind, centred every frame exactly where he is (`follow`: the van while he
## drives, Ethan on foot), turned smoothly with the van at the wheel and with the camera on foot,
## nearer in on foot; the player an arrow pointing the way he faces, north marked at the edge;
## the objective's place a pulsing amber pin, held at the edge when it lies beyond (`set_target`).

## Each time the map takes the player's place and way (for a test to compare at that moment).
signal followed

const MAP_SIZE := Vector2(340.0, 236.0)
const RENDER_SCALE := 2.0
const MARGIN := 24.0
const GROUND = preload("art/mission_map_ground.png")
const GROUND_BOUNDS := "res://features/ui/driving_hud/art/mission_map_ground.json"
const FADE = preload("map_fade.gdshader")
## The camera: tilted down TILT, back from the player along the map's heading and up, so he sits
## PLAYER_AT down the picture; at the wheel and on foot.
const TILT := deg_to_rad(52.0)
const FOV := 40.0
const DISTANCE_DRIVING := 120.0
const DISTANCE_ON_FOOT := 60.0
const PLAYER_AT := 0.68
## How far inside the map's edges its pin stays, where the picture is not yet faded (#358).
const PIN_INSET := Vector2(34.0, 30.0)
const ZOOM_RATE := 3.0
## How fast the map turns to its heading: quick enough to stay true, slow enough to hide a jolt.
const TURN_RATE := 18.0
const BLOCK_TOP := Color(0.46, 0.51, 0.57)
const INK := Color("e2e5df")
const RIM := Color(0.86, 0.84, 0.78, 0.85)

var focus := Vector3.ZERO
var heading := 0.0
var facing := 0.0
var driving := true
var viewport: SubViewport
var camera: Camera3D
var ground: MeshInstance3D
var screen: TextureRect
var blocks: Array[MeshInstance3D] = []
var _roads: Array[PackedVector3Array] = []
var _distance := DISTANCE_DRIVING
var _font: Font
var _overlay: Control
var _block_material: StandardMaterial3D
var _target := Vector3.INF
var _pulse := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.name = "MapWorld"
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(MAP_SIZE * RENDER_SCALE)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.6, 0.68)
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var surroundings := WorldEnvironment.new()
	surroundings.environment = environment
	viewport.add_child(surroundings)
	var sun := OmniLight3D.new()
	sun.name = "MapSun"
	sun.omni_range = 6000.0
	sun.omni_attenuation = 0.0
	sun.light_energy = 0.75
	sun.position = Vector3(1300.0, 2400.0, 1800.0)
	viewport.add_child(sun)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.far = 1200.0
	viewport.add_child(camera)
	camera.current = true
	_lay_ground()
	_block_material = StandardMaterial3D.new()
	_block_material.albedo_color = BLOCK_TOP
	_block_material.roughness = 0.9
	screen = TextureRect.new()
	screen.name = "MapPicture"
	screen.texture = viewport.get_texture()
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := ShaderMaterial.new()
	fade.shader = FADE
	screen.material = fade
	add_child(screen)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	resized.connect(_place)
	_place()


func set_font(font: Font) -> void:
	_font = font


func _lay_ground() -> void:
	var bounds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND_BOUNDS))
	var origin: Array = bounds["origin"]
	var extent: Array = bounds["size"]
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(extent[0]), float(extent[1]))
	ground = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.position = Vector3(float(origin[0]) + float(extent[0]) / 2.0, 0.0,
		float(origin[1]) + float(extent[1]) / 2.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = GROUND
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ground.material_override = paint
	viewport.add_child(ground)


## The world's roads (centre lines, for the route) and its buildings: each block's corners (x, z)
## and its height.
func set_world(roads: Array[PackedVector3Array], buildings: Array) -> void:
	_roads = roads
	for block in blocks:
		block.queue_free()
	blocks.clear()
	for building: Dictionary in buildings:
		var corners: PackedVector2Array = building["corners"]
		var height: float = building["height"]
		var along := corners[1] - corners[0]
		var across := corners[3] - corners[0]
		var middle := (corners[0] + corners[2]) / 2.0
		var box := BoxMesh.new()
		box.size = Vector3(along.length(), height, across.length())
		var block := MeshInstance3D.new()
		block.name = "Block%d" % blocks.size()
		block.mesh = box
		block.material_override = _block_material
		viewport.add_child(block)
		block.position = Vector3(middle.x, height / 2.0, middle.y)
		block.rotation.y = -atan2(along.y, along.x)
		blocks.append(block)


func road_count() -> int:
	return _roads.size()


func place_count() -> int:
	return blocks.size()


## Where the map is drawn on the screen.
func map_rect() -> Rect2:
	return Rect2(Vector2(MARGIN, size.y - MARGIN - MAP_SIZE.y), MAP_SIZE)


func _place() -> void:
	if screen == null:
		return
	var rect := map_rect()
	screen.position = rect.position
	screen.size = rect.size
	_overlay.position = rect.position
	_overlay.size = rect.size


## Centres the map on `at`, turning it toward `toward` (a yaw: the way up the map) and pointing
## the player's arrow along `faces` (his own yaw); `on_foot` brings it nearer.
func follow(at: Vector3, toward: float, faces: float, on_foot: bool, delta: float) -> void:
	focus = at
	if driving == on_foot:
		heading = toward
	driving = not on_foot
	heading = lerp_angle(heading, toward, 1.0 - exp(-delta * TURN_RATE))
	facing = faces
	_distance = lerpf(_distance, DISTANCE_ON_FOOT if on_foot else DISTANCE_DRIVING,
		1.0 - exp(-delta * ZOOM_RATE))
	_aim()
	_overlay.queue_redraw()
	followed.emit()


## The camera back from the player along the heading and up, tilted down TILT, turned so the
## player sits PLAYER_AT down the picture.
func _aim() -> void:
	if camera == null:
		return
	var forward := Vector3(sin(heading), 0.0, cos(heading))
	var half := deg_to_rad(FOV) / 2.0
	var below := (PLAYER_AT - 0.5) * 2.0 * half
	var look := TILT + below
	var target := Vector3(focus.x, 0.0, focus.z)
	camera.global_position = target - forward * cos(look) * _distance + Vector3.UP * sin(look) \
		* _distance
	camera.global_basis = Basis.looking_at(forward * cos(TILT) - Vector3.UP * sin(TILT),
		Vector3.UP)


## The objective's place (#358): a pin on the map there, pulsing; held at the map's edge with an
## arrow when it lies beyond what the map shows. Vector3.INF for none.
func set_target(point: Vector3) -> void:
	_target = point


## Where the pin is drawn, in the map's own pixels (Vector2.INF with no target): where the place
## is, or where the way to it leaves the oval the map shows before its edges fade.
func pin_at() -> Vector2:
	if _target == Vector3.INF:
		return Vector2.INF
	var middle := MAP_SIZE / 2.0
	var radii := MAP_SIZE / 2.0 - PIN_INSET
	var at := to_map(Vector3(_target.x, 0.0, _target.z))
	if at != Vector2.INF and ((at - middle) / radii).length() <= 1.0:
		return at
	var player := to_map(Vector3(focus.x, 0.0, focus.z))
	if player == Vector2.INF:
		player = middle
	var toward: Vector2
	if at != Vector2.INF:
		toward = (at - player).normalized()
	else:
		var way := Vector2(sin(heading), cos(heading))
		var offset := Vector2(_target.x - focus.x, _target.z - focus.z)
		toward = Vector2(offset.dot(Vector2(-way.y, way.x)), -offset.dot(way)).normalized()
	var p := (player - middle) / radii
	var d := toward / radii
	var a := d.dot(d)
	var b := 2.0 * p.dot(d)
	var c := p.dot(p) - 1.0
	var t := (-b + sqrt(maxf(b * b - 4.0 * a * c, 0.0))) / (2.0 * a)
	return player + toward * maxf(t, 0.0)


## A point of the world on the map's picture, in the map's own pixels.
func to_map(point: Vector3) -> Vector2:
	if camera == null or camera.is_position_behind(point):
		return Vector2.INF
	return camera.unproject_position(point) / RENDER_SCALE


func _draw_pin() -> void:
	var pin := pin_at()
	if pin == Vector2.INF:
		return
	_pulse = fmod(_pulse + get_process_delta_time() * 0.8, 1.0)
	var amber := Color(1.0, 0.72, 0.3)
	_overlay.draw_circle(pin, 8.0 + 12.0 * _pulse, Color(amber, 0.35 * (1.0 - _pulse)))
	_overlay.draw_circle(pin, 9.0, Color(0.0, 0.0, 0.0, 0.55))
	var diamond := PackedVector2Array([pin + Vector2(0.0, -7.0), pin + Vector2(7.0, 0.0),
		pin + Vector2(0.0, 7.0), pin + Vector2(-7.0, 0.0)])
	_overlay.draw_colored_polygon(diamond, amber)


func _draw_overlay() -> void:
	var at := to_map(Vector3(focus.x, 0.0, focus.z))
	if at == Vector2.INF:
		return
	_draw_pin()
	var turn := -angle_difference(heading, facing)
	var arrow := PackedVector2Array()
	var shadow := PackedVector2Array()
	for corner: Vector2 in [Vector2(0.0, -12.0), Vector2(9.0, 9.0), Vector2(0.0, 4.0),
			Vector2(-9.0, 9.0)]:
		arrow.append(at + corner.rotated(turn))
		shadow.append(at + corner.rotated(turn) + Vector2(0.0, 2.0))
	_overlay.draw_circle(at, 13.0, Color(0.02, 0.03, 0.04, 0.8))
	_overlay.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.6))
	_overlay.draw_colored_polygon(arrow, INK)
	var north := to_map(Vector3(focus.x, 0.0, focus.z - 60.0))
	if north != Vector2.INF:
		var way := (north - at).normalized()
		var centre := MAP_SIZE / 2.0
		var reach := minf(absf((MAP_SIZE.x / 2.0 - 22.0) / maxf(absf(way.x), 0.001)),
			absf((MAP_SIZE.y / 2.0 - 22.0) / maxf(absf(way.y), 0.001)))
		var mark := centre + way * reach
		var font := _font if _font != null else get_theme_default_font()
		var width := font.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_overlay.draw_string(font, mark + Vector2(-width / 2.0, 6.0), "N",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, RIM)
