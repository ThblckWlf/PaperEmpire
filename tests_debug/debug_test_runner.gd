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
	_runTest("Prototype mini goals fixture loads and validates", _testPrototypeMiniGoalsFixture)
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
	_runTest("WorldMap creates country and army nodes", _testWorldMapCreatesCountryAndArmyNodes)
	_runTest("MapCamera clamps pan and zoom", _testMapCameraClampsPanAndZoom)
	_runTest("RunStateView creates UI summaries", _testRunStateViewCreatesSummaries)
	_runTest("Main UI layout binds state and commands", _testMainUiLayoutBindsStateAndCommands)

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


func _testPrototypeMiniGoalsFixture() -> ValidationResult:
	return MiniGoalDataValidator.validate(PrototypeContentLoader.loadMiniGoals())


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

	var validation := RunStateValidator.validate(manager.getCurrentRunState())
	if not validation.isValid():
		for error in validation.errors:
			result.addError("Battle completion produced invalid RunState: %s" % error)

	manager.free()
	simulation.free()
	bus.free()
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
	if goldLabel.text != "Gold: %d" % NewRunFactory.START_GOLD:
		result.addError("TopBar did not bind starting gold.")

	var armyTitle := main.get_node("GameRoot/UIRoot/Root/LeftPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if armyTitle.text != "army_start":
		result.addError("ArmyPanel did not bind selected army.")

	var infantryButton := main.get_node("GameRoot/UIRoot/Root/RightPanel/MarginContainer/VBoxContainer/RecruitButtons/InfantryButton") as Button
	infantryButton.emit_signal("pressed")
	if goldLabel.text != "Gold: %d" % (NewRunFactory.START_GOLD - 50):
		result.addError("Recruit button did not update top bar gold.")

	eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Normal,
	})
	simulationManager.stepSimulation(GameTime.SECONDS_PER_WEEK_AT_1X * GameTime.WEEKS_PER_MONTH)
	if goldLabel.text != "Gold: %d" % (NewRunFactory.START_GOLD - 50 + 35):
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

	uiRoot.call("_openEscMenu")
	if not bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not open.")

	uiRoot.call("_resumeFromEscMenu")
	if bool(uiRoot.call("isEscMenuOpen")):
		result.addError("ESC menu did not close on resume.")
	if gameManager.getCurrentRunState().speed == GameSpeed.Value.Paused:
		result.addError("ESC menu resume did not restore speed.")

	_cleanupMainForTest(main)
	return result


func _recordGameEvent(eventName: StringName, payload: Dictionary) -> void:
	capturedEvents.append({
		"eventName": eventName,
		"payload": payload,
	})


func _capturedEvent(eventName: StringName) -> bool:
	for event in capturedEvents:
		if event.get("eventName", GameIds.EMPTY_ID) == eventName:
			return true
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
