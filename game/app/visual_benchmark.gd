extends Node3D

const Audio = preload("res://features/audio/first_drive/driving_audio.gd")

@onready var van: CharacterBody3D = $FreightVan
var _spawn: Transform3D


func _ready() -> void:
	_spawn = van.global_transform
	var audio := Audio.new()
	add_child(audio)
	audio.configure(van)
	_set_driving(true)


func _set_driving(value: bool) -> void:
	van.input_enabled = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_driving(not van.input_enabled)
	elif event.is_action_pressed("recover"):
		van.recover(_spawn)
