# UI Foundation

Phase 10 adds the first gameplay HUD. It displays state and emits commands; it does not calculate economy, combat, movement, or ownership changes.

## Layout

`res://scenes/main/Main.tscn` now has these `UIRoot` children:

- `MainMenu` (created at runtime under `Root`)
- `TopBar`
- `LeftPanel`
- `RightPanel`
- `BottomBar`
- `ModalLayer`

`UIRoot` is a `CanvasLayer`; the listed children are `Control` nodes under `Root`.

## Main Menu

File: `res://scenes/ui/MainMenu.tscn`

The game boots to the Main Menu before creating a run. It uses the Paper Empire parchment UI kit under
`res://assets/` for the menu background, panels, button states, dividers, and icons.

The menu exposes Continue Run, New Run, Shop, How To Play, Settings, Load Game, Credits, and Quit Game.
`Start Age Run` exists as a hidden debug placeholder and is not connected to gameplay.

Continue and Load use the current manual slot, `manual_1`. If no valid run save exists, both actions are
disabled and the info panel reports `No save found`.

Country selection and save-slot browsing are placeholders in this step. New Run starts the current Paperland
prototype only after the placeholder modal is confirmed.

## TopBar

File: `res://scenes/ui/top_bar.gd`

Displays prepared values from `RunStateView`:

- Gold
- Food
- Army count
- Threat
- Date

The TopBar does not compute these values.

It refreshes on `monthTick`, so Phase 11 economy changes appear through normal state/event flow.

Phase 16 adds threat state labels and simple colors for low, caution, high, and critical.

## CountryPanel

File: `res://scenes/ui/country_panel.gd`

`RightPanel` displays the selected country:

- Name
- Owner
- Gold/month
- Food/month
- Defense
- Stationed armies and units
- MVP recruitment buttons
- Create Army button

It refreshes when `countrySelected`, `runStarted`, or `runReset` events are raised.

Phase 13 buttons send commands through `EventBus`; the panel does not spend resources or modify armies directly.

## ArmyPanel

File: `res://scenes/ui/army_panel.gd`

`LeftPanel` displays the selected army:

- Status
- Location
- Target
- Unit counts

It refreshes on run, army selection, movement start, movement completion, battle start/end, conquest, recruitment, army creation, month tick, and speed events. Movement, combat, and recruitment rules stay in core simulation code.

## MiniGoalPanel

File: `res://scenes/ui/mini_goal_panel.gd`

Displays prototype mini-goal progress. Completed unclaimed goals become claim buttons and request `claim_mini_goal_reward`.

## TimeControls

File: `res://scenes/ui/time_controls.gd`

`BottomBar` contains Pause, 1x, 2x, and 4x buttons. They emit commands through `EventBus`:

- `pause_game`
- `set_game_speed`

## ESC Menu

File: `res://scenes/ui/esc_menu.gd`

ESC opens `ModalLayer`, pauses the run, and shows Resume, Save, Load, Settings, Return to Main Menu, and Quit Game.
Resume restores the previous speed. Shop/meta-progression is intentionally not available from the ESC menu.

## UpgradeModal

File: `res://scenes/ui/upgrade_modal.gd`

Shows three upgrade choices after conquest. It uses the same `ModalLayer`, blocks normal interaction, and sends `choose_upgrade` through `EventBus`.

## View Data

File: `res://src/core/view/run_state_view.gd`

`RunStateView` creates display dictionaries for UI scripts. This keeps TopBar and CountryPanel simple and prevents UI scripts from owning gameplay rules.

Phase 12 adds selected army panel data to the same view layer.

Phase 17 adds mini-goal panel data to the same view layer.
