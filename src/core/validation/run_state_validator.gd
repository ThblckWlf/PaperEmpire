extends RefCounted
class_name RunStateValidator


static func validate(runState: RunState) -> ValidationResult:
	var result := ValidationResult.new()
	_validateTime(runState.time, result)
	_validateResources(runState.resources, result)
	_validateSpeed(runState.speed, result)
	_validateArmyLocations(runState, result)
	return result


static func _validateTime(time: Dictionary, result: ValidationResult) -> void:
	var elapsedSeconds = time.get("elapsedSeconds", 0.0)
	if not _isNumeric(elapsedSeconds):
		result.addError("RunState time elapsedSeconds is not numeric.")
	elif is_nan(float(elapsedSeconds)):
		result.addError("RunState time elapsedSeconds is NaN.")
	elif float(elapsedSeconds) < 0.0:
		result.addError("RunState time elapsedSeconds is negative.")

	var week := int(time.get("week", 0))
	if week < 1 or week > GameTime.WEEKS_PER_MONTH:
		result.addError("RunState time week is out of range: %s." % week)

	var month := int(time.get("month", 0))
	if month < 1 or month > GameTime.MONTHS_PER_YEAR:
		result.addError("RunState time month is out of range: %s." % month)

	var year := int(time.get("year", 0))
	if year < 1:
		result.addError("RunState time year is out of range: %s." % year)


static func _validateResources(resources: Dictionary, result: ValidationResult) -> void:
	for key in ["gold", "food", "threat"]:
		if not resources.has(key):
			result.addError("RunState resources missing key: %s." % key)
			continue

		var value = resources[key]
		var valueType := typeof(value)
		if valueType != TYPE_INT and valueType != TYPE_FLOAT:
			result.addError("RunState resource %s is not numeric." % key)
			continue

		if valueType == TYPE_FLOAT and is_nan(float(value)):
			result.addError("RunState resource %s is NaN." % key)


static func _validateSpeed(speed: int, result: ValidationResult) -> void:
	var validSpeeds := [
		GameSpeed.Value.Paused,
		GameSpeed.Value.Normal,
		GameSpeed.Value.Fast,
		GameSpeed.Value.VeryFast,
	]

	if not validSpeeds.has(speed):
		result.addError("RunState speed is invalid: %s." % speed)


static func _validateArmyLocations(runState: RunState, result: ValidationResult) -> void:
	for armyId in runState.armies.keys():
		var army = runState.armies[armyId]
		if not (army is ArmyData):
			result.addError("RunState army %s is not ArmyData." % armyId)
			continue

		if not runState.countries.has(army.locationCountryId):
			result.addError("Army %s has unknown locationCountryId: %s." % [army.id, army.locationCountryId])

		if army.targetCountryId != GameIds.EMPTY_ID and not runState.countries.has(army.targetCountryId):
			result.addError("Army %s has unknown targetCountryId: %s." % [army.id, army.targetCountryId])


static func _isNumeric(value: Variant) -> bool:
	var valueType := typeof(value)
	return valueType == TYPE_INT or valueType == TYPE_FLOAT
