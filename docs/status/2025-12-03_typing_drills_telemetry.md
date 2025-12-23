# Typing Drill Quickstart Telemetry - 2025-12-03
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `npm run telemetry:typing-drills` to summarize `ui.typingDrill.menuQuickstart` + `typing-drill.started/completed` envelopes from exported telemetry JSON, producing JSON/Markdown for dashboards and GH step summaries.
- Codex dashboard + portal now render a Typing Drills Quickstart section (counts, source/mode mix/share, recommendation mix, completion rate, reasons, recent quickstarts) powered by `artifacts/summaries/typing-drill-telemetry.json`.
- New telemetry fixture (`docs/codex_pack/fixtures/telemetry/typing-drill-quickstart.json`) and Vitest coverage validate parsing/formatting for drill quickstart adoption metrics.
- .gitignore now ignores coverage outputs under `apps/**/coverage/` to keep repo clean after local test runs.

## Next Steps
1. Pipe live telemetry exports from sessions/CI smoke into the summary job so menu vs HUD CTA adoption trends stay fresh.
2. Add HUD CTA vs menu comparison in the summary markdown once HUD `typing-drill.started` volumes are available.
3. Consider surfacing a lightweight sparkline for quickstart volume over time if telemetry history grows.

## Related Work
- `apps/keyboard-defense/scripts/ci/typingDrillTelemetrySummary.mjs`
- `apps/keyboard-defense/scripts/generateCodexDashboard.mjs`
- `docs/codex_pack/fixtures/telemetry/typing-drill-quickstart.json`

