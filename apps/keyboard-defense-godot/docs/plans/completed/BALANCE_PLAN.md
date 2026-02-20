# P0 Balance Plan

Roadmap IDs: P0-BAL-001

## What needs balancing
- Enemy hp, armor, and speed scaling across days 1-7.
- Tower costs, upgrade costs, and damage/range scaling.
- Word length ranges per enemy kind and lesson.
- Threat and wave pacing so early nights are survivable without high speed.

## Tuning workflow
1) Establish baselines
   - Fixed seeds for days 1, 3, 5, 7.
   - Record wave size, enemy mix, and survival outcomes.
   - Run the P0 balance suite (`scripts/scenarios.ps1` or `scripts/scenarios.sh`) and review the latest report in `user://scenario_reports/`.
   - For midgame tuning, run: `godot --headless --path . --script res://tools/run_scenarios.gd -- --tag p0 --tag balance --tag mid --enforce-targets`.
   - Capture deltas and notes in `docs/plans/p0/BALANCE_TUNING_NOTES.md`.
2) Targeted adjustments
   - Adjust enemy stats and tower costs in small increments.
   - Re-run the same fixed seeds for comparison.
3) Validate readability
   - Ensure enemies remain readable and typing load feels teachable.
4) Repeat until targets are met

## Data to adjust (code references)
- Enemy stats: `res://sim/enemies.gd`
- Tower stats and costs: `res://sim/buildings.gd`
- Night setup and spawn pacing: `res://sim/apply_intent.gd`
- Lesson word lengths: `res://sim/lessons.gd` + `res://data/lessons.json`
- Economy guardrails (caps/bonuses): `res://sim/balance.gd`
- Constants index: `docs/BALANCE_CONSTANTS.md`

## Targets
- Numeric ranges and day buckets: `docs/plans/p0/BALANCE_TARGETS.md`

## Planning references
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/BALANCING_MODEL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CORE_SIM_GAMEPLAY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/PLAYTEST_PLAN.md`

## Acceptance criteria
- Day 1-3 runs are survivable with average accuracy (no hard speed gate).
- Towers meaningfully reduce damage without trivializing waves.
- Enemy variety appears by day 3+ with clear, teachable word lengths.
- Balance changes remain deterministic for the same seed/actions.

## Test plan
- Add fixed-seed scenario tests for days 1, 3, 5, 7 (headless).
- Manual: run 2-3 sessions at different typing speeds and record outcomes.
