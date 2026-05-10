# Steam Build Notes

Phase 22 does not integrate Steamworks or GodotSteam.

Before a Steam build, verify:

- Steam app id and depot ids are defined outside the repo or in release-only config.
- The game starts without Steam running by falling back to `MockPlatformService`.
- Achievement ids in `achievement_event_map.gd` match Steamworks backend ids.
- Save/settings paths remain under `user://paper_empire/`.
- Steam Cloud decisions are handled separately from local save schema migration.
- Build exports do not include debug-only test scenes unless intentionally packaged.

The current platform seam is `PlatformService`; future Steam work should implement that interface instead of letting gameplay or UI scripts call Steam APIs directly.
