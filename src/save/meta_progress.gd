extends RefCounted
class_name MetaProgress


const SCHEMA_VERSION: int = 1

var crowns: int = 0
var generalUpgrades: Dictionary = {}
var countryUpgrades: Dictionary = {}


func toDictionary() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"crowns": crowns,
		"generalUpgrades": generalUpgrades.duplicate(true),
		"countryUpgrades": countryUpgrades.duplicate(true),
	}


static func createDefaultData() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"crowns": 0,
		"generalUpgrades": {},
		"countryUpgrades": {},
	}


static func isValidDictionary(data: Dictionary) -> bool:
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return false
	if int(data.get("crowns", 0)) < 0:
		return false
	if not (data.get("generalUpgrades", {}) is Dictionary):
		return false
	if not (data.get("countryUpgrades", {}) is Dictionary):
		return false
	return true


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}
