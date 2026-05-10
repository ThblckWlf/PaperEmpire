extends RefCounted
class_name MetaProgressSimulation


const META_PROGRESS := preload("res://src/save/meta_progress.gd")

const BASE_CROWNS_FOR_RUN_END: int = 8
const CROWNS_PER_CONQUERED_COUNTRY: int = 4
const CROWNS_PER_CHOSEN_UPGRADE: int = 2
const CROWNS_FOR_WIN: int = 20
const CROWN_MULTIPLIER_EFFECT: String = "crownRewardMultiplier"


static func calculateCrownsReward(runState: RunState, metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	if runState == null:
		return {
			"accepted": false,
			"reason": "missing_run_state",
			"crowns": 0,
		}

	var conqueredCountries := _playerOwnedCountryCount(runState) - 1
	var chosenUpgrades := runState.upgrades.size()
	var crowns := BASE_CROWNS_FOR_RUN_END
	crowns += maxi(conqueredCountries, 0) * CROWNS_PER_CONQUERED_COUNTRY
	crowns += chosenUpgrades * CROWNS_PER_CHOSEN_UPGRADE
	if runState.runStatus == RunState.RUN_STATUS_WON:
		crowns += CROWNS_FOR_WIN

	var multiplier := 1.0 + _effectValue(metaProgressData, metaUpgradeRows, CROWN_MULTIPLIER_EFFECT)
	crowns = int(round(float(crowns) * multiplier))
	return {
		"accepted": true,
		"crowns": maxi(crowns, 0),
		"conqueredCountries": maxi(conqueredCountries, 0),
		"chosenUpgrades": chosenUpgrades,
		"runStatus": str(runState.runStatus),
	}


static func awardRunEndCrowns(metaProgressData: Dictionary, runState: RunState, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	var reward := calculateCrownsReward(runState, metaProgressData, metaUpgradeRows)
	if not bool(reward.get("accepted", false)):
		return reward

	var nextMeta := _normalizedMetaProgress(metaProgressData, metaUpgradeRows)
	nextMeta["crowns"] = int(nextMeta.get("crowns", 0)) + int(reward.get("crowns", 0))
	reward["metaProgress"] = nextMeta
	reward["totalCrowns"] = int(nextMeta.get("crowns", 0))
	return reward


static func purchaseUpgrade(metaProgressData: Dictionary, upgradeId: StringName, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	var nextMeta := _normalizedMetaProgress(metaProgressData, metaUpgradeRows)
	var definition := _definitionById(metaUpgradeRows, upgradeId)
	if definition.is_empty():
		return _purchaseRejected(upgradeId, "unknown_upgrade", nextMeta)

	var row := _upgradeStateRow(nextMeta, definition)
	if row.is_empty():
		return _purchaseRejected(upgradeId, "missing_upgrade_state", nextMeta)

	var level := int(row.get(META_PROGRESS.UPGRADE_LEVEL_KEY, 0))
	var maxLevel := int(row.get(META_PROGRESS.UPGRADE_MAX_LEVEL_KEY, 1))
	if level >= maxLevel:
		return _purchaseRejected(upgradeId, "max_level", nextMeta)

	var cost := upgradeCost(definition, level)
	var crowns := int(nextMeta.get("crowns", 0))
	if crowns < cost:
		return _purchaseRejected(upgradeId, "not_enough_crowns", nextMeta)

	row[META_PROGRESS.UPGRADE_LEVEL_KEY] = level + 1
	nextMeta["crowns"] = crowns - cost
	return {
		"accepted": true,
		"upgradeId": str(upgradeId),
		"scope": str(definition.get("scope", "")),
		"countryId": str(definition.get("countryId", "")),
		"cost": cost,
		"level": level + 1,
		"crowns": int(nextMeta.get("crowns", 0)),
		"metaProgress": nextMeta,
	}


static func applyStartingBonuses(runState: RunState, startCountryId: StringName, metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	var result := {
		"goldBonus": 0,
		"foodBonus": 0,
		"infantryBonus": 0,
	}
	if runState == null:
		return result

	var metaData := _normalizedMetaProgress(metaProgressData, metaUpgradeRows)
	for definition in metaUpgradeRows:
		var effectType := str(definition.get("effectType", ""))
		var scope := str(definition.get("scope", ""))
		if scope == "country" and StringName(str(definition.get("countryId", ""))) != startCountryId:
			continue

		var level := _upgradeLevel(metaData, definition)
		if level <= 0:
			continue

		var value := int(round(float(definition.get("valuePerLevel", 0)) * float(level)))
		match effectType:
			"startGoldBonus", "countryStartGoldBonus":
				runState.resources["gold"] = int(runState.resources.get("gold", 0)) + value
				result["goldBonus"] = int(result.get("goldBonus", 0)) + value
			"startFoodBonus", "countryStartFoodBonus":
				runState.resources["food"] = int(runState.resources.get("food", 0)) + value
				result["foodBonus"] = int(result.get("foodBonus", 0)) + value
			"countryStartArmyBonus":
				var army := runState.armies.get(&"army_start", null) as ArmyData
				if army != null:
					army.units[GameIds.INFANTRY_UNIT_ID] = int(army.units.get(GameIds.INFANTRY_UNIT_ID, 0)) + value
					result["infantryBonus"] = int(result.get("infantryBonus", 0)) + value
	return result


static func upgradeCost(definition: Dictionary, currentLevel: int) -> int:
	return int(definition.get("baseCost", 0)) + int(definition.get("costPerLevel", 0)) * currentLevel


static func createShopRows(metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var metaData := _normalizedMetaProgress(metaProgressData, metaUpgradeRows)
	for definition in metaUpgradeRows:
		var level := _upgradeLevel(metaData, definition)
		var maxLevel := int(definition.get("maxLevel", 1))
		var cost := upgradeCost(definition, level)
		rows.append({
			"id": str(definition.get("id", "")),
			"name": str(definition.get("name", "")),
			"description": str(definition.get("description", "")),
			"scope": str(definition.get("scope", "")),
			"countryId": str(definition.get("countryId", "")),
			"effectType": str(definition.get("effectType", "")),
			"level": level,
			"maxLevel": maxLevel,
			"cost": cost,
			"canPurchase": level < maxLevel and int(metaData.get("crowns", 0)) >= cost,
		})
	return rows


static func _normalizedMetaProgress(metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	if META_PROGRESS.isValidDictionary(metaProgressData, metaUpgradeRows):
		return metaProgressData.duplicate(true)
	return META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)


static func _definitionById(metaUpgradeRows: Array[Dictionary], upgradeId: StringName) -> Dictionary:
	for definition in metaUpgradeRows:
		if StringName(str(definition.get("id", ""))) == upgradeId:
			return definition
	return {}


static func _upgradeStateRow(metaProgressData: Dictionary, definition: Dictionary) -> Dictionary:
	var scope := str(definition.get("scope", ""))
	var upgradeId := str(definition.get("id", ""))
	if scope == "general":
		var generalUpgrades: Dictionary = metaProgressData.get("generalUpgrades", {})
		return generalUpgrades.get(upgradeId, {}) as Dictionary

	var countryUpgrades: Dictionary = metaProgressData.get("countryUpgrades", {})
	var countryState: Dictionary = countryUpgrades.get(str(definition.get("countryId", "")), {})
	return countryState.get(upgradeId, {}) as Dictionary


static func _upgradeLevel(metaProgressData: Dictionary, definition: Dictionary) -> int:
	var row := _upgradeStateRow(metaProgressData, definition)
	return int(row.get(META_PROGRESS.UPGRADE_LEVEL_KEY, 0))


static func _effectValue(metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary], effectType: String) -> float:
	var total := 0.0
	var metaData := _normalizedMetaProgress(metaProgressData, metaUpgradeRows)
	for definition in metaUpgradeRows:
		if str(definition.get("effectType", "")) != effectType:
			continue

		total += float(definition.get("valuePerLevel", 0.0)) * float(_upgradeLevel(metaData, definition))
	return total


static func _playerOwnedCountryCount(runState: RunState) -> int:
	var count := 0
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			count += 1
	return count


static func _purchaseRejected(upgradeId: StringName, reason: String, metaProgressData: Dictionary) -> Dictionary:
	return {
		"accepted": false,
		"upgradeId": str(upgradeId),
		"reason": reason,
		"metaProgress": metaProgressData,
		"crowns": int(metaProgressData.get("crowns", 0)),
	}
