extends Node3D
## Ethan's handgun in the hangar's encounter (Mission 3's step 6, docs/PHASE_BRIEF.md, 2026-11-22,
## #359-#360; GAME_DESIGN §8: "one handgun, hitscan ... ammunition, reload"): Adrian's compact
## semi-automatic, as Maya hands it over, 15 in the magazine and one spare magazine of 15. Each pull
## fires one round, no faster than a trigger is pulled and the sights found again (BETWEEN), along
## the line it is given out to REACH: the first solid thing or man on it is hit, a man by `shot`
## (a body hit or one to the head, which his own script judges). Empty, the trigger only clicks
## (`dry`). A reload takes RELOAD_SECONDS and fills the magazine from the spare. Its muzzle flashes
## and it is heard (`fired`, which the encounter's men listen for). The model is the men's own
## pistol (`pistol.glb`), shown in his hands while he aims.
## Since C68 (#393-#403) Ethan's gun is a rifle, an M16 (rifle_carry.gd shows it and handles it):
## a 30-round magazine and one spare, and a reload as long as the reload clip (100 frames at
## 30 fps, its last frame at 99/30 s), so the magazine fills as his hands finish. Hitscan, BETWEEN
## and REACH are as they were.

signal fired(at: Vector3)

const MODEL = preload("pistol.glb")
const SHOT = preload("res://features/audio/last_run/pistol_shot.wav")
const MAGAZINE := 30
const RELOAD_SECONDS := 99.0 / 30.0
const BETWEEN := 0.25
const REACH := 60.0
## What a round stops at: the world, the van and the men (`ArmedGuard.TARGETS`).
const STOPS := 1 | 2 | 16
const FLASH_SECONDS := 0.05

var armed := false
var magazine := MAGAZINE
var reserve := MAGAZINE
var reloading := false
var shots := 0
var dry := 0
var model: Node3D
var _reload_left := 0.0
var _cooldown := 0.0
var _flash_left := 0.0
var _flash: OmniLight3D
var _sound: AudioStreamPlayer3D


func _ready() -> void:
	model = MODEL.instantiate() as Node3D
	model.name = "Pistol"
	add_child(model)
	model.visible = false
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.78, 0.45)
	_flash.light_energy = 0.0
	_flash.omni_range = 4.0
	model.add_child(_flash)
	_flash.position = Vector3(0.0, 0.03, -0.1)
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = SHOT
	_sound.unit_size = 30.0
	_sound.max_polyphony = 3
	add_child(_sound)


## Full again, as when Maya hands it over (and on a retry).
func refill() -> void:
	magazine = MAGAZINE
	reserve = MAGAZINE
	reloading = false
	_reload_left = 0.0
	_cooldown = 0.0


## Starts a reload, if there is room in the magazine and a round spare.
func reload() -> bool:
	if not armed or reloading or magazine >= MAGAZINE or reserve <= 0:
		return false
	reloading = true
	_reload_left = RELOAD_SECONDS
	return true


## One pull of the trigger, the round going from `from` toward `toward`, `exclude` not hit: what
## it hit ({} for nothing, or no round).
func pull(from: Vector3, toward: Vector3, exclude: Array[RID]) -> Dictionary:
	if not armed or reloading or _cooldown > 0.0:
		return {}
	if magazine <= 0:
		dry += 1
		_cooldown = BETWEEN
		return {}
	magazine -= 1
	shots += 1
	_cooldown = BETWEEN
	_flash_left = FLASH_SECONDS
	_flash.light_energy = 3.0
	_sound.global_position = model.global_position
	_sound.play()
	fired.emit(from)
	var query := PhysicsRayQueryParameters3D.create(from, from + (toward - from).normalized()
		* REACH, STOPS, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var man := (hit["collider"] as Node).get_meta("guard", null) as Node
	if man != null:
		man.call("shot", hit["position"] as Vector3, from)
	return hit


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash.light_energy = 0.0
	if reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			var taken := mini(MAGAZINE - magazine, reserve)
			magazine += taken
			reserve -= taken
			reloading = false
