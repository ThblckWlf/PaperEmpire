extends Node
class_name DebugTestRunner


var totalTests: int = 0
var failedTests: int = 0
var capturedEvents: Array[Dictionary] = []


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
	_runTest("NewRunFactory creates valid prototype run", _testNewRunFactory)
	_runTest("GameManager commands update state and emit events", _testGameManagerCommands)

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
	var bus := EventBus.new()
	capturedEvents.clear()
	bus.gameEventRaised.connect(_recordGameEvent)
	manager.setEventBus(bus)

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

	if not _capturedEvent(EventType.RUN_STARTED):
		result.addError("GameManager did not emit runStarted.")

	if not _capturedEvent(EventType.COUNTRY_SELECTED):
		result.addError("GameManager did not emit countrySelected.")

	if not _capturedEvent(EventType.GAME_SPEED_CHANGED):
		result.addError("GameManager did not emit gameSpeedChanged.")

	if not _capturedEvent(EventType.RUN_RESET):
		result.addError("GameManager did not emit runReset.")

	manager.free()
	bus.free()
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
