extends RefCounted
class_name RecruitmentSimulation


static func calculateRecruitmentCost(unitData: UnitData, amount: int, upgradeEffects: Dictionary = {}) -> Dictionary:
	if unitData == null or amount <= 0:
		return {
			"goldCost": 0,
			"foodReserveRequired": 0,
		}

	var costMultiplier := float(upgradeEffects.get("recruitmentCostMultiplier", 1.0))
	return {
		"goldCost": maxi(1, int(ceil(float(unitData.cost * amount) * costMultiplier))),
		"foodReserveRequired": unitData.foodUpkeep * amount,
	}


static func applyRecruitment(
	runState: RunState,
	countryId: StringName,
	unitId: StringName,
	amount: int,
	units: Array[UnitData],
	preferredArmyId: StringName = GameIds.EMPTY_ID
) -> Dictionary:
	var result := _validateRecruitment(runState, countryId, unitId, amount, units, preferredArmyId)
	if not bool(result.get("accepted", false)):
		return result

	var army := runState.armies[StringName(str(result.get("armyId", "")))] as ArmyData
	var goldCost := int(result.get("goldCost", 0))
	runState.resources["gold"] = int(runState.resources.get("gold", 0)) - goldCost
	army.units[unitId] = int(army.units.get(unitId, 0)) + amount
	result["gold"] = int(runState.resources.get("gold", 0))
	result["unitCount"] = int(army.units.get(unitId, 0))
	return result


static func updateArmyComposition(
	runState: RunState,
	armyId: StringName,
	targetUnits: Dictionary,
	units: Array[UnitData]
) -> Dictionary:
	var result := _validateCompositionUpdate(runState, armyId, targetUnits, units)
	if not bool(result.get("accepted", false)):
		return result

	var army := runState.armies[armyId] as ArmyData
	var goldCost := int(result.get("goldCost", 0))
	runState.resources["gold"] = int(runState.resources.get("gold", 0)) - goldCost
	army.units = _normalizedTargetUnits(targetUnits)
	result["gold"] = int(runState.resources.get("gold", 0))
	result["units"] = army.units.duplicate(true)
	return result


static func createArmy(runState: RunState, countryId: StringName) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": GameIds.EMPTY_ID,
		"countryId": countryId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.countries.has(countryId):
		result["reason"] = "unknown_country"
		return result

	var country := runState.countries[countryId] as CountryData
	if country == null:
		result["reason"] = "invalid_country"
		return result

	if country.ownerId != GameIds.PLAYER_OWNER_ID:
		result["reason"] = "country_not_owned"
		return result

	var army := ArmyData.new()
	army.id = _nextArmyId(runState)
	army.ownerId = GameIds.PLAYER_OWNER_ID
	army.locationCountryId = countryId
	army.targetCountryId = GameIds.EMPTY_ID
	army.units = {}
	army.status = ArmyStatus.Value.Stationed
	army.movementProgress = 0.0
	runState.armies[army.id] = army

	result["accepted"] = true
	result["armyId"] = army.id
	return result


static func createArmyForOwner(
	runState: RunState,
	countryId: StringName,
	ownerId: StringName,
	initialUnits: Dictionary = {}
) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": GameIds.EMPTY_ID,
		"countryId": countryId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.countries.has(countryId):
		result["reason"] = "unknown_country"
		return result

	var army := ArmyData.new()
	army.id = _nextArmyId(runState)
	army.ownerId = ownerId
	army.locationCountryId = countryId
	army.targetCountryId = GameIds.EMPTY_ID
	army.units = _normalizedTargetUnits(initialUnits)
	army.status = ArmyStatus.Value.Stationed
	army.movementProgress = 0.0
	runState.armies[army.id] = army

	result["accepted"] = true
	result["armyId"] = army.id
	return result


static func _validateRecruitment(
	runState: RunState,
	countryId: StringName,
	unitId: StringName,
	amount: int,
	units: Array[UnitData],
	preferredArmyId: StringName
) -> Dictionary:
	var result := {
		"accepted": false,
		"countryId": countryId,
		"unitType": unitId,
		"amount": amount,
		"armyId": GameIds.EMPTY_ID,
		"goldCost": 0,
		"foodReserveRequired": 0,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if amount <= 0:
		result["reason"] = "invalid_amount"
		return result

	if bool(runState.economy.get("recruitmentBlocked", false)):
		result["reason"] = "recruitment_blocked"
		return result

	if not runState.countries.has(countryId):
		result["reason"] = "unknown_country"
		return result

	var country := runState.countries[countryId] as CountryData
	if country == null:
		result["reason"] = "invalid_country"
		return result

	if country.ownerId != GameIds.PLAYER_OWNER_ID:
		result["reason"] = "country_not_owned"
		return result

	var unitData := _unitById(units, unitId)
	if unitData == null:
		result["reason"] = "unknown_unit"
		return result

	var targetArmy := _recruitTargetArmy(runState, countryId, preferredArmyId)
	if targetArmy == null:
		result["reason"] = "no_stationed_army"
		return result

	var cost := calculateRecruitmentCost(unitData, amount, runState.upgradeEffects)
	result["armyId"] = targetArmy.id
	result["goldCost"] = int(cost.get("goldCost", 0))
	result["foodReserveRequired"] = int(cost.get("foodReserveRequired", 0))

	if int(runState.resources.get("gold", 0)) < int(result["goldCost"]):
		result["reason"] = "not_enough_gold"
		return result

	result["accepted"] = true
	return result


static func _validateCompositionUpdate(
	runState: RunState,
	armyId: StringName,
	targetUnits: Dictionary,
	units: Array[UnitData]
) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": armyId,
		"targetUnits": targetUnits.duplicate(true),
		"goldCost": 0,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.armies.has(armyId):
		result["reason"] = "unknown_army"
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

	var normalizedUnits := _normalizedTargetUnits(targetUnits)
	for unitId in normalizedUnits.keys():
		if _unitById(units, StringName(str(unitId))) == null:
			result["reason"] = "unknown_unit"
			return result

	var goldCost := _compositionGoldCost(army.units, normalizedUnits, units, runState.upgradeEffects)
	result["goldCost"] = goldCost
	if int(runState.resources.get("gold", 0)) < goldCost:
		result["reason"] = "not_enough_gold"
		return result

	result["accepted"] = true
	return result


static func _unitById(units: Array[UnitData], unitId: StringName) -> UnitData:
	for unit in units:
		if unit.id == unitId:
			return unit
	return null


static func _recruitTargetArmy(runState: RunState, countryId: StringName, preferredArmyId: StringName) -> ArmyData:
	if preferredArmyId != GameIds.EMPTY_ID and runState.armies.has(preferredArmyId):
		var preferredArmy := runState.armies[preferredArmyId] as ArmyData
		if _canRecruitIntoArmy(preferredArmy, countryId):
			return preferredArmy

	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if _canRecruitIntoArmy(army, countryId):
			return army
	return null


static func _canRecruitIntoArmy(army: ArmyData, countryId: StringName) -> bool:
	return (
		army != null
		and army.ownerId == GameIds.PLAYER_OWNER_ID
		and army.locationCountryId == countryId
		and army.status == ArmyStatus.Value.Stationed
	)


static func _compositionGoldCost(
	currentUnits: Dictionary,
	targetUnits: Dictionary,
	units: Array[UnitData],
	upgradeEffects: Dictionary
) -> int:
	var totalCost := 0
	var costMultiplier := float(upgradeEffects.get("recruitmentCostMultiplier", 1.0))
	for unitId in targetUnits.keys():
		var targetAmount := int(targetUnits.get(unitId, 0))
		var currentAmount := int(currentUnits.get(unitId, 0))
		var addedAmount := maxi(0, targetAmount - currentAmount)
		if addedAmount <= 0:
			continue

		var unitData := _unitById(units, StringName(str(unitId)))
		if unitData != null:
			totalCost += int(ceil(float(unitData.cost * addedAmount) * costMultiplier))
	return maxi(0, totalCost)


static func _normalizedTargetUnits(targetUnits: Dictionary) -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: maxi(0, int(targetUnits.get(GameIds.INFANTRY_UNIT_ID, targetUnits.get(str(GameIds.INFANTRY_UNIT_ID), 0)))),
		GameIds.CAVALRY_UNIT_ID: maxi(0, int(targetUnits.get(GameIds.CAVALRY_UNIT_ID, targetUnits.get(str(GameIds.CAVALRY_UNIT_ID), 0)))),
		GameIds.ARTILLERY_UNIT_ID: maxi(0, int(targetUnits.get(GameIds.ARTILLERY_UNIT_ID, targetUnits.get(str(GameIds.ARTILLERY_UNIT_ID), 0)))),
	}


static func _nextArmyId(runState: RunState) -> StringName:
	var nextIndex := 1
	while runState.armies.has(StringName("army_%d" % nextIndex)):
		nextIndex += 1
	return StringName("army_%d" % nextIndex)
