# Project Documentation Index

Use this index to jump straight to the guidance you'll need while building and testing Keyboard Defense. Documents are grouped by theme; each bullet links to a Markdown file or status note within this repo.

## Project Overview & Strategy
- `apps/keyboard-defense/docs/season1_backlog.md` - Feature roadmap and numbered backlog for the Siege of the Azure Vale.
- `apps/keyboard-defense/docs/season2_backlog.md` - Next-phase 100-item backlog for ages 8-16 (Edge/Chrome, free, pixel art direction).
- `apps/keyboard-defense/docs/icon_set_spec.md` - Pixel UI icon set spec (sizes, palette, states, naming) for buttons/toggles/HUD controls.
- `apps/keyboard-defense/docs/qa_typing_edge_cases.md` - QA checklist for typing input edge cases (modifiers, buffer rules, accessibility).
- `apps/keyboard-defense/docs/wordlist_lint_spec.md` - Wordlist/lesson lint rules and planned CLI (safe vocab, gating, lengths, weights, themes).
- `apps/keyboard-defense/docs/castle_tileset_spec.md` - Pixel castle tileset spec (walls, gates, towers, damage states, palette, exports).
- `apps/keyboard-defense/docs/roadmap/season1.json` - Season 1 roadmap milestones consumed by the HUD overlay.
- `apps/keyboard-defense/docs/deployment_checklist.md` - Deployment/release checklist for Edge/Chrome (automated gates, browser smoke, accessibility, packaging).
- `apps/keyboard-defense/docs/visual_baselines.md` - Playwright visual snapshot coverage and usage notes (HUD/loading/options/caps-lock).
- `docs/CODEX_AUTONOMOUS_TESTING_DIRECTIVE_Siege_of_the_Azure_Vale.md` - Automation-first definition of done, scripting expectations, and QA guardrails.
- `docs/CODEX_GUIDE.md` - Codex-oriented workflow guide (where to find tasks, required commands, documentation rules).
- `docs/CODEX_PLAYBOOKS.md` - Domain-specific instruction sets (automation/CI, gameplay & UI, analytics/telemetry, documentation) tailored for Codex.
- `docs/CODEX_PORTAL.md` - Single navigation surface for all Codex instructions, scripts, fixtures, and task workflows.
- `docs/hud_gallery.md` - HUD/Tutorial screenshot gallery with condensed-state badges sourced from `scripts/hudScreenshots.mjs`.
- `apps/keyboard-defense/docs/enemies/bestiary.json` - Enemy dossiers (roles, abilities, tips) consumed by the HUD wave preview bios.

## Analytics & Telemetry
- `docs/analytics_schema.md` - JSON/CSV snapshot schema, telemetry payload details, and aggregation column order.
- Typing drills quickstart telemetry (`ui.typingDrill.menuQuickstart`) - see `docs/analytics_schema.md#typing-drill-telemetry`.
- Typing drill quickstart summary CLI (`npm run telemetry:typing-drills`) - `apps/keyboard-defense/scripts/ci/typingDrillTelemetrySummary.mjs` (fixture: `docs/codex_pack/fixtures/telemetry/typing-drill-quickstart.json`).
- `docs/status/2025-11-04_telemetry_controls.md` - Status updates covering telemetry UI, export, and analytics enhancements.
- `apps/keyboard-defense/scripts/ci/diagnosticsDashboard.mjs` - Gold delta + passive timeline dashboard generator (`node scripts/ci/diagnosticsDashboard.mjs --help`).
- `apps/keyboard-defense/scripts/analytics/goldDeltaAggregator.mjs` - Per-wave gold delta aggregator powering docs/dashboards (`node scripts/analytics/goldDeltaAggregator.mjs --help`).
- `apps/keyboard-defense/scripts/ci/goldAnalyticsBoard.mjs` - Merges gold summary/timeline/passive/guard artifacts into a single Markdown/JSON board for Codex dashboards (`node scripts/ci/goldAnalyticsBoard.mjs --help`).
- `apps/keyboard-defense/scripts/debug/dprTransition.mjs` - Headless DPR transition simulator (`npm run debug:dpr-transition -- --steps 1:960,1.5:840 --json`) for reproducing `ui.canvasResolutionChanged` telemetry without browser zooming.
- `apps/keyboard-defense/scripts/analytics/validate-schema.mjs` - Ajv-based validator for analytics snapshots (`node scripts/analytics/validate-schema.mjs --help`).
- `apps/keyboard-defense/scripts/docs/verifyHudSnapshots.mjs` - Verifies HUD screenshot metadata contains diagnostics + preference fields (`npm run docs:verify-hud-snapshots`).

## Automation & Monitoring
- `docs/status/2025-11-04_automation_scaffold.md` - Current automation script layout, future CI plans, and pending tooling work.
- `docs/status/2025-11-03_dev_monitor.md` - Dev-server monitor CLI notes and follow-up ideas.
- `docs/codex_pack/README.md` - Canonical automation task map, links to manifest, and authoring rules for Codex-driven work.
- `docs/codex_pack/manifest.yml` - Machine-readable task list powering the Codex automation blueprint.
- `apps/keyboard-defense/scripts/waveSim.mjs` - Deterministic wave simulation CLI (run `node scripts/waveSim.mjs --help`).
- `apps/keyboard-defense/scripts/validateConfig.mjs` - Validate GameConfig JSON via JSON Schema (`node scripts/validateConfig.mjs --help`).
- `apps/keyboard-defense/scripts/devMonitor.mjs` - Standalone readiness monitor that polls the dev server and writes `artifacts/monitor/dev-monitor.json` (`npm run monitor:dev -- --help`).
- `apps/keyboard-defense/scripts/serveStartSmoke.mjs` - Force-restart/start/stop smoke harness used by CI (`npm run serve:start-smoke -- --help`).
- `apps/keyboard-defense/scripts/waveBenchmark.mjs` - Run curated wave benchmarks (`node scripts/waveBenchmark.mjs`) for quick balance checks.
- `docs/status/2025-11-06_castle_breach_replay.md` - Breach replay CLI summary plus outstanding analytics follow-ups.
- `docs/codex_pack/tasks/29-castle-breach-analytics.md` - Detailed automation plan for breach summaries, turrets, multi-enemy scenarios, and dashboards.
- `docs/CODEX_PLAYBOOKS.md#castle-breach-analytics-task-castle-breach-analytics` - Step-by-step workflow for implementing the breach analytics board.
- `apps/keyboard-defense/scripts/ci/traceabilityReport.mjs` - Maps backlog IDs to Codex tasks/tests and emits JSON/Markdown traceability summaries (`npm run ci:traceability`).

## Responsive Canvas & HUD
- `docs/status/2025-11-18_canvas_scaling.md` - Canvas resize helper, flex-driven render size, and pending DPR listener follow-ups.
- `docs/codex_pack/tasks/21-canvas-dpr-monitor.md` - Canonical work plan for DPR listeners, fade transitions, telemetry, and tests.
- `docs/CODEX_PLAYBOOKS.md#canvas-dpr-monitor--transitions-task-canvas-dpr-monitor` - Step-by-step implementation + verification checklist for Codex.

## Status Notes
Status entries live under `docs/status/`. Recent highlights include:
- `2025-12-10_fullscreen_toggle.md` - HUD fullscreen toggle button (syncs on fullscreenchange, disables if unsupported).
- `2025-12-10_caps_lock_warning.md` - Caps-lock warning under the typing input with aria-live feedback.
- `2025-12-10_loading_screen.md` - Loading overlay with pixel animation and rotating typing tips that auto-dismiss after assets are ready.
- `2025-12-09_devserver_open.md` - `npm run serve:open` starts/reuses the dev server with `--no-build` and opens the browser (supports `--force-restart`, `--host`, and `--port`).
- `2025-12-09_visual_auto_runner.md` - One-command Playwright visual runner that starts/stops the dev server and supports `--update`/`--keep-alive` flags.
- `2025-12-09_remote_visual_testing.md` - Quick steps for running Playwright visual tests over the network using `--host`/`--port` overrides.
- `2025-12-09_evacuation_events_slice3.md` - Evacuation lane reservation prevents conflicts with hazards/dynamic events; skips if no lane is free.
- `2025-12-09_wave_preview_slice3.md` - Live wave preview UI with timelines, lane/event filters, and SSE reloads (`npm run wave:preview`).
- `2025-12-06_git_hooks_precommit.md` - Pre-commit hook now uses a Node runner, respects `SKIP_HOOKS`, and installs via `npm run hooks:install`.
- `2025-12-06_turret_flavor_tooltips.md` - Turret selectors/status tooltips now carry flavor blurbs for Arrow/Arcane/Flame/Crystal.
- `2025-12-06_hud_font_shortcuts.md` - Diagnostics lists the active HUD font preset and options overlay supports `[` / `]` shortcuts to cycle sizes.
- `2025-12-05_hud_font_scale.md` - HUD font size options now include Small/Default/Large/XL presets with persistence and live scaling.
- `2025-12-07_typing_buffer_fuzz.md` - Typing buffer fuzz tests guard invalid input handling, buffer overflow, and purge/reset behavior.
- `2025-12-08_season_roadmap_overlay.md` - HUD roadmap overlay with filters/tracking and persisted preferences.
- `2025-12-08_enemy_biographies.md` - Wave preview enemy bios with selectable dossiers and tips.
- `2025-12-08_ambient_music_escalation.md` - Ambient profiles (calm/rising/siege/dire) with wave/health-driven escalation.
- `2025-12-08_wave_wordbanks.md` - Wave-themed vocab merged into enemy word pools (scout/shield/boss).
- `2025-12-08_victory_defeat_stingers.md` - Short audio stingers for victory/defeat status transitions.
- `2025-12-07_backlog_slicing.md` - Breakdowns for remaining "Not Started" backlog items and the planned slices for each.
- `2025-12-07_visual_regression_harness.md` - Playwright visual baselines for HUD overlays (hud-main, options, tutorial summary, wave scorecard) with update/run commands.
- `2025-12-07_tutorial_assist_replay_skip.md` - TutorialManager tests cover assist hints, skip cleanup, and replay/reset state clearing.
- `2025-12-07_tutorial_summary_snapshot.md` - Tutorial summary modal snapshot test covering stat text and CTA wiring.
- `2025-12-07_tutorial_replay_skip_soak.md` - Soak test alternates tutorial replay/skip, validating completion flag persistence across rapid cycles.
- `2025-12-07_asset_manifest_generation.md` - CLI to generate asset manifests with integrity hashes (`npm run assets:manifest`) plus verification mode.
- `2025-12-07_sprite_atlas_generation.md` - Sprite atlas packer CLI (`npm run assets:atlas`) with row-wrapping layout and tests.
- `2025-12-07_deferred_highres_assets.md` - Tiered asset loader loads low-res first, then high-res replacements with forced reloads and graceful fallback on failure.
- `2025-12-07_projectile_particles.md` - Offscreen-capable particle renderer stub with reduced-motion no-op and decay tests.
- `2025-12-07_castle_visual_morphing.md` - Castle levels carry palettes; renderer morphs visuals as upgrades progress (tests included).
- `2025-12-04_docs_watch.md` - `npm run docs:watch` monitors docs folders and auto-regenerates the Codex dashboard/portal after doc edits with debounced rebuilds.
- `2025-12-04_runtime_log_summary.md` - `npm run logs:summary` scans monitor/dev-server logs and emits breach/accuracy + warning/error summaries in JSON/Markdown.
- `2025-12-03_typing_drills_telemetry.md` - Telemetry summary CLI + dashboard tile for menu quickstarts, with fixtures/tests and coverage ignores.
- `2025-12-02_typing_drills_responsive.md` - HUD CTA now shows recommended drills inline; overlay gains condensed/mobile layout with scroll-capped card.
- `2025-12-01_typing_drills.md` - Typing drills overlay (Burst/Endurance/Shield Breaker) with HUD CTA, pause-safe flow, and analytics export columns.
- `2025-11-21_semantic_release.md` - Release automation (semantic-release, release workflow, bundle manifest) plus documentation updates for Codex operators.
- `2025-11-29_ci_matrix_nightly.md` - Nightly scenario matrix workflow (asset integrity, HUD screenshots, condensed audit) with uploaded summaries/artifacts.
- `docs/nightly_ops.md` - Cheat sheet for dispatching nightly workflows, artifacts to expect, and quick recovery commands.
- `apps/keyboard-defense/scripts/ci/downloadArtifacts.mjs` - Helper to pull nightly artifacts via `npm run ci:download-artifacts -- --run-id <id> --name <artifact>`.
  - Can auto-resolve the latest run id via `--workflow ci-matrix-nightly.yml` or `--workflow codex-dashboard-nightly.yml`.
- `apps/keyboard-defense/docs/WAVE_AUTHORING.md` - Quickstart for generating, validating, and live-previewing designer wave configs.
- `2025-11-20_gold_percentile_guard.md` - CI guard script now validates gold summary percentiles and publishes JSON/Markdown summaries.
- `2025-11-20_passive_gold_dashboard.md` - Passive unlock + gold dashboard automation now runs in CI and exposes summary JSON/Markdown for Codex reviews.
- `2025-11-20_gold_timeline_dashboard.md` - Gold timeline dashboard automation surfaces derived metrics (net delta, spend streaks) directly in CI summaries.
- `2025-11-20_gold_summary_dashboard.md` - Gold summary report now renders median/p90 gain/spend metrics with thresholds inside CI dashboards.
- `2025-11-20_gold_percentile_alerts.md` - Gold percentile baselines + thresholds now drive automated alerts and CI Markdown tables.
- `2025-11-20_gold_analytics_board.md` - Unified gold analytics board aggregates summary/timeline/passive/guard feeds and publishes a single CI tile.
- `2025-11-20_ui_snapshot_gallery.md` - HUD screenshot metadata + gallery automation keep condensed-state badges visible in docs and CI summaries.
- `2025-11-17_hud_condensed_lists.md` - Castle passives/gold events in the HUD collapse into summary cards for small screens.
- `2025-11-17_responsive_layout.md` - HUD stacks vertically on tablets/phones, overlays scroll, and touch targets grow to 44px min height.
- `codex_pack/fixtures/responsive/condensed-matrix.yml` - source of truth for condensed panel coverage (hud-main, options overlay, wave scorecard) consumed by `scripts/docs/condensedAudit.mjs`.
- `2025-11-16_audio_intensity_slider.md` - Audio intensity slider in the pause/options overlay with persistence and scaled sound playback.
- `2025-11-16_devserver_monitor_refresh.md` - Dev server lifecycle restored (`npm run start`), standalone monitor CLI, and `start:monitored` wrapper wired back in.
- `2025-11-15_tooling_baseline.md` - ESLint/TypeScript/Prettier baselines restored so `npm run test` can run cleanly again.
- `2025-11-28_gold_board_baseline.md` - Gold analytics board rows now surface timeline baseline drift (median/p90) and docs point `goldTimelineDashboard` at the committed percentile baseline.
- `2025-11-28_hud_screenshot_expansion.md` - Diagnostics and shortcut overlay captures added to the HUD gallery/fixtures with expanded required shot coverage.
- `2025-11-28_hud_gallery_dedupe.md` - HUD gallery generator dedupes shot ids, prefers live artifacts, and lists all metadata sources.
- `apps/keyboard-defense/scripts/ci/goldBaselineGuard.mjs` - CLI to check timeline scenarios against percentile baselines, emit a coverage report, and warn/fail when baselines are missing (nightly workflow includes it).
- `2025-11-28_codex_dashboard_nightly.md` - Nightly workflow refreshes the Codex dashboard/portal using gold board fixtures so starfield telemetry stays visible without manual runs.
- `.github/workflows/codex-dashboard-nightly.yml` - Actions workflow to regenerate the Codex dashboard/portal nightly or on dispatch (accepts artifact override inputs).
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
