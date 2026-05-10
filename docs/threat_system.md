# Threat System

Phase 16 centralizes threat and adds a small world-reaction stub. It does not add diplomacy, coalition AI, or real counterattack behavior.

## ThreatSimulation

File: `res://src/core/simulation/threat_simulation.gd`

Responsibilities:

- Add passive monthly threat while the run is advancing.
- Add action threat for started wars and conquered countries.
- Add monthly large-army threat when player unit count exceeds the MVP threshold.
- Derive visible threat states.
- Update the world reaction stub.

Pause behavior is inherited from `SimulationManager`: paused runs do not advance time, so monthly threat does not tick.

## Threat Sources

Current sources:

- `PASSIVE_THREAT_PER_MONTH`
- `WAR_STARTED_THREAT`
- `COUNTRY_CONQUERED_THREAT`
- Large army pressure above `LARGE_ARMY_THRESHOLD`

The `warThreatMultiplier` upgrade effect applies to war and conquest action threat.

## UI States

TopBar displays threat with a state label:

- `low`
- `caution`
- `high`
- `critical`

The label color changes by state. These are simple Control colors, not final art.

## World Reaction Stub

`RunState.worldReaction` stores:

- `level`
- `enemyStrengthMultiplier`
- `counterAttackPrepared`
- `lastThreat`

At higher threat levels, enemy country defense receives a simple multiplier through `CombatSimulation`. At critical threat, `counterAttackPrepared` becomes true as a future AI hook; no counterattack is launched in Phase 16.
