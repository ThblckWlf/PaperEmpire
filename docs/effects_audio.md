# Effects And Audio

Phase 18 adds event-driven visual and sound feedback without changing gameplay rules.

## Effects

`res://scenes/world/WorldMap.tscn` owns an `EffectsLayer` with separate child layers for movement, battle, and one-shot feedback. `EffectsLayer` listens to `EventBus.gameEventRaised` and creates:

- movement path lines and a pulsing marker for moving armies
- battle pulse overlays for active battles
- conquest flash overlays
- symbolic missile flight tweens
- explosion flash and particles on missile impact

The layer reads country centers and army movement state only to display feedback. It does not change ownership, resources, armies, battles, threat, upgrades, or goals.

## Audio

`AudioManager` creates and uses the `Master`, `Music`, `SFX`, and `UI` buses. Phase 18 uses generated placeholder tone streams instead of final assets.

Connected stubs:

- command requests: UI click tone
- `battleStarted`: battle tone
- `countryConquered`: conquest tone
- `missileLaunched`: missile tone
- missile impact: explosion tone through the EffectsLayer impact callback
