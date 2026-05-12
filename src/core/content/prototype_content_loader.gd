extends RefCounted
class_name PrototypeContentLoader


const UNITS_PATH: String = "res://data/units.json"
const COUNTRIES_PATH: String = "res://data/countries.json"
const UPGRADES_PATH: String = "res://data/upgrades.json"
const MINI_GOALS_PATH: String = "res://data/miniGoals.json"
const META_UPGRADES_PATH: String = "res://data/metaUpgrades.json"
const MAP_SHAPES_PATH: String = "res://data/mapShapes.json"


static func loadUnits() -> Array[UnitData]:
	var rows := _loadJsonArray(UNITS_PATH)
	var units: Array[UnitData] = []
	for row in rows:
		if not (row is Dictionary):
			continue

		var rowData := row as Dictionary
		var data := UnitData.new()
		data.id = StringName(str(rowData.get("id", "")))
		data.name = str(rowData.get("name", ""))
		data.cost = int(rowData.get("cost", 0))
		data.combatPower = int(rowData.get("combatPower", 0))
		data.foodUpkeep = int(rowData.get("foodUpkeep", 0))
		data.moveSpeed = float(rowData.get("moveSpeed", 0.0))
		data.bonuses = _dictionaryValue(rowData.get("bonuses", {}))
		units.append(data)
	return units


static func loadCountries() -> Array[CountryData]:
	var rows := _loadJsonArray(COUNTRIES_PATH)
	var countries: Array[CountryData] = []
	for row in rows:
		if not (row is Dictionary):
			continue

		var rowData := row as Dictionary
		var data := CountryData.new()
		data.id = StringName(str(rowData.get("id", "")))
		data.name = str(rowData.get("name", ""))
		data.ownerId = StringName(str(rowData.get("ownerId", "")))
		data.goldPerMonth = int(rowData.get("goldPerMonth", 0))
		data.foodPerMonth = int(rowData.get("foodPerMonth", 0))
		data.defense = int(rowData.get("defense", 0))
		data.center = _vector2Value(_dictionaryValue(rowData.get("center", {})))
		data.neighbors = _stringNameArray(rowData.get("neighbors", []))
		data.aiCooldownMonths = int(rowData.get("aiCooldownMonths", data.aiCooldownMonths))
		data.isUnderAttack = bool(rowData.get("isUnderAttack", data.isUnderAttack))
		data.aiAggression = float(rowData.get("aiAggression", data.aiAggression))
		data.aiExpansionDesire = float(rowData.get("aiExpansionDesire", data.aiExpansionDesire))
		data.aiAttackCooldownMonths = int(rowData.get("aiAttackCooldownMonths", data.aiAttackCooldownMonths))
		countries.append(data)
	return countries


static func loadUpgrades() -> Array[Dictionary]:
	return _dictionaryRows(_loadJsonArray(UPGRADES_PATH))


static func loadMiniGoals() -> Array[Dictionary]:
	return _dictionaryRows(_loadJsonArray(MINI_GOALS_PATH))


static func loadMetaUpgrades() -> Array[Dictionary]:
	return _dictionaryRows(_loadJsonArray(META_UPGRADES_PATH))


static func loadMapShapes() -> Dictionary:
	var rows := _loadJsonArray(MAP_SHAPES_PATH)
	var shapes := {}
	for row in rows:
		if not (row is Dictionary):
			continue

		var rowData := row as Dictionary
		var countryId := StringName(str(rowData.get("countryId", "")))
		if countryId == GameIds.EMPTY_ID:
			continue

		var polygons := _polygonArray(rowData.get("polygons", []))
		if polygons.is_empty():
			var points := _vector2Array(rowData.get("points", []))
			if points.size() >= 3:
				polygons.append(points)
		shapes[countryId] = polygons
	return shapes


static func _loadJsonArray(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Prototype content file not found: %s" % path)
		return []

	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not (parsed is Array):
		push_error("Prototype content file is not a JSON array: %s" % path)
		return []

	var parsedRows := parsed as Array
	return parsedRows


static func _dictionaryRows(rows: Array) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	for row in rows:
		if row is Dictionary:
			var rowData := row as Dictionary
			dictionaries.append(rowData)
	return dictionaries


static func _dictionaryValue(value: Variant) -> Dictionary:
	if value is Dictionary:
		var data := value as Dictionary
		return data
	return {}


static func _stringNameArray(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not (value is Array):
		return result

	for item in value:
		result.append(StringName(str(item)))
	return result


static func _vector2Value(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))


static func _vector2Array(value: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not (value is Array):
		return result

	for item in value:
		if item is Dictionary:
			result.append(_vector2Value(item as Dictionary))
	return result


static func _polygonArray(value: Variant) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not (value is Array):
		return result

	for item in value:
		var points := _vector2Array(item)
		if points.size() >= 3:
			result.append(points)
	return result
