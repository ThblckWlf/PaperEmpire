extends Node2D
class_name ExplosionEffect


signal finished

const FLASH_COLOR: Color = Color(1.0, 0.78, 0.28, 0.55)
const RING_COLOR: Color = Color(1.0, 0.32, 0.12, 0.7)
const PARTICLE_COLOR: Color = Color(1.0, 0.62, 0.22, 0.8)
const DURATION_SECONDS: float = 0.65

var flashNode: Polygon2D
var ringNode: Line2D
var particlesNode: CPUParticles2D


func _ready() -> void:
	_createVisuals()
	play()


func play() -> void:
	if particlesNode != null:
		particlesNode.emitting = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flashNode, "scale", Vector2(1.45, 1.45), DURATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flashNode, "modulate:a", 0.0, DURATION_SECONDS)
	tween.tween_property(ringNode, "scale", Vector2(2.0, 2.0), DURATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ringNode, "modulate:a", 0.0, DURATION_SECONDS)
	tween.set_parallel(false)
	tween.tween_callback(_finish)


func _finish() -> void:
	finished.emit()
	queue_free()


func _createVisuals() -> void:
	flashNode = Polygon2D.new()
	flashNode.name = "Flash"
	flashNode.polygon = _circlePoints(24, 18.0)
	flashNode.color = FLASH_COLOR
	flashNode.z_index = 48
	add_child(flashNode)

	ringNode = Line2D.new()
	ringNode.name = "Ring"
	ringNode.points = _closedCirclePoints(32, 22.0)
	ringNode.width = 3.0
	ringNode.default_color = RING_COLOR
	ringNode.z_index = 49
	add_child(ringNode)

	particlesNode = CPUParticles2D.new()
	particlesNode.name = "Particles"
	particlesNode.amount = 32
	particlesNode.lifetime = 0.45
	particlesNode.one_shot = true
	particlesNode.explosiveness = 1.0
	particlesNode.direction = Vector2.UP
	particlesNode.spread = 180.0
	particlesNode.gravity = Vector2.ZERO
	particlesNode.initial_velocity_min = 45.0
	particlesNode.initial_velocity_max = 115.0
	particlesNode.scale_amount_min = 1.8
	particlesNode.scale_amount_max = 3.2
	particlesNode.color = PARTICLE_COLOR
	particlesNode.z_index = 50
	add_child(particlesNode)


func _circlePoints(count: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _closedCirclePoints(count: int, radius: float) -> PackedVector2Array:
	var points := _circlePoints(count, radius)
	if not points.is_empty():
		points.append(points[0])
	return points
