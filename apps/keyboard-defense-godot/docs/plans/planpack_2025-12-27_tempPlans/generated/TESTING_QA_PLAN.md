# Testing and QA Plan

## Purpose
Ensure every feature is validated with headless tests, data integrity checks,
and smoke boot coverage.

## Sources
- docs/GODOT_TESTING_PLAN.md
- apps/keyboard-defense-godot/docs/ROADMAP.md
- docs/keyboard-defense-plans/CODEX_CLI_PLAYBOOK.md

## Required test layers
1) Unit and system tests (GDScript)
   - Typing rules, progression, rewards, buffs, and save/load.
2) Data contract tests
   - Lessons, map nodes, drills, and upgrades validate against schemas.
3) Scene and UI layout tests
   - Main scenes load headless and verify key nodes/layout invariants.
4) Gameplay integration smoke
   - Deterministic battle smoke run with victory/defeat coverage.
5) Asset audit checks
   - Manifest completeness, size budgets, and import settings.

## Execution commands
- Headless tests: `godot --headless --path . --script res://tests/run_tests.gd`
- Smoke boot: `godot --headless --path . --quit`

## Acceptance criteria
- All automated tests pass headless.
- Smoke boot completes without errors.
- New art/audio passes automated audit plus manual QA review.
