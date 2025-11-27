# Gold Analytics Board Sparkline - 2025-11-26

## Summary
- Added a timeline sparkline payload to `scripts/ci/goldAnalyticsBoard.mjs` so each scenario now emits `timelineSparkline` (up to 8 latest events with `delta`, `timestamp`, `gold`) alongside the existing snapshot rows. This keeps the board JSON ASCII-only and ready for lightweight charts in dashboards/portal without re-reading the timeline artifact.
- Markdown now surfaces the sparkline as a `Δ@t` column so reviewers can see recent deltas inline; the JSON remains unchanged.
- The Vitest asserts the sparkline shape to prevent regressions, and scenario IDs prefer explicit `scenario`/`mode` fields before falling back to filenames so alerts, summaries, and timeline rows coalesce correctly even when artifacts use slugs instead of paths.
- Sparklines now pull from the full timeline metrics payload when available (before falling back to a truncated `latestEvents` list) so dashboards keep up to 8 points even if CI summaries shorten their preview.
- The timeline dashboard now emits per-scenario slices (`scenarios[*].latestEvents`), and the gold analytics board prefers those slices when rendering sparklines so each scenario keeps its own trendline even if aggregated summaries truncate events.
- The timeline dashboard Markdown now renders a per-scenario table (events, net Δ, medians, spend streak, latest `Δ@t`), keeping the human-readable summary aligned with the JSON slices the board ingests.
- Per-scenario rows now include p90 gain/spend and variance vs the global medians/p90s, giving reviewers quick drift signals before diving into artifacts.

## How to Use
- Consumers can read `board.scenarios[*].timelineSparkline` directly for plotting per-scenario micro charts in Codex dashboards or portal embeds; values are already normalized to numbers or `null`.
- CLI remains the same: `npm run analytics:gold:board` (or `node scripts/ci/goldAnalyticsBoard.mjs --help`) writes `artifacts/summaries/gold-analytics-board.ci.json` and `.md` plus appends to `$GITHUB_STEP_SUMMARY`.

## Next Steps
1. Add percentile baselines per scenario once global baselines are emitted, so variance can compare against known targets instead of the current run’s global medians.
