extends Node


const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://src/save/settings_manager.gd")

@onready var eventBus: EventBus = $GameRoot/Managers/EventBus as EventBus
@onready var managersNode: Node = $GameRoot/Managers as Node
@onready var gameManager: GameManager = $GameRoot/Managers/GameManager as GameManager
@onready var simulationManager: SimulationManager = $GameRoot/Managers/SimulationManager as SimulationManager
@onready var audioManager: AudioManager = $GameRoot/Managers/AudioManager as AudioManager
@onready var worldMap = $GameRoot/WorldRoot/WorldMap
@onready var uiRoot = $GameRoot/UIRoot


func _ready() -> void:
	INPUT_ACTIONS.ensureDefaultActions()
	var saveManager := _createSaveManager()
	var settingsManager := _createSettingsManager()
	eventBus.logGameEvents = OS.is_debug_build()
	gameManager.setEventBus(eventBus)
	gameManager.setSimulationManager(simulationManager)
	gameManager.setSaveManager(saveManager)
	gameManager.startNewRun(str(NewRunFactory.DEFAULT_START_COUNTRY_ID))
	worldMap.configure(gameManager, eventBus, audioManager)
	audioManager.configure(eventBus)
	settingsManager.loadSettings()
	uiRoot.configure(gameManager, eventBus, settingsManager)
	settingsManager.configure(audioManager, uiRoot)

	if OS.is_debug_build():
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.VeryFast,
		})


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
