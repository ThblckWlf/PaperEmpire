extends RefCounted
class_name NewRunFactory


const MINI_GOAL_SIMULATION := preload("res://src/core/simulation/mini_goal_simulation.gd")
const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")

const DEFAULT_START_COUNTRY_ID: StringName = &"usa"
const START_GOLD: int = 150
const START_FOOD: int = 100
const START_INFANTRY: int = 30
const START_CAVALRY: int = 6
const START_ARTILLERY: int = 2

const SMALL_DEFENSE_INFANTRY: int = 20
const SMALL_DEFENSE_CAVALRY: int = 5
const SMALL_DEFENSE_ARTILLERY: int = 2
const MEDIUM_DEFENSE_INFANTRY: int = 40
const MEDIUM_DEFENSE_CAVALRY: int = 10
const MEDIUM_DEFENSE_ARTILLERY: int = 4
const LARGE_DEFENSE_INFANTRY: int = 70
const LARGE_DEFENSE_CAVALRY: int = 15
const LARGE_DEFENSE_ARTILLERY: int = 8


static func createNewRun(
	startCountryId: StringName = DEFAULT_START_COUNTRY_ID,
	metaProgressData: Dictionary = {},
	metaUpgradeRows: Array[Dictionary] = []
) -> RunState:
	var runState := RunState.new()
	runState.time = GameTime.createInitialState()
	var countries := PrototypeContentLoader.loadCountries()
	var hasStartCountry := false

	for sourceCountry in countries:
		var country := _copyCountry(sourceCountry)
		if country.id == startCountryId:
			country.ownerId = GameIds.PLAYER_OWNER_ID
			hasStartCountry = true
		elif country.ownerId == GameIds.PLAYER_OWNER_ID:
			country.ownerId = GameIds.NEUTRAL_OWNER_ID

		runState.countries[country.id] = country

	runState.resources = {
		"gold": START_GOLD,
		"food": START_FOOD,
		"threat": 0,
	}
	runState.speed = GameSpeed.Value.Normal
	runState.miniGoals = MINI_GOAL_SIMULATION.initializeGoals(PrototypeContentLoader.loadMiniGoals())

	if hasStartCountry:
		runState.runStatus = RunState.RUN_STATUS_ACTIVE
		runState.armies[&"army_start"] = _createStartingArmy(startCountryId)
		_createInitialDefendingArmies(runState)
		META_PROGRESS_SIMULATION.applyStartingBonuses(runState, startCountryId, metaProgressData, metaUpgradeRows)
	else:
		runState.runStatus = RunState.RUN_STATUS_NOT_STARTED
		push_error("Cannot create run. Unknown start country: %s" % startCountryId)

	return runState


static func _copyCountry(source: CountryData) -> CountryData:
	var country := CountryData.new()
	country.id = source.id
	country.name = source.name
	country.ownerId = source.ownerId
	country.goldPerMonth = source.goldPerMonth
	country.foodPerMonth = source.foodPerMonth
	country.defense = source.defense
	country.center = source.center
	country.neighbors = []
	for neighborId in source.neighbors:
		country.neighbors.append(neighborId)
	return country


static func _createStartingArmy(startCountryId: StringName) -> ArmyData:
	var army := ArmyData.new()
	army.id = &"army_start"
	army.ownerId = GameIds.PLAYER_OWNER_ID
	army.locationCountryId = startCountryId
	army.targetCountryId = GameIds.EMPTY_ID
	army.units = {
		GameIds.INFANTRY_UNIT_ID: START_INFANTRY,
		GameIds.CAVALRY_UNIT_ID: START_CAVALRY,
		GameIds.ARTILLERY_UNIT_ID: START_ARTILLERY,
	}
	army.status = ArmyStatus.Value.Stationed
	army.movementProgress = 0.0
	return army


static func _createInitialDefendingArmies(runState: RunState) -> void:
	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := runState.countries[countryId] as CountryData
		if country == null or country.ownerId == GameIds.PLAYER_OWNER_ID:
			continue

		var army := ArmyData.new()
		army.id = StringName("army_def_%s" % str(country.id))
		army.ownerId = country.ownerId
		army.locationCountryId = country.id
		army.targetCountryId = GameIds.EMPTY_ID
		army.units = _defenseUnitsForCountry(country)
		army.status = ArmyStatus.Value.Stationed
		army.movementProgress = 0.0
		runState.armies[army.id] = army
		runState.aiGoldByCountry[country.id] = 0


static func _defenseUnitsForCountry(country: CountryData) -> Dictionary:
	if country.defense > 700:
		return {
			GameIds.INFANTRY_UNIT_ID: LARGE_DEFENSE_INFANTRY,
			GameIds.CAVALRY_UNIT_ID: LARGE_DEFENSE_CAVALRY,
			GameIds.ARTILLERY_UNIT_ID: LARGE_DEFENSE_ARTILLERY,
		}

	if country.defense >= 300:
		return {
			GameIds.INFANTRY_UNIT_ID: MEDIUM_DEFENSE_INFANTRY,
			GameIds.CAVALRY_UNIT_ID: MEDIUM_DEFENSE_CAVALRY,
			GameIds.ARTILLERY_UNIT_ID: MEDIUM_DEFENSE_ARTILLERY,
		}

	return {
		GameIds.INFANTRY_UNIT_ID: SMALL_DEFENSE_INFANTRY,
		GameIds.CAVALRY_UNIT_ID: SMALL_DEFENSE_CAVALRY,
		GameIds.ARTILLERY_UNIT_ID: SMALL_DEFENSE_ARTILLERY,
	}
