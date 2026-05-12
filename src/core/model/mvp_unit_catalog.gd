extends RefCounted
class_name MvpUnitCatalog


static func createUnits() -> Array[UnitData]:
	var units: Array[UnitData] = []
	units.append(_createUnit(GameIds.INFANTRY_UNIT_ID, "Infanterie", 10, 10, 1, 1.0, {
		"counterBonusVs": str(GameIds.CAVALRY_UNIT_ID),
		"counterBonusMultiplier": 1.3,
	}))
	units.append(_createUnit(GameIds.CAVALRY_UNIT_ID, "Kavallerie", 25, 18, 2, 1.35, {
		"counterBonusVs": str(GameIds.ARTILLERY_UNIT_ID),
		"counterBonusMultiplier": 1.35,
	}))
	units.append(_createUnit(GameIds.ARTILLERY_UNIT_ID, "Artillerie", 45, 28, 3, 0.75, {
		"counterBonusVs": str(GameIds.INFANTRY_UNIT_ID),
		"counterBonusMultiplier": 1.3,
		"defenseDamageMultiplier": 1.5,
		"supportInfantryPerArtillery": 2,
		"unsupportedCombatMultiplier": 0.5,
	}))
	return units


static func _createUnit(
	unitId: StringName,
	unitName: String,
	cost: int,
	combatPower: int,
	foodUpkeep: int,
	moveSpeed: float,
	bonuses: Dictionary = {}
) -> UnitData:
	var data := UnitData.new()
	data.id = unitId
	data.name = unitName
	data.cost = cost
	data.combatPower = combatPower
	data.foodUpkeep = foodUpkeep
	data.moveSpeed = moveSpeed
	data.bonuses = bonuses.duplicate(true)
	return data
