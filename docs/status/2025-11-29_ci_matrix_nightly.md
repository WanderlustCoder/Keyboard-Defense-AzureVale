# CI Matrix Nightly - 2025-11-29
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `ci-matrix-nightly` workflow to run the tutorial/breach scenario matrix every day at 06:00 UTC (or on dispatch) using the existing `scripts/ci/run-matrix.mjs` harness.
- Nightly job installs Playwright browsers, verifies asset integrity in strict mode, captures HUD screenshots, runs the HUD metadata verifier + condensed audit, and uploads the matrix summary plus gallery/audit artifacts for review.
- HUD gallery artifacts now stay fresh even when CI smoke jobs are idle, and the condensed audit keeps responsive coverage visible in nightly outputs.

## Next Steps
1. Consider wiring matrix alerts into dashboards/portal so missing HUD shots or asset integrity failures surface without opening artifacts.
2. Optionally add dispatch inputs for starfield scene/viewport overrides to make screenshot tuning easier for future HUD changes.

## Follow-up
- `docs/codex_pack/tasks/04-scenario-matrix.md`
- `docs/codex_pack/tasks/37-responsive-condensed-audit.md`

