extends Node2D
class_name EffectsLayer


signal visualEffectRaised(eventName: StringName, payload: Dictionary)

const MISSILE_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/MissileEffect.tscn")
const EXPLOSION_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/ExplosionEffect.tscn")
const MOVE_ARROW_TEXTURE: Texture2D = preload("res://assets/map/paths/moveArrowGreen.png")
const PATH_ARROW_HEAD_TEXTURE: Texture2D = preload("res://assets/map/paths/pathArrowHead.png")
const BATTLE_MARKER_TEXTURE: Texture2D = preload("res://assets/map/markers/battleMarker.png")
const BATTLE_CLASH_TEXTURE: Texture2D = preload("res://assets/vfx/battle/battleClashIcon.png")
const BATTLE_VICTORY_TEXTURE: Texture2D = preload("res://assets/vfx/battle/battleVictoryStamp.png")
const BATTLE_DEFEAT_TEXTURE: Texture2D = preload("res://assets/vfx/battle/battleDefeatStamp.png")
const CONQUEST_STAMP_TEXTURE: Texture2D = preload("res://assets/vfx/conquest/conquestStamp.png")

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
			_playBattleResultStamp(payload)
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
		if army == null or not _isMovementFeedbackStatus(army.status) or army.targetCountryId == GameIds.EMPTY_ID:
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
	var pathArrow := feedbackNode.get_node("PathArrow") as Sprite2D
	var markerNode := feedbackNode.get_node("ProgressMarker") as Sprite2D
	var progress := clampf(army.movementProgress, 0.0, 1.0)
	var currentPosition := sourceCountry.center.lerp(targetCountry.center, progress)
	var direction := targetCountry.center - sourceCountry.center
	var distance := direction.length()
	pathLine.points = PackedVector2Array([sourceCountry.center, targetCountry.center])
	pathArrow.position = sourceCountry.center.lerp(targetCountry.center, 0.5)
	pathArrow.rotation = direction.angle()
	pathArrow.scale = Vector2(maxf(distance / float(MOVE_ARROW_TEXTURE.get_width()), 0.1), 0.16)
	markerNode.position = currentPosition
	markerNode.rotation = direction.angle()


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
	pathLine.default_color = MOVEMENT_LINE_COLOR.darkened(0.35)
	feedbackNode.add_child(pathLine)

	var pathArrow := Sprite2D.new()
	pathArrow.name = "PathArrow"
	pathArrow.texture = MOVE_ARROW_TEXTURE
	pathArrow.centered = true
	pathArrow.modulate = Color(1.0, 1.0, 1.0, 0.82)
	feedbackNode.add_child(pathArrow)

	var markerNode := Sprite2D.new()
	markerNode.name = "ProgressMarker"
	markerNode.texture = PATH_ARROW_HEAD_TEXTURE
	markerNode.centered = true
	markerNode.modulate = MOVEMENT_MARKER_COLOR
	markerNode.scale = Vector2(0.14, 0.14)
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


func _isMovementFeedbackStatus(status: int) -> bool:
	return status == ArmyStatus.Value.Moving or status == ArmyStatus.Value.Attacking


func _startBattlePulse(payload: Dictionary) -> void:
	var battleId := StringName(str(payload.get("battleId", "")))
	var countryId := StringName(str(payload.get("targetCountryId", "")))
	if battleId == GameIds.EMPTY_ID or countryId == GameIds.EMPTY_ID:
		return
	if battleFeedback.has(battleId):
		return

	var feedbackNode := Node2D.new()
	feedbackNode.name = "BattleFeedback_%s" % str(battleId)
	feedbackNode.position = _countryCenter(countryId)
	feedbackNode.z_index = 42
	battleLayer.add_child(feedbackNode)

	var pulseNode := Polygon2D.new()
	pulseNode.name = "Pulse"
	pulseNode.polygon = _countryShapeOrCircle(countryId)
	pulseNode.color = BATTLE_PULSE_COLOR
	feedbackNode.add_child(pulseNode)

	var markerNode := Sprite2D.new()
	markerNode.name = "BattleMarker"
	markerNode.texture = BATTLE_MARKER_TEXTURE
	markerNode.centered = true
	markerNode.scale = Vector2(0.16, 0.16)
	feedbackNode.add_child(markerNode)

	var clashNode := Sprite2D.new()
	clashNode.name = "BattleClash"
	clashNode.texture = BATTLE_CLASH_TEXTURE
	clashNode.centered = true
	clashNode.scale = Vector2(0.12, 0.12)
	clashNode.position = Vector2(0.0, -22.0)
	feedbackNode.add_child(clashNode)
	battleFeedback[battleId] = feedbackNode

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

	var flashRoot := Node2D.new()
	flashRoot.name = "ConquestFlash_%s" % str(countryId)
	flashRoot.position = _countryCenter(countryId)
	flashRoot.z_index = 44
	oneShotLayer.add_child(flashRoot)

	var flashNode := Polygon2D.new()
	flashNode.name = "CountryFlash"
	flashNode.polygon = _countryShapeOrCircle(countryId)
	flashNode.color = CONQUEST_FLASH_COLOR
	flashRoot.add_child(flashNode)

	var stampNode := Sprite2D.new()
	stampNode.name = "ConquestStamp"
	stampNode.texture = CONQUEST_STAMP_TEXTURE
	stampNode.centered = true
	stampNode.scale = Vector2(0.22, 0.22)
	flashRoot.add_child(stampNode)

	var tween := flashRoot.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flashRoot, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flashRoot, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(flashRoot.queue_free)


func _playBattleResultStamp(payload: Dictionary) -> void:
	var countryId := StringName(str(payload.get("targetCountryId", "")))
	if countryId == GameIds.EMPTY_ID:
		return

	var stampNode := Sprite2D.new()
	stampNode.name = "BattleResultStamp_%s" % str(payload.get("battleId", ""))
	stampNode.texture = BATTLE_VICTORY_TEXTURE if bool(payload.get("attackerWon", false)) else BATTLE_DEFEAT_TEXTURE
	stampNode.centered = true
	stampNode.position = _countryCenter(countryId)
	stampNode.scale = Vector2(0.24, 0.24)
	stampNode.z_index = 45
	oneShotLayer.add_child(stampNode)

	var tween := stampNode.create_tween()
	tween.set_parallel(true)
	tween.tween_property(stampNode, "scale", Vector2(0.3, 0.3), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(stampNode, "modulate:a", 0.0, 0.55).set_delay(0.35)
	tween.set_parallel(false)
	tween.tween_callback(stampNode.queue_free)


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
