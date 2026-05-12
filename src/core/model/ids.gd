extends RefCounted
class_name GameIds


# Stable game IDs use StringName so UI, data, and simulation can share identifiers.
const EMPTY_ID: StringName = &""
const PLAYER_OWNER_ID: StringName = &"player"
const NEUTRAL_OWNER_ID: StringName = &"neutral"
const WORLD_OWNER_ID: StringName = &"world"
const NPC_OWNER_PREFIX: String = "npc_"

const INFANTRY_UNIT_ID: StringName = &"infantry"
const CAVALRY_UNIT_ID: StringName = &"cavalry"
const ARTILLERY_UNIT_ID: StringName = &"artillery"


static func npcOwnerIdForCountry(countryId: StringName) -> StringName:
	return StringName("%s%s" % [NPC_OWNER_PREFIX, str(countryId)])


static func isNpcOwnerId(ownerId: StringName) -> bool:
	return str(ownerId).begins_with(NPC_OWNER_PREFIX)
