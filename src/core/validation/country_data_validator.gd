extends RefCounted
class_name CountryDataValidator


static func validate(countries: Array[CountryData], validOwnerIds: Array[StringName]) -> ValidationResult:
	var result := ValidationResult.new()
	var knownIds: Dictionary = {}
	var countryById: Dictionary = {}

	for country in countries:
		if country.id == GameIds.EMPTY_ID:
			result.addError("Country has empty id.")
			continue

		if knownIds.has(country.id):
			result.addError("Duplicate country id: %s." % country.id)
		else:
			knownIds[country.id] = true
			countryById[country.id] = country

		if country.name.is_empty():
			result.addError("Country %s has empty name." % country.id)

		if not validOwnerIds.has(country.ownerId):
			result.addError("Country %s has invalid ownerId: %s." % [country.id, country.ownerId])

		if country.goldPerMonth < 0:
			result.addError("Country %s has negative goldPerMonth." % country.id)

		if country.foodPerMonth < 0:
			result.addError("Country %s has negative foodPerMonth." % country.id)

		if country.defense < 0:
			result.addError("Country %s has negative defense." % country.id)

		if country.center == Vector2.ZERO or is_nan(country.center.x) or is_nan(country.center.y):
			result.addError("Country %s has missing or invalid center." % country.id)

	for country in countries:
		for neighborId in country.neighbors:
			if neighborId == country.id:
				result.addError("Country %s lists itself as a neighbor." % country.id)
			elif not knownIds.has(neighborId):
				result.addError("Country %s has unknown neighbor: %s." % [country.id, neighborId])
			else:
				var neighbor := countryById[neighborId] as CountryData
				if not neighbor.neighbors.has(country.id):
					result.addError("Country %s neighbor %s is not bidirectional." % [country.id, neighborId])

	return result
