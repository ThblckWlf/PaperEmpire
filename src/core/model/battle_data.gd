extends RefCounted
class_name BattleData


var id: StringName = GameIds.EMPTY_ID
var attackerArmyId: StringName = GameIds.EMPTY_ID
var attackerOwnerId: StringName = GameIds.EMPTY_ID
var defenderOwnerId: StringName = GameIds.EMPTY_ID
var attackerArmyIds: Array[StringName] = []
var defenderArmyIds: Array[StringName] = []
var sourceCountryId: StringName = GameIds.EMPTY_ID
var targetCountryId: StringName = GameIds.EMPTY_ID
var status: int = BattleStatus.Value.Pending
var elapsedSeconds: float = 0.0
var durationSeconds: float = 0.0
var attackerPower: float = 0.0
var defenderPower: float = 0.0
var attackerWon: bool = false
var winnerOwnerId: StringName = GameIds.EMPTY_ID
var casualties: Dictionary = {}
