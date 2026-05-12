# Map Scene

Phase 8 adds the first prototype map rendering path. Phase 9 adds camera controls. The map remains limited to scene structure, input forwarding, and visual state.

## WorldMap

File: `res://scenes/world/WorldMap.tscn`

Nodes:

- `CountryLayer`
- `ArmyLayer`
- `EffectsLayer`
- `MapPaperBackground`
- `MapCamera`

`WorldMap` receives `GameManager` and `EventBus` from `Main.tscn`, creates one `CountryNode` per playable country/region, and listens for selection events. It does not own gameplay rules.

`MapCamera` has a controller script for:

- Start zoom.
- Bounds based on the real-world country/region shapes.
- WASD/arrow pan through registered InputMap actions.
- Right- or middle-mouse drag pan.
- Mouse-wheel zoom through registered InputMap actions with min/max clamps.

## CountryNode

File: `res://scenes/world/CountryNode.tscn`

Nodes:

- hidden template nodes for fill, outline, label, and collision setup
- generated fill and outline nodes for each country/region polygon

`CountryNode` displays one playable country/region as one or more polygons and updates hover/selection visuals. Normal borders come from the baked parchment map; `WorldMap` handles exact polygon hit-testing for click input.

## ArmyNode

File: `res://scenes/world/ArmyNode.tscn`

`ArmyNode` displays a compact marker at the army's current map position. For moving armies it interpolates between source and target country centers from `ArmyData.movementProgress`.

It emits selection input only. Movement rules stay in `ArmyMovementSimulation`.

## Input Flow

Map clicks follow the command boundary:

1. `WorldMap` hit-tests the cursor against country/region polygons.
2. `WorldMap` calls `EventBus.requestCommand(CommandType.SELECT_COUNTRY, payload)`.
3. `GameManager` handles the command and emits `countrySelected`.
4. `WorldMap` updates visual selection from the event.

No combat, movement, economy, or ownership changes are triggered by map clicks in Phase 8.

Pointer input checks `Viewport.gui_get_hovered_control()` before emitting map commands so UI controls can consume pointer events first.

Phase 12 adds army movement input:

1. Left-click an `ArmyNode` to request `select_army`.
2. Right-click a player-owned country/region to request `move_army` for the selected army.
3. Right-click a non-player-owned country/region to request `start_attack` for the selected army.
4. `GameManager` validates through core rules and emits movement or battle events.
5. `WorldMap` updates country owners and army positions from `RunState`.

## Country Shapes

File: `res://data/mapShapes.json`

The fixture contains local polygon arrays for the playable real-world map. Some small countries are grouped under a region id, and islands or separated landmasses use multiple polygons under the same id.
