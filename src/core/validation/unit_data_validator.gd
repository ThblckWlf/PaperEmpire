extends RefCounted
class_name UnitDataValidator


static func validate(units: Array[UnitData]) -> ValidationResult:
	var result := ValidationResult.new()
	var knownIds: Dictionary = {}
	var allowedIds := {
		GameIds.INFANTRY_UNIT_ID: true,
		GameIds.CAVALRY_UNIT_ID: true,
		GameIds.ARTILLERY_UNIT_ID: true,
	}

	for unit in units:
		if unit.id == GameIds.EMPTY_ID:
			result.addError("Unit has empty id.")
			continue

		if knownIds.has(unit.id):
			result.addError("Duplicate unit id: %s." % unit.id)
		else:
			knownIds[unit.id] = true

		if not allowedIds.has(unit.id):
			result.addError("Unknown MVP unit id: %s." % unit.id)

		if unit.name.is_empty():
			result.addError("Unit %s has empty name." % unit.id)

		if unit.cost <= 0:
			result.addError("Unit %s has non-positive cost." % unit.id)

		if unit.combatPower <= 0:
			result.addError("Unit %s has non-positive combatPower." % unit.id)

		if unit.foodUpkeep < 0:
			result.addError("Unit %s has negative foodUpkeep." % unit.id)

		if unit.moveSpeed <= 0.0 or is_nan(unit.moveSpeed):
			result.addError("Unit %s has invalid moveSpeed." % unit.id)

	return result
