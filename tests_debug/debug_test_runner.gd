extends Node
class_name DebugTestRunner


var totalTests: int = 0
var failedTests: int = 0
var capturedEvents: Array[Dictionary] = []
const RUN_STATE_VIEW := preload("res://src/core/view/run_state_view.gd")
const ECONOMY_SIMULATION := preload("res://src/core/simulation/economy_simulation.gd")
const ARMY_MOVEMENT_SIMULATION := preload("res://src/core/simulation/army_movement_simulation.gd")
const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const MINI_GOAL_SIMULATION := preload("res://src/core/simulation/mini_goal_simulation.gd")
const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")
const SHOP_STATE_VIEW := preload("res://src/core/view/shop_state_view.gd")
const SHOP_PANEL_SCRIPT := preload("res://scenes/ui/shop_panel.gd")
const META_UPGRADE_DATA_VALIDATOR := preload("res://src/core/validation/meta_upgrade_data_validator.gd")
const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const META_PROGRESS := preload("res://src/save/meta_progress.gd")
const RUN_STATE_SERIALIZER := preload("res://src/save/run_state_serializer.gd")

var lastShopUpgradeId: StringName = GameIds.EMPTY_ID


func _ready() -> void:
	runAll()


func runAll() -> void:
	totalTests = 0
	failedTests = 0

	_runTest("CountryData valid fixture passes", _testValidCountries)
	_runTest("CountryData invalid fixture fails", _testInvalidCountries)
	_runTest("UnitData MVP catalog passes", _testValidUnits)
	_runTest("UnitData invalid fixture fails", _testInvalidUnits)
	_runTest("RunState valid fixture passes", _testValidRunState)
	_runTest("RunState invalid fixture fails", _testInvalidRunState)
	_runTest("Prototype units fixture loads and validates", _testPrototypeUnitsFixture)
	_runTest("Prototype countries fixture loads and validates", _testPrototypeCountriesFixture)
	_runTest("Prototype upgrades fixture loads and validates", _testPrototypeUpgradesFixture)
	_runTest("UpgradeData invalid fixture fails", _testInvalidUpgrades)
	_runTest("Prototype mini goals fixture loads and validates", _testPrototypeMiniGoalsFixture)
	_runTest("MiniGoalData invalid fixture fails", _testInvalidMiniGoals)
	_runTest("Prototype meta upgrades fixture loads and validates", _testPrototypeMetaUpgradesFixture)
	_runTest("Prototype map shapes fixture loads and validates", _testPrototypeMapShapesFixture)
	_runTest("NewRunFactory creates valid prototype run", _testNewRunFactory)
	_runTest("GameManager commands update state and emit events", _testGameManagerCommands)
	_runTest("GameTime advances deterministically", _testGameTimeAdvances)
	_runTest("SimulationManager applies speed and emits monthTick", _testSimulationManagerTicks)
	_runTest("EconomySimulation calculates income and upkeep", _testEconomyCalculatesIncomeAndUpkeep)
	_runTest("EconomySimulation applies month tick and shortage", _testEconomyAppliesMonthTickAndShortage)
	_runTest("ArmyMovementSimulation validates and advances movement", _testArmyMovementValidatesAndAdvances)
	_runTest("GameManager move army command emits events", _testGameManagerMoveArmyCommand)
	_runTest("RecruitmentSimulation applies recruitment rules", _testRecruitmentAppliesRules)
	_runTest("GameManager recruit and create army commands emit events", _testGameManagerRecruitAndCreateArmyCommands)
	_runTest("CombatSimulation calculates combat power", _testCombatCalculatesPower)
	_runTest("CombatSimulation starts valid attacks only", _testCombatStartsValidAttacks)
	_runTest("SimulationManager completes battle and conquest", _testSimulationCompletesBattleAndConquest)
	_runTest("UpgradeSimulation rolls choices and applies effects", _testUpgradeRollsChoicesAndAppliesEffects)
	_runTest("Upgrade modal applies one selected upgrade", _testUpgradeModalAppliesSelectedUpgrade)
	_runTest("ThreatSimulation applies passive and action threat", _testThreatAppliesPassiveAndActionThreat)
	_runTest("Threat UI summaries expose warning states", _testThreatUiSummariesExposeWarningStates)
	_runTest("MiniGoalSimulation tracks progress and rewards", _testMiniGoalsTrackProgressAndRewards)
	_runTest("MiniGoal panel claims completed reward", _testMiniGoalPanelClaimsReward)
	_runTest("WorldMap creates country and army nodes", _testWorldMapCreatesCountryAndArmyNodes)
	_runTest("MapCamera clamps pan and zoom", _testMapCameraClampsPanAndZoom)
	_runTest("RunStateView creates UI summaries", _testRunStateViewCreatesSummaries)
	_runTest("Main UI layout binds state and commands", _testMainUiLayoutBindsStateAndCommands)
	_runTest("EffectsLayer reacts to event feedback", _testEffectsLayerReactsToEventFeedback)
	_runTest("AudioManager creates buses and sound stubs", _testAudioManagerCreatesBusesAndSoundStubs)
	_runTest("SaveFormat defines versioned save schema", _testSaveFormatDefinesVersionedSchema)
	_runTest("RunStateSerializer writes pure data", _testRunStateSerializerWritesPureData)
	_runTest("SaveManager writes and loads user saves", _testSaveManagerWritesAndLoadsUserSaves)
	_runTest("Manual save load UI restores run state", _testManualSaveLoadUiRestoresRunState)
	_runTest("MetaProgress stores upgrade state", _testMetaProgressStoresUpgradeState)
	_runTest("MetaProgress awards crowns and applies purchases", _testMetaProgressAwardsCrownsAndAppliesPurchases)
	_runTest("Shop panel sends purchase commands", _testShopPanelSendsPurchaseCommands)

	if failedTests == 0:
		print("[DebugTestRunner] PASS: %d/%d tests passed." % [totalTests, totalTests])
	else:
		push_error("[DebugTestRunner] FAIL: %d/%d tests failed." % [failedTests, totalTests])


func _runTest(testName: String, testCallable: Callable) -> void:
	totalTests += 1
	var result := testCallable.call() as ValidationResult
	if result.isValid():
		print("[DebugTestRunner] PASS: %s" % testName)
	else:
		failedTests += 1
		push_error("[DebugTestRunner] FAIL: %s" % testName)
		for error in result.errors:
			push_error("  - %s" % error)


func _testValidCountries() -> ValidationResult:
	return CountryDataValidator.validate(_createValidCountries(), _validOwnerIds())


func _testInvalidCountries() -> ValidationResult:
	var invalidCountries: Array[CountryData] = _createValidCountries()
	var missingNeighbors: Array[StringName] = [&"missing"]
	var noNeighbors: Array[StringName] = []
	invalidCountries.append(_createCountry(&"paperland", "Paperland Copy", GameIds.PLAYER_OWNER_ID, Vector2(50.0, 50.0), missingNeighbors))
	var invalidCountry := _createCountry(GameIds.EMPTY_ID, "", &"invalid_owner", Vector2.ZERO, noNeighbors)
	invalidCountry.goldPerMonth = -1
	invalidCountries.append(invalidCountry)

	var result := CountryDataValidator.validate(invalidCountries, _validOwnerIds())
	return _expectFailure(result)


func _testValidUnits() -> ValidationResult:
	return UnitDataValidator.validate(MvpUnitCatalog.createUnits())


func _testInvalidUnits() -> ValidationResult:
	var invalidUnits: Array[UnitData] = MvpUnitCatalog.createUnits()
	var invalidUnit := UnitData.new()
	invalidUnit.id = &"tank"
	invalidUnit.name = "Tank"
	invalidUnit.cost = -5
	invalidUnit.combatPower = 0
	invalidUnit.foodUpkeep = -1
	invalidUnit.moveSpeed = 0.0
	invalidUnits.append(invalidUnit)

	var result := UnitDataValidator.validate(invalidUnits)
	return _expectFailure(result)


func _testValidRunState() -> ValidationResult:
	return RunStateValidator.validate(_createValidRunState())


func _testInvalidRunState() -> ValidationResult:
	var runState := _createValidRunState()
	runState.speed = 3
	runState.resources["threat"] = NAN
	var army := runState.armies[&"army_1"] as ArmyData
	army.locationCountryId = &"missing_country"

	var result := RunStateValidator.validate(runState)
	return _expectFailure(result)


func _testPrototypeUnitsFixture() -> ValidationResult:
	return UnitDataValidator.validate(PrototypeContentLoader.loadUnits())


func _testPrototypeCountriesFixture() -> ValidationResult:
	return CountryDataValidator.validate(PrototypeContentLoader.loadCountries(), _validOwnerIds())


func _testPrototypeUpgradesFixture() -> ValidationResult:
	return UpgradeDataValidator.validate(PrototypeContentLoader.loadUpgrades())


func _testInvalidUpgrades() -> ValidationResult:
	var invalidUpgrades := PrototypeContentLoader.loadUpgrades()
	invalidUpgrades.append({
		"id": "",
		"name": "",
		"description": "",
		"rarity": "mythic",
		"effectType": "moveSpeedMultiplier",
		"value": 0,
	})
	return _expectFailure(UpgradeDataValidator.validate(invalidUpgrades))


func _testPrototypeMiniGoalsFixture() -> ValidationResult:
	return MiniGoalDataValidator.validate(PrototypeContentLoader.loadMiniGoals())


func _testInvalidMiniGoals() -> ValidationResult:
	var invalidGoals := PrototypeContentLoader.loadMiniGoals()
	invalidGoals.append({
		"id": "",
		"name": "",
		"description": "",
		"goalType": "unknown",
		"progressRule": "",
		"target": 0,
		"rewardType": "permanentUnlock",
		"rewardValue": 0,
	})
	return _expectFailure(MiniGoalDataValidator.validate(invalidGoals))


func _testPrototypeMetaUpgradesFixture() -> ValidationResult:
	return META_UPGRADE_DATA_VALIDATOR.validate(PrototypeContentLoader.loadMetaUpgrades(), PrototypeContentLoader.loadCountries())


func _testPrototypeMapShapesFixture() -> ValidationResult:
	var result := ValidationResult.new()
	var countries := PrototypeContentLoader.loadCountries()
	var shapes := PrototypeContentLoader.loadMapShapes()
	var boundsByCountry := {}

	for country in countries:
		if not shapes.has(country.id):
			result.addError("Map shape missing for country: %s." % country.id)
			continue

		var points: PackedVector2Array = shapes[country.id]
		if points.size() < 3:
			result.addError("Map shape has fewer than 3 points for country: %s." % country.id)
			continue

		boundsByCountry[country.id] = _countryShapeBounds(country.center, points)

	var countryIds := boundsByCountry.keys()
	countryIds.sort()
	for leftIndex in range(countryIds.size()):
		for rightIndex in range(leftIndex + 1, countryIds.size()):
			var leftId: StringName = countryIds[leftIndex]
			var rightId: StringName = countryIds[rightIndex]
			var leftBounds: Rect2 = boundsByCountry[leftId]
			var rightBounds: Rect2 = boundsByCountry[rightId]
			if leftBounds.intersects(rightBounds):
				result.addError("Map shapes overlap: %s and %s." % [leftId, rightId])

	return result


func _testNewRunFactory() -> ValidationResult:
	var runState := NewRunFactory.createNewRun(&"paperland")
	var result := RunStateValidator.validate(runState)

	if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
		result.addError("New run is not active.")

	if not runState.countries.has(&"paperland"):
		result.addError("New run does not contain start country.")
	else:
		var startCountry := runState.countries[&"paperland"] as CountryData
		if startCountry.ownerId != GameIds.PLAYER_OWNER_ID:
			result.addError("Start country is not owned by player.")

	if not runState.armies.has(&"army_start"):
		result.addError("New run does not contain starting army.")
	else:
		var army := runState.armies[&"army_start"] as ArmyData
		if int(army.units.get(GameIds.ARTILLERY_UNIT_ID, 0)) != NewRunFactory.START_ARTILLERY:
			result.addError("Starting army does not contain artillery.")

	if int(runState.resources.get("gold", 0)) != NewRunFactory.START_GOLD:
		result.addError("New run has wrong starting gold.")

	if int(runState.resources.get("food", 0)) != NewRunFactory.START_FOOD:
		result.addError("New run has wrong starting food.")

	if runState.miniGoals.is_empty():
		result.addError("New run has no mini goals.")

	return result


func _testGameManagerCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)

	manager.startNewRun("paperland")
	if not manager.hasActiveRun():
		result.addError("GameManager did not create an active run.")

	manager.submitCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "inkreich",
	})
	if manager.getSelectedCountryId() != &"inkreich":
		result.addError("select_country did not update selectedCountryId.")

	manager.submitCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Fast,
	})
	if manager.getCurrentRunState().speed != GameSpeed.Value.Fast:
		result.addError("set_game_speed did not update speed.")
	if simulation.getGameSpeed() != GameSpeed.Value.Fast:
		result.addError("set_game_speed did not update SimulationManager speed.")

	manager.submitCommand(CommandType.PAUSE_GAME)
	if manager.getCurrentRunState().speed != GameSpeed.Value.Paused:
		result.addError("pause_game did not pause the run.")

	manager.submitCommand(CommandType.RESUME_GAME)
	if manager.getCurrentRunState().speed != GameSpeed.Value.Normal:
		result.addError("resume_game did not resume normal speed.")

	manager.submitCommand(CommandType.RESET_RUN, {
		"startCountryId": "foldmark",
	})
	if manager.getSelectedCountryId() != &"foldmark":
		result.addError("reset_run did not update selectedCountryId.")
	if simulation.getRunState() != manager.getCurrentRunState():
		result.addError("reset_run did not update SimulationManager run state.")

	if not _capturedEvent(EventType.RUN_STARTED):
		result.addError("GameManager did not emit runStarted.")

	if not _capturedEvent(EventType.COUNTRY_SELECTED):
		result.addError("GameManager did not emit countrySelected.")

	if not _capturedEvent(EventType.GAME_SPEED_CHANGED):
		result.addError("GameManager did not emit gameSpeedChanged.")

	if not _capturedEvent(EventType.RUN_RESET):
		result.addError("GameManager did not emit runReset.")

	manager.free()
	simulation.free()
	bus.free()
	return result


func _testGameTimeAdvances() -> ValidationResult:
	var result := ValidationResult.new()
	var time := GameTime.createInitialState()

	var monthTicks := GameTime.advance(time, GameTime.SECONDS_PER_WEEK_AT_1X)
	if monthTicks != 0:
		result.addError("GameTime emitted month tick after one week.")
	if int(time.get("week", 0)) != 2:
		result.addError("GameTime did not advance to week 2.")
	if int(time.get("month", 0)) != 1:
		result.addError("GameTime changed month too early.")

	monthTicks = GameTime.advance(time, GameTime.SECONDS_PER_WEEK_AT_1X * 3.0)
	if monthTicks != 1:
		result.addError("GameTime did not emit one month tick after four weeks.")
	if int(time.get("week", 0)) != 1:
		result.addError("GameTime did not wrap week after one month.")
	if int(time.get("month", 0)) != 2:
		result.addError("GameTime did not advance to month 2.")

	monthTicks = GameTime.advance(time, GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH * 11.0)
	if monthTicks != 11:
		result.addError("GameTime did not emit remaining year month ticks.")
	if int(time.get("month", 0)) != 1:
		result.addError("GameTime did not wrap month after one year.")
	if int(time.get("year", 0)) != 2:
		result.addError("GameTime did not advance to year 2.")

	return result


func _testSimulationManagerTicks() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	simulation.configure(runState, bus)

	simulation.setGameSpeed(GameSpeed.Value.Paused)
	simulation.stepSimulation(60.0)
	if GameTime.getElapsedSeconds(runState.time) != 0.0:
		result.addError("Paused SimulationManager advanced time.")

	simulation.setGameSpeed(GameSpeed.Value.Normal)
	simulation.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X)
	if int(runState.time.get("week", 0)) != 2:
		result.addError("SimulationManager did not advance one week at 1x.")

	simulation.setGameSpeed(GameSpeed.Value.Fast)
	simulation.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * 1.5)
	if int(runState.time.get("month", 0)) != 2:
		result.addError("SimulationManager did not apply 2x speed to reach month 2.")

	simulation.setGameSpeed(GameSpeed.Value.VeryFast)
	simulation.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X)
	if int(runState.time.get("month", 0)) != 3:
		result.addError("SimulationManager did not apply 4x speed to reach month 3.")

	if not _capturedEvent(EventType.MONTH_TICK):
		result.addError("SimulationManager did not emit monthTick.")

	var pendingEvents := simulation.collectPendingEvents()
	if pendingEvents.is_empty():
		result.addError("SimulationManager did not store pending events.")

	simulation.free()
	bus.free()
	return result


func _testEconomyCalculatesIncomeAndUpkeep() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var income: Dictionary = ECONOMY_SIMULATION.calculateMonthlyIncome(runState)
	var upkeep: int = ECONOMY_SIMULATION.calculateArmyFoodUpkeep(runState, PrototypeContentLoader.loadUnits())
	if int(income.get("gold", 0)) != 35:
		result.addError("EconomySimulation calculated wrong gold income.")
	if int(income.get("food", 0)) != 24:
		result.addError("EconomySimulation calculated wrong food income.")
	if upkeep != 17:
		result.addError("EconomySimulation calculated wrong army food upkeep.")
	return result


func _testEconomyAppliesMonthTickAndShortage() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var monthResult: Dictionary = ECONOMY_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	if int(runState.resources.get("gold", 0)) != NewRunFactory.START_GOLD + 35:
		result.addError("EconomySimulation did not apply monthly gold income.")
	if int(runState.resources.get("food", 0)) != NewRunFactory.START_FOOD + 24 - 17:
		result.addError("EconomySimulation did not apply food income and upkeep.")
	if int(monthResult.get("foodUpkeep", 0)) != 17:
		result.addError("EconomySimulation month result missing upkeep.")

	runState.resources["food"] = 0
	var army := runState.armies[&"army_start"] as ArmyData
	army.units[GameIds.INFANTRY_UNIT_ID] = 1000
	ECONOMY_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	ECONOMY_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	if not bool(runState.economy.get("isFoodShortage", false)):
		result.addError("EconomySimulation did not set food shortage flag.")
	if not bool(runState.economy.get("recruitmentBlocked", false)):
		result.addError("EconomySimulation did not set recruitment block flag.")
	if not bool(runState.economy.get("healingBlocked", false)):
		result.addError("EconomySimulation did not set healing block flag.")
	if not is_equal_approx(float(runState.economy.get("combatPowerMultiplier", 1.0)), ECONOMY_SIMULATION.FOOD_SHORTAGE_COMBAT_MULTIPLIER):
		result.addError("EconomySimulation did not apply food shortage combat malus.")
	return result


func _testArmyMovementValidatesAndAdvances() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var invalidMove: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(runState, &"army_start", &"graphia")
	if bool(invalidMove.get("accepted", false)):
		result.addError("ArmyMovementSimulation accepted a non-neighbor move.")

	var move: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(runState, &"army_start", &"inkreich")
	if not bool(move.get("accepted", false)):
		result.addError("ArmyMovementSimulation rejected a neighbor move.")

	var army := runState.armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Moving:
		result.addError("ArmyMovementSimulation did not set moving status.")
	if army.targetCountryId != &"inkreich":
		result.addError("ArmyMovementSimulation did not set target country.")

	var completedEarly: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 0.5)
	if not completedEarly.is_empty():
		result.addError("ArmyMovementSimulation completed movement too early.")
	if not is_equal_approx(army.movementProgress, 0.5):
		result.addError("ArmyMovementSimulation did not advance progress deterministically.")

	var completed: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 0.5)
	if completed.size() != 1:
		result.addError("ArmyMovementSimulation did not report completed move.")
	if army.locationCountryId != &"inkreich":
		result.addError("ArmyMovementSimulation did not update location.")
	if army.status != ArmyStatus.Value.Stationed:
		result.addError("ArmyMovementSimulation did not restore stationed status.")
	return result


func _testGameManagerMoveArmyCommand() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")

	bus.requestCommand(CommandType.MOVE_ARMY, {
		"armyId": "army_start",
		"targetCountryId": "inkreich",
	})
	var army := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Moving:
		result.addError("move_army command did not start army movement.")
	if manager.getSelectedArmyId() != &"army_start":
		result.addError("move_army command did not preserve selected army.")
	if not _capturedEvent(EventType.ARMY_MOVE_STARTED):
		result.addError("move_army command did not emit armyMoveStarted.")

	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE)
	if army.locationCountryId != &"inkreich":
		result.addError("SimulationManager did not complete army movement.")
	if not _capturedEvent(EventType.ARMY_MOVED):
		result.addError("SimulationManager did not emit armyMoved.")

	manager.free()
	simulation.free()
	bus.free()
	return result


func _testRecruitmentAppliesRules() -> ValidationResult:
	var result := ValidationResult.new()
	var units := PrototypeContentLoader.loadUnits()
	var infantry := _unitFromCatalog(GameIds.INFANTRY_UNIT_ID)
	var cost: Dictionary = RECRUITMENT_SIMULATION.calculateRecruitmentCost(infantry, 2)
	if int(cost.get("goldCost", 0)) != 100:
		result.addError("RecruitmentSimulation calculated wrong infantry gold cost.")
	if int(cost.get("foodReserveRequired", 0)) != 2:
		result.addError("RecruitmentSimulation calculated wrong infantry food reserve.")

	var runState := NewRunFactory.createNewRun(&"paperland")
	var recruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(
		runState,
		&"paperland",
		GameIds.CAVALRY_UNIT_ID,
		1,
		units,
		&"army_start"
	)
	if not bool(recruit.get("accepted", false)):
		result.addError("RecruitmentSimulation rejected valid recruitment.")

	var army := runState.armies[&"army_start"] as ArmyData
	if int(runState.resources.get("gold", 0)) != NewRunFactory.START_GOLD - 90:
		result.addError("RecruitmentSimulation did not spend gold.")
	if int(army.units.get(GameIds.CAVALRY_UNIT_ID, 0)) != NewRunFactory.START_CAVALRY + 1:
		result.addError("RecruitmentSimulation did not add recruited units.")

	var enemyRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"inkreich", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(enemyRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation accepted recruitment in non-owned country.")

	runState.resources["gold"] = 10
	var expensiveRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"paperland", GameIds.ARTILLERY_UNIT_ID, 1, units, &"army_start")
	if bool(expensiveRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation accepted recruitment without enough gold.")

	runState.resources["gold"] = 1000
	runState.resources["food"] = 0
	var noFoodRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"paperland", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(noFoodRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation accepted recruitment without food reserve.")

	runState.resources["food"] = 100
	runState.economy["recruitmentBlocked"] = true
	var blockedRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"paperland", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(blockedRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation ignored recruitmentBlocked.")
	return result


func _testGameManagerRecruitAndCreateArmyCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")

	bus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": "paperland",
		"unitType": "infantry",
		"amount": 1,
	})
	var army := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	if int(manager.getCurrentRunState().resources.get("gold", 0)) != NewRunFactory.START_GOLD - 50:
		result.addError("recruit_units command did not spend gold.")
	if int(army.units.get(GameIds.INFANTRY_UNIT_ID, 0)) != NewRunFactory.START_INFANTRY + 1:
		result.addError("recruit_units command did not add infantry.")
	if not _capturedEvent(EventType.UNITS_RECRUITED):
		result.addError("recruit_units command did not emit unitsRecruited.")

	var previousArmyCount := manager.getCurrentRunState().armies.size()
	bus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": "paperland",
	})
	if manager.getCurrentRunState().armies.size() != previousArmyCount + 1:
		result.addError("create_army command did not add an army.")
	if manager.getSelectedArmyId() == &"army_start":
		result.addError("create_army command did not select the new army.")
	if not _capturedEvent(EventType.ARMY_CREATED):
		result.addError("create_army command did not emit armyCreated.")

	var validation := RunStateValidator.validate(manager.getCurrentRunState())
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Created army produced invalid RunState: %s" % error)

	manager.free()
	simulation.free()
	bus.free()
	return result


func _testCombatCalculatesPower() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var army := runState.armies[&"army_start"] as ArmyData
	var targetCountry := runState.countries[&"inkreich"] as CountryData
	var power := COMBAT_SIMULATION.calculateArmyCombatPower(army, PrototypeContentLoader.loadUnits(), runState.economy, {
		"targetDefense": targetCountry.defense,
	})
	var expectedPower := 178.0
	if not is_equal_approx(power, expectedPower):
		result.addError("CombatSimulation calculated wrong army power: %s." % power)

	runState.economy["combatPowerMultiplier"] = 0.8
	var malusPower := COMBAT_SIMULATION.calculateArmyCombatPower(army, PrototypeContentLoader.loadUnits(), runState.economy, {
		"targetDefense": targetCountry.defense,
	})
	if not is_equal_approx(malusPower, expectedPower * 0.8):
		result.addError("CombatSimulation did not apply food combat malus.")

	var defensePower := COMBAT_SIMULATION.calculateCountryDefensePower(targetCountry)
	if not is_equal_approx(defensePower, float(targetCountry.defense) * COMBAT_SIMULATION.COUNTRY_DEFENSE_POWER_MULTIPLIER):
		result.addError("CombatSimulation calculated wrong country defense power.")
	return result


func _testCombatStartsValidAttacks() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var invalidAttack: Dictionary = COMBAT_SIMULATION.startAttack(runState, &"army_start", &"graphia", PrototypeContentLoader.loadUnits())
	if bool(invalidAttack.get("accepted", false)):
		result.addError("CombatSimulation accepted a non-neighbor attack.")

	var attack: Dictionary = COMBAT_SIMULATION.startAttack(runState, &"army_start", &"inkreich", PrototypeContentLoader.loadUnits())
	if not bool(attack.get("accepted", false)):
		result.addError("CombatSimulation rejected a valid attack.")
	if not runState.battles.has(StringName(str(attack.get("battleId", "")))):
		result.addError("CombatSimulation did not create BattleData.")

	var army := runState.armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Attacking:
		result.addError("CombatSimulation did not set attacker status.")
	if army.targetCountryId != &"inkreich":
		result.addError("CombatSimulation did not set attacker target.")

	var secondAttack: Dictionary = COMBAT_SIMULATION.startAttack(runState, &"army_start", &"foldmark", PrototypeContentLoader.loadUnits())
	if bool(secondAttack.get("accepted", false)):
		result.addError("CombatSimulation accepted an attack from a non-stationed army.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Combat start produced invalid RunState: %s" % error)
	return result


func _testSimulationCompletesBattleAndConquest() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")

	bus.requestCommand(CommandType.START_ATTACK, {
		"armyId": "army_start",
		"targetCountryId": "inkreich",
	})
	if not _capturedEvent(EventType.BATTLE_STARTED):
		result.addError("start_attack command did not emit battleStarted.")

	var army := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Attacking:
		result.addError("start_attack command did not set army attacking.")

	simulation.stepSimulation(COMBAT_SIMULATION.BATTLE_DURATION_SECONDS)
	var targetCountry := manager.getCurrentRunState().countries[&"inkreich"] as CountryData
	if targetCountry.ownerId != GameIds.PLAYER_OWNER_ID:
		result.addError("SimulationManager did not conquer target country.")
	if army.locationCountryId != &"inkreich":
		result.addError("Conquering army did not station in target country.")
	if army.status != ArmyStatus.Value.Stationed:
		result.addError("Conquering army did not return to stationed status.")
	if _unitCount(army.units) < 0:
		result.addError("Combat casualties produced negative unit count.")
	if not _capturedEvent(EventType.BATTLE_ENDED):
		result.addError("SimulationManager did not emit battleEnded.")
	if not _capturedEvent(EventType.COUNTRY_CONQUERED):
		result.addError("SimulationManager did not emit countryConquered.")
	if not _capturedEvent(EventType.UPGRADE_CHOICE_OPENED):
		result.addError("Conquest did not open upgrade choices.")
	if not bool(manager.getCurrentRunState().activeUpgradeChoice.get("isOpen", false)):
		result.addError("Conquest did not store active upgrade choice in RunState.")
	if int(manager.getCurrentRunState().speed) != GameSpeed.Value.Paused:
		result.addError("Upgrade choice did not pause the run.")

	var validation := RunStateValidator.validate(manager.getCurrentRunState())
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Battle completion produced invalid RunState: %s" % error)

	manager.free()
	simulation.free()
	bus.free()
	return result


func _testUpgradeRollsChoicesAndAppliesEffects() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var choices: Dictionary = UPGRADE_SIMULATION.rollUpgradeChoices(runState, PrototypeContentLoader.loadUpgrades())
	if not bool(choices.get("opened", false)):
		result.addError("UpgradeSimulation did not open choices.")
	var choiceRows: Array = choices.get("choices", [])
	if choiceRows.size() != UPGRADE_SIMULATION.CHOICE_COUNT:
		result.addError("UpgradeSimulation did not roll exactly three choices.")
	if _hasDuplicateUpgradeIds(choiceRows):
		result.addError("UpgradeSimulation rolled duplicate choices.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"rapidRecruitment")]}
	var rapid: Dictionary = UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"rapidRecruitment")
	if not bool(rapid.get("accepted", false)):
		result.addError("UpgradeSimulation rejected recruitment discount.")
	var infantry := _unitFromCatalog(GameIds.INFANTRY_UNIT_ID)
	var discountedCost: Dictionary = RECRUITMENT_SIMULATION.calculateRecruitmentCost(infantry, 1, runState.upgradeEffects)
	if int(discountedCost.get("goldCost", 0)) != 45:
		result.addError("Recruitment discount did not change recruitment cost.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"efficientSupply")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"efficientSupply")
	var upkeep := ECONOMY_SIMULATION.calculateArmyFoodUpkeep(runState, PrototypeContentLoader.loadUnits())
	if upkeep != 16:
		result.addError("Food upkeep upgrade did not reduce upkeep.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"warChest")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"warChest")
	var reward: Dictionary = UPGRADE_SIMULATION.applyConquestReward(runState, &"inkreich")
	if int(reward.get("goldReward", 0)) != 85:
		result.addError("Conquest gold upgrade did not increase reward.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"quietWars")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"quietWars")
	var threat: Dictionary = UPGRADE_SIMULATION.applyWarThreat(runState)
	if int(threat.get("threatAdded", 0)) != 3:
		result.addError("War threat upgrade did not reduce threat gain.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"strongFronts")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"strongFronts")
	var ownedCountry := runState.countries[&"paperland"] as CountryData
	var defensePower := COMBAT_SIMULATION.calculateCountryDefensePower(ownedCountry, runState.upgradeEffects)
	if not is_equal_approx(defensePower, float(ownedCountry.defense) * COMBAT_SIMULATION.COUNTRY_DEFENSE_POWER_MULTIPLIER * 1.15):
		result.addError("Defense upgrade did not change owned country defense power.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Upgrade effects produced invalid RunState: %s" % error)
	return result


func _testUpgradeModalAppliesSelectedUpgrade() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for upgrade modal test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var eventBus := main.get_node("GameRoot/Managers/EventBus") as EventBus
	var uiRoot = main.get_node("GameRoot/UIRoot")
	var modalLayer = main.get_node("GameRoot/UIRoot/Root/ModalLayer")
	var upgradeModal = main.get_node("GameRoot/UIRoot/Root/ModalLayer/UpgradeModal")
	var choiceButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/UpgradeModal/MarginContainer/VBoxContainer/ChoiceButton1") as Button
	var choices := [
		_upgradeById(&"rapidRecruitment"),
		_upgradeById(&"warChest"),
		_upgradeById(&"efficientSupply"),
	]
	gameManager.getCurrentRunState().activeUpgradeChoice = {
		"isOpen": true,
		"choices": choices,
	}
	eventBus.raiseGameEvent(EventType.UPGRADE_CHOICE_OPENED, {
		"choices": choices,
	})
	if not bool(modalLayer.visible) or not bool(upgradeModal.visible):
		result.addError("Upgrade modal did not open from event.")

	choiceButton.emit_signal("pressed")
	if not gameManager.getCurrentRunState().upgrades.has(&"rapidRecruitment"):
		result.addError("Upgrade modal choice did not apply selected upgrade.")
	if bool(upgradeModal.visible):
		result.addError("Upgrade modal did not close after selection.")
	if bool(uiRoot.call("isEscMenuOpen")):
		result.addError("Upgrade modal left ESC menu marked open.")

	_cleanupMainForTest(main)
	return result


func _testThreatAppliesPassiveAndActionThreat() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	simulation.configure(runState, bus)

	simulation.setGameSpeed(GameSpeed.Value.Paused)
	simulation.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH)
	if int(runState.resources.get("threat", 0)) != 0:
		result.addError("Paused run gained passive threat.")

	simulation.setGameSpeed(GameSpeed.Value.Normal)
	simulation.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH)
	if int(runState.resources.get("threat", 0)) != THREAT_SIMULATION.PASSIVE_THREAT_PER_MONTH:
		result.addError("Running run did not gain passive monthly threat.")
	if not _capturedEvent(EventType.THREAT_CHANGED):
		result.addError("Passive threat did not emit threatChanged.")

	runState.upgradeEffects["warThreatMultiplier"] = 0.85
	var warThreat: Dictionary = THREAT_SIMULATION.applyActionThreat(runState, THREAT_SIMULATION.ACTION_WAR_STARTED)
	if int(warThreat.get("threatAdded", 0)) != 3:
		result.addError("War threat multiplier did not reduce action threat.")

	var army := runState.armies[&"army_start"] as ArmyData
	army.units[GameIds.INFANTRY_UNIT_ID] = 60
	var largeArmyThreat: Dictionary = THREAT_SIMULATION.applyMonthlyThreat(runState)
	if int(largeArmyThreat.get("largeArmyThreat", 0)) <= 0:
		result.addError("Large army did not add threat.")

	runState.resources["threat"] = THREAT_SIMULATION.CRITICAL_THRESHOLD
	var reaction: Dictionary = THREAT_SIMULATION.updateWorldReaction(runState)
	if str(reaction.get("level", "")) != "mobilized":
		result.addError("World reaction did not reach mobilized at critical threat.")
	if not bool(reaction.get("counterAttackPrepared", false)):
		result.addError("World reaction did not prepare counterattack stub.")

	var enemyCountry := runState.countries[&"inkreich"] as CountryData
	var enemyDefensePower := COMBAT_SIMULATION.calculateCountryDefensePower(enemyCountry, {}, runState.worldReaction)
	var expectedDefensePower := float(enemyCountry.defense) * COMBAT_SIMULATION.COUNTRY_DEFENSE_POWER_MULTIPLIER * 1.25
	if not is_equal_approx(enemyDefensePower, expectedDefensePower):
		result.addError("World reaction did not boost enemy defense power.")

	simulation.free()
	bus.free()
	return result


func _testThreatUiSummariesExposeWarningStates() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	runState.resources["threat"] = 55
	var topBarData: Dictionary = RUN_STATE_VIEW.createTopBarData(runState)
	if str(topBarData.get("threatState", "")) != "high":
		result.addError("RunStateView did not expose high threat state.")

	runState.resources["threat"] = 80
	topBarData = RUN_STATE_VIEW.createTopBarData(runState)
	if str(topBarData.get("threatState", "")) != "critical":
		result.addError("RunStateView did not expose critical threat state.")
	return result


func _testMiniGoalsTrackProgressAndRewards() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var units := PrototypeContentLoader.loadUnits()

	MINI_GOAL_SIMULATION.updateProgress(runState, EventType.COUNTRY_CONQUERED, {"countryId": "inkreich"}, units)
	var conquerGoal := _miniGoalById(runState, &"conquerThreeCountries")
	if int(conquerGoal.get("progress", 0)) != 1:
		result.addError("MiniGoal conquerCountries did not advance on conquest.")
	var lowThreatGoal := _miniGoalById(runState, &"lowThreatWin")
	if int(lowThreatGoal.get("progress", 0)) != 1:
		result.addError("MiniGoal conquerWithThreatBelow did not advance below threat limit.")

	runState.resources["gold"] = 550
	MINI_GOAL_SIMULATION.updateProgress(runState, EventType.MONTH_TICK, {}, units)
	var goldGoal := _miniGoalById(runState, &"reachGold")
	if not bool(goldGoal.get("isCompleted", false)):
		result.addError("MiniGoal reachGold did not complete from resources.")

	var armyGoal := _miniGoalById(runState, &"fieldArmy")
	if not bool(armyGoal.get("isCompleted", false)):
		result.addError("MiniGoal reachArmyPower did not complete from army power.")

	MINI_GOAL_SIMULATION.updateProgress(runState, EventType.BATTLE_ENDED, {
		"attackerWon": true,
		"attackerPower": 20.0,
		"defenderPower": 40.0,
	}, units)
	var hardTargetGoal := _miniGoalById(runState, &"hardTarget")
	if not bool(hardTargetGoal.get("isCompleted", false)):
		result.addError("MiniGoal defeatStrongerCountry did not complete from battle payload.")

	runState.resources["threat"] = THREAT_SIMULATION.CAUTION_THRESHOLD
	for _index in range(3):
		MINI_GOAL_SIMULATION.updateProgress(runState, EventType.MONTH_TICK, {}, units)
	var holdGoal := _miniGoalById(runState, &"holdBorder")
	if not bool(holdGoal.get("isCompleted", false)):
		result.addError("MiniGoal holdThreatenedCountryMonths did not complete after threatened months.")

	MINI_GOAL_SIMULATION.updateProgress(runState, EventType.COUNTRY_CONQUERED, {"countryId": "foldmark"}, units)
	MINI_GOAL_SIMULATION.updateProgress(runState, EventType.COUNTRY_CONQUERED, {"countryId": "vellum"}, units)
	conquerGoal = _miniGoalById(runState, &"conquerThreeCountries")
	if not bool(conquerGoal.get("isCompleted", false)):
		result.addError("MiniGoal conquerCountries did not complete at target.")

	var previousGold := int(runState.resources.get("gold", 0))
	var reward: Dictionary = MINI_GOAL_SIMULATION.claimReward(runState, &"conquerThreeCountries")
	if not bool(reward.get("accepted", false)):
		result.addError("MiniGoal reward claim rejected completed goal.")
	if int(runState.resources.get("gold", 0)) != previousGold + 150:
		result.addError("MiniGoal gold reward was not applied.")
	var secondClaim: Dictionary = MINI_GOAL_SIMULATION.claimReward(runState, &"conquerThreeCountries")
	if bool(secondClaim.get("accepted", false)):
		result.addError("MiniGoal reward could be claimed twice.")

	var boostReward: Dictionary = MINI_GOAL_SIMULATION.claimReward(runState, &"hardTarget")
	if not bool(boostReward.get("accepted", false)):
		result.addError("MiniGoal upgrade rarity reward was rejected.")
	if int(runState.miniGoalState.get("upgradeRarityBoost", 0)) != 1:
		result.addError("MiniGoal upgrade rarity reward did not update state.")

	var choices: Dictionary = UPGRADE_SIMULATION.rollUpgradeChoices(runState, PrototypeContentLoader.loadUpgrades())
	var choiceRows: Array = choices.get("choices", [])
	if choiceRows.is_empty() or str((choiceRows[0] as Dictionary).get("rarity", "")) != "rare":
		result.addError("MiniGoal rarity boost did not affect next upgrade choice.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("MiniGoal progress produced invalid RunState: %s" % error)
	return result


func _testMiniGoalPanelClaimsReward() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for mini goal panel test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var eventBus := main.get_node("GameRoot/Managers/EventBus") as EventBus
	var goalButton := main.get_node("GameRoot/UIRoot/Root/MiniGoalPanel/MarginContainer/VBoxContainer/GoalButton1") as Button
	var runState := gameManager.getCurrentRunState()
	runState.miniGoals[0]["progress"] = float(runState.miniGoals[0].get("target", 1))
	runState.miniGoals[0]["isCompleted"] = true
	eventBus.raiseGameEvent(EventType.THREAT_CHANGED, {})
	if goalButton.disabled:
		result.addError("MiniGoal panel did not enable claim button for completed goal.")

	var previousGold := int(runState.resources.get("gold", 0))
	goalButton.emit_signal("pressed")
	if int(runState.resources.get("gold", 0)) != previousGold + int(runState.miniGoals[0].get("rewardValue", 0)):
		result.addError("MiniGoal panel claim did not apply reward.")
	if not bool(runState.miniGoals[0].get("isRewardClaimed", false)):
		result.addError("MiniGoal panel claim did not mark reward claimed.")

	_cleanupMainForTest(main)
	return result


func _testWorldMapCreatesCountryAndArmyNodes() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/world/WorldMap.tscn") as PackedScene
	if scene == null:
		result.addError("WorldMap.tscn could not be loaded.")
		return result

	var worldMap = scene.instantiate()
	if worldMap == null:
		result.addError("WorldMap.tscn could not be instantiated.")
		return result

	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	add_child(worldMap)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")
	worldMap.configure(manager, bus)

	var runState := manager.getCurrentRunState()
	if worldMap.getCountryNodeCount() != runState.countries.size():
		result.addError("WorldMap did not create a CountryNode for every country.")
	if worldMap.getArmyNodeCount() != runState.armies.size():
		result.addError("WorldMap did not create an ArmyNode for every army.")
	if worldMap.getArmyNode(&"army_start") == null:
		result.addError("WorldMap did not expose the starting ArmyNode.")

	bus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": "paperland",
	})
	if worldMap.getArmyNodeCount() != runState.armies.size():
		result.addError("WorldMap did not refresh ArmyNodes after army creation.")

	bus.requestCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "inkreich",
	})
	var inkreichNode = worldMap.getCountryNode(&"inkreich")
	if inkreichNode == null:
		result.addError("WorldMap did not expose inkreich CountryNode.")
	elif not bool(inkreichNode.get("isSelected")):
		result.addError("WorldMap did not update CountryNode selection from command event.")

	remove_child(worldMap)
	worldMap.free()
	manager.free()
	simulation.free()
	bus.free()
	return result


func _testMapCameraClampsPanAndZoom() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/world/WorldMap.tscn") as PackedScene
	if scene == null:
		result.addError("WorldMap.tscn could not be loaded for camera test.")
		return result

	var worldMap = scene.instantiate()
	add_child(worldMap)
	var camera = worldMap.get_node("MapCamera")
	if camera == null:
		result.addError("WorldMap has no MapCamera node.")
		return result

	if not camera.has_method("setZoomScalar") or not camera.has_method("panBy"):
		result.addError("MapCamera does not expose expected camera control methods.")
		return result

	camera.setMapBounds(Rect2(Vector2(50.0, 180.0), Vector2(420.0, 320.0)))
	camera.setZoomScalar(99.0)
	if not is_equal_approx(float(camera.getZoomScalar()), float(camera.getMaxZoom())):
		result.addError("MapCamera did not clamp max zoom.")

	camera.setZoomScalar(0.1)
	if not is_equal_approx(float(camera.getZoomScalar()), float(camera.getMinZoom())):
		result.addError("MapCamera did not clamp min zoom.")

	camera.panBy(Vector2(100000.0, -100000.0))
	var movementBounds: Rect2 = camera.getMovementBounds()
	var cameraPosition: Vector2 = camera.position
	if (
		cameraPosition.x < movementBounds.position.x
		or cameraPosition.x > movementBounds.end.x
		or cameraPosition.y < movementBounds.position.y
		or cameraPosition.y > movementBounds.end.y
	):
		result.addError("MapCamera pan escaped movement bounds.")

	remove_child(worldMap)
	worldMap.free()
	return result


func _testRunStateViewCreatesSummaries() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	var topBarData: Dictionary = RUN_STATE_VIEW.createTopBarData(runState)
	if int(topBarData.get("gold", 0)) != NewRunFactory.START_GOLD:
		result.addError("RunStateView top bar gold is wrong.")
	if int(topBarData.get("food", 0)) != NewRunFactory.START_FOOD:
		result.addError("RunStateView top bar food is wrong.")
	if int(topBarData.get("armyStrength", 0)) != NewRunFactory.START_INFANTRY + NewRunFactory.START_CAVALRY + NewRunFactory.START_ARTILLERY:
		result.addError("RunStateView army strength summary is wrong.")
	if str(topBarData.get("dateText", "")) != "Y1 M1 W1":
		result.addError("RunStateView date text is wrong.")

	var countryData: Dictionary = RUN_STATE_VIEW.createCountryPanelData(runState, &"paperland")
	if str(countryData.get("name", "")) != "Paperland":
		result.addError("RunStateView country panel name is wrong.")
	if int(countryData.get("stationedArmyCount", 0)) != 1:
		result.addError("RunStateView stationed army count is wrong.")
	if not bool(countryData.get("canRecruit", false)):
		result.addError("RunStateView did not mark owned country as recruitable.")

	var armyData: Dictionary = RUN_STATE_VIEW.createArmyPanelData(runState, &"army_start")
	if str(armyData.get("status", "")) != "Stationed":
		result.addError("RunStateView army panel status is wrong.")
	if str(armyData.get("location", "")) != "Paperland":
		result.addError("RunStateView army panel location is wrong.")
	return result


func _testMainUiLayoutBindsStateAndCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for UI test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var eventBus := main.get_node("GameRoot/Managers/EventBus") as EventBus
	var simulationManager := main.get_node("GameRoot/Managers/SimulationManager") as SimulationManager
	var uiRoot = main.get_node("GameRoot/UIRoot")
	var topBar = main.get_node("GameRoot/UIRoot/Root/TopBar")
	var leftPanel = main.get_node("GameRoot/UIRoot/Root/LeftPanel")
	var rightPanel = main.get_node("GameRoot/UIRoot/Root/RightPanel")
	var bottomBar = main.get_node("GameRoot/UIRoot/Root/BottomBar")
	var modalLayer = main.get_node("GameRoot/UIRoot/Root/ModalLayer")
	if uiRoot == null or topBar == null or leftPanel == null or rightPanel == null or bottomBar == null or modalLayer == null:
		result.addError("Main UI layout is missing required nodes.")
		_cleanupMainForTest(main)
		return result

	var goldLabel := main.get_node("GameRoot/UIRoot/Root/TopBar/MarginContainer/HBoxContainer/GoldLabel") as Label
	var startingGold := int(gameManager.getCurrentRunState().resources.get("gold", 0))
	if goldLabel.text != "Gold: %d" % startingGold:
		result.addError("TopBar did not bind starting gold.")

	var threatLabel := main.get_node("GameRoot/UIRoot/Root/TopBar/MarginContainer/HBoxContainer/ThreatLabel") as Label
	gameManager.getCurrentRunState().resources["threat"] = 55
	eventBus.raiseGameEvent(EventType.THREAT_CHANGED, {
		"threat": 55,
	})
	if threatLabel.text != "Threat: 55 (High)":
		result.addError("TopBar did not show high threat state.")

	var armyTitle := main.get_node("GameRoot/UIRoot/Root/LeftPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if armyTitle.text != "army_start":
		result.addError("ArmyPanel did not bind selected army.")

	var infantryButton := main.get_node("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/RecruitButtons/InfantryButton") as Button
	infantryButton.emit_signal("pressed")
	if goldLabel.text != "Gold: %d" % (startingGold - 50):
		result.addError("Recruit button did not update top bar gold.")

	eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Normal,
	})
	simulationManager.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH)
	if goldLabel.text != "Gold: %d" % (startingGold - 50 + 35):
		result.addError("TopBar did not update after month tick economy apply.")

	eventBus.requestCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "inkreich",
	})
	var countryTitle := main.get_node("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if countryTitle.text != "Inkreich":
		result.addError("CountryPanel did not update from country selection.")

	var pauseButton := main.get_node("GameRoot/UIRoot/Root/BottomBar/MarginContainer/HBoxContainer/PauseButton") as Button
	pauseButton.emit_signal("pressed")
	if gameManager.getCurrentRunState().speed != GameSpeed.Value.Paused:
		result.addError("TimeControls pause button did not request pause.")

	var shopButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/ShopButton") as Button
	var shopPanel = main.get_node("GameRoot/UIRoot/Root/ModalLayer/ShopPanel")
	if shopButton == null or shopPanel == null:
		result.addError("Shop UI is missing required nodes.")

	uiRoot.call("_openEscMenu")
	if not bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not open.")

	if shopButton != null:
		shopButton.emit_signal("pressed")
		if not bool(shopPanel.get("visible")):
			result.addError("Shop button did not open shop panel.")
		uiRoot.call("_closeShopPanel")

	uiRoot.call("_openEscMenu")
	uiRoot.call("_resumeFromEscMenu")
	if bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not close on resume.")
	if gameManager.getCurrentRunState().speed == GameSpeed.Value.Paused:
		result.addError("ESC menu resume did not restore speed.")

	_cleanupMainForTest(main)
	return result


func _testEffectsLayerReactsToEventFeedback() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/world/WorldMap.tscn") as PackedScene
	if scene == null:
		result.addError("WorldMap.tscn could not be loaded for effects test.")
		return result

	var worldMap = scene.instantiate()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	var audio := AudioManager.new()
	add_child(worldMap)
	add_child(audio)
	audio.configure(bus)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")
	worldMap.configure(manager, bus, audio)

	var effectsLayer = worldMap.get_node("EffectsLayer")
	if effectsLayer == null or not effectsLayer.has_method("getMovementFeedbackCount"):
		result.addError("EffectsLayer is missing expected feedback methods.")
		remove_child(worldMap)
		remove_child(audio)
		worldMap.free()
		audio.free()
		manager.free()
		simulation.free()
		bus.free()
		return result

	bus.requestCommand(CommandType.MOVE_ARMY, {
		"armyId": "army_start",
		"targetCountryId": "inkreich",
	})
	if int(effectsLayer.call("getMovementFeedbackCount")) != 1:
		result.addError("EffectsLayer did not create movement feedback after armyMoveStarted.")

	bus.raiseGameEvent(EventType.BATTLE_STARTED, {
		"battleId": "battle_visual_test",
		"armyId": "army_start",
		"sourceCountryId": "paperland",
		"targetCountryId": "inkreich",
	})
	if int(effectsLayer.call("getBattleFeedbackCount")) != 1:
		result.addError("EffectsLayer did not create battle pulse feedback.")

	bus.raiseGameEvent(EventType.BATTLE_ENDED, {
		"battleId": "battle_visual_test",
	})
	if int(effectsLayer.call("getBattleFeedbackCount")) != 0:
		result.addError("EffectsLayer did not remove battle pulse feedback after battleEnded.")

	var oneShotBefore := int(effectsLayer.call("getOneShotFeedbackCount"))
	bus.raiseGameEvent(EventType.COUNTRY_CONQUERED, {
		"countryId": "inkreich",
	})
	if int(effectsLayer.call("getOneShotFeedbackCount")) <= oneShotBefore:
		result.addError("EffectsLayer did not create conquest flash feedback.")

	oneShotBefore = int(effectsLayer.call("getOneShotFeedbackCount"))
	bus.raiseGameEvent(EventType.MISSILE_LAUNCHED, {
		"fromCountryId": "paperland",
		"targetCountryId": "inkreich",
	})
	if int(effectsLayer.call("getOneShotFeedbackCount")) <= oneShotBefore:
		result.addError("EffectsLayer did not spawn missile feedback.")

	remove_child(worldMap)
	remove_child(audio)
	worldMap.free()
	audio.free()
	manager.free()
	simulation.free()
	bus.free()
	return result


func _testAudioManagerCreatesBusesAndSoundStubs() -> ValidationResult:
	var result := ValidationResult.new()
	var bus := EventBus.new()
	var audio := AudioManager.new()
	add_child(audio)
	audio.configure(bus)

	for busName in [AudioManager.BUS_MASTER, AudioManager.BUS_MUSIC, AudioManager.BUS_SFX, AudioManager.BUS_UI]:
		if AudioServer.get_bus_index(str(busName)) < 0:
			result.addError("Audio bus missing: %s." % str(busName))

	audio.playSfx(AudioManager.SOUND_BATTLE_START)
	if audio.getActiveStubPlayerCount() <= 0:
		result.addError("AudioManager did not create a SFX stub player.")

	var playerCount := audio.getActiveStubPlayerCount()
	bus.raiseGameEvent(EventType.MISSILE_LAUNCHED, {})
	if audio.getActiveStubPlayerCount() <= playerCount:
		result.addError("AudioManager did not react to missileLaunched event.")

	audio.setBusMuted(AudioManager.BUS_SFX, true)
	var sfxBusIndex := AudioServer.get_bus_index(str(AudioManager.BUS_SFX))
	if sfxBusIndex >= 0 and not AudioServer.is_bus_mute(sfxBusIndex):
		result.addError("AudioManager did not mute the SFX bus.")
	audio.setBusMuted(AudioManager.BUS_SFX, false)

	remove_child(audio)
	audio.free()
	bus.free()
	return result


func _testSaveFormatDefinesVersionedSchema() -> ValidationResult:
	var result := ValidationResult.new()
	var metaData: Dictionary = META_PROGRESS.createDefaultData()
	if int(metaData.get("schemaVersion", 0)) != META_PROGRESS.SCHEMA_VERSION:
		result.addError("MetaProgress schemaVersion is missing.")
	if int(metaData.get("crowns", -1)) != 0:
		result.addError("MetaProgress default crowns are wrong.")
	if not META_PROGRESS.isValidDictionary(metaData):
		result.addError("MetaProgress default data does not validate.")

	var root := SAVE_FORMAT.createSaveRoot(SAVE_FORMAT.createEmptyRunStateData(), metaData)
	if int(root.get("schemaVersion", 0)) != SAVE_FORMAT.SCHEMA_VERSION:
		result.addError("Save root schemaVersion is missing.")
	if str(root.get("gameVersion", "")) == "":
		result.addError("Save root gameVersion is missing.")
	if str(root.get("createdAt", "")) == "":
		result.addError("Save root createdAt is missing.")
	if not SAVE_FORMAT.isValidSaveRoot(root):
		result.addError("Save root does not validate.")

	var invalidRoot := root.duplicate(true)
	invalidRoot["schemaVersion"] = 0
	if SAVE_FORMAT.isValidSaveRoot(invalidRoot):
		result.addError("Save root accepted invalid schemaVersion.")
	return result


func _testRunStateSerializerWritesPureData() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"paperland")
	runState.upgrades.append(&"rapidRecruitment")
	var battle := BattleData.new()
	battle.id = &"battle_save"
	battle.attackerArmyId = &"army_start"
	battle.sourceCountryId = &"paperland"
	battle.targetCountryId = &"inkreich"
	battle.status = BattleStatus.Value.Active
	battle.elapsedSeconds = 1.5
	battle.durationSeconds = 6.0
	battle.casualties = {
		GameIds.INFANTRY_UNIT_ID: 2,
	}
	runState.battles[battle.id] = battle

	var serialized: Dictionary = RUN_STATE_SERIALIZER.serializeRunState(runState)
	if int(serialized.get("schemaVersion", 0)) != SAVE_FORMAT.SCHEMA_VERSION:
		result.addError("Serialized RunState schemaVersion is missing.")
	if not RUN_STATE_SERIALIZER.containsOnlyJsonValues(serialized):
		result.addError("Serialized RunState contains non-JSON values.")

	var countries: Dictionary = serialized.get("countries", {})
	var paperland: Dictionary = countries.get("paperland", {})
	var center: Dictionary = paperland.get("center", {})
	if float(center.get("x", -1.0)) <= 0.0 or float(center.get("y", -1.0)) <= 0.0:
		result.addError("Serialized country center is missing.")

	var armies: Dictionary = serialized.get("armies", {})
	var army: Dictionary = armies.get("army_start", {})
	if str(army.get("locationCountryId", "")) != "paperland":
		result.addError("Serialized army location is wrong.")

	var battles: Dictionary = serialized.get("battles", {})
	var serializedBattle: Dictionary = battles.get("battle_save", {})
	if str(serializedBattle.get("targetCountryId", "")) != "inkreich":
		result.addError("Serialized battle target is wrong.")

	var root: Dictionary = SAVE_FORMAT.createRunSaveRoot(serialized)
	if not SAVE_FORMAT.isValidSaveRoot(root):
		result.addError("Serialized RunState could not be placed in a valid save root.")
	return result


func _testSaveManagerWritesAndLoadsUserSaves() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := SaveManager.new()
	add_child(manager)
	var slotId := "debug_test_slot"
	manager.deleteSave(slotId)

	var runState := NewRunFactory.createNewRun(&"paperland")
	var runData: Dictionary = RUN_STATE_SERIALIZER.serializeRunState(runState)
	var root: Dictionary = SAVE_FORMAT.createRunSaveRoot(runData)
	if not manager.saveGame(slotId, root):
		result.addError("SaveManager rejected a valid save root.")
	if not manager.hasSave(slotId):
		result.addError("SaveManager did not report saved slot.")

	var loaded: Dictionary = manager.loadGame(slotId)
	if loaded.is_empty():
		result.addError("SaveManager did not load saved data.")
	elif not SAVE_FORMAT.isValidSaveRoot(loaded):
		result.addError("SaveManager loaded invalid save data.")
	else:
		var loadedRun: Dictionary = loaded.get(SAVE_FORMAT.RUN_STATE_KEY, {})
		var loadedCountries: Dictionary = loadedRun.get("countries", {})
		if not loadedCountries.has("paperland"):
			result.addError("Loaded save is missing serialized country data.")

	manager.deleteSave(slotId)
	remove_child(manager)
	manager.free()
	return result


func _testManualSaveLoadUiRestoresRunState() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for save/load UI test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var saveManager := main.get_node("GameRoot/Managers/SaveManager") as SaveManager
	var uiRoot = main.get_node("GameRoot/UIRoot")
	var saveButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/SaveButton") as Button
	var loadButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/LoadButton") as Button
	if saveManager == null or saveButton == null or loadButton == null:
		result.addError("Manual save/load UI is missing required nodes.")
		_cleanupMainForTest(main)
		return result

	saveManager.deleteSave("manual_1")
	var runState := gameManager.getCurrentRunState()
	runState.resources["gold"] = 321
	uiRoot.call("_openEscMenu")
	saveButton.emit_signal("pressed")
	if not saveManager.hasSave("manual_1"):
		result.addError("Manual save button did not create a save file.")

	runState.resources["gold"] = 999
	loadButton.emit_signal("pressed")
	if int(gameManager.getCurrentRunState().resources.get("gold", 0)) != 321:
		result.addError("Manual load button did not restore saved run gold.")

	saveManager.deleteSave("manual_1")
	_cleanupMainForTest(main)
	return result


func _testMetaProgressStoresUpgradeState() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := SaveManager.new()
	add_child(manager)
	var slotId := "debug_meta_progress_slot"
	manager.deleteSave(slotId)

	var metaData: Dictionary = META_PROGRESS.createDefaultData()
	var generalUpgrades: Dictionary = metaData.get("generalUpgrades", {})
	var countryUpgrades: Dictionary = metaData.get("countryUpgrades", {})
	if int(metaData.get("crowns", -1)) != 0:
		result.addError("MetaProgress default crowns are wrong.")
	if not generalUpgrades.has("startGold") or not generalUpgrades.has("startFood"):
		result.addError("MetaProgress default general upgrades are missing.")
	if not countryUpgrades.has("paperland"):
		result.addError("MetaProgress default country upgrades are missing.")

	metaData["crowns"] = 25
	(generalUpgrades["startGold"] as Dictionary)["level"] = 1
	var paperlandUpgrades := countryUpgrades["paperland"] as Dictionary
	(paperlandUpgrades["paperlandDiscipline"] as Dictionary)["level"] = 1
	if not META_PROGRESS.isValidDictionary(metaData):
		result.addError("MetaProgress rejected valid upgraded state.")

	var root: Dictionary = SAVE_FORMAT.createSaveRoot(SAVE_FORMAT.createEmptyRunStateData(), metaData)
	if not manager.saveGame(slotId, root):
		result.addError("SaveManager rejected MetaProgress save root.")

	var loaded: Dictionary = manager.loadGame(slotId)
	var loadedMeta: Dictionary = loaded.get(SAVE_FORMAT.META_PROGRESS_KEY, {})
	if int(loadedMeta.get("crowns", 0)) != 25:
		result.addError("Loaded MetaProgress crowns are wrong.")
	var loadedGeneral: Dictionary = loadedMeta.get("generalUpgrades", {})
	var loadedStartGold := loadedGeneral.get("startGold", {}) as Dictionary
	if int(loadedStartGold.get("level", 0)) != 1:
		result.addError("Loaded MetaProgress general upgrade level is wrong.")

	var invalidMeta := metaData.duplicate(true)
	((invalidMeta["generalUpgrades"] as Dictionary)["startGold"] as Dictionary)["level"] = 99
	if META_PROGRESS.isValidDictionary(invalidMeta):
		result.addError("MetaProgress accepted level above maxLevel.")

	manager.deleteSave(slotId)
	remove_child(manager)
	manager.free()
	return result


func _testMetaProgressAwardsCrownsAndAppliesPurchases() -> ValidationResult:
	var result := ValidationResult.new()
	var metaUpgradeRows := PrototypeContentLoader.loadMetaUpgrades()
	var fixtureResult := META_UPGRADE_DATA_VALIDATOR.validate(metaUpgradeRows, PrototypeContentLoader.loadCountries())
	if not fixtureResult.isValid():
		return fixtureResult

	var metaData: Dictionary = META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)
	var runState := NewRunFactory.createNewRun(&"paperland", metaData, metaUpgradeRows)
	runState.upgrades.append(&"rapidRecruitment")
	var conqueredCountry := runState.countries[&"inkreich"] as CountryData
	conqueredCountry.ownerId = GameIds.PLAYER_OWNER_ID

	var reward: Dictionary = META_PROGRESS_SIMULATION.calculateCrownsReward(runState, metaData, metaUpgradeRows)
	if not bool(reward.get("accepted", false)):
		result.addError("MetaProgressSimulation rejected valid run reward.")
	if int(reward.get("crowns", 0)) != 14:
		result.addError("MetaProgressSimulation calculated wrong crown reward.")

	var awarded: Dictionary = META_PROGRESS_SIMULATION.awardRunEndCrowns(metaData, runState, metaUpgradeRows)
	if int(awarded.get("totalCrowns", 0)) != 14:
		result.addError("MetaProgressSimulation did not add rewarded crowns.")

	metaData["crowns"] = 50
	var purchaseResult: Dictionary = META_PROGRESS_SIMULATION.purchaseUpgrade(metaData, &"startGold", metaUpgradeRows)
	if not bool(purchaseResult.get("accepted", false)):
		result.addError("MetaProgressSimulation rejected affordable purchase.")

	var purchasedMeta := purchaseResult.get("metaProgress", {}) as Dictionary
	var purchasedGeneral := purchasedMeta.get("generalUpgrades", {}) as Dictionary
	var startGoldUpgrade := purchasedGeneral.get("startGold", {}) as Dictionary
	if int(startGoldUpgrade.get("level", 0)) != 1:
		result.addError("MetaProgressSimulation did not raise purchased upgrade level.")
	if int(purchasedMeta.get("crowns", 0)) != 30:
		result.addError("MetaProgressSimulation did not subtract purchase cost.")

	var bonusRun := NewRunFactory.createNewRun(&"paperland", purchasedMeta, metaUpgradeRows)
	if int(bonusRun.resources.get("gold", 0)) != NewRunFactory.START_GOLD + 50:
		result.addError("NewRunFactory did not apply purchased starting gold bonus.")

	purchasedMeta["crowns"] = 50
	var countryPurchase: Dictionary = META_PROGRESS_SIMULATION.purchaseUpgrade(purchasedMeta, &"paperlandDiscipline", metaUpgradeRows)
	var countryMeta := countryPurchase.get("metaProgress", {}) as Dictionary
	var countryBonusRun := NewRunFactory.createNewRun(&"paperland", countryMeta, metaUpgradeRows)
	var startArmy := countryBonusRun.armies[&"army_start"] as ArmyData
	if int(startArmy.units.get(GameIds.INFANTRY_UNIT_ID, 0)) != NewRunFactory.START_INFANTRY + 1:
		result.addError("NewRunFactory did not apply country starting army bonus.")

	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	add_child(manager)
	add_child(simulation)
	add_child(bus)
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("paperland")
	var commandMeta: Dictionary = META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)
	commandMeta["crowns"] = 20
	manager.metaProgressData = commandMeta
	bus.requestCommand(CommandType.PURCHASE_META_UPGRADE, {
		"upgradeId": "startGold",
	})
	var commandResultMeta := manager.getMetaProgressData()
	var commandGeneral := commandResultMeta.get("generalUpgrades", {}) as Dictionary
	var commandStartGold := commandGeneral.get("startGold", {}) as Dictionary
	if int(commandStartGold.get("level", 0)) != 1:
		result.addError("GameManager purchase command did not update MetaProgress.")
	if not _capturedEvent(EventType.META_UPGRADE_PURCHASED) or not _capturedEvent(EventType.META_PROGRESS_CHANGED):
		result.addError("GameManager purchase command did not emit meta progress events.")

	remove_child(manager)
	remove_child(simulation)
	remove_child(bus)
	manager.free()
	simulation.free()
	bus.free()
	return result


func _testShopPanelSendsPurchaseCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var metaUpgradeRows := PrototypeContentLoader.loadMetaUpgrades()
	var metaData: Dictionary = META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)
	metaData["crowns"] = 20
	var panel = SHOP_PANEL_SCRIPT.new()
	add_child(panel)
	lastShopUpgradeId = GameIds.EMPTY_ID
	panel.connect("purchaseRequested", Callable(self, "_recordShopPurchase"))
	panel.call("setData", SHOP_STATE_VIEW.createShopPanelData(metaData, metaUpgradeRows))

	var buttons := panel.get("rowButtons") as Array
	if buttons.is_empty():
		result.addError("ShopPanel did not create purchase rows.")
	else:
		var firstButton := buttons[0] as Button
		if firstButton.disabled:
			result.addError("ShopPanel disabled affordable upgrade row.")
		firstButton.emit_signal("pressed")
		if lastShopUpgradeId != &"startGold":
			result.addError("ShopPanel did not emit selected upgrade id.")

	remove_child(panel)
	panel.free()
	return result


func _recordGameEvent(eventName: StringName, payload: Dictionary) -> void:
	capturedEvents.append({
		"eventName": eventName,
		"payload": payload,
	})


func _recordShopPurchase(upgradeId: StringName) -> void:
	lastShopUpgradeId = upgradeId


func _capturedEvent(eventName: StringName) -> bool:
	for event in capturedEvents:
		if event.get("eventName", GameIds.EMPTY_ID) == eventName:
			return true
	return false


func _hasDuplicateUpgradeIds(choices: Array) -> bool:
	var seen := {}
	for choice in choices:
		if not (choice is Dictionary):
			continue

		var upgrade := choice as Dictionary
		var upgradeId := StringName(str(upgrade.get("id", "")))
		if seen.has(upgradeId):
			return true
		seen[upgradeId] = true
	return false


func _expectFailure(result: ValidationResult) -> ValidationResult:
	if result.isValid():
		var wrapper := ValidationResult.new()
		wrapper.addError("Expected validation failure, but fixture passed.")
		return wrapper

	return ValidationResult.new()


func _createValidRunState() -> RunState:
	var runState := RunState.new()
	for country in _createValidCountries():
		runState.countries[country.id] = country

	var army := ArmyData.new()
	army.id = &"army_1"
	army.ownerId = GameIds.PLAYER_OWNER_ID
	army.locationCountryId = &"paperland"
	army.targetCountryId = &"inkreich"
	army.units = {
		GameIds.INFANTRY_UNIT_ID: 10,
		GameIds.CAVALRY_UNIT_ID: 2,
	}
	runState.armies[army.id] = army

	runState.resources = {
		"gold": 100,
		"food": 80,
		"threat": 0,
	}
	runState.speed = GameSpeed.Value.Normal
	runState.runStatus = RunState.RUN_STATUS_ACTIVE
	return runState


func _createValidCountries() -> Array[CountryData]:
	var countries: Array[CountryData] = []
	var paperlandNeighbors: Array[StringName] = [&"inkreich"]
	var inkreichNeighbors: Array[StringName] = [&"paperland"]
	countries.append(_createCountry(&"paperland", "Paperland", GameIds.PLAYER_OWNER_ID, Vector2(100.0, 120.0), paperlandNeighbors))
	countries.append(_createCountry(&"inkreich", "Inkreich", GameIds.NEUTRAL_OWNER_ID, Vector2(180.0, 125.0), inkreichNeighbors))
	return countries


func _createCountry(
	countryId: StringName,
	countryName: String,
	ownerId: StringName,
	center: Vector2,
	neighbors: Array[StringName]
) -> CountryData:
	var country := CountryData.new()
	country.id = countryId
	country.name = countryName
	country.ownerId = ownerId
	country.goldPerMonth = 25
	country.foodPerMonth = 15
	country.defense = 10
	country.center = center
	country.neighbors = neighbors
	return country


func _validOwnerIds() -> Array[StringName]:
	return [
		GameIds.PLAYER_OWNER_ID,
		GameIds.NEUTRAL_OWNER_ID,
		GameIds.WORLD_OWNER_ID,
	]


func _unitFromCatalog(unitId: StringName) -> UnitData:
	for unit in PrototypeContentLoader.loadUnits():
		if unit.id == unitId:
			return unit
	return null


func _upgradeById(upgradeId: StringName) -> Dictionary:
	for upgrade in PrototypeContentLoader.loadUpgrades():
		if StringName(str(upgrade.get("id", ""))) == upgradeId:
			return upgrade
	return {}


func _miniGoalById(runState: RunState, goalId: StringName) -> Dictionary:
	for goal in runState.miniGoals:
		if StringName(str(goal.get("id", ""))) == goalId:
			return goal
	return {}


func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += int(units.get(unitId, 0))
	return total


func _countryShapeBounds(center: Vector2, points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(center + points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(center + point)
	return bounds


func _cleanupMainForTest(main: Node) -> void:
	if main.get_parent() == self:
		remove_child(main)
	main.free()
