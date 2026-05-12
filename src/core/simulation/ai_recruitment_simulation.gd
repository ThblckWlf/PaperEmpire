extends RefCounted
class_name AiRecruitmentSimulation


const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")

const AI_POWER_CAP_MULTIPLIER: float = 40.0
const AI_RECRUITMENT_UNIT_ORDER := [
	GameIds.INFANTRY_UNIT_ID,
	GameIds.CAVALRY_UNIT_ID,
	GameIds.ARTILLERY_UNIT_ID,
]


static func applyMonthTick(runState: RunState, units: Array[UnitData]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if runState == null:
		return events

	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := runState.countries[countryId] as CountryData
		if country == null or country.ownerId == GameIds.PLAYER_OWNER_ID:
			continue
		if country.isUnderAttack:
			continue

		var storedGold := int(runState.aiGoldByCountry.get(country.id, 0))
		storedGold += maxi(0, country.goldPerMonth)
		runState.aiGoldByCountry[country.id] = storedGold

		var army := _localDefendingArmy(runState, country)
		if army == null:
			var createResult: Dictionary = RECRUITMENT_SIMULATION.createArmyForOwner(
				runState,
				country.id,
				country.ownerId
			)
			if not bool(createResult.get("accepted", false)):
				continue
			army = runState.armies[StringName(str(createResult.get("armyId", "")))] as ArmyData
			events.append({
				"eventType": EventType.ARMY_CREATED,
				"payload": createResult,
			})

		var beforeUnits := army.units.duplicate(true)
		_spendAiGoldOnArmy(runState, country, army, units)
		if beforeUnits != army.units:
			events.append({
				"eventType": EventType.ARMY_UPDATED,
				"payload": {
					"armyId": army.id,
					"countryId": country.id,
					"units": army.units.duplicate(true),
					"aiGold": int(runState.aiGoldByCountry.get(country.id, 0)),
				},
			})
	return events


static func _spendAiGoldOnArmy(
	runState: RunState,
	country: CountryData,
	army: ArmyData,
	units: Array[UnitData]
) -> void:
	var maxArmyPower := maxf(float(country.defense) * AI_POWER_CAP_MULTIPLIER, 1.0)
	var currentPower := COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {})
	if currentPower >= maxArmyPower:
		return

	var unitCatalog := _unitCatalogById(units)
	var safetyCounter := 0
	while safetyCounter < 128:
		safetyCounter += 1
		var boughtUnit := false
		for unitId in AI_RECRUITMENT_UNIT_ORDER:
			if COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {}) >= maxArmyPower:
				return

			var unit := unitCatalog.get(unitId, null) as UnitData
			if unit == null:
				continue

			var aiGold := int(runState.aiGoldByCountry.get(country.id, 0))
			if aiGold < unit.cost:
				continue

			army.units[unit.id] = int(army.units.get(unit.id, 0)) + 1
			runState.aiGoldByCountry[country.id] = aiGold - unit.cost
			boughtUnit = true

		if not boughtUnit:
			return


static func _localDefendingArmy(runState: RunState, country: CountryData) -> ArmyData:
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

		if army.status == ArmyStatus.Value.Defeated or army.status == ArmyStatus.Value.Moving or army.status == ArmyStatus.Value.Attacking:
			continue

		return army
	return null


static func _unitCatalogById(units: Array[UnitData]) -> Dictionary:
	var catalog := {}
	for unit in units:
		catalog[unit.id] = unit
	return catalog
