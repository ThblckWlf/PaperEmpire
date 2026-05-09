# UI Foundation

Phase 10 adds the first gameplay HUD. It displays state and emits commands; it does not calculate economy, combat, movement, or ownership changes.

## Layout

`res://scenes/main/Main.tscn` now has these `UIRoot` children:

- `TopBar`
- `LeftPanel`
- `RightPanel`
- `BottomBar`
- `ModalLayer`

`UIRoot` is a `CanvasLayer`; the listed children are `Control` nodes under `Root`.

## TopBar

File: `res://scenes/ui/top_bar.gd`

Displays prepared values from `RunStateView`:

- Gold
- Food
- Army count
- Threat
- Date

The TopBar does not compute these values.

## CountryPanel

File: `res://scenes/ui/country_panel.gd`

`RightPanel` displays the selected country:

- Name
- Owner
- Gold/month
- Food/month
- Defense
- Stationed armies and units

It refreshes when `countrySelected`, `runStarted`, or `runReset` events are raised.

## TimeControls

File: `res://scenes/ui/time_controls.gd`

`BottomBar` contains Pause, 1x, 2x, and 4x buttons. They emit commands through `EventBus`:

- `pause_game`
- `set_game_speed`

## ESC Menu Stub

File: `res://scenes/ui/esc_menu.gd`

ESC opens `ModalLayer`, pauses the run, and shows Resume plus a Quit-to-Menu stub. Resume restores the previous speed. Save/load is intentionally not present in Phase 10.

## View Data

File: `res://src/core/view/run_state_view.gd`

`RunStateView` creates display dictionaries for UI scripts. This keeps TopBar and CountryPanel simple and prevents UI scripts from owning gameplay rules.
