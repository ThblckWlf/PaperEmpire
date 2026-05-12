extends RefCounted
class_name RunStateView


const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")


static func createTopBarData(runState: RunState) -> Dictionary:
	if runState == null:
		return {}

	return {
		"gold": int(runState.resources.get("gold", 0)),
		"food": int(runState.resources.get("food", 0)),
		"threat": int(runState.resources.get("threat", 0)),
		"threatState": THREAT_SIMULATION.threatState(int(runState.resources.get("threat", 0))),
		"armyStrength": _totalArmyUnits(runState),
		"dateText": _dateText(runState.time),
		"speed": int(runState.speed),
		"isFoodShortage": bool(runState.economy.get("isFoodShortage", false)),
		"combatPowerMultiplier": float(runState.economy.get("combatPowerMultiplier", 1.0)),
	}


static func createCountryPanelData(
	runState: RunState,
	countryId: StringName,
	selectedArmyId: StringName = GameIds.EMPTY_ID
) -> Dictionary:
	if runState == null or not runState.countries.has(countryId):
		return {
			"hasCountry": false,
			"name": "No country selected",
		}

	var country := runState.countries[countryId] as CountryData
	if country == null:
		return {
			"hasCountry": false,
			"name": "No country selected",
		}

	var stationedArmyCount := 0
	var stationedUnitCount := 0
	var stationedArmyRows: Array[String] = []
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.locationCountryId != country.id:
			continue

		stationedArmyCount += 1
		var armyUnitCount := _unitCount(army.units)
		stationedUnitCount += armyUnitCount
		stationedArmyRows.append("%s: %d" % [str(army.id), armyUnitCount])
	if stationedArmyRows.is_empty():
		stationedArmyRows.append("None")

	return {
		"hasCountry": true,
		"id": country.id,
		"name": country.name,
		"ownerId": country.ownerId,
		"isPlayerOwned": country.ownerId == GameIds.PLAYER_OWNER_ID,
		"canRecruit": country.ownerId == GameIds.PLAYER_OWNER_ID and not bool(runState.economy.get("recruitmentBlocked", false)),
		"goldPerMonth": country.goldPerMonth,
		"foodPerMonth": country.foodPerMonth,
		"defense": country.defense,
		"stationedArmyCount": stationedArmyCount,
		"stationedUnitCount": stationedUnitCount,
		"stationedArmyRows": stationedArmyRows,
		"selectedArmyId": selectedArmyId,
		"canAttack": _canSelectedArmyAttack(runState, selectedArmyId, country.id),
	}


static func createArmyPanelData(
	runState: RunState,
	armyId: StringName,
	selectedCountryId: StringName = GameIds.EMPTY_ID
) -> Dictionary:
	if runState == null or not runState.armies.has(armyId):
		return {
			"hasArmy": false,
			"name": "No army selected",
			"selectedCountryId": selectedCountryId,
			"canCreateArmy": _canCreateArmyInCountry(runState, selectedCountryId),
		}

	var army := runState.armies[armyId] as ArmyData
	if army == null:
		return {
			"hasArmy": false,
			"name": "No army selected",
		}

	var locationName := _countryName(runState, army.locationCountryId)
	var targetName := "-"
	if army.targetCountryId != GameIds.EMPTY_ID:
		targetName = _countryName(runState, army.targetCountryId)
	var unitRows := _unitRows(army.units)
	var unitCosts := _unitCostsById()
	var unitNames := _unitNamesById()
	var foodUpkeep := _armyFoodUpkeep(runState, army)
	var combatPower := COMBAT_SIMULATION.calculateArmyCombatPower(
		army,
		PrototypeContentLoader.loadUnits(),
		runState.economy,
		{}
	)

	return {
		"hasArmy": true,
		"id": army.id,
		"name": str(army.id),
		"ownerId": army.ownerId,
		"isPlayerOwned": army.ownerId == GameIds.PLAYER_OWNER_ID,
		"canEdit": army.ownerId == GameIds.PLAYER_OWNER_ID and army.status == ArmyStatus.Value.Stationed,
		"selectedCountryId": selectedCountryId,
		"canCreateArmy": _canCreateArmyInCountry(runState, selectedCountryId),
		"status": _statusText(army.status),
		"location": locationName,
		"target": targetName,
		"movementProgress": army.movementProgress,
		"units": _normalizedUnits(army.units),
		"unitRows": unitRows,
		"unitCosts": unitCosts,
		"unitNames": unitNames,
		"unitOrder": [
			GameIds.INFANTRY_UNIT_ID,
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
		],
		"totalCombatPower": combatPower,
		"foodUpkeepPerMonth": foodUpkeep,
	}


static func createMiniGoalPanelData(runState: RunState) -> Dictionary:
	if runState == null:
		return {
			"goalRows": [],
		}

	var rows: Array[Dictionary] = []
	for goal in runState.miniGoals:
		var progress := float(goal.get("progress", 0.0))
		var target := float(goal.get("target", 1.0))
		var isCompleted := bool(goal.get("isCompleted", false))
		var isRewardClaimed := bool(goal.get("isRewardClaimed", false))
		rows.append({
			"id": StringName(str(goal.get("id", ""))),
			"name": str(goal.get("name", "Goal")),
			"progressText": "%d/%d" % [int(progress), int(target)],
			"isCompleted": isCompleted,
			"isRewardClaimed": isRewardClaimed,
			"canClaim": isCompleted and not isRewardClaimed,
		})
	return {
		"goalRows": rows,
	}


static func _dateText(time: Dictionary) -> String:
	return "Y%d M%d W%d" % [
		int(time.get("year", 1)),
		int(time.get("month", 1)),
		int(time.get("week", 1)),
	]


static func _totalArmyUnits(runState: RunState) -> int:
	var total := 0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army != null and army.ownerId == GameIds.PLAYER_OWNER_ID:
			total += _unitCount(army.units)
	return total


static func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += int(units[unitId])
	return total


static func _countryName(runState: RunState, countryId: StringName) -> String:
	if not runState.countries.has(countryId):
		return "-"

	var country := runState.countries[countryId] as CountryData
	if country == null:
		return "-"
	return country.name


static func _statusText(status: int) -> String:
	match status:
		ArmyStatus.Value.Stationed:
			return "Stationed"
		ArmyStatus.Value.Moving:
			return "Moving"
		ArmyStatus.Value.Attacking:
			return "Attacking"
		ArmyStatus.Value.Defending:
			return "Defending"
		ArmyStatus.Value.Defeated:
			return "Defeated"
		ArmyStatus.Value.Fighting:
			return "Fighting"
		_:
			return "Unknown"


static func _unitRows(units: Dictionary) -> Array[String]:
	var rows: Array[String] = []
	var unitNames := _unitNamesById()
	var unitIds := units.keys()
	unitIds.sort()
	for unitId in unitIds:
		var unitName := str(unitNames.get(StringName(str(unitId)), str(unitId).capitalize()))
		rows.append("%s: %d" % [unitName, int(units[unitId])])
	if rows.is_empty():
		rows.append("None")
	return rows


static func _normalizedUnits(units: Dictionary) -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: maxi(0, int(units.get(GameIds.INFANTRY_UNIT_ID, units.get(str(GameIds.INFANTRY_UNIT_ID), 0)))),
		GameIds.CAVALRY_UNIT_ID: maxi(0, int(units.get(GameIds.CAVALRY_UNIT_ID, units.get(str(GameIds.CAVALRY_UNIT_ID), 0)))),
		GameIds.ARTILLERY_UNIT_ID: maxi(0, int(units.get(GameIds.ARTILLERY_UNIT_ID, units.get(str(GameIds.ARTILLERY_UNIT_ID), 0)))),
	}


static func _unitCostsById() -> Dictionary:
	var costs := {}
	for unit in PrototypeContentLoader.loadUnits():
		costs[unit.id] = unit.cost
	return costs


static func _unitNamesById() -> Dictionary:
	var names := {}
	for unit in PrototypeContentLoader.loadUnits():
		names[unit.id] = unit.name
	return names


static func _armyFoodUpkeep(runState: RunState, army: ArmyData) -> int:
	var units := PrototypeContentLoader.loadUnits()
	var catalog := {}
	for unit in units:
		catalog[unit.id] = unit

	var upkeep := 0
	for unitId in army.units.keys():
		var unit := catalog.get(StringName(str(unitId)), null) as UnitData
		if unit != null:
			upkeep += maxi(0, int(army.units.get(unitId, 0))) * unit.foodUpkeep
	var multiplier := float(runState.upgradeEffects.get("foodUpkeepMultiplier", 1.0))
	return maxi(0, int(ceil(float(upkeep) * multiplier)))


static func _canCreateArmyInCountry(runState: RunState, countryId: StringName) -> bool:
	if runState == null or not runState.countries.has(countryId):
		return false

	var country := runState.countries[countryId] as CountryData
	return country != null and country.ownerId == GameIds.PLAYER_OWNER_ID


static func _canSelectedArmyAttack(runState: RunState, armyId: StringName, targetCountryId: StringName) -> bool:
	if runState == null or not runState.armies.has(armyId) or not runState.countries.has(targetCountryId):
		return false

	var army := runState.armies[armyId] as ArmyData
	var targetCountry := runState.countries[targetCountryId] as CountryData
	if army == null or targetCountry == null:
		return false

	if army.ownerId != GameIds.PLAYER_OWNER_ID or army.status != ArmyStatus.Value.Stationed:
		return false

	if targetCountry.ownerId == GameIds.PLAYER_OWNER_ID or _unitCount(army.units) <= 0:
		return false

	var sourceCountry := runState.countries.get(army.locationCountryId, null) as CountryData
	return sourceCountry != null and sourceCountry.neighbors.has(targetCountryId)
