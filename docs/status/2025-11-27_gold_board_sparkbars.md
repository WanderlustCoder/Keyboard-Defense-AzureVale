# Gold Analytics Board Spark Bars - 2025-11-27

## Summary
- Added compact ASCII spark bars to the gold analytics board rows in both the Codex dashboard and portal tiles. Each scenario now shows the `delta@t` sequence plus a bar glyph strip that scales to the largest recent delta, staying ASCII-only for CI summaries.
- The generator (`scripts/ci/goldAnalyticsBoard.mjs` payload consumed by `generateCodexDashboard.mjs`) already emits `timelineSparkline`; the dashboard formatter now renders both the readable `+/-Δ@t` string and a bar strip to make trend shape visible at a glance.
- Regenerated `docs/codex_dashboard.md` and `docs/CODEX_PORTAL.md` so the new spark bars appear in the published tiles.

## Next Steps
1. Add optional starfield/castle severity badges (e.g., WARN on castle ratio drift) once thresholds are locked.
2. Consider a denser spark bar legend in `docs/CODEX_GUIDE.md` for new reviewers.
