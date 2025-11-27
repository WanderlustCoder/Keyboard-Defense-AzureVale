# Gold Analytics Board - 2025-11-20

## Summary
- Landed `scripts/ci/goldAnalyticsBoard.mjs`, which ingests the existing gold summary, timeline, passive, guard, and percentile alert artifacts into a single JSON/Markdown bundle (`gold-analytics-board.*`). The CLI normalizes scenario rows, bubbles up guard/alert warnings, and auto-appends the Markdown block to `$GITHUB_STEP_SUMMARY`.
- CI smoke and full e2e workflows now run the board step immediately after the individual gold dashboards. Each job writes `artifacts/summaries/gold-analytics-board.(smoke|e2e).{json,md}` plus the refreshed percentile alerts JSON, so reviewers only need to open one tile per run.
- Documentation (Guide, Playbooks, Dashboard, Portal) now lists the board CLI, fixture dry-run command, and artifact locations so collaborators can reproduce the board locally (`node scripts/ci/goldAnalyticsBoard.mjs --summary docs/codex_pack/fixtures/gold/gold-summary-report.json --timeline docs/codex_pack/fixtures/gold/gold-timeline-summary.json --passive docs/codex_pack/fixtures/gold/passive-gold-summary.json --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json temp/gold-analytics-board.fixture.json --markdown temp/gold-analytics-board.fixture.md`).
- The Codex dashboard now consumes the board JSON directly, showing the latest status badge plus a per-scenario table (net delta, last gold delta, last passive, alert counts) so reviewers can see the state without opening artifacts.
- The Codex portal includes the same snapshot (between `GOLD_ANALYTICS_BOARD` markers), giving operators a live landing-page view of the latest economy health without navigating to the dashboard.
- Starfield telemetry from the gold summary now feeds the board: the Markdown/portal snapshot prints a `Starfield` column per scenario plus a summary bullet with the averaged depth/drift/wave/castle tint so castle damage context travels with every gold review.
- Board JSON/Markdown now include timeline sparklines (delta@t arrays plus ASCII spark bars) and starfield severity badges (`CALM/WARN/BREACH`) computed from castle ratio thresholds (default warn < 65%, breach < 50%; overridable via CLI/env) so trend shape and castle damage drift are visible at a glance in both the dashboard tile and portal.
- Added a dedicated starfield telemetry tile to the Codex portal (under `STARFIELD_TELEMETRY` markers) that summarizes the latest averages/severity, thresholds, and per-scenario starfield badges directly from the board JSON so portal visitors can spot castle tint drift without opening artifacts.

## Next Steps
1. Wire the board snapshot into the Codex dashboard automation in CI (e.g., nightly job) so docs stay up to date without manual `npm run codex:dashboard` executions.

## Follow-up
- `docs/codex_pack/tasks/38-gold-analytics-board.md`
