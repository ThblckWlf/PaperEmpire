extends RefCounted
class_name RunStateSerializer


const SAVE_FORMAT := preload("res://src/save/save_format.gd")


static func serializeRunState(runState: RunState) -> Dictionary:
	if runState == null:
		return {}

	return {
		"schemaVersion": SAVE_FORMAT.SCHEMA_VERSION,
		"time": _serializeValue(runState.time),
		"speed": int(runState.speed),
		"resources": _serializeValue(runState.resources),
		"worldReaction": _serializeValue(runState.worldReaction),
		"economy": _serializeValue(runState.economy),
		"countries": _serializeCountries(runState.countries),
		"armies": _serializeArmies(runState.armies),
		"battles": _serializeBattles(runState.battles),
		"activeUpgradeChoice": _serializeValue(runState.activeUpgradeChoice),
		"upgrades": _serializeValue(runState.upgrades),
		"upgradeEffects": _serializeValue(runState.upgradeEffects),
		"miniGoalState": _serializeValue(runState.miniGoalState),
		"miniGoals": _serializeValue(runState.miniGoals),
		"runStatus": str(runState.runStatus),
	}


static func containsOnlyJsonValues(value: Variant) -> bool:
	var valueType := typeof(value)
	match valueType:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item in value as Array:
				if not containsOnlyJsonValues(item):
					return false
			return true
		TYPE_DICTIONARY:
			var data := value as Dictionary
			for key in data.keys():
				if typeof(key) != TYPE_STRING:
					return false
				if not containsOnlyJsonValues(data[key]):
					return false
			return true
		_:
			return false


static func _serializeCountries(countries: Dictionary) -> Dictionary:
	var serialized := {}
	var countryIds := countries.keys()
	countryIds.sort()
	for countryId in countryIds:
		var country := countries[countryId] as CountryData
		if country == null:
			continue

		serialized[str(country.id)] = {
			"id": str(country.id),
			"name": country.name,
			"ownerId": str(country.ownerId),
			"goldPerMonth": country.goldPerMonth,
			"foodPerMonth": country.foodPerMonth,
			"defense": country.defense,
			"center": _serializeVector2(country.center),
			"neighbors": _serializeValue(country.neighbors),
		}
	return serialized


static func _serializeArmies(armies: Dictionary) -> Dictionary:
	var serialized := {}
	var armyIds := armies.keys()
	armyIds.sort()
	for armyId in armyIds:
		var army := armies[armyId] as ArmyData
		if army == null:
			continue

		serialized[str(army.id)] = {
			"id": str(army.id),
			"ownerId": str(army.ownerId),
			"locationCountryId": str(army.locationCountryId),
			"targetCountryId": str(army.targetCountryId),
			"units": _serializeValue(army.units),
			"status": int(army.status),
			"movementProgress": float(army.movementProgress),
		}
	return serialized


static func _serializeBattles(battles: Dictionary) -> Dictionary:
	var serialized := {}
	var battleIds := battles.keys()
	battleIds.sort()
	for battleId in battleIds:
		var battle = battles[battleId]
		if battle == null:
			continue

		serialized[str(battleId)] = {
			"id": str(battle.get("id")),
			"attackerArmyId": str(battle.get("attackerArmyId")),
			"sourceCountryId": str(battle.get("sourceCountryId")),
			"targetCountryId": str(battle.get("targetCountryId")),
			"status": int(battle.get("status")),
			"elapsedSeconds": float(battle.get("elapsedSeconds")),
			"durationSeconds": float(battle.get("durationSeconds")),
			"attackerPower": float(battle.get("attackerPower")),
			"defenderPower": float(battle.get("defenderPower")),
			"attackerWon": bool(battle.get("attackerWon")),
			"winnerOwnerId": str(battle.get("winnerOwnerId")),
			"casualties": _serializeValue(battle.get("casualties")),
		}
	return serialized


static func _serializeValue(value: Variant) -> Variant:
	var valueType := typeof(value)
	match valueType:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME:
			return str(value)
		TYPE_VECTOR2:
			return _serializeVector2(value as Vector2)
		TYPE_ARRAY:
			var serializedArray := []
			for item in value as Array:
				serializedArray.append(_serializeValue(item))
			return serializedArray
		TYPE_DICTIONARY:
			var serializedDictionary := {}
			var data := value as Dictionary
			for key in data.keys():
				serializedDictionary[str(key)] = _serializeValue(data[key])
			return serializedDictionary
		_:
			push_warning("Unsupported save value type skipped: %s" % valueType)
			return null


static func _serializeVector2(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}
