extends Node2D
class_name MissileEffect


signal impactReached(worldPosition: Vector2)

const DEFAULT_DURATION_SECONDS: float = 0.75
const ARC_HEIGHT: float = 54.0
const TRAIL_COLOR: Color = Color(1.0, 0.74, 0.32, 0.55)
const MISSILE_COLOR: Color = Color(0.98, 0.96, 0.88, 1.0)

var startPosition: Vector2 = Vector2.ZERO
var targetPosition: Vector2 = Vector2.ZERO
var trailNode: Line2D
var missileNode: Polygon2D


func _ready() -> void:
	_createVisuals()


func launch(fromPosition: Vector2, toPosition: Vector2, durationSeconds: float = DEFAULT_DURATION_SECONDS) -> void:
	startPosition = fromPosition
	targetPosition = toPosition
	_setFlightProgress(0.0)

	var tween := create_tween()
	tween.tween_method(_setFlightProgress, 0.0, 1.0, maxf(durationSeconds, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finishImpact)


func _setFlightProgress(progress: float) -> void:
	var clampedProgress := clampf(progress, 0.0, 1.0)
	var currentPosition := startPosition.lerp(targetPosition, clampedProgress)
	currentPosition.y -= sin(clampedProgress * PI) * ARC_HEIGHT

	missileNode.position = currentPosition
	missileNode.rotation = (targetPosition - startPosition).angle()
	trailNode.points = PackedVector2Array([startPosition, currentPosition])


func _finishImpact() -> void:
	impactReached.emit(targetPosition)
	queue_free()


func _createVisuals() -> void:
	trailNode = Line2D.new()
	trailNode.name = "Trail"
	trailNode.width = 3.0
	trailNode.default_color = TRAIL_COLOR
	trailNode.z_index = 35
	add_child(trailNode)

	missileNode = Polygon2D.new()
	missileNode.name = "Missile"
	missileNode.polygon = PackedVector2Array([
		Vector2(13.0, 0.0),
		Vector2(-8.0, -5.0),
		Vector2(-4.0, 0.0),
		Vector2(-8.0, 5.0),
	])
	missileNode.color = MISSILE_COLOR
	missileNode.z_index = 36
	add_child(missileNode)
