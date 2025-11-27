## Gold Timeline Dashboard Automation - 2025-11-20

**Summary**
- Added `scripts/ci/goldTimelineDashboard.mjs`, which reads either analytics snapshots or existing `goldTimeline` outputs, merges passive unlock metadata, and computes derived metrics (net delta, median gain/spend, average delta, max spend streak). The script emits Markdown/JSON summaries (`artifacts/summaries/gold-timeline*.json`) and supports configurable thresholds via `GOLD_TIMELINE_MAX_SPEND_STREAK` / `GOLD_TIMELINE_MIN_NET_DELTA` plus fail/warn guard modes.
- GitHub Actions smoke/e2e jobs now run the dashboard step after the passive/gold aggregator, so reviewers get a single CI summary that lists the latest gold events, rolling net delta, and spend streak alerts without downloading artifacts.
- Codex documentation (Guide, Playbooks, dashboard appendix) now references the CLI + fixtures, so autonomous runs can regenerate the timeline summary locally: `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn`.
- `goldAnalyticsBoard.mjs` now ingests the timeline summary for both smoke/e2e workflows, so the consolidated CI tile surfaces the most recent events, passive links, and spend streak alerts directly.

**Next Steps**
1. Extend the dashboard to publish percentile deltas (median/p90) once task #27 wires gold summary data into the same reporting surface.
2. Emit sparkline-friendly arrays so the analytics board (and future static dashboards) can render short trendlines instead of single deltas per scenario.

## Follow-up
- `docs/codex_pack/tasks/34-gold-timeline-dashboard.md`
- `docs/codex_pack/tasks/38-gold-analytics-board.md`
