# Codex Dashboard Nightly - 2025-11-28

## Summary
- Added `codex-dashboard-nightly` GitHub Actions workflow to refresh the Codex dashboard and portal every day (05:30 UTC) using gold analytics fixtures. The run generates the gold analytics board, rebuilds `docs/codex_dashboard.md` + `docs/CODEX_PORTAL.md`, and uploads the Markdown/JSON artifacts so the portal’s starfield telemetry tile stays current without manual commands.
- Workflow uses the configurable starfield severity thresholds (warn < 65%, breach < 50%) and the same fixture inputs documented in the gold board task, keeping severity badges consistent across the board, dashboard, and portal tiles.

## Next Steps
1. Swap fixtures for real nightly artifacts once a CI job produces fresh gold summaries/timelines; then publish the refreshed dashboard to GitHub Pages or commit the Markdown automatically.
2. Consider adding a portal badge/link to the uploaded artifact so operators can grab the nightly board directly from the Actions run.
