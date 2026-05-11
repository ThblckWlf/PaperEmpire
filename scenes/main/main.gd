extends Node


const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://src/save/settings_manager.gd")
const MOCK_PLATFORM_SERVICE_SCRIPT := preload("res://src/platform/mock_platform_service.gd")
const PLATFORM_EVENT_BRIDGE_SCRIPT := preload("res://src/platform/platform_event_bridge.gd")

@onready var eventBus: EventBus = $GameRoot/Managers/EventBus as EventBus
@onready var managersNode: Node = $GameRoot/Managers as Node
@onready var gameManager: GameManager = $GameRoot/Managers/GameManager as GameManager
@onready var simulationManager: SimulationManager = $GameRoot/Managers/SimulationManager as SimulationManager
@onready var audioManager: AudioManager = $GameRoot/Managers/AudioManager as AudioManager
@onready var worldRoot: Node2D = $GameRoot/WorldRoot as Node2D
@onready var worldMap = $GameRoot/WorldRoot/WorldMap
@onready var uiRoot = $GameRoot/UIRoot


func _ready() -> void:
	INPUT_ACTIONS.ensureDefaultActions()
	var saveManager := _createSaveManager()
	var settingsManager := _createSettingsManager()
	var platformService := _createPlatformService()
	var platformEventBridge := _createPlatformEventBridge()
	eventBus.logGameEvents = OS.is_debug_build()
	platformService.call("initialize")
	platformEventBridge.call("configure", eventBus, platformService)
	gameManager.setEventBus(eventBus)
	gameManager.setSimulationManager(simulationManager)
	gameManager.setSaveManager(saveManager)
	worldMap.configure(gameManager, eventBus, audioManager)
	audioManager.configure(eventBus)
	settingsManager.loadSettings()
	uiRoot.configure(gameManager, eventBus, settingsManager, saveManager)
	uiRoot.newRunRequested.connect(_startNewRunFromMenu)
	uiRoot.loadGameRequested.connect(_loadRunFromMenu)
	uiRoot.returnToMainMenuRequested.connect(_returnToMainMenu)
	uiRoot.quitGameRequested.connect(_quitGame)
	uiRoot.gameplayVisibilityChanged.connect(_setGameplayVisible)
	settingsManager.configure(audioManager, uiRoot)
	simulationManager.processTicks = false
	_setGameplayVisible(false)
	uiRoot.showMainMenu()


func _createSaveManager() -> SaveManager:
	var existingSaveManager := managersNode.get_node_or_null("SaveManager") as SaveManager
	if existingSaveManager != null:
		return existingSaveManager

	var saveManager := SaveManager.new()
	saveManager.name = "SaveManager"
	managersNode.add_child(saveManager)
	return saveManager


func _createSettingsManager() -> Node:
	var existingSettingsManager := managersNode.get_node_or_null("SettingsManager")
	if existingSettingsManager != null:
		return existingSettingsManager

	var settingsManager := SETTINGS_MANAGER_SCRIPT.new()
	settingsManager.name = "SettingsManager"
	managersNode.add_child(settingsManager)
	return settingsManager


func _createPlatformService() -> Node:
	var existingPlatformService := managersNode.get_node_or_null("PlatformService")
	if existingPlatformService != null:
		return existingPlatformService

	var platformService := MOCK_PLATFORM_SERVICE_SCRIPT.new()
	platformService.name = "PlatformService"
	managersNode.add_child(platformService)
	return platformService


func _createPlatformEventBridge() -> Node:
	var existingBridge := managersNode.get_node_or_null("PlatformEventBridge")
	if existingBridge != null:
		return existingBridge

	var bridge := PLATFORM_EVENT_BRIDGE_SCRIPT.new()
	bridge.name = "PlatformEventBridge"
	managersNode.add_child(bridge)
	return bridge


func _startNewRunFromMenu(startCountryId: String) -> void:
	gameManager.startNewRun(startCountryId)
	_showGameplay()


func _loadRunFromMenu(slotId: String) -> void:
	eventBus.requestCommand(CommandType.LOAD_GAME, {
		"slotId": slotId,
	})
	if gameManager.getCurrentRunState() != null:
		_showGameplay()


func _returnToMainMenu() -> void:
	if gameManager.getCurrentRunState() != null:
		eventBus.requestCommand(CommandType.PAUSE_GAME)
	simulationManager.processTicks = false
	uiRoot.showMainMenu()


func _showGameplay() -> void:
	worldMap.refreshFromRunState()
	simulationManager.processTicks = true
	uiRoot.showGameplay()
	_setGameplayVisible(true)
	if OS.is_debug_build() and gameManager.getCurrentRunState() != null:
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.VeryFast,
		})


func _setGameplayVisible(isVisible: bool) -> void:
	worldRoot.visible = isVisible


func _quitGame() -> void:
	get_tree().quit()
