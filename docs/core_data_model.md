# Core Data Model

Phase 3 defines the shared MVP data structures used by simulation and UI. These classes are pure data containers based on `RefCounted`; they must not reference scene nodes or own gameplay rules.

## Central Types

- `GameIds` - shared `StringName` IDs for owner and MVP unit identifiers.
- `OwnerType` - owner category enum.
- `GameSpeed` - paused, 1x, 2x, and 4x speed enum values.
- `GameTime` - deterministic calendar helper for weeks, months, and years.
- `ArmyStatus` - stationed, moving, attacking, defending, defeated.
- `BattleStatus` - pending, active, ended.
- `EventType` - shared event identifiers for Phase 3 game events.

## CountryData

File: `res://src/core/model/country_data.gd`

Fields:

- `id: StringName`
- `name: String`
- `ownerId: StringName`
- `goldPerMonth: int`
- `foodPerMonth: int`
- `defense: int`
- `center: Vector2`
- `neighbors: Array[StringName]`

This model supports future country fixtures. It does not import a full world map or validate neighbors yet.

## UnitData

File: `res://src/core/model/unit_data.gd`

Fields:

- `id: StringName`
- `name: String`
- `cost: int`
- `combatPower: int`
- `foodUpkeep: int`
- `moveSpeed: float`
- `bonuses: Dictionary`

`MvpUnitCatalog.createUnits()` can create the three MVP unit definitions:

- infantry
- cavalry
- artillery

No later-era unit types are included in Phase 3.

## ArmyData

File: `res://src/core/model/army_data.gd`

Fields:

- `id: StringName`
- `ownerId: StringName`
- `locationCountryId: StringName`
- `targetCountryId: StringName`
- `units: Dictionary`
- `status: int`
- `movementProgress: float`

`units` is a dictionary from unit ID to amount. Movement and combat logic are intentionally not implemented here.

## RunState

File: `res://src/core/model/run_state.gd`

Fields:

- `time: Dictionary`
- `speed: int`
- `resources: Dictionary`
- `countries: Dictionary`
- `armies: Dictionary`
- `battles: Dictionary`
- `activeUpgradeChoice: Dictionary`
- `miniGoals: Array[Dictionary]`
- `runStatus: StringName`

`RunState` is a runtime state container. Save serialization and migration are not part of Phase 3.

## GameEvent

File: `res://src/core/model/game_event.gd`

Fields:

- `type: StringName`
- `payload: Dictionary`
- `occurredAtSeconds: float`

Phase 3 event types:

- `countrySelected`
- `armyMoved`
- `battleStarted`
- `battleEnded`
- `countryConquered`
- `upgradeChoiceOpened`
- `missileLaunched`
- `runStarted`
- `runReset`
- `gameSpeedChanged`
- `monthTick`

Events are data only. Effects, audio, and UI may consume them later, but events do not trigger effects directly.

## Validation

Phase 4 adds validation scripts under `res://src/core/validation/` and a manual runner at `res://tests_debug/DebugTestRunner.tscn`.

Current validation checks:

- IDs are non-empty and unique.
- Country neighbors point to known countries.
- Country owners are in the provided owner list.
- Country centers are set to a non-zero finite coordinate.
- MVP units use known unit IDs.
- Unit costs, combat power, upkeep, and movement speed are valid.
- RunState resources are numeric and not NaN.
- RunState time has valid elapsed seconds, week, month, and year values.
- RunState speed is one of the supported speed values.
- Army locations and targets reference known countries.

Later validation can add stricter event type checks and fixture-file loading once static data files exist.
