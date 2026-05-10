extends RefCounted
class_name RunStateView


const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")


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


static func createCountryPanelData(runState: RunState, countryId: StringName) -> Dictionary:
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
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.locationCountryId != country.id:
			continue

		stationedArmyCount += 1
		stationedUnitCount += _unitCount(army.units)

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
	}


static func createArmyPanelData(runState: RunState, armyId: StringName) -> Dictionary:
	if runState == null or not runState.armies.has(armyId):
		return {
			"hasArmy": false,
			"name": "No army selected",
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

	return {
		"hasArmy": true,
		"id": army.id,
		"name": str(army.id),
		"status": _statusText(army.status),
		"location": locationName,
		"target": targetName,
		"movementProgress": army.movementProgress,
		"unitRows": _unitRows(army.units),
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
		if army != null:
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
		_:
			return "Unknown"


static func _unitRows(units: Dictionary) -> Array[String]:
	var rows: Array[String] = []
	var unitIds := units.keys()
	unitIds.sort()
	for unitId in unitIds:
		rows.append("%s: %d" % [str(unitId).capitalize(), int(units[unitId])])
	if rows.is_empty():
		rows.append("None")
	return rows
