# Paper Empire - Codex Rules

## Project
Paper Empire is a desktop-first Steam strategy roguelike built with Godot 4 and GDScript.

## Hard Rules
- Use Godot 4.
- Use GDScript, not C#.
- Do not add .NET dependencies.
- Use static typing in GDScript where practical.
- Use lowerCamelCase for variables and functions.
- Keep changes small and focused.
- Do not implement multiple phases at once.
- Do not redesign scenes unless explicitly asked.
- Do not rename existing nodes unless explicitly asked.
- Do not change public behavior unless explicitly asked.

## Architecture Rules
- Game simulation logic belongs in scripts under res://src/core/.
- UI scenes display state and call commands, but must not contain combat, economy or movement rules.
- Visual effects scenes may animate events, but must not own gameplay rules.
- Save/load logic belongs in res://src/save/.
- Steam integration must stay behind a PlatformService abstraction.
- GodotSteam must not be added until explicitly requested.

## Scene Rules
- Prefer small scenes with clear responsibility.
- Do not hardcode fragile node paths across unrelated scenes.
- Use signals for communication between UI and game systems.
- Every important scene should have a short README or comment explaining its role.

## Checks
After changes:
- Open the project in Godot and check for parser errors.
- For headless CLI checks, use `.\scripts\godot.ps1 --headless --path . --quit` instead of relying on `godot` being on PATH.
- Run the main scene if it exists.
- Check the Output panel for errors.
- Keep Git changes reviewable.
