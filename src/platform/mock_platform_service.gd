extends "res://src/platform/platform_service.gd"
class_name MockPlatformService


var unlockedAchievements: Dictionary = {}
var stats: Dictionary = {}
var initialized: bool = false


func initialize() -> bool:
	initialized = true
	return true


func isAvailable() -> bool:
	return initialized


func getServiceName() -> String:
	return "mock"


func unlockAchievement(achievementId: StringName) -> bool:
	if achievementId == GameIds.EMPTY_ID:
		return false

	unlockedAchievements[achievementId] = true
	achievementUnlocked.emit(achievementId)
	return true


func setStat(statId: StringName, value: int) -> bool:
	if statId == GameIds.EMPTY_ID:
		return false

	stats[statId] = value
	return true


func storeStats() -> bool:
	return true


func hasUnlockedAchievement(achievementId: StringName) -> bool:
	return unlockedAchievements.has(achievementId)


func getStat(statId: StringName) -> int:
	return int(stats.get(statId, 0))
