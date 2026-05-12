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
const AI_WAR_SIMULATION := preload("res://src/core/simulation/ai_war_simulation.gd")
const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")
const SHOP_STATE_VIEW := preload("res://src/core/view/shop_state_view.gd")
const SHOP_PANEL_SCRIPT := preload("res://scenes/ui/shop_panel.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://src/save/settings_manager.gd")
const SETTINGS_PANEL_SCRIPT := preload("res://scenes/ui/settings_panel.gd")
const USER_SETTINGS := preload("res://src/save/user_settings.gd")
const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")
const MOCK_PLATFORM_SERVICE_SCRIPT := preload("res://src/platform/mock_platform_service.gd")
const PLATFORM_EVENT_BRIDGE_SCRIPT := preload("res://src/platform/platform_event_bridge.gd")
const ACHIEVEMENT_EVENT_MAP := preload("res://src/platform/achievement_event_map.gd")
const META_UPGRADE_DATA_VALIDATOR := preload("res://src/core/validation/meta_upgrade_data_validator.gd")
const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const META_PROGRESS := preload("res://src/save/meta_progress.gd")
const RUN_STATE_SERIALIZER := preload("res://src/save/run_state_serializer.gd")

var lastShopUpgradeId: StringName = GameIds.EMPTY_ID
var lastSettingKey: StringName = GameIds.EMPTY_ID
var lastSettingValue: Variant = null


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
	_runTest("AiWarSimulation starts adjacent NPC attacks", _testAiWarStartsAdjacentNpcAttack)
	_runTest("AiWarSimulation can attack threatened player border", _testAiWarCanAttackThreatenedPlayerBorder)
	_runTest("NPC conquest does not open upgrade choice", _testNpcConquestDoesNotOpenUpgradeChoice)
	_runTest("Game over awards crowns and blocks commands", _testGameOverAwardsCrownsAndBlocksCommands)
	_runTest("UpgradeSimulation rolls choices and applies effects", _testUpgradeRollsChoicesAndAppliesEffects)
	_runTest("Upgrade modal applies one selected upgrade", _testUpgradeModalAppliesSelectedUpgrade)
	_runTest("ThreatSimulation applies passive and action threat", _testThreatAppliesPassiveAndActionThreat)
	_runTest("Threat UI summaries expose warning states", _testThreatUiSummariesExposeWarningStates)
	_runTest("WorldMap creates country and army nodes", _testWorldMapCreatesCountryAndArmyNodes)
	_runTest("MapCamera clamps pan and zoom", _testMapCameraClampsPanAndZoom)
	_runTest("Input actions register desktop controls", _testInputActionsRegisterDesktopControls)
	_runTest("RunStateView creates UI summaries", _testRunStateViewCreatesSummaries)
	_runTest("Main menu first boot and actions", _testMainMenuFirstBootAndActions)
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
	_runTest("Settings manager saves and applies settings", _testSettingsManagerSavesAndAppliesSettings)
	_runTest("Settings panel sends setting changes", _testSettingsPanelSendsSettingChanges)
	_runTest("Platform service mock records achievements", _testPlatformServiceMockRecordsAchievements)
	_runTest("Platform event bridge unlocks mapped achievements", _testPlatformEventBridgeUnlocksMappedAchievements)
	_runTest("Vertical slice balance envelope is playable", _testVerticalSliceBalanceEnvelope)
	_runTest("Vertical slice mini run reaches win status", _testVerticalSliceMiniRunReachesWinStatus)

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
	invalidCountries.append(_createCountry(&"usa", "United States of America Copy", GameIds.PLAYER_OWNER_ID, Vector2(50.0, 50.0), missingNeighbors))
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

		var polygons: Array[PackedVector2Array] = _mapShapePolygons(shapes[country.id])
		if polygons.is_empty():
			result.addError("Map shape has no valid polygons for country: %s." % country.id)
			continue

		var hasCountryBounds := false
		var countryBounds := Rect2()
		for points in polygons:
			if points.size() < 3:
				result.addError("Map shape has fewer than 3 points for country: %s." % country.id)
				continue

			var polygonBounds := _countryShapeBounds(country.center, points)
			if hasCountryBounds:
				countryBounds = countryBounds.merge(polygonBounds)
			else:
				countryBounds = polygonBounds
				hasCountryBounds = true

		if hasCountryBounds:
			boundsByCountry[country.id] = countryBounds

	for countryId in boundsByCountry.keys():
		var countryBounds: Rect2 = boundsByCountry[countryId]
		if countryBounds.size.x <= 2.0 or countryBounds.size.y <= 2.0:
			result.addError("Map shape is too small for country: %s." % countryId)

	return result


func _testNewRunFactory() -> ValidationResult:
	var runState := NewRunFactory.createNewRun(&"usa")
	var result := RunStateValidator.validate(runState)

	if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
		result.addError("New run is not active.")

	if not runState.countries.has(&"usa"):
		result.addError("New run does not contain start country.")
	else:
		var startCountry := runState.countries[&"usa"] as CountryData
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

	if not runState.miniGoals.is_empty():
		result.addError("New run should not contain mini goals for the MVP.")

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

	manager.startNewRun("usa")
	if not manager.hasActiveRun():
		result.addError("GameManager did not create an active run.")

	manager.submitCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "can",
	})
	if manager.getSelectedCountryId() != &"can":
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
		"startCountryId": "mex",
	})
	if manager.getSelectedCountryId() != &"mex":
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
	var runState := NewRunFactory.createNewRun(&"usa")
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
	var runState := NewRunFactory.createNewRun(&"usa")
	var income: Dictionary = ECONOMY_SIMULATION.calculateMonthlyIncome(runState)
	var upkeep: int = ECONOMY_SIMULATION.calculateArmyFoodUpkeep(runState, PrototypeContentLoader.loadUnits())
	if int(income.get("gold", 0)) != 35:
		result.addError("EconomySimulation calculated wrong gold income.")
	if int(income.get("food", 0)) != 24:
		result.addError("EconomySimulation calculated wrong food income.")
	if upkeep != 48:
		result.addError("EconomySimulation calculated wrong army food upkeep.")
	return result


func _testEconomyAppliesMonthTickAndShortage() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"usa")
	var monthResult: Dictionary = ECONOMY_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	if int(runState.resources.get("gold", 0)) != NewRunFactory.START_GOLD + 35:
		result.addError("EconomySimulation did not apply monthly gold income.")
	if int(runState.resources.get("food", 0)) != NewRunFactory.START_FOOD + 24 - 48:
		result.addError("EconomySimulation did not apply food income and upkeep.")
	if int(monthResult.get("foodUpkeep", 0)) != 48:
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
	var runState := NewRunFactory.createNewRun(&"usa")
	var invalidMove: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(runState, &"army_start", &"bra")
	if bool(invalidMove.get("accepted", false)):
		result.addError("ArmyMovementSimulation accepted a non-neighbor move.")

	var can := runState.countries[&"can"] as CountryData
	can.ownerId = GameIds.PLAYER_OWNER_ID
	var move: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(runState, &"army_start", &"can")
	if not bool(move.get("accepted", false)):
		result.addError("ArmyMovementSimulation rejected a neighbor move.")

	var army := runState.armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Moving:
		result.addError("ArmyMovementSimulation did not set moving status.")
	if army.targetCountryId != &"can":
		result.addError("ArmyMovementSimulation did not set target country.")

	var completedEarly: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 0.5)
	if not completedEarly.is_empty():
		result.addError("ArmyMovementSimulation completed movement too early.")
	if not is_equal_approx(army.movementProgress, 0.5):
		result.addError("ArmyMovementSimulation did not advance progress deterministically.")

	var completed: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 0.5)
	if completed.size() != 1:
		result.addError("ArmyMovementSimulation did not report completed move.")
	if army.locationCountryId != &"can":
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
	manager.startNewRun("usa")
	var can := manager.getCurrentRunState().countries[&"can"] as CountryData
	can.ownerId = GameIds.PLAYER_OWNER_ID

	bus.requestCommand(CommandType.MOVE_ARMY, {
		"armyId": "army_start",
		"targetCountryId": "can",
	})
	var army := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	if army.status != ArmyStatus.Value.Moving:
		result.addError("move_army command did not start army movement.")
	if manager.getSelectedArmyId() != &"army_start":
		result.addError("move_army command did not preserve selected army.")
	if not _capturedEvent(EventType.ARMY_MOVE_STARTED):
		result.addError("move_army command did not emit armyMoveStarted.")

	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5)
	if army.locationCountryId != &"can":
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
	if int(cost.get("goldCost", 0)) != 20:
		result.addError("RecruitmentSimulation calculated wrong infantry gold cost.")
	if int(cost.get("foodReserveRequired", 0)) != 2:
		result.addError("RecruitmentSimulation calculated wrong infantry food reserve.")

	var runState := NewRunFactory.createNewRun(&"usa")
	var recruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(
		runState,
		&"usa",
		GameIds.CAVALRY_UNIT_ID,
		1,
		units,
		&"army_start"
	)
	if not bool(recruit.get("accepted", false)):
		result.addError("RecruitmentSimulation rejected valid recruitment.")

	var army := runState.armies[&"army_start"] as ArmyData
	if int(runState.resources.get("gold", 0)) != NewRunFactory.START_GOLD - 25:
		result.addError("RecruitmentSimulation did not spend gold.")
	if int(army.units.get(GameIds.CAVALRY_UNIT_ID, 0)) != NewRunFactory.START_CAVALRY + 1:
		result.addError("RecruitmentSimulation did not add recruited units.")

	var enemyRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"can", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(enemyRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation accepted recruitment in non-owned country.")

	runState.resources["gold"] = 10
	var expensiveRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"usa", GameIds.ARTILLERY_UNIT_ID, 1, units, &"army_start")
	if bool(expensiveRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation accepted recruitment without enough gold.")

	runState.resources["gold"] = 1000
	runState.resources["food"] = 0
	var noFoodRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"usa", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if not bool(noFoodRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation rejected recruitment even though MVP recruitment only costs gold.")

	runState.resources["food"] = 100
	runState.economy["recruitmentBlocked"] = true
	var blockedRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"usa", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(blockedRecruit.get("accepted", false)):
		result.addError("RecruitmentSimulation ignored recruitmentBlocked.")
	runState.economy["recruitmentBlocked"] = false
	var usa := runState.countries[&"usa"] as CountryData
	usa.isUnderAttack = true
	var underAttackRecruit: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(runState, &"usa", GameIds.INFANTRY_UNIT_ID, 1, units, &"army_start")
	if bool(underAttackRecruit.get("accepted", false)) or str(underAttackRecruit.get("reason", "")) != "country_under_attack":
		result.addError("RecruitmentSimulation allowed recruitment in an attacked country.")
	var underAttackCreate: Dictionary = RECRUITMENT_SIMULATION.createArmy(runState, &"usa")
	if bool(underAttackCreate.get("accepted", false)) or str(underAttackCreate.get("reason", "")) != "country_under_attack":
		result.addError("RecruitmentSimulation allowed new army creation in an attacked country.")
	var underAttackEdit: Dictionary = RECRUITMENT_SIMULATION.updateArmyComposition(runState, &"army_start", {
		GameIds.INFANTRY_UNIT_ID: NewRunFactory.START_INFANTRY + 2,
	}, units)
	if bool(underAttackEdit.get("accepted", false)) or str(underAttackEdit.get("reason", "")) != "country_under_attack":
		result.addError("RecruitmentSimulation allowed army editing in an attacked country.")
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
	manager.startNewRun("usa")

	bus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": "usa",
		"unitType": "infantry",
		"amount": 1,
	})
	var army := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	if int(manager.getCurrentRunState().resources.get("gold", 0)) != NewRunFactory.START_GOLD - 10:
		result.addError("recruit_units command did not spend gold.")
	if int(army.units.get(GameIds.INFANTRY_UNIT_ID, 0)) != NewRunFactory.START_INFANTRY + 1:
		result.addError("recruit_units command did not add infantry.")
	if not _capturedEvent(EventType.UNITS_RECRUITED):
		result.addError("recruit_units command did not emit unitsRecruited.")

	var previousArmyCount := manager.getCurrentRunState().armies.size()
	bus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": "usa",
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
	var runState := NewRunFactory.createNewRun(&"usa")
	var army := runState.armies[&"army_start"] as ArmyData
	var targetCountry := runState.countries[&"can"] as CountryData
	var power := COMBAT_SIMULATION.calculateArmyCombatPower(army, PrototypeContentLoader.loadUnits(), runState.economy, {
		"targetDefense": targetCountry.defense,
	})
	var expectedPower := 492.0
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
	var runState := NewRunFactory.createNewRun(&"usa")
	var invalidAttack: Dictionary = COMBAT_SIMULATION.startAttack(runState, &"army_start", &"bra", PrototypeContentLoader.loadUnits())
	if bool(invalidAttack.get("accepted", false)):
		result.addError("CombatSimulation accepted a non-neighbor attack.")

	var attack: Dictionary = COMBAT_SIMULATION.startAttack(runState, &"army_start", &"can", PrototypeContentLoader.loadUnits())
	if not bool(attack.get("accepted", false)):
		result.addError("CombatSimulation rejected a valid attack.")
	if not runState.battles.is_empty():
		result.addError("CombatSimulation created BattleData before the attacker arrived.")

	var reserveArmy := runState.armies[&"army_start"] as ArmyData
	var attackArmyId := StringName(str(attack.get("armyId", "")))
	var attackArmy := runState.armies.get(attackArmyId, null) as ArmyData
	if attackArmy == null:
		result.addError("CombatSimulation did not create a separate attack army.")
	elif attackArmy.status != ArmyStatus.Value.Attacking:
		result.addError("CombatSimulation did not set attack army status.")
	elif attackArmy.targetCountryId != &"can":
		result.addError("CombatSimulation did not set attack army target.")
	if reserveArmy.status != ArmyStatus.Value.Stationed:
		result.addError("CombatSimulation did not keep reserve stationed.")
	if _unitCount(reserveArmy.units) != int(attack.get("reserveUnitCount", -1)):
		result.addError("CombatSimulation reserve count does not match payload.")
	if attackArmy != null and _unitCount(attackArmy.units) + _unitCount(reserveArmy.units) != NewRunFactory.START_INFANTRY + NewRunFactory.START_CAVALRY + NewRunFactory.START_ARTILLERY:
		result.addError("CombatSimulation lost units while splitting attack and reserve.")

	var smallRunState := NewRunFactory.createNewRun(&"usa")
	var smallArmy := smallRunState.armies[&"army_start"] as ArmyData
	smallArmy.units = {
		GameIds.INFANTRY_UNIT_ID: 6,
	}
	var smallAttack: Dictionary = COMBAT_SIMULATION.startAttack(smallRunState, &"army_start", &"can", PrototypeContentLoader.loadUnits())
	if bool(smallAttack.get("accepted", false)):
		result.addError("CombatSimulation accepted an attack from a too-small army.")

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
	manager.startNewRun("usa")
	var startingArmy := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	startingArmy.units = {
		GameIds.INFANTRY_UNIT_ID: 160,
		GameIds.CAVALRY_UNIT_ID: 20,
		GameIds.ARTILLERY_UNIT_ID: 10,
	}

	bus.requestCommand(CommandType.START_ATTACK, {
		"armyId": "army_start",
		"targetCountryId": "can",
	})

	var reserveArmy := manager.getCurrentRunState().armies[&"army_start"] as ArmyData
	var army := _attackingArmyForTarget(manager.getCurrentRunState(), &"can", GameIds.PLAYER_OWNER_ID)
	if army == null:
		result.addError("start_attack command did not create an attack army.")
	elif army.status != ArmyStatus.Value.Attacking:
		result.addError("start_attack command did not set attack army attacking.")
	if reserveArmy == null or reserveArmy.status != ArmyStatus.Value.Stationed or reserveArmy.locationCountryId != &"usa":
		result.addError("start_attack command did not leave a stationed reserve.")
	elif _unitCount(reserveArmy.units) < COMBAT_SIMULATION.MIN_RESERVE_ARMY_SIZE:
		result.addError("start_attack command left too small a reserve.")

	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5 + COMBAT_SIMULATION.BATTLE_DURATION_SECONDS)
	if not _capturedEvent(EventType.BATTLE_STARTED):
		result.addError("Attack arrival did not emit battleStarted.")
	var targetCountry := manager.getCurrentRunState().countries[&"can"] as CountryData
	if targetCountry.ownerId != GameIds.PLAYER_OWNER_ID:
		result.addError("SimulationManager did not conquer target country.")
	if army != null and army.locationCountryId != &"can":
		result.addError("Conquering army did not station in target country.")
	if army != null and army.status != ArmyStatus.Value.Stationed:
		result.addError("Conquering army did not return to stationed status.")
	if reserveArmy != null and (reserveArmy.locationCountryId != &"usa" or reserveArmy.status != ArmyStatus.Value.Stationed):
		result.addError("Reserve army did not stay in the source country.")
	if army != null and _unitCount(army.units) < 0:
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


func _testAiWarStartsAdjacentNpcAttack() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := _createAiWarTestRunState()
	var events: Array[Dictionary] = AI_WAR_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	var sourceCountry := runState.countries[&"aiSource"] as CountryData
	var targetCountry := runState.countries[&"aiTarget"] as CountryData
	var sourceArmy := runState.armies[&"army_ai_source"] as ArmyData
	var attackArmy := _attackingArmyForTarget(runState, targetCountry.id, sourceCountry.ownerId)

	if not _eventRowsContain(events, EventType.AI_ATTACK_STARTED):
		result.addError("AiWarSimulation did not emit aiAttackStarted.")
	if not _eventRowsContain(events, EventType.ARMY_MOVE_STARTED):
		result.addError("AiWarSimulation did not reuse armyMoveStarted for movement visuals.")
	if attackArmy == null or attackArmy.status != ArmyStatus.Value.Attacking:
		result.addError("AI attack army did not enter attacking status.")
	if attackArmy != null and attackArmy.targetCountryId != targetCountry.id:
		result.addError("AI army did not choose the adjacent target.")
	if sourceArmy.status != ArmyStatus.Value.Stationed or _unitCount(sourceArmy.units) < COMBAT_SIMULATION.MIN_RESERVE_ARMY_SIZE:
		result.addError("AI attack did not leave a stationed reserve.")
	if sourceCountry.aiCooldownMonths < AI_WAR_SIMULATION.NPC_ATTACK_COOLDOWN_MONTHS:
		result.addError("AI attack did not apply source cooldown.")
	if not targetCountry.isUnderAttack:
		result.addError("AI attack did not mark target as under attack.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("AI attack produced invalid RunState: %s" % error)
	return result


func _testAiWarCanAttackThreatenedPlayerBorder() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := _createAiVsPlayerWarTestRunState()
	var events: Array[Dictionary] = AI_WAR_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	var sourceCountry := runState.countries[&"aiSource"] as CountryData
	var playerCountry := runState.countries[&"playerBorder"] as CountryData
	var sourceArmy := runState.armies[&"army_ai_source"] as ArmyData
	var attackArmy := _attackingArmyForTarget(runState, playerCountry.id, sourceCountry.ownerId)

	if not _eventRowsContain(events, EventType.PLAYER_ATTACKED):
		result.addError("AiWarSimulation did not emit playerAttacked.")
	if not _eventRowsContain(events, EventType.AI_ATTACK_STARTED):
		result.addError("AiWarSimulation did not emit aiAttackStarted for player attack.")
	if attackArmy == null or attackArmy.status != ArmyStatus.Value.Attacking:
		result.addError("AI army did not attack the player border.")
	if attackArmy != null and attackArmy.targetCountryId != playerCountry.id:
		result.addError("AI army targeted the wrong player country.")
	if sourceArmy.status != ArmyStatus.Value.Stationed or _unitCount(sourceArmy.units) < COMBAT_SIMULATION.MIN_RESERVE_ARMY_SIZE:
		result.addError("AI player attack did not leave a stationed reserve.")
	if sourceCountry.aiCooldownMonths < AI_WAR_SIMULATION.PLAYER_ATTACK_COOLDOWN_MONTHS:
		result.addError("AI player attack did not apply the longer cooldown.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("AI player attack produced invalid RunState: %s" % error)
	return result


func _testNpcConquestDoesNotOpenUpgradeChoice() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := _createAiWarTestRunState()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	simulation.configure(runState, bus)

	var attackResult: Dictionary = COMBAT_SIMULATION.startAttack(
		runState,
		&"army_ai_source",
		&"aiTarget",
		PrototypeContentLoader.loadUnits()
	)
	if not bool(attackResult.get("accepted", false)):
		result.addError("NPC test attack was rejected: %s." % str(attackResult.get("reason", "unknown_reason")))

	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5 + COMBAT_SIMULATION.BATTLE_DURATION_SECONDS)
	var targetCountry := runState.countries[&"aiTarget"] as CountryData
	if targetCountry.ownerId != GameIds.npcOwnerIdForCountry(&"aiSource"):
		result.addError("NPC conquest did not assign the attacker owner.")
	if bool(runState.activeUpgradeChoice.get("isOpen", false)):
		result.addError("NPC conquest opened a player upgrade choice.")
	if _capturedEvent(EventType.UPGRADE_CHOICE_OPENED):
		result.addError("NPC conquest emitted upgradeChoiceOpened.")
	if not _capturedEvent(EventType.AI_COUNTRY_CONQUERED):
		result.addError("NPC conquest did not emit aiCountryConquered.")

	var validation := RunStateValidator.validate(runState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("NPC conquest produced invalid RunState: %s" % error)

	simulation.free()
	bus.free()
	return result


func _testGameOverAwardsCrownsAndBlocksCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.startNewRun("usa")

	var runState := manager.getCurrentRunState()
	runState.runStats["monthsSurvived"] = 3
	var startCountry := runState.countries[&"usa"] as CountryData
	startCountry.ownerId = GameIds.npcOwnerIdForCountry(&"usa")
	var playerArmy := runState.armies[&"army_start"] as ArmyData
	if playerArmy == null or playerArmy.ownerId != GameIds.PLAYER_OWNER_ID:
		result.addError("Game over fixture lost its player army.")

	bus.raiseGameEvent(EventType.COUNTRY_CONQUERED, {
		"countryId": "usa",
		"newOwnerId": str(startCountry.ownerId),
		"previousOwnerId": str(GameIds.PLAYER_OWNER_ID),
	})

	if runState.runStatus != RunState.RUN_STATUS_LOST:
		result.addError("Run did not enter lost status after all countries were lost.")
	if int(runState.speed) != GameSpeed.Value.Paused:
		result.addError("Lost run was not paused.")
	if not bool(runState.runStats.get("crownsAwarded", false)):
		result.addError("RunStats did not record crown payout.")
	if not _capturedEvent(EventType.RUN_LOST):
		result.addError("Game over did not emit runLost.")
	if not _capturedEvent(EventType.GAME_OVER_TRIGGERED):
		result.addError("Game over did not emit gameOverTriggered.")
	if not _capturedEvent(EventType.CROWNS_AWARDED):
		result.addError("Game over did not emit crownsAwarded.")

	var expectedCrowns := 18
	var metaData := manager.getMetaProgressData()
	if int(metaData.get("crowns", 0)) != expectedCrowns:
		result.addError("Game over awarded wrong crowns: %d." % int(metaData.get("crowns", 0)))

	var previousGold := int(runState.resources.get("gold", 0))
	var previousInfantry := int(playerArmy.units.get(GameIds.INFANTRY_UNIT_ID, 0))
	bus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": "usa",
		"unitType": "infantry",
		"amount": 1,
		"armyId": "army_start",
	})
	if int(runState.resources.get("gold", 0)) != previousGold:
		result.addError("Recruit command changed gold after game over.")
	if int(playerArmy.units.get(GameIds.INFANTRY_UNIT_ID, 0)) != previousInfantry:
		result.addError("Recruit command changed army units after game over.")

	bus.requestCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Normal,
	})
	if int(runState.speed) != GameSpeed.Value.Paused:
		result.addError("Lost run resumed through speed command.")

	bus.raiseGameEvent(EventType.COUNTRY_CONQUERED, {
		"countryId": "usa",
		"newOwnerId": str(startCountry.ownerId),
		"previousOwnerId": str(GameIds.PLAYER_OWNER_ID),
	})
	if int(manager.getMetaProgressData().get("crowns", 0)) != expectedCrowns:
		result.addError("Game over awarded crowns more than once.")

	manager.free()
	simulation.free()
	bus.free()
	return result


func _testUpgradeRollsChoicesAndAppliesEffects() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"usa")
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
	if int(discountedCost.get("goldCost", 0)) != 9:
		result.addError("Recruitment discount did not change recruitment cost.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"efficientSupply")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"efficientSupply")
	var upkeep := ECONOMY_SIMULATION.calculateArmyFoodUpkeep(runState, PrototypeContentLoader.loadUnits())
	if upkeep != 44:
		result.addError("Food upkeep upgrade did not reduce upkeep.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"warChest")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"warChest")
	var reward: Dictionary = UPGRADE_SIMULATION.applyConquestReward(runState, &"can")
	if int(reward.get("goldReward", 0)) != 93:
		result.addError("Conquest gold upgrade did not increase reward.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"quietWars")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"quietWars")
	var threat: Dictionary = UPGRADE_SIMULATION.applyWarThreat(runState)
	if int(threat.get("threatAdded", 0)) != 3:
		result.addError("War threat upgrade did not reduce threat gain.")

	runState.activeUpgradeChoice = {"isOpen": true, "choices": [_upgradeById(&"strongFronts")]}
	UPGRADE_SIMULATION.applyUpgradeChoice(runState, &"strongFronts")
	var ownedCountry := runState.countries[&"usa"] as CountryData
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
	_startMainRunForTest(main)
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var eventBus := main.get_node("GameRoot/Managers/EventBus") as EventBus
	var uiRoot = main.get_node("GameRoot/UIRoot")
	var modalLayer = main.get_node("GameRoot/UIRoot/Root/ModalLayer")
	var upgradeModal = main.get_node("GameRoot/UIRoot/Root/ModalLayer/UpgradeModal")
	var choiceButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/UpgradeModal/MarginContainer/VBoxContainer/ChoiceRow/ChoiceButton1") as Button
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
	var runState := NewRunFactory.createNewRun(&"usa")
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
	var expectedMonthlyThreat := THREAT_SIMULATION.PASSIVE_THREAT_PER_MONTH + THREAT_SIMULATION.calculateLargeArmyThreat(runState)
	if int(runState.resources.get("threat", 0)) != expectedMonthlyThreat:
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

	var enemyCountry := runState.countries[&"can"] as CountryData
	var enemyDefensePower := COMBAT_SIMULATION.calculateCountryDefensePower(enemyCountry, {}, runState.worldReaction)
	var expectedDefensePower := float(enemyCountry.defense) * COMBAT_SIMULATION.COUNTRY_DEFENSE_POWER_MULTIPLIER * 1.25
	if not is_equal_approx(enemyDefensePower, expectedDefensePower):
		result.addError("World reaction did not boost enemy defense power.")

	simulation.free()
	bus.free()
	return result


func _testThreatUiSummariesExposeWarningStates() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"usa")
	runState.resources["threat"] = 55
	var topBarData: Dictionary = RUN_STATE_VIEW.createTopBarData(runState)
	if str(topBarData.get("threatState", "")) != "high":
		result.addError("RunStateView did not expose high threat state.")

	runState.resources["threat"] = 80
	topBarData = RUN_STATE_VIEW.createTopBarData(runState)
	if str(topBarData.get("threatState", "")) != "critical":
		result.addError("RunStateView did not expose critical threat state.")
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
	manager.startNewRun("usa")
	worldMap.configure(manager, bus)

	var runState := manager.getCurrentRunState()
	if worldMap.getCountryNodeCount() != runState.countries.size():
		result.addError("WorldMap did not create a CountryNode for every country.")
	if worldMap.getArmyNodeCount() != runState.armies.size():
		result.addError("WorldMap did not create an ArmyNode for every army.")
	if worldMap.getArmyNode(&"army_start") == null:
		result.addError("WorldMap did not expose the starting ArmyNode.")

	bus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": "usa",
	})
	if worldMap.getArmyNodeCount() != runState.armies.size():
		result.addError("WorldMap did not refresh ArmyNodes after army creation.")

	bus.requestCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "can",
	})
	var canNode = worldMap.getCountryNode(&"can")
	if canNode == null:
		result.addError("WorldMap did not expose can CountryNode.")
	elif not bool(canNode.get("isSelected")):
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


func _testInputActionsRegisterDesktopControls() -> ValidationResult:
	var result := ValidationResult.new()
	INPUT_ACTIONS.ensureDefaultActions()
	var actions := [
		INPUT_ACTIONS.ACTION_OPEN_MENU,
		INPUT_ACTIONS.ACTION_PAUSE,
		INPUT_ACTIONS.ACTION_PAN_LEFT,
		INPUT_ACTIONS.ACTION_PAN_RIGHT,
		INPUT_ACTIONS.ACTION_PAN_UP,
		INPUT_ACTIONS.ACTION_PAN_DOWN,
		INPUT_ACTIONS.ACTION_ZOOM_IN,
		INPUT_ACTIONS.ACTION_ZOOM_OUT,
		INPUT_ACTIONS.ACTION_SPEED_NORMAL,
		INPUT_ACTIONS.ACTION_SPEED_FAST,
		INPUT_ACTIONS.ACTION_SPEED_VERY_FAST,
	]
	for actionName in actions:
		if not InputMap.has_action(actionName):
			result.addError("InputMap missing action: %s." % str(actionName))
		elif InputMap.action_get_events(actionName).is_empty():
			result.addError("InputMap action has no events: %s." % str(actionName))
	return result


func _testRunStateViewCreatesSummaries() -> ValidationResult:
	var result := ValidationResult.new()
	var runState := NewRunFactory.createNewRun(&"usa")
	var topBarData: Dictionary = RUN_STATE_VIEW.createTopBarData(runState)
	if int(topBarData.get("gold", 0)) != NewRunFactory.START_GOLD:
		result.addError("RunStateView top bar gold is wrong.")
	if int(topBarData.get("food", 0)) != NewRunFactory.START_FOOD:
		result.addError("RunStateView top bar food is wrong.")
	if int(topBarData.get("armyStrength", 0)) != NewRunFactory.START_INFANTRY + NewRunFactory.START_CAVALRY + NewRunFactory.START_ARTILLERY:
		result.addError("RunStateView army strength summary is wrong.")
	if str(topBarData.get("dateText", "")) != "Y1 M1 W1":
		result.addError("RunStateView date text is wrong.")

	var countryData: Dictionary = RUN_STATE_VIEW.createCountryPanelData(runState, &"usa")
	if str(countryData.get("name", "")) != "United States of America":
		result.addError("RunStateView country panel name is wrong.")
	if int(countryData.get("stationedArmyCount", 0)) != 1:
		result.addError("RunStateView stationed army count is wrong.")
	if not bool(countryData.get("canRecruit", false)):
		result.addError("RunStateView did not mark owned country as recruitable.")

	var armyData: Dictionary = RUN_STATE_VIEW.createArmyPanelData(runState, &"army_start")
	if str(armyData.get("status", "")) != "Stationed":
		result.addError("RunStateView army panel status is wrong.")
	if str(armyData.get("location", "")) != "United States of America":
		result.addError("RunStateView army panel location is wrong.")
	return result


func _testMainMenuFirstBootAndActions() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for main menu test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	var uiRoot = main.get_node("GameRoot/UIRoot")
	var worldRoot = main.get_node("GameRoot/WorldRoot")
	var gameManager := main.get_node("GameRoot/Managers/GameManager") as GameManager
	var saveManager := main.get_node("GameRoot/Managers/SaveManager") as SaveManager
	var mainMenu = main.get_node("GameRoot/UIRoot/Root/MainMenu")
	if uiRoot == null or mainMenu == null or worldRoot == null or saveManager == null:
		result.addError("Main menu boot nodes are missing.")
		_cleanupMainForTest(main)
		return result

	saveManager.deleteSave("manual_1")
	mainMenu.call("refreshSaveStatus")
	var continueButton := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/MainMenuPanel/MarginContainer/ButtonList/ContinueRunButton") as Button
	var loadButton := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/MainMenuPanel/MarginContainer/ButtonList/LoadGameButton") as Button
	var shopButton := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/MainMenuPanel/MarginContainer/ButtonList/ShopButton") as Button
	var ageRunButton := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/MainMenuPanel/MarginContainer/ButtonList/StartAgeRunHiddenButton") as Button
	var saveStatusLabel := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/InfoPanel/MarginContainer/InfoContent/SaveStatusLabel") as Label
	if not bool(uiRoot.call("isMainMenuVisible")):
		result.addError("Main menu was not visible on first boot.")
	if bool(worldRoot.visible):
		result.addError("Gameplay world was visible behind first boot menu.")
	if gameManager.getCurrentRunState() != null:
		result.addError("Main boot created a run before menu action.")
	if continueButton == null or loadButton == null or shopButton == null or ageRunButton == null:
		result.addError("Main menu is missing required buttons.")
	else:
		if not continueButton.disabled or not loadButton.disabled:
			result.addError("Missing-save buttons were not disabled.")
		if ageRunButton.visible:
			result.addError("Age Run debug button was visible by default.")
	if saveStatusLabel == null or saveStatusLabel.text != "No save found":
		result.addError("Main menu did not show missing save status.")

	if shopButton != null:
		shopButton.emit_signal("pressed")
		var menuShopPanel = main.get_node_or_null("GameRoot/UIRoot/Root/MainMenu/SafeArea/ModalLayer/MainMenuShopPanel")
		if menuShopPanel == null or not bool(menuShopPanel.visible):
			result.addError("Main menu Shop button did not open the shop panel.")
		mainMenu.call("closeOpenPanel")

	var newRunButton := main.get_node("GameRoot/UIRoot/Root/MainMenu/SafeArea/MainMenuPanel/MarginContainer/ButtonList/NewRunButton") as Button
	newRunButton.emit_signal("pressed")
	var countrySelectionPanel = main.get_node_or_null("GameRoot/UIRoot/Root/MainMenu/SafeArea/ModalLayer/CountrySelectionPanel")
	if countrySelectionPanel == null or not bool(countrySelectionPanel.visible):
		result.addError("New Run did not open the country selection panel.")
	else:
		var startSelectedCountryButton := countrySelectionPanel.find_child("StartSelectedCountryButton", true, false) as Button
		if startSelectedCountryButton == null:
			result.addError("Country selection panel is missing the start button.")
		else:
			startSelectedCountryButton.emit_signal("pressed")
	if gameManager.getCurrentRunState() == null:
		result.addError("New Run country selection did not start a run.")
	if bool(uiRoot.call("isMainMenuVisible")):
		result.addError("Main menu stayed visible after starting a run.")
	if not bool(worldRoot.visible):
		result.addError("Gameplay world did not become visible after starting a run.")

	_cleanupMainForTest(main)
	return result


func _testMainUiLayoutBindsStateAndCommands() -> ValidationResult:
	var result := ValidationResult.new()
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for UI test.")
		return result

	var main = scene.instantiate()
	add_child(main)
	_startMainRunForTest(main)
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

	var goldLabel := main.get_node("GameRoot/UIRoot/Root/TopBar/MarginContainer/HBoxContainer/GoldSection/GoldLabel") as Label
	var startingGold := int(gameManager.getCurrentRunState().resources.get("gold", 0))
	if not goldLabel.text.contains("Gold") or not goldLabel.text.contains(str(startingGold)) or not goldLabel.text.contains("/Monat"):
		result.addError("TopBar did not bind starting gold.")

	var threatLabel := main.get_node("GameRoot/UIRoot/Root/TopBar/MarginContainer/HBoxContainer/ThreatSection/ThreatLabel") as Label
	gameManager.getCurrentRunState().resources["threat"] = 55
	eventBus.raiseGameEvent(EventType.THREAT_CHANGED, {
		"threat": 55,
	})
	if not threatLabel.text.contains("Bedrohung") or not threatLabel.text.contains("55%"):
		result.addError("TopBar did not show high threat state.")

	var armyTitle := main.get_node("GameRoot/UIRoot/Root/LeftPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if armyTitle.text != "United States of America":
		result.addError("ArmyPanel did not bind player country.")

	var infantryButton := main.get_node("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/RecruitButtons/InfantryButton") as Button
	infantryButton.emit_signal("pressed")
	if not goldLabel.text.contains(str(startingGold - 10)):
		result.addError("Recruit button did not update top bar gold.")

	eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Normal,
	})
	simulationManager.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH)
	if not goldLabel.text.contains(str(startingGold - 10 + 35)):
		result.addError("TopBar did not update after month tick economy apply.")

	eventBus.requestCommand(CommandType.SELECT_COUNTRY, {
		"countryId": "can",
	})
	var countryTitle := main.get_node("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if countryTitle.text != "Canada":
		result.addError("CountryPanel did not update from country selection.")

	var attackButton := main.get_node_or_null("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/AttackButton") as Button
	if attackButton == null or not attackButton.visible or attackButton.disabled:
		result.addError("CountryPanel did not expose a valid attack button.")
	else:
		attackButton.emit_signal("pressed")
		var selectedArmy := gameManager.getCurrentRunState().armies.get(gameManager.getSelectedArmyId(), null) as ArmyData
		if selectedArmy == null or selectedArmy.status != ArmyStatus.Value.Attacking:
			result.addError("Attack button did not start an attack army.")
		var reserveArmy := gameManager.getCurrentRunState().armies.get(&"army_start", null) as ArmyData
		if reserveArmy == null or reserveArmy.status != ArmyStatus.Value.Stationed:
			result.addError("Attack button did not leave the source reserve stationed.")

	var pauseButton := main.get_node("GameRoot/UIRoot/Root/BottomBar/MarginContainer/HBoxContainer/PauseButton") as Button
	pauseButton.emit_signal("pressed")
	if gameManager.getCurrentRunState().speed != GameSpeed.Value.Paused:
		result.addError("TimeControls pause button did not request pause.")

	var shopButton := main.get_node_or_null("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/ShopButton") as Button
	var settingsButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/SettingsButton") as Button
	var returnToMainMenuButton := main.get_node("GameRoot/UIRoot/Root/ModalLayer/EscMenu/MarginContainer/VBoxContainer/ReturnToMainMenuButton") as Button
	var settingsPanel = main.get_node("GameRoot/UIRoot/Root/ModalLayer/SettingsPanel")
	var debugOverlay = main.get_node("GameRoot/UIRoot/Root/DebugErrorOverlay")
	var settingsManager = main.get_node("GameRoot/Managers/SettingsManager")
	if settingsManager != null:
		settingsManager.call("setSettingsPathForDebug", "user://paper_empire/debug_main_settings_test.json")
		settingsManager.call("deleteSettings")
	if shopButton != null:
		result.addError("ESC menu still exposes Shop.")
	if settingsButton == null or returnToMainMenuButton == null or settingsPanel == null or debugOverlay == null:
		result.addError("Menu extension UI is missing required nodes.")

	uiRoot.call("_openEscMenu")
	if not bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not open.")

	if settingsButton != null:
		settingsButton.emit_signal("pressed")
		if not bool(settingsPanel.get("visible")):
			result.addError("Settings button did not open settings panel.")
		uiRoot.call("_closeSettingsPanel")

	eventBus.reportDebugError("Cannot select unknown country: missing_country")
	if not str(debugOverlay.call("getLastMessage")).contains("unknown country"):
		result.addError("Debug error overlay did not show command warning.")

	uiRoot.call("_openEscMenu")
	uiRoot.call("_resumeFromEscMenu")
	if bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not close on resume.")
	if gameManager.getCurrentRunState().speed == GameSpeed.Value.Paused:
		result.addError("ESC menu resume did not restore speed.")

	uiRoot.call("_openEscMenu")
	if returnToMainMenuButton != null:
		returnToMainMenuButton.emit_signal("pressed")
		if not bool(uiRoot.call("isMainMenuVisible")):
			result.addError("Return to Main Menu did not show the main menu.")

	if settingsManager != null:
		settingsManager.call("deleteSettings")
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
	manager.startNewRun("usa")
	var can := manager.getCurrentRunState().countries[&"can"] as CountryData
	can.ownerId = GameIds.PLAYER_OWNER_ID
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
		"targetCountryId": "can",
	})
	if int(effectsLayer.call("getMovementFeedbackCount")) != 1:
		result.addError("EffectsLayer did not create movement feedback after armyMoveStarted.")

	bus.raiseGameEvent(EventType.BATTLE_STARTED, {
		"battleId": "battle_visual_test",
		"armyId": "army_start",
		"sourceCountryId": "usa",
		"targetCountryId": "can",
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
		"countryId": "can",
	})
	if int(effectsLayer.call("getOneShotFeedbackCount")) <= oneShotBefore:
		result.addError("EffectsLayer did not create conquest flash feedback.")

	oneShotBefore = int(effectsLayer.call("getOneShotFeedbackCount"))
	bus.raiseGameEvent(EventType.MISSILE_LAUNCHED, {
		"fromCountryId": "usa",
		"targetCountryId": "can",
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
	var runState := NewRunFactory.createNewRun(&"usa")
	runState.upgrades.append(&"rapidRecruitment")
	var battle := BattleData.new()
	battle.id = &"battle_save"
	battle.attackerArmyId = &"army_start"
	battle.sourceCountryId = &"usa"
	battle.targetCountryId = &"can"
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
	var usa: Dictionary = countries.get("usa", {})
	var center: Dictionary = usa.get("center", {})
	if float(center.get("x", -1.0)) <= 0.0 or float(center.get("y", -1.0)) <= 0.0:
		result.addError("Serialized country center is missing.")

	var armies: Dictionary = serialized.get("armies", {})
	var army: Dictionary = armies.get("army_start", {})
	if str(army.get("locationCountryId", "")) != "usa":
		result.addError("Serialized army location is wrong.")

	var battles: Dictionary = serialized.get("battles", {})
	var serializedBattle: Dictionary = battles.get("battle_save", {})
	if str(serializedBattle.get("targetCountryId", "")) != "can":
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

	var runState := NewRunFactory.createNewRun(&"usa")
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
		if not loadedCountries.has("usa"):
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
	_startMainRunForTest(main)
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
	if not countryUpgrades.has("usa"):
		result.addError("MetaProgress default country upgrades are missing.")

	metaData["crowns"] = 25
	(generalUpgrades["startGold"] as Dictionary)["level"] = 1
	var usaUpgrades := countryUpgrades["usa"] as Dictionary
	(usaUpgrades["usaDiscipline"] as Dictionary)["level"] = 1
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
	var runState := NewRunFactory.createNewRun(&"usa", metaData, metaUpgradeRows)
	runState.upgrades.append(&"rapidRecruitment")
	var conqueredCountry := runState.countries[&"can"] as CountryData
	conqueredCountry.ownerId = GameIds.PLAYER_OWNER_ID
	runState.runStatus = RunState.RUN_STATUS_LOST
	runState.runStats["countriesConquered"] = 1
	runState.runStats["maxCountriesOwned"] = 2
	runState.runStats["monthsSurvived"] = 4
	runState.runStats["battlesWon"] = 1
	runState.runStats["highestThreatReached"] = 75.0

	var reward: Dictionary = META_PROGRESS_SIMULATION.calculateCrownsReward(runState, metaData, metaUpgradeRows)
	if not bool(reward.get("accepted", false)):
		result.addError("MetaProgressSimulation rejected valid run reward.")
	if int(reward.get("crowns", 0)) != 76:
		result.addError("MetaProgressSimulation calculated wrong crown reward.")

	var awarded: Dictionary = META_PROGRESS_SIMULATION.awardRunEndCrowns(metaData, runState, metaUpgradeRows)
	if int(awarded.get("totalCrowns", 0)) != 76:
		result.addError("MetaProgressSimulation did not add rewarded crowns.")
	var secondAward: Dictionary = META_PROGRESS_SIMULATION.awardRunEndCrowns(metaData, runState, metaUpgradeRows)
	if bool(secondAward.get("accepted", false)):
		result.addError("MetaProgressSimulation allowed duplicate crown payout.")

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

	var bonusRun := NewRunFactory.createNewRun(&"usa", purchasedMeta, metaUpgradeRows)
	if int(bonusRun.resources.get("gold", 0)) != NewRunFactory.START_GOLD + 50:
		result.addError("NewRunFactory did not apply purchased starting gold bonus.")

	purchasedMeta["crowns"] = 50
	var countryPurchase: Dictionary = META_PROGRESS_SIMULATION.purchaseUpgrade(purchasedMeta, &"usaDiscipline", metaUpgradeRows)
	var countryMeta := countryPurchase.get("metaProgress", {}) as Dictionary
	var countryBonusRun := NewRunFactory.createNewRun(&"usa", countryMeta, metaUpgradeRows)
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
	manager.startNewRun("usa")
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


func _testSettingsManagerSavesAndAppliesSettings() -> ValidationResult:
	var result := ValidationResult.new()
	var settingsPath := "user://paper_empire/debug_settings_test.json"
	var audio := AudioManager.new()
	var manager = SETTINGS_MANAGER_SCRIPT.new()
	add_child(audio)
	add_child(manager)
	audio.ensureAudioBuses()
	manager.call("setSettingsPathForDebug", settingsPath)
	manager.call("deleteSettings")
	var defaults := manager.call("loadSettings") as Dictionary
	if not USER_SETTINGS.isValidDictionary(defaults):
		result.addError("SettingsManager did not load valid default settings.")

	manager.call("configure", audio, null)
	manager.call("updateSetting", &"sfxVolume", 0.4)
	var sfxBusIndex := AudioServer.get_bus_index(AudioManager.BUS_SFX)
	if sfxBusIndex < 0:
		result.addError("SettingsManager test could not find SFX bus.")
	elif not is_equal_approx(AudioServer.get_bus_volume_db(sfxBusIndex), linear_to_db(0.4)):
		result.addError("SettingsManager did not apply SFX volume immediately.")

	var loadedManager = SETTINGS_MANAGER_SCRIPT.new()
	add_child(loadedManager)
	loadedManager.call("setSettingsPathForDebug", settingsPath)
	var loaded := loadedManager.call("loadSettings") as Dictionary
	if not is_equal_approx(float(loaded.get("sfxVolume", 0.0)), 0.4):
		result.addError("SettingsManager did not persist changed settings.")

	manager.call("deleteSettings")
	if sfxBusIndex >= 0:
		AudioServer.set_bus_volume_db(sfxBusIndex, linear_to_db(1.0))
	remove_child(loadedManager)
	remove_child(manager)
	remove_child(audio)
	loadedManager.free()
	manager.free()
	audio.free()
	return result


func _testSettingsPanelSendsSettingChanges() -> ValidationResult:
	var result := ValidationResult.new()
	var panel = SETTINGS_PANEL_SCRIPT.new()
	add_child(panel)
	lastSettingKey = GameIds.EMPTY_ID
	lastSettingValue = null
	panel.connect("settingChanged", Callable(self, "_recordSettingChange"))
	panel.call("setData", USER_SETTINGS.createDefaultData())

	var sfxSlider := panel.get("sfxSlider") as HSlider
	if sfxSlider == null:
		result.addError("SettingsPanel did not create SFX slider.")
	else:
		sfxSlider.emit_signal("value_changed", 0.35)
		if lastSettingKey != &"sfxVolume" or not is_equal_approx(float(lastSettingValue), 0.35):
			result.addError("SettingsPanel did not emit SFX volume change.")

	var uiScaleSlider := panel.get("uiScaleSlider") as HSlider
	var acceptButton := panel.get("acceptButton") as Button
	if uiScaleSlider == null or acceptButton == null:
		result.addError("SettingsPanel did not create UI Scale accept controls.")
	else:
		lastSettingKey = GameIds.EMPTY_ID
		lastSettingValue = null
		uiScaleSlider.value = 1.4
		if lastSettingKey == &"uiScale":
			result.addError("SettingsPanel emitted UI Scale before Accept.")
		if acceptButton.disabled:
			result.addError("SettingsPanel did not enable Accept for pending UI Scale.")
		acceptButton.emit_signal("pressed")
		if lastSettingKey != &"uiScale" or not is_equal_approx(float(lastSettingValue), 1.4):
			result.addError("SettingsPanel did not emit UI Scale on Accept.")

	var windowModeDropdown := panel.get("windowModeDropdown") as OptionButton
	if windowModeDropdown == null:
		result.addError("SettingsPanel did not create window mode dropdown.")
	else:
		lastSettingKey = GameIds.EMPTY_ID
		lastSettingValue = null
		windowModeDropdown.emit_signal("item_selected", 1)
		if lastSettingKey == &"windowMode":
			result.addError("SettingsPanel emitted window mode before Accept.")
		if acceptButton != null:
			acceptButton.emit_signal("pressed")
			if lastSettingKey != &"windowMode" or str(lastSettingValue) != USER_SETTINGS.WINDOW_MODE_FULLSCREEN:
				result.addError("SettingsPanel did not emit fullscreen mode change on Accept.")

	var resolutionDropdown := panel.get("resolutionDropdown") as OptionButton
	if resolutionDropdown == null:
		result.addError("SettingsPanel did not create resolution dropdown.")
	else:
		lastSettingKey = GameIds.EMPTY_ID
		lastSettingValue = null
		resolutionDropdown.emit_signal("item_selected", 0)
		if lastSettingKey == &"resolution":
			result.addError("SettingsPanel emitted resolution before Accept.")
		if acceptButton != null:
			acceptButton.emit_signal("pressed")
			if lastSettingKey != &"resolution" or str(lastSettingValue) != "1280x720":
				result.addError("SettingsPanel did not emit resolution change on Accept.")

	remove_child(panel)
	panel.free()
	return result


func _testPlatformServiceMockRecordsAchievements() -> ValidationResult:
	var result := ValidationResult.new()
	var service = MOCK_PLATFORM_SERVICE_SCRIPT.new()
	add_child(service)
	if not bool(service.call("initialize")):
		result.addError("MockPlatformService did not initialize.")
	if not bool(service.call("isAvailable")):
		result.addError("MockPlatformService did not report availability after initialize.")
	if not bool(service.call("unlockAchievement", ACHIEVEMENT_EVENT_MAP.ACHIEVEMENT_FIRST_CONQUEST)):
		result.addError("MockPlatformService rejected achievement unlock.")
	if not bool(service.call("hasUnlockedAchievement", ACHIEVEMENT_EVENT_MAP.ACHIEVEMENT_FIRST_CONQUEST)):
		result.addError("MockPlatformService did not record unlocked achievement.")
	if not bool(service.call("setStat", &"runs_finished", 3)):
		result.addError("MockPlatformService rejected stat write.")
	if int(service.call("getStat", &"runs_finished")) != 3:
		result.addError("MockPlatformService did not store stat value.")

	remove_child(service)
	service.free()
	return result


func _testPlatformEventBridgeUnlocksMappedAchievements() -> ValidationResult:
	var result := ValidationResult.new()
	var bus := EventBus.new()
	var service = MOCK_PLATFORM_SERVICE_SCRIPT.new()
	var bridge = PLATFORM_EVENT_BRIDGE_SCRIPT.new()
	add_child(bus)
	add_child(service)
	add_child(bridge)
	service.call("initialize")
	bridge.call("configure", bus, service)

	bus.raiseGameEvent(EventType.COUNTRY_CONQUERED, {
		"countryId": "can",
	})
	if not bool(service.call("hasUnlockedAchievement", ACHIEVEMENT_EVENT_MAP.ACHIEVEMENT_FIRST_CONQUEST)):
		result.addError("PlatformEventBridge did not unlock conquest achievement.")

	bus.raiseGameEvent(EventType.CROWNS_REWARDED, {
		"runStatus": RunState.RUN_STATUS_WON,
	})
	if not bool(service.call("hasUnlockedAchievement", ACHIEVEMENT_EVENT_MAP.ACHIEVEMENT_RUN_WON)):
		result.addError("PlatformEventBridge did not unlock run won achievement.")

	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		result.addError("Main.tscn could not be loaded for platform service test.")
	else:
		var main = scene.instantiate()
		add_child(main)
		var mainPlatformService = main.get_node("GameRoot/Managers/PlatformService")
		var mainBridge = main.get_node("GameRoot/Managers/PlatformEventBridge")
		if mainPlatformService == null or mainBridge == null:
			result.addError("Main scene did not create platform service bridge.")
		_cleanupMainForTest(main)

	remove_child(bridge)
	remove_child(service)
	remove_child(bus)
	bridge.free()
	service.free()
	bus.free()
	return result


func _testVerticalSliceBalanceEnvelope() -> ValidationResult:
	var result := ValidationResult.new()
	var countries := PrototypeContentLoader.loadCountries()
	var units := PrototypeContentLoader.loadUnits()
	if countries.size() < 110 or countries.size() > 150:
		result.addError("Vertical slice country count is outside 110-150: %d." % countries.size())
	if units.size() != 3:
		result.addError("Vertical slice does not expose exactly three unit types.")

	var runState := NewRunFactory.createNewRun(&"usa")
	var startingArmy := runState.armies[&"army_start"] as ArmyData
	var startingPower := COMBAT_SIMULATION.calculateArmyCombatPower(startingArmy, units, runState.economy, {
		"targetDefense": 10,
	})
	var mex := runState.countries[&"mex"] as CountryData
	var chn := runState.countries[&"chn"] as CountryData
	var earlyDefense := _countryDefenseWithLocalArmies(runState, mex, units)
	var lateDefense := _countryDefenseWithLocalArmies(runState, chn, units)
	if startingPower <= earlyDefense:
		result.addError("Starting army cannot beat an early neighbor.")
	if startingPower >= lateDefense:
		result.addError("Starting army can already beat the late world country; slice is too trivial.")

	var infantry := _unitFromCatalog(GameIds.INFANTRY_UNIT_ID)
	var infantryCost: Dictionary = RECRUITMENT_SIMULATION.calculateRecruitmentCost(infantry, 1, runState.upgradeEffects)
	if int(infantryCost.get("goldCost", 0)) > NewRunFactory.START_GOLD:
		result.addError("Player cannot afford first infantry recruitment from starting gold.")

	var income: Dictionary = ECONOMY_SIMULATION.calculateMonthlyIncome(runState)
	if int(income.get("gold", 0)) <= 0 or int(income.get("food", 0)) <= 0:
		result.addError("Starting country does not produce positive economy income.")
	return result


func _testVerticalSliceMiniRunReachesWinStatus() -> ValidationResult:
	var result := ValidationResult.new()
	var manager := GameManager.new()
	var simulation := SimulationManager.new()
	var bus := EventBus.new()
	var saveManager := SaveManager.new()
	var slotId := "debug_vertical_slice_gate"
	add_child(manager)
	add_child(simulation)
	add_child(bus)
	add_child(saveManager)
	saveManager.deleteSave(slotId)
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)
	manager.setSimulationManager(simulation)
	manager.setSaveManager(saveManager)
	manager.startNewRun("usa")

	var runState := manager.getCurrentRunState()
	runState.resources["gold"] = 7000
	runState.resources["food"] = 1000
	bus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": "usa",
		"unitType": "artillery",
		"amount": 24,
	})
	bus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": "usa",
		"unitType": "infantry",
		"amount": 20,
	})
	var army := runState.armies[&"army_start"] as ArmyData
	if int(army.units.get(GameIds.ARTILLERY_UNIT_ID, 0)) < NewRunFactory.START_ARTILLERY + 24:
		result.addError("Vertical slice recruitment did not add artillery.")

	bus.requestCommand(CommandType.START_ATTACK, {
		"armyId": "army_start",
		"targetCountryId": "can",
	})
	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5 + COMBAT_SIMULATION.BATTLE_DURATION_SECONDS)
	_chooseFirstUpgradeForVerticalSlice(manager, bus, result)
	if (manager.getCurrentRunState().countries[&"can"] as CountryData).ownerId != GameIds.PLAYER_OWNER_ID:
		result.addError("Vertical slice first conquest failed.")

	var savedGold := int(manager.getCurrentRunState().resources.get("gold", 0))
	bus.requestCommand(CommandType.SAVE_GAME, {
		"slotId": slotId,
	})
	manager.getCurrentRunState().resources["gold"] = 1
	bus.requestCommand(CommandType.LOAD_GAME, {
		"slotId": slotId,
	})
	if int(manager.getCurrentRunState().resources.get("gold", 0)) != savedGold:
		result.addError("Vertical slice save/load did not restore resources.")

	var finalTargetId := &"mex"
	var finalArmy := manager.getCurrentRunState().armies.get(manager.getSelectedArmyId(), null) as ArmyData
	if finalArmy != null:
		finalArmy.units = {
			GameIds.INFANTRY_UNIT_ID: 180,
			GameIds.CAVALRY_UNIT_ID: 24,
			GameIds.ARTILLERY_UNIT_ID: 12,
		}
	for countryId in manager.getCurrentRunState().countries.keys():
		var country := manager.getCurrentRunState().countries[countryId] as CountryData
		if country != null and country.id != finalTargetId:
			country.ownerId = GameIds.PLAYER_OWNER_ID

	_moveArmyForVerticalSlice(manager, simulation, bus, &"usa", result)
	_attackForVerticalSlice(manager, simulation, bus, finalTargetId, result)

	var finalState := manager.getCurrentRunState()
	if finalState.runStatus != RunState.RUN_STATUS_WON:
		result.addError("Vertical slice did not end with won run status.")
	if not _capturedEvent(EventType.RUN_WON):
		result.addError("Vertical slice did not emit runWon.")
	for countryId in finalState.countries.keys():
		var country := finalState.countries[countryId] as CountryData
		if country != null and country.ownerId != GameIds.PLAYER_OWNER_ID:
			result.addError("Vertical slice left country unconquered: %s." % str(countryId))

	var validation := RunStateValidator.validate(finalState)
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Vertical slice produced invalid RunState: %s" % error)

	saveManager.deleteSave(slotId)
	remove_child(saveManager)
	remove_child(bus)
	remove_child(simulation)
	remove_child(manager)
	saveManager.free()
	bus.free()
	simulation.free()
	manager.free()
	return result


func _recordGameEvent(eventName: StringName, payload: Dictionary) -> void:
	capturedEvents.append({
		"eventName": eventName,
		"payload": payload,
	})


func _recordShopPurchase(upgradeId: StringName) -> void:
	lastShopUpgradeId = upgradeId


func _recordSettingChange(settingKey: StringName, value: Variant) -> void:
	lastSettingKey = settingKey
	lastSettingValue = value


func _attackForVerticalSlice(
	manager: GameManager,
	simulation: SimulationManager,
	bus: EventBus,
	targetCountryId: StringName,
	result: ValidationResult
) -> void:
	if not result.isValid():
		return

	bus.requestCommand(CommandType.START_ATTACK, {
		"armyId": str(manager.getSelectedArmyId()),
		"targetCountryId": str(targetCountryId),
	})
	var army := manager.getCurrentRunState().armies[manager.getSelectedArmyId()] as ArmyData
	if army.status != ArmyStatus.Value.Attacking:
		result.addError("Vertical slice could not start attack on %s." % str(targetCountryId))
		return

	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5 + COMBAT_SIMULATION.BATTLE_DURATION_SECONDS)
	var country := manager.getCurrentRunState().countries[targetCountryId] as CountryData
	if country.ownerId != GameIds.PLAYER_OWNER_ID:
		result.addError("Vertical slice did not conquer %s." % str(targetCountryId))
		return

	if manager.getCurrentRunState().runStatus == RunState.RUN_STATUS_ACTIVE:
		_chooseFirstUpgradeForVerticalSlice(manager, bus, result)


func _moveArmyForVerticalSlice(
	manager: GameManager,
	simulation: SimulationManager,
	bus: EventBus,
	targetCountryId: StringName,
	result: ValidationResult
) -> void:
	if not result.isValid():
		return

	bus.requestCommand(CommandType.MOVE_ARMY, {
		"armyId": str(manager.getSelectedArmyId()),
		"targetCountryId": str(targetCountryId),
	})
	simulation.stepSimulation(ARMY_MOVEMENT_SIMULATION.MOVEMENT_SECONDS_PER_EDGE * 1.5)
	var army := manager.getCurrentRunState().armies[manager.getSelectedArmyId()] as ArmyData
	if army.locationCountryId != targetCountryId or army.status != ArmyStatus.Value.Stationed:
		result.addError("Vertical slice did not move army to %s." % str(targetCountryId))


func _chooseFirstUpgradeForVerticalSlice(manager: GameManager, bus: EventBus, result: ValidationResult) -> void:
	var runState := manager.getCurrentRunState()
	if not bool(runState.activeUpgradeChoice.get("isOpen", false)):
		return

	var choices: Array = runState.activeUpgradeChoice.get("choices", [])
	if choices.is_empty() or not (choices[0] is Dictionary):
		result.addError("Vertical slice opened upgrade choice without valid choices.")
		return

	var choice := choices[0] as Dictionary
	bus.requestCommand(CommandType.CHOOSE_UPGRADE, {
		"upgradeId": str(choice.get("id", "")),
	})
	if bool(runState.activeUpgradeChoice.get("isOpen", false)):
		result.addError("Vertical slice upgrade choice did not close.")


func _capturedEvent(eventName: StringName) -> bool:
	for event in capturedEvents:
		if event.get("eventName", GameIds.EMPTY_ID) == eventName:
			return true
	return false


func _eventRowsContain(events: Array[Dictionary], eventName: StringName) -> bool:
	for event in events:
		if StringName(str(event.get("eventType", ""))) == eventName:
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
	army.locationCountryId = &"usa"
	army.targetCountryId = &"can"
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


func _createAiWarTestRunState() -> RunState:
	var runState := RunState.new()
	var sourceOwnerId := GameIds.npcOwnerIdForCountry(&"aiSource")
	var targetOwnerId := GameIds.npcOwnerIdForCountry(&"aiTarget")
	var sourceNeighbors: Array[StringName] = [&"aiTarget"]
	var targetNeighbors: Array[StringName] = [&"aiSource"]
	var sourceCountry := _createCountry(&"aiSource", "AI Source", sourceOwnerId, Vector2(100.0, 100.0), sourceNeighbors)
	var targetCountry := _createCountry(&"aiTarget", "AI Target", targetOwnerId, Vector2(180.0, 100.0), targetNeighbors)
	sourceCountry.defense = 10
	sourceCountry.aiAggression = 1.0
	sourceCountry.aiExpansionDesire = 1.0
	sourceCountry.aiAttackCooldownMonths = AI_WAR_SIMULATION.NPC_ATTACK_COOLDOWN_MONTHS
	targetCountry.defense = 1
	runState.countries[sourceCountry.id] = sourceCountry
	runState.countries[targetCountry.id] = targetCountry

	var sourceArmy := ArmyData.new()
	sourceArmy.id = &"army_ai_source"
	sourceArmy.ownerId = sourceOwnerId
	sourceArmy.locationCountryId = sourceCountry.id
	sourceArmy.units = {
		GameIds.INFANTRY_UNIT_ID: 90,
		GameIds.CAVALRY_UNIT_ID: 12,
		GameIds.ARTILLERY_UNIT_ID: 4,
	}
	runState.armies[sourceArmy.id] = sourceArmy

	var targetArmy := ArmyData.new()
	targetArmy.id = &"army_ai_target"
	targetArmy.ownerId = targetOwnerId
	targetArmy.locationCountryId = targetCountry.id
	targetArmy.units = {
		GameIds.INFANTRY_UNIT_ID: 1,
	}
	runState.armies[targetArmy.id] = targetArmy

	runState.resources = {
		"gold": 0,
		"food": 0,
		"threat": 0,
	}
	runState.speed = GameSpeed.Value.Normal
	runState.runStatus = RunState.RUN_STATUS_ACTIVE
	return runState


func _createAiVsPlayerWarTestRunState() -> RunState:
	var runState := RunState.new()
	var sourceOwnerId := GameIds.npcOwnerIdForCountry(&"aiSource")
	var sourceNeighbors: Array[StringName] = [&"playerBorder"]
	var playerNeighbors: Array[StringName] = [&"aiSource"]
	var sourceCountry := _createCountry(&"aiSource", "AI Source", sourceOwnerId, Vector2(100.0, 100.0), sourceNeighbors)
	var playerCountry := _createCountry(&"playerBorder", "Player Border", GameIds.PLAYER_OWNER_ID, Vector2(180.0, 100.0), playerNeighbors)
	sourceCountry.defense = 10
	sourceCountry.aiAggression = 1.0
	sourceCountry.aiExpansionDesire = 1.0
	sourceCountry.aiAttackCooldownMonths = AI_WAR_SIMULATION.NPC_ATTACK_COOLDOWN_MONTHS
	playerCountry.defense = 1
	runState.countries[sourceCountry.id] = sourceCountry
	runState.countries[playerCountry.id] = playerCountry

	var sourceArmy := ArmyData.new()
	sourceArmy.id = &"army_ai_source"
	sourceArmy.ownerId = sourceOwnerId
	sourceArmy.locationCountryId = sourceCountry.id
	sourceArmy.units = {
		GameIds.INFANTRY_UNIT_ID: 40,
		GameIds.CAVALRY_UNIT_ID: 8,
		GameIds.ARTILLERY_UNIT_ID: 2,
	}
	runState.armies[sourceArmy.id] = sourceArmy

	runState.resources = {
		"gold": 0,
		"food": 0,
		"threat": AI_WAR_SIMULATION.HIGH_PLAYER_THREAT,
	}
	runState.speed = GameSpeed.Value.Normal
	runState.runStatus = RunState.RUN_STATUS_ACTIVE
	return runState


func _createValidCountries() -> Array[CountryData]:
	var countries: Array[CountryData] = []
	var usaNeighbors: Array[StringName] = [&"can"]
	var canNeighbors: Array[StringName] = [&"usa"]
	countries.append(_createCountry(&"usa", "United States of America", GameIds.PLAYER_OWNER_ID, Vector2(100.0, 120.0), usaNeighbors))
	countries.append(_createCountry(&"can", "Canada", GameIds.NEUTRAL_OWNER_ID, Vector2(180.0, 125.0), canNeighbors))
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


func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += int(units.get(unitId, 0))
	return total


func _attackingArmyForTarget(runState: RunState, targetCountryId: StringName, ownerId: StringName) -> ArmyData:
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue
		if army.ownerId == ownerId and army.status == ArmyStatus.Value.Attacking and army.targetCountryId == targetCountryId:
			return army
	return null


func _countryDefenseWithLocalArmies(runState: RunState, country: CountryData, units: Array[UnitData]) -> float:
	var power := COMBAT_SIMULATION.calculateCountryDefensePower(country, runState.upgradeEffects, runState.worldReaction)
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.locationCountryId != country.id or army.ownerId == GameIds.PLAYER_OWNER_ID:
			continue
		power += COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {})
	return power


func _countryShapeBounds(center: Vector2, points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(center + points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(center + point)
	return bounds


func _mapShapePolygons(shapeValue: Variant) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	if shapeValue is PackedVector2Array:
		polygons.append(shapeValue as PackedVector2Array)
	elif shapeValue is Array:
		for polygonValue in shapeValue:
			if polygonValue is PackedVector2Array:
				polygons.append(polygonValue as PackedVector2Array)
	return polygons


func _cleanupMainForTest(main: Node) -> void:
	if main.get_parent() == self:
		remove_child(main)
	main.free()


func _startMainRunForTest(main: Node) -> void:
	if main.has_method("_startNewRunFromMenu"):
		main.call("_startNewRunFromMenu", "usa")
