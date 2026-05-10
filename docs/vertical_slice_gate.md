# Vertical Slice Gate

Phase 24 verifies the current MVP slice without adding new gameplay systems.

## Mini-Run Scope

The prototype slice currently contains:

- 12 countries in `data/countries.json`
- 3 unit types in `data/units.json`
- monthly gold/food economy
- army recruitment and movement
- attack, battle completion, conquest, and rewards
- upgrade choice after conquest
- manual save/load
- run win status when every country is player-owned

`DebugTestRunner` includes a vertical-slice gate test that runs recruitment, combat, movement, save/load, upgrades, and a full-map conquest path to `RunState.RUN_STATUS_WON`.

## Bugfix Freeze

No feature work was added in Phase 24. The only gameplay fix was completing the already-present run status contract: when the final hostile country is conquered, the run now transitions to `won`, pauses, and emits `runWon`.

Known non-blockers:

- The packaged Windows executable smoke test still depends on the missing Godot 4.6.2 export templates documented in `docs/export_packaging.md`.
- The quit-to-menu path remains an MVP stub from earlier phases.

## Balance Pass 1

No data changes were required for the first balance envelope.

Current checks:

- Starting army can beat an early neighboring country.
- Starting army cannot beat the late world country without reinforcements.
- Starting gold can afford early recruitment.
- Starting country produces positive gold and food income.

Future balance work should continue to change values in `data/*.json` or core constants, not UI scripts.
