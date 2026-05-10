# Project Structure

This document records the Phase 1 folder layout. It is intentionally light: the folders exist so later steps have stable places to add scenes, data, and typed GDScript without reshaping the repository.

## Scene Folders

- `res://scenes/main/` - Main entry scenes. `Main.tscn` is the configured run scene.
- `res://scenes/managers/` - Future manager scenes, if a step explicitly adds them.
- `res://scenes/world/` - Map, country, army-node, army-layer, and world visual scenes.
- `res://scenes/ui/` - Godot Control-based UI scripts for HUD panels and menu stubs.
- `res://scenes/effects/` - Future visual effect scenes that react to events but do not own rules.

## Source And Data

- `res://src/core/` - Canonical home for game simulation and domain logic.
- `res://src/core/simulation/` - Rule modules such as economy, movement, recruitment, combat, and future systems.
- `res://src/core/view/` - Core-side display data builders used by UI scenes.
- `res://src/save/` - Save/load implementation. Runtime saves should use `user://`.
- `res://src/platform/` - Desktop/Steam abstraction layer. No GodotSteam dependency in Phase 1.
- `res://scripts/` - Reserved for small Godot/editor helper scripts if needed later. Gameplay rules belong in `src/core`.
- `res://data/` - Static prototype data such as countries, units, upgrades, and mini-goals.

## Assets And Support

- `res://map/` - Map source assets or prototypes.
- `res://audio/` - Music, SFX, and UI audio assets.
- `res://effects/` - Shared effect assets or resources.
- `res://ui/` - Shared UI assets or early UI references.
- `res://save/` - Save schemas or fixtures only; runtime saves use `user://`.
- `res://platform/` - Platform notes/assets only; source code belongs in `src/platform`.
- `res://tests_debug/` - Manual debug scenes, smoke checks, or small test fixtures.
- `res://docs/` - Project documentation.
