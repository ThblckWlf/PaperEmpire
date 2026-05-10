extends Node
class_name PlatformService


signal achievementUnlocked(achievementId: StringName)


func initialize() -> bool:
	return true


func isAvailable() -> bool:
	return false


func getServiceName() -> String:
	return "platform"


func unlockAchievement(_achievementId: StringName) -> bool:
	return false


func setStat(_statId: StringName, _value: int) -> bool:
	return false


func storeStats() -> bool:
	return false
