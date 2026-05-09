# Main Scene

`Main.tscn` is the startup scene. It defines the stable root skeleton:

- `GameRoot` groups the playable run tree.
- `Managers` owns the core manager nodes wired during startup.
- `WorldRoot` owns `WorldMap`, the Phase 8 prototype map scene.
- `UIRoot` is reserved for Control-based UI scenes.

`main.gd` bootstraps the manager graph and passes `GameManager`/`EventBus` to `WorldMap`. Gameplay rules remain in `res://src/core/`; map scenes only display state and forward input as commands.
