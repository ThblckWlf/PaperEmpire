# Main Scene

`Main.tscn` is the startup scene. It defines the stable root skeleton:

- `GameRoot` groups the playable run tree.
- `Managers` owns the core manager nodes wired during startup.
- `WorldRoot` owns `WorldMap`, the Phase 8 prototype map scene.
- `UIRoot` owns the Phase 10 HUD layout and modal layer.

`main.gd` bootstraps the manager graph and passes `GameManager`/`EventBus` to `WorldMap` and `UIRoot`. Gameplay rules remain in `res://src/core/`; map and UI scenes only display state and forward input as commands.
