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
	return createDefaultDataForUpgrades([])


static func createDefaultDataForUpgrades(upgradeRows: Array[Dictionary]) -> Dictionary:
	var definitions := upgradeRows
	if definitions.is_empty():
		definitions = _fallbackUpgradeDefinitions()

	return {
		"schemaVersion": SCHEMA_VERSION,
		"crowns": 0,
		"generalUpgrades": createDefaultGeneralUpgradeState(definitions),
		"countryUpgrades": createDefaultCountryUpgradeState(definitions),
	}


static func generalUpgradeDefinitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for row in _fallbackUpgradeDefinitions():
		if str(row.get("scope", "")) == "general":
			definitions.append(row)
	return definitions


static func countryUpgradeDefinitions() -> Dictionary:
	var definitions := {}
	for row in _fallbackUpgradeDefinitions():
		if str(row.get("scope", "")) != "country":
			continue

		var countryId := str(row.get("countryId", ""))
		if not definitions.has(countryId):
			definitions[countryId] = []
		(definitions[countryId] as Array).append(row)
	return definitions


static func createDefaultGeneralUpgradeState(upgradeRows: Array[Dictionary] = []) -> Dictionary:
	var definitions := upgradeRows
	if definitions.is_empty():
		definitions = _fallbackUpgradeDefinitions()

	var state := {}
	for definition in definitions:
		if str(definition.get("scope", "")) != "general":
			continue
		state[str(definition.get("id", ""))] = _upgradeStateRow(definition)
	return state


static func createDefaultCountryUpgradeState(upgradeRows: Array[Dictionary] = []) -> Dictionary:
	var definitions := upgradeRows
	if definitions.is_empty():
		definitions = _fallbackUpgradeDefinitions()

	var state := {}
	for definition in definitions:
		if str(definition.get("scope", "")) != "country":
			continue

		var countryId := str(definition.get("countryId", ""))
		if countryId == "":
			continue
		if not state.has(countryId):
			state[countryId] = {}
		var countryState := state[countryId] as Dictionary
		countryState[str(definition.get("id", ""))] = _upgradeStateRow(definition)
	return state


static func isValidDictionary(data: Dictionary, upgradeRows: Array[Dictionary] = []) -> bool:
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return false
	if int(data.get("crowns", 0)) < 0:
		return false

	var definitions := upgradeRows
	if definitions.is_empty():
		definitions = _fallbackUpgradeDefinitions()

	var generalState: Variant = data.get("generalUpgrades", {})
	if not (generalState is Dictionary):
		return false
	if not _isValidGeneralUpgradeState(generalState as Dictionary, definitions):
		return false
	var countryState: Variant = data.get("countryUpgrades", {})
	if not (countryState is Dictionary):
		return false
	if not _isValidCountryUpgradeState(countryState as Dictionary, definitions):
		return false
	return true


static func _fallbackUpgradeDefinitions() -> Array[Dictionary]:
	return [
		{
			"id": "startGold",
			"scope": "general",
			"name": "Starting Treasury",
			"description": "Adds gold at the start of future runs.",
			"maxLevel": 3,
			"baseCost": 20,
			"costPerLevel": 15,
			"effectType": "startGoldBonus",
			"valuePerLevel": 50,
		},
		{
			"id": "startFood",
			"scope": "general",
			"name": "Stored Rations",
			"description": "Adds food at the start of future runs.",
			"maxLevel": 3,
			"baseCost": 18,
			"costPerLevel": 12,
			"effectType": "startFoodBonus",
			"valuePerLevel": 30,
		},
		{
			"id": "bonusCrowns",
			"scope": "general",
			"name": "Royal Accountants",
			"description": "Improves future crown rewards.",
			"maxLevel": 2,
			"baseCost": 30,
			"costPerLevel": 20,
			"effectType": "crownRewardMultiplier",
			"valuePerLevel": 0.05,
		},
		{
			"id": "paperlandDiscipline",
			"scope": "country",
			"countryId": "paperland",
			"name": "Paperland Discipline",
			"description": "Paperland starts future runs with better drilled troops.",
			"maxLevel": 2,
			"baseCost": 22,
			"costPerLevel": 16,
			"effectType": "countryStartArmyBonus",
			"valuePerLevel": 1,
		},
		{
			"id": "inkreichTreasury",
			"scope": "country",
			"countryId": "inkreich",
			"name": "Inkreich Treasury",
			"description": "Inkreich starts future runs with extra gold.",
			"maxLevel": 2,
			"baseCost": 22,
			"costPerLevel": 16,
			"effectType": "countryStartGoldBonus",
			"valuePerLevel": 40,
		},
		{
			"id": "foldmarkGranaries",
			"scope": "country",
			"countryId": "foldmark",
			"name": "Foldmark Granaries",
			"description": "Foldmark starts future runs with extra food.",
			"maxLevel": 2,
			"baseCost": 20,
			"costPerLevel": 14,
			"effectType": "countryStartFoodBonus",
			"valuePerLevel": 25,
		},
	]


static func _upgradeStateRow(definition: Dictionary) -> Dictionary:
	return {
		UPGRADE_LEVEL_KEY: 0,
		UPGRADE_MAX_LEVEL_KEY: int(definition.get("maxLevel", 1)),
	}


static func _isValidGeneralUpgradeState(state: Dictionary, definitions: Array[Dictionary]) -> bool:
	var generalDefinitions: Array[Dictionary] = []
	for definition in definitions:
		if str(definition.get("scope", "")) == "general":
			generalDefinitions.append(definition)
	return _isValidUpgradeStateForDefinitions(state, generalDefinitions)


static func _isValidCountryUpgradeState(state: Dictionary, definitions: Array[Dictionary]) -> bool:
	var definitionsByCountry := {}
	for definition in definitions:
		if str(definition.get("scope", "")) != "country":
			continue

		var countryId := str(definition.get("countryId", ""))
		if not definitionsByCountry.has(countryId):
			definitionsByCountry[countryId] = []
		(definitionsByCountry[countryId] as Array).append(definition)

	for countryId in definitionsByCountry.keys():
		var countryIdString := str(countryId)
		if not state.has(countryIdString):
			return false
		var countryState = state.get(countryIdString, {})
		if not (countryState is Dictionary):
			return false
		var countryDefinitions: Array[Dictionary] = []
		for definition in definitionsByCountry[countryId]:
			if definition is Dictionary:
				countryDefinitions.append(definition as Dictionary)
		if not _isValidUpgradeStateForDefinitions(countryState as Dictionary, countryDefinitions):
			return false
	return true


static func _isValidUpgradeStateForDefinitions(state: Dictionary, definitions: Array[Dictionary]) -> bool:
	for definition in definitions:
		var upgradeId := str(definition.get("id", ""))
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
		var expectedMaxLevel := int(definition.get("maxLevel", 1))
		if maxLevel != expectedMaxLevel:
			return false
		if level < 0 or level > maxLevel:
			return false
	return true


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}
