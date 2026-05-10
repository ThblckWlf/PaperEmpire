# Mini-Goal System

Phase 17 adds runtime progress and claimable rewards for prototype mini-goals. It does not add story events, quest chains, or permanent unlocks.

## Data

File: `res://data/miniGoals.json`

Each fixture requires:

- `id`
- `name`
- `description`
- `goalType`
- `progressRule`
- `target`
- `rewardType`
- `rewardValue`

Optional:

- `limit`

`MiniGoalDataValidator` rejects invalid goal types, progress rules, reward types, non-positive target/reward values, and quest-chain fields.

## Runtime State

`NewRunFactory` initializes mini-goals through `MiniGoalSimulation.initializeGoals()`.

Runtime fields per goal:

- `progress`
- `isCompleted`
- `isRewardClaimed`
- `isFailed`

`RunState.miniGoalState` currently stores `upgradeRarityBoost` for rewards that improve the next upgrade roll.

## Progress

File: `res://src/core/simulation/mini_goal_simulation.gd`

Progress updates from game events and current state:

- Conquest count
- Gold resources
- Total army power
- Battle result payloads
- Threatened-month ticks
- Low-threat conquests

`GameManager` and `SimulationManager` call the mini-goal simulation before emitting gameplay events, so UI refreshes see updated progress.

## Rewards

Rewards are claimed through `claim_mini_goal_reward`; they are not auto-claimed.

Supported rewards:

- Gold
- Food
- Upgrade rarity boost

Each reward can be claimed once. The mini-goal panel disables already-claimed rewards.

## UI

File: `res://scenes/ui/mini_goal_panel.gd`

The panel shows current progress for all prototype goals. Completed unclaimed goals become clickable claim buttons.
