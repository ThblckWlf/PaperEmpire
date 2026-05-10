# Export And Packaging

Phase 23 adds a Windows Desktop export preset and packaging checklist for the vertical-slice build.

## Windows Preset

`export_presets.cfg` contains one runnable preset:

- Preset: `Windows Desktop`
- Output: `exports/windows/PaperEmpire.exe`
- Architecture: `x86_64`
- PCK mode: embedded
- Product name: `Paper Empire`
- Product/file version: `0.1.0.0`

The project metadata in `project.godot` sets `config/name`, `config/version`, and the existing placeholder `res://icon.svg`.

## Export Command

```powershell
.\scripts\godot.ps1 --headless --path . --export-release "Windows Desktop" "exports/windows/PaperEmpire.exe"
```

The target directory must exist before running the command.

## Production Smoke Checklist

For a packaged Windows build, verify:

- App starts from `PaperEmpire.exe`.
- Main scene starts without parser/import errors.
- New run is created automatically.
- World map, country nodes, army nodes, and camera controls render.
- Army movement can be requested between neighboring countries.
- Manual Save/Load works through the ESC menu.
- Shop and Settings panels open from ESC.
- Quit path is either functional or documented as MVP stub.

## Phase 23 Local Result

The Windows preset is recognized by Godot 4.6.2, but the packaged executable export is blocked on this machine because Windows export templates are not installed.

Missing template paths reported by Godot:

- `C:/Users/mausg/AppData/Roaming/Godot/export_templates/4.6.2.stable/windows_debug_x86_64.exe`
- `C:/Users/mausg/AppData/Roaming/Godot/export_templates/4.6.2.stable/windows_release_x86_64.exe`

This is an environmental blocker, not a gameplay code blocker. After installing the matching Godot 4.6.2 export templates, rerun the export command above and then execute the smoke checklist on `exports/windows/PaperEmpire.exe`.

Do not add SteamPipe upload or store assets in this phase.

## Performance Snapshot

Packaged-build performance measurement is blocked until the Windows export templates are installed and the executable can be produced.

Initial target for the vertical slice:

- Stable desktop frame pacing at the current prototype map scale.
- No obvious CPU spikes during month ticks, movement, combat, save/load, or UI panel opening.
- No optimization work without a measured profiler issue.

The first packaged-build profiler pass should record:

- Average FPS over one minute in a running mini-run.
- CPU frame time during month tick.
- CPU frame time during army movement.
- GPU frame time with map/effects visible.
- Any visible hitch while saving/loading.
