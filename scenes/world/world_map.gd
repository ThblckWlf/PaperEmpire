extends Node2D
class_name WorldMap


signal countryPressed(countryId: StringName)
signal countryHoverChanged(countryId: StringName, isHovered: bool)

const COUNTRY_NODE_SCENE: PackedScene = preload("res://scenes/world/CountryNode.tscn")
const ARMY_NODE_SCENE: PackedScene = preload("res://scenes/world/ArmyNode.tscn")

@onready var countryLayer: Node2D = $CountryLayer as Node2D
@onready var armyLayer: Node2D = $ArmyLayer as Node2D
@onready var mapCamera = $MapCamera

var gameManager: GameManager
var eventBus: EventBus
var countryNodes: Dictionary = {}
var armyNodes: Dictionary = {}


func _process(_delta: float) -> void:
	_updateArmyNodesFromRunState()


func configure(newGameManager: GameManager, newEventBus: EventBus) -> void:
	_disconnectEventBus()
	gameManager = newGameManager
	eventBus = newEventBus
	_connectEventBus()
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

		var node = COUNTRY_NODE_SCENE.instantiate()
		countryLayer.add_child(node)
		node.bindCountry(country, _shapeForCountry(mapShapes, country.id), country.id == selectedCountryId)
		node.countryPressed.connect(_onCountryPressed)
		node.countryMoveTargetPressed.connect(_onCountryMoveTargetPressed)
		node.countryHoverChanged.connect(_onCountryHoverChanged)
		countryNodes[country.id] = node

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

	eventBus.requestCommand(CommandType.MOVE_ARMY, {
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
			_updateArmySelection(StringName(str(payload.get("armyId", ""))))
		EventType.ARMY_MOVE_STARTED, EventType.ARMY_MOVED, EventType.UNITS_RECRUITED:
			_updateArmyNodesFromRunState()
		EventType.ARMY_CREATED:
			_refreshArmyNodesFromRunState()
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


func _clearCountryNodes() -> void:
	for child in countryLayer.get_children():
		child.queue_free()
	countryNodes.clear()


func _clearArmyNodes() -> void:
	for child in armyLayer.get_children():
		child.queue_free()
	armyNodes.clear()


func _shapeForCountry(mapShapes: Dictionary, countryId: StringName) -> PackedVector2Array:
	if not mapShapes.has(countryId):
		return PackedVector2Array()

	var points: PackedVector2Array = mapShapes[countryId]
	return points


func _configureMapCamera(runState: RunState, mapShapes: Dictionary) -> void:
	if mapCamera == null or not mapCamera.has_method("setMapBounds"):
		return

	var bounds := _calculateMapBounds(runState, mapShapes)
	mapCamera.setMapBounds(bounds)


func _calculateMapBounds(runState: RunState, mapShapes: Dictionary) -> Rect2:
	var hasBounds := false
	var bounds := Rect2()
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country == null:
			continue

		var points := _shapeForCountry(mapShapes, country.id)
		if points.is_empty():
			continue

		for point in points:
			var worldPoint := country.center + point
			if hasBounds:
				bounds = bounds.expand(worldPoint)
			else:
				bounds = Rect2(worldPoint, Vector2.ZERO)
				hasBounds = true

	if not hasBounds:
		return Rect2(Vector2(40.0, 170.0), Vector2(430.0, 330.0))

	return bounds


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
