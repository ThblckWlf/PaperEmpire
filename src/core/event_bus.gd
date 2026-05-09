extends Node
class_name EventBus


signal commandRequested(commandName: StringName, payload: Dictionary)
signal gameEventRaised(eventName: StringName, payload: Dictionary)


func requestCommand(commandName: StringName, payload: Dictionary = {}) -> void:
	commandRequested.emit(commandName, payload)


func raiseGameEvent(eventName: StringName, payload: Dictionary = {}) -> void:
	gameEventRaised.emit(eventName, payload)
