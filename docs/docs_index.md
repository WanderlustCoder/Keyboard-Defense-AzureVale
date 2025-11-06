# Project Documentation Index

Use this index to jump straight to the guidance you'll need while building and testing Keyboard Defense. Documents are grouped by theme; each bullet links to a Markdown file or status note within this repo.

## Project Overview & Strategy
- `docs/season1_backlog.md` — Feature roadmap and numbered backlog for the Siege of the Azure Vale.
- `docs/CODEX_AUTONOMOUS_TESTING_DIRECTIVE_Siege_of_the_Azure_Vale.md` — Automation-first definition of done, scripting expectations, and QA guardrails.

## Analytics & Telemetry
- `docs/analytics_schema.md` — JSON/CSV snapshot schema, telemetry payload details, and aggregation column order.
- `docs/status/2025-11-04_telemetry_controls.md` — Status updates covering telemetry UI, export, and analytics enhancements.

## Automation & Monitoring
- `docs/status/2025-11-04_automation_scaffold.md` — Current automation script layout, future CI plans, and pending tooling work.
- `docs/status/2025-11-03_dev_monitor.md` — Dev-server monitor CLI notes and follow-up ideas.
- `apps/keyboard-defense/scripts/waveSim.mjs` — Deterministic wave simulation CLI (run `node scripts/waveSim.mjs --help`).
- `apps/keyboard-defense/scripts/validateConfig.mjs` — Validate GameConfig JSON via JSON Schema (`node scripts/validateConfig.mjs --help`).
- `apps/keyboard-defense/scripts/waveBenchmark.mjs` — Run curated wave benchmarks (`node scripts/waveBenchmark.mjs`) for quick balance checks.

## Status Notes
Status entries live under `docs/status/`. Recent highlights include:
- `2025-11-07_diagnostics_passives.md` - Diagnostics gold delta display, analytics CSV enrichment, and passive unlock artifacts.
- `2025-11-06_crystal_pulse.md` - Crystal Pulse turret rollout, toggle wiring, and shield-burst analytics.
- `2025-11-06_ci_pipeline.md` - CI workflow wiring for build/unit/integration + tutorial smoke and full E2E runs.
- `2025-11-06_hud_screenshots.md` - Automated HUD/options overlay screenshot capture script and usage.
- `2025-11-06_castle_breach_replay.md` - Deterministic castle breach replay CLI and backlog #99 closure.
- `2025-11-06_gold_event_delta.md` - Gold event delta/timestamp enrichment for economy analytics.
- `2025-11-06_castle_passives.md` - Castle passive buffs surfaced in HUD/options with unlock events.
- `2025-11-04_telemetry_controls.md` - Telemetry toggles, export metadata, and analytics viewer updates.
- `2025-11-04_automation_scaffold.md` - Scripts, test orchestration, and CI roadmap.
- `2025-11-03_dev_monitor.md` - Dev monitor CLI implementation details.

## Where to Look Next
- Backlog item references (e.g., `#51`) point to `docs/season1_backlog.md`.
- Script entry points (build, unit, integration, smoke) are documented in `apps/keyboard-defense/scripts/README.md` (see that directory for inline comments if README missing).
- For onboarding/tutorial work, consult `docs/status/*` and the tutorial sections in `season1_backlog.md`.
