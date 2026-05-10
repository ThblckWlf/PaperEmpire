extends RefCounted
class_name CombatSimulation


const BATTLE_DURATION_SECONDS: float = 6.0
const COUNTRY_DEFENSE_POWER_MULTIPLIER: float = 8.0
const MIN_WIN_CASUALTY_RATE: float = 0.05
const MAX_WIN_CASUALTY_RATE: float = 0.35
const LOSS_CASUALTY_RATE: float = 0.55
const MIN_CASUALTIES_WHEN_DAMAGED: int = 1
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
	var totalPower := 0.0
	for unitId in army.units.keys():
		var amount := int(army.units.get(unitId, 0))
		if amount <= 0:
			continue

		var unitData := _unitById(units, StringName(str(unitId)))
		if unitData == null:
			continue

		var unitPower := float(amount * unitData.combatPower)
		if unitData.id == GameIds.CAVALRY_UNIT_ID:
			unitPower *= 1.0 + float(unitData.bonuses.get("flanking", 0.0))
		elif unitData.id == GameIds.ARTILLERY_UNIT_ID and targetDefense > 0:
			unitPower *= 1.0 + float(unitData.bonuses.get("fortificationDamage", 0.0))

		totalPower += unitPower

	totalPower *= float(economy.get("combatPowerMultiplier", 1.0))
	return maxf(totalPower, 0.0)


static func calculateCountryDefensePower(country: CountryData) -> float:
	if country == null:
		return 0.0
	return maxf(float(country.defense) * COUNTRY_DEFENSE_POWER_MULTIPLIER, 0.0)


static func startAttack(
	runState: RunState,
	armyId: StringName,
	targetCountryId: StringName,
	units: Array[UnitData]
) -> Dictionary:
	var result := _validateAttack(runState, armyId, targetCountryId)
	if not bool(result.get("accepted", false)):
		return result

	var army := runState.armies[armyId] as ArmyData
	var targetCountry := runState.countries[targetCountryId] as CountryData
	var battle = BATTLE_DATA.new()
	battle.id = _nextBattleId(runState)
	battle.attackerArmyId = army.id
	battle.sourceCountryId = army.locationCountryId
	battle.targetCountryId = targetCountryId
	battle.status = BattleStatus.Value.Active
	battle.durationSeconds = BATTLE_DURATION_SECONDS
	battle.attackerPower = calculateArmyCombatPower(army, units, runState.economy, {
		"targetDefense": targetCountry.defense,
	})
	battle.defenderPower = calculateCountryDefensePower(targetCountry)
	runState.battles[battle.id] = battle

	army.status = ArmyStatus.Value.Attacking
	army.targetCountryId = targetCountryId
	army.movementProgress = 0.0

	result["battleId"] = battle.id
	result["sourceCountryId"] = battle.sourceCountryId
	result["attackerPower"] = battle.attackerPower
	result["defenderPower"] = battle.defenderPower
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

	battle.attackerPower = calculateArmyCombatPower(army, units, runState.economy, {
		"targetDefense": targetCountry.defense,
	})
	battle.defenderPower = calculateCountryDefensePower(targetCountry)
	battle.attackerWon = battle.attackerPower >= battle.defenderPower
	battle.winnerOwnerId = GameIds.PLAYER_OWNER_ID if battle.attackerWon else targetCountry.ownerId
	var previousOwnerId := targetCountry.ownerId

	if battle.attackerWon:
		var casualtyRate := clampf(battle.defenderPower / maxf(battle.attackerPower, 1.0) * 0.25, MIN_WIN_CASUALTY_RATE, MAX_WIN_CASUALTY_RATE)
		battle.casualties = _applyCasualties(army, casualtyRate)
		targetCountry.ownerId = GameIds.PLAYER_OWNER_ID
		army.locationCountryId = battle.targetCountryId
		army.status = ArmyStatus.Value.Stationed
	else:
		battle.casualties = _applyCasualties(army, LOSS_CASUALTY_RATE)
		army.status = ArmyStatus.Value.Defeated if _unitCount(army.units) <= 0 else ArmyStatus.Value.Stationed

	army.targetCountryId = GameIds.EMPTY_ID
	army.movementProgress = 0.0
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
				"newOwnerId": GameIds.PLAYER_OWNER_ID,
				"previousOwnerId": previousOwnerId,
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

	if army.ownerId != GameIds.PLAYER_OWNER_ID:
		result["reason"] = "army_not_owned"
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

	if not sourceCountry.neighbors.has(targetCountryId):
		result["reason"] = "target_not_neighbor"
		return result

	var targetCountry := runState.countries[targetCountryId] as CountryData
	if targetCountry == null:
		result["reason"] = "invalid_target_country"
		return result

	if targetCountry.ownerId == GameIds.PLAYER_OWNER_ID:
		result["reason"] = "target_already_owned"
		return result

	if _hasActiveBattleFor(runState, armyId, targetCountryId):
		result["reason"] = "battle_already_active"
		return result

	result["accepted"] = true
	return result


static func _applyCasualties(army: ArmyData, casualtyRate: float) -> Dictionary:
	var casualties := {}
	var totalLost := 0
	var unitIds := army.units.keys()
	unitIds.sort()
	for unitId in unitIds:
		var amount := int(army.units.get(unitId, 0))
		if amount <= 0:
			continue

		var lost := int(floor(float(amount) * casualtyRate))
		if lost <= 0 and casualtyRate > 0.0 and totalLost < MIN_CASUALTIES_WHEN_DAMAGED:
			lost = 1

		lost = mini(lost, amount)
		if lost <= 0:
			continue

		army.units[unitId] = amount - lost
		casualties[unitId] = lost
		totalLost += lost
	return casualties


static func _hasActiveBattleFor(runState: RunState, armyId: StringName, targetCountryId: StringName) -> bool:
	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle == null or battle.status != BattleStatus.Value.Active:
			continue

		if battle.attackerArmyId == armyId or battle.targetCountryId == targetCountryId:
			return true
	return false


static func _battlePayload(battle: Variant) -> Dictionary:
	return {
		"battleId": battle.id,
		"armyId": battle.attackerArmyId,
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
		total += int(units.get(unitId, 0))
	return total


static func _nextBattleId(runState: RunState) -> StringName:
	var nextIndex := 1
	while runState.battles.has(StringName("battle_%d" % nextIndex)):
		nextIndex += 1
	return StringName("battle_%d" % nextIndex)
