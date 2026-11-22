extends Node3D
## Bay 9's dock station (step 3 of #253, #263-#265): where its dock worker sits between jobs, as a
## dock's checker does, by the door he works. On the dock floor in the corner east of the lift,
## along the edge rail: Poly Haven's Metal Office Desk, its drawers toward the lift; Red Fox's
## office chair in its kneehole, facing it, so that he sits side-on to the doorway and is seen
## through it from the yard; on the desk Poly Haven's Clipboard, the seal log, and its Stationery
## Supplies' pen cup. Out of the way of the load's approach to the lift, its pit and the way to
## the dock stair. The desk and the chair are solid; the chair has its own body, to move with it.

const MODELS := "res://features/environments/industrial_loop/art/dock_station/models/%s/%s.gltf"
const CHAIR_MODEL := preload(
	"res://features/environments/industrial_loop/art/depot/office_chair.glb")
const FLOOR := 1.3
const DESK_TOP := 0.788
## The desk's footprint as it stands, turned: 0.947 m deep across x, 2.0 m long along z.
const DESK := Vector3(-45.31, FLOOR, 18.55)
const DESK_SIZE := Vector3(0.947, DESK_TOP, 2.0)
const CHAIR := Vector3(-46.14, FLOOR, 18.55)
const CHAIR_BODY := Vector2(0.3, 0.89)
const SEAL_LOG := Vector3(-45.41, FLOOR + DESK_TOP, 18.35)
const PEN_CUP := Vector3(-45.11, FLOOR + DESK_TOP, 19.0)

var chair: Node3D


func build() -> void:
	var desk := _model("metal_office_desk", "Desk", DESK, -PI / 2.0)
	var body := StaticBody3D.new()
	body.name = "DeskBody"
	desk.add_child(body)
	var box := BoxShape3D.new()
	box.size = Vector3(DESK_SIZE.z, DESK_SIZE.y, DESK_SIZE.x)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, DESK_TOP / 2.0, 0.0)
	body.add_child(shape)
	chair = CHAIR_MODEL.instantiate() as Node3D
	chair.name = "Chair"
	add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0), CHAIR)
	var seat := StaticBody3D.new()
	seat.name = "ChairBody"
	chair.add_child(seat)
	var round := CylinderShape3D.new()
	round.radius = CHAIR_BODY.x
	round.height = CHAIR_BODY.y
	var column := CollisionShape3D.new()
	column.shape = round
	column.position = Vector3(0.0, CHAIR_BODY.y / 2.0, 0.0)
	seat.add_child(column)
	_standing(_model("clipboard", "SealLog", SEAL_LOG, deg_to_rad(-82.0)), SEAL_LOG.y)
	_standing(_model("stationery_supplies", "PenCup", PEN_CUP, deg_to_rad(-60.0)), PEN_CUP.y)


func _model(asset: String, label: String, at: Vector3, turn: float) -> Node3D:
	var model := (load(MODELS % [asset, asset]) as PackedScene).instantiate() as Node3D
	model.name = label
	add_child(model)
	model.global_transform = Transform3D(Basis(Vector3.UP, turn), at)
	return model


## `model` set down so that its lowest point rests at `top`: a model's origin is not always at
## its foot (the pen cup's is 0.074 m above it).
func _standing(model: Node3D, top: float) -> void:
	var lowest := INF
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		lowest = minf(lowest, (mesh.global_transform * mesh.get_aabb()).position.y)
	if lowest < INF:
		model.global_position.y += top - lowest
