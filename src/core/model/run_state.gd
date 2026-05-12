extends RefCounted
class_name RunState


const RUN_STATUS_NOT_STARTED: StringName = &"notStarted"
const RUN_STATUS_ACTIVE: StringName = &"active"
const RUN_STATUS_WON: StringName = &"won"
const RUN_STATUS_LOST: StringName = &"lost"

var time: Dictionary = {
	"elapsedSeconds": 0.0,
	"week": 1,
	"month": 1,
	"year": 1,
}
var speed: int = GameSpeed.Value.Normal
var resources: Dictionary = {
	"gold": 0,
	"food": 0,
	"threat": 0,
}
var worldReaction: Dictionary = {
	"level": "calm",
	"enemyStrengthMultiplier": 1.0,
	"counterAttackPrepared": false,
	"lastThreat": 0,
}
var economy: Dictionary = {
	"isFoodShortage": false,
	"foodShortageMonths": 0,
	"recruitmentBlocked": false,
	"healingBlocked": false,
	"combatPowerMultiplier": 1.0,
	"lastMonthResult": {},
}
var countries: Dictionary = {}
var armies: Dictionary = {}
var battles: Dictionary = {}
var aiGoldByCountry: Dictionary = {}
var activeUpgradeChoice: Dictionary = {}
var upgrades: Array[StringName] = []
var upgradeEffects: Dictionary = {
	"recruitmentCostMultiplier": 1.0,
	"foodUpkeepMultiplier": 1.0,
	"conquestGoldMultiplier": 1.0,
	"warThreatMultiplier": 1.0,
	"defenseCombatMultiplier": 1.0,
}
var miniGoalState: Dictionary = {
	"upgradeRarityBoost": 0,
}
var miniGoals: Array[Dictionary] = []
var runStats: Dictionary = {
	"countriesConquered": 0,
	"maxCountriesOwned": 0,
	"monthsSurvived": 0,
	"miniGoalsCompleted": 0,
	"battlesWon": 0,
	"battlesLost": 0,
	"highestThreatReached": 0.0,
	"crownsAwarded": false,
}
var runStatus: StringName = RUN_STATUS_NOT_STARTED
