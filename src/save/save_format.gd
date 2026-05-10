extends RefCounted
class_name SaveFormat


const SCHEMA_VERSION: int = 1
const GAME_VERSION: String = "0.1.0"
const RUN_STATE_KEY: String = "runState"
const META_PROGRESS_KEY: String = "metaProgress"
const META_PROGRESS := preload("res://src/save/meta_progress.gd")


static func createSaveRoot(runStateData: Dictionary = {}, metaProgressData: Dictionary = {}) -> Dictionary:
	var metaData := metaProgressData
	if metaData.is_empty():
		metaData = META_PROGRESS.createDefaultData()

	return {
		"schemaVersion": SCHEMA_VERSION,
		"gameVersion": GAME_VERSION,
		"createdAt": Time.get_datetime_string_from_system(true),
		RUN_STATE_KEY: runStateData.duplicate(true),
		META_PROGRESS_KEY: metaData.duplicate(true),
	}


static func createEmptyRunStateData() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
	}


static func createRunSaveRoot(runStateData: Dictionary, metaProgressData: Dictionary = {}) -> Dictionary:
	var root := createSaveRoot(runStateData, metaProgressData)
	root[RUN_STATE_KEY] = runStateData.duplicate(true)
	return root


static func isValidSaveRoot(data: Dictionary) -> bool:
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return false
	if str(data.get("gameVersion", "")) == "":
		return false
	if str(data.get("createdAt", "")) == "":
		return false
	if not (data.get(RUN_STATE_KEY, {}) is Dictionary):
		return false
	if not (data.get(META_PROGRESS_KEY, {}) is Dictionary):
		return false

	var metaProgressData := data.get(META_PROGRESS_KEY, {}) as Dictionary
	return META_PROGRESS.isValidDictionary(metaProgressData)


static func needsMigration(data: Dictionary) -> bool:
	var version := int(data.get("schemaVersion", 0))
	return version > 0 and version < SCHEMA_VERSION
