# Codex Milestone EXT-06 - Balance Simulator Tooling

## LANDMARK: Goal
Create a developer tool under `scripts/tools/sim/` that runs many simulated runs
and produces CSV or JSON summaries.

## Tasks
1) Implement scenario loader reading:
   - `docs/keyboard-defense-plans/extended/tools/sim/scenarios.json`
2) Implement simplified player policy and typing model:
   - WPM and error rate inputs
   - time window logic
3) Run N simulations and compute:
   - survival curve
   - avg resources by day
   - top spike days
4) Output:
   - `user://sim_reports/<timestamp>/summary.json`
   - `user://sim_reports/<timestamp>/runs.csv`
   - `user://sim_reports/<timestamp>/report.md`
5) Add a headless runner:
   - `godot --headless --script res://scripts/tools/sim/balance_sim.gd -- --scenario Beginner --runs 1000`

## LANDMARK: Acceptance criteria
- 1k runs complete quickly (target under 5s).
- Deterministic outputs for fixed seed and config.
