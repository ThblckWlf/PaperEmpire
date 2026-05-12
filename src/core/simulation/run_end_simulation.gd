extends RefCounted
class_name RunEndSimulation


const RUN_STATS_SIMULATION := preload("res://src/core/simulation/run_stats_simulation.gd")

const REASON_NO_COUNTRIES_REMAINING: String = "noCountriesRemaining"


static func shouldLoseRun(runState: RunState) -> bool:
	return (
		runState != null
		and runState.runStatus == RunState.RUN_STATUS_ACTIVE
		and _hasPlayerRunStarted(runState)
		and RUN_STATS_SIMULATION.playerCountryCount(runState) <= 0
	)


static func markRunLostIfNeeded(runState: RunState, reason: String = REASON_NO_COUNTRIES_REMAINING) -> Dictionary:
	var result := {
		"triggered": false,
		"reason": reason,
		"runStatus": "",
		"playerCountryCount": 0,
		"runStats": {},
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	result["runStatus"] = str(runState.runStatus)
	result["playerCountryCount"] = RUN_STATS_SIMULATION.playerCountryCount(runState)
	result["runStats"] = RUN_STATS_SIMULATION.statsSnapshot(runState)
	if runState.runStatus == RunState.RUN_STATUS_LOST:
		result["reason"] = "already_lost"
		return result

	if not shouldLoseRun(runState):
		return result

	runState.runStatus = RunState.RUN_STATUS_LOST
	runState.speed = GameSpeed.Value.Paused
	runState.activeUpgradeChoice = {}
	result["triggered"] = true
	result["reason"] = reason
	result["runStatus"] = str(runState.runStatus)
	result["playerCountryCount"] = 0
	result["runStats"] = RUN_STATS_SIMULATION.statsSnapshot(runState)
	return result


static func _hasPlayerRunStarted(runState: RunState) -> bool:
	var stats := RUN_STATS_SIMULATION.ensureStats(runState)
	if int(stats.get("maxCountriesOwned", 0)) > 0:
		return true

	if RUN_STATS_SIMULATION.playerCountryCount(runState) > 0:
		return true

	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army != null and army.ownerId == GameIds.PLAYER_OWNER_ID:
			return true
	return false
