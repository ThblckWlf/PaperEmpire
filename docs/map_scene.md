# Map Scene

Phase 8 adds the first prototype map rendering path. Phase 9 adds camera controls. The map remains limited to scene structure, input forwarding, and visual state.

## WorldMap

File: `res://scenes/world/WorldMap.tscn`

Nodes:

- `CountryLayer`
- `ArmyLayer`
- `EffectsLayer`
- `MapCamera`

`WorldMap` receives `GameManager` and `EventBus` from `Main.tscn`, creates one `CountryNode` per `CountryData`, and listens for selection events. It does not own gameplay rules.

`MapCamera` has a controller script for:

- Start zoom.
- Bounds based on prototype country shapes.
- WASD/arrow pan.
- Right- or middle-mouse drag pan.
- Mouse-wheel zoom with min/max clamps.

## CountryNode

File: `res://scenes/world/CountryNode.tscn`

Nodes:

- `Polygon2D`
- `Outline`
- `Area2D`
- `CollisionPolygon2D`

`CountryNode` displays a simplified polygon, updates hover/selection visuals, and emits click/hover signals.

## Input Flow

Country clicks follow the command boundary:

1. `CountryNode` emits `countryPressed(countryId)`.
2. `WorldMap` calls `EventBus.requestCommand(CommandType.SELECT_COUNTRY, payload)`.
3. `GameManager` handles the command and emits `countrySelected`.
4. `WorldMap` updates visual selection from the event.

No combat, movement, economy, or ownership changes are triggered by map clicks in Phase 8.

Camera input uses `_unhandled_input()` so UI controls can consume pointer events first. `CountryNode` also checks `Viewport.gui_get_hovered_control()` before emitting country commands.

## Prototype Shapes

File: `res://data/mapShapes.json`

The fixture contains local polygon points for the 12 prototype countries. These are simple non-overlapping shapes for visibility and input testing, not a real world map.
