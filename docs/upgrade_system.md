# Upgrade System

Phase 15 adds passive conquest upgrades. It does not add active abilities, rerolls, a shop, meta progression, or complex synergies.

## Upgrade Data

File: `res://data/upgrades.json`

Each upgrade requires:

- `id`
- `name`
- `description`
- `rarity`
- `effectType`
- `value`

Supported MVP effect types:

- `recruitmentCostMultiplier`
- `foodUpkeepMultiplier`
- `conquestGoldMultiplier`
- `warThreatMultiplier`
- `defenseCombatMultiplier`

`UpgradeDataValidator` rejects unsupported effect types and active abilities.

## Runtime State

`RunState` stores:

- `activeUpgradeChoice`
- `upgrades`
- `upgradeEffects`

`upgradeEffects` contains aggregated multipliers so simulation systems can read one stable value per effect type.

## Choice Roll

File: `res://src/core/simulation/upgrade_simulation.gd`

After conquest, `SimulationManager` asks `UpgradeSimulation` to roll exactly three eligible upgrades without duplicate IDs. Already chosen upgrades are excluded.

When a choice opens:

- `activeUpgradeChoice` is stored in `RunState`.
- The run speed is set to paused.
- `upgradeChoiceOpened` is emitted.

## Modal

File: `res://scenes/ui/upgrade_modal.gd`

The modal shows three upgrade buttons. Pressing one sends `choose_upgrade`; the modal does not apply effects directly.

`GameManager` applies the selected upgrade, emits `upgradeChosen`, and resumes normal speed.

## Passive Effects

Implemented effects:

- Recruitment cost multiplier changes `RecruitmentSimulation` gold costs.
- Food upkeep multiplier changes monthly army upkeep.
- Conquest gold multiplier changes immediate conquest rewards.
- War threat multiplier changes threat added when starting attacks.
- Defense combat multiplier changes owned-country defense power.

Phase 16 centralizes threat in `ThreatSimulation`; upgrade code only provides the `warThreatMultiplier` value.
