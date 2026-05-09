extends Node2D
class_name WorldMap


signal countryPressed(countryId: StringName)
signal countryHoverChanged(countryId: StringName, isHovered: bool)

const COUNTRY_NODE_SCENE: PackedScene = preload("res://scenes/world/CountryNode.tscn")

@onready var countryLayer: Node2D = $CountryLayer as Node2D

var gameManager: GameManager
var eventBus: EventBus
var countryNodes: Dictionary = {}


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
		node.countryHoverChanged.connect(_onCountryHoverChanged)
		countryNodes[country.id] = node


func getCountryNodeCount() -> int:
	return countryNodes.size()


func getCountryNode(countryId: StringName) -> Node:
	return countryNodes.get(countryId, null) as Node


func _onCountryPressed(countryId: StringName) -> void:
	countryPressed.emit(countryId)
	if eventBus != null:
		eventBus.requestCommand(CommandType.SELECT_COUNTRY, {
			"countryId": str(countryId),
		})


func _onCountryHoverChanged(countryId: StringName, isHovered: bool) -> void:
	countryHoverChanged.emit(countryId, isHovered)


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.COUNTRY_SELECTED:
			_updateSelection(StringName(str(payload.get("countryId", ""))))
		EventType.RUN_STARTED, EventType.RUN_RESET:
			refreshFromRunState()


func _updateSelection(selectedCountryId: StringName) -> void:
	for countryId in countryNodes.keys():
		var node = countryNodes[countryId]
		if node != null:
			node.setSelected(countryId == selectedCountryId)


func _clearCountryNodes() -> void:
	for child in countryLayer.get_children():
		child.queue_free()
	countryNodes.clear()


func _shapeForCountry(mapShapes: Dictionary, countryId: StringName) -> PackedVector2Array:
	if not mapShapes.has(countryId):
		return PackedVector2Array()

	var points: PackedVector2Array = mapShapes[countryId]
	return points


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
