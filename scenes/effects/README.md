# Effects Scenes

Phase 18 visual effects live here. `EffectsLayer` listens to `GameEvent`s and creates map-only feedback for movement, battles, conquest, missiles, and explosions.

Effects scenes must not change `RunState`, resources, ownership, combat, economy, movement, threat, or mini-goal progress.
