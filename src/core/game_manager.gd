extends Node
class_name GameManager


var currentRunState: RunState
var eventBus: EventBus
var selectedCountryId: StringName = GameIds.EMPTY_ID


func setEventBus(newEventBus: EventBus) -> void:
	eventBus = newEventBus


func startNewRun(startCountryId: String) -> void:
	currentRunState = NewRunFactory.createNewRun(StringName(startCountryId))
	selectedCountryId = StringName(startCountryId)
	_raiseEvent(EventType.RUN_STARTED, {
		"startCountryId": selectedCountryId,
	})


func submitCommand(commandName: StringName, payload: Dictionary = {}) -> void:
	match commandName:
		CommandType.SELECT_COUNTRY:
			_selectCountry(StringName(str(payload.get("countryId", ""))))
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
	_raiseEvent(EventType.RUN_RESET, {
		"startCountryId": nextStartCountryId,
	})


func getCurrentRunState() -> RunState:
	return currentRunState


func hasActiveRun() -> bool:
	return currentRunState != null and currentRunState.runStatus == RunState.RUN_STATUS_ACTIVE


func getSelectedCountryId() -> StringName:
	return selectedCountryId


func _selectCountry(countryId: StringName) -> void:
	if currentRunState == null or not currentRunState.countries.has(countryId):
		push_warning("Cannot select unknown country: %s" % countryId)
		return

	selectedCountryId = countryId
	_raiseEvent(EventType.COUNTRY_SELECTED, {
		"countryId": countryId,
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
