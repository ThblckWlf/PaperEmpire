extends RefCounted
class_name GameTime


const SECONDS_PER_WEEK_AT_1X: float = 5.0
const WEEKS_PER_MONTH: int = 4
const MONTHS_PER_YEAR: int = 12
const FLOAT_EPSILON: float = 0.00001


static func createInitialState() -> Dictionary:
	return {
		"elapsedSeconds": 0.0,
		"week": 1,
		"month": 1,
		"year": 1,
	}


static func advance(time: Dictionary, deltaSeconds: float) -> int:
	if deltaSeconds <= 0.0:
		return 0

	var previousCompletedMonths := getCompletedMonths(time)
	var elapsedSeconds := getElapsedSeconds(time) + deltaSeconds
	if elapsedSeconds < 0.0:
		elapsedSeconds = 0.0

	applyElapsedSeconds(time, elapsedSeconds)
	return getCompletedMonths(time) - previousCompletedMonths


static func applyElapsedSeconds(time: Dictionary, elapsedSeconds: float) -> void:
	if is_nan(elapsedSeconds) or elapsedSeconds < 0.0:
		elapsedSeconds = 0.0

	var completedWeeks := _completedWeeksForElapsed(elapsedSeconds)
	var completedMonths := int(floor(float(completedWeeks) / float(WEEKS_PER_MONTH)))
	time["elapsedSeconds"] = elapsedSeconds
	time["week"] = completedWeeks % WEEKS_PER_MONTH + 1
	time["month"] = completedMonths % MONTHS_PER_YEAR + 1
	time["year"] = int(floor(float(completedMonths) / float(MONTHS_PER_YEAR))) + 1


static func getElapsedSeconds(time: Dictionary) -> float:
	var value = time.get("elapsedSeconds", 0.0)
	var valueType := typeof(value)
	if valueType != TYPE_INT and valueType != TYPE_FLOAT:
		return 0.0

	var elapsedSeconds := float(value)
	if is_nan(elapsedSeconds):
		return 0.0
	return elapsedSeconds


static func getCompletedWeeks(time: Dictionary) -> int:
	return _completedWeeksForElapsed(getElapsedSeconds(time))


static func getCompletedMonths(time: Dictionary) -> int:
	return int(floor(float(getCompletedWeeks(time)) / float(WEEKS_PER_MONTH)))


static func _completedWeeksForElapsed(elapsedSeconds: float) -> int:
	return int(floor((elapsedSeconds + FLOAT_EPSILON) / SECONDS_PER_WEEK_AT_1X))
