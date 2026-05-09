# World Scenes

Phase 8 introduces the prototype map scene graph.

- `WorldMap.tscn` owns map-only layers: countries, armies, effects, and the map camera.
- `CountryNode.tscn` displays one simplified prototype country shape and emits hover/click signals.
- `map_camera.gd` owns map navigation input: bounded pan and clamped zoom.

These scenes display state and forward input as commands. They do not calculate combat, economy, movement, ownership changes, or other gameplay rules.
