# Platform Service

Phase 22 adds a platform abstraction without adding Steam or GodotSteam.

## Scripts

- `src/platform/platform_service.gd`: base interface for platform capabilities.
- `src/platform/mock_platform_service.gd`: local mock used by the prototype and tests.
- `src/platform/achievement_event_map.gd`: maps gameplay events to achievement ids.
- `src/platform/platform_event_bridge.gd`: listens to `EventBus` game events and forwards mapped achievement unlocks to the active platform service.

Gameplay systems do not call Steam APIs directly. They raise normal game events; the platform layer reacts outside simulation rules.

## Current Achievements

- `achievement_first_conquest`
- `achievement_first_upgrade`
- `achievement_first_mini_goal`
- `achievement_first_meta_purchase`
- `achievement_run_won`

The ids are placeholders and can be aligned with Steamworks achievement API names later.
