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
