extends RefCounted
class_name GameIds


# Stable game IDs use StringName so UI, data, and simulation can share identifiers.
const EMPTY_ID: StringName = &""
const PLAYER_OWNER_ID: StringName = &"player"
const NEUTRAL_OWNER_ID: StringName = &"neutral"
const WORLD_OWNER_ID: StringName = &"world"

const INFANTRY_UNIT_ID: StringName = &"infantry"
const CAVALRY_UNIT_ID: StringName = &"cavalry"
const ARTILLERY_UNIT_ID: StringName = &"artillery"
