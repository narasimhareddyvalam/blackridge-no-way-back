extends RefCounted

const GRAVITY := 9.81
const WATER_DENSITY := 1000.0
const AIR_DENSITY := 1.2
const SURFACE_TENSION := 0.072
const CONTACT_ANGLE := 0.8727
const CONTACT_HYSTERESIS := 0.32
const DROP_DRAG := 0.8
const BOUNDARY_LAYER := 0.002
const SLIDE_RESISTANCE := 1.16
const FILM_THICKNESS := 0.00005
const WATER_VISCOSITY := 0.001
const SKIN_FRICTION := 0.005
const RESPONSE_SECONDS := 0.15
const RADII := Vector4(0.0016, 0.0022, 0.003, 0.0038)
const RUNNER_RADIUS := 0.0055

var travel := Vector4.ZERO
var travel_x := Vector4.ZERO
var travel_y := Vector4.ZERO
var speed := Vector4.ZERO
var runner_travel: float = 0.0
var runner_speed: float = 0.0
var runner_down: float = 0.0
var runner_up: float = 0.0
var film_travel: float = 0.0
var direction := Vector2(0.0, -1.0)


static func drop_velocity(radius: float, down: Vector2, air: Vector2) -> Vector2:
	var cap := cos(CONTACT_ANGLE)
	var rim := sin(CONTACT_ANGLE)
	var volume := PI * (2.0 - 3.0 * cap + cap * cap * cap) / (3.0 * rim * rim * rim) \
		* radius * radius * radius
	var height := radius * (1.0 - cap) / rim
	var wind := air * minf(1.0, height / BOUNDARY_LAYER)
	var area := 4.0 / 3.0 * radius * height
	var force := down * WATER_DENSITY * volume * GRAVITY \
		+ wind * wind.length() * 0.5 * AIR_DENSITY * DROP_DRAG * area
	var excess := force.length() - SURFACE_TENSION * 2.0 * radius * CONTACT_HYSTERESIS
	if excess <= 0.0:
		return Vector2.ZERO
	return force.normalized() * excess / (SLIDE_RESISTANCE * radius)


static func film_velocity(down: Vector2, air: Vector2) -> Vector2:
	var drain := down * WATER_DENSITY * GRAVITY * FILM_THICKNESS * FILM_THICKNESS \
		/ (3.0 * WATER_VISCOSITY)
	var shear := air * air.length() * 0.5 * AIR_DENSITY * SKIN_FRICTION
	return drain + shear * FILM_THICKNESS / (2.0 * WATER_VISCOSITY)


func step(delta: float, down: Vector2, air: Vector2, axis: Vector2) -> void:
	var blend := 1.0 - exp(-delta / RESPONSE_SECONDS)
	var lead := drop_velocity(RUNNER_RADIUS, down, air)
	if lead.length() > 0.0001:
		direction = direction.lerp(lead.normalized(), blend).normalized()
	var along := axis if axis != Vector2.ZERO else direction
	for index in range(4):
		var velocity := drop_velocity(RADII[index], down, air)
		speed[index] = lerpf(speed[index], velocity.dot(along), blend)
		travel[index] += speed[index] * delta
		travel_x[index] += velocity.x * delta
		travel_y[index] += velocity.y * delta
	runner_speed = lerpf(runner_speed, lead.dot(along), blend)
	runner_travel += runner_speed * delta
	runner_down += maxf(-runner_speed, 0.0) * delta
	runner_up += maxf(runner_speed, 0.0) * delta
	film_travel += film_velocity(down, air).dot(along) * delta
