# World Scenes

World scenes render the playable paper-style map without owning simulation rules.

- `WorldMap.tscn` owns map-only layers: countries, armies, effects, and the map camera.
- `MapPaperBackground` draws the baked parchment real-world map backing.
- `CountryNode.tscn` displays one playable country/region from one or more polygons.
- `ArmyNode.tscn` displays one army marker and emits selection input.
- `map_camera.gd` owns map navigation input: bounded pan and clamped zoom.

These scenes display state and forward input as commands. They do not calculate combat, economy, movement, ownership changes, or other gameplay rules.

`WorldMap` hit-tests pointer input against the country/region polygons. Right-clicking a player-owned target requests movement. Right-clicking a non-player-owned target requests an attack; core systems still validate the command.
