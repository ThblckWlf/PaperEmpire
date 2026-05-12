extends RefCounted
class_name ThreatSimulation


const ACTION_WAR_STARTED: StringName = &"war_started"
const ACTION_COUNTRY_CONQUERED: StringName = &"country_conquered"

const PASSIVE_THREAT_PER_MONTH: int = 1
const WAR_STARTED_THREAT: int = 4
const COUNTRY_CONQUERED_THREAT: int = 2
const LARGE_ARMY_THRESHOLD: int = 25
const LARGE_ARMY_STEP_UNITS: int = 10

const MAX_THREAT: int = 100
const CAUTION_THRESHOLD: int = 25
const HIGH_THRESHOLD: int = 50
const CRITICAL_THRESHOLD: int = 75
const COALITION_THRESHOLD: int = 100


static func applyMonthlyThreat(runState: RunState) -> Dictionary:
	var largeArmyThreat := calculateLargeArmyThreat(runState)
	var threatAdded := PASSIVE_THREAT_PER_MONTH + largeArmyThreat
	var result := _applyThreat(runState, threatAdded)
	result["passiveThreat"] = PASSIVE_THREAT_PER_MONTH
	result["largeArmyThreat"] = largeArmyThreat
	result["source"] = "month"
	return result


static func applyActionThreat(runState: RunState, actionType: StringName) -> Dictionary:
	var baseThreat := 0
	match actionType:
		ACTION_WAR_STARTED:
			baseThreat = WAR_STARTED_THREAT
		ACTION_COUNTRY_CONQUERED:
			baseThreat = COUNTRY_CONQUERED_THREAT
		_:
			baseThreat = 0

	var multiplier := float(runState.upgradeEffects.get("warThreatMultiplier", 1.0)) if runState != null else 1.0
	var threatAdded := maxi(0, int(round(float(baseThreat) * multiplier)))
	var result := _applyThreat(runState, threatAdded)
	result["source"] = str(actionType)
	return result


static func calculateLargeArmyThreat(runState: RunState) -> int:
	if runState == null:
		return 0

	var unitCount := 0
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.ownerId != GameIds.PLAYER_OWNER_ID:
			continue

		for unitId in army.units.keys():
			unitCount += int(army.units.get(unitId, 0))

	if unitCount <= LARGE_ARMY_THRESHOLD:
		return 0

	return int(ceil(float(unitCount - LARGE_ARMY_THRESHOLD) / float(LARGE_ARMY_STEP_UNITS)))


static func threatState(threat: int) -> String:
	if threat >= COALITION_THRESHOLD:
		return "coalition"
	if threat >= CRITICAL_THRESHOLD:
		return "critical"
	if threat >= HIGH_THRESHOLD:
		return "high"
	if threat >= CAUTION_THRESHOLD:
		return "caution"
	return "low"


static func updateWorldReaction(runState: RunState) -> Dictionary:
	var result := {
		"changed": false,
		"level": "calm",
		"enemyStrengthMultiplier": 1.0,
		"counterAttackPrepared": false,
		"lastThreat": 0,
	}
	if runState == null:
		return result

	var threat := int(runState.resources.get("threat", 0))
	var nextReaction := _reactionForThreat(threat)
	var previousReaction := runState.worldReaction.duplicate()
	nextReaction["lastThreat"] = threat
	runState.worldReaction = nextReaction
	result = nextReaction.duplicate()
	result["changed"] = not _reactionsEqual(previousReaction, nextReaction)
	return result


static func _applyThreat(runState: RunState, threatAdded: int) -> Dictionary:
	var result := {
		"threatAdded": 0,
		"threat": 0,
		"threatState": "low",
		"worldReaction": {},
	}
	if runState == null:
		return result

	var previousThreat := int(runState.resources.get("threat", 0))
	var nextThreat := clampi(previousThreat + threatAdded, 0, MAX_THREAT)
	runState.resources["threat"] = nextThreat
	var appliedThreat := nextThreat - previousThreat
	var reaction := updateWorldReaction(runState)
	result["threatAdded"] = appliedThreat
	result["threat"] = nextThreat
	result["threatState"] = threatState(nextThreat)
	result["worldReaction"] = reaction
	return result


static func _reactionForThreat(threat: int) -> Dictionary:
	if threat >= COALITION_THRESHOLD:
		return {
			"level": "coalition",
			"enemyStrengthMultiplier": 1.35,
			"counterAttackPrepared": true,
		}
	if threat >= CRITICAL_THRESHOLD:
		return {
			"level": "mobilized",
			"enemyStrengthMultiplier": 1.25,
			"counterAttackPrepared": true,
		}
	if threat >= HIGH_THRESHOLD:
		return {
			"level": "alert",
			"enemyStrengthMultiplier": 1.15,
			"counterAttackPrepared": false,
		}
	if threat >= CAUTION_THRESHOLD:
		return {
			"level": "watching",
			"enemyStrengthMultiplier": 1.05,
			"counterAttackPrepared": false,
		}
	return {
		"level": "calm",
		"enemyStrengthMultiplier": 1.0,
		"counterAttackPrepared": false,
	}


static func _reactionsEqual(left: Dictionary, right: Dictionary) -> bool:
	return (
		str(left.get("level", "")) == str(right.get("level", ""))
		and is_equal_approx(float(left.get("enemyStrengthMultiplier", 1.0)), float(right.get("enemyStrengthMultiplier", 1.0)))
		and bool(left.get("counterAttackPrepared", false)) == bool(right.get("counterAttackPrepared", false))
	)
