extends SceneTree

const MirrorGlass = preload("res://features/vehicles/freight_van/mirror_glass.gd")
const EXTERIOR := "res://features/vehicles/freight_van/art/iveco/iveco_exterior.glb"
const SHINE := "res://features/vehicles/freight_van/art/iveco/iveco_exterior_Front_door_metallicRoughness.webp"
const OUTPUT := "res://features/vehicles/freight_van/art/iveco/mirror_glass_%s.tres"
const DOORS := {"left": "DriverDoor", "right": "PassengerDoor"}


func _initialize() -> void:
	var shine := Image.load_from_file(ProjectSettings.globalize_path(SHINE))
	var van := (load(EXTERIOR) as PackedScene).instantiate() as Node3D
	var status := 0
	for side: String in DOORS:
		var door := van.get_node(DOORS[side]) as MeshInstance3D
		var glass := MirrorGlass.select(door, door.transform, shine)
		var error := ResourceSaver.save(glass, OUTPUT % side)
		print("%s mirror: %d main and %d wide-angle glass triangles, saved to %s (%s)" % [side,
			glass.surface_get_array_len(0) / 3, glass.surface_get_array_len(1) / 3, OUTPUT % side,
			error_string(error)])
		if error != OK:
			status = 1
	van.free()
	quit(status)
