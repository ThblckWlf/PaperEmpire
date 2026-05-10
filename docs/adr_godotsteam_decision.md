# ADR: GodotSteam Timing

## Status

Deferred.

## Context

Paper Empire needs Steam achievements eventually, but the prototype still changes event names, save data, run-end flow, and meta progression. Adding GodotSteam now would increase setup and CI friction before the platform contract is stable.

## Decision

Keep Steam behind `PlatformService` and use `MockPlatformService` for current development. Do not add GodotSteam, Steamworks binaries, or .NET dependencies in Phase 22.

## Consequences

- Gameplay remains independent of Steam APIs.
- Tests can verify achievement mapping with the mock service.
- A future Steam implementation can be introduced by replacing the service implementation and preserving the bridge/event map.
