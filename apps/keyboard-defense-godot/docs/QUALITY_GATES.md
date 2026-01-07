# Quality Gates

## Scope and intent
This document defines the minimum quality checks required for merges and releases so that deterministic gameplay, docs, and tests remain trustworthy.

## Definitions
- Merge Gate: required checks before merging changes into the main branch.
- Release Gate: additional checks before producing a public build.

## Merge Gate checklist
- Run automated tests: `scripts/test.ps1` and `scripts/test.sh`.
- Run headless smoke boot: `godot --headless --path . --quit-after 2`.
- Update docs when applicable (ROADMAP/PROJECT_STATUS/CHANGELOG).
- Verify no determinism regressions (same seed + actions -> same outcomes).

## Release Gate checklist
- Complete the manual smoke test script (core loop day->night->dawn).
- Run `docs/ACCESSIBILITY_VERIFICATION.md` (1280x720 readability + keyboard-only checklist).
- Confirm default keybinds are conflict-free (`settings verify` shows `Keybind conflicts: none`).
- Verify versioning notes are updated for the build.
- Review export instructions in `docs/plans/p0/EXPORT_PIPELINE_PLAN.md`.
- Confirm save/profile migrations are documented.

## Scenario test triggers
- Add or update scenario tests when touching P0-BAL-001 or P1-QA-001 scope.
- Use the scenario catalog and harness plan for deterministic checks.
- P0 balance suite (fast): `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --exclude-tag long --out-dir Logs/ScenarioReports`
- Full balance suite: `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --out-dir Logs/ScenarioReports`
- Targets view (non-enforcing): `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --targets --out-dir Logs/ScenarioReports`
- Early targets enforced (must stay green): `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --tag early --enforce-targets --out-dir Logs/ScenarioReports`
- Early targets enforced wrapper: `scripts/scenarios_early.ps1` or `scripts/scenarios_early.sh`
- Mid targets enforced (informational until tuned): `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --tag mid --enforce-targets --out-dir Logs/ScenarioReports`
- Mid targets enforced wrapper: `scripts/scenarios_mid.ps1` or `scripts/scenarios_mid.sh`
- Targets enforced (future gate): `godot --headless --path . --script res://tools/run_scenarios.gd --tag p0 --tag balance --enforce-targets --out-dir Logs/ScenarioReports`
- Baselines are expected to pass; targets are informational until explicitly enforced.
- Scenario artifacts (CI-friendly): `Logs/ScenarioReports/*.json` + `Logs/ScenarioReports/last_summary.txt`.
- After direct scenario runs, view the summary: `Get-Content Logs/ScenarioReports/last_summary.txt` (PowerShell) or `cat Logs/ScenarioReports/last_summary.txt` (bash).

## Future gate (scenario harness)
- Once coverage is sufficient, scenario runs will become a PR or nightly gate.
- Command: `godot --headless --path . --script res://tools/run_scenarios.gd --all`

## Links
- `docs/ROADMAP.md`
- `docs/COMMAND_REFERENCE.md`
- `docs/plans/README.md`

## Sources (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/QA_CHECKLIST.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`
