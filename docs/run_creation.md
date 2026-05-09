# Run Creation And Commands

Phase 6 adds the first controlled way to create and modify a run state. This is still core-only work: there is no UI, no map interaction, no economy tick, and no combat.

## NewRunFactory

File: `res://src/core/new_run_factory.gd`

`NewRunFactory.createNewRun(startCountryId: StringName)` builds a `RunState` from prototype fixtures:

- Loads countries from `res://data/countries.json`.
- Sets the selected start country owner to `player`.
- Resets any previous fixture player-owned country to `neutral`.
- Sets starting resources.
- Adds a starting army at the start country.
- Loads prototype mini-goals.
- Marks the run as `active` when the start country exists.

The phase plan calls this `create_new_run`; the project uses `createNewRun` to stay consistent with the GDScript naming rules in `AGENTS.md`.

## GameManager

File: `res://src/core/game_manager.gd`

`GameManager` now owns the current `RunState` and selected country ID. Access should go through:

- `startNewRun(startCountryId: String)`
- `resetRun(startCountryId: StringName = GameIds.EMPTY_ID)`
- `submitCommand(commandName: StringName, payload: Dictionary = {})`
- `getCurrentRunState() -> RunState`
- `hasActiveRun() -> bool`
- `getSelectedCountryId() -> StringName`

## Command Skeleton

Supported Phase 6 commands:

- `select_country`
- `set_game_speed`
- `pause_game`
- `resume_game`
- `reset_run`

No combat, recruitment, economy, movement, save, or UI commands are implemented in Phase 6.

## Events

When an `EventBus` is assigned through `setEventBus()`, `GameManager` emits:

- `runStarted`
- `countrySelected`
- `gameSpeedChanged`
- `runReset`

`EventBus.logGameEvents` can be enabled to print events to the Output panel.

## Debug Checks

`res://tests_debug/DebugTestRunner.tscn` validates:

- New run creation from prototype content.
- Controlled command updates.
- Expected event emission.
