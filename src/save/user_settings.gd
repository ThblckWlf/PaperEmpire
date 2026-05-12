extends RefCounted
class_name UserSettings


const SCHEMA_VERSION: int = 2
const WINDOW_MODE_WINDOWED: String = "windowed"
const WINDOW_MODE_FULLSCREEN: String = "fullscreen"
const WINDOW_MODE_BORDERLESS: String = "borderless"

const RESOLUTION_NATIVE: String = "native"
const ALLOWED_RESOLUTIONS: Array[String] = [
	"1280x720",
	"1600x900",
	"1920x1080",
	"2560x1440",
	RESOLUTION_NATIVE,
]

const UI_SCALE_MIN: float = 0.8
const UI_SCALE_MAX: float = 1.6
const UI_SCALE_DEFAULT: float = 1.2
const DEFAULT_RESOLUTION: String = "1920x1080"


static func createDefaultData() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"masterVolume": 1.0,
		"musicVolume": 0.8,
		"sfxVolume": 0.8,
		"uiScale": UI_SCALE_DEFAULT,
		"windowMode": WINDOW_MODE_WINDOWED,
		"resolution": DEFAULT_RESOLUTION,
	}


static func sanitize(data: Dictionary) -> Dictionary:
	var settings := createDefaultData()
	settings["masterVolume"] = clampf(float(data.get("masterVolume", settings["masterVolume"])), 0.0, 1.0)
	settings["musicVolume"] = clampf(float(data.get("musicVolume", settings["musicVolume"])), 0.0, 1.0)
	settings["sfxVolume"] = clampf(float(data.get("sfxVolume", settings["sfxVolume"])), 0.0, 1.0)
	settings["uiScale"] = clampf(float(data.get("uiScale", settings["uiScale"])), UI_SCALE_MIN, UI_SCALE_MAX)
	var windowMode := str(data.get("windowMode", settings["windowMode"]))
	if windowMode != WINDOW_MODE_FULLSCREEN and windowMode != WINDOW_MODE_BORDERLESS:
		windowMode = WINDOW_MODE_WINDOWED
	settings["windowMode"] = windowMode
	var resolution := str(data.get("resolution", settings["resolution"]))
	if not ALLOWED_RESOLUTIONS.has(resolution):
		resolution = DEFAULT_RESOLUTION
	settings["resolution"] = resolution
	return settings


static func withValue(data: Dictionary, key: StringName, value: Variant) -> Dictionary:
	var nextSettings := sanitize(data)
	match key:
		&"masterVolume", &"musicVolume", &"sfxVolume", &"uiScale", &"windowMode", &"resolution":
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
	if uiScale < UI_SCALE_MIN or uiScale > UI_SCALE_MAX:
		return false
	var windowMode := str(data.get("windowMode", ""))
	if windowMode != WINDOW_MODE_WINDOWED and windowMode != WINDOW_MODE_FULLSCREEN and windowMode != WINDOW_MODE_BORDERLESS:
		return false
	if not ALLOWED_RESOLUTIONS.has(str(data.get("resolution", ""))):
		return false
	return true
