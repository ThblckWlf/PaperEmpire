extends Node2D
class_name EffectsLayer


signal visualEffectRaised(eventName: StringName, payload: Dictionary)

const MISSILE_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/MissileEffect.tscn")
const EXPLOSION_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/ExplosionEffect.tscn")

const MOVEMENT_LINE_COLOR: Color = Color(0.2, 0.82, 0.72, 0.55)
const MOVEMENT_MARKER_COLOR: Color = Color(0.22, 0.92, 0.78, 0.9)
const BATTLE_PULSE_COLOR: Color = Color(1.0, 0.18, 0.12, 0.32)
const CONQUEST_FLASH_COLOR: Color = Color(1.0, 0.86, 0.28, 0.5)

@onready var movementLayer: Node2D = $MovementFeedback as Node2D
@onready var battleLayer: Node2D = $BattleFeedback as Node2D
@onready var oneShotLayer: Node2D = $OneShotFeedback as Node2D

var gameManager: GameManager
var eventBus: EventBus
var worldMap: Node
var audioManager: AudioManager
var movementFeedback: Dictionary = {}
var battleFeedback: Dictionary = {}


func _process(_delta: float) -> void:
	_refreshMovementFeedback()


func configure(
	newGameManager: GameManager,
	newEventBus: EventBus,
	newWorldMap: Node,
	newAudioManager: AudioManager = null
) -> void:
	_disconnectEventBus()
	gameManager = newGameManager
	eventBus = newEventBus
	worldMap = newWorldMap
	audioManager = newAudioManager
	_connectEventBus()
	_clearAll()
	_refreshMovementFeedback()


func getMovementFeedbackCount() -> int:
	return movementFeedback.size()


func getBattleFeedbackCount() -> int:
	return battleFeedback.size()


func getOneShotFeedbackCount() -> int:
	return oneShotLayer.get_child_count()


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.ARMY_MOVE_STARTED:
			_refreshMovementFeedback()
		EventType.ARMY_MOVED:
			_removeMovementFeedback(StringName(str(payload.get("armyId", ""))))
		EventType.BATTLE_STARTED:
			_startBattlePulse(payload)
		EventType.BATTLE_ENDED:
			_stopBattlePulse(StringName(str(payload.get("battleId", ""))))
		EventType.COUNTRY_CONQUERED:
			_playConquestFlash(StringName(str(payload.get("countryId", ""))))
		EventType.MISSILE_LAUNCHED:
			_playMissile(payload)
		EventType.RUN_STARTED, EventType.RUN_RESET:
			_clearAll()


func _refreshMovementFeedback() -> void:
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return

	var runState := gameManager.getCurrentRunState()
	var activeArmyIds := {}
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.status != ArmyStatus.Value.Moving or army.targetCountryId == GameIds.EMPTY_ID:
			continue

		activeArmyIds[army.id] = true
		_updateMovementFeedback(army, runState.countries)

	for armyId in movementFeedback.keys():
		if not activeArmyIds.has(armyId):
			_removeMovementFeedback(StringName(str(armyId)))


func _updateMovementFeedback(army: ArmyData, countries: Dictionary) -> void:
	var sourceCountry := countries.get(army.locationCountryId, null) as CountryData
	var targetCountry := countries.get(army.targetCountryId, null) as CountryData
	if sourceCountry == null or targetCountry == null:
		_removeMovementFeedback(army.id)
		return

	var feedbackNode := _ensureMovementFeedback(army.id)
	var pathLine := feedbackNode.get_node("PathLine") as Line2D
	var markerNode := feedbackNode.get_node("ProgressMarker") as Polygon2D
	var progress := clampf(army.movementProgress, 0.0, 1.0)
	var currentPosition := sourceCountry.center.lerp(targetCountry.center, progress)
	pathLine.points = PackedVector2Array([sourceCountry.center, targetCountry.center])
	markerNode.position = currentPosition
	markerNode.rotation = (targetCountry.center - sourceCountry.center).angle()


func _ensureMovementFeedback(armyId: StringName) -> Node2D:
	if movementFeedback.has(armyId):
		return movementFeedback[armyId] as Node2D

	var feedbackNode := Node2D.new()
	feedbackNode.name = "MovementFeedback_%s" % str(armyId)
	feedbackNode.z_index = 25
	movementLayer.add_child(feedbackNode)

	var pathLine := Line2D.new()
	pathLine.name = "PathLine"
	pathLine.width = 3.0
	pathLine.default_color = MOVEMENT_LINE_COLOR
	feedbackNode.add_child(pathLine)

	var markerNode := Polygon2D.new()
	markerNode.name = "ProgressMarker"
	markerNode.polygon = PackedVector2Array([
		Vector2(11.0, 0.0),
		Vector2(-7.0, -5.0),
		Vector2(-4.0, 0.0),
		Vector2(-7.0, 5.0),
	])
	markerNode.color = MOVEMENT_MARKER_COLOR
	feedbackNode.add_child(markerNode)

	var tween := feedbackNode.create_tween()
	tween.set_loops()
	tween.tween_property(markerNode, "scale", Vector2(1.25, 1.25), 0.35)
	tween.tween_property(markerNode, "scale", Vector2.ONE, 0.35)

	movementFeedback[armyId] = feedbackNode
	return feedbackNode


func _removeMovementFeedback(armyId: StringName) -> void:
	if not movementFeedback.has(armyId):
		return

	var feedbackNode := movementFeedback[armyId] as Node2D
	movementFeedback.erase(armyId)
	if feedbackNode != null:
		feedbackNode.queue_free()


func _startBattlePulse(payload: Dictionary) -> void:
	var battleId := StringName(str(payload.get("battleId", "")))
	var countryId := StringName(str(payload.get("targetCountryId", "")))
	if battleId == GameIds.EMPTY_ID or countryId == GameIds.EMPTY_ID:
		return
	if battleFeedback.has(battleId):
		return

	var pulseNode := Polygon2D.new()
	pulseNode.name = "BattlePulse_%s" % str(battleId)
	pulseNode.position = _countryCenter(countryId)
	pulseNode.polygon = _countryShapeOrCircle(countryId)
	pulseNode.color = BATTLE_PULSE_COLOR
	pulseNode.z_index = 42
	battleLayer.add_child(pulseNode)
	battleFeedback[battleId] = pulseNode

	var tween := pulseNode.create_tween()
	tween.set_loops()
	tween.tween_property(pulseNode, "scale", Vector2(1.06, 1.06), 0.28)
	tween.parallel().tween_property(pulseNode, "modulate:a", 0.45, 0.28)
	tween.tween_property(pulseNode, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(pulseNode, "modulate:a", 0.7, 0.28)


func _stopBattlePulse(battleId: StringName) -> void:
	if not battleFeedback.has(battleId):
		return

	var pulseNode := battleFeedback[battleId] as Node2D
	battleFeedback.erase(battleId)
	if pulseNode != null:
		pulseNode.queue_free()


func _playConquestFlash(countryId: StringName) -> void:
	if countryId == GameIds.EMPTY_ID:
		return

	var flashNode := Polygon2D.new()
	flashNode.name = "ConquestFlash_%s" % str(countryId)
	flashNode.position = _countryCenter(countryId)
	flashNode.polygon = _countryShapeOrCircle(countryId)
	flashNode.color = CONQUEST_FLASH_COLOR
	flashNode.z_index = 44
	oneShotLayer.add_child(flashNode)

	var tween := flashNode.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flashNode, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flashNode, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(flashNode.queue_free)


func _playMissile(payload: Dictionary) -> void:
	var fromCountryId := StringName(str(payload.get("fromCountryId", payload.get("sourceCountryId", ""))))
	var targetCountryId := StringName(str(payload.get("targetCountryId", payload.get("toCountryId", ""))))
	if fromCountryId == GameIds.EMPTY_ID or targetCountryId == GameIds.EMPTY_ID:
		return

	var missile := MISSILE_EFFECT_SCENE.instantiate()
	if missile == null:
		return

	oneShotLayer.add_child(missile)
	if missile.has_signal("impactReached"):
		missile.connect("impactReached", Callable(self, "_onMissileImpact"))
	if missile.has_method("launch"):
		missile.call("launch", _countryCenter(fromCountryId), _countryCenter(targetCountryId))
	visualEffectRaised.emit(&"missileLaunchedVisual", {
		"fromCountryId": fromCountryId,
		"targetCountryId": targetCountryId,
	})


func _onMissileImpact(worldPosition: Vector2) -> void:
	_spawnExplosion(worldPosition)
	if audioManager != null:
		audioManager.playSfx(AudioManager.SOUND_EXPLOSION)
	visualEffectRaised.emit(&"missileImpactVisual", {
		"position": worldPosition,
	})


func _spawnExplosion(worldPosition: Vector2) -> void:
	var explosion := EXPLOSION_EFFECT_SCENE.instantiate()
	if explosion == null:
		return

	explosion.position = worldPosition
	oneShotLayer.add_child(explosion)


func _countryCenter(countryId: StringName) -> Vector2:
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return Vector2.ZERO

	var country := gameManager.getCurrentRunState().countries.get(countryId, null) as CountryData
	if country == null:
		return Vector2.ZERO
	return country.center


func _countryShapeOrCircle(countryId: StringName) -> PackedVector2Array:
	var mapShapes := PrototypeContentLoader.loadMapShapes()
	if mapShapes.has(countryId):
		var shapeValue = mapShapes[countryId]
		if shapeValue is PackedVector2Array:
			return shapeValue as PackedVector2Array
		if shapeValue is Array:
			var largestPolygon := PackedVector2Array()
			var largestArea := 0.0
			for polygonValue in shapeValue:
				if not (polygonValue is PackedVector2Array):
					continue

				var polygon := polygonValue as PackedVector2Array
				var area := absf(_polygonArea(polygon))
				if area > largestArea:
					largestArea = area
					largestPolygon = polygon
			if largestPolygon.size() >= 3:
				return largestPolygon

	return _circlePoints(24, 24.0)


func _polygonArea(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0

	var area := 0.0
	for index in range(points.size()):
		var nextIndex := (index + 1) % points.size()
		area += points[index].x * points[nextIndex].y
		area -= points[nextIndex].x * points[index].y
	return area * 0.5


func _circlePoints(count: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _clearAll() -> void:
	for child in movementLayer.get_children():
		child.queue_free()
	for child in battleLayer.get_children():
		child.queue_free()
	for child in oneShotLayer.get_children():
		child.queue_free()
	movementFeedback.clear()
	battleFeedback.clear()


func _connectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)


func _disconnectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)
