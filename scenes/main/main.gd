extends Node


@onready var eventBus: EventBus = $GameRoot/Managers/EventBus as EventBus
@onready var gameManager: GameManager = $GameRoot/Managers/GameManager as GameManager
@onready var simulationManager: SimulationManager = $GameRoot/Managers/SimulationManager as SimulationManager
@onready var audioManager: AudioManager = $GameRoot/Managers/AudioManager as AudioManager
@onready var worldMap = $GameRoot/WorldRoot/WorldMap
@onready var uiRoot = $GameRoot/UIRoot


func _ready() -> void:
	eventBus.logGameEvents = OS.is_debug_build()
	gameManager.setEventBus(eventBus)
	gameManager.setSimulationManager(simulationManager)
	gameManager.startNewRun(str(NewRunFactory.DEFAULT_START_COUNTRY_ID))
	worldMap.configure(gameManager, eventBus, audioManager)
	uiRoot.configure(gameManager, eventBus)

	if OS.is_debug_build():
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.VeryFast,
		})

	audioManager.configure(eventBus)
