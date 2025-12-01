# Codex Dashboard

| Task | Priority | State | Owner | Status Note | Backlog |
| --- | --- | --- | --- | --- | --- |
| `ci-guards` | P1 | done | codex | docs/status/2025-11-14_gold_summary_ci_guard.md | #82 |
| `ci-matrix` | P1 | done | codex | docs/status/2025-11-18_devserver_bin_resolution.md | #82 |
| `ci-step-summary` | P1 | done | codex | docs/status/2025-11-18_devserver_smoke_ci.md | #79 |
| `type-lint-test` | P1 | done | codex | docs/status/2025-11-15_tooling_baseline.md | #73 |
| `visual-diffs` | P1 | done | codex | docs/status/2025-11-06_hud_screenshots.md | #94 |
| `asset-integrity-telemetry` | P2 | done | codex | docs/status/2025-11-08_asset_integrity.md | #69, #41 |
| `audio-intensity-telemetry` | P2 | done | codex | docs/status/2025-11-16_audio_intensity_slider.md | #54, #79 |
| `canvas-dpr-monitor` | P2 | done | codex | docs/status/2025-11-18_canvas_scaling.md | #53 |
| `castle-breach-analytics` | P2 | done | unassigned | docs/status/2025-11-06_castle_breach_replay.md | #99, #41 |
| `ci-traceability-report` | P2 | done | codex | docs/status/2025-11-06_ci_pipeline.md | #71, #95 |
| `combo-accuracy-analytics` | P2 | done | codex | docs/status/2025-11-14_combo_accuracy_delta.md | #14, #41 |
| `defeat-burst-diagnostics` | P2 | done | codex | docs/status/2025-11-07_enemy_defeat_animation.md | #41 |
| `devserver-bin-guidance` | P2 | done | codex | docs/status/2025-11-18_devserver_bin_resolution.md | #82 |
| `devserver-monitor-upgrade` | P2 | done | codex | docs/status/2025-11-16_devserver_monitor_refresh.md | #82 |
| `diagnostics-condensed-controls` | P2 | done | codex | docs/status/2025-11-18_diagnostics_overlay_condensed.md | #41 |
| `diagnostics-dashboard` | P2 | done | codex | docs/status/2025-11-07_diagnostics_passives.md | #79 |
| `docs-watch` | P2 | done | unassigned | docs/status/2025-12-04_docs_watch.md | #77 |
| `git-hooks-lint` | P2 | done | codex | docs/status/2025-11-15_tooling_baseline.md | #80 |
| `gold-analytics-board` | P2 | done | codex | docs/status/2025-11-20_gold_summary_dashboard.md | #79, #101, #45 |
| `gold-delta-aggregates` | P2 | done | codex | docs/status/2025-11-06_gold_event_delta.md | #79 |
| `gold-percentile-baseline-refresh` | P2 | done | codex | docs/status/2025-11-20_gold_percentile_alerts.md | #101, #79 |
| `gold-percentile-dashboard-alerts` | P2 | done | unassigned | docs/status/2025-11-09_gold_percentiles.md | #101, #79 |
| `gold-percentile-ingestion-guard` | P2 | done | unassigned | docs/status/2025-11-13_gold_summary_checker.md | #103, #104, #105, #106 |
| `gold-summary-dashboard-integration` | P2 | done | unassigned | docs/status/2025-11-08_gold_summary_cli.md | #101, #79 |
| `gold-timeline-dashboard` | P2 | done | unassigned | docs/status/2025-11-08_gold_timeline_cli.md | #45, #79 |
| `hermetic-ci` | P2 | done | codex | docs/status/2025-11-16_devserver_monitor_refresh.md | #82 |
| `hud-gallery-dedupe` | P2 | done | codex | docs/status/2025-11-28_hud_gallery_dedupe.md | #72 |
| `hud-screenshot-expansion` | P2 | done | codex | docs/status/2025-11-28_hud_screenshot_expansion.md | #72 |
| `passive-analytics-export` | P2 | done | codex | docs/status/2025-11-06_castle_passives.md | #41, #79 |
| `passive-gold-dashboard` | P2 | done | unassigned | docs/status/2025-11-07_passive_timeline.md | #41, #79 |
| `responsive-condensed-audit` | P2 | done | codex | docs/status/2025-11-17_hud_condensed_lists.md | #53, #58 |
| `scenario-matrix` | P2 | done | codex | docs/status/2025-11-06_ci_pipeline.md | #71, #95 |
| `schema-contracts` | P2 | done | codex | docs/status/2025-11-08_gold_summary_cli.md | #76 |
| `semantic-release` | P2 | done | codex | docs/status/2025-11-21_semantic_release.md | #80 |
| `static-dashboard` | P2 | done | codex | docs/status/2025-11-18_devserver_smoke_ci.md | #79 |
| `taunt-analytics-metadata` | P2 | done | codex | docs/status/2025-11-19_enemy_taunts.md | #41, #79 |
| `tutorial-passive-messaging` | P2 | done | codex | docs/status/2025-11-06_castle_passives.md | #1, #30 |
| `tutorial-ui-snapshot-publishing` | P2 | done | unassigned | docs/status/2025-11-18_tutorial_condensed_states.md | #53, #59 |
| `typing-drills-overlay` | P2 | done | codex | docs/status/2025-12-03_typing_drills_telemetry.md | #19 |
| `enemy-defeat-spriteframes` | P3 | done | codex | docs/status/2025-11-07_enemy_defeat_animation.md | #66 |
| `passive-iconography` | P3 | done | codex | docs/status/2025-11-06_castle_passives.md | #30 |
| `starfield-parallax-effects` | P3 | done | codex | docs/status/2025-11-07_starfield.md | #68, #94 |
| `taunt-catalog-expansion` | P3 | done | codex | docs/status/2025-11-19_enemy_taunts.md | #83, #87 |

## Passive Unlock & Gold Dashboard
- CI smoke & e2e jobs publish `artifacts/summaries/passive-gold*.json` plus a Markdown snippet for `$GITHUB_STEP_SUMMARY`.
- Local dry-run: `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn`.

## Gold Timeline Dashboard
- CI publishes `artifacts/summaries/gold-timeline*.json` alongside percentile/passive summaries; Markdown appears in CI summaries.
- Local dry-run: `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn`.

## Gold Summary Report
- CI publishes `artifacts/summaries/gold-summary-report*.json`; thresholds live in `scripts/ci/gold-percentile-thresholds.json`.
- Local dry-run: `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold/gold-summary-report.json --summary temp/gold-summary-report.fixture.json --mode warn`.

## Gold Analytics Board
- Aggregate gold summary, timeline, passive, guard, and percentile alerts via `node scripts/ci/goldAnalyticsBoard.mjs --summary artifacts/summaries/gold-summary-report.ci.json --timeline artifacts/summaries/gold-timeline.ci.json --passive artifacts/summaries/passive-gold.ci.json --percentile-guard artifacts/summaries/gold-percentile-guard.ci.json --percentile-alerts artifacts/summaries/gold-percentiles.ci.json --out-json artifacts/summaries/gold-analytics-board.ci.json --markdown artifacts/summaries/gold-analytics-board.ci.md`.
- Fixture dry-run: `node scripts/ci/goldAnalyticsBoard.mjs --summary docs/codex_pack/fixtures/gold/gold-summary-report.json --timeline docs/codex_pack/fixtures/gold/gold-timeline-summary.json --passive docs/codex_pack/fixtures/gold/passive-gold-summary.json --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json temp/gold-analytics-board.fixture.json --markdown temp/gold-analytics-board.fixture.md`.
- Baseline guard: `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` (nightly runs fail if coverage is missing).
- Latest board (2025-11-27T04:30:34.847Z) status [PASS] with 1 scenario(s); warnings: 0.
- Baseline guard report missing; run `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn`.
- Timeline baseline: ../../docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json (1/1 matched)

| Scenario | Net delta | Median Gain | Median Spend | Timeline Drift (med/p90) | Baseline Drift (med/p90) | Last Gold delta | Last Passive | Sparkline (delta@t + bars) | Alerts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| tutorial-skip | 175 | 60 | -35 | 0/0 | -10/-40 | -60 @ 75.2s | gold L1 (+1.15) @ 78.2s | -60@75.2, +50@63.1, +75@46.4, -30@22.8, +40@10.5 -*+=+#--+- | [PASS 4] |

## Typing Drills Quickstart Telemetry
- Latest summary (2025-12-01T22:55:13.580Z) scanned 6 telemetry event(s) with 3 drill start(s).
- Menu quickstarts: 2 (recommended 1, fallback 1); share of menu starts: 100%.
- Recommendation mix: recommended 50% | fallback 50%.
- Drill starts by source: menu 2, cta 1; share: menu 0.6666666666666666, cta 0.3333333333333333; modes: burst 2, endurance 1.
- Drill completions: 1 (rate: 33.3%; per-source: -; avg: 96% / 82 wpm; sources: -; modes: burst 1).
- Quickstart reasons: accuracyDip 1, fallback 1; modes: burst 2.

| Timestamp | Mode | Recommendation | Reason |
| --- | --- | --- | --- |
| 2025-12-03T02:40:00.000Z | burst | fallback | fallback |
| 2025-12-02T02:40:00.000Z | burst | recommended | accuracyDip |

## UI Snapshot Gallery

| Shot | Starfield | Summary |
| --- | --- | --- |
| diagnostics-overlay | warning | Diagnostics overlay expanded with all sections visible; HUD and options panels expanded |
| hud-main | tutorial | Compact viewport; Tutorial banner condensed; HUD passives collapsed; HUD gold events collapsed; Diagnostics condensed; Diagnostics sections — gold-events:collapsed, castle-passives:expanded |
| options-overlay | warning | Default viewport; HUD passives expanded; HUD gold events expanded; Options passives collapsed; Diagnostics expanded; Diagnostics sections — turret-dps:collapsed |
| shortcut-overlay | tutorial | Shortcut overlay displayed while diagnostics sections remain collapsed |
| tutorial-summary | tutorial | Default viewport; Tutorial summary expanded; HUD + options panels expanded; Diagnostics expanded |
| wave-scorecard | breach | Compact viewport; HUD prefers condensed layout; Diagnostics condensed with turret DPS collapsed |

## Responsive Condensed Audit
- Latest run (2025-11-27T15:17:21.267Z) passed with 30 checks across 7 panels (snapshots scanned: 6).
- No outstanding issues; all required panels/breakpoints are covered.

Generated automatically via `npm run codex:dashboard`.