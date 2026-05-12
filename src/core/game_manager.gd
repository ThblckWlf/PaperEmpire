extends Node
class_name GameManager


const ARMY_MOVEMENT_SIMULATION := preload("res://src/core/simulation/army_movement_simulation.gd")
const RECRUITMENT_SIMULATION := preload("res://src/core/simulation/recruitment_simulation.gd")
const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")
const UPGRADE_SIMULATION := preload("res://src/core/simulation/upgrade_simulation.gd")
const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")
const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")
const RUN_STATS_SIMULATION := preload("res://src/core/simulation/run_stats_simulation.gd")
const RUN_END_SIMULATION := preload("res://src/core/simulation/run_end_simulation.gd")
const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const RUN_STATE_SERIALIZER := preload("res://src/save/run_state_serializer.gd")
const META_PROGRESS := preload("res://src/save/meta_progress.gd")
const SHOP_STATE_VIEW := preload("res://src/core/view/shop_state_view.gd")

var currentRunState: RunState
var metaProgressData: Dictionary = {}
var eventBus: EventBus
var simulationManager: SimulationManager
var saveManager: SaveManager
var selectedCountryId: StringName = GameIds.EMPTY_ID
var selectedArmyId: StringName = GameIds.EMPTY_ID
var gameOverTriggeredForRun: bool = false


func setEventBus(newEventBus: EventBus) -> void:
	_disconnectEventBusCommands()
	eventBus = newEventBus
	_connectEventBusCommands()
	if simulationManager != null:
		simulationManager.setEventBus(eventBus)


func setSimulationManager(newSimulationManager: SimulationManager) -> void:
	simulationManager = newSimulationManager
	_configureSimulationManager()


func setSaveManager(newSaveManager: SaveManager) -> void:
	saveManager = newSaveManager
	_loadMetaProgress()


func startNewRun(startCountryId: String) -> void:
	currentRunState = NewRunFactory.createNewRun(StringName(startCountryId), metaProgressData, PrototypeContentLoader.loadMetaUpgrades())
	gameOverTriggeredForRun = false
	selectedCountryId = StringName(startCountryId)
	selectedArmyId = _firstArmyId()
	_configureSimulationManager()
	_raiseEvent(EventType.RUN_STARTED, {
		"startCountryId": selectedCountryId,
		"selectedArmyId": selectedArmyId,
	})


func submitCommand(commandName: StringName, payload: Dictionary = {}) -> void:
	if _isCommandBlockedAfterGameOver(commandName, payload):
		return

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
				int(payload.get("amount", 0)),
				StringName(str(payload.get("armyId", selectedArmyId)))
			)
		CommandType.CREATE_ARMY:
			_createArmy(StringName(str(payload.get("countryId", selectedCountryId))))
		CommandType.UPDATE_ARMY_COMPOSITION:
			_updateArmyComposition(
				StringName(str(payload.get("armyId", selectedArmyId))),
				payload.get("targetUnits", {}) as Dictionary
			)
		CommandType.CHOOSE_UPGRADE:
			_chooseUpgrade(StringName(str(payload.get("upgradeId", ""))))
		CommandType.SAVE_GAME:
			_saveGame(str(payload.get("slotId", "manual_1")))
		CommandType.LOAD_GAME:
			_loadGame(str(payload.get("slotId", "manual_1")))
		CommandType.PURCHASE_META_UPGRADE:
			_purchaseMetaUpgrade(StringName(str(payload.get("upgradeId", ""))))
		CommandType.AWARD_RUN_END_CROWNS:
			_awardRunEndCrowns()
		CommandType.SET_GAME_SPEED:
			_setGameSpeed(int(payload.get("speed", GameSpeed.Value.Normal)))
		CommandType.PAUSE_GAME:
			_setGameSpeed(GameSpeed.Value.Paused)
		CommandType.RESUME_GAME:
			_setGameSpeed(GameSpeed.Value.Normal)
		CommandType.RESET_RUN:
			resetRun(StringName(str(payload.get("startCountryId", selectedCountryId))))
		_:
			_reportWarning("Unknown command: %s" % commandName)


func resetRun(startCountryId: StringName = GameIds.EMPTY_ID) -> void:
	var nextStartCountryId := startCountryId
	if nextStartCountryId == GameIds.EMPTY_ID:
		nextStartCountryId = selectedCountryId

	if nextStartCountryId == GameIds.EMPTY_ID:
		nextStartCountryId = NewRunFactory.DEFAULT_START_COUNTRY_ID

	currentRunState = NewRunFactory.createNewRun(nextStartCountryId, metaProgressData, PrototypeContentLoader.loadMetaUpgrades())
	gameOverTriggeredForRun = false
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


func getMetaProgressData() -> Dictionary:
	return metaProgressData.duplicate(true)


func getShopPanelData() -> Dictionary:
	return SHOP_STATE_VIEW.createShopPanelData(metaProgressData, PrototypeContentLoader.loadMetaUpgrades())


func _selectCountry(countryId: StringName) -> void:
	if currentRunState == null or not currentRunState.countries.has(countryId):
		_reportWarning("Cannot select unknown country: %s" % countryId)
		return

	selectedCountryId = countryId
	_raiseEvent(EventType.COUNTRY_SELECTED, {
		"countryId": countryId,
	})


func _selectArmy(armyId: StringName) -> void:
	if currentRunState == null or not currentRunState.armies.has(armyId):
		_reportWarning("Cannot select unknown army: %s" % armyId)
		return

	selectedArmyId = armyId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": armyId,
	})


func _moveArmy(armyId: StringName, targetCountryId: StringName) -> void:
	var moveResult: Dictionary = ARMY_MOVEMENT_SIMULATION.requestMove(currentRunState, armyId, targetCountryId)
	if not bool(moveResult.get("accepted", false)):
		_reportWarning("Cannot move army: %s" % str(moveResult.get("reason", "unknown_reason")))
		return

	selectedArmyId = armyId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": armyId,
	})
	_raiseEvent(EventType.ARMY_MOVE_STARTED, moveResult)


func _startAttack(armyId: StringName, targetCountryId: StringName) -> void:
	if currentRunState == null:
		_reportWarning("Cannot start attack without an active run.")
		return

	var army := currentRunState.armies.get(armyId, null) as ArmyData
	if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID:
		var invalidResult := {
			"accepted": false,
			"armyId": armyId,
			"targetCountryId": targetCountryId,
			"reason": "army_not_owned",
		}
		_raiseEvent(EventType.INVALID_ATTACK, invalidResult)
		_reportWarning("Cannot start attack: army_not_owned")
		return

	var attackResult: Dictionary = COMBAT_SIMULATION.startAttack(
		currentRunState,
		armyId,
		targetCountryId,
		PrototypeContentLoader.loadUnits()
	)
	if not bool(attackResult.get("accepted", false)):
		_raiseEvent(EventType.INVALID_ATTACK, attackResult)
		_reportWarning("Cannot start attack: %s" % str(attackResult.get("reason", "unknown_reason")))
		return

	selectedArmyId = StringName(str(attackResult.get("armyId", armyId)))
	selectedCountryId = targetCountryId
	var threatResult: Dictionary = THREAT_SIMULATION.applyActionThreat(currentRunState, THREAT_SIMULATION.ACTION_WAR_STARTED)
	attackResult["threatAdded"] = int(threatResult.get("threatAdded", 0))
	attackResult["threat"] = int(threatResult.get("threat", 0))
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})
	_raiseEvent(EventType.COUNTRY_SELECTED, {
		"countryId": selectedCountryId,
	})
	_raiseEvent(EventType.THREAT_CHANGED, threatResult)
	_raiseWorldReactionIfChanged(threatResult)
	_raiseEvent(EventType.ARMY_MOVE_STARTED, attackResult)


func _chooseUpgrade(upgradeId: StringName) -> void:
	var chooseResult: Dictionary = UPGRADE_SIMULATION.applyUpgradeChoice(currentRunState, upgradeId)
	if not bool(chooseResult.get("accepted", false)):
		_reportWarning("Cannot choose upgrade: %s" % str(chooseResult.get("reason", "unknown_reason")))
		return

	_raiseEvent(EventType.UPGRADE_CHOSEN, chooseResult)
	_setGameSpeed(GameSpeed.Value.Normal)


func _saveGame(slotId: String) -> void:
	if saveManager == null or currentRunState == null:
		_reportWarning("Cannot save without SaveManager and active run.")
		return

	var runData: Dictionary = RUN_STATE_SERIALIZER.serializeRunState(currentRunState)
	var root: Dictionary = SAVE_FORMAT.createRunSaveRoot(runData, metaProgressData)
	if not saveManager.saveGame(slotId, root):
		_reportWarning("Save command failed for slot: %s" % slotId)


func _loadGame(slotId: String) -> void:
	if saveManager == null:
		_reportWarning("Cannot load without SaveManager.")
		return

	var root: Dictionary = saveManager.loadGame(slotId)
	if root.is_empty():
		_reportWarning("Load command found no valid save for slot: %s" % slotId)
		return

	var runData: Dictionary = root.get(SAVE_FORMAT.RUN_STATE_KEY, {})
	var loadedMetaData: Dictionary = root.get(SAVE_FORMAT.META_PROGRESS_KEY, {})
	if META_PROGRESS.isValidDictionary(loadedMetaData, PrototypeContentLoader.loadMetaUpgrades()):
		metaProgressData = loadedMetaData.duplicate(true)
	var loadedRunState: RunState = RUN_STATE_SERIALIZER.deserializeRunState(runData)
	var validation := RunStateValidator.validate(loadedRunState)
	if not validation.isValid():
		for error in validation.errors:
			_reportWarning("Loaded save is invalid: %s" % error)
		return

	currentRunState = loadedRunState
	RUN_STATS_SIMULATION.ensureStats(currentRunState)
	gameOverTriggeredForRun = bool(currentRunState.runStats.get("crownsAwarded", false)) and currentRunState.runStatus == RunState.RUN_STATUS_LOST
	selectedCountryId = _firstPlayerCountryId()
	selectedArmyId = _firstArmyId()
	_configureSimulationManager()
	_raiseEvent(EventType.RUN_RESET, {
		"startCountryId": selectedCountryId,
		"selectedArmyId": selectedArmyId,
		"source": "load",
	})
	_triggerGameOverIfNoCountries(RUN_END_SIMULATION.REASON_NO_COUNTRIES_REMAINING)


func _purchaseMetaUpgrade(upgradeId: StringName) -> void:
	var purchaseResult: Dictionary = META_PROGRESS_SIMULATION.purchaseUpgrade(
		metaProgressData,
		upgradeId,
		PrototypeContentLoader.loadMetaUpgrades()
	)
	if not bool(purchaseResult.get("accepted", false)):
		_reportWarning("Cannot purchase meta upgrade: %s" % str(purchaseResult.get("reason", "unknown_reason")))
		return

	metaProgressData = (purchaseResult.get("metaProgress", {}) as Dictionary).duplicate(true)
	_saveMetaProgress()
	_raiseEvent(EventType.META_UPGRADE_PURCHASED, purchaseResult)
	_raiseEvent(EventType.META_PROGRESS_CHANGED, {
		"metaProgress": metaProgressData,
	})


func _awardRunEndCrowns() -> void:
	_awardRunEndCrownsForCurrentRun(true)


func _awardRunEndCrownsForCurrentRun(reportWarnings: bool) -> Dictionary:
	var rewardResult: Dictionary = META_PROGRESS_SIMULATION.awardRunEndCrowns(
		metaProgressData,
		currentRunState,
		PrototypeContentLoader.loadMetaUpgrades()
	)
	if not bool(rewardResult.get("accepted", false)):
		if reportWarnings and str(rewardResult.get("reason", "")) != "crowns_already_awarded":
			_reportWarning("Cannot award crowns: %s" % str(rewardResult.get("reason", "unknown_reason")))
		return rewardResult

	metaProgressData = (rewardResult.get("metaProgress", {}) as Dictionary).duplicate(true)
	_saveMetaProgress()
	_raiseEvent(EventType.CROWNS_AWARDED, rewardResult)
	_raiseEvent(EventType.CROWNS_REWARDED, rewardResult)
	_raiseEvent(EventType.META_PROGRESS_CHANGED, {
		"metaProgress": metaProgressData,
	})
	return rewardResult


func _recruitUnits(
	countryId: StringName,
	unitId: StringName,
	amount: int,
	armyId: StringName = GameIds.EMPTY_ID
) -> void:
	var recruitResult: Dictionary = RECRUITMENT_SIMULATION.applyRecruitment(
		currentRunState,
		countryId,
		unitId,
		amount,
		PrototypeContentLoader.loadUnits(),
		armyId
	)
	if not bool(recruitResult.get("accepted", false)):
		if str(recruitResult.get("reason", "")) == "country_under_attack":
			_reportWarning("Nicht möglich: Land wird angegriffen.")
			return
		if str(recruitResult.get("reason", "")) == "not_enough_gold":
			_raiseEvent(EventType.NOT_ENOUGH_GOLD, recruitResult)
		_reportWarning("Cannot recruit units: %s" % str(recruitResult.get("reason", "unknown_reason")))
		return

	selectedCountryId = countryId
	selectedArmyId = StringName(str(recruitResult.get("armyId", selectedArmyId)))
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})
	_raiseEvent(EventType.UNITS_RECRUITED, recruitResult)
	_raiseEvent(EventType.ARMY_UPDATED, recruitResult)


func _updateArmyComposition(armyId: StringName, targetUnits: Dictionary) -> void:
	var updateResult: Dictionary = RECRUITMENT_SIMULATION.updateArmyComposition(
		currentRunState,
		armyId,
		targetUnits,
		PrototypeContentLoader.loadUnits()
	)
	if not bool(updateResult.get("accepted", false)):
		if str(updateResult.get("reason", "")) == "country_under_attack":
			_reportWarning("Nicht möglich: Land wird angegriffen.")
			return
		if str(updateResult.get("reason", "")) == "not_enough_gold":
			_raiseEvent(EventType.NOT_ENOUGH_GOLD, updateResult)
		_reportWarning("Cannot update army: %s" % str(updateResult.get("reason", "unknown_reason")))
		return

	selectedArmyId = armyId
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})
	_raiseEvent(EventType.ARMY_UPDATED, updateResult)


func _createArmy(countryId: StringName) -> void:
	var createResult: Dictionary = RECRUITMENT_SIMULATION.createArmy(currentRunState, countryId)
	if not bool(createResult.get("accepted", false)):
		if str(createResult.get("reason", "")) == "country_under_attack":
			_reportWarning("Nicht möglich: Land wird angegriffen.")
			return
		_reportWarning("Cannot create army: %s" % str(createResult.get("reason", "unknown_reason")))
		return

	selectedCountryId = countryId
	selectedArmyId = StringName(str(createResult.get("armyId", GameIds.EMPTY_ID)))
	_raiseEvent(EventType.ARMY_CREATED, createResult)
	_raiseEvent(EventType.ARMY_SELECTED, {
		"armyId": selectedArmyId,
	})


func _setGameSpeed(speed: int) -> void:
	if currentRunState == null:
		_reportWarning("Cannot set speed without an active run.")
		return
	if currentRunState.runStatus == RunState.RUN_STATUS_LOST and speed != GameSpeed.Value.Paused:
		_reportWarning("Cannot resume a lost run.")
		return

	var validSpeeds := [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	]
	if not validSpeeds.has(speed):
		_reportWarning("Cannot set invalid game speed: %s" % speed)
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
		if currentRunState != null:
			RUN_STATS_SIMULATION.updateForEvent(currentRunState, eventType, payload)
		return

	if currentRunState != null:
		RUN_STATS_SIMULATION.updateForEvent(currentRunState, eventType, payload)

	var gameEvent := GameEvent.new()
	gameEvent.type = eventType
	gameEvent.payload = payload
	if currentRunState != null:
		gameEvent.occurredAtSeconds = float(currentRunState.time.get("elapsedSeconds", 0.0))

	eventBus.raiseEvent(gameEvent)


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.RUN_LOST:
			_handleRunLost(payload)
		EventType.COUNTRY_CONQUERED, EventType.MONTH_TICK:
			_triggerGameOverIfNoCountries(RUN_END_SIMULATION.REASON_NO_COUNTRIES_REMAINING)


func _handleRunLost(payload: Dictionary) -> void:
	var reason := str(payload.get("reason", RUN_END_SIMULATION.REASON_NO_COUNTRIES_REMAINING))
	_triggerGameOver(reason, payload)


func _triggerGameOverIfNoCountries(reason: String) -> void:
	var lossResult: Dictionary = RUN_END_SIMULATION.markRunLostIfNeeded(currentRunState, reason)
	if bool(lossResult.get("triggered", false)):
		_raiseEvent(EventType.RUN_LOST, lossResult)
		_triggerGameOver(reason, lossResult)


func _triggerGameOver(reason: String, lossPayload: Dictionary = {}) -> void:
	if currentRunState == null or gameOverTriggeredForRun:
		return
	if currentRunState.runStatus == RunState.RUN_STATUS_WON:
		return
	if currentRunState.runStatus != RunState.RUN_STATUS_LOST:
		var lossResult: Dictionary = RUN_END_SIMULATION.markRunLostIfNeeded(currentRunState, reason)
		if not bool(lossResult.get("triggered", false)):
			return
		lossPayload = lossResult

	gameOverTriggeredForRun = true
	currentRunState.speed = GameSpeed.Value.Paused
	currentRunState.activeUpgradeChoice = {}
	var rewardResult := _awardRunEndCrownsForCurrentRun(false)
	var crownsEarned := int(rewardResult.get("crowns", 0)) if bool(rewardResult.get("accepted", false)) else 0
	var gameOverPayload := {
		"reason": reason,
		"crownsEarned": crownsEarned,
		"playerCountryCount": RUN_STATS_SIMULATION.playerCountryCount(currentRunState),
		"runStats": RUN_STATS_SIMULATION.statsSnapshot(currentRunState),
		"loss": lossPayload.duplicate(true),
	}
	_raiseEvent(EventType.GAME_OVER_TRIGGERED, gameOverPayload)


func _isCommandBlockedAfterGameOver(commandName: StringName, payload: Dictionary) -> bool:
	if currentRunState == null or currentRunState.runStatus != RunState.RUN_STATUS_LOST:
		return false

	if commandName == CommandType.SET_GAME_SPEED:
		var requestedSpeed := int(payload.get("speed", GameSpeed.Value.Paused))
		if requestedSpeed == GameSpeed.Value.Paused:
			return false
		_reportWarning("Cannot resume a lost run.")
		return true

	if commandName == CommandType.PAUSE_GAME:
		return false

	if [
		CommandType.MOVE_ARMY,
		CommandType.START_ATTACK,
		CommandType.RECRUIT_UNITS,
		CommandType.CREATE_ARMY,
		CommandType.UPDATE_ARMY_COMPOSITION,
		CommandType.CHOOSE_UPGRADE,
		CommandType.RESUME_GAME,
	].has(commandName):
		_reportWarning("Cannot use gameplay command after game over: %s" % str(commandName))
		return true

	return false


func _reportWarning(message: String) -> void:
	push_warning(message)
	if eventBus != null:
		eventBus.reportDebugError(message)


func _raiseWorldReactionIfChanged(threatResult: Dictionary) -> void:
	var worldReaction: Dictionary = threatResult.get("worldReaction", {})
	if bool(worldReaction.get("changed", false)):
		_raiseEvent(EventType.WORLD_REACTION_UPDATED, worldReaction)


func _configureSimulationManager() -> void:
	if simulationManager != null:
		simulationManager.configure(currentRunState, eventBus)


func _loadMetaProgress() -> void:
	var metaUpgradeRows := PrototypeContentLoader.loadMetaUpgrades()
	if saveManager == null:
		metaProgressData = META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)
		return

	var loadedMeta := saveManager.loadMetaProgress()
	if META_PROGRESS.isValidDictionary(loadedMeta, metaUpgradeRows):
		metaProgressData = loadedMeta.duplicate(true)
	else:
		metaProgressData = META_PROGRESS.createDefaultDataForUpgrades(metaUpgradeRows)


func _saveMetaProgress() -> void:
	if saveManager == null:
		return

	if not saveManager.saveMetaProgress(metaProgressData):
		_reportWarning("Meta progress save failed.")


func _firstArmyId() -> StringName:
	if currentRunState == null or currentRunState.armies.is_empty():
		return GameIds.EMPTY_ID

	var armyIds := currentRunState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := currentRunState.armies[armyId] as ArmyData
		if army != null and army.ownerId == GameIds.PLAYER_OWNER_ID:
			return StringName(str(armyId))
	return StringName(str(armyIds[0]))


func _firstPlayerCountryId() -> StringName:
	if currentRunState == null:
		return GameIds.EMPTY_ID

	var countryIds := currentRunState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := currentRunState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			return country.id
	return GameIds.EMPTY_ID


func _connectEventBusCommands() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "submitCommand")
	if not eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.connect(commandCallable)

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)


func _disconnectEventBusCommands() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "submitCommand")
	if eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.disconnect(commandCallable)

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)
