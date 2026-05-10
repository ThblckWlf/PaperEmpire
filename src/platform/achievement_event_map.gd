extends RefCounted
class_name AchievementEventMap


const ACHIEVEMENT_FIRST_CONQUEST: StringName = &"achievement_first_conquest"
const ACHIEVEMENT_FIRST_UPGRADE: StringName = &"achievement_first_upgrade"
const ACHIEVEMENT_FIRST_MINI_GOAL: StringName = &"achievement_first_mini_goal"
const ACHIEVEMENT_FIRST_META_PURCHASE: StringName = &"achievement_first_meta_purchase"
const ACHIEVEMENT_RUN_WON: StringName = &"achievement_run_won"


static func achievementsForEvent(eventName: StringName, payload: Dictionary = {}) -> Array[StringName]:
	var achievements: Array[StringName] = []
	match eventName:
		EventType.COUNTRY_CONQUERED:
			achievements.append(ACHIEVEMENT_FIRST_CONQUEST)
		EventType.UPGRADE_CHOSEN:
			achievements.append(ACHIEVEMENT_FIRST_UPGRADE)
		EventType.MINI_GOAL_REWARD_CLAIMED:
			achievements.append(ACHIEVEMENT_FIRST_MINI_GOAL)
		EventType.META_UPGRADE_PURCHASED:
			achievements.append(ACHIEVEMENT_FIRST_META_PURCHASE)
		EventType.RUN_WON:
			achievements.append(ACHIEVEMENT_RUN_WON)
		EventType.CROWNS_REWARDED:
			if str(payload.get("runStatus", "")) == RunState.RUN_STATUS_WON:
				achievements.append(ACHIEVEMENT_RUN_WON)
	return achievements
