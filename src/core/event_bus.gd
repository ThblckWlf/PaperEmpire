extends Node
class_name EventBus


signal commandRequested(commandName: StringName, payload: Dictionary)
signal gameEventRaised(eventName: StringName, payload: Dictionary)


func requestCommand(_commandName: StringName, _payload: Dictionary = {}) -> void:
	# TODO: Emit commandRequested after Step 2.3 defines signal routing rules.
	pass


func raiseGameEvent(_eventName: StringName, _payload: Dictionary = {}) -> void:
	# TODO: Emit gameEventRaised after core event types are defined.
	pass
