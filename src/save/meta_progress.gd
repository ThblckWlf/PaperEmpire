extends RefCounted
class_name MetaProgress


const SCHEMA_VERSION: int = 1
const UPGRADE_LEVEL_KEY: String = "level"
const UPGRADE_MAX_LEVEL_KEY: String = "maxLevel"

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
		"generalUpgrades": createDefaultGeneralUpgradeState(),
		"countryUpgrades": createDefaultCountryUpgradeState(),
	}


static func generalUpgradeDefinitions() -> Array[Dictionary]:
	return [
		{
			"id": "startGold",
			"name": "Starting Treasury",
			"description": "Adds gold at the start of future runs.",
			"maxLevel": 3,
			"effectType": "startGoldBonus",
			"valuePerLevel": 50,
		},
		{
			"id": "startFood",
			"name": "Stored Rations",
			"description": "Adds food at the start of future runs.",
			"maxLevel": 3,
			"effectType": "startFoodBonus",
			"valuePerLevel": 30,
		},
		{
			"id": "bonusCrowns",
			"name": "Royal Accountants",
			"description": "Improves future crown rewards.",
			"maxLevel": 2,
			"effectType": "crownRewardMultiplier",
			"valuePerLevel": 0.05,
		},
	]


static func countryUpgradeDefinitions() -> Dictionary:
	return {
		"paperland": [
			{
				"id": "paperlandDiscipline",
				"name": "Paperland Discipline",
				"description": "Paperland starts future runs with better drilled troops.",
				"maxLevel": 2,
				"effectType": "countryStartArmyBonus",
				"valuePerLevel": 1,
			},
		],
		"inkreich": [
			{
				"id": "inkreichTreasury",
				"name": "Inkreich Treasury",
				"description": "Inkreich starts future runs with extra gold.",
				"maxLevel": 2,
				"effectType": "countryStartGoldBonus",
				"valuePerLevel": 40,
			},
		],
		"foldmark": [
			{
				"id": "foldmarkGranaries",
				"name": "Foldmark Granaries",
				"description": "Foldmark starts future runs with extra food.",
				"maxLevel": 2,
				"effectType": "countryStartFoodBonus",
				"valuePerLevel": 25,
			},
		],
	}


static func createDefaultGeneralUpgradeState() -> Dictionary:
	var state := {}
	for definition in generalUpgradeDefinitions():
		state[str(definition.get("id", ""))] = _upgradeStateRow(definition)
	return state


static func createDefaultCountryUpgradeState() -> Dictionary:
	var state := {}
	var definitions := countryUpgradeDefinitions()
	var countryIds := definitions.keys()
	countryIds.sort()
	for countryId in countryIds:
		var countryState := {}
		for definition in definitions[countryId] as Array:
			countryState[str((definition as Dictionary).get("id", ""))] = _upgradeStateRow(definition as Dictionary)
		state[str(countryId)] = countryState
	return state


static func isValidDictionary(data: Dictionary) -> bool:
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return false
	if int(data.get("crowns", 0)) < 0:
		return false
	var generalState: Variant = data.get("generalUpgrades", {})
	if not (generalState is Dictionary):
		return false
	if not _isValidGeneralUpgradeState(generalState as Dictionary):
		return false
	var countryState: Variant = data.get("countryUpgrades", {})
	if not (countryState is Dictionary):
		return false
	if not _isValidCountryUpgradeState(countryState as Dictionary):
		return false
	return true


static func _upgradeStateRow(definition: Dictionary) -> Dictionary:
	return {
		UPGRADE_LEVEL_KEY: 0,
		UPGRADE_MAX_LEVEL_KEY: int(definition.get("maxLevel", 1)),
	}


static func _isValidGeneralUpgradeState(state: Dictionary) -> bool:
	return _isValidUpgradeStateForDefinitions(state, generalUpgradeDefinitions())


static func _isValidCountryUpgradeState(state: Dictionary) -> bool:
	var definitions := countryUpgradeDefinitions()
	for countryId in definitions.keys():
		if not state.has(str(countryId)):
			return false
		var countryState = state.get(str(countryId), {})
		if not (countryState is Dictionary):
			return false
		if not _isValidUpgradeStateForDefinitions(countryState as Dictionary, definitions[countryId] as Array):
			return false
	return true


static func _isValidUpgradeStateForDefinitions(state: Dictionary, definitions: Array) -> bool:
	for definition in definitions:
		if not (definition is Dictionary):
			return false

		var definitionData := definition as Dictionary
		var upgradeId := str(definitionData.get("id", ""))
		if upgradeId == "":
			return false
		if not state.has(upgradeId):
			return false

		var row = state.get(upgradeId, {})
		if not (row is Dictionary):
			return false

		var rowData := row as Dictionary
		var level := int(rowData.get(UPGRADE_LEVEL_KEY, -1))
		var maxLevel := int(rowData.get(UPGRADE_MAX_LEVEL_KEY, 0))
		var expectedMaxLevel := int(definitionData.get("maxLevel", 1))
		if maxLevel != expectedMaxLevel:
			return false
		if level < 0 or level > maxLevel:
			return false
	return true


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}
