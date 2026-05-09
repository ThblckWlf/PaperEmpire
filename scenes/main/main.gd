extends Node


@onready var eventBus: EventBus = $GameRoot/Managers/EventBus as EventBus
@onready var gameManager: GameManager = $GameRoot/Managers/GameManager as GameManager
@onready var simulationManager: SimulationManager = $GameRoot/Managers/SimulationManager as SimulationManager


func _ready() -> void:
	eventBus.logGameEvents = OS.is_debug_build()
	gameManager.setEventBus(eventBus)
	gameManager.setSimulationManager(simulationManager)
	gameManager.startNewRun(str(NewRunFactory.DEFAULT_START_COUNTRY_ID))

	if OS.is_debug_build():
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.VeryFast,
		})
