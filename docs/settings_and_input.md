# Settings And Input

Phase 21 adds desktop settings, runtime input actions, and a debug error overlay.

## User Settings

`UserSettings` defines a versioned settings dictionary:

- `masterVolume`
- `musicVolume`
- `sfxVolume`
- `uiScale`
- `windowMode`

`SettingsManager` stores the file at `user://paper_empire/settings.json`, applies audio volume immediately through `AudioManager`, applies UI scale through `UIRoot`, and switches fullscreen/windowed mode through `DisplayServer` outside headless runs.

## Settings UI

`settings_panel.gd` displays settings data and emits setting changes. It does not write files, change audio buses, or call `DisplayServer` directly.

`ui_root.gd` wires the panel to `SettingsManager` from the ESC menu.

## Input Actions

`InputActions.ensureDefaultActions()` registers runtime actions for:

- ESC menu
- pause
- WASD/arrow map pan
- mouse-wheel zoom
- speed hotkeys 1/2/3

`map_camera.gd` and `ui_root.gd` read those actions instead of hardcoded keyboard checks.

## Debug Overlay

`EventBus.reportDebugError()` forwards debug messages to `debug_error_overlay.gd`. The overlay is a UI-only display surface; systems that detect problems still own their validation and warning behavior.
