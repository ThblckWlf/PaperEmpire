extends RefCounted
class_name EconomySimulation


const FOOD_SHORTAGE_MALUS_MONTHS: int = 1
const FOOD_SHORTAGE_COMBAT_MULTIPLIER: float = 0.7


static func calculateMonthlyIncome(runState: RunState) -> Dictionary:
	var income := {
		"gold": 0,
		"food": 0,
	}
	if runState == null:
		return income

	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country == null or country.ownerId != GameIds.PLAYER_OWNER_ID:
			continue

		income["gold"] = int(income["gold"]) + country.goldPerMonth
		income["food"] = int(income["food"]) + country.foodPerMonth
	return income


static func calculateArmyFoodUpkeep(runState: RunState, units: Array[UnitData]) -> int:
	if runState == null:
		return 0

	var rawUpkeep := _playerRawFoodUpkeep(runState, units)
	var multiplier := float(runState.upgradeEffects.get("foodUpkeepMultiplier", 1.0))
	return maxi(0, int(ceil(float(rawUpkeep) * multiplier)))


static func calculateUnitFoodUpkeepRaw(unitCounts: Dictionary, units: Array[UnitData]) -> int:
	var unitCatalog := _unitCatalogById(units)
	var upkeep := 0
	for unitIdValue in unitCounts.keys():
		var unitId := StringName(str(unitIdValue))
		var unit := unitCatalog.get(unitId, null) as UnitData
		if unit != null:
			upkeep += maxi(0, int(unitCounts.get(unitIdValue, 0))) * unit.foodUpkeep
	return upkeep


static func calculateFoodStatus(runState: RunState, units: Array[UnitData]) -> Dictionary:
	var income := calculateMonthlyIncome(runState)
	var rawUpkeep := _playerRawFoodUpkeep(runState, units)
	var multiplier := float(runState.upgradeEffects.get("foodUpkeepMultiplier", 1.0)) if runState != null else 1.0
	var upkeep := maxi(0, int(ceil(float(rawUpkeep) * multiplier)))
	var foodIncome := int(income.get("food", 0))
	var netFood := foodIncome - upkeep
	var currentFood := int(runState.resources.get("food", 0)) if runState != null else 0
	return {
		"food": currentFood,
		"foodIncome": foodIncome,
		"foodUpkeep": upkeep,
		"netFood": netFood,
		"foodWarning": netFood < 0,
		"isFoodShortage": currentFood <= 0,
	}


static func calculateProjectedFoodStatus(
	runState: RunState,
	units: Array[UnitData],
	rawFoodUpkeepAdded: int
) -> Dictionary:
	var income := calculateMonthlyIncome(runState)
	var rawUpkeep := _playerRawFoodUpkeep(runState, units)
	var multiplier := float(runState.upgradeEffects.get("foodUpkeepMultiplier", 1.0)) if runState != null else 1.0
	var currentUpkeep := maxi(0, int(ceil(float(rawUpkeep) * multiplier)))
	var projectedUpkeep := maxi(0, int(ceil(float(rawUpkeep + maxi(0, rawFoodUpkeepAdded)) * multiplier)))
	var projectedFoodNet := int(income.get("food", 0)) - projectedUpkeep
	var currentFood := int(runState.resources.get("food", 0)) if runState != null else 0
	return {
		"food": currentFood,
		"foodIncome": int(income.get("food", 0)),
		"foodUpkeep": currentUpkeep,
		"netFood": int(income.get("food", 0)) - currentUpkeep,
		"foodUpkeepAdded": maxi(0, projectedUpkeep - currentUpkeep),
		"projectedFoodUpkeep": projectedUpkeep,
		"projectedFoodNet": projectedFoodNet,
		"foodWarning": projectedFoodNet < 0,
	}


static func applyMonthTick(runState: RunState, units: Array[UnitData]) -> Dictionary:
	var income := calculateMonthlyIncome(runState)
	var upkeep := calculateArmyFoodUpkeep(runState, units)
	var previousFood := int(runState.resources.get("food", 0))
	var nextFood := maxi(0, previousFood + int(income["food"]) - upkeep)
	var nextGold := int(runState.resources.get("gold", 0)) + int(income["gold"])

	runState.resources["gold"] = nextGold
	runState.resources["food"] = nextFood
	_updateFoodShortage(runState, nextFood)

	var result := {
		"goldIncome": int(income["gold"]),
		"foodIncome": int(income["food"]),
		"foodUpkeep": upkeep,
		"netFood": int(income["food"]) - upkeep,
		"foodWarning": int(income["food"]) - upkeep < 0,
		"gold": nextGold,
		"food": nextFood,
		"isFoodShortage": bool(runState.economy.get("isFoodShortage", false)),
		"foodShortageMonths": int(runState.economy.get("foodShortageMonths", 0)),
		"combatPowerMultiplier": float(runState.economy.get("combatPowerMultiplier", 1.0)),
	}
	runState.economy["lastMonthResult"] = result.duplicate()
	return result


static func _updateFoodShortage(runState: RunState, food: int) -> void:
	var isFoodShortage := food <= 0
	if isFoodShortage:
		runState.economy["foodShortageMonths"] = int(runState.economy.get("foodShortageMonths", 0)) + 1
	else:
		runState.economy["foodShortageMonths"] = 0

	var shortageMonths := int(runState.economy.get("foodShortageMonths", 0))
	runState.economy["isFoodShortage"] = isFoodShortage
	runState.economy["recruitmentBlocked"] = isFoodShortage
	runState.economy["healingBlocked"] = isFoodShortage
	runState.economy["combatPowerMultiplier"] = FOOD_SHORTAGE_COMBAT_MULTIPLIER if shortageMonths >= FOOD_SHORTAGE_MALUS_MONTHS else 1.0


static func _unitCatalogById(units: Array[UnitData]) -> Dictionary:
	var catalog := {}
	for unit in units:
		catalog[unit.id] = unit
	return catalog


static func _playerRawFoodUpkeep(runState: RunState, units: Array[UnitData]) -> int:
	if runState == null:
		return 0

	var upkeep := 0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID:
			continue

		upkeep += calculateUnitFoodUpkeepRaw(army.units, units)
	return upkeep
