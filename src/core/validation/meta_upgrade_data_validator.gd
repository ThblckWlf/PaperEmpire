extends RefCounted
class_name MetaUpgradeDataValidator


const VALID_SCOPES := {
	"general": true,
	"country": true,
}

const VALID_EFFECT_TYPES := {
	"startGoldBonus": true,
	"startFoodBonus": true,
	"crownRewardMultiplier": true,
	"countryStartArmyBonus": true,
	"countryStartGoldBonus": true,
	"countryStartFoodBonus": true,
}


static func validate(rows: Array[Dictionary], countries: Array[CountryData]) -> ValidationResult:
	var result := ValidationResult.new()
	var seenIds := {}
	var countryIds := {}
	for country in countries:
		countryIds[country.id] = true

	for row in rows:
		var upgradeId := str(row.get("id", ""))
		var scope := str(row.get("scope", ""))
		var effectType := str(row.get("effectType", ""))

		if upgradeId == "":
			result.addError("Meta upgrade has empty id.")
		elif seenIds.has(upgradeId):
			result.addError("Duplicate meta upgrade id: %s." % upgradeId)
		else:
			seenIds[upgradeId] = true

		if str(row.get("name", "")) == "":
			result.addError("Meta upgrade %s has empty name." % upgradeId)
		if str(row.get("description", "")) == "":
			result.addError("Meta upgrade %s has empty description." % upgradeId)
		if not VALID_SCOPES.has(scope):
			result.addError("Meta upgrade %s has invalid scope: %s." % [upgradeId, scope])
		if not VALID_EFFECT_TYPES.has(effectType):
			result.addError("Meta upgrade %s has invalid effectType: %s." % [upgradeId, effectType])
		if int(row.get("maxLevel", 0)) <= 0:
			result.addError("Meta upgrade %s maxLevel must be positive." % upgradeId)
		if int(row.get("baseCost", 0)) < 0:
			result.addError("Meta upgrade %s baseCost is negative." % upgradeId)
		if int(row.get("costPerLevel", 0)) < 0:
			result.addError("Meta upgrade %s costPerLevel is negative." % upgradeId)
		if not _isNumeric(row.get("valuePerLevel", 0)):
			result.addError("Meta upgrade %s valuePerLevel is not numeric." % upgradeId)

		if scope == "country":
			var countryId := StringName(str(row.get("countryId", "")))
			if countryId == GameIds.EMPTY_ID:
				result.addError("Country meta upgrade %s has empty countryId." % upgradeId)
			elif not countryIds.has(countryId):
				result.addError("Country meta upgrade %s references unknown countryId: %s." % [upgradeId, countryId])
		elif row.has("countryId") and str(row.get("countryId", "")) != "":
			result.addError("General meta upgrade %s should not set countryId." % upgradeId)

	return result


static func _isNumeric(value: Variant) -> bool:
	var valueType := typeof(value)
	return valueType == TYPE_INT or valueType == TYPE_FLOAT
