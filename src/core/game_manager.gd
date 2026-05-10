extends Node
class_name GameManager


const ARMY_MOVEMENT_SIMULATION := preload("res://src/core/simulation/army_movement_simulation.gd")
const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")

var currentRunState: RunState
var eventBus: EventBus
var simulationManager: SimulationManager
var selectedCountryId: StringName = GameIds.EMPTY_ID
var selectedArmyId: StringName = GameIds.EMPTY_ID


func setEventBus(newEventBus: EventBus) -> void:
	_disconnectEventBusCommands()
	eventBus = newEventBus
	_connectEventBusCommands()
	if simulationManager != null:
		simulationManager.setEventBus(eventBus)


func setSimulationManager(newSimulationManager: SimulationManager) -> void:
	simulationManager = newSimulationManager
	_configureSimulationManager()


func startNewRun(startCountryId: String) -> void:
	currentRunState = NewRunFactory.createNewRun(StringName(startCountryId))
	selectedCountryId = StringName(startCountryId)
	selectedArmyId = _firstArmyId()
	_configureSimulationManager()
	_raiseEvent(EventType.RUN_STARTED, {
		"startCountryId": selectedCountryId,
		"selectedArmyId": selectedArmyId,
	})


func submitCommand(commandName: StringName, payload: Dictionary = {}) -> void:
	match commandName:
		CommandType.SELECT_COUNTRY:
			_selectCountry(StringName(str(payload.get("countryId", ""))))
		CommandType.SELECT_ARMY:
			_selectArmy(StringName(str(payload.get("armyId", ""))))
		CommandType.MOVE_ARMY:
			_moveArmy(
				StringName(str(payload.get("armyId", selectedArmyId))),
				StringName(str(payload.get("targetCountryId", "")))
			)
		CommandType.START_ATTACK:
			_startAttack(
				StringName(str(payload.get("armyId", selectedArmyId))),
				StringName(str(payload.get("targetCountryId", "")))
			)
		CommandType.RECRUIT_UNITS:
			_recruitUnits(
				StringName(str(payload.get("countryId", selectedCountryId))),
				StringName(str(payload.get("unitType", payload.get("unitId", "")))),
				int(payload.get("amount", 0))
			)
		CommandType.CREATE_ARMY:
			_createArmy(StringName(str(payload.get("countryId", selectedCountryId))))
		CommandType.SET_GAME_SPEED:
			_setGameSpeed(int(payload.get("speed", GameSpeed.Value.Normal)))
		CommandType.PAUSE_GAME:
			_setGameSpeed(GameSpeed.Value.Paused)
		CommandType.RESUME_GAME:
			_setGameSpeed(GameSpeed.Value.Normal)
		CommandType.RESET_RUN:
			resetRun(StringName(str(payload.get("startCountryId", selectedCountryId))))
		_:
			push_warning("Unknown command: %s" % commandName)


func resetRun(startCountryId: StringName = GameIds.EMPTY_ID) -> void:
	var nextStartCountryId := startCountryId
	if nextStartCountryId == GameIds.EMPTY_ID:
		nextStartCountryId = selectedCountryId

	if nextStartCountryId == GameIds.EMPTY_ID:
		nextStartCountryId = NewRunFactory.DEFAULT_START_COUNTRY_ID

	currentRunState = NewRunFactory.createNewRun(nextStartCountryId)
	selectedCountryId = nextStartCountryId
	selectedArmyId = _firstArmyId()
	_configureSimulationManager()
	_raiseEvent(EventType.RUN_RESET, {
		"startCountryId": nextStartCountryId,
		"selectedArmyId": selectedArmyId,
	})


func getCurrentRunState() -> RunState:
	return currentRunState


func hasActiveRun() -> bool:
	return currentRunState != null and currentRunState.runStatus == RunState.RUN_STATUS_ACTIVE


func getSelectedCountryId() -> StringName:
	return selectedCountryId


func getSelectedArmyId() -> StringName:
	return selectedArmyId


func _selectCountry(countryId: StringName) -> void:
	if currentRunState == null or not currentRunState.countries.has(countryId):
		push_warning("Cannot select unknown country: %s" % countryId)
		return

	selectedCountryId = countryId
	_raiseEvent(EventType.COUNTRY_SELECTED, {
		"countryId": countryId,
	})


func _selectArmy(armyId: StringName) -> void:
	if currentRunState == null or not currentRunState.armies.has(armyId):
		push_warning("Cannot select unknown army: %s" % armyId)
		return

	selectedArmyId = armyId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": armyId,
	})


func _moveArmy(armyId: StringName, targetCountryId: StringName) -> void:
	var moveResult: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(currentRunState, armyId, targetCountryId)
	if not bool(moveResult.get("accepted", false)):
		push_warning("Cannot move army: %s" % str(moveResult.get("reason", "unknown_reason")))
		return

	selectedArmyId = armyId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": armyId,
	})
	_raiseEvent(EventType.ARMY_MOVE_STARTED, moveResult)


func _startAttack(armyId: StringName, targetCountryId: StringName) -> void:
	var attackResult: Dictionary = COMBAT_SIMULATION.startAttack(
		currentRunState,
		armyId,
		targetCountryId,
		PrototypeContentLoader.loadUnits()
	)
	if not bool(attackResult.get("accepted", false)):
		push_warning("Cannot start attack: %s" % str(attackResult.get("reason", "unknown_reason")))
		return

	selectedArmyId = armyId
	selectedCountryId = targetCountryId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})
	_raiseEvent(EventType.COUNTRY_SELECTED, {
		"countryId": selectedCountryId,
	})
	_raiseEvent(EventType.BATTLE_STARTED, attackResult)


func _recruitUnits(countryId: StringName, unitId: StringName, amount: int) -> void:
	var recruitResult: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(
		currentRunState,
		countryId,
		unitId,
		amount,
		PrototypeContentLoader.loadUnits(),
		selectedArmyId
	)
	if not bool(recruitResult.get("accepted", false)):
		push_warning("Cannot recruit units: %s" % str(recruitResult.get("reason", "unknown_reason")))
		return

	selectedCountryId = countryId
	selectedArmyId = StringName(str(recruitResult.get("armyId", selectedArmyId)))
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})
	_raiseEvent(EventType.UNITS_RECRUITED, recruitResult)


func _createArmy(countryId: StringName) -> void:
	var createResult: Dictionary = RECRUITMENT_SIMULATION.createArmy(currentRunState, countryId)
	if not bool(createResult.get("accepted", false)):
		push_warning("Cannot create army: %s" % str(createResult.get("reason", "unknown_reason")))
		return

	selectedCountryId = countryId
	selectedArmyId = StringName(str(createResult.get("armyId", GameIds.EMPTY_ID)))
	_raiseEvent(EventType.ARMY_CREATED, createResult)
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})


func _setGameSpeed(speed: int) -> void:
	if currentRunState == null:
		push_warning("Cannot set speed without an active run.")
		return

	var validSpeeds := [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	]
	if not validSpeeds.has(speed):
		push_warning("Cannot set invalid game speed: %s" % speed)
		return

	if simulationManager != null:
		if not simulationManager.setGameSpeed(speed):
			return
	else:
		currentRunState.speed = speed

	_raiseEvent(EventType.GAME_SPEED_CHANGED, {
		"speed": speed,
	})


func _raiseEvent(eventType: StringName, payload: Dictionary = {}) -> void:
	if eventBus == null:
		return

	var gameEvent := GameEvent.new()
	gameEvent.type = eventType
	gameEvent.payload = payload
	if currentRunState != null:
		gameEvent.occurredAtSeconds = float(currentRunState.time.get("elapsedSeconds", 0.0))

	eventBus.raiseEvent(gameEvent)


func _configureSimulationManager() -> void:
	if simulationManager != null:
		simulationManager.configure(currentRunState, eventBus)


func _firstArmyId() -> StringName:
	if currentRunState == null or currentRunState.armies.is_empty():
		return GameIds.EMPTY_ID

	var armyIds := currentRunState.armies.keys()
	armyIds.sort()
	return StringName(str(armyIds[0]))


func _connectEventBusCommands() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "submitCommand")
	if not eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.connect(commandCallable)


func _disconnectEventBusCommands() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "submitCommand")
	if eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.disconnect(commandCallable)
