extends RefCounted
class_name MiniGoalSimulation


const THREAT_SIMULATION := preload("res://src/core/simulation/threat_simulation.gd")


static func initializeGoals(fixtures: Array[Dictionary]) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	for fixture in fixtures:
		var goal := fixture.duplicate(true)
		goal["progress"] = float(goal.get("progress", 0.0))
		goal["isCompleted"] = bool(goal.get("isCompleted", false))
		goal["isRewardClaimed"] = bool(goal.get("isRewardClaimed", false))
		goal["isFailed"] = bool(goal.get("isFailed", false))
		goals.append(goal)
	return goals


static func updateProgress(
	runState: RunState,
	eventType: StringName,
	payload: Dictionary,
	units: Array[UnitData]
) -> Dictionary:
	var result := {
		"changed": false,
		"completedGoalIds": [],
	}
	if runState == null:
		return result

	for index in range(runState.miniGoals.size()):
		var goal := runState.miniGoals[index]
		if bool(goal.get("isCompleted", false)) or bool(goal.get("isFailed", false)):
			continue

		var previousProgress := float(goal.get("progress", 0.0))
		_updateGoal(runState, goal, eventType, payload, units)
		var target := float(goal.get("target", 1.0))
		var nextProgress := float(goal.get("progress", 0.0))
		if nextProgress >= target:
			goal["progress"] = target
			goal["isCompleted"] = true
			var completedGoalIds: Array = result["completedGoalIds"]
			completedGoalIds.append(StringName(str(goal.get("id", ""))))
			result["completedGoalIds"] = completedGoalIds

		if not is_equal_approx(previousProgress, float(goal.get("progress", 0.0))) or bool(goal.get("isCompleted", false)):
			result["changed"] = true
			runState.miniGoals[index] = goal
	return result


static func claimReward(runState: RunState, goalId: StringName) -> Dictionary:
	var result := {
		"accepted": false,
		"goalId": goalId,
		"rewardType": "",
		"rewardValue": 0,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	for index in range(runState.miniGoals.size()):
		var goal := runState.miniGoals[index]
		if StringName(str(goal.get("id", ""))) != goalId:
			continue

		if not bool(goal.get("isCompleted", false)):
			result["reason"] = "goal_not_completed"
			return result

		if bool(goal.get("isRewardClaimed", false)):
			result["reason"] = "reward_already_claimed"
			return result

		var rewardType := str(goal.get("rewardType", ""))
		var rewardValue := int(goal.get("rewardValue", 0))
		_applyReward(runState, rewardType, rewardValue)
		goal["isRewardClaimed"] = true
		runState.miniGoals[index] = goal

		result["accepted"] = true
		result["rewardType"] = rewardType
		result["rewardValue"] = rewardValue
		result["resources"] = runState.resources.duplicate()
		result["miniGoalState"] = runState.miniGoalState.duplicate()
		return result

	result["reason"] = "unknown_goal"
	return result


static func _updateGoal(
	runState: RunState,
	goal: Dictionary,
	eventType: StringName,
	payload: Dictionary,
	units: Array[UnitData]
) -> void:
	match str(goal.get("goalType", "")):
		"conquerCountries":
			if eventType == EventType.COUNTRY_CONQUERED:
				_incrementProgress(goal, 1.0)
		"reachGold":
			goal["progress"] = maxf(float(goal.get("progress", 0.0)), float(runState.resources.get("gold", 0)))
		"reachArmyPower":
			goal["progress"] = maxf(float(goal.get("progress", 0.0)), _totalArmyPower(runState, units))
		"defeatStrongerCountry":
			if eventType == EventType.BATTLE_ENDED and bool(payload.get("attackerWon", false)) and float(payload.get("defenderPower", 0.0)) > float(payload.get("attackerPower", 0.0)):
				_incrementProgress(goal, 1.0)
		"holdThreatenedCountryMonths":
			if eventType == EventType.MONTH_TICK and _hasThreatenedOwnedCountry(runState):
				_incrementProgress(goal, 1.0)
		"conquerWithThreatBelow":
			if eventType == EventType.COUNTRY_CONQUERED and int(runState.resources.get("threat", 0)) < int(goal.get("limit", 999999)):
				_incrementProgress(goal, 1.0)


static func _applyReward(runState: RunState, rewardType: String, rewardValue: int) -> void:
	match rewardType:
		"gold":
			runState.resources["gold"] = int(runState.resources.get("gold", 0)) + rewardValue
		"food":
			runState.resources["food"] = int(runState.resources.get("food", 0)) + rewardValue
		"upgradeRarityBoost":
			runState.miniGoalState["upgradeRarityBoost"] = int(runState.miniGoalState.get("upgradeRarityBoost", 0)) + rewardValue


static func _incrementProgress(goal: Dictionary, amount: float) -> void:
	goal["progress"] = float(goal.get("progress", 0.0)) + amount


static func _totalArmyPower(runState: RunState, units: Array[UnitData]) -> float:
	var catalog := {}
	for unit in units:
		catalog[unit.id] = unit

	var total := 0.0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID:
			continue

		for unitId in army.units.keys():
			var unit := catalog.get(unitId, null) as UnitData
			if unit != null:
				total += float(int(army.units.get(unitId, 0)) * unit.combatPower)
	return total


static func _hasThreatenedOwnedCountry(runState: RunState) -> bool:
	if int(runState.resources.get("threat", 0)) < THREAT_SIMULATION.CAUTION_THRESHOLD:
		return false

	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country != null and country.ownerId == GameIds.PLAYER_OWNER_ID:
			return true
	return false
