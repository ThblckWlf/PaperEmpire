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
- `armyMoved`
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

These wrappers only emit signals. Command dispatch, typed event models, and simulation handling belong to later steps.

## Naming

- Signal names use `lowerCamelCase`.
- Event and command identifiers use `StringName`.
- Payload keys use `lowerCamelCase`.
- Payloads must contain IDs and primitive values, not Godot Node references.

## Current Limits

- No CommandBus implementation yet.
- No typed GameEvent resource or enum yet.
- No scene wiring yet.
- No autoload configuration yet.
