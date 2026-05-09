extends RefCounted
class_name MvpUnitCatalog


static func createUnits() -> Array[UnitData]:
	var units: Array[UnitData] = []
	units.append(_createUnit(GameIds.INFANTRY_UNIT_ID, "Infantry", 50, 10, 1, 1.0))
	units.append(_createUnit(GameIds.CAVALRY_UNIT_ID, "Cavalry", 90, 18, 2, 1.35))
	units.append(_createUnit(GameIds.ARTILLERY_UNIT_ID, "Artillery", 140, 32, 3, 0.75))
	return units


static func _createUnit(
	unitId: StringName,
	unitName: String,
	cost: int,
	combatPower: int,
	foodUpkeep: int,
	moveSpeed: float
) -> UnitData:
	var data := UnitData.new()
	data.id = unitId
	data.name = unitName
	data.cost = cost
	data.combatPower = combatPower
	data.foodUpkeep = foodUpkeep
	data.moveSpeed = moveSpeed
	return data
