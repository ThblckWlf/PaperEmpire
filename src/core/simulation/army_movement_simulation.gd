extends RefCounted
class_name ArmyMovementSimulation


const MOVEMENT_SECONDS_PER_EDGE: float = 8.0
const PROGRESS_EPSILON: float = 0.00001


static func requestMove(runState: RunState, armyId: StringName, targetCountryId: StringName) -> Dictionary:
	var result := {
		"accepted": false,
		"armyId": armyId,
		"targetCountryId": targetCountryId,
		"reason": "",
	}
	if runState == null:
		result["reason"] = "missing_run_state"
		return result

	if not runState.armies.has(armyId):
		result["reason"] = "unknown_army"
		return result

	if not runState.countries.has(targetCountryId):
		result["reason"] = "unknown_target_country"
		return result

	var army := runState.armies[armyId] as ArmyData
	if army == null:
		result["reason"] = "invalid_army"
		return result

	if army.status == ArmyStatus.Value.Moving:
		result["reason"] = "army_already_moving"
		return result

	if army.locationCountryId == targetCountryId:
		result["reason"] = "already_at_target"
		return result

	var sourceCountry := runState.countries.get(army.locationCountryId, null) as CountryData
	if sourceCountry == null:
		result["reason"] = "unknown_source_country"
		return result

	if not sourceCountry.neighbors.has(targetCountryId):
		result["reason"] = "target_not_neighbor"
		return result

	army.targetCountryId = targetCountryId
	army.status = ArmyStatus.Value.Moving
	army.movementProgress = 0.0
	result["accepted"] = true
	result["sourceCountryId"] = army.locationCountryId
	return result


static func advanceMovement(runState: RunState, deltaSeconds: float) -> Array[Dictionary]:
	var completedMoves: Array[Dictionary] = []
	if runState == null or deltaSeconds <= 0.0:
		return completedMoves

	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or army.status != ArmyStatus.Value.Moving:
			continue

		var sourceCountryId := army.locationCountryId
		var nextProgress := army.movementProgress + deltaSeconds / MOVEMENT_SECONDS_PER_EDGE
		if nextProgress + PROGRESS_EPSILON < 1.0:
			army.movementProgress = nextProgress
			continue

		army.movementProgress = 1.0
		army.locationCountryId = army.targetCountryId
		army.targetCountryId = GameIds.EMPTY_ID
		army.status = ArmyStatus.Value.Stationed
		army.movementProgress = 0.0
		completedMoves.append({
			"armyId": army.id,
			"fromCountryId": sourceCountryId,
			"toCountryId": army.locationCountryId,
		})
	return completedMoves
