# Gold Analytics Board Sparkline - 2025-11-26

## Summary
- Added a timeline sparkline payload to `scripts/ci/goldAnalyticsBoard.mjs` so each scenario now emits `timelineSparkline` (up to 8 latest events with `delta`, `timestamp`, `gold`) alongside the existing snapshot rows. This keeps the board JSON ASCII-only and ready for lightweight charts in dashboards/portal without re-reading the timeline artifact.
- The Vitest now asserts the sparkline shape to prevent regressions while keeping the Markdown output unchanged (still the compact table).
- Scenario IDs now prefer explicit `scenario`/`mode` fields before falling back to filenames, ensuring alerts, summaries, and timeline rows coalesce correctly even when artifacts use slugs instead of paths.

## How to Use
- Consumers can read `board.scenarios[*].timelineSparkline` directly for plotting per-scenario micro charts in Codex dashboards or portal embeds; values are already normalized to numbers or `null`.
- CLI remains the same: `npm run analytics:gold:board` (or `node scripts/ci/goldAnalyticsBoard.mjs --help`) writes `artifacts/summaries/gold-analytics-board.ci.json` and `.md` plus appends to `$GITHUB_STEP_SUMMARY`.

## Next Steps
1. Render the sparkline in the Codex dashboard and portal cards (mini delta strip + hover values).
2. Expand sparkline source to use the full timeline summary metrics when available, keeping truncation at 8 points for readability.
3. Add optional severity badges for starfield/castle thresholds to the Markdown/JSON once thresholds are finalized.
