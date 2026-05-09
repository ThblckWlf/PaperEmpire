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
var countries: Dictionary = {}
var armies: Dictionary = {}
var battles: Dictionary = {}
var activeUpgradeChoice: Dictionary = {}
var miniGoals: Array[Dictionary] = []
var runStatus: StringName = RUN_STATUS_NOT_STARTED
