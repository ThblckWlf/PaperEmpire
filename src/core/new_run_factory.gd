extends RefCounted
class_name NewRunFactory


const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")
const RUN_STATS_SIMULATION := preload("res://src/core/simulation/run_stats_simulation.gd")

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

const SMALL_AI_AGGRESSION: float = 0.25
const MEDIUM_AI_AGGRESSION: float = 0.35
const LARGE_AI_AGGRESSION: float = 0.45
const SMALL_AI_EXPANSION_DESIRE: float = 0.25
const MEDIUM_AI_EXPANSION_DESIRE: float = 0.35
const LARGE_AI_EXPANSION_DESIRE: float = 0.45
const DEFAULT_AI_ATTACK_COOLDOWN_MONTHS: int = 2


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
			country.ownerId = GameIds.npcOwnerIdForCountry(country.id)
		elif country.ownerId == GameIds.NEUTRAL_OWNER_ID:
			country.ownerId = GameIds.npcOwnerIdForCountry(country.id)
		_configureAiCountryDefaults(country)

		runState.countries[country.id] = country

	runState.resources = {
		"gold": START_GOLD,
		"food": START_FOOD,
		"threat": 0,
	}
	runState.speed = GameSpeed.Value.Normal
	runState.miniGoals = []

	if hasStartCountry:
		runState.runStatus = RunState.RUN_STATUS_ACTIVE
		runState.armies[&"army_start"] = _createStartingArmy(startCountryId)
		_createInitialDefendingArmies(runState)
		META_PROGRESS_SIMULATION.applyStartingBonuses(runState, startCountryId, metaProgressData, metaUpgradeRows)
		RUN_STATS_SIMULATION.initializeForRun(runState)
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
	country.aiCooldownMonths = source.aiCooldownMonths
	country.isUnderAttack = source.isUnderAttack
	country.aiAggression = source.aiAggression
	country.aiExpansionDesire = source.aiExpansionDesire
	country.aiAttackCooldownMonths = source.aiAttackCooldownMonths
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
		if not runState.aiGoldByOwner.has(country.ownerId):
			runState.aiGoldByOwner[country.ownerId] = 0


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


static func _configureAiCountryDefaults(country: CountryData) -> void:
	if country.ownerId == GameIds.PLAYER_OWNER_ID:
		country.aiCooldownMonths = 0
		country.isUnderAttack = false
		return

	country.aiCooldownMonths = 0
	country.isUnderAttack = false
	country.aiAttackCooldownMonths = DEFAULT_AI_ATTACK_COOLDOWN_MONTHS
	if country.defense >= 34 or country.ownerId == GameIds.WORLD_OWNER_ID:
		country.aiAggression = LARGE_AI_AGGRESSION
		country.aiExpansionDesire = LARGE_AI_EXPANSION_DESIRE
	elif country.defense >= 30:
		country.aiAggression = MEDIUM_AI_AGGRESSION
		country.aiExpansionDesire = MEDIUM_AI_EXPANSION_DESIRE
	else:
		country.aiAggression = SMALL_AI_AGGRESSION
		country.aiExpansionDesire = SMALL_AI_EXPANSION_DESIRE
