# Main Scene

`Main.tscn` is the startup scene. It defines the stable root skeleton:

- `GameRoot` groups the playable run tree.
- `Managers` owns the core manager nodes wired during startup.
- `WorldRoot` is reserved for map and world visuals.
- `UIRoot` is reserved for Control-based UI scenes.

`main.gd` only bootstraps the Phase 7 manager graph: `EventBus`, `GameManager`, and `SimulationManager`. Gameplay rules remain in `res://src/core/`; no map rendering or UI systems live here yet.
