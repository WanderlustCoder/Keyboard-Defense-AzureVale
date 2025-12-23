# Gold Analytics Baseline Drift - 2025-11-28
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Propagated timeline baseline variance from `goldTimelineDashboard` into the gold analytics board JSON so per-scenario rows now carry `timelineBaselineVariance`.
- Dashboard and Codex portal tables gained a **Baseline Drift (med/p90)** column alongside the existing timeline drift, keeping board/portal snapshots aligned with baseline-aware timeline metrics.
- Documented the `--baseline` flag in the gold timeline CLI entries (`CODEX_GUIDE`, `CODEX_PLAYBOOKS`) so local/CI runs can point at `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json` or updated baselines.
- Added a `--timeline-baseline` fallback to `goldAnalyticsBoard.mjs` (wired into the nightly dashboard workflow) so baseline drift still populates when timeline summaries were generated without baseline data.
- Board Markdown now lists baseline coverage stats (matched/missing), making it easier to confirm when CI runs skipped a baseline or when new scenarios need baseline entries.
- Guide/playbook entries note that baseline coverage warnings will appear when scenarios are missing percentile baseline rows so operators can refresh baselines proactively.
- Nightly dashboard summary now prints the baseline coverage line (`matched/total`, baseline entries) to `$GITHUB_STEP_SUMMARY`, so operators don't have to open the artifacts to spot missing baselines.
- Added a unit test that asserts baseline warnings fire when coverage is missing, and the board now surfaces a sample warning line in the dashboard/portal snippets for quicker triage.
- Added `goldBaselineGuard.mjs` + CI guard step (nightly) to fail/warn when timeline scenarios lack baselines; guide updated with the guard CLI.
- Nightly guard now runs in `fail` mode so missing baseline coverage will break the dashboard job until baselines are refreshed.

## Next Steps
1. Wire the nightly dashboard workflow to pass a baseline path (if not already present) so the new column stays populated on scheduled runs.
2. After the next CI artifact drop, rerun `node scripts/ci/goldTimelineDashboard.mjs ... --baseline <latest>` + `npm run codex:dashboard` to publish live baseline drift values.***

