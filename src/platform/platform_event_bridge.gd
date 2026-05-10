extends Node
class_name PlatformEventBridge


const ACHIEVEMENT_EVENT_MAP := preload("res://src/platform/achievement_event_map.gd")

var eventBus: EventBus
var platformService


func configure(newEventBus: EventBus, newPlatformService) -> void:
	_disconnectEventBus()
	eventBus = newEventBus
	platformService = newPlatformService
	_connectEventBus()


func _exit_tree() -> void:
	_disconnectEventBus()


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	if platformService == null or not platformService.has_method("unlockAchievement"):
		return
	if platformService.has_method("isAvailable") and not bool(platformService.call("isAvailable")):
		return

	for achievementId in ACHIEVEMENT_EVENT_MAP.achievementsForEvent(eventName, payload):
		platformService.call("unlockAchievement", achievementId)


func _connectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)


func _disconnectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)
