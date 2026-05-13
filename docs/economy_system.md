# Economy System

Phase 11 adds the first monthly economy pass. It is isolated in core simulation code and runs only on `monthTick`.

## EconomySimulation

File: `res://src/core/simulation/economy_simulation.gd`

Responsibilities:

- Calculate monthly gold and food income from player-owned countries.
- Calculate food upkeep for player-owned armies from `UnitData.foodUpkeep` and `ArmyData.units`.
- Expose central food projection helpers for recruitment previews.
- Apply monthly income and upkeep to `RunState.resources`.
- Maintain visible food-shortage state in `RunState.economy`.

No trade routes, supply lines, healing, rebellion, or UI-specific rules are implemented in Phase 11.

## Month Tick

`SimulationManager` applies economy before emitting `monthTick`. This means UI refreshes from the existing `monthTick` event and does not need special economy logic.

The `monthTick` payload includes an `economy` dictionary with:

- `goldIncome`
- `foodIncome`
- `foodUpkeep`
- `netFood`
- `supplyDeficit`
- `emergencySupplyGoldPerMonth`
- `emergencySupplyGoldPaid`
- `unfundedSupplyDeficit`
- `gold`
- `food`
- `isFoodShortage`
- `foodShortageMonths`
- `combatPowerMultiplier`
- `foodWarning`

## Food Balance

New runs apply food-income floors in `NewRunFactory`:

- Every country has at least `32` food per month in run state.
- The start country has at least the starting army upkeep plus `12` food per month.
- Unit gold costs and starting army composition are unchanged.

Recruitment uses a soft food cap:

- Gold is still a hard requirement.
- Recruitment is not blocked by stored food.
- Recruitment is allowed even if the projected monthly food net becomes negative.
- Accepted recruitment results include `foodUpkeepAdded`, `projectedFoodUpkeep`, `projectedFoodNet`, and `foodWarning`.
- Accepted recruitment results also include projected emergency supply gold per month.

## Food Shortage MVP

When food net is negative, monthly economy first consumes stored food. If stored food is not enough, missing supply is paid automatically with gold at `2` gold per missing food.

When gold can cover the missing supply:

- `food` stays at `0`
- `emergencySupplyGoldPaid` records the paid gold
- `isFoodShortage` stays `false`
- `combatPowerMultiplier` stays `1.0`

When both food and gold cannot cover army supply, `RunState.economy` exposes:

- `isFoodShortage`
- `healingBlocked`
- `unfundedSupplyDeficit`

Starting with the first shortage month, `combatPowerMultiplier` becomes `0.7`.

`recruitmentBlocked` remains in the run state for save compatibility, but food shortage does not set it and recruitment does not consume it.

Phase 15 applies `foodUpkeepMultiplier` from upgrades when calculating monthly army upkeep.
