# Prototype Content

Phase 5 started with small JSON fixtures. The current content files now hold the playable real-world region map used by the prototype.

## Files

- `res://data/units.json` - exactly three MVP units: infantry, cavalry, artillery.
- `res://data/countries.json` - real countries and grouped regions with owners, income, defense, center points, and bidirectional neighbors.
- `res://data/upgrades.json` - 10 passive run upgrades using the Phase 15 supported effect types.
- `res://data/miniGoals.json` - 6 simple mini-goals with progress rules and rewards.
- `res://data/mapShapes.json` - local polygon arrays for the playable real-world region map.

## Loader

`res://src/core/content/prototype_content_loader.gd` loads the JSON fixtures:

- `loadUnits() -> Array[UnitData]`
- `loadCountries() -> Array[CountryData]`
- `loadUpgrades() -> Array[Dictionary]`
- `loadMiniGoals() -> Array[Dictionary]`
- `loadMapShapes() -> Dictionary`

The loader is intentionally narrow and only supports the current prototype files.

## Validation

The debug runner validates prototype content through:

- `CountryDataValidator`
- `UnitDataValidator`
- `UpgradeDataValidator`
- `MiniGoalDataValidator`
- Map-shape fixture checks in `DebugTestRunner`

Run `res://tests_debug/DebugTestRunner.tscn` and check the Output panel for PASS/FAIL lines.

## Current Limits

- The current world map uses 127 playable countries/regions. Small areas such as the Caribbean are intentionally grouped for readability and click targets.
- No pathfinding.
- Gameplay simulation exists for economy, movement, recruitment, combat, and passive upgrades.
- Mini-goal completion and one-time reward claiming exist for the prototype goals.
- No active abilities.
