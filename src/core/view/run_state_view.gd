extends RefCounted
class_name RunStateView


const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const ECONOMY_SIMULATION := preload("res://src/core/simulation/economy_simulation.gd")
const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")


static func createTopBarData(runState: RunState) -> Dictionary:
	if runState == null:
		return {}

	var monthlyIncome := ECONOMY_SIMULATION.calculateMonthlyIncome(runState)
	var foodStatus := ECONOMY_SIMULATION.calculateFoodStatus(runState, PrototypeContentLoader.loadUnits())
	return {
		"gold": int(runState.resources.get("gold", 0)),
		"food": int(runState.resources.get("food", 0)),
		"threat": int(runState.resources.get("threat", 0)),
		"threatState": THREAT_SIMULATION.threatState(int(runState.resources.get("threat", 0))),
		"armyStrength": _totalArmyUnits(runState),
		"goldPerMonth": int(monthlyIncome.get("gold", 0)),
		"foodPerMonth": int(foodStatus.get("netFood", 0)),
		"foodIncomePerMonth": int(foodStatus.get("foodIncome", 0)),
		"foodUpkeepPerMonth": int(foodStatus.get("foodUpkeep", 0)),
		"supplyDeficit": int(foodStatus.get("supplyDeficit", 0)),
		"emergencySupplyGoldPerMonth": int(foodStatus.get("emergencySupplyGoldPerMonth", 0)),
		"foodDeficitThisMonth": int(foodStatus.get("foodDeficitThisMonth", 0)),
		"emergencySupplyGoldCost": int(foodStatus.get("emergencySupplyGoldCost", 0)),
		"unfundedSupplyDeficit": int(foodStatus.get("unfundedSupplyDeficit", 0)),
		"dateText": _dateText(runState.time),
		"speed": int(runState.speed),
		"isFoodShortage": bool(runState.economy.get("isFoodShortage", false)),
		"foodWarning": bool(foodStatus.get("foodWarning", false)),
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
		stationedArmyRows.append("Keine")

	var attackOptions := _attackOptionsForTarget(runState, country.id)
	var selectedAttackArmyId := _selectedAttackArmyId(attackOptions, selectedArmyId)
	var canAttack := not attackOptions.is_empty()

	return {
		"hasCountry": true,
		"id": country.id,
		"name": country.name,
		"ownerId": country.ownerId,
		"ownerText": _ownerText(runState, country.ownerId),
		"isPlayerOwned": country.ownerId == GameIds.PLAYER_OWNER_ID,
		"canRecruit": country.ownerId == GameIds.PLAYER_OWNER_ID and not _isCountryUnderAttack(runState, country.id),
		"goldPerMonth": country.goldPerMonth,
		"foodPerMonth": country.foodPerMonth,
		"defense": country.defense,
		"stationedArmyCount": stationedArmyCount,
		"stationedUnitCount": stationedUnitCount,
		"stationedArmySummary": "%d / %d" % [stationedArmyCount, stationedUnitCount],
		"stationedArmyRows": stationedArmyRows,
		"selectedArmyId": selectedArmyId,
		"selectedAttackArmyId": selectedAttackArmyId,
		"canAttack": canAttack,
		"attackBlockedReason": "" if canAttack else _attackBlockedReason(runState, selectedArmyId, country.id),
		"attackOptions": attackOptions,
		"unitNames": _unitNamesById(),
		"unitOrder": [
			GameIds.INFANTRY_UNIT_ID,
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
		],
		"recruitmentPreviews": _recruitmentPreviewsForCountry(runState, country.id),
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
			"playerCountryId": _playerCountryId(runState),
			"playerCountryName": _playerCountryName(runState),
			"selectedCountryId": selectedCountryId,
			"canCreateArmy": _canCreateArmyInCountry(runState, selectedCountryId),
		}

	var army := runState.armies[armyId] as ArmyData
	if army == null:
		return {
			"hasArmy": false,
			"name": "No army selected",
			"playerCountryId": _playerCountryId(runState),
			"playerCountryName": _playerCountryName(runState),
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
		"canEdit": army.ownerId == GameIds.PLAYER_OWNER_ID and army.status == ArmyStatus.Value.Stationed and not _isCountryUnderAttack(runState, army.locationCountryId),
		"playerCountryId": _playerCountryId(runState),
		"playerCountryName": _playerCountryName(runState),
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
		if rows.size() >= 3:
			break
		if bool(goal.get("isFailed", false)) or bool(goal.get("isRewardClaimed", false)):
			continue

		var progress := float(goal.get("progress", 0.0))
		var target := float(goal.get("target", 1.0))
		var isCompleted := bool(goal.get("isCompleted", false))
		var isRewardClaimed := bool(goal.get("isRewardClaimed", false))
		rows.append({
			"id": StringName(str(goal.get("id", ""))),
			"name": str(goal.get("name", "Goal")),
			"goalType": str(goal.get("goalType", "")),
			"shortText": _goalShortText(goal),
			"description": str(goal.get("description", "")),
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


static func _playerCountryId(runState: RunState) -> StringName:
	if runState == null:
		return GameIds.EMPTY_ID

	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			return country.id
	return GameIds.EMPTY_ID


static func _playerCountryName(runState: RunState) -> String:
	var countryId := _playerCountryId(runState)
	if countryId == GameIds.EMPTY_ID:
		return "Spielerland"
	return _countryName(runState, countryId)


static func _countryName(runState: RunState, countryId: StringName) -> String:
	if not runState.countries.has(countryId):
		return "-"

	var country := runState.countries[countryId] as CountryData
	if country == null:
		return "-"
	return country.name


static func _ownerText(runState: RunState, ownerId: StringName) -> String:
	match ownerId:
		GameIds.PLAYER_OWNER_ID:
			return "Spieler"
		GameIds.NEUTRAL_OWNER_ID:
			return "Neutral"
		GameIds.WORLD_OWNER_ID:
			return "Welt"

	var ownerText := str(ownerId)
	if GameIds.isNpcOwnerId(ownerId):
		var countryId := StringName(ownerText.substr(GameIds.NPC_OWNER_PREFIX.length()))
		var countryName := _countryName(runState, countryId)
		if countryName != "-":
			return countryName
		return "Gegner"
	return ownerText


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


static func _recruitmentPreviewsForCountry(runState: RunState, countryId: StringName) -> Dictionary:
	var previews := {}
	var units := PrototypeContentLoader.loadUnits()
	for unit in units:
		previews[unit.id] = RECRUITMENT_SIMULATION.previewRecruitment(
			runState,
			countryId,
			unit.id,
			1,
			units
		)
	return previews


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
	return country != null and country.ownerId == GameIds.PLAYER_OWNER_ID and not _isCountryUnderAttack(runState, country.id)


static func _attackOptionsForTarget(runState: RunState, targetCountryId: StringName) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if runState == null or not runState.countries.has(targetCountryId):
		return options

	var targetCountry := runState.countries[targetCountryId] as CountryData
	if targetCountry == null or targetCountry.ownerId == GameIds.PLAYER_OWNER_ID or targetCountry.isUnderAttack:
		return options

	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID or army.status != ArmyStatus.Value.Stationed:
			continue
		if _unitCount(army.units) <= 0:
			continue

		var sourceCountry := runState.countries.get(army.locationCountryId, null) as CountryData
		if sourceCountry == null or not sourceCountry.neighbors.has(targetCountryId):
			continue
		if _hasActiveBattleFor(runState, army.id, targetCountryId):
			continue

		var defaultSplit: Dictionary = COMBAT_SIMULATION.splitMaximumUnitsForAttack(army.units)
		if not bool(defaultSplit.get("accepted", false)):
			continue

		options.append({
			"id": army.id,
			"name": str(army.id),
			"sourceCountryId": army.locationCountryId,
			"sourceCountryName": sourceCountry.name,
			"units": _normalizedUnits(army.units),
			"defaultAttackUnits": _normalizedUnits(defaultSplit.get("attackingUnits", {}) as Dictionary),
			"unitCount": _unitCount(army.units),
		})
	return options


static func _selectedAttackArmyId(attackOptions: Array[Dictionary], selectedArmyId: StringName) -> StringName:
	for option in attackOptions:
		if StringName(str(option.get("id", ""))) == selectedArmyId:
			return selectedArmyId

	if attackOptions.is_empty():
		return GameIds.EMPTY_ID
	return StringName(str(attackOptions[0].get("id", "")))


static func _attackBlockedReason(runState: RunState, armyId: StringName, targetCountryId: StringName) -> String:
	if runState == null or not runState.countries.has(targetCountryId):
		return "Kein Ziel"

	var targetCountry := runState.countries[targetCountryId] as CountryData
	if targetCountry == null:
		return "Kein Ziel"
	if targetCountry.ownerId == GameIds.PLAYER_OWNER_ID:
		return ""
	if targetCountry.isUnderAttack:
		return "Kampf läuft"

	if armyId == GameIds.EMPTY_ID or not runState.armies.has(armyId):
		return "Keine verfügbare Armee"

	var army := runState.armies[armyId] as ArmyData
	if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID:
		return "Keine verfügbare Armee"
	if army.status != ArmyStatus.Value.Stationed:
		return "Armee unterwegs"
	if _unitCount(army.units) <= 0:
		return "Keine verfügbare Armee"

	var sourceCountry := runState.countries.get(army.locationCountryId, null) as CountryData
	if sourceCountry == null or not sourceCountry.neighbors.has(targetCountryId):
		return "Kein Nachbarland"
	if _hasActiveBattleFor(runState, armyId, targetCountryId):
		return "Kampf läuft"
	return ""


static func _hasActiveBattleFor(runState: RunState, armyId: StringName, targetCountryId: StringName) -> bool:
	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle == null:
			continue
		if battle.status != BattleStatus.Value.Active:
			continue
		if battle.attackerArmyId == armyId or battle.targetCountryId == targetCountryId:
			return true
	return false


static func _isCountryUnderAttack(runState: RunState, countryId: StringName) -> bool:
	var country := runState.countries.get(countryId, null) as CountryData
	if country != null and country.isUnderAttack:
		return true

	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army != null and army.status == ArmyStatus.Value.Attacking and army.targetCountryId == countryId:
			return true

	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle != null and battle.status == BattleStatus.Value.Active and StringName(str(battle.get("targetCountryId"))) == countryId:
			return true
	return false


static func _goalShortText(goal: Dictionary) -> String:
	var target := int(goal.get("target", 1))
	match str(goal.get("goalType", "")):
		"conquerCountries":
			return "Erobere %d Länder" % target
		"reachGold":
			return "Erreiche %d Gold" % target
		"reachArmyPower":
			return "Besitze %d Armee" % target
		"defeatStrongerCountry":
			return "Besiege stärkeres Land"
		"holdThreatenedCountryMonths":
			return "Halte Grenze %dM" % target
		"conquerWithThreatBelow":
			return "Erobere bei < %d%%" % int(goal.get("limit", 0))
		_:
			return str(goal.get("name", "Ziel"))
