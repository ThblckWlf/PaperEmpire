extends Node
class_name SaveManager


const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const SAVE_SCHEMA_VERSION: int = SAVE_FORMAT.SCHEMA_VERSION
const SAVE_DIRECTORY: String = "user://paper_empire"
const SAVE_EXTENSION: String = ".json"
const META_SLOT_ID: String = "meta"


func saveGame(slotId: String, state: Dictionary) -> bool:
	if not SAVE_FORMAT.isValidSaveRoot(state):
		push_warning("Cannot save invalid save root.")
		return false

	var savePath := getSavePath(slotId)
	if savePath == "":
		return false

	if not _ensureSaveDirectory():
		return false

	var file := FileAccess.open(savePath, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot open save file for writing: %s" % savePath)
		return false

	file.store_string(JSON.stringify(state, "\t"))
	file.close()
	return true


func loadGame(slotId: String) -> Dictionary:
	var savePath := getSavePath(slotId)
	if savePath == "" or not FileAccess.file_exists(savePath):
		return {}

	var text := FileAccess.get_file_as_string(savePath)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Save file is not a JSON object: %s" % savePath)
		return {}

	var data := parsed as Dictionary
	if not SAVE_FORMAT.isValidSaveRoot(data):
		push_warning("Save file failed schema validation: %s" % savePath)
		return {}

	return data


func hasSave(slotId: String) -> bool:
	var savePath := getSavePath(slotId)
	return savePath != "" and FileAccess.file_exists(savePath)


func deleteSave(slotId: String) -> bool:
	var savePath := getSavePath(slotId)
	if savePath == "" or not FileAccess.file_exists(savePath):
		return false

	return DirAccess.remove_absolute(savePath) == OK


func saveMetaProgress(metaProgressData: Dictionary) -> bool:
	var root: Dictionary = SAVE_FORMAT.createSaveRoot(SAVE_FORMAT.createEmptyRunStateData(), metaProgressData)
	return saveGame(META_SLOT_ID, root)


func loadMetaProgress() -> Dictionary:
	var root := loadGame(META_SLOT_ID)
	if root.is_empty():
		return {}
	return root.get(SAVE_FORMAT.META_PROGRESS_KEY, {}) as Dictionary


func hasMetaProgress() -> bool:
	return hasSave(META_SLOT_ID)


func deleteMetaProgress() -> bool:
	return deleteSave(META_SLOT_ID)


func getSavePath(slotId: String) -> String:
	var safeSlotId := _safeSlotId(slotId)
	if safeSlotId == "":
		return ""
	return "%s/%s%s" % [SAVE_DIRECTORY, safeSlotId, SAVE_EXTENSION]


func _ensureSaveDirectory() -> bool:
	var error := DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	if error != OK:
		push_warning("Cannot create save directory: %s" % SAVE_DIRECTORY)
		return false
	return true


func _safeSlotId(slotId: String) -> String:
	var trimmedSlotId := slotId.strip_edges()
	if trimmedSlotId == "":
		push_warning("Save slot id cannot be empty.")
		return ""

	var safe := ""
	for index in range(trimmedSlotId.length()):
		var character := trimmedSlotId.substr(index, 1)
		if character.is_valid_identifier() or character.is_valid_int() or character == "-":
			safe += character
		else:
			safe += "_"

	return safe
