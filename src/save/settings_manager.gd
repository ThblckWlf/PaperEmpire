extends Node
class_name SettingsManager


signal settingsChanged(settingsData: Dictionary)

const USER_SETTINGS := preload("res://src/save/user_settings.gd")
const SETTINGS_PATH: String = "user://paper_empire/settings.json"

var settingsData: Dictionary = USER_SETTINGS.createDefaultData()
var settingsPath: String = SETTINGS_PATH
var audioManager: AudioManager
var uiRoot: CanvasLayer


func configure(newAudioManager: AudioManager, newUiRoot: CanvasLayer) -> void:
	audioManager = newAudioManager
	uiRoot = newUiRoot
	applySettings()


func loadSettings() -> Dictionary:
	if not FileAccess.file_exists(settingsPath):
		settingsData = USER_SETTINGS.createDefaultData()
		return getSettingsData()

	var text := FileAccess.get_file_as_string(settingsPath)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		settingsData = USER_SETTINGS.createDefaultData()
		return getSettingsData()

	var parsedData := parsed as Dictionary
	if USER_SETTINGS.isValidDictionary(parsedData):
		settingsData = parsedData.duplicate(true)
	else:
		settingsData = USER_SETTINGS.sanitize(parsedData)
	return getSettingsData()


func saveSettings() -> bool:
	if not _ensureSaveDirectory():
		return false

	var file := FileAccess.open(settingsPath, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot open settings file for writing: %s" % settingsPath)
		return false

	file.store_string(JSON.stringify(settingsData, "\t"))
	file.close()
	return true


func updateSetting(key: StringName, value: Variant) -> void:
	settingsData = USER_SETTINGS.withValue(settingsData, key, value)
	applySettings()
	saveSettings()
	settingsChanged.emit(getSettingsData())


func getSettingsData() -> Dictionary:
	return settingsData.duplicate(true)


func setSettingsPathForDebug(path: String) -> void:
	settingsPath = path


func deleteSettings() -> bool:
	if not FileAccess.file_exists(settingsPath):
		return false
	return DirAccess.remove_absolute(settingsPath) == OK


func applySettings() -> void:
	if audioManager != null:
		audioManager.setMasterVolume(float(settingsData.get("masterVolume", 1.0)))
		audioManager.setMusicVolume(float(settingsData.get("musicVolume", 0.8)))
		audioManager.setSfxVolume(float(settingsData.get("sfxVolume", 0.8)))

	if uiRoot != null and uiRoot.has_method("setUiScale"):
		uiRoot.call("setUiScale", float(settingsData.get("uiScale", 1.0)))

	_applyWindowMode(str(settingsData.get("windowMode", USER_SETTINGS.WINDOW_MODE_WINDOWED)))


func _applyWindowMode(windowMode: String) -> void:
	if DisplayServer.get_name() == "headless":
		return

	if windowMode == USER_SETTINGS.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _ensureSaveDirectory() -> bool:
	var error := DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIRECTORY)
	if error != OK:
		push_warning("Cannot create settings directory: %s" % SaveManager.SAVE_DIRECTORY)
		return false
	return true
