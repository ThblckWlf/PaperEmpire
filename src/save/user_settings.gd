extends RefCounted
class_name UserSettings


const SCHEMA_VERSION: int = 1
const WINDOW_MODE_WINDOWED: String = "windowed"
const WINDOW_MODE_FULLSCREEN: String = "fullscreen"


static func createDefaultData() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"masterVolume": 1.0,
		"musicVolume": 0.8,
		"sfxVolume": 0.8,
		"uiScale": 1.0,
		"windowMode": WINDOW_MODE_WINDOWED,
	}


static func sanitize(data: Dictionary) -> Dictionary:
	var settings := createDefaultData()
	settings["masterVolume"] = clampf(float(data.get("masterVolume", settings["masterVolume"])), 0.0, 1.0)
	settings["musicVolume"] = clampf(float(data.get("musicVolume", settings["musicVolume"])), 0.0, 1.0)
	settings["sfxVolume"] = clampf(float(data.get("sfxVolume", settings["sfxVolume"])), 0.0, 1.0)
	settings["uiScale"] = clampf(float(data.get("uiScale", settings["uiScale"])), 0.8, 1.4)
	var windowMode := str(data.get("windowMode", settings["windowMode"]))
	if windowMode != WINDOW_MODE_FULLSCREEN:
		windowMode = WINDOW_MODE_WINDOWED
	settings["windowMode"] = windowMode
	return settings


static func withValue(data: Dictionary, key: StringName, value: Variant) -> Dictionary:
	var nextSettings := sanitize(data)
	match key:
		&"masterVolume", &"musicVolume", &"sfxVolume", &"uiScale", &"windowMode":
			nextSettings[str(key)] = value
		_:
			return nextSettings
	return sanitize(nextSettings)


static func isValidDictionary(data: Dictionary) -> bool:
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return false
	for key in ["masterVolume", "musicVolume", "sfxVolume"]:
		var value := float(data.get(key, -1.0))
		if value < 0.0 or value > 1.0:
			return false
	var uiScale := float(data.get("uiScale", -1.0))
	if uiScale < 0.8 or uiScale > 1.4:
		return false
	var windowMode := str(data.get("windowMode", ""))
	return windowMode == WINDOW_MODE_WINDOWED or windowMode == WINDOW_MODE_FULLSCREEN
