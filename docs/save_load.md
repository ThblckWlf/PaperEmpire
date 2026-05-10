# Save And Load

Phase 19.1 defines the first versioned save schema. Runtime file IO and RunState serialization are added in later Phase 19 steps.

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
