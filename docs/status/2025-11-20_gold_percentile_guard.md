## Gold Percentile Guard - 2025-11-20

**Summary**
- Added `scripts/ci/goldPercentileGuard.mjs`, a Codex-friendly wrapper around `goldSummaryCheck.mjs` that locates gold summary artifacts, enforces the canonical percentile list, and emits both JSON (`artifacts/summaries/gold-percentile-guard*.json`) and Markdown so CI reviewers see mismatches without downloading artifacts.
- GitHub Actions `Tutorial Smoke` and `Full E2E` jobs now call the guard immediately after generating their gold summary outputs. Failures block the job (unless `GOLD_GUARD_MODE=warn`), and the produced summary JSON rides alongside the existing smoke/e2e artifact bundles.
- Updated Codex guide/playbook entries so local dry-runs (`node scripts/ci/goldPercentileGuard.mjs docs/codex_pack/fixtures/gold-summary.json`) stay in sync with CI expectations.
- `goldAnalyticsBoard.mjs` now ingests the guard summary from both workflows, so percentile failures surface on the consolidated CI tile without visiting multiple dashboard sections.

**Next Steps**
1. Extend the guard output with percentile deltas when `gold-percentile-dashboard-alerts` lands, so alerting thresholds can reuse the same normalized payload.
2. Consider exposing guard duration/latency stats inside the JSON to help the analytics board flag stale artifacts when runs omit gold summaries.

## Follow-up
- `docs/codex_pack/tasks/36-gold-percentile-ingestion-guard.md`
- `docs/codex_pack/tasks/27-gold-summary-dashboard-integration.md`
- `docs/codex_pack/tasks/38-gold-analytics-board.md`
