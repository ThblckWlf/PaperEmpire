# Coding And Scene Standards

These standards apply to Paper Empire's Godot 4 project. They are intentionally narrow so later implementation steps can stay consistent without locking the project into unnecessary abstractions.

## Canonical Source Paths

`res://src/` is the canonical source root for project code.

- `res://src/core/` - simulation, domain models, commands, and gameplay rules.
- `res://src/save/` - save/load code and save schema handling.
- `res://src/platform/` - desktop and future Steam abstraction code.
- `res://scripts/` - reserved for small editor or helper scripts only. Do not put gameplay rules here.

If an older plan mentions `res://scripts/core/`, treat `res://src/core/` as the current project rule because AGENTS.md defines it as the active architecture boundary.

## Files And Folders

- Folder names use `lower_snake_case` or existing simple lowercase names.
- GDScript files use `lower_snake_case.gd`.
- Scene files use `PascalCase.tscn` when they represent a reusable scene or screen.
- Data files use `lowerCamelCase.json` when they represent game datasets, for example `miniGoals.json`.
- Documentation files use `lower_snake_case.md`, except root-level `README.md` and `AGENTS.md`.
- Keep runtime saves out of the repository. Runtime save files belong under `user://`.

## Nodes And Scenes

- Root node names use `PascalCase`, for example `Main`, `GameRoot`, `WorldRoot`.
- Important child nodes use `PascalCase` when they represent stable scene responsibilities.
- UI Control nodes may use descriptive names such as `CountryPanel`, `TimeControls`, or `UpgradeModal`.
- Do not rename existing nodes unless a step explicitly requires it.
- Avoid fragile cross-scene node paths. Prefer exported `NodePath`, signals, or parent-scoped references.
- Every important scene should have a short README or script header describing its role.

## GDScript Naming

- Use typed GDScript where practical for variables, parameters, and return values.
- Custom variables and functions use `lowerCamelCase`.
- Godot lifecycle methods keep their required names: `_ready`, `_process`, `_physics_process`, `_unhandled_input`.
- `class_name` values use `PascalCase`.
- Constants use `UPPER_SNAKE_CASE`.
- Enum names use `PascalCase`; enum values use `PascalCase` unless a Godot API requires a different style.
- Private helper functions may use a leading underscore plus lowerCamelCase, for example `_buildCommandPayload()`.

## Signals

- Custom signal names use `lowerCamelCase`, for example `countrySelected` or `commandRequested`.
- Signal payload parameters use typed `lowerCamelCase` names.
- UI signals request actions or selection changes; they do not calculate combat, economy, movement, or threat.
- Simulation events should be represented as game events and consumed by UI, audio, or effects in later steps.

## Architecture Boundaries

- Simulation and gameplay rules belong under `res://src/core/`.
- UI scenes display state and call commands or services.
- Effects may animate game events but must not modify gameplay state.
- Save/load logic belongs under `res://src/save/`.
- Platform and Steam-specific behavior belongs behind `res://src/platform/` abstractions.
- Do not add GodotSteam, C#, .NET, web, Electron, React, or mobile architecture unless explicitly requested.

## Scene Editing Rules

- Prefer creating or editing scripts, data, and documentation before changing `.tscn` files.
- Change `.tscn` files only when the current step needs scene structure or scene references.
- Keep scene edits small and reviewable.
- Do not redesign existing scenes or move established nodes without an explicit task.

## Comments

- Code comments should be short and useful.
- Use comments to explain non-obvious responsibilities, assumptions, or boundaries.
- Avoid comments that repeat the code.
- Use English names and comments in code.

## Checks After Each Step

- Open the project in Godot 4.
- Run `res://scenes/main/Main.tscn` if it exists.
- Check the Output panel for parser, import, or scene reference errors.
- If the Godot executable is available on PATH, run:

```powershell
godot --headless --path . --quit
```

- Keep Git changes small enough to review in one pass.
