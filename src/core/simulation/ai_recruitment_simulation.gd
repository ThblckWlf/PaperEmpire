extends RefCounted
class_name AiRecruitmentSimulation


const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")

const AI_POWER_CAP_MULTIPLIER: float = 10.0
const MAX_UNITS_PER_OWNER_PER_MONTH: int = 6
const MAX_UNITS_PER_COUNTRY_PER_MONTH: int = 2
const PLAYER_THREAT_POWER_RATIO: float = 0.8
const MIN_INFANTRY_MASS: int = 8


static func applyMonthTick(runState: RunState, units: Array[UnitData]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if runState == null:
		return events

	_migrateLegacyCountryGoldIfNeeded(runState)
	var countriesByOwner := _countriesByOwner(runState)
	var ownerIds := countriesByOwner.keys()
	ownerIds.sort()

	for ownerIdValue in ownerIds:
		var ownerId := StringName(str(ownerIdValue))
		var countries: Array = countriesByOwner.get(ownerId, [])
		var storedGold := maxi(0, int(runState.aiGoldByOwner.get(ownerId, 0)))
		runState.aiGoldByOwner[ownerId] = storedGold + _monthlyGoldIncome(countries)

	for ownerIdValue in ownerIds:
		var ownerId := StringName(str(ownerIdValue))
		var countries: Array = countriesByOwner.get(ownerId, [])
		var ownerFoodIncome := _monthlyFoodIncome(countries)
		var ownerFoodUpkeep := _ownerFoodUpkeep(runState, ownerId, units)
		var ownerBoughtUnits := 0
		var candidates := _recruitmentCandidates(runState, countries, units)

		for candidate in candidates:
			if ownerBoughtUnits >= MAX_UNITS_PER_OWNER_PER_MONTH:
				break

			var countryId := StringName(str(candidate.get("countryId", GameIds.EMPTY_ID)))
			var country := runState.countries.get(countryId, null) as CountryData
			if country == null or country.ownerId != ownerId:
				continue

			var army := _localRecruitmentArmy(runState, country)
			if army == null:
				if _isCountryUnderAttack(runState, country.id):
					continue

				var createResult: Dictionary = RECRUITMENT_SIMULATION.createArmyForOwner(
					runState,
					country.id,
					country.ownerId
				)
				if not bool(createResult.get("accepted", false)):
					continue
				army = runState.armies[StringName(str(createResult.get("armyId", "")))] as ArmyData
				createResult["ownerId"] = country.ownerId
				createResult["aiGold"] = int(runState.aiGoldByOwner.get(ownerId, 0))
				events.append({
					"eventType": EventType.ARMY_CREATED,
					"payload": createResult,
				})

			var beforeUnits := army.units.duplicate(true)
			var spendResult := _spendOwnerGoldOnArmy(
				runState,
				ownerId,
				country,
				army,
				units,
				ownerFoodIncome,
				ownerFoodUpkeep,
				bool(candidate.get("ignoreFood", false)),
				MAX_UNITS_PER_OWNER_PER_MONTH - ownerBoughtUnits
			)
			ownerBoughtUnits += int(spendResult.get("boughtUnits", 0))
			ownerFoodUpkeep = int(spendResult.get("ownerFoodUpkeep", ownerFoodUpkeep))
			if beforeUnits != army.units:
				events.append({
					"eventType": EventType.ARMY_UPDATED,
					"payload": {
						"armyId": army.id,
						"countryId": country.id,
						"ownerId": ownerId,
						"units": army.units.duplicate(true),
						"aiGold": int(runState.aiGoldByOwner.get(ownerId, 0)),
					},
				})
	return events


static func _spendOwnerGoldOnArmy(
	runState: RunState,
	ownerId: StringName,
	country: CountryData,
	army: ArmyData,
	units: Array[UnitData],
	ownerFoodIncome: int,
	ownerFoodUpkeep: int,
	ignoreFood: bool,
	remainingOwnerLimit: int
) -> Dictionary:
	var result := {
		"boughtUnits": 0,
		"ownerFoodUpkeep": ownerFoodUpkeep,
	}
	var localLimit := mini(MAX_UNITS_PER_COUNTRY_PER_MONTH, remainingOwnerLimit)
	if localLimit <= 0:
		return result

	var maxArmyPower := _localPowerTarget(country)
	var unitCatalog := _unitCatalogById(units)
	var boughtUnits := 0
	while boughtUnits < localLimit:
		var currentPower := COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {})
		if currentPower >= maxArmyPower:
			break

		var ownerGold := maxi(0, int(runState.aiGoldByOwner.get(ownerId, 0)))
		var unit := _nextRecruitUnit(army, unitCatalog, ownerGold, ownerFoodIncome, ownerFoodUpkeep, ignoreFood)
		if unit == null:
			break

		army.units[unit.id] = int(army.units.get(unit.id, 0)) + 1
		runState.aiGoldByOwner[ownerId] = ownerGold - unit.cost
		ownerFoodUpkeep += unit.foodUpkeep
		boughtUnits += 1

	result["boughtUnits"] = boughtUnits
	result["ownerFoodUpkeep"] = ownerFoodUpkeep
	return result


static func _nextRecruitUnit(
	army: ArmyData,
	unitCatalog: Dictionary,
	ownerGold: int,
	ownerFoodIncome: int,
	ownerFoodUpkeep: int,
	ignoreFood: bool
) -> UnitData:
	var recruitmentOrder := _recruitmentUnitOrder(army, unitCatalog)
	for unitId in recruitmentOrder:
		var unit := unitCatalog.get(unitId, null) as UnitData
		if unit == null:
			continue
		if ownerGold < unit.cost:
			continue
		if not ignoreFood and ownerFoodIncome - (ownerFoodUpkeep + unit.foodUpkeep) < 0:
			continue
		return unit
	return null


static func _recruitmentUnitOrder(army: ArmyData, unitCatalog: Dictionary) -> Array[StringName]:
	var infantry := _unitAmount(army.units, GameIds.INFANTRY_UNIT_ID)
	var cavalry := _unitAmount(army.units, GameIds.CAVALRY_UNIT_ID)
	var artillery := _unitAmount(army.units, GameIds.ARTILLERY_UNIT_ID)
	var artilleryUnit := unitCatalog.get(GameIds.ARTILLERY_UNIT_ID, null) as UnitData
	var supportInfantryPerArtillery := 2
	if artilleryUnit != null:
		supportInfantryPerArtillery = maxi(1, int(artilleryUnit.bonuses.get("supportInfantryPerArtillery", 2)))

	if infantry < MIN_INFANTRY_MASS or infantry < artillery * supportInfantryPerArtillery:
		return [
			GameIds.INFANTRY_UNIT_ID,
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
		]

	if cavalry * 4 < infantry:
		return [
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
			GameIds.INFANTRY_UNIT_ID,
		]

	return [
		GameIds.ARTILLERY_UNIT_ID,
		GameIds.CAVALRY_UNIT_ID,
		GameIds.INFANTRY_UNIT_ID,
	]


static func _recruitmentCandidates(runState: RunState, countries: Array, units: Array[UnitData]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var globalFoodException := int(runState.resources.get("threat", 0)) >= THREAT_SIMULATION.CRITICAL_THRESHOLD
	for countryValue in countries:
		var country := countryValue as CountryData
		if country == null:
			continue

		var localPower := _localArmyPower(runState, country, units)
		var localTarget := _localPowerTarget(country)
		if localPower >= localTarget:
			continue

		var immediateDanger := _isCountryInImmediateDanger(runState, country, units)
		candidates.append({
			"countryId": country.id,
			"powerRatio": localPower / maxf(localTarget, 1.0),
			"immediateDanger": immediateDanger,
			"ignoreFood": globalFoodException or immediateDanger,
		})
	candidates.sort_custom(_sortRecruitmentCandidate)
	return candidates


static func _countriesByOwner(runState: RunState) -> Dictionary:
	var countriesByOwner := {}
	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := runState.countries[countryId] as CountryData
		if country == null or not _isAiOwner(country.ownerId):
			continue

		if not countriesByOwner.has(country.ownerId):
			countriesByOwner[country.ownerId] = []
		(countriesByOwner[country.ownerId] as Array).append(country)
		if not runState.aiGoldByOwner.has(country.ownerId):
			runState.aiGoldByOwner[country.ownerId] = 0
	return countriesByOwner


static func _monthlyGoldIncome(countries: Array) -> int:
	var income := 0
	for countryValue in countries:
		var country := countryValue as CountryData
		if country != null:
			income += maxi(0, country.goldPerMonth)
	return income


static func _monthlyFoodIncome(countries: Array) -> int:
	var income := 0
	for countryValue in countries:
		var country := countryValue as CountryData
		if country != null:
			income += country.foodPerMonth
	return income


static func _ownerFoodUpkeep(runState: RunState, ownerId: StringName, units: Array[UnitData]) -> int:
	var unitCatalog := _unitCatalogById(units)
	var upkeep := 0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != ownerId or army.status == ArmyStatus.Value.Defeated:
			continue

		for unitIdValue in army.units.keys():
			var unitId := StringName(str(unitIdValue))
			var unit := unitCatalog.get(unitId, null) as UnitData
			if unit == null:
				continue
			upkeep += maxi(0, int(army.units.get(unitIdValue, 0))) * unit.foodUpkeep
	return upkeep


static func _localRecruitmentArmy(runState: RunState, country: CountryData) -> ArmyData:
	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.ownerId != country.ownerId:
			continue

		if army.locationCountryId != country.id:
			continue

		if army.status != ArmyStatus.Value.Stationed:
			continue

		return army
	return null


static func _localArmyPower(runState: RunState, country: CountryData, units: Array[UnitData]) -> float:
	var power := 0.0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != country.ownerId or army.locationCountryId != country.id:
			continue
		if army.status == ArmyStatus.Value.Defeated or army.status == ArmyStatus.Value.Moving or army.status == ArmyStatus.Value.Attacking:
			continue

		power += COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {})
	return maxf(power, 0.0)


static func _localDefensePower(runState: RunState, country: CountryData, units: Array[UnitData]) -> float:
	var power := COMBAT_SIMULATION.calculateCountryDefensePower(country, {}, runState.worldReaction)
	power += _localArmyPower(runState, country, units)
	return maxf(power, 1.0)


static func _localPowerTarget(country: CountryData) -> float:
	if country == null:
		return 1.0
	return maxf(float(country.defense) * AI_POWER_CAP_MULTIPLIER, 1.0)


static func _isCountryInImmediateDanger(runState: RunState, country: CountryData, units: Array[UnitData]) -> bool:
	if _isCountryUnderAttack(runState, country.id):
		return true

	var localDefensePower := _localDefensePower(runState, country, units)
	for neighborId in country.neighbors:
		var neighbor := runState.countries.get(neighborId, null) as CountryData
		if neighbor == null or neighbor.ownerId != GameIds.PLAYER_OWNER_ID:
			continue

		var playerPower := _stationedPlayerPowerInCountry(runState, neighbor.id, country.defense, units)
		if playerPower >= localDefensePower * PLAYER_THREAT_POWER_RATIO:
			return true
	return false


static func _stationedPlayerPowerInCountry(
	runState: RunState,
	countryId: StringName,
	targetDefense: int,
	units: Array[UnitData]
) -> float:
	var power := 0.0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue
		if army.ownerId != GameIds.PLAYER_OWNER_ID or army.locationCountryId != countryId:
			continue
		if army.status != ArmyStatus.Value.Stationed:
			continue

		power += COMBAT_SIMULATION.calculateArmyCombatPower(army, units, runState.economy, {
			"targetDefense": targetDefense,
		})
	return power


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
		if battle != null and int(battle.get("status")) == BattleStatus.Value.Active and StringName(str(battle.get("targetCountryId"))) == countryId:
			return true
	return false


static func _migrateLegacyCountryGoldIfNeeded(runState: RunState) -> void:
	if not runState.aiGoldByOwner.is_empty() or runState.aiGoldByCountry.is_empty():
		return

	for countryIdValue in runState.aiGoldByCountry.keys():
		var countryId := StringName(str(countryIdValue))
		var country := runState.countries.get(countryId, null) as CountryData
		if country == null or not _isAiOwner(country.ownerId):
			continue

		var gold := maxi(0, int(runState.aiGoldByCountry.get(countryIdValue, 0)))
		runState.aiGoldByOwner[country.ownerId] = int(runState.aiGoldByOwner.get(country.ownerId, 0)) + gold


static func _isAiOwner(ownerId: StringName) -> bool:
	return ownerId != GameIds.PLAYER_OWNER_ID and ownerId != GameIds.EMPTY_ID


static func _unitCatalogById(units: Array[UnitData]) -> Dictionary:
	var catalog := {}
	for unit in units:
		catalog[unit.id] = unit
	return catalog


static func _unitAmount(units: Dictionary, unitId: StringName) -> int:
	return maxi(0, int(units.get(unitId, units.get(str(unitId), 0))))


static func _sortRecruitmentCandidate(left: Dictionary, right: Dictionary) -> bool:
	var leftDanger := bool(left.get("immediateDanger", false))
	var rightDanger := bool(right.get("immediateDanger", false))
	if leftDanger != rightDanger:
		return leftDanger

	var leftRatio := float(left.get("powerRatio", 1.0))
	var rightRatio := float(right.get("powerRatio", 1.0))
	if not is_equal_approx(leftRatio, rightRatio):
		return leftRatio < rightRatio

	return str(left.get("countryId", "")) < str(right.get("countryId", ""))
