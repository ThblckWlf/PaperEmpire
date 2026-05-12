extends Node2D
class_name WorldMap


signal countryPressed(countryId: StringName)
signal countryHoverChanged(countryId: StringName, isHovered: bool)

const COUNTRY_NODE_SCENE: PackedScene = preload("res://scenes/world/CountryNode.tscn")
const ARMY_NODE_SCENE: PackedScene = preload("res://scenes/world/ArmyNode.tscn")

@onready var countryLayer: Node2D = $CountryLayer as Node2D
@onready var armyLayer: Node2D = $ArmyLayer as Node2D
@onready var effectsLayer: Node = $EffectsLayer as Node
@onready var mapCamera = $MapCamera

var gameManager: GameManager
var eventBus: EventBus
var audioManager: AudioManager
var countryNodes: Dictionary = {}
var armyNodes: Dictionary = {}
var countryHitShapes: Dictionary = {}
var hoveredCountryId: StringName = GameIds.EMPTY_ID


func _process(_delta: float) -> void:
	_updateArmyNodesFromRunState()


func _input(event: InputEvent) -> void:
	if _isPointerOverUi():
		_updateHoveredCountry(GameIds.EMPTY_ID)
		return

	var mouseMotion := event as InputEventMouseMotion
	if mouseMotion != null:
		_updateHoveredCountry(_countryAtWorldPosition(get_global_mouse_position()))
		return

	var mouseButton := event as InputEventMouseButton
	if mouseButton == null or not mouseButton.pressed:
		return

	var countryId := _countryAtWorldPosition(get_global_mouse_position())
	if countryId == GameIds.EMPTY_ID:
		return

	if mouseButton.button_index == MOUSE_BUTTON_LEFT:
		_onCountryPressed(countryId)
		get_viewport().set_input_as_handled()
	elif mouseButton.button_index == MOUSE_BUTTON_RIGHT:
		_onCountryMoveTargetPressed(countryId)
		get_viewport().set_input_as_handled()


func configure(newGameManager: GameManager, newEventBus: EventBus, newAudioManager: AudioManager = null) -> void:
	_disconnectEventBus()
	gameManager = newGameManager
	eventBus = newEventBus
	audioManager = newAudioManager
	_connectEventBus()
	_configureEffectsLayer()
	refreshFromRunState()


func refreshFromRunState() -> void:
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return

	var runState := gameManager.getCurrentRunState()
	var selectedCountryId := gameManager.getSelectedCountryId()
	var mapShapes := PrototypeContentLoader.loadMapShapes()
	_clearCountryNodes()

	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := runState.countries[countryId] as CountryData
		if country == null:
			continue

		var polygons := _shapeForCountry(mapShapes, country.id)
		var node = COUNTRY_NODE_SCENE.instantiate()
		countryLayer.add_child(node)
		node.bindCountry(country, polygons, country.id == selectedCountryId)
		node.countryPressed.connect(_onCountryPressed)
		node.countryMoveTargetPressed.connect(_onCountryMoveTargetPressed)
		node.countryHoverChanged.connect(_onCountryHoverChanged)
		countryNodes[country.id] = node
		_setCountryHitShapes(country.id, country.center, polygons)

	_refreshArmyNodesFromRunState()
	_configureMapCamera(runState, mapShapes)


func getCountryNodeCount() -> int:
	return countryNodes.size()


func getCountryNode(countryId: StringName) -> Node:
	return countryNodes.get(countryId, null) as Node


func getArmyNodeCount() -> int:
	return armyNodes.size()


func getArmyNode(armyId: StringName) -> Node:
	return armyNodes.get(armyId, null) as Node


func _onCountryPressed(countryId: StringName) -> void:
	countryPressed.emit(countryId)
	if eventBus != null:
		eventBus.requestCommand(CommandType.SELECT_COUNTRY, {
			"countryId": str(countryId),
		})


func _onCountryMoveTargetPressed(countryId: StringName) -> void:
	if eventBus == null or gameManager == null:
		return

	var armyId := gameManager.getSelectedArmyId()
	if armyId == GameIds.EMPTY_ID:
		return

	var commandName := CommandType.MOVE_ARMY
	var runState := gameManager.getCurrentRunState()
	if runState != null and runState.countries.has(countryId):
		var targetCountry := runState.countries[countryId] as CountryData
		if targetCountry != null and targetCountry.ownerId != GameIds.PLAYER_OWNER_ID:
			commandName = CommandType.START_ATTACK

	eventBus.requestCommand(commandName, {
		"armyId": str(armyId),
		"targetCountryId": str(countryId),
	})


func _onArmyPressed(armyId: StringName) -> void:
	if eventBus != null:
		eventBus.requestCommand(CommandType.SELECT_ARMY, {
			"armyId": str(armyId),
		})


func _onCountryHoverChanged(countryId: StringName, isHovered: bool) -> void:
	countryHoverChanged.emit(countryId, isHovered)


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.COUNTRY_SELECTED:
			_updateSelection(StringName(str(payload.get("countryId", ""))))
		EventType.ARMY_SELECTED:
			var selectedArmyId := StringName(str(payload.get("armyId", "")))
			_updateArmySelection(selectedArmyId)
			if bool(payload.get("focusCamera", false)) and selectedArmyId != GameIds.EMPTY_ID:
				_focusCameraOnArmy(selectedArmyId)
		EventType.ARMY_MOVE_STARTED, EventType.ARMY_MOVED, EventType.UNITS_RECRUITED, EventType.ARMY_UPDATED, EventType.BATTLE_STARTED, EventType.BATTLE_ENDED:
			_updateArmyNodesFromRunState()
		EventType.ARMY_CREATED, EventType.COUNTRY_CONQUERED:
			_refreshArmyNodesFromRunState()
			_updateCountryOwnersFromRunState()
		EventType.RUN_STARTED, EventType.RUN_RESET:
			refreshFromRunState()


func _updateSelection(selectedCountryId: StringName) -> void:
	for countryId in countryNodes.keys():
		var node = countryNodes[countryId]
		if node != null:
			node.setSelected(countryId == selectedCountryId)


func _refreshArmyNodesFromRunState() -> void:
	_clearArmyNodes()
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return

	var runState := gameManager.getCurrentRunState()
	var selectedArmyId := gameManager.getSelectedArmyId()
	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		var node = ARMY_NODE_SCENE.instantiate()
		armyLayer.add_child(node)
		node.bindArmy(army, runState.countries, army.id == selectedArmyId)
		node.armyPressed.connect(_onArmyPressed)
		armyNodes[army.id] = node


func _updateArmyNodesFromRunState() -> void:
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return

	var runState := gameManager.getCurrentRunState()
	for armyId in armyNodes.keys():
		if not runState.armies.has(armyId):
			continue

		var army := runState.armies[armyId] as ArmyData
		var node = armyNodes[armyId]
		if army != null and node != null:
			node.updateFromArmy(army, runState.countries)


func _updateArmySelection(selectedArmyId: StringName) -> void:
	for armyId in armyNodes.keys():
		var node = armyNodes[armyId]
		if node != null:
			node.setSelected(armyId == selectedArmyId)


func _focusCameraOnArmy(armyId: StringName) -> void:
	if mapCamera == null or not mapCamera.has_method("focusOnWorldPosition"):
		return

	var armyNode := armyNodes.get(armyId, null) as Node2D
	if armyNode == null:
		return

	mapCamera.focusOnWorldPosition(armyNode.global_position)


func _updateCountryOwnersFromRunState() -> void:
	if gameManager == null or gameManager.getCurrentRunState() == null:
		return

	var runState := gameManager.getCurrentRunState()
	for countryId in countryNodes.keys():
		if not runState.countries.has(countryId):
			continue

		var country := runState.countries[countryId] as CountryData
		var node = countryNodes[countryId]
		if country != null and node != null:
			node.setOwner(country.ownerId)


func _clearCountryNodes() -> void:
	for child in countryLayer.get_children():
		child.queue_free()
	countryNodes.clear()
	countryHitShapes.clear()
	hoveredCountryId = GameIds.EMPTY_ID


func _clearArmyNodes() -> void:
	for child in armyLayer.get_children():
		child.queue_free()
	armyNodes.clear()


func _shapeForCountry(mapShapes: Dictionary, countryId: StringName) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not mapShapes.has(countryId):
		return result

	var shapeValue = mapShapes[countryId]
	if shapeValue is Array:
		for polygonValue in shapeValue:
			if polygonValue is PackedVector2Array:
				result.append(polygonValue as PackedVector2Array)
	return result


func _configureMapCamera(runState: RunState, mapShapes: Dictionary) -> void:
	if mapCamera == null or not mapCamera.has_method("setMapBounds"):
		return

	var bounds := _calculateMapBounds(runState, mapShapes)
	mapCamera.setMapBounds(bounds)


func _configureEffectsLayer() -> void:
	if effectsLayer == null or not effectsLayer.has_method("configure"):
		return

	effectsLayer.call("configure", gameManager, eventBus, self, audioManager)


func _calculateMapBounds(runState: RunState, mapShapes: Dictionary) -> Rect2:
	var hasBounds := false
	var bounds := Rect2()
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country == null:
			continue

		var polygons := _shapeForCountry(mapShapes, country.id)
		if polygons.is_empty():
			continue

		for points in polygons:
			for point in points:
				var worldPoint := country.center + point
				if hasBounds:
					bounds = bounds.expand(worldPoint)
				else:
					bounds = Rect2(worldPoint, Vector2.ZERO)
					hasBounds = true

	if not hasBounds:
		return Rect2(Vector2.ZERO, Vector2(4096.0, 2304.0))

	return bounds


func _setCountryHitShapes(countryId: StringName, center: Vector2, polygons: Array[PackedVector2Array]) -> void:
	var hitShapes: Array[Dictionary] = []
	for points in polygons:
		if points.size() < 3:
			continue

		var worldPoints := PackedVector2Array()
		for point in points:
			worldPoints.append(center + point)
		hitShapes.append({
			"points": worldPoints,
			"bounds": _polygonBounds(worldPoints),
			"area": absf(_polygonArea(worldPoints)),
		})
	countryHitShapes[countryId] = hitShapes


func _countryAtWorldPosition(worldPosition: Vector2) -> StringName:
	var bestCountryId := GameIds.EMPTY_ID
	var bestArea := INF
	for countryId in countryHitShapes.keys():
		var hitShapes: Array = countryHitShapes[countryId]
		for shape in hitShapes:
			if not (shape is Dictionary):
				continue

			var shapeData := shape as Dictionary
			var bounds := shapeData.get("bounds", Rect2()) as Rect2
			if not bounds.has_point(worldPosition):
				continue

			var points := shapeData.get("points", PackedVector2Array()) as PackedVector2Array
			if not _pointInPolygon(worldPosition, points):
				continue

			var area := float(shapeData.get("area", INF))
			if area < bestArea:
				bestArea = area
				bestCountryId = StringName(str(countryId))
	return bestCountryId


func _updateHoveredCountry(countryId: StringName) -> void:
	if hoveredCountryId == countryId:
		return

	var previousCountryId := hoveredCountryId
	if previousCountryId != GameIds.EMPTY_ID and countryNodes.has(previousCountryId):
		var previousNode = countryNodes[previousCountryId]
		if previousNode != null and previousNode.has_method("setHovered"):
			previousNode.call("setHovered", false)
		countryHoverChanged.emit(previousCountryId, false)

	hoveredCountryId = countryId
	if hoveredCountryId != GameIds.EMPTY_ID and countryNodes.has(hoveredCountryId):
		var nextNode = countryNodes[hoveredCountryId]
		if nextNode != null and nextNode.has_method("setHovered"):
			nextNode.call("setHovered", true)
		countryHoverChanged.emit(hoveredCountryId, true)


func _polygonBounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _polygonArea(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in range(points.size()):
		var nextIndex := (index + 1) % points.size()
		area += points[index].x * points[nextIndex].y
		area -= points[nextIndex].x * points[index].y
	return area * 0.5


func _pointInPolygon(point: Vector2, points: PackedVector2Array) -> bool:
	var inside := false
	var previousIndex := points.size() - 1
	for index in range(points.size()):
		var currentPoint := points[index]
		var previousPoint := points[previousIndex]
		var crossesY := (currentPoint.y > point.y) != (previousPoint.y > point.y)
		if crossesY:
			var slopeX := (previousPoint.x - currentPoint.x) * (point.y - currentPoint.y) / (previousPoint.y - currentPoint.y) + currentPoint.x
			if point.x < slopeX:
				inside = not inside
		previousIndex = index
	return inside


func _isPointerOverUi() -> bool:
	var viewport := get_viewport()
	return viewport != null and viewport.gui_get_hovered_control() != null


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
