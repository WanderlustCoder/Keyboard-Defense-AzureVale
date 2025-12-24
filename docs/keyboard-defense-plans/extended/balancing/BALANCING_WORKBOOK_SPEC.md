# Balancing Workbook Spec (Keyboard Defense)

This is a planning artifact for balancing inputs and outputs. It is a guide for
building a spreadsheet, not a required runtime file.

## Sheets and key fields

### Sheet: Inputs
- Base wave pacing (seconds per wave)
- Enemy health and speed multipliers
- Typing timing windows by tier
- Intervention effect sizes (slow, heal, buff)
- Reward tuning (gold per wave, bonus tiers)

### Sheet: Upgrades
- Upgrade id and cost
- Stat deltas per upgrade level
- Unlock prerequisites
- Notes on intent (early, mid, late)

### Sheet: Threat Cards
- Threat id
- Difficulty delta
- Counter intervention id
- Expected frequency

### Sheet: Player Skill Brackets
- WPM and error rate targets for Beginner, Intermediate, Advanced
- Assist mode or time multiplier
- Expected survival day

### Sheet: Outputs
- Survival curves by bracket
- Resource totals by day
- Notable spike days and causes

## Integration with sim scenarios
Use the scenario JSON to run the balance tool:
- `docs/keyboard-defense-plans/extended/tools/sim/scenarios.json`

## Acceptance criteria
- Workbook can be filled without referencing code.
- Values map cleanly to data files and sim tool inputs.
- Changes are traceable via version notes.
