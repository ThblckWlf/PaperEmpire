extends RefCounted
class_name RunStatsSimulation


static func defaultStats() -> Dictionary:
	return {
		"countriesConquered": 0,
		"maxCountriesOwned": 0,
		"monthsSurvived": 0,
		"battlesWon": 0,
		"battlesLost": 0,
		"highestThreatReached": 0.0,
		"crownsAwarded": false,
	}


static func ensureStats(runState: RunState) -> Dictionary:
	if runState == null:
		return defaultStats()

	var stats := defaultStats()
	for key in stats.keys():
		if runState.runStats.has(key):
			stats[key] = runState.runStats[key]
	runState.runStats = stats
	return runState.runStats


static func initializeForRun(runState: RunState) -> void:
	if runState == null:
		return

	runState.runStats = defaultStats()
	_updateMaxCountriesOwned(runState)
	_updateHighestThreatReached(runState)


static func updateForEvent(
	runState: RunState,
	eventType: StringName,
	payload: Dictionary = {}
) -> void:
	if runState == null:
		return

	var stats := ensureStats(runState)
	match eventType:
		EventType.COUNTRY_CONQUERED:
			if _isPlayerConquest(payload):
				stats["countriesConquered"] = int(stats.get("countriesConquered", 0)) + 1
		EventType.MONTH_TICK:
			stats["monthsSurvived"] = int(stats.get("monthsSurvived", 0)) + 1
		EventType.BATTLE_ENDED:
			_updateBattleStats(stats, payload)

	_updateMaxCountriesOwned(runState)
	_updateHighestThreatReached(runState)


static func statsSnapshot(runState: RunState) -> Dictionary:
	if runState == null:
		return defaultStats()
	return ensureStats(runState).duplicate(true)


static func playerCountryCount(runState: RunState) -> int:
	if runState == null:
		return 0

	var count := 0
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			count += 1
	return count


static func _updateMaxCountriesOwned(runState: RunState) -> void:
	var stats := ensureStats(runState)
	stats["maxCountriesOwned"] = maxi(
		int(stats.get("maxCountriesOwned", 0)),
		playerCountryCount(runState)
	)


static func _updateHighestThreatReached(runState: RunState) -> void:
	var stats := ensureStats(runState)
	stats["highestThreatReached"] = maxf(
		float(stats.get("highestThreatReached", 0.0)),
		float(runState.resources.get("threat", 0.0))
	)


static func _updateBattleStats(stats: Dictionary, payload: Dictionary) -> void:
	var attackerOwnerId := StringName(str(payload.get("attackerOwnerId", GameIds.EMPTY_ID)))
	var defenderOwnerId := StringName(str(payload.get("defenderOwnerId", GameIds.EMPTY_ID)))
	var winnerOwnerId := StringName(str(payload.get("winnerOwnerId", GameIds.EMPTY_ID)))
	var playerInvolved := attackerOwnerId == GameIds.PLAYER_OWNER_ID or defenderOwnerId == GameIds.PLAYER_OWNER_ID
	if not playerInvolved:
		return

	if winnerOwnerId == GameIds.PLAYER_OWNER_ID:
		stats["battlesWon"] = int(stats.get("battlesWon", 0)) + 1
	else:
		stats["battlesLost"] = int(stats.get("battlesLost", 0)) + 1


static func _isPlayerConquest(payload: Dictionary) -> bool:
	return StringName(str(payload.get("newOwnerId", GameIds.EMPTY_ID))) == GameIds.PLAYER_OWNER_ID
