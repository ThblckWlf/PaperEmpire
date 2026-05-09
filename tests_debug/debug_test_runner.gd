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
	_runTest("Prototype map shapes fixture loads and validates", _testPrototypeMapShapesFixture)
	_runTest("NewRunFactory creates valid prototype run", _testNewRunFactory)
	_runTest("GameManager commands update state and emit events", _testGameManagerCommands)
	_runTest("GameTime advances deterministically", _testGameTimeAdvances)
	_runTest("SimulationManager applies speed and emits monthTick", _testSimulationManagerTicks)
	_runTest("WorldMap creates country nodes", _testWorldMapCreatesCountryNodes)
	_runTest("MapCamera clamps pan and zoom", _testMapCameraClampsPanAndZoom)

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


func _testWorldMapCreatesCountryNodes() -> ValidationResult:
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


func _countryShapeBounds(center: Vector2, points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(center + points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(center + point)
	return bounds
