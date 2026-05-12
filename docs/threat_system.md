# Threat System

Phase 16 centralizes threat and world reactions. Threat is capped at 100; at 100, the world enters coalition mode and NPC countries bordering the player can attack the player.

## ThreatSimulation

File: `res://src/core/simulation/threat_simulation.gd`

Responsibilities:

- Add passive monthly threat while the run is advancing.
- Add action threat for started wars and conquered countries.
- Add monthly large-army threat when player unit count exceeds the MVP threshold.
- Derive visible threat states.
- Update the world reaction state.

Pause behavior is inherited from `SimulationManager`: paused runs do not advance time, so monthly threat does not tick.

## Threat Sources

Current sources:

- `PASSIVE_THREAT_PER_MONTH`
- `WAR_STARTED_THREAT`
- `COUNTRY_CONQUERED_THREAT`
- Large army pressure above `LARGE_ARMY_THRESHOLD`

The `warThreatMultiplier` upgrade effect applies to war and conquest action threat.

Threat can never exceed `MAX_THREAT` / `COALITION_THRESHOLD` (100). Threat results report only the amount that was actually applied after the cap.

## UI States

TopBar displays threat with a state label:

- `low`
- `caution`
- `high`
- `critical`
- `coalition`

The label color changes by state. These are simple Control colors, not final art.

## AI War Behavior

Below 100 threat, AI countries remain peaceful. They do not start NPC-vs-NPC attacks and they do not attack the player.

At exactly 100 threat, coalition behavior starts: NPC countries adjacent to player-owned countries can attack those player borders. NPC-vs-NPC attacks remain disabled.

## World Reaction Stub

`RunState.worldReaction` stores:

- `level`
- `enemyStrengthMultiplier`
- `counterAttackPrepared`
- `lastThreat`

At higher threat levels, enemy country defense receives a simple multiplier through `CombatSimulation`. At critical threat, `counterAttackPrepared` becomes true. At coalition threat, the reaction level becomes `coalition`, enemy strength uses the coalition multiplier, and AI war decisions can target player-owned border countries.
