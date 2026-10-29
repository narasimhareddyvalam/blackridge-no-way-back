extends Node

const NIGHT_SHADER = preload("res://shaders/night_cluster.gdshader")

@export var fade_in_seconds: float = 0.25
@export var fade_out_seconds: float = 0.35

var vehicle: CharacterBody3D
var material := ShaderMaterial.new()
var night_amount: float = 0.0


func configure(van: CharacterBody3D, cluster: CanvasItem) -> void:
	vehicle = van
	material.shader = NIGHT_SHADER
	cluster.material = material
	night_amount = 1.0 if vehicle.headlights_on else 0.0
	material.set_shader_parameter("night_amount", night_amount)


func _process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	var target := 1.0 if vehicle.headlights_on else 0.0
	if night_amount == target:
		return
	var seconds := fade_in_seconds if target > night_amount else fade_out_seconds
	night_amount = move_toward(night_amount, target, delta / seconds)
	if absf(target - night_amount) < 0.000001:
		night_amount = target
	material.set_shader_parameter("night_amount", night_amount)
