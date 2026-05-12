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
		"aiGoldByCountry": _serializeValue(runState.aiGoldByCountry),
		"activeUpgradeChoice": _serializeValue(runState.activeUpgradeChoice),
		"upgrades": _serializeValue(runState.upgrades),
		"upgradeEffects": _serializeValue(runState.upgradeEffects),
		"miniGoalState": _serializeValue(runState.miniGoalState),
		"miniGoals": _serializeValue(runState.miniGoals),
		"runStatus": str(runState.runStatus),
	}


static func deserializeRunState(data: Dictionary) -> RunState:
	var runState := RunState.new()
	runState.time = _dictionaryValue(data.get("time", GameTime.createInitialState())).duplicate(true)
	GameTime.applyElapsedSeconds(runState.time, GameTime.getElapsedSeconds(runState.time))
	runState.speed = int(data.get("speed", GameSpeed.Value.Normal))
	runState.resources = _dictionaryValue(data.get("resources", runState.resources)).duplicate(true)
	runState.worldReaction = _dictionaryValue(data.get("worldReaction", runState.worldReaction)).duplicate(true)
	runState.economy = _dictionaryValue(data.get("economy", runState.economy)).duplicate(true)
	runState.countries = _deserializeCountries(_dictionaryValue(data.get("countries", {})))
	runState.armies = _deserializeArmies(_dictionaryValue(data.get("armies", {})))
	runState.battles = _deserializeBattles(_dictionaryValue(data.get("battles", {})))
	runState.aiGoldByCountry = _dictionaryValue(data.get("aiGoldByCountry", {})).duplicate(true)
	runState.activeUpgradeChoice = _dictionaryValue(data.get("activeUpgradeChoice", {})).duplicate(true)
	runState.upgrades = _deserializeStringNameArray(data.get("upgrades", []))
	runState.upgradeEffects = _dictionaryValue(data.get("upgradeEffects", runState.upgradeEffects)).duplicate(true)
	runState.miniGoalState = _dictionaryValue(data.get("miniGoalState", runState.miniGoalState)).duplicate(true)
	runState.miniGoals = _deserializeDictionaryArray(data.get("miniGoals", []))
	runState.runStatus = StringName(str(data.get("runStatus", RunState.RUN_STATUS_NOT_STARTED)))
	return runState


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
			"defenderArmyIds": _serializeValue(battle.get("defenderArmyIds")),
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


static func _deserializeCountries(data: Dictionary) -> Dictionary:
	var countries := {}
	var countryIds := data.keys()
	countryIds.sort()
	for countryId in countryIds:
		var row := _dictionaryValue(data[countryId])
		var country := CountryData.new()
		country.id = StringName(str(row.get("id", countryId)))
		country.name = str(row.get("name", ""))
		country.ownerId = StringName(str(row.get("ownerId", GameIds.NEUTRAL_OWNER_ID)))
		country.goldPerMonth = int(row.get("goldPerMonth", 0))
		country.foodPerMonth = int(row.get("foodPerMonth", 0))
		country.defense = int(row.get("defense", 0))
		country.center = _deserializeVector2(_dictionaryValue(row.get("center", {})))
		country.neighbors = _deserializeStringNameArray(row.get("neighbors", []))
		countries[country.id] = country
	return countries


static func _deserializeArmies(data: Dictionary) -> Dictionary:
	var armies := {}
	var armyIds := data.keys()
	armyIds.sort()
	for armyId in armyIds:
		var row := _dictionaryValue(data[armyId])
		var army := ArmyData.new()
		army.id = StringName(str(row.get("id", armyId)))
		army.ownerId = StringName(str(row.get("ownerId", GameIds.EMPTY_ID)))
		army.locationCountryId = StringName(str(row.get("locationCountryId", GameIds.EMPTY_ID)))
		army.targetCountryId = StringName(str(row.get("targetCountryId", GameIds.EMPTY_ID)))
		army.units = _dictionaryValue(row.get("units", {})).duplicate(true)
		army.status = int(row.get("status", ArmyStatus.Value.Stationed))
		army.movementProgress = float(row.get("movementProgress", 0.0))
		armies[army.id] = army
	return armies


static func _deserializeBattles(data: Dictionary) -> Dictionary:
	var battles := {}
	var battleIds := data.keys()
	battleIds.sort()
	for battleId in battleIds:
		var row := _dictionaryValue(data[battleId])
		var battle := BattleData.new()
		battle.id = StringName(str(row.get("id", battleId)))
		battle.attackerArmyId = StringName(str(row.get("attackerArmyId", GameIds.EMPTY_ID)))
		battle.defenderArmyIds = _deserializeStringNameArray(row.get("defenderArmyIds", []))
		battle.sourceCountryId = StringName(str(row.get("sourceCountryId", GameIds.EMPTY_ID)))
		battle.targetCountryId = StringName(str(row.get("targetCountryId", GameIds.EMPTY_ID)))
		battle.status = int(row.get("status", BattleStatus.Value.Pending))
		battle.elapsedSeconds = float(row.get("elapsedSeconds", 0.0))
		battle.durationSeconds = float(row.get("durationSeconds", 0.0))
		battle.attackerPower = float(row.get("attackerPower", 0.0))
		battle.defenderPower = float(row.get("defenderPower", 0.0))
		battle.attackerWon = bool(row.get("attackerWon", false))
		battle.winnerOwnerId = StringName(str(row.get("winnerOwnerId", GameIds.EMPTY_ID)))
		battle.casualties = _dictionaryValue(row.get("casualties", {})).duplicate(true)
		battles[battle.id] = battle
	return battles


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


static func _deserializeVector2(data: Dictionary) -> Vector2:
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


static func _deserializeStringNameArray(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not (value is Array):
		return result

	for item in value as Array:
		result.append(StringName(str(item)))
	return result


static func _deserializeDictionaryArray(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result

	for item in value as Array:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}
