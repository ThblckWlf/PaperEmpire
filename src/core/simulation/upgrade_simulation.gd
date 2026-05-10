extends RefCounted
class_name UpgradeSimulation


const CHOICE_COUNT: int = 3
const CONQUEST_GOLD_BASE: int = 40
const WAR_THREAT_BASE: int = 4

const RECRUITMENT_COST_MULTIPLIER: String = "recruitmentCostMultiplier"
const FOOD_UPKEEP_MULTIPLIER: String = "foodUpkeepMultiplier"
const CONQUEST_GOLD_MULTIPLIER: String = "conquestGoldMultiplier"
const WAR_THREAT_MULTIPLIER: String = "warThreatMultiplier"
const DEFENSE_COMBAT_MULTIPLIER: String = "defenseCombatMultiplier"


static func supportedEffectTypes() -> Dictionary:
	return {
		RECRUITMENT_COST_MULTIPLIER: true,
		FOOD_UPKEEP_MULTIPLIER: true,
		CONQUEST_GOLD_MULTIPLIER: true,
		WAR_THREAT_MULTIPLIER: true,
		DEFENSE_COMBAT_MULTIPLIER: true,
	}


static func rollUpgradeChoices(runState: RunState, upgrades: Array[Dictionary]) -> Dictionary:
	var result := {
		"opened": false,
		"choices": [],
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if hasActiveChoice(runState):
		result["reason"] = "choice_already_open"
		result["choices"] = runState.activeUpgradeChoice.get("choices", [])
		return result

	var candidates := _eligibleUpgrades(runState, upgrades)
	if candidates.size() < CHOICE_COUNT:
		result["reason"] = "not_enough_upgrades"
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = _choiceSeed(runState)
	var choices: Array[Dictionary] = []
	while choices.size() < CHOICE_COUNT and not candidates.is_empty():
		var index := rng.randi_range(0, candidates.size() - 1)
		choices.append(candidates[index])
		candidates.remove_at(index)

	runState.activeUpgradeChoice = {
		"isOpen": true,
		"choices": choices,
	}
	result["opened"] = true
	result["choices"] = choices
	return result


static func applyUpgradeChoice(runState: RunState, upgradeId: StringName) -> Dictionary:
	var result := {
		"accepted": false,
		"upgradeId": upgradeId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not hasActiveChoice(runState):
		result["reason"] = "no_active_choice"
		return result

	var upgrade := _choiceById(runState.activeUpgradeChoice.get("choices", []), upgradeId)
	if upgrade.is_empty():
		result["reason"] = "upgrade_not_in_choice"
		return result

	if runState.upgrades.has(upgradeId):
		result["reason"] = "upgrade_already_applied"
		return result

	var effectType := str(upgrade.get("effectType", ""))
	var value := float(upgrade.get("value", 1.0))
	if not supportedEffectTypes().has(effectType):
		result["reason"] = "unsupported_effect_type"
		return result

	runState.upgrades.append(upgradeId)
	runState.upgradeEffects[effectType] = float(runState.upgradeEffects.get(effectType, 1.0)) * value
	runState.activeUpgradeChoice = {}

	result["accepted"] = true
	result["upgrade"] = upgrade
	result["effectType"] = effectType
	result["value"] = value
	result["upgradeEffects"] = runState.upgradeEffects.duplicate()
	return result


static func applyWarThreat(runState: RunState) -> Dictionary:
	var result := {
		"threatAdded": 0,
		"threat": 0,
	}
	if runState == null:
		return result

	var multiplier := float(runState.upgradeEffects.get(WAR_THREAT_MULTIPLIER, 1.0))
	var threatAdded := maxi(1, int(round(float(WAR_THREAT_BASE) * multiplier)))
	runState.resources["threat"] = int(runState.resources.get("threat", 0)) + threatAdded
	result["threatAdded"] = threatAdded
	result["threat"] = int(runState.resources.get("threat", 0))
	return result


static func applyConquestReward(runState: RunState, countryId: StringName) -> Dictionary:
	var result := {
		"goldReward": 0,
		"gold": 0,
	}
	if runState == null:
		return result

	var country := runState.countries.get(countryId, null) as CountryData
	var baseReward := CONQUEST_GOLD_BASE
	if country != null:
		baseReward += country.goldPerMonth

	var multiplier := float(runState.upgradeEffects.get(CONQUEST_GOLD_MULTIPLIER, 1.0))
	var goldReward := maxi(0, int(round(float(baseReward) * multiplier)))
	runState.resources["gold"] = int(runState.resources.get("gold", 0)) + goldReward
	result["goldReward"] = goldReward
	result["gold"] = int(runState.resources.get("gold", 0))
	return result


static func hasActiveChoice(runState: RunState) -> bool:
	return runState != null and bool(runState.activeUpgradeChoice.get("isOpen", false))


static func _eligibleUpgrades(runState: RunState, upgrades: Array[Dictionary]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var supported := supportedEffectTypes()
	for upgrade in upgrades:
		var upgradeId := StringName(str(upgrade.get("id", "")))
		if upgradeId == GameIds.EMPTY_ID or runState.upgrades.has(upgradeId):
			continue

		if not supported.has(str(upgrade.get("effectType", ""))):
			continue

		candidates.append(upgrade)
	return candidates


static func _choiceById(choices: Array, upgradeId: StringName) -> Dictionary:
	for choice in choices:
		if not (choice is Dictionary):
			continue

		var upgrade := choice as Dictionary
		if StringName(str(upgrade.get("id", ""))) == upgradeId:
			return upgrade
	return {}


static func _choiceSeed(runState: RunState) -> int:
	var ownedCountries := 0
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			ownedCountries += 1

	return int(GameTime.getElapsedSeconds(runState.time) * 1000.0) + ownedCountries * 7919 + runState.upgrades.size() * 104729
