# UI Scenes

Phase 10 UI scripts display prepared state and emit commands through `EventBus`.

- `MainMenu.tscn` / `res://scripts/ui/main_menu.gd` provide the first boot screen, menu modals, and Main Menu access to Shop/Settings.
- `ui_root.gd` wires the HUD, event refreshes, and ESC menu behavior.
- `top_bar.gd` displays run resources, army count, threat, and date.
- `army_panel.gd` displays the currently selected army.
- `mini_goal_panel.gd` displays mini-goal progress and sends reward-claim commands.
- `country_panel.gd` displays the currently selected country and sends recruitment/create-army commands.
- `time_controls.gd` emits pause and speed commands.
- `esc_menu.gd` exposes Resume, Save, Load, Settings, Return to Main Menu, and Quit Game. It must not expose Shop.
- `upgrade_modal.gd` displays three upgrade choices and sends `choose_upgrade`.
- `shop_panel.gd` displays prepared meta-upgrade shop rows and sends `purchase_meta_upgrade`.
- `settings_panel.gd` displays desktop settings and emits setting change requests.
- `debug_error_overlay.gd` displays debug messages reported through `EventBus`.

UI scripts must not calculate combat, economy, movement, ownership changes, or save/load behavior.
