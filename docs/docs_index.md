# Project Documentation Index

Use this index to jump straight to the guidance you'll need while building and testing Keyboard Defense. Documents are grouped by theme; each bullet links to a Markdown file or status note within this repo.

## Project Overview & Strategy
- `docs/season1_backlog.md` - Feature roadmap and numbered backlog for the Siege of the Azure Vale.
- `docs/CODEX_AUTONOMOUS_TESTING_DIRECTIVE_Siege_of_the_Azure_Vale.md` - Automation-first definition of done, scripting expectations, and QA guardrails.
- `docs/CODEX_GUIDE.md` - Codex-oriented workflow guide (where to find tasks, required commands, documentation rules).
- `docs/CODEX_PLAYBOOKS.md` - Domain-specific instruction sets (automation/CI, gameplay & UI, analytics/telemetry, documentation) tailored for Codex.
- `docs/CODEX_PORTAL.md` - Single navigation surface for all Codex instructions, scripts, fixtures, and task workflows.

## Analytics & Telemetry
- `docs/analytics_schema.md` — JSON/CSV snapshot schema, telemetry payload details, and aggregation column order.
- `docs/status/2025-11-04_telemetry_controls.md` — Status updates covering telemetry UI, export, and analytics enhancements.

## Automation & Monitoring
- `docs/status/2025-11-04_automation_scaffold.md` - Current automation script layout, future CI plans, and pending tooling work.
- `docs/status/2025-11-03_dev_monitor.md` - Dev-server monitor CLI notes and follow-up ideas.
- `docs/codex_pack/README.md` - Canonical automation task map, links to manifest, and authoring rules for Codex-driven work.
- `docs/codex_pack/manifest.yml` - Machine-readable task list powering the Codex automation blueprint.
- `apps/keyboard-defense/scripts/waveSim.mjs` - Deterministic wave simulation CLI (run `node scripts/waveSim.mjs --help`).
- `apps/keyboard-defense/scripts/validateConfig.mjs` - Validate GameConfig JSON via JSON Schema (`node scripts/validateConfig.mjs --help`).
- `apps/keyboard-defense/scripts/waveBenchmark.mjs` - Run curated wave benchmarks (`node scripts/waveBenchmark.mjs`) for quick balance checks.

## Status Notes
Status entries live under `docs/status/`. Recent highlights include:
- `2025-11-17_hud_condensed_lists.md` - Castle passives/gold events in the HUD collapse into summary cards for small screens.
- `2025-11-17_responsive_layout.md` - HUD stacks vertically on tablets/phones, overlays scroll, and touch targets grow to 44px min height.
- `2025-11-16_audio_intensity_slider.md` - Audio intensity slider in the pause/options overlay with persistence and scaled sound playback.
- `2025-11-16_devserver_monitor_refresh.md` - Dev server lifecycle restored (`npm run start`), standalone monitor CLI, and `start:monitored` wrapper wired back in.
- `2025-11-15_tooling_baseline.md` - ESLint/TypeScript/Prettier baselines restored so `npm run test` can run cleanly again.
- `2025-11-14_gold_summary_ci_guard.md` - CI smoke now runs `goldSummaryCheck` against the tutorial gold summary artifact.
- `2025-11-14_combo_accuracy_delta.md` - Combo warning badge now surfaces the live accuracy delta so players can react before streaks fall off.
- `2025-11-13_gold_summary_checker.md` - Standalone CLI validates gold summary artifacts (JSON/CSV) before dashboards ingest them.
- `2025-11-12_gold_summary_metadata.md` - Gold summary artifacts now embed the percentile list (JSON + CSV) for downstream validation.
- `2025-11-11_gold_ci_percentiles.md` - CI smoke and `goldReport` now forward `--percentiles 25,50,90` so gold summaries match dashboards.
- `2025-11-10_gold_percentile_flag.md` - `goldSummary.mjs` gains a `--percentiles` flag and dynamic gain/spend percentile columns.
- `2025-11-09_gold_percentiles.md` - Gold summary CLI now emits median/p90 gain & spend stats plus accurate cross-file aggregates.
- `2025-11-07_diagnostics_passives.md` - Diagnostics gold delta display, analytics CSV enrichment, and passive unlock artifacts.
- `2025-11-08_gold_event_history.md` - Diagnostics overlay now lists recent gold events for rapid economy debugging.
- `2025-11-08_gold_timeline_cli.md` - `npm run analytics:gold` CLI for exporting gold-event timelines from snapshots/artifacts.
- `2025-11-08_gold_summary_cli.md` - `npm run analytics:gold:summary` aggregates gold timelines into per-file economy stats.
- `2025-11-06_crystal_pulse.md` - Crystal Pulse turret rollout, toggle wiring, and shield-burst analytics.
- `2025-11-06_ci_pipeline.md` - CI workflow wiring for build/unit/integration + tutorial smoke and full E2E runs.
- `2025-11-06_hud_screenshots.md` - Automated HUD/options overlay screenshot capture script and usage.
- `2025-11-06_castle_breach_replay.md` - Deterministic castle breach replay CLI and backlog #99 closure.
- `2025-11-06_gold_event_delta.md` - Gold event delta/timestamp enrichment for economy analytics.
- `2025-11-06_castle_passives.md` - Castle passive buffs surfaced in HUD/options with unlock events.
- `2025-11-07_enemy_defeat_animation.md` - Procedural defeat burst animation added to fulfill backlog #66.
- `2025-11-07_starfield.md` - Ambient starfield background layer for backlog #68.
- `2025-11-07_passive_timeline.md` - Passive unlock timeline CLI for analytics exports and dashboard feeding.
- `2025-11-04_telemetry_controls.md` - Telemetry toggles, export metadata, and analytics viewer updates.
- `2025-11-04_automation_scaffold.md` - Scripts, test orchestration, and CI roadmap.
- `2025-11-03_dev_monitor.md` - Dev monitor CLI implementation details.
- `2025-11-08_asset_integrity.md` - Asset loader checksum enforcement, warnings, and backlog #69 closure.

## Where to Look Next
- Backlog item references (e.g., `#51`) point to `docs/season1_backlog.md`.
- Script entry points (build, unit, integration, smoke) are documented in `apps/keyboard-defense/scripts/README.md` (see that directory for inline comments if README missing).
- For onboarding/tutorial work, consult `docs/status/*` and the tutorial sections in `season1_backlog.md`.
