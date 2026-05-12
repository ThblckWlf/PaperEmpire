extends RefCounted
class_name CombatSimulation


const BATTLE_DURATION_SECONDS: float = 6.0
const COUNTRY_DEFENSE_POWER_MULTIPLIER: float = 8.0
const MIN_WIN_CASUALTY_RATE: float = 0.10
const MAX_WIN_CASUALTY_RATE: float = 0.35
const MIN_LOSS_CASUALTY_RATE: float = 0.70
const MAX_LOSS_CASUALTY_RATE: float = 1.0
const MIN_CASUALTIES_WHEN_DAMAGED: int = 1
const ATTACK_PORTION: float = 0.70
const RESERVE_PORTION: float = 0.30
const MIN_ATTACK_ARMY_SIZE: int = 5
const MIN_RESERVE_ARMY_SIZE: int = 3
const BATTLE_DATA := preload("res://src/core/model/battle_data.gd")


static func calculateArmyCombatPower(
	army: ArmyData,
	units: Array[UnitData],
	economy: Dictionary,
	context: Dictionary = {}
) -> float:
	if army == null:
		return 0.0

	var targetDefense := int(context.get("targetDefense", 0))
	var opposingUnits := _dictionaryValue(context.get("opposingUnits", {}))
	var infantryCount := maxi(0, int(army.units.get(GameIds.INFANTRY_UNIT_ID, army.units.get(str(GameIds.INFANTRY_UNIT_ID), 0))))
	var totalPower := 0.0
	for unitId in army.units.keys():
		var amount := maxi(0, int(army.units.get(unitId, 0)))
		if amount <= 0:
			continue

		var unitData := _unitById(units, StringName(str(unitId)))
		if unitData == null:
			continue

		var unitPower := float(amount * unitData.combatPower)
		unitPower *= _artillerySupportMultiplier(unitData, amount, infantryCount)
		unitPower *= _counterMultiplier(unitData, amount, opposingUnits)
		if unitData.id == GameIds.ARTILLERY_UNIT_ID and targetDefense > 0:
			unitPower *= float(unitData.bonuses.get("defenseDamageMultiplier", 1.0))

		totalPower += unitPower

	totalPower *= float(economy.get("combatPowerMultiplier", 1.0))
	return maxf(totalPower, 0.0)


static func calculateCountryDefensePower(
	country: CountryData,
	upgradeEffects: Dictionary = {},
	worldReaction: Dictionary = {}
) -> float:
	if country == null:
		return 0.0
	var multiplier := 1.0
	if country.ownerId == GameIds.PLAYER_OWNER_ID:
		multiplier = float(upgradeEffects.get("defenseCombatMultiplier", 1.0))
	else:
		multiplier = float(worldReaction.get("enemyStrengthMultiplier", 1.0))
	return maxf(float(country.defense) * COUNTRY_DEFENSE_POWER_MULTIPLIER * multiplier, 0.0)


static func startAttack(
	runState: RunState,
	armyId: StringName,
	targetCountryId: StringName,
	_units: Array[UnitData],
	requestedAttackingUnits: Dictionary = {}
) -> Dictionary:
	var result := _validateAttack(runState, armyId, targetCountryId)
	if not bool(result.get("accepted", false)):
		return result

	var army := runState.armies[armyId] as ArmyData
	var splitResult := splitUnitsForAttack(army.units) if requestedAttackingUnits.is_empty() else splitSpecificUnitsForAttack(army.units, requestedAttackingUnits)
	if not bool(splitResult.get("accepted", false)):
		result["accepted"] = false
		result["reason"] = str(splitResult.get("reason", "invalid_attack_split"))
		result["attackingUnitCount"] = int(splitResult.get("attackingUnitCount", 0))
		result["reserveUnitCount"] = int(splitResult.get("reserveUnitCount", 0))
		return result

	var attackArmy := ArmyData.new()
	attackArmy.id = _nextAttackArmyId(runState)
	attackArmy.ownerId = army.ownerId
	attackArmy.locationCountryId = army.locationCountryId
	attackArmy.targetCountryId = targetCountryId
	attackArmy.units = (splitResult.get("attackingUnits", {}) as Dictionary).duplicate(true)
	attackArmy.status = ArmyStatus.Value.Attacking
	attackArmy.movementProgress = 0.0
	runState.armies[attackArmy.id] = attackArmy

	army.units = (splitResult.get("reserveUnits", {}) as Dictionary).duplicate(true)
	army.status = ArmyStatus.Value.Stationed
	army.targetCountryId = GameIds.EMPTY_ID
	army.movementProgress = 0.0

	var targetCountry := runState.countries[targetCountryId] as CountryData
	targetCountry.isUnderAttack = true

	result["armyId"] = attackArmy.id
	result["sourceArmyId"] = armyId
	result["reserveArmyId"] = armyId
	result["sourceCountryId"] = attackArmy.locationCountryId
	result["attackerOwnerId"] = attackArmy.ownerId
	result["targetOwnerId"] = targetCountry.ownerId
	result["isAttack"] = true
	result["attackingUnits"] = attackArmy.units.duplicate(true)
	result["reserveUnits"] = army.units.duplicate(true)
	result["attackingUnitCount"] = int(splitResult.get("attackingUnitCount", 0))
	result["reserveUnitCount"] = int(splitResult.get("reserveUnitCount", 0))
	return result


static func splitSpecificUnitsForAttack(units: Dictionary, requestedAttackingUnits: Dictionary) -> Dictionary:
	var result := {
		"accepted": false,
		"reason": "",
		"attackingUnits": {},
		"reserveUnits": {},
		"attackingUnitCount": 0,
		"reserveUnitCount": 0,
	}
	var sourceUnits := _normalizedUnitCounts(units)
	var attackingUnits := _normalizedUnitCounts(requestedAttackingUnits)
	var reserveUnits := {}
	for unitId in sourceUnits.keys():
		var sourceAmount := int(sourceUnits.get(unitId, 0))
		var attackAmount := int(attackingUnits.get(unitId, 0))
		if attackAmount > sourceAmount:
			result["reason"] = "attack_units_unavailable"
			return result

		reserveUnits[unitId] = sourceAmount - attackAmount

	var attackingUnitCount := _unitCount(attackingUnits)
	var reserveUnitCount := _unitCount(reserveUnits)
	result["attackingUnits"] = attackingUnits
	result["reserveUnits"] = reserveUnits
	result["attackingUnitCount"] = attackingUnitCount
	result["reserveUnitCount"] = reserveUnitCount

	if attackingUnitCount < MIN_ATTACK_ARMY_SIZE:
		result["reason"] = "attack_army_too_small"
		return result
	if reserveUnitCount < MIN_RESERVE_ARMY_SIZE:
		result["reason"] = "reserve_army_too_small"
		return result

	result["accepted"] = true
	return result


static func splitUnitsForAttack(units: Dictionary) -> Dictionary:
	var result := {
		"accepted": false,
		"reason": "",
		"attackingUnits": {},
		"reserveUnits": {},
		"attackingUnitCount": 0,
		"reserveUnitCount": 0,
	}
	var totalUnits := _unitCount(units)
	var attackingUnitCount := int(floor(float(totalUnits) * ATTACK_PORTION))
	var reserveUnitCount := totalUnits - attackingUnitCount
	result["attackingUnitCount"] = attackingUnitCount
	result["reserveUnitCount"] = reserveUnitCount

	if attackingUnitCount < MIN_ATTACK_ARMY_SIZE:
		result["reason"] = "attack_army_too_small"
		return result
	if reserveUnitCount < MIN_RESERVE_ARMY_SIZE:
		result["reason"] = "reserve_army_too_small"
		return result

	var split := _proportionalUnitSplit(units, attackingUnitCount, totalUnits)
	result["attackingUnits"] = split.get("attackingUnits", {})
	result["reserveUnits"] = split.get("reserveUnits", {})
	result["accepted"] = true
	return result


static func beginBattleAfterArrival(
	runState: RunState,
	armyId: StringName,
	sourceCountryId: StringName,
	targetCountryId: StringName,
	units: Array[UnitData]
) -> Dictionary:
	var result := _validateBattleStart(runState, armyId, sourceCountryId, targetCountryId)
	if not bool(result.get("accepted", false)):
		return result

	var army := runState.armies[armyId] as ArmyData
	var targetCountry := runState.countries[targetCountryId] as CountryData
	var defenderArmyIds := _defenderArmyIds(runState, targetCountryId, army.ownerId)
	var battle = BATTLE_DATA.new()
	battle.id = _nextBattleId(runState)
	battle.attackerArmyId = army.id
	battle.attackerOwnerId = army.ownerId
	battle.defenderOwnerId = targetCountry.ownerId
	battle.attackerArmyIds.clear()
	battle.attackerArmyIds.append(army.id)
	battle.defenderArmyIds = defenderArmyIds
	battle.sourceCountryId = sourceCountryId
	battle.targetCountryId = targetCountryId
	battle.status = BattleStatus.Value.Active
	battle.durationSeconds = BATTLE_DURATION_SECONDS
	battle.attackerPower = _calculateAttackerBattlePower(runState, battle, units)
	battle.defenderPower = _calculateDefenderBattlePower(runState, battle, units)
	runState.battles[battle.id] = battle
	targetCountry.isUnderAttack = true

	army.status = ArmyStatus.Value.Fighting
	army.targetCountryId = targetCountryId
	for defenderArmyId in defenderArmyIds:
		var defender := runState.armies.get(defenderArmyId, null) as ArmyData
		if defender != null:
			defender.status = ArmyStatus.Value.Defending
			defender.targetCountryId = sourceCountryId
			defender.movementProgress = 0.0

	result["battleId"] = battle.id
	result["sourceCountryId"] = battle.sourceCountryId
	result["attackerOwnerId"] = battle.attackerOwnerId
	result["defenderOwnerId"] = battle.defenderOwnerId
	result["attackerArmyIds"] = battle.attackerArmyIds.duplicate()
	result["attackerPower"] = battle.attackerPower
	result["defenderPower"] = battle.defenderPower
	result["defenderArmyIds"] = battle.defenderArmyIds.duplicate()
	result["countryDefensePower"] = calculateCountryDefensePower(targetCountry, runState.upgradeEffects, runState.worldReaction)
	return result


static func advanceBattles(runState: RunState, deltaSeconds: float, units: Array[UnitData]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if runState == null or deltaSeconds <= 0.0:
		return events

	var battleIds := runState.battles.keys()
	battleIds.sort()
	for battleId in battleIds:
		var battle = runState.battles[battleId]
		if battle == null or battle.status != BattleStatus.Value.Active:
			continue

		battle.elapsedSeconds += deltaSeconds
		if battle.elapsedSeconds + GameTime.FLOAT_EPSILON < battle.durationSeconds:
			continue

		events.append_array(_finishBattle(runState, battle, units))
	return events


static func _finishBattle(runState: RunState, battle: Variant, units: Array[UnitData]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var army := runState.armies.get(battle.attackerArmyId, null) as ArmyData
	var targetCountry := runState.countries.get(battle.targetCountryId, null) as CountryData
	if army == null or targetCountry == null:
		battle.status = BattleStatus.Value.Ended
		return events

	var attackerOwnerId := army.ownerId
	battle.attackerPower = _calculateAttackerBattlePower(runState, battle, units)
	battle.defenderPower = _calculateDefenderBattlePower(runState, battle, units)
	battle.attackerWon = battle.attackerPower >= battle.defenderPower
	var previousOwnerId := targetCountry.ownerId
	if battle.attackerOwnerId == GameIds.EMPTY_ID:
		battle.attackerOwnerId = attackerOwnerId
	if battle.defenderOwnerId == GameIds.EMPTY_ID:
		battle.defenderOwnerId = previousOwnerId
	battle.winnerOwnerId = attackerOwnerId if battle.attackerWon else previousOwnerId

	if battle.attackerWon:
		var attackerCasualtyRate := _winnerCasualtyRate(battle.attackerPower, battle.defenderPower)
		var attackerCasualties := _applyCasualties(army, attackerCasualtyRate)
		var defenderCasualties := _applyDefenderCasualties(runState, battle.defenderArmyIds, MAX_LOSS_CASUALTY_RATE)
		_removeDefenderArmies(runState, battle.defenderArmyIds)
		targetCountry.ownerId = attackerOwnerId
		targetCountry.isUnderAttack = false
		army.locationCountryId = battle.targetCountryId
		army.status = ArmyStatus.Value.Stationed
		army.targetCountryId = GameIds.EMPTY_ID
		battle.casualties = {
			"attacker": attackerCasualties,
			"defenders": defenderCasualties,
		}
	else:
		var defenderCasualtyRate := _winnerCasualtyRate(battle.defenderPower, battle.attackerPower)
		var attackerCasualtyRate := _loserCasualtyRate(battle.attackerPower, battle.defenderPower)
		var defenderCasualties := _applyDefenderCasualties(runState, battle.defenderArmyIds, defenderCasualtyRate)
		var attackerCasualties := _applyCasualties(army, attackerCasualtyRate)
		_restoreDefenderArmies(runState, battle.defenderArmyIds)
		if _unitCount(army.units) <= 0:
			runState.armies.erase(army.id)
		else:
			army.locationCountryId = battle.sourceCountryId
			army.status = ArmyStatus.Value.Stationed
			army.targetCountryId = GameIds.EMPTY_ID
			army.movementProgress = 0.0
		battle.casualties = {
			"attacker": attackerCasualties,
			"defenders": defenderCasualties,
		}
		targetCountry.isUnderAttack = false

	battle.status = BattleStatus.Value.Ended
	battle.elapsedSeconds = battle.durationSeconds

	var endedPayload := _battlePayload(battle)
	events.append({
		"eventType": EventType.BATTLE_ENDED,
		"payload": endedPayload,
	})
	if battle.attackerWon:
		events.append({
			"eventType": EventType.COUNTRY_CONQUERED,
			"payload": {
				"battleId": battle.id,
				"armyId": battle.attackerArmyId,
				"countryId": battle.targetCountryId,
				"newOwnerId": attackerOwnerId,
				"previousOwnerId": previousOwnerId,
				"attackerOwnerId": attackerOwnerId,
				"defenderOwnerId": battle.defenderOwnerId,
			},
		})
	return events


static func _validateAttack(runState: RunState, armyId: StringName, targetCountryId: StringName) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": armyId,
		"targetCountryId": targetCountryId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.armies.has(armyId):
		result["reason"] = "unknown_army"
		return result

	if not runState.countries.has(targetCountryId):
		result["reason"] = "unknown_target_country"
		return result

	var army := runState.armies[armyId] as ArmyData
	if army == null:
		result["reason"] = "invalid_army"
		return result

	if army.status != ArmyStatus.Value.Stationed:
		result["reason"] = "army_not_stationed"
		return result

	if _unitCount(army.units) <= 0:
		result["reason"] = "army_has_no_units"
		return result

	var sourceCountry := runState.countries.get(army.locationCountryId, null) as CountryData
	if sourceCountry == null:
		result["reason"] = "unknown_source_country"
		return result

	if sourceCountry.ownerId != army.ownerId:
		result["reason"] = "source_not_owned"
		return result

	if not sourceCountry.neighbors.has(targetCountryId):
		result["reason"] = "target_not_neighbor"
		return result

	var targetCountry := runState.countries[targetCountryId] as CountryData
	if targetCountry == null:
		result["reason"] = "invalid_target_country"
		return result

	if targetCountry.ownerId == army.ownerId:
		result["reason"] = "target_already_owned"
		return result

	if targetCountry.isUnderAttack:
		result["reason"] = "target_under_attack"
		return result

	if _hasActiveBattleFor(runState, armyId, targetCountryId):
		result["reason"] = "battle_already_active"
		return result

	result["accepted"] = true
	return result


static func _validateBattleStart(
	runState: RunState,
	armyId: StringName,
	sourceCountryId: StringName,
	targetCountryId: StringName
) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": armyId,
		"sourceCountryId": sourceCountryId,
		"targetCountryId": targetCountryId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.armies.has(armyId):
		result["reason"] = "unknown_army"
		return result

	if not runState.countries.has(sourceCountryId) or not runState.countries.has(targetCountryId):
		result["reason"] = "unknown_country"
		return result

	var army := runState.armies[armyId] as ArmyData
	if army == null:
		result["reason"] = "invalid_army"
		return result

	if army.locationCountryId != targetCountryId:
		result["reason"] = "army_not_at_target"
		return result

	var targetCountry := runState.countries[targetCountryId] as CountryData
	if targetCountry == null or targetCountry.ownerId == army.ownerId:
		result["reason"] = "invalid_target_country"
		return result

	result["accepted"] = true
	return result


static func _calculateAttackerBattlePower(runState: RunState, battle: Variant, units: Array[UnitData]) -> float:
	var army := runState.armies.get(battle.attackerArmyId, null) as ArmyData
	var targetCountry := runState.countries.get(battle.targetCountryId, null) as CountryData
	var economy := runState.economy if army != null and army.ownerId == GameIds.PLAYER_OWNER_ID else {}
	return calculateArmyCombatPower(army, units, economy, {
		"targetDefense": targetCountry.defense if targetCountry != null else 0,
		"opposingUnits": _combinedUnits(runState, battle.defenderArmyIds),
	})


static func _calculateDefenderBattlePower(runState: RunState, battle: Variant, units: Array[UnitData]) -> float:
	var attacker := runState.armies.get(battle.attackerArmyId, null) as ArmyData
	var targetCountry := runState.countries.get(battle.targetCountryId, null) as CountryData
	var attackerUnits := attacker.units if attacker != null else {}
	var power := calculateCountryDefensePower(targetCountry, runState.upgradeEffects, runState.worldReaction)
	for defenderArmyId in battle.defenderArmyIds:
		var defender := runState.armies.get(defenderArmyId, null) as ArmyData
		if defender == null:
			continue

		power += calculateArmyCombatPower(defender, units, {}, {
			"opposingUnits": attackerUnits,
		})
	return maxf(power, 0.0)


static func _defenderArmyIds(runState: RunState, targetCountryId: StringName, attackerOwnerId: StringName) -> Array[StringName]:
	var defenderIds: Array[StringName] = []
	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.locationCountryId != targetCountryId:
			continue

		if army.ownerId == attackerOwnerId or army.status == ArmyStatus.Value.Defeated:
			continue

		defenderIds.append(army.id)
	return defenderIds


static func _combinedUnits(runState: RunState, armyIds: Array[StringName]) -> Dictionary:
	var combined := {}
	for armyId in armyIds:
		var army := runState.armies.get(armyId, null) as ArmyData
		if army == null:
			continue

		for unitId in army.units.keys():
			var normalizedId := StringName(str(unitId))
			combined[normalizedId] = int(combined.get(normalizedId, 0)) + maxi(0, int(army.units.get(unitId, 0)))
	return combined


static func _proportionalUnitSplit(units: Dictionary, attackingUnitCount: int, totalUnits: int) -> Dictionary:
	var attackingUnits := {}
	var reserveUnits := {}
	var remainders: Array[Dictionary] = []
	var assignedAttackers := 0
	var unitIds := units.keys()
	unitIds.sort()
	for unitId in unitIds:
		var normalizedId := StringName(str(unitId))
		var amount := maxi(0, int(units.get(unitId, 0)))
		var exactAttackers := float(amount * attackingUnitCount) / maxf(float(totalUnits), 1.0)
		var attackers := mini(amount, int(floor(exactAttackers)))
		attackingUnits[normalizedId] = attackers
		reserveUnits[normalizedId] = amount - attackers
		assignedAttackers += attackers
		remainders.append({
			"unitId": normalizedId,
			"remainder": exactAttackers - float(attackers),
		})

	remainders.sort_custom(_sortRemainderDescending)
	var missingAttackers := attackingUnitCount - assignedAttackers
	for row in remainders:
		if missingAttackers <= 0:
			break

		var unitId := StringName(str(row.get("unitId", GameIds.EMPTY_ID)))
		var reserveAmount := int(reserveUnits.get(unitId, 0))
		if reserveAmount <= 0:
			continue

		attackingUnits[unitId] = int(attackingUnits.get(unitId, 0)) + 1
		reserveUnits[unitId] = reserveAmount - 1
		missingAttackers -= 1

	return {
		"attackingUnits": attackingUnits,
		"reserveUnits": reserveUnits,
	}


static func _applyDefenderCasualties(runState: RunState, defenderArmyIds: Array[StringName], casualtyRate: float) -> Dictionary:
	var casualties := {}
	for defenderArmyId in defenderArmyIds:
		var defender := runState.armies.get(defenderArmyId, null) as ArmyData
		if defender == null:
			continue

		casualties[str(defenderArmyId)] = _applyCasualties(defender, casualtyRate)
	return casualties


static func _applyCasualties(army: ArmyData, casualtyRate: float) -> Dictionary:
	var casualties := {}
	var totalLost := 0
	var unitIds := army.units.keys()
	unitIds.sort()
	for unitId in unitIds:
		var amount := maxi(0, int(army.units.get(unitId, 0)))
		if amount <= 0:
			army.units[unitId] = 0
			continue

		var lost := int(floor(float(amount) * casualtyRate))
		if lost <= 0 and casualtyRate > 0.0 and totalLost < MIN_CASUALTIES_WHEN_DAMAGED:
			lost = 1

		lost = mini(lost, amount)
		army.units[unitId] = maxi(0, amount - lost)
		if lost > 0:
			casualties[unitId] = lost
			totalLost += lost
	return casualties


static func _restoreDefenderArmies(runState: RunState, defenderArmyIds: Array[StringName]) -> void:
	for defenderArmyId in defenderArmyIds:
		var defender := runState.armies.get(defenderArmyId, null) as ArmyData
		if defender == null:
			continue

		if _unitCount(defender.units) <= 0:
			runState.armies.erase(defenderArmyId)
			continue

		defender.status = ArmyStatus.Value.Stationed
		defender.targetCountryId = GameIds.EMPTY_ID
		defender.movementProgress = 0.0


static func _removeDefenderArmies(runState: RunState, defenderArmyIds: Array[StringName]) -> void:
	for defenderArmyId in defenderArmyIds:
		runState.armies.erase(defenderArmyId)


static func _winnerCasualtyRate(winnerPower: float, loserPower: float) -> float:
	var pressure := loserPower / maxf(winnerPower, 1.0)
	return clampf(pressure * 0.28, MIN_WIN_CASUALTY_RATE, MAX_WIN_CASUALTY_RATE)


static func _loserCasualtyRate(loserPower: float, winnerPower: float) -> float:
	var dominance := winnerPower / maxf(loserPower, 1.0)
	return clampf(0.70 + (dominance - 1.0) * 0.15, MIN_LOSS_CASUALTY_RATE, MAX_LOSS_CASUALTY_RATE)


static func _artillerySupportMultiplier(unitData: UnitData, artilleryAmount: int, infantryCount: int) -> float:
	if unitData.id != GameIds.ARTILLERY_UNIT_ID:
		return 1.0

	var requiredInfantry := int(unitData.bonuses.get("supportInfantryPerArtillery", 2)) * artilleryAmount
	if infantryCount >= requiredInfantry:
		return 1.0

	return float(unitData.bonuses.get("unsupportedCombatMultiplier", 0.5))


static func _counterMultiplier(unitData: UnitData, ownAmount: int, opposingUnits: Dictionary) -> float:
	var counterVs := StringName(str(unitData.bonuses.get("counterBonusVs", "")))
	if counterVs == GameIds.EMPTY_ID:
		return 1.0

	var counteredAmount := maxi(0, int(opposingUnits.get(counterVs, opposingUnits.get(str(counterVs), 0))))
	if counteredAmount <= 0:
		return 1.0

	var counterRatio := clampf(float(counteredAmount) / maxf(float(ownAmount), 1.0), 0.0, 1.0)
	return lerpf(1.0, float(unitData.bonuses.get("counterBonusMultiplier", 1.0)), counterRatio)


static func _hasActiveBattleFor(runState: RunState, armyId: StringName, targetCountryId: StringName) -> bool:
	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle == null or battle.status != BattleStatus.Value.Active:
			continue

		if battle.attackerArmyId == armyId or battle.targetCountryId == targetCountryId:
			return true
	return false


static func _sortRemainderDescending(left: Dictionary, right: Dictionary) -> bool:
	var leftRemainder := float(left.get("remainder", 0.0))
	var rightRemainder := float(right.get("remainder", 0.0))
	if not is_equal_approx(leftRemainder, rightRemainder):
		return leftRemainder > rightRemainder
	return str(left.get("unitId", "")) < str(right.get("unitId", ""))


static func _battlePayload(battle: Variant) -> Dictionary:
	var attackerArmyIds: Array[StringName] = battle.attackerArmyIds.duplicate()
	if attackerArmyIds.is_empty() and battle.attackerArmyId != GameIds.EMPTY_ID:
		attackerArmyIds.append(battle.attackerArmyId)
	return {
		"battleId": battle.id,
		"armyId": battle.attackerArmyId,
		"attackerArmyIds": attackerArmyIds,
		"attackerOwnerId": battle.attackerOwnerId,
		"defenderOwnerId": battle.defenderOwnerId,
		"defenderArmyIds": battle.defenderArmyIds.duplicate(),
		"sourceCountryId": battle.sourceCountryId,
		"targetCountryId": battle.targetCountryId,
		"attackerPower": battle.attackerPower,
		"defenderPower": battle.defenderPower,
		"attackerWon": battle.attackerWon,
		"winnerOwnerId": battle.winnerOwnerId,
		"casualties": battle.casualties,
	}


static func _unitById(units: Array[UnitData], unitId: StringName) -> UnitData:
	for unit in units:
		if unit.id == unitId:
			return unit
	return null


static func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += maxi(0, int(units.get(unitId, 0)))
	return total


static func _normalizedUnitCounts(units: Dictionary) -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: maxi(0, int(units.get(GameIds.INFANTRY_UNIT_ID, units.get(str(GameIds.INFANTRY_UNIT_ID), 0)))),
		GameIds.CAVALRY_UNIT_ID: maxi(0, int(units.get(GameIds.CAVALRY_UNIT_ID, units.get(str(GameIds.CAVALRY_UNIT_ID), 0)))),
		GameIds.ARTILLERY_UNIT_ID: maxi(0, int(units.get(GameIds.ARTILLERY_UNIT_ID, units.get(str(GameIds.ARTILLERY_UNIT_ID), 0)))),
	}


static func _nextBattleId(runState: RunState) -> StringName:
	var nextIndex := 1
	while runState.battles.has(StringName("battle_%d" % nextIndex)):
		nextIndex += 1
	return StringName("battle_%d" % nextIndex)


static func _nextAttackArmyId(runState: RunState) -> StringName:
	var nextIndex := 1
	while runState.armies.has(StringName("army_attack_%d" % nextIndex)):
		nextIndex += 1
	return StringName("army_attack_%d" % nextIndex)


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}
