extends CharacterBody3D

const Build = preload("res://shared/components/mesh_builder.gd")
var active: bool = false
var _pivot: Node3D
var _camera: Camera3D
var _body: Node3D
var _legs: Array[Node3D] = []
var _step: float = 0.0
var _collision: CollisionShape3D


func _ready() -> void:
	var collision := CollisionShape3D.new()
	_collision = collision
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.88
	add_child(collision)
	collision_layer = 4
	collision_mask = 3
	_body = Node3D.new()
	add_child(_body)
	var coat := Build.material(Color("24353d"))
	var trousers := Build.material(Color("1a2229"))
	Build.box(_body, Vector3(0, 1.17, 0), Vector3(0.48, 0.65, 0.26), coat)
	Build.cylinder(_body, Vector3(0, 1.66, 0), 0.13, 0.28,
		Build.material(Color("76675b")))
	for side in [-1, 1]:
		var leg := Node3D.new()
		_body.add_child(leg)
		leg.position = Vector3(side * 0.13, 0.85, 0)
		Build.box(leg, Vector3(0, -0.40, 0), Vector3(0.18, 0.8, 0.22), trousers)
		_legs.append(leg)
		Build.box(_body, Vector3(side * 0.32, 1.10, 0), Vector3(0.15, 0.65, 0.19), coat)
	_pivot = Node3D.new()
	_pivot.position.y = 1.45
	add_child(_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 3.5
	arm.margin = 0.2
	arm.collision_mask = 3
	arm.add_excluded_object(get_rid())
	arm.rotation.x = -0.14
	_pivot.add_child(arm)
	_camera = Camera3D.new()
	_camera.fov = 70
	arm.add_child(_camera)
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value
	set_physics_process(value)
	_collision.set_deferred("disabled", not value)
	if value:
		_camera.make_current()


func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	var direction := _pivot.global_basis * Vector3(movement.x, 0, movement.y)
	direction.y = 0
	direction = direction.normalized()
	var pace := 5.0 if Input.is_action_pressed("sprint") else 2.8
	velocity.x = direction.x * pace
	velocity.z = direction.z * pace
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18 * delta
	move_and_slide()
	if direction.length_squared() > 0.1:
		_body.rotation.y = lerp_angle(_body.rotation.y,
			atan2(-direction.x, -direction.z), 1.0 - exp(-delta * 12))
		_step += delta * pace * 2.2
	for index in range(_legs.size()):
		_legs[index].rotation.x = sin(_step + index * PI) * movement.length() * 0.45


func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pivot.rotation.y -= event.relative.x * 0.002
		_pivot.rotation.x = clampf(_pivot.rotation.x - event.relative.y * 0.002, -0.5, 0.6)


func get_camera() -> Camera3D:
	return _camera
