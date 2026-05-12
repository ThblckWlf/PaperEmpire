extends Node
class_name SimulationManager


signal gameSpeedChanged(speed: int)
signal monthTick(month: int, year: int, elapsedSeconds: float)

const DEFAULT_FIXED_STEP_SECONDS: float = 0.1
const ECONOMY_SIMULATION := preload("res://src/core/simulation/economy_simulation.gd")
const ARMY_MOVEMENT_SIMULATION := preload("res://src/core/simulation/army_movement_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const AI_RECRUITMENT_SIMULATION := preload("res://src/core/simulation/ai_recruitment_simulation.gd")
const AI_WAR_SIMULATION := preload("res://src/core/simulation/ai_war_simulation.gd")
const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const RUN_STATS_SIMULATION := preload("res://src/core/simulation/run_stats_simulation.gd")
const RUN_END_SIMULATION := preload("res://src/core/simulation/run_end_simulation.gd")

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

	if _updateRunLostIfNoCountries():
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
		if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
			return


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
	var units := PrototypeContentLoader.loadUnits()
	var completedMoves: Array[Dictionary] = ARMY_MOVEMENT_SIMULATION.advanceMovement(runState, deltaSeconds, units)
	for movePayload in completedMoves:
		_raiseEvent(EventType.ARMY_MOVED, movePayload)
		if bool(movePayload.get("isAttack", false)):
			_beginBattleForCompletedAttack(movePayload, units)

	var battleEvents: Array[Dictionary] = COMBAT_SIMULATION.advanceBattles(runState, deltaSeconds, units)
	for battleEvent in battleEvents:
		_handleBattleEvent(battleEvent)
		if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
			return

	var monthTickCount := GameTime.advance(runState.time, deltaSeconds)
	for _index in range(monthTickCount):
		_raiseMonthTick()
		if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
			return


func _raiseMonthTick() -> void:
	if _updateRunLostIfNoCountries():
		return

	var units := PrototypeContentLoader.loadUnits()
	var economyResult: Dictionary = ECONOMY_SIMULATION.applyMonthTick(runState, units)
	var aiRecruitmentEvents: Array[Dictionary] = AI_RECRUITMENT_SIMULATION.applyMonthTick(runState, units)
	var aiWarEvents: Array[Dictionary] = AI_WAR_SIMULATION.applyMonthTick(runState, units)
	var threatResult: Dictionary = THREAT_SIMULATION.applyMonthlyThreat(runState)
	var payload := {
		"week": int(runState.time.get("week", 1)),
		"month": int(runState.time.get("month", 1)),
		"year": int(runState.time.get("year", 1)),
		"elapsedSeconds": GameTime.getElapsedSeconds(runState.time),
		"economy": economyResult,
		"aiRecruitmentUpdatedArmyCount": aiRecruitmentEvents.size(),
		"aiWarStartedAttackCount": _countEvents(aiWarEvents, EventType.AI_ATTACK_STARTED),
		"threat": threatResult,
	}
	monthTick.emit(int(payload["month"]), int(payload["year"]), float(payload["elapsedSeconds"]))
	if int(threatResult.get("threatAdded", 0)) > 0:
		_raiseEvent(EventType.THREAT_CHANGED, threatResult)
		_raiseWorldReactionIfChanged(threatResult)
	for aiWarEvent in aiWarEvents:
		_raiseEvent(StringName(str(aiWarEvent.get("eventType", ""))), aiWarEvent.get("payload", {}) as Dictionary)
	_raiseEvent(EventType.MONTH_TICK, payload)
	_updateRunLostIfNoCountries()


func _beginBattleForCompletedAttack(movePayload: Dictionary, units: Array[UnitData]) -> void:
	var battleResult: Dictionary = COMBAT_SIMULATION.beginBattleAfterArrival(
		runState,
		StringName(str(movePayload.get("armyId", ""))),
		StringName(str(movePayload.get("fromCountryId", ""))),
		StringName(str(movePayload.get("toCountryId", ""))),
		units
	)
	if not bool(battleResult.get("accepted", false)):
		var targetCountry := runState.countries.get(StringName(str(movePayload.get("toCountryId", ""))), null) as CountryData
		if targetCountry != null:
			targetCountry.isUnderAttack = false
		_raiseEvent(EventType.INVALID_ATTACK, battleResult)
		return

	_raiseEvent(EventType.BATTLE_STARTED, battleResult)
	if StringName(str(battleResult.get("attackerOwnerId", GameIds.EMPTY_ID))) != GameIds.PLAYER_OWNER_ID:
		_raiseEvent(EventType.AI_BATTLE_STARTED, battleResult)


func _handleBattleEvent(battleEvent: Dictionary) -> void:
	var eventType := StringName(str(battleEvent.get("eventType", "")))
	var payload: Dictionary = battleEvent.get("payload", {})
	if eventType != EventType.COUNTRY_CONQUERED:
		_raiseEvent(eventType, payload)
		if eventType == EventType.BATTLE_ENDED and StringName(str(payload.get("attackerOwnerId", GameIds.EMPTY_ID))) != GameIds.PLAYER_OWNER_ID:
			_raiseEvent(EventType.AI_BATTLE_ENDED, payload)
		return

	if StringName(str(payload.get("newOwnerId", GameIds.EMPTY_ID))) != GameIds.PLAYER_OWNER_ID:
		_raiseEvent(EventType.COUNTRY_CONQUERED, payload)
		_raiseEvent(EventType.AI_COUNTRY_CONQUERED, payload)
		if _updateRunLostIfNoCountries():
			return
		if _updateRunWonIfComplete():
			return
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
		RUN_STATS_SIMULATION.updateForEvent(runState, eventType, payload)

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
	if runState.runStatus != RunState.RUN_STATUS_ACTIVE:
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


func _updateRunLostIfNoCountries() -> bool:
	var lossResult: Dictionary = RUN_END_SIMULATION.markRunLostIfNeeded(runState)
	if not bool(lossResult.get("triggered", false)):
		return false

	_raiseEvent(EventType.RUN_LOST, lossResult)
	return true


func _isValidGameSpeed(speed: int) -> bool:
	return [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	].has(speed)


func _countEvents(events: Array[Dictionary], eventType: StringName) -> int:
	var count := 0
	for event in events:
		if StringName(str(event.get("eventType", ""))) == eventType:
			count += 1
	return count
