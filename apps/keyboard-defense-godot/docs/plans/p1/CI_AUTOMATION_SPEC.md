# CI Automation Spec (P1-QA-001)

## Objectives
Define a minimal, tool-agnostic CI pipeline that enforces the Quality Gates now and scales to scenario testing later. This spec does not mandate a CI vendor.

References:
- `docs/QUALITY_GATES.md`
- `docs/plans/p1/QA_AUTOMATION_PLAN.md`
- `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`

## CI stages (proposed)
1) Validate repo layout
   - Ensure required docs exist.
2) Headless tests
   - `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - `bash ./scripts/test.sh`
3) Headless smoke boot
   - `godot --headless --path . --quit-after 2`
4) Scenario suite (future)
   - `godot --headless --path . --script res://tests/run_scenarios.gd`

## Minimal command set (current)
- `godot --version`
- `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
- `bash ./scripts/test.sh`
- `godot --headless --path . --quit-after 2`

## Artifact capture
- Preserve `_test.log` and `_test_summary.log` from scripts.
- Scenario harness writes JSON reports and `last_summary.txt` under `Logs/ScenarioReports/` when `--out-dir` is used (recommended for CI collection).

## Gating policy proposal
- PR gate: headless tests + smoke boot.
- Nightly: full scenario catalog + report diffs.

## Local dev parity
Developers must be able to run the same commands locally, using the scripts in `scripts/` for consistent output.

## Future expansion
- Add lint/format when GDScript quality tooling is selected.
- Add baseline diff checks for scenarios with deterministic outputs.
