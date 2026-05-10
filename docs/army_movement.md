# Army Movement

Phase 12 adds the first army placement and movement loop. The implementation is still map-edge based and deterministic; there is no pathfinding, battle resolution, split/merge, or physics.

## Starting Army

`NewRunFactory` creates `army_start` in the chosen start country. The MVP army contains:

- Infantry
- Cavalry
- Artillery

The selected army defaults to the first army in the active run so the left UI panel can show useful state immediately.

## Movement Rules

File: `res://src/core/simulation/army_movement_simulation.gd`

`ArmyMovementSimulation.requestMove()` accepts only adjacent country moves:

- The army must exist.
- The target country must exist.
- The army must be stationed.
- The target must be listed as a neighbor of the current country.

Accepted moves set `ArmyData.status` to `Moving`, assign `targetCountryId`, and reset `movementProgress`.

`ArmyMovementSimulation.advanceMovement()` advances progress by fixed simulation time. On completion it updates `locationCountryId`, clears `targetCountryId`, restores `Stationed`, and returns an `armyMoved` payload.

## Commands And Events

New commands:

- `select_army`
- `move_army`

New events:

- `armySelected`
- `armyMoveStarted`

Existing event:

- `armyMoved`

`GameManager` handles selection and move commands. `SimulationManager` advances active movement during fixed steps, so movement respects pause and game speed.

## Map And UI

`WorldMap` renders one `ArmyNode` per army on `ArmyLayer`. A moving army lerps between the source and target country centers using `movementProgress`.

Interaction:

- Left-click an army to select it.
- Right-click a neighboring country to move the selected army there.

`LeftPanel` now uses `army_panel.gd` to show selected army status, location, target, and unit counts. It displays prepared data from `RunStateView`; UI scripts do not own movement rules.
