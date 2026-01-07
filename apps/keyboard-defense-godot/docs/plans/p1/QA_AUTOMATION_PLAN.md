# QA Automation Plan

Roadmap ID: P1-QA-001 (Status: In progress)

## Test pyramid
- Unit tests: sim logic (parser, reducers, determinism) and pure helpers.
- Integration tests: headless smoke boot of main scene.
- Data contract tests: file presence and lightweight schema checks.

## CI-friendly verification commands
- `godot --headless --path . --script res://tests/run_tests.gd`
- `godot --headless --path . --quit-after 2`
- Wrapper scripts: `scripts/test.ps1` and `scripts/test.sh` for summary visibility.

## Determinism guarantees
- RNG state stored in `GameState` and only mutated in sim.
- Word selection uses deterministic hashes and does not consume RNG state.
- Any new sim randomness must use `sim/rng.gd` helpers.

## Scenario test harness (linked plan)
- See `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md` for fixed-seed scenarios.

## Acceptance criteria
- Headless tests remain green on every milestone.
- CI logs show `[tests] OK N` via wrapper scripts.
- Determinism tests cover core night pipeline and exploration.

## Test plan
- Maintain unit coverage for parser, reducer, and typing feedback helpers.
- Add scenario suite and record outputs for balance checks.
- Manual smoke checklist before releases (load/save, day->night->dawn).

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/generated/TESTING_QA_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/GODOT_TESTING_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/QA_CHECKLIST.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`
