# Paper Empire

Paper Empire is a desktop-first Steam strategy roguelike built with Godot 4 and GDScript.

The MVP is a fast world-conquest run on a simplified 2D world map. The player picks a country, builds armies, conquers whole countries, chooses one of three upgrades after each conquest, and manages rising global threat before the world response becomes overwhelming.

## Current Status

Phase 1 project foundation is in place:

- Godot project name: Paper Empire
- Main scene: `res://scenes/main/Main.tscn`
- Initial scene skeleton: `Main/GameRoot/Managers`, `Main/GameRoot/WorldRoot`, `Main/GameRoot/UIRoot`
- Base folders for scenes, source code, data, map, audio, effects, save/platform boundaries, debug checks, and docs

No gameplay, map, UI systems, managers, save logic, or Steam integration are implemented yet.

## Opening The Project

1. Open this folder in Godot 4.x. The project metadata currently targets Godot 4.6 features.
2. Open or run `res://scenes/main/Main.tscn`.
3. Confirm the Output panel has no parser or import errors.

Optional command-line smoke check, if the Godot executable is on PATH:

```powershell
godot --headless --path . --quit
```

## Codex Workflow

- Work one step at a time from the plan.
- Keep simulation/gameplay logic under `res://src/core/`.
- Keep save/load code under `res://src/save/`.
- UI scenes display state and call commands, but do not own combat, economy, movement, or threat rules.
- Steam-specific behavior must stay behind a PlatformService abstraction and is not part of the MVP foundation.

## MVP Non-Goals

- No web, Electron, React, browser, or mobile version.
- No C# or .NET dependencies.
- No multiplayer.
- No diplomacy, marine, trade, stability, provinces, research, or age-system work in the first MVP foundation.
- No GodotSteam dependency until explicitly requested.
