# Combat System

Phase 14 adds deterministic MVP combat and conquest. It is intentionally small: no tactical battle buttons, no ranged attacks, no diplomacy, and no healing.

## BattleData

File: `res://src/core/model/battle_data.gd`

`BattleData` stores active and completed battles in `RunState.battles`:

- Attacker army
- Source country
- Target country
- Status
- Elapsed and duration seconds
- Attacker and defender power
- Winner and casualties

## Combat Rules

File: `res://src/core/simulation/combat_simulation.gd`

`calculateArmyCombatPower()` sums `ArmyData.units` against `UnitData.combatPower`.

MVP modifiers:

- Cavalry uses its `flanking` bonus.
- Artillery uses its `fortificationDamage` bonus against defended countries.
- Food shortage applies `RunState.economy.combatPowerMultiplier`.
- Owned-country defense can use `defenseCombatMultiplier` from upgrades.

`calculateCountryDefensePower()` converts country defense into simple defender power.

## Attack Command

`start_attack(armyId, targetCountryId)` starts a battle only when:

- The army exists, is player-owned, stationed, and has units.
- The target country exists and is adjacent.
- The target is not already player-owned.
- The army or target is not already in an active battle.

The attacking army enters `Attacking` status and stores the target country.

## Battle Lifecycle

`SimulationManager` advances active battles during fixed simulation steps, so battle progress respects pause and game speed.

At battle end:

- Casualties are applied to the attacker and cannot make unit counts negative.
- If attacker power is at least defender power, the target country becomes player-owned.
- The winning army stations in the conquered country.
- `battleEnded` is emitted.
- On conquest, `countryConquered` is emitted.

## Map Input

Right-clicking a player-owned neighboring country requests movement. Right-clicking a non-player-owned neighboring country requests an attack. Core validation still decides whether the command is legal.

Phase 15 adds attack threat through `UpgradeSimulation.applyWarThreat()`, and conquest rewards plus upgrade choices after `countryConquered`.
