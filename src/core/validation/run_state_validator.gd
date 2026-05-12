extends RefCounted
class_name RunStateValidator


const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")


static func validate(runState: RunState) -> ValidationResult:
	var result := ValidationResult.new()
	_validateTime(runState.time, result)
	_validateResources(runState.resources, result)
	_validateWorldReaction(runState.worldReaction, result)
	_validateEconomy(runState.economy, result)
	_validateAiGold(runState.aiGoldByCountry, result)
	_validateUpgrades(runState, result)
	_validateMiniGoalState(runState, result)
	_validateRunStats(runState.runStats, result)
	_validateSpeed(runState.speed, result)
	_validateArmyLocations(runState, result)
	_validateBattles(runState, result)
	return result


static func _validateTime(time: Dictionary, result: ValidationResult) -> void:
	var elapsedSeconds = time.get("elapsedSeconds", 0.0)
	if not _isNumeric(elapsedSeconds):
		result.addError("RunState time elapsedSeconds is not numeric.")
	elif is_nan(float(elapsedSeconds)):
		result.addError("RunState time elapsedSeconds is NaN.")
	elif float(elapsedSeconds) < 0.0:
		result.addError("RunState time elapsedSeconds is negative.")

	var week := int(time.get("week", 0))
	if week < 1 or week > GameTime.WEEKS_PER_MONTH:
		result.addError("RunState time week is out of range: %s." % week)

	var month := int(time.get("month", 0))
	if month < 1 or month > GameTime.MONTHS_PER_YEAR:
		result.addError("RunState time month is out of range: %s." % month)

	var year := int(time.get("year", 0))
	if year < 1:
		result.addError("RunState time year is out of range: %s." % year)


static func _validateResources(resources: Dictionary, result: ValidationResult) -> void:
	for key in ["gold", "food", "threat"]:
		if not resources.has(key):
			result.addError("RunState resources missing key: %s." % key)
			continue

		var value = resources[key]
		var valueType := typeof(value)
		if valueType != TYPE_INT and valueType != TYPE_FLOAT:
			result.addError("RunState resource %s is not numeric." % key)
			continue

		if valueType == TYPE_FLOAT and is_nan(float(value)):
			result.addError("RunState resource %s is NaN." % key)


static func _validateWorldReaction(worldReaction: Dictionary, result: ValidationResult) -> void:
	for key in ["level", "enemyStrengthMultiplier", "counterAttackPrepared", "lastThreat"]:
		if not worldReaction.has(key):
			result.addError("RunState worldReaction missing key: %s." % key)

	if typeof(worldReaction.get("level", "")) != TYPE_STRING:
		result.addError("RunState worldReaction level is not a string.")

	var multiplier = worldReaction.get("enemyStrengthMultiplier", 1.0)
	if not _isNumeric(multiplier):
		result.addError("RunState worldReaction enemyStrengthMultiplier is not numeric.")
	elif float(multiplier) <= 0.0 or is_nan(float(multiplier)):
		result.addError("RunState worldReaction enemyStrengthMultiplier must be positive.")

	if typeof(worldReaction.get("counterAttackPrepared", false)) != TYPE_BOOL:
		result.addError("RunState worldReaction counterAttackPrepared is not bool.")

	var lastThreat = worldReaction.get("lastThreat", 0)
	if not _isNumeric(lastThreat):
		result.addError("RunState worldReaction lastThreat is not numeric.")
	elif int(lastThreat) < 0:
		result.addError("RunState worldReaction lastThreat is negative.")


static func _validateEconomy(economy: Dictionary, result: ValidationResult) -> void:
	for key in ["isFoodShortage", "recruitmentBlocked", "healingBlocked"]:
		if not economy.has(key):
			result.addError("RunState economy missing key: %s." % key)
		elif typeof(economy[key]) != TYPE_BOOL:
			result.addError("RunState economy %s is not bool." % key)

	var shortageMonths = economy.get("foodShortageMonths", 0)
	if not _isNumeric(shortageMonths):
		result.addError("RunState economy foodShortageMonths is not numeric.")
	elif int(shortageMonths) < 0:
		result.addError("RunState economy foodShortageMonths is negative.")

	var combatPowerMultiplier = economy.get("combatPowerMultiplier", 1.0)
	if not _isNumeric(combatPowerMultiplier):
		result.addError("RunState economy combatPowerMultiplier is not numeric.")
	elif float(combatPowerMultiplier) <= 0.0:
		result.addError("RunState economy combatPowerMultiplier is not positive.")


static func _validateSpeed(speed: int, result: ValidationResult) -> void:
	var validSpeeds := [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	]

	if not validSpeeds.has(speed):
		result.addError("RunState speed is invalid: %s." % speed)


static func _validateArmyLocations(runState: RunState, result: ValidationResult) -> void:
	for armyId in runState.armies.keys():
		var army = runState.armies[armyId]
		if not (army is ArmyData):
			result.addError("RunState army %s is not ArmyData." % armyId)
			continue

		if not runState.countries.has(army.locationCountryId):
			result.addError("Army %s has unknown locationCountryId: %s." % [army.id, army.locationCountryId])

		if army.targetCountryId != GameIds.EMPTY_ID and not runState.countries.has(army.targetCountryId):
			result.addError("Army %s has unknown targetCountryId: %s." % [army.id, army.targetCountryId])

		for unitId in army.units.keys():
			if int(army.units.get(unitId, 0)) < 0:
				result.addError("Army %s has negative unit count for %s." % [army.id, str(unitId)])


static func _validateBattles(runState: RunState, result: ValidationResult) -> void:
	for battleId in runState.battles.keys():
		var battle := runState.battles[battleId] as Object
		if battle == null:
			result.addError("RunState battle %s is not an Object." % battleId)
			continue

		var storedId := StringName(str(battle.get("id")))
		var attackerArmyId := StringName(str(battle.get("attackerArmyId")))
		var defenderArmyIds: Array[StringName] = _stringNameArray(battle.get("defenderArmyIds"))
		var sourceCountryId := StringName(str(battle.get("sourceCountryId")))
		var targetCountryId := StringName(str(battle.get("targetCountryId")))
		var status := int(battle.get("status"))
		var elapsedSeconds := float(battle.get("elapsedSeconds"))
		var durationSeconds := float(battle.get("durationSeconds"))

		if storedId == GameIds.EMPTY_ID:
			result.addError("Battle has empty id.")
		elif storedId != battleId:
			result.addError("Battle %s is stored under mismatched key %s." % [storedId, battleId])

		if status != BattleStatus.Value.Ended and not runState.armies.has(attackerArmyId):
			result.addError("Battle %s has unknown attackerArmyId: %s." % [storedId, attackerArmyId])

		for defenderArmyId in defenderArmyIds:
			if status != BattleStatus.Value.Ended and not runState.armies.has(defenderArmyId):
				result.addError("Battle %s has unknown defenderArmyId: %s." % [storedId, defenderArmyId])

		if not runState.countries.has(sourceCountryId):
			result.addError("Battle %s has unknown sourceCountryId: %s." % [storedId, sourceCountryId])

		if not runState.countries.has(targetCountryId):
			result.addError("Battle %s has unknown targetCountryId: %s." % [storedId, targetCountryId])

		if not [
			BattleStatus.Value.Pending,
			BattleStatus.Value.Active,
			BattleStatus.Value.Ended,
		].has(status):
			result.addError("Battle %s has invalid status: %s." % [storedId, status])

		if elapsedSeconds < 0.0 or is_nan(elapsedSeconds):
			result.addError("Battle %s has invalid elapsedSeconds." % storedId)

		if durationSeconds < 0.0 or is_nan(durationSeconds):
			result.addError("Battle %s has invalid durationSeconds." % storedId)


static func _validateUpgrades(runState: RunState, result: ValidationResult) -> void:
	var seenUpgradeIds := {}
	for upgradeId in runState.upgrades:
		if upgradeId == GameIds.EMPTY_ID:
			result.addError("RunState upgrades contains empty id.")
		elif seenUpgradeIds.has(upgradeId):
			result.addError("RunState upgrades contains duplicate id: %s." % upgradeId)
		else:
			seenUpgradeIds[upgradeId] = true

	for effectType in UPGRADE_SIMULATION.supportedEffectTypes().keys():
		if not runState.upgradeEffects.has(effectType):
			result.addError("RunState upgradeEffects missing key: %s." % effectType)
			continue

		var value = runState.upgradeEffects[effectType]
		if not _isNumeric(value):
			result.addError("RunState upgrade effect %s is not numeric." % effectType)
		elif float(value) <= 0.0 or is_nan(float(value)):
			result.addError("RunState upgrade effect %s must be positive." % effectType)

	if not runState.activeUpgradeChoice.is_empty():
		if typeof(runState.activeUpgradeChoice.get("isOpen", false)) != TYPE_BOOL:
			result.addError("RunState activeUpgradeChoice isOpen is not bool.")
		var choices = runState.activeUpgradeChoice.get("choices", [])
		if not (choices is Array):
			result.addError("RunState activeUpgradeChoice choices is not an array.")


static func _validateMiniGoalState(runState: RunState, result: ValidationResult) -> void:
	var rarityBoost = runState.miniGoalState.get("upgradeRarityBoost", 0)
	if not _isNumeric(rarityBoost):
		result.addError("RunState miniGoalState upgradeRarityBoost is not numeric.")
	elif int(rarityBoost) < 0:
		result.addError("RunState miniGoalState upgradeRarityBoost is negative.")

	var seenGoalIds := {}
	for goal in runState.miniGoals:
		var goalId := StringName(str(goal.get("id", "")))
		if goalId == GameIds.EMPTY_ID:
			result.addError("RunState mini goal has empty id.")
		elif seenGoalIds.has(goalId):
			result.addError("RunState mini goals contains duplicate id: %s." % goalId)
		else:
			seenGoalIds[goalId] = true

		var progress = goal.get("progress", 0.0)
		if not _isNumeric(progress):
			result.addError("Mini goal %s progress is not numeric." % goalId)
		elif float(progress) < 0.0 or is_nan(float(progress)):
			result.addError("Mini goal %s progress is invalid." % goalId)

		for key in ["isCompleted", "isRewardClaimed", "isFailed"]:
			if goal.has(key) and typeof(goal.get(key)) != TYPE_BOOL:
				result.addError("Mini goal %s %s is not bool." % [goalId, key])


static func _validateRunStats(runStats: Dictionary, result: ValidationResult) -> void:
	for key in ["countriesConquered", "maxCountriesOwned", "monthsSurvived", "battlesWon", "battlesLost"]:
		if not runStats.has(key):
			result.addError("RunStats missing key: %s." % key)
			continue

		if not _isNumeric(runStats.get(key, 0)):
			result.addError("RunStats %s is not numeric." % key)
		elif int(runStats.get(key, 0)) < 0:
			result.addError("RunStats %s is negative." % key)

	if not runStats.has("highestThreatReached"):
		result.addError("RunStats missing key: highestThreatReached.")
	elif not _isNumeric(runStats.get("highestThreatReached", 0.0)):
		result.addError("RunStats highestThreatReached is not numeric.")
	elif float(runStats.get("highestThreatReached", 0.0)) < 0.0 or is_nan(float(runStats.get("highestThreatReached", 0.0))):
		result.addError("RunStats highestThreatReached is invalid.")

	if not runStats.has("crownsAwarded"):
		result.addError("RunStats missing key: crownsAwarded.")
	elif typeof(runStats.get("crownsAwarded", false)) != TYPE_BOOL:
		result.addError("RunStats crownsAwarded is not bool.")


static func _validateAiGold(aiGoldByCountry: Dictionary, result: ValidationResult) -> void:
	for countryId in aiGoldByCountry.keys():
		var gold = aiGoldByCountry[countryId]
		if not _isNumeric(gold):
			result.addError("RunState aiGoldByCountry %s is not numeric." % str(countryId))
		elif float(gold) < 0.0 or is_nan(float(gold)):
			result.addError("RunState aiGoldByCountry %s is invalid." % str(countryId))


static func _isNumeric(value: Variant) -> bool:
	var valueType := typeof(value)
	return valueType == TYPE_INT or valueType == TYPE_FLOAT


static func _stringNameArray(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not (value is Array):
		return result

	for item in value as Array:
		result.append(StringName(str(item)))
	return result
