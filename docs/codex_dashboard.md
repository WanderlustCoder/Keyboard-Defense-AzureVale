# Codex Dashboard

| Task | Priority | State | Owner | Status Note | Backlog |
| --- | --- | --- | --- | --- | --- |
| `ci-guards` | P1 | todo | unassigned | docs/status/2025-11-14_gold_summary_ci_guard.md | #82 |
| `ci-matrix` | P1 | todo | unassigned | docs/status/2025-11-18_devserver_bin_resolution.md | #82 |
| `ci-step-summary` | P1 | todo | unassigned | docs/status/2025-11-18_devserver_smoke_ci.md | #79 |
| `type-lint-test` | P1 | todo | unassigned | docs/status/2025-11-15_tooling_baseline.md | #73 |
| `visual-diffs` | P1 | todo | unassigned | docs/status/2025-11-06_hud_screenshots.md | #94 |
| `asset-integrity-telemetry` | P2 | todo | unassigned | docs/status/2025-11-08_asset_integrity.md | #69, #41 |
| `audio-intensity-telemetry` | P2 | todo | unassigned | docs/status/2025-11-16_audio_intensity_slider.md | #54, #79 |
| `canvas-dpr-monitor` | P2 | todo | unassigned | docs/status/2025-11-18_canvas_scaling.md | #53 |
| `ci-traceability-report` | P2 | todo | unassigned | docs/status/2025-11-06_ci_pipeline.md | #71, #95 |
| `combo-accuracy-analytics` | P2 | todo | unassigned | docs/status/2025-11-14_combo_accuracy_delta.md | #14, #41 |
| `defeat-burst-diagnostics` | P2 | todo | unassigned | docs/status/2025-11-07_enemy_defeat_animation.md | #41 |
| `devserver-bin-guidance` | P2 | todo | unassigned | docs/status/2025-11-18_devserver_bin_resolution.md | #82 |
| `devserver-monitor-upgrade` | P2 | todo | unassigned | docs/status/2025-11-16_devserver_monitor_refresh.md | #82 |
| `diagnostics-condensed-controls` | P2 | todo | unassigned | docs/status/2025-11-18_diagnostics_overlay_condensed.md | #41 |
| `diagnostics-dashboard` | P2 | todo | unassigned | docs/status/2025-11-07_diagnostics_passives.md | #79 |
| `git-hooks-lint` | P2 | todo | unassigned | docs/status/2025-11-15_tooling_baseline.md | #80 |
| `gold-analytics-board` | P2 | todo | unassigned | docs/status/2025-11-20_gold_summary_dashboard.md | #79, #101, #45 |
| `gold-delta-aggregates` | P2 | todo | unassigned | docs/status/2025-11-06_gold_event_delta.md | #79 |
| `gold-percentile-baseline-refresh` | P2 | todo | unassigned | docs/status/2025-11-20_gold_percentile_alerts.md | #101, #79 |
| `hermetic-ci` | P2 | todo | unassigned | docs/status/2025-11-16_devserver_monitor_refresh.md | #82 |
| `passive-analytics-export` | P2 | todo | unassigned | docs/status/2025-11-06_castle_passives.md | #41, #79 |
| `responsive-condensed-audit` | P2 | todo | unassigned | docs/status/2025-11-17_hud_condensed_lists.md | #53, #58 |
| `scenario-matrix` | P2 | todo | unassigned | docs/status/2025-11-06_ci_pipeline.md | #71, #95 |
| `schema-contracts` | P2 | todo | unassigned | docs/status/2025-11-08_gold_summary_cli.md | #76 |
| `semantic-release` | P2 | todo | unassigned | docs/status/2025-11-15_tooling_baseline.md | #80 |
| `static-dashboard` | P2 | todo | unassigned | docs/status/2025-11-18_devserver_smoke_ci.md | #79 |
| `taunt-analytics-metadata` | P2 | done | codex | docs/status/2025-11-19_enemy_taunts.md | #41, #79 |
| `tutorial-passive-messaging` | P2 | todo | unassigned | docs/status/2025-11-06_castle_passives.md | #1, #30 |
| `castle-breach-analytics` | P2 | done | unassigned | docs/status/2025-11-06_castle_breach_replay.md | #99, #41 |
| `gold-percentile-dashboard-alerts` | P2 | done | unassigned | docs/status/2025-11-09_gold_percentiles.md | #101, #79 |
| `gold-percentile-ingestion-guard` | P2 | done | unassigned | docs/status/2025-11-13_gold_summary_checker.md | #103, #104, #105, #106 |
| `gold-summary-dashboard-integration` | P2 | done | unassigned | docs/status/2025-11-08_gold_summary_cli.md | #101, #79 |
| `gold-timeline-dashboard` | P2 | done | unassigned | docs/status/2025-11-08_gold_timeline_cli.md | #45, #79 |
| `passive-gold-dashboard` | P2 | done | unassigned | docs/status/2025-11-07_passive_timeline.md | #41, #79 |
| `tutorial-ui-snapshot-publishing` | P2 | done | unassigned | docs/status/2025-11-18_tutorial_condensed_states.md | #53, #59 |
| `enemy-defeat-spriteframes` | P3 | todo | unassigned | docs/status/2025-11-07_enemy_defeat_animation.md | #66 |
| `passive-iconography` | P3 | todo | unassigned | docs/status/2025-11-06_castle_passives.md | #30 |
| `starfield-parallax-effects` | P3 | todo | unassigned | docs/status/2025-11-07_starfield.md | #68, #94 |
| `taunt-catalog-expansion` | P3 | todo | unassigned | docs/status/2025-11-19_enemy_taunts.md | #83, #87 |

## Passive Unlock & Gold Dashboard
- CI smoke & e2e jobs publish `artifacts/summaries/passive-gold*.json` plus the Markdown snippet attached to the job summary.
- Local dry-run: `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn`.
- Thresholds: `PASSIVE_MAX_GAP_SECONDS` controls unlock spacing, `PASSIVE_MAX_GOLD_LAG_SECONDS` bounds the unlock-to-gold merge latency.

## Gold Timeline Dashboard
- CI publishes `artifacts/summaries/gold-timeline*.json` alongside the percentile and passive summaries; Markdown appears in the job summary.
- Local dry-run: `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn`.
- Thresholds: `GOLD_TIMELINE_MAX_SPEND_STREAK` caps consecutive spend streaks, `GOLD_TIMELINE_MIN_NET_DELTA` enforces a net economy floor.

## Gold Summary Report
- CI publishes `artifacts/summaries/gold-summary-report*.json`; Markdown shows percentile drift + net delta per artifact.
- Local dry-run: `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold-summary.json --summary temp/gold-summary-report.fixture.json --mode warn`.
- Baselines live in `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`, thresholds in `scripts/ci/gold-percentile-thresholds.json`.

## Castle Breach Watch
- E2E workflow runs `node scripts/ci/castleBreachSummary.mjs --summary artifacts/summaries/castle-breach.e2e.json artifacts/castle-breach.ci.json` and appends the Markdown table to `$GITHUB_STEP_SUMMARY`.
- Local dry-run: `node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach/base.json --summary temp/castle-breach-summary.fixture.json --mode warn`.
- Thresholds: `CASTLE_BREACH_MAX_TIME_MS` caps time-to-breach, `CASTLE_BREACH_MIN_DAMAGE` ensures defenses still register meaningful hits.

## Taunt Spotlight
- CI analytics exports now include `analytics.taunt` metadata plus HUD screenshot sidecars (`*.meta.json`) listing the active taunt, lane, wave, and timestamp.
- Local dry-run: `npx vitest run tests/analyticsAggregate.test.js` to verify CSV columns, then `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots` to regenerate the gallery meta files.
- Use the `hud_gallery.md` badges to confirm responsive captures reflect the taunt state without downloading raw artifacts.

Generated automatically via `npm run codex:dashboard`.
