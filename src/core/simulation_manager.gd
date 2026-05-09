extends Node
class_name SimulationManager


func resetSimulation() -> void:
	# TODO: Reset simulation modules after core state types exist.
	pass


func stepSimulation(_deltaSeconds: float) -> void:
	# TODO: Advance fixed simulation ticks after TimeController is implemented.
	pass


func collectPendingEvents() -> Array[Dictionary]:
	# TODO: Return GameEvents after event data types are defined.
	return []
