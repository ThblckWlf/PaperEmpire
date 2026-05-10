# Signal Rules

This document defines the Phase 2 signal boundaries for Paper Empire. It does not introduce a full event architecture; it only records which layer is allowed to talk to which other layer.

## Direction Of Communication

- UI requests actions through commands.
- Core simulation changes state and raises game events.
- Effects, audio, and UI react to game events.
- Save/load and platform services are called through explicit manager/service APIs, not through broad gameplay signals.

## UI To Commands

UI scripts may emit selection or request signals, then call a command-facing API.

Allowed:

- `countrySelected(countryId: String)`
- `armySelected(armyId: String)`
- `commandRequested(commandName: StringName, payload: Dictionary)`

Not allowed:

- UI scripts calculating combat outcomes.
- UI scripts changing ownership, resources, army movement, or threat directly.
- UI scripts reaching into simulation internals by node path.

## Simulation To GameEvents

Simulation modules should own rule outcomes. When a meaningful outcome happens, they raise a game event through `EventBus.raiseGameEvent()`.

Examples:

- `countryConquered`
- `armyMoveStarted`
- `armyMoved`
- `unitsRecruited`
- `armyCreated`
- `battleStarted`
- `battleResolved`
- `resourcesChanged`
- `threatChanged`
- `upgradeOffered`
- `miniGoalCompleted`

Payloads remain `Dictionary` in Phase 2 because typed event data models are not part of this step.

## Effects And Audio

Effects and audio listen to game events. They can animate, play sounds, or update visuals, but they must not change gameplay state.

Allowed:

- `ExplosionEffect` reacts to `battleResolved`.
- `EffectsLayer` reacts to `armyMoved`.
- `AudioManager` reacts to `countryConquered`.

Not allowed:

- Effects deciding battle damage.
- Audio or particles triggering ownership changes.
- Visual completion callbacks changing core state.

## EventBus Stub

`res://src/core/event_bus.gd` currently exposes two signals:

- `commandRequested(commandName: StringName, payload: Dictionary)`
- `gameEventRaised(eventName: StringName, payload: Dictionary)`

It also exposes two wrapper methods:

- `requestCommand(commandName: StringName, payload: Dictionary = {})`
- `raiseGameEvent(eventName: StringName, payload: Dictionary = {})`
- `raiseEvent(gameEvent: GameEvent)`

These wrappers only emit signals. Command dispatch is owned by `GameManager`; Phase 7 connects `commandRequested` to `GameManager.submitCommand()` so future UI can request speed changes without touching state directly.

`SimulationManager` also exposes local signals for time consumers:

- `gameSpeedChanged(speed: int)`
- `monthTick(month: int, year: int, elapsedSeconds: float)`

Simulation rules still belong in core systems, not UI scenes.

Phase 10 UI controls use the same command boundary. `TimeControls` sends speed commands through `EventBus.requestCommand()`, and the ESC menu pauses/resumes through commands instead of mutating `RunState`.

Phase 12 army movement uses the same boundary:

- `ArmyNode` selection requests `select_army`.
- Right-click country target requests `move_army`.
- `GameManager` delegates move validation to `ArmyMovementSimulation`.
- `SimulationManager` emits `armyMoved` when movement completes.

Phase 13 recruitment uses the same boundary:

- `CountryPanel` buttons request `recruit_units` or `create_army`.
- `GameManager` delegates validation to `RecruitmentSimulation`.
- UI and map scenes refresh from `unitsRecruited` and `armyCreated`.

Phase 14 combat uses the same boundary:

- Map input requests `start_attack` for non-player-owned targets.
- `GameManager` delegates validation to `CombatSimulation`.
- `SimulationManager` emits `battleEnded` and `countryConquered` after deterministic battle completion.

Phase 15 upgrades use the same boundary:

- `SimulationManager` emits `upgradeChoiceOpened` after conquest.
- `UpgradeModal` requests `choose_upgrade`.
- `GameManager` delegates effect application to `UpgradeSimulation` and emits `upgradeChosen`.

Phase 16 threat uses the same boundary:

- Core systems call `ThreatSimulation` for all threat changes.
- `SimulationManager` emits `threatChanged` and `worldReactionUpdated`.
- UI refreshes warning states from prepared view data.

## Naming

- Signal names use `lowerCamelCase`.
- Event and command identifiers use `StringName`.
- Payload keys use `lowerCamelCase`.
- Payloads must contain IDs and primitive values, not Godot Node references.

## Current Limits

- No CommandBus implementation yet.
- Only core manager scene wiring exists.
- No autoload configuration yet.
