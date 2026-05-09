extends RefCounted
class_name ArmyData


var id: StringName = GameIds.EMPTY_ID
var ownerId: StringName = GameIds.EMPTY_ID
var locationCountryId: StringName = GameIds.EMPTY_ID
var targetCountryId: StringName = GameIds.EMPTY_ID
var units: Dictionary = {}
var status: int = ArmyStatus.Value.Stationed
var movementProgress: float = 0.0
