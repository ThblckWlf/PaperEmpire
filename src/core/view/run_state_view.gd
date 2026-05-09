extends RefCounted
class_name RunStateView


static func createTopBarData(runState: RunState) -> Dictionary:
	if runState == null:
		return {}

	return {
		"gold": int(runState.resources.get("gold", 0)),
		"food": int(runState.resources.get("food", 0)),
		"threat": int(runState.resources.get("threat", 0)),
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
		"goldPerMonth": country.goldPerMonth,
		"foodPerMonth": country.foodPerMonth,
		"defense": country.defense,
		"stationedArmyCount": stationedArmyCount,
		"stationedUnitCount": stationedUnitCount,
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
