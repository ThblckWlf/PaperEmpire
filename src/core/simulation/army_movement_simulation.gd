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

	if army.ownerId != GameIds.PLAYER_OWNER_ID:
		result["reason"] = "army_not_owned"
		return result

	if army.status == ArmyStatus.Value.Moving or army.status == ArmyStatus.Value.Attacking or army.status == ArmyStatus.Value.Fighting:
		result["reason"] = "army_already_moving"
		return result

	if army.status != ArmyStatus.Value.Stationed:
		result["reason"] = "army_not_stationed"
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

	var targetCountry := runState.countries.get(targetCountryId, null) as CountryData
	if targetCountry == null:
		result["reason"] = "invalid_target_country"
		return result

	if targetCountry.ownerId != GameIds.PLAYER_OWNER_ID:
		result["reason"] = "target_not_owned"
		return result

	army.targetCountryId = targetCountryId
	army.status = ArmyStatus.Value.Moving
	army.movementProgress = 0.0
	result["accepted"] = true
	result["sourceCountryId"] = army.locationCountryId
	result["isAttack"] = false
	return result


static func advanceMovement(
	runState: RunState,
	deltaSeconds: float,
	units: Array[UnitData] = []
) -> Array[Dictionary]:
	var completedMoves: Array[Dictionary] = []
	if runState == null or deltaSeconds <= 0.0:
		return completedMoves

	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null or not _isMovingStatus(army.status):
			continue

		var sourceCountryId := army.locationCountryId
		var targetCountryId := army.targetCountryId
		var moveDuration := _movementDurationSeconds(army, units)
		var nextProgress := army.movementProgress + deltaSeconds / moveDuration
		if nextProgress + PROGRESS_EPSILON < 1.0:
			army.movementProgress = nextProgress
			continue

		var wasAttack := army.status == ArmyStatus.Value.Attacking
		army.movementProgress = 1.0
		army.locationCountryId = targetCountryId
		if wasAttack:
			army.status = ArmyStatus.Value.Fighting
		else:
			army.targetCountryId = GameIds.EMPTY_ID
			army.status = ArmyStatus.Value.Stationed
		army.movementProgress = 0.0
		completedMoves.append({
			"armyId": army.id,
			"fromCountryId": sourceCountryId,
			"toCountryId": army.locationCountryId,
			"isAttack": wasAttack,
		})
	return completedMoves


static func _isMovingStatus(status: int) -> bool:
	return status == ArmyStatus.Value.Moving or status == ArmyStatus.Value.Attacking


static func _movementDurationSeconds(army: ArmyData, units: Array[UnitData]) -> float:
	var speedMultiplier := _armyMoveSpeedMultiplier(army, units)
	return MOVEMENT_SECONDS_PER_EDGE / maxf(speedMultiplier, 0.1)


static func _armyMoveSpeedMultiplier(army: ArmyData, units: Array[UnitData]) -> float:
	if army == null or units.is_empty():
		return 1.0

	var unitCatalog := {}
	for unit in units:
		unitCatalog[unit.id] = unit

	var weightedSpeed := 0.0
	var totalUnits := 0
	for unitId in army.units.keys():
		var amount := int(army.units.get(unitId, 0))
		if amount <= 0:
			continue

		var unit := unitCatalog.get(unitId, null) as UnitData
		if unit == null:
			continue

		weightedSpeed += float(amount) * maxf(unit.moveSpeed, 0.1)
		totalUnits += amount

	if totalUnits <= 0:
		return 1.0

	return weightedSpeed / float(totalUnits)
