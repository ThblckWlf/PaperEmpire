extends Node
class_name EventBus


signal commandRequested(commandName: StringName, payload: Dictionary)
signal gameEventRaised(eventName: StringName, payload: Dictionary)
signal debugErrorReported(message: String)

var logGameEvents: bool = false


func requestCommand(commandName: StringName, payload: Dictionary = {}) -> void:
	commandRequested.emit(commandName, payload)


func raiseGameEvent(eventName: StringName, payload: Dictionary = {}) -> void:
	gameEventRaised.emit(eventName, payload)


func reportDebugError(message: String) -> void:
	debugErrorReported.emit(message)


func raiseEvent(gameEvent: GameEvent) -> void:
	if logGameEvents:
		print("[EventBus] %s %s" % [gameEvent.type, gameEvent.payload])

	raiseGameEvent(gameEvent.type, gameEvent.payload)
