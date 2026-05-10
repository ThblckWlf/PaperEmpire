# Save And Load

Phase 19 defines the first versioned save schema, run serialization, and local file persistence.

## Save Root

Every save root contains:

- `schemaVersion`: current save schema version
- `gameVersion`: project game version string
- `createdAt`: UTC timestamp string
- `runState`: serialized run data
- `metaProgress`: serialized meta progression

## Meta Progress

`MetaProgress` is a small data container for future post-run progression:

- `crowns`
- `generalUpgrades`
- `countryUpgrades`

No Steam Cloud, binary saves, shop logic, or file persistence is part of this step.

## Run Serialization

Phase 19.2 adds `RunStateSerializer.serializeRunState()`. It converts the current run into JSON-compatible dictionaries, arrays, strings, bools, ints, and floats.

The serializer explicitly converts:

- `StringName` IDs to strings
- `Vector2` country centers to `{ "x": ..., "y": ... }`
- `CountryData`, `ArmyData`, and battle objects to plain dictionaries

It does not write files, read files, migrate old saves, or restore a `RunState`.

## Local Save Files

Phase 19.3 adds `SaveManager` file IO under `user://paper_empire/`.

`SaveManager.saveGame(slotId, root)` writes only validated save roots. `loadGame(slotId)` returns a validated dictionary or `{}`. Slot IDs are sanitized into JSON filenames, and no project-folder save files or Steam Cloud calls are used.

## Manual Save/Load

Phase 19.4 adds `save_game` and `load_game` commands plus Save/Load buttons in the ESC menu. The MVP manual slot is `manual_1`.

Loading reconstructs a `RunState` from serialized data, validates it, reconnects the `SimulationManager`, and refreshes map/UI through the existing `runReset` event. The UI only sends commands; save file logic remains in `res://src/save/`.
