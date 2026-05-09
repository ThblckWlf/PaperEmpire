# Prototype Content

Phase 5 adds small JSON fixtures for manual testing and future prototype scenes. These are not final balance data and do not represent the full world map.

## Files

- `res://data/units.json` - exactly three MVP units: infantry, cavalry, artillery.
- `res://data/countries.json` - 12 test countries with owners, income, defense, center points, and bidirectional neighbors.
- `res://data/upgrades.json` - 10 passive run upgrades.
- `res://data/miniGoals.json` - 6 simple mini-goals.

## Loader

`res://src/core/content/prototype_content_loader.gd` loads the JSON fixtures:

- `loadUnits() -> Array[UnitData]`
- `loadCountries() -> Array[CountryData]`
- `loadUpgrades() -> Array[Dictionary]`
- `loadMiniGoals() -> Array[Dictionary]`

The loader is intentionally narrow and only supports the current prototype files.

## Validation

The debug runner validates prototype content through:

- `CountryDataValidator`
- `UnitDataValidator`
- `UpgradeDataValidator`
- `MiniGoalDataValidator`

Run `res://tests_debug/DebugTestRunner.tscn` and check the Output panel for PASS/FAIL lines.

## Current Limits

- No real world map import.
- No pathfinding.
- No gameplay simulation.
- No upgrade rolling logic.
- No mini-goal completion logic.
- No active abilities.
