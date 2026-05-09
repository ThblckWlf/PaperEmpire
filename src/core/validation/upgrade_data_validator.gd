extends RefCounted
class_name UpgradeDataValidator


static func validate(upgrades: Array[Dictionary]) -> ValidationResult:
	var result := ValidationResult.new()
	var knownIds: Dictionary = {}
	var allowedRarities := {
		"common": true,
		"uncommon": true,
		"rare": true,
	}

	if upgrades.size() < 8 or upgrades.size() > 12:
		result.addError("Upgrade fixture should contain 8-12 upgrades, found %d." % upgrades.size())

	for upgrade in upgrades:
		var id := str(upgrade.get("id", ""))
		if id.is_empty():
			result.addError("Upgrade has empty id.")
		elif knownIds.has(id):
			result.addError("Duplicate upgrade id: %s." % id)
		else:
			knownIds[id] = true

		if str(upgrade.get("name", "")).is_empty():
			result.addError("Upgrade %s has empty name." % id)

		if str(upgrade.get("description", "")).is_empty():
			result.addError("Upgrade %s has empty description." % id)

		if not allowedRarities.has(str(upgrade.get("rarity", ""))):
			result.addError("Upgrade %s has invalid rarity." % id)

		if str(upgrade.get("effectType", "")).is_empty():
			result.addError("Upgrade %s has empty effectType." % id)

		var value = upgrade.get("value", null)
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			result.addError("Upgrade %s value is not numeric." % id)
		elif float(value) <= 0.0 or is_nan(float(value)):
			result.addError("Upgrade %s value must be positive." % id)

		if upgrade.has("activeAbility"):
			result.addError("Upgrade %s defines activeAbility, which is not MVP content." % id)

	return result
