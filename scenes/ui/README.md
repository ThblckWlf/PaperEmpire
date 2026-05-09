# UI Scenes

Phase 10 UI scripts display prepared state and emit commands through `EventBus`.

- `ui_root.gd` wires the HUD, event refreshes, and ESC menu behavior.
- `top_bar.gd` displays run resources, army count, threat, and date.
- `country_panel.gd` displays the currently selected country.
- `time_controls.gd` emits pause and speed commands.
- `esc_menu.gd` exposes Resume and a Quit-to-Menu stub.

UI scripts must not calculate combat, economy, movement, ownership changes, or save/load behavior.
