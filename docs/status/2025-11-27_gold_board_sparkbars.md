# Gold Analytics Board Spark Bars - 2025-11-27

## Summary
- Added compact ASCII spark bars to the gold analytics board rows in both the Codex dashboard and portal tiles. Each scenario now shows the `delta@t` sequence plus a bar glyph strip that scales to the largest recent delta, staying ASCII-only for CI summaries.
- The generator (`scripts/ci/goldAnalyticsBoard.mjs` payload consumed by `generateCodexDashboard.mjs`) already emits `timelineSparkline`; the dashboard formatter now renders both the readable `+/-delta@t` string and a bar strip to make trend shape visible at a glance. The Markdown board now mirrors the portal by appending the ASCII bar strip to each sparkline row.
- Regenerated `docs/codex_dashboard.md` and `docs/CODEX_PORTAL.md` so the new spark bars appear in the published tiles. Added a short spark bar legend to `docs/CODEX_GUIDE.md` so reviewers know how to read the glyphs.

## Next Steps
1. Consider a denser spark bar legend or tooltip snippet if reviewers need clearer glyph scaling.
