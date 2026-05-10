# Recruitment System

Phase 13 adds MVP recruitment and empty army creation. It is immediate and command-driven; there is no queue, training time, split, merge, or final balancing.

## Core Rules

File: `res://src/core/simulation/recruitment_simulation.gd`

`RecruitmentSimulation.calculateRecruitmentCost()` calculates:

- Gold cost from `UnitData.cost * amount`.
- Food reserve required from `UnitData.foodUpkeep * amount`.

Food is checked as an available reserve but is not spent by recruitment. Monthly food upkeep remains owned by the economy system.

Phase 15 applies `recruitmentCostMultiplier` from upgrades to the gold cost.

`RecruitmentSimulation.applyRecruitment()` accepts recruitment only when:

- The country exists and is player-owned.
- The unit type is one of the loaded MVP units.
- Amount is positive.
- Recruitment is not blocked by `RunState.economy.recruitmentBlocked`.
- Gold is high enough for the purchase.
- Food reserve is high enough for the added upkeep.
- A stationed player army exists in the country.

The preferred target is the currently selected army when it is stationed in the country; otherwise the first valid stationed army in that country is used.

## Commands And Events

New commands:

- `recruit_units`
- `create_army`

New events:

- `unitsRecruited`
- `armyCreated`

`GameManager` owns command dispatch, delegates validation to `RecruitmentSimulation`, and emits events after successful state changes.

## Create Army MVP

`create_army` creates a new empty stationed player army in a player-owned country. It is selected immediately so later recruitment commands can fill it.

Empty armies are allowed in Phase 13 because split/merge and army templates are not implemented yet.

## UI

The country panel exposes MVP buttons:

- `+Inf`
- `+Cav`
- `+Art`
- `Create Army`

Buttons request commands through `EventBus`; they do not mutate state directly. The top bar, army panel, country panel, and map refresh through normal game events.
