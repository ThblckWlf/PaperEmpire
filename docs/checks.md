# Local Checks

Run these checks after each focused implementation step. The goal is to catch parser errors, broken scene references, and unintended repository changes before moving to the next step.

## Required Manual Checks

1. Open the project folder in Godot 4.
2. Confirm the project opens without import or parser errors.
3. Open `res://scenes/main/Main.tscn`.
4. Run the main scene.
5. Check the Output panel for errors or warnings that block the current step.
6. Review the changed files in Git.

## Optional Headless Check

If the Godot executable is available on PATH:

```powershell
godot --headless --path . --quit
```

If the executable is named differently on the machine, use that name instead:

```powershell
godot4 --headless --path . --quit
```

## Debug Validation Runner

Phase 4 adds a manual debug scene for core data validation:

1. Open `res://tests_debug/DebugTestRunner.tscn`.
2. Run the current scene with F6.
3. Check the Output panel for `[DebugTestRunner] PASS` or `[DebugTestRunner] FAIL` lines.

The runner currently checks:

- `CountryData` valid and invalid fixtures.
- MVP `UnitData` definitions.
- `RunState` valid and invalid fixtures.
- Prototype JSON fixtures under `res://data/`.
- `NewRunFactory` prototype run creation.
- `GameManager` command skeleton and event emission.
- `GameTime` deterministic calendar advancement.
- `SimulationManager` speed handling and `monthTick` events.

## Git Checks

```powershell
git status --short
git diff --check
```

Before committing staged files:

```powershell
git diff --cached --check
git diff --cached --stat
```

## Phase Gate

Do not move to the next phase if any of these are true:

- `Main.tscn` does not start.
- `DebugTestRunner.tscn` reports failures.
- Godot reports parser errors.
- A changed scene has a missing script or invalid node reference.
- A step has half-wired signals or TODO-only scene references that are expected to work immediately.
- The Git diff includes unrelated changes.

## Current Environment Note

During Phase 2 setup on this machine, `godot` and `godot4` were not available on PATH. Until that is fixed, the Godot editor check and Output panel review must be performed manually.
