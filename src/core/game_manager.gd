extends Node
class_name GameManager


func startNewRun(_startCountryId: String) -> void:
	# TODO: Create the initial run state after core data models exist.
	pass


func submitCommand(_commandName: StringName, _payload: Dictionary = {}) -> void:
	# TODO: Route commands to simulation modules after CommandBus is defined.
	pass


func getCurrentRunState() -> Dictionary:
	# TODO: Return a readonly state snapshot after GameState is defined.
	return {}
