extends RefCounted
class_name MiniGoalDataValidator


static func validate(miniGoals: Array[Dictionary]) -> ValidationResult:
	var result := ValidationResult.new()
	var knownIds: Dictionary = {}
	var allowedGoalTypes := {
		"conquerCountries": true,
		"reachGold": true,
		"reachArmyPower": true,
		"defeatStrongerCountry": true,
		"holdThreatenedCountryMonths": true,
		"conquerWithThreatBelow": true,
	}
	var allowedRewardTypes := {
		"gold": true,
		"food": true,
		"upgradeRarityBoost": true,
	}

	if miniGoals.size() < 5 or miniGoals.size() > 8:
		result.addError("MiniGoal fixture should contain 5-8 goals, found %d." % miniGoals.size())

	for miniGoal in miniGoals:
		var id := str(miniGoal.get("id", ""))
		if id.is_empty():
			result.addError("MiniGoal has empty id.")
		elif knownIds.has(id):
			result.addError("Duplicate MiniGoal id: %s." % id)
		else:
			knownIds[id] = true

		if str(miniGoal.get("name", "")).is_empty():
			result.addError("MiniGoal %s has empty name." % id)

		if str(miniGoal.get("description", "")).is_empty():
			result.addError("MiniGoal %s has empty description." % id)

		if not allowedGoalTypes.has(str(miniGoal.get("goalType", ""))):
			result.addError("MiniGoal %s has invalid goalType." % id)

		if not allowedRewardTypes.has(str(miniGoal.get("rewardType", ""))):
			result.addError("MiniGoal %s has invalid rewardType." % id)

		var target = miniGoal.get("target", null)
		if typeof(target) != TYPE_INT and typeof(target) != TYPE_FLOAT:
			result.addError("MiniGoal %s target is not numeric." % id)
		elif float(target) <= 0.0 or is_nan(float(target)):
			result.addError("MiniGoal %s target must be positive." % id)

		var rewardValue = miniGoal.get("rewardValue", null)
		if typeof(rewardValue) != TYPE_INT and typeof(rewardValue) != TYPE_FLOAT:
			result.addError("MiniGoal %s rewardValue is not numeric." % id)
		elif float(rewardValue) <= 0.0 or is_nan(float(rewardValue)):
			result.addError("MiniGoal %s rewardValue must be positive." % id)

		if miniGoal.has("chainId"):
			result.addError("MiniGoal %s defines chainId, which is not MVP content." % id)

	return result
