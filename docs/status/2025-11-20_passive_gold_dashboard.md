## Passive Unlock & Gold Dashboard - 2025-11-20

**Summary**
- Added `scripts/ci/passiveGoldDashboard.mjs`, which reuses the passive timeline helper to aggregate castle passive unlocks, merge nearby gold deltas, compute spacing/lag metrics, and emit both JSON and Markdown summaries (default `artifacts/summaries/passive-gold*.json`). Thresholds are configurable via `PASSIVE_MAX_GAP_SECONDS`, `PASSIVE_MAX_GOLD_LAG_SECONDS`, and the guard supports `fail`/`warn` modes just like the percentile guard.
- Tutorial smoke and e2e workflows now run the dashboard step right after the gold percentile guard, appending the Markdown snapshot to `$GITHUB_STEP_SUMMARY` and uploading the summary JSON so reviewers can see the last few unlocks plus gold spikes without downloading raw artifacts. The e2e variant also ingests the castle breach artifact to keep breach unlocks visible.
- Codex docs (`CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md`, `codex_dashboard.md`) now reference the new script/fixtures so local dry-runs mirror CI: `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn`.
- The consolidated `goldAnalyticsBoard.mjs` step consumes the passive summary for smoke/e2e jobs, so the nightly CI tile now shows the latest unlock cadence + gold lag alongside the timeline, guard, and percentile data.

**Next Steps**
1. Consider rendering sparkline images (or markdown glyphs) so the Codex dashboard shows directional changes even when Markdown tables are truncated.
2. Surface per-passive lag deltas (min/avg/max) in the summary JSON so the analytics board can highlight which unlocks are drifting longest.

## Follow-up
- `docs/codex_pack/tasks/34-gold-timeline-dashboard.md`
- `docs/codex_pack/tasks/38-gold-analytics-board.md`
