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
		uiRoot.call("setUiScale", float(settingsData.get("uiScale", USER_SETTINGS.UI_SCALE_DEFAULT)))

	_applyWindowAndResolution(
		str(settingsData.get("windowMode", USER_SETTINGS.WINDOW_MODE_WINDOWED)),
		str(settingsData.get("resolution", USER_SETTINGS.DEFAULT_RESOLUTION))
	)


func _applyWindowAndResolution(windowMode: String, resolution: String) -> void:
	if DisplayServer.get_name() == "headless":
		return

	match windowMode:
		USER_SETTINGS.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		USER_SETTINGS.WINDOW_MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			# Defer so the mode/flag change is applied before resizing the window.
			call_deferred("_applyWindowSize", DisplayServer.screen_get_size())
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var targetSize := _resolveResolution(resolution)
			if targetSize != Vector2i.ZERO:
				call_deferred("_applyWindowSize", targetSize)


func _resolveResolution(resolution: String) -> Vector2i:
	if resolution == USER_SETTINGS.RESOLUTION_NATIVE:
		return DisplayServer.screen_get_size()
	var parts := resolution.split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	var width := int(parts[0])
	var height := int(parts[1])
	if width <= 0 or height <= 0:
		return Vector2i.ZERO
	return Vector2i(width, height)


func _applyWindowSize(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	var screenSize := DisplayServer.screen_get_size()
	var screenOrigin := DisplayServer.screen_get_position()
	var topLeft := screenOrigin + ((screenSize - size) / 2)
	DisplayServer.window_set_position(topLeft)


func _ensureSaveDirectory() -> bool:
	var error := DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIRECTORY)
	if error != OK:
		push_warning("Cannot create settings directory: %s" % SaveManager.SAVE_DIRECTORY)
		return false
	return true
