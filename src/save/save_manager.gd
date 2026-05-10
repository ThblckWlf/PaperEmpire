extends Node
class_name SaveManager


const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const SAVE_SCHEMA_VERSION: int = SAVE_FORMAT.SCHEMA_VERSION


func saveGame(_slotId: String, _state: Dictionary) -> bool:
	# TODO: Serialize validated save data to user:// after save schemas exist.
	return false


func loadGame(_slotId: String) -> Dictionary:
	# TODO: Load and migrate save data after save schemas exist.
	return {}


func hasSave(_slotId: String) -> bool:
	# TODO: Check user:// save slots after save path rules are defined.
	return false
