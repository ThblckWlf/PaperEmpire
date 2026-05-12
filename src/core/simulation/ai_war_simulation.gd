extends RefCounted
class_name AiWarSimulation


const COMBAT_SIMULATION := preload("res://src/core/simulation/combat_simulation.gd")

const MAX_AI_ATTACKS_PER_DECISION_TICK: int = 3
const ATTACK_CONFIDENCE_THRESHOLD: float = 1.25
const PLAYER_STRONG_CONFIDENCE_THRESHOLD: float = 1.35
const PLAYER_HIGH_THREAT_CONFIDENCE_THRESHOLD: float = 1.10
const PLAYER_WEAK_BORDER_CONFIDENCE_THRESHOLD: float = 1.10
const HIGH_PLAYER_THREAT: int = 60
const NPC_ATTACK_COOLDOWN_MONTHS: int = 2
const PLAYER_ATTACK_COOLDOWN_MONTHS: int = 3


static func applyMonthTick(runState: RunState, units: Array[UnitData]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if runState == null:
		return events

	_tickCooldowns(runState)
	var candidates := _collectAttackCandidates(runState, units)
	var startedOwnerIds := {}
	var startedSourceCountryIds := {}
	var startedAttackCount := 0
	while startedAttackCount < MAX_AI_ATTACKS_PER_DECISION_TICK:
		var candidateIndex := _bestCandidateIndex(candidates, startedOwnerIds, startedSourceCountryIds)
		if candidateIndex < 0:
			break

		var candidate: Dictionary = candidates[candidateIndex]
		candidates.remove_at(candidateIndex)
		var sourceCountry := runState.countries.get(StringName(str(candidate.get("sourceCountryId", ""))), null) as CountryData
		var targetCountry := runState.countries.get(StringName(str(candidate.get("targetCountryId", ""))), null) as CountryData
		if sourceCountry == null or targetCountry == null:
			continue

		if sourceCountry.aiCooldownMonths > 0 or sourceCountry.isUnderAttack or targetCountry.isUnderAttack:
			continue

		var attackResult: Dictionary = COMBAT_SIMULATION.startAttack(
			runState,
			StringName(str(candidate.get("armyId", ""))),
			targetCountry.id,
			units
		)
		if not bool(attackResult.get("accepted", false)):
			events.append({
				"eventType": EventType.AI_ATTACK_REJECTED,
				"payload": _rejectedPayload(candidate, attackResult),
			})
			continue

		var targetWasPlayer := targetCountry.ownerId == GameIds.PLAYER_OWNER_ID
		sourceCountry.aiCooldownMonths = _cooldownMonthsForAttack(sourceCountry, targetWasPlayer)
		targetCountry.isUnderAttack = true
		var payload := _attackStartedPayload(sourceCountry, targetCountry, candidate, attackResult)
		print("AI Decision: %s attacks %s. Power %.0f vs %.0f." % [
			sourceCountry.name.to_lower(),
			targetCountry.name.to_lower(),
			float(payload.get("attackerPower", 0.0)),
			float(payload.get("defenderPower", 0.0)),
		])

		events.append({
			"eventType": EventType.ARMY_MOVE_STARTED,
			"payload": payload,
		})
		events.append({
			"eventType": EventType.AI_ATTACK_STARTED,
			"payload": payload,
		})
		if targetWasPlayer:
			print("AI Warning: %s attacks player country %s." % [
				sourceCountry.name.to_lower(),
				targetCountry.name.to_lower(),
			])
			events.append({
				"eventType": EventType.PLAYER_ATTACKED,
				"payload": payload,
			})

		startedOwnerIds[sourceCountry.ownerId] = true
		startedSourceCountryIds[sourceCountry.id] = true
		startedAttackCount += 1
	return events


static func _tickCooldowns(runState: RunState) -> void:
	for countryId in runState.countries.keys():
		var country := runState.countries[countryId] as CountryData
		if country == null or country.ownerId == GameIds.PLAYER_OWNER_ID:
			continue

		if country.aiCooldownMonths > 0:
			country.aiCooldownMonths -= 1


static func _collectAttackCandidates(runState: RunState, units: Array[UnitData]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = _decisionSeed(runState)
	var countryIds := runState.countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var sourceCountry := runState.countries[countryId] as CountryData
		if sourceCountry == null or sourceCountry.ownerId == GameIds.PLAYER_OWNER_ID:
			continue

		if sourceCountry.aiCooldownMonths > 0:
			continue
		if sourceCountry.isUnderAttack:
			continue

		var readyArmies := _readyArmiesAtCountry(runState, sourceCountry)
		if readyArmies.is_empty():
			continue

		for neighborId in sourceCountry.neighbors:
			var targetCountry := runState.countries.get(neighborId, null) as CountryData
			if targetCountry == null:
				continue

			if not _isValidTarget(runState, sourceCountry, targetCountry):
				continue

			var defenderUnits := _stationedDefenderUnits(runState, targetCountry.id, sourceCountry.ownerId)
			var attackerArmy := _primaryAttackArmy(runState, sourceCountry, readyArmies, targetCountry, defenderUnits, units)
			if attackerArmy == null:
				continue

			var splitResult: Dictionary = COMBAT_SIMULATION.splitUnitsForAttack(attackerArmy.units)
			if not bool(splitResult.get("accepted", false)):
				continue

			var attackingUnits := splitResult.get("attackingUnits", {}) as Dictionary
			var reserveUnits := splitResult.get("reserveUnits", {}) as Dictionary
			var attackerPower := _armyPowerForUnits(runState, sourceCountry.ownerId, attackingUnits, targetCountry, defenderUnits, units)
			var reservePower := _armyPowerForUnits(runState, sourceCountry.ownerId, reserveUnits, sourceCountry, {}, units)
			if reservePower <= 0.0:
				print("AI skipped attack: not enough reserve.")
				continue

			var defenderPower := _targetDefensePower(runState, targetCountry, sourceCountry.ownerId, units, attackingUnits)
			if not _passesConfidenceGate(runState, targetCountry, attackerPower, defenderPower):
				continue

			var attackChance := _attackChance(sourceCountry, targetCountry, runState)
			if rng.randf() > attackChance:
				continue

			candidates.append({
				"sourceCountryId": sourceCountry.id,
				"targetCountryId": targetCountry.id,
				"armyId": attackerArmy.id,
				"ownerId": sourceCountry.ownerId,
				"targetOwnerId": targetCountry.ownerId,
				"attackerPower": attackerPower,
				"defenderPower": defenderPower,
				"reservePower": reservePower,
				"attackingUnitCount": int(splitResult.get("attackingUnitCount", 0)),
				"reserveUnitCount": int(splitResult.get("reserveUnitCount", 0)),
				"score": _targetScore(sourceCountry, targetCountry, attackerPower, defenderPower, rng),
				"targetIsPlayer": targetCountry.ownerId == GameIds.PLAYER_OWNER_ID,
			})
	return candidates


static func _armyPowerForUnits(
	runState: RunState,
	ownerId: StringName,
	armyUnits: Dictionary,
	targetCountry: CountryData,
	defenderUnits: Dictionary,
	units: Array[UnitData]
) -> float:
	var projectedArmy := ArmyData.new()
	projectedArmy.ownerId = ownerId
	projectedArmy.units = armyUnits
	var economy := runState.economy if ownerId == GameIds.PLAYER_OWNER_ID else {}
	return COMBAT_SIMULATION.calculateArmyCombatPower(projectedArmy, units, economy, {
		"targetDefense": targetCountry.defense,
		"opposingUnits": defenderUnits,
	})


static func _isValidTarget(runState: RunState, sourceCountry: CountryData, targetCountry: CountryData) -> bool:
	if targetCountry.ownerId == sourceCountry.ownerId:
		return false

	if targetCountry.isUnderAttack:
		return false

	if not sourceCountry.neighbors.has(targetCountry.id):
		return false

	if _ownerAlreadyAttackingTarget(runState, sourceCountry.ownerId, targetCountry.id):
		return false

	if _hasAnyActiveAttackToTarget(runState, targetCountry.id):
		return false

	return true


static func _passesConfidenceGate(
	runState: RunState,
	targetCountry: CountryData,
	attackerPower: float,
	defenderPower: float
) -> bool:
	if defenderPower <= 0.0:
		return attackerPower > 0.0

	if targetCountry.ownerId != GameIds.PLAYER_OWNER_ID:
		return attackerPower >= defenderPower * ATTACK_CONFIDENCE_THRESHOLD

	var threat := int(runState.resources.get("threat", 0))
	if attackerPower >= defenderPower * PLAYER_STRONG_CONFIDENCE_THRESHOLD:
		return true

	if threat >= HIGH_PLAYER_THREAT and attackerPower >= defenderPower * PLAYER_HIGH_THREAT_CONFIDENCE_THRESHOLD:
		return true

	var weakBorderPower := maxf(180.0, attackerPower * 0.70)
	if defenderPower <= weakBorderPower and attackerPower >= defenderPower * PLAYER_WEAK_BORDER_CONFIDENCE_THRESHOLD:
		return true

	return false


static func _attackChance(sourceCountry: CountryData, targetCountry: CountryData, runState: RunState) -> float:
	if sourceCountry.aiAggression >= 1.0 and sourceCountry.aiExpansionDesire >= 1.0:
		return 1.0

	var chance := 0.18 + sourceCountry.aiAggression * 0.45 + sourceCountry.aiExpansionDesire * 0.25
	if targetCountry.ownerId == GameIds.PLAYER_OWNER_ID and int(runState.resources.get("threat", 0)) >= HIGH_PLAYER_THREAT:
		chance += 0.15
	return clampf(chance, 0.05, 0.80)


static func _cooldownMonthsForAttack(sourceCountry: CountryData, targetWasPlayer: bool) -> int:
	var minimumCooldown := PLAYER_ATTACK_COOLDOWN_MONTHS if targetWasPlayer else NPC_ATTACK_COOLDOWN_MONTHS
	return maxi(minimumCooldown, sourceCountry.aiAttackCooldownMonths)


static func _targetScore(
	sourceCountry: CountryData,
	targetCountry: CountryData,
	attackerPower: float,
	defenderPower: float,
	rng: RandomNumberGenerator
) -> float:
	var powerRatio := attackerPower / maxf(defenderPower, 1.0)
	var resourceScore := float(targetCountry.goldPerMonth) * 1.4 + float(targetCountry.foodPerMonth)
	var weaknessScore := powerRatio * 18.0 - defenderPower * 0.035
	var defensePenalty := float(targetCountry.defense) * 1.2
	var aggressionScore := sourceCountry.aiAggression * 16.0 + sourceCountry.aiExpansionDesire * 10.0
	return resourceScore + weaknessScore + aggressionScore - defensePenalty + rng.randf_range(-8.0, 8.0)


static func _bestCandidateIndex(
	candidates: Array[Dictionary],
	startedOwnerIds: Dictionary,
	startedSourceCountryIds: Dictionary
) -> int:
	var bestIndex := -1
	var bestScore := -INF
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		var ownerId := StringName(str(candidate.get("ownerId", "")))
		var sourceCountryId := StringName(str(candidate.get("sourceCountryId", "")))
		if startedOwnerIds.has(ownerId) or startedSourceCountryIds.has(sourceCountryId):
			continue

		var score := float(candidate.get("score", -INF))
		if score > bestScore:
			bestScore = score
			bestIndex = index
	return bestIndex


static func _readyArmiesAtCountry(runState: RunState, country: CountryData) -> Array[ArmyData]:
	var armies: Array[ArmyData] = []
	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.ownerId != country.ownerId:
			continue

		if army.locationCountryId != country.id:
			continue

		if army.status != ArmyStatus.Value.Stationed:
			continue

		if _unitCount(army.units) <= 0:
			continue

		armies.append(army)
	return armies


static func _primaryAttackArmy(
	runState: RunState,
	sourceCountry: CountryData,
	readyArmies: Array[ArmyData],
	targetCountry: CountryData,
	defenderUnits: Dictionary,
	units: Array[UnitData]
) -> ArmyData:
	var bestArmy: ArmyData = null
	var bestPower := -1.0
	for army in readyArmies:
		var splitResult: Dictionary = COMBAT_SIMULATION.splitUnitsForAttack(army.units)
		if not bool(splitResult.get("accepted", false)):
			continue

		var power := _armyPowerForUnits(
			runState,
			sourceCountry.ownerId,
			splitResult.get("attackingUnits", {}) as Dictionary,
			targetCountry,
			defenderUnits,
			units
		)
		if power > bestPower:
			bestPower = power
			bestArmy = army
	return bestArmy


static func _targetDefensePower(
	runState: RunState,
	targetCountry: CountryData,
	attackerOwnerId: StringName,
	units: Array[UnitData],
	attackerUnits: Dictionary
) -> float:
	var power := COMBAT_SIMULATION.calculateCountryDefensePower(targetCountry, runState.upgradeEffects, runState.worldReaction)
	var armyIds := runState.armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.ownerId == attackerOwnerId:
			continue

		if army.locationCountryId != targetCountry.id:
			continue

		if army.status != ArmyStatus.Value.Stationed:
			continue

		power += COMBAT_SIMULATION.calculateArmyCombatPower(army, units, {}, {
			"opposingUnits": attackerUnits,
		})
	return maxf(power, 0.0)


static func _stationedDefenderUnits(runState: RunState, targetCountryId: StringName, attackerOwnerId: StringName) -> Dictionary:
	var combined := {}
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.ownerId == attackerOwnerId:
			continue

		if army.locationCountryId != targetCountryId or army.status != ArmyStatus.Value.Stationed:
			continue

		for unitId in army.units.keys():
			var normalizedId := StringName(str(unitId))
			combined[normalizedId] = int(combined.get(normalizedId, 0)) + maxi(0, int(army.units.get(unitId, 0)))
	return combined


static func _ownerAlreadyAttackingTarget(runState: RunState, ownerId: StringName, targetCountryId: StringName) -> bool:
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army == null:
			continue

		if army.ownerId == ownerId and army.status == ArmyStatus.Value.Attacking and army.targetCountryId == targetCountryId:
			return true

	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle == null or battle.status != BattleStatus.Value.Active:
			continue

		if StringName(str(battle.get("attackerOwnerId"))) == ownerId and StringName(str(battle.get("targetCountryId"))) == targetCountryId:
			return true
	return false


static func _hasAnyActiveAttackToTarget(runState: RunState, targetCountryId: StringName) -> bool:
	for armyId in runState.armies.keys():
		var army := runState.armies[armyId] as ArmyData
		if army != null and army.status == ArmyStatus.Value.Attacking and army.targetCountryId == targetCountryId:
			return true

	for battleId in runState.battles.keys():
		var battle = runState.battles[battleId]
		if battle != null and battle.status == BattleStatus.Value.Active and StringName(str(battle.get("targetCountryId"))) == targetCountryId:
			return true
	return false


static func _attackStartedPayload(
	sourceCountry: CountryData,
	targetCountry: CountryData,
	candidate: Dictionary,
	attackResult: Dictionary
) -> Dictionary:
	var payload := attackResult.duplicate(true)
	payload["sourceCountryId"] = sourceCountry.id
	payload["targetCountryId"] = targetCountry.id
	payload["sourceCountryName"] = sourceCountry.name
	payload["targetCountryName"] = targetCountry.name
	payload["attackerOwnerId"] = sourceCountry.ownerId
	payload["targetOwnerId"] = targetCountry.ownerId
	payload["attackerPower"] = float(candidate.get("attackerPower", 0.0))
	payload["defenderPower"] = float(candidate.get("defenderPower", 0.0))
	payload["targetIsPlayer"] = bool(candidate.get("targetIsPlayer", false))
	payload["aiCooldownMonths"] = sourceCountry.aiCooldownMonths
	return payload


static func _rejectedPayload(candidate: Dictionary, attackResult: Dictionary) -> Dictionary:
	var payload := candidate.duplicate(true)
	payload["reason"] = str(attackResult.get("reason", "unknown_reason"))
	return payload


static func _decisionSeed(runState: RunState) -> int:
	var completedMonths := GameTime.getCompletedMonths(runState.time)
	return maxi(1, completedMonths * 1103515245 + int(runState.countries.size()) * 97)


static func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += maxi(0, int(units.get(unitId, 0)))
	return total
