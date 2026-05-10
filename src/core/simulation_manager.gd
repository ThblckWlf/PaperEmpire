extends Node
class_name SimulationManager


signal gameSpeedChanged(speed: int)
signal monthTick(month: int, year: int, elapsedSeconds: float)

const DEFAULT_FIXED_STEP_SECONDS: float = 0.1
const ECONOMY_SIMULATION := preload("res://src/core/simulation/economy_simulation.gd")
const ARMY_MOVEMENT_SIMULATION := preload("res://src/core/simulation/army_movement_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const MINI_GOAL_SIMULATION := preload("res://src/core/simulation/mini_goal_simulation.gd")

var fixedStepSeconds: float = DEFAULT_FIXED_STEP_SECONDS
var accumulatedSeconds: float = 0.0
var runState: RunState
var eventBus: EventBus
var pendingEvents: Array[GameEvent] = []
var processTicks: bool = true


func _process(delta: float) -> void:
	if processTicks:
		stepSimulation(delta)


func configure(newRunState: RunState, newEventBus: EventBus = null) -> void:
	runState = newRunState
	eventBus = newEventBus
	accumulatedSeconds = 0.0
	if runState != null:
		GameTime.applyElapsedSeconds(runState.time, GameTime.getElapsedSeconds(runState.time))


func setRunState(newRunState: RunState) -> void:
	configure(newRunState, eventBus)


func setEventBus(newEventBus: EventBus) -> void:
	eventBus = newEventBus


func resetSimulation() -> void:
	accumulatedSeconds = 0.0
	pendingEvents.clear()
	if runState != null:
		runState.time = GameTime.createInitialState()


func stepSimulation(deltaSeconds: float) -> void:
	if runState == null or runState.runStatus != RunState.RUN_STATUS_ACTIVE:
		return

	if fixedStepSeconds <= 0.0:
		push_warning("Simulation fixedStepSeconds must be greater than zero.")
		return

	var speed := int(runState.speed)
	if speed <= GameSpeed.Value.Paused or deltaSeconds <= 0.0:
		return

	accumulatedSeconds += deltaSeconds * float(speed)
	while accumulatedSeconds + GameTime.FLOAT_EPSILON >= fixedStepSeconds:
		_advanceFixedStep(fixedStepSeconds)
		accumulatedSeconds -= fixedStepSeconds


func setGameSpeed(speed: int) -> bool:
	if not _isValidGameSpeed(speed):
		push_warning("Cannot set invalid simulation speed: %s" % speed)
		return false

	if runState != null:
		runState.speed = speed

	gameSpeedChanged.emit(speed)
	return true


func getGameSpeed() -> int:
	if runState == null:
		return GameSpeed.Value.Paused
	return int(runState.speed)


func getRunState() -> RunState:
	return runState


func collectPendingEvents() -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	for event in pendingEvents:
		events.append(event)

	pendingEvents.clear()
	return events


func _advanceFixedStep(deltaSeconds: float) -> void:
	var completedMoves: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, deltaSeconds)
	for movePayload in completedMoves:
		_raiseEvent(EventType.ARMY_MOVED, movePayload)

	var battleEvents: Array[Dictionary] = COMBAT_SIMULATION.advanceBattles(runState, deltaSeconds, PrototypeContentLoader.loadUnits())
	for battleEvent in battleEvents:
		_handleBattleEvent(battleEvent)

	var monthTickCount := GameTime.advance(runState.time, deltaSeconds)
	for _index in range(monthTickCount):
		_raiseMonthTick()


func _raiseMonthTick() -> void:
	var economyResult: Dictionary = ECONOMY_SIMULATION.applyMonthTick(runState, PrototypeContentLoader.loadUnits())
	var threatResult: Dictionary = THREAT_SIMULATION.applyMonthlyThreat(runState)
	var payload := {
		"week": int(runState.time.get("week", 1)),
		"month": int(runState.time.get("month", 1)),
		"year": int(runState.time.get("year", 1)),
		"elapsedSeconds": GameTime.getElapsedSeconds(runState.time),
		"economy": economyResult,
		"threat": threatResult,
	}
	monthTick.emit(int(payload["month"]), int(payload["year"]), float(payload["elapsedSeconds"]))
	if int(threatResult.get("threatAdded", 0)) > 0:
		_raiseEvent(EventType.THREAT_CHANGED, threatResult)
		_raiseWorldReactionIfChanged(threatResult)
	_raiseEvent(EventType.MONTH_TICK, payload)


func _handleBattleEvent(battleEvent: Dictionary) -> void:
	var eventType := StringName(str(battleEvent.get("eventType", "")))
	var payload: Dictionary = battleEvent.get("payload", {})
	if eventType != EventType.COUNTRY_CONQUERED:
		_raiseEvent(eventType, payload)
		return

	var reward: Dictionary = UPGRADE_SIMULATION.applyConquestReward(runState, StringName(str(payload.get("countryId", ""))))
	var threatResult: Dictionary = THREAT_SIMULATION.applyActionThreat(runState, THREAT_SIMULATION.ACTION_COUNTRY_CONQUERED)
	payload["goldReward"] = int(reward.get("goldReward", 0))
	payload["gold"] = int(reward.get("gold", 0))
	payload["threatAdded"] = int(threatResult.get("threatAdded", 0))
	payload["threat"] = int(threatResult.get("threat", 0))
	_raiseEvent(EventType.THREAT_CHANGED, threatResult)
	_raiseWorldReactionIfChanged(threatResult)
	_raiseEvent(eventType, payload)

	if _updateRunWonIfComplete():
		return

	var choice: Dictionary = UPGRADE_SIMULATION.rollUpgradeChoices(runState, PrototypeContentLoader.loadUpgrades())
	if bool(choice.get("opened", false)):
		runState.speed = GameSpeed.Value.Paused
		_raiseEvent(EventType.UPGRADE_CHOICE_OPENED, choice)


func _raiseEvent(eventType: StringName, payload: Dictionary = {}) -> void:
	if runState != null:
		MINI_GOAL_SIMULATION.updateProgress(runState, eventType, payload, PrototypeContentLoader.loadUnits())

	var gameEvent := GameEvent.new()
	gameEvent.type = eventType
	gameEvent.payload = payload
	gameEvent.occurredAtSeconds = GameTime.getElapsedSeconds(runState.time)
	pendingEvents.append(gameEvent)

	if eventBus != null:
		eventBus.raiseEvent(gameEvent)


func _raiseWorldReactionIfChanged(threatResult: Dictionary) -> void:
	var worldReaction: Dictionary = threatResult.get("worldReaction", {})
	if bool(worldReaction.get("changed", false)):
		_raiseEvent(EventType.WORLD_REACTION_UPDATED, worldReaction)


func _updateRunWonIfComplete() -> bool:
	if runState == null:
		return false

	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId != GameIds.PLAYER_OWNER_ID:
			return false

	runState.runStatus = RunState.RUN_STATUS_WON
	runState.speed = GameSpeed.Value.Paused
	runState.activeUpgradeChoice = {}
	_raiseEvent(EventType.RUN_WON, {
		"runStatus": RunState.RUN_STATUS_WON,
		"ownedCountryCount": runState.countries.size(),
	})
	return true


func _isValidGameSpeed(speed: int) -> bool:
	return [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	].has(speed)
