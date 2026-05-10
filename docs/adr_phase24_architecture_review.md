# ADR: Phase 24 Architecture Review

## Status

Accepted.

## Context

Phase 24 is a vertical-slice gate. The goal is to verify that the current Godot structure still supports a playable MVP run without mixing UI, simulation, save, platform, or effects responsibilities.

## Review

- Simulation and gameplay rules remain under `res://src/core/`.
- Save/load and settings persistence remain under `res://src/save/`.
- Platform achievements remain behind `res://src/platform/PlatformService` and no GodotSteam dependency exists.
- UI scripts display projected state and send commands through `EventBus`.
- Effects/audio react to events and do not mutate gameplay state.
- Static balance/content remains in `res://data/` for countries, units, upgrades, mini goals, and meta upgrades.
- Export and Steam documentation remain in `res://docs/`.

## Decision

Keep the current architecture. Phase 24 does not require a scene redesign, framework change, Steam SDK integration, or new gameplay subsystem.

## Follow-Up

Before future feature work, resolve generated `.uid` file handling and the existing local `Main.tscn` workspace change so later diffs stay easier to review.
