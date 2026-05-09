# Time Model

Phase 7 adds deterministic simulation time without economy, movement, combat, or final UI.

## Calendar

File: `res://src/core/model/game_time.gd`

`GameTime` uses the concept timing:

- 1 in-game week = 5 simulated seconds at 1x.
- 4 weeks = 1 month.
- 12 months = 1 year.

`RunState.time` remains a dictionary for save/load compatibility:

- `elapsedSeconds`
- `week`
- `month`
- `year`

## Simulation Tick

File: `res://src/core/simulation_manager.gd`

`SimulationManager` owns the fixed-step accumulator. Real frame delta is multiplied by the active game speed:

- paused = 0x
- normal = 1x
- fast = 2x
- very fast = 4x

The fixed step is `0.1` simulated seconds. This keeps rule updates deterministic and separate from visual frame rate.

## Month Tick

When four in-game weeks have elapsed, `SimulationManager` emits:

- local signal `monthTick(month, year, elapsedSeconds)`
- `EventType.MONTH_TICK` through `EventBus` when one is assigned

No resources, upkeep, threat, recruitment, movement, or combat are calculated in Phase 7.

## TimeControls Hook

`GameManager.setEventBus()` connects `EventBus.commandRequested` to `GameManager.submitCommand()`.
Future `TimeControls` can request `set_game_speed`; `GameManager` forwards valid speed changes to `SimulationManager`.

`Main.tscn` wires `EventBus`, `GameManager`, and `SimulationManager` so the main scene can run the prototype clock. In debug builds, event logging is enabled and speed is set to 4x so `monthTick` appears quickly in the Output panel.
