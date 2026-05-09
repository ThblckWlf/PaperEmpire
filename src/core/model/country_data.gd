extends RefCounted
class_name CountryData


var id: StringName = GameIds.EMPTY_ID
var name: String = ""
var ownerId: StringName = GameIds.NEUTRAL_OWNER_ID
var goldPerMonth: int = 0
var foodPerMonth: int = 0
var defense: int = 0
var center: Vector2 = Vector2.ZERO
var neighbors: Array[StringName] = []
