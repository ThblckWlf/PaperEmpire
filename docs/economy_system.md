# Economy System

Phase 11 adds the first monthly economy pass. It is isolated in core simulation code and runs only on `monthTick`.

## EconomySimulation

File: `res://src/core/simulation/economy_simulation.gd`

Responsibilities:

- Calculate monthly gold and food income from player-owned countries.
- Calculate food upkeep for player-owned armies from `UnitData.foodUpkeep` and `ArmyData.units`.
- Apply monthly income and upkeep to `RunState.resources`.
- Maintain visible food-shortage state in `RunState.economy`.

No trade routes, supply lines, recruitment, healing, rebellion, or UI-specific rules are implemented in Phase 11.

## Month Tick

`SimulationManager` applies economy before emitting `monthTick`. This means UI refreshes from the existing `monthTick` event and does not need special economy logic.

The `monthTick` payload includes an `economy` dictionary with:

- `goldIncome`
- `foodIncome`
- `foodUpkeep`
- `netFood`
- `gold`
- `food`
- `isFoodShortage`
- `foodShortageMonths`
- `combatPowerMultiplier`

## Food Shortage MVP

When food reaches `0`, `RunState.economy` exposes:

- `isFoodShortage`
- `recruitmentBlocked`
- `healingBlocked`

After two shortage months, `combatPowerMultiplier` becomes `0.8`. The later combat and recruitment systems can consume these flags; they are not applied to combat or recruitment yet.
