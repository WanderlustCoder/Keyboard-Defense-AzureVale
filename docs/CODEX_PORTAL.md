# Codex Portal

This portal consolidates every instruction set, script, and artifact Codex needs
to develop Keyboard Defense end-to-end. Use it as your starting point each time
you work on the project.

## Quick links

| Area | Doc |
| --- | --- |
| Global workflow | `docs/CODEX_GUIDE.md` |
| Domain playbooks (automation, UI, analytics, docs) | `docs/CODEX_PLAYBOOKS.md` |
| Automation tasks & snippets | `docs/codex_pack/` |
| Codex dashboard (live status) | `docs/codex_dashboard.md` |
| HUD screenshot gallery + JSON badges | `docs/hud_gallery.md` |
| Backlog | `apps/keyboard-defense/docs/season1_backlog.md` |
| Status notes | `docs/status/` |

## Command dashboard

```bash
# Install dependencies
npm ci
cd apps/keyboard-defense
npm ci

# Core Codex checks
npm run lint
npm run test
npm run codex:validate-pack
npm run codex:validate-links
npm run codex:status
npm run codex:dashboard
npm run codex:next        # prints the next TODO task

# CI summary dry-run (surfaces audio intensity + condensed audit rows)
node scripts/ci/emit-summary.mjs --smoke docs/codex_pack/fixtures/smoke-summary.json --gold docs/codex_pack/fixtures/gold-summary.json --condensed-audit docs/codex_pack/fixtures/responsive/condensed-audit.json

# HUD gallery refresh (after `node scripts/hudScreenshots.mjs ...`)
# runs HUD metadata checks + condensed audit
npm run docs:verify-hud-snapshots -- --meta artifacts/screenshots ../../docs/codex_pack/fixtures/ui-snapshot
npm run docs:gallery
# condensed audit summary lives at apps/keyboard-defense/artifacts/summaries/condensed-audit.(json|md)

# Responsive condensed audit (standalone dry-run)
npm run docs:condensed-audit

# Releases (semantic-release)
npm run release:dry-run   # generates artifacts/release/* locally without publishing
npm run release           # requires GITHUB_TOKEN; CI workflow handles production publishes

# Traceability
npm run ci:traceability -- --test-report artifacts/summaries/vitest-summary.json --out-json temp/traceability.json
npm run ci:traceability -- --test-report ../../docs/codex_pack/fixtures/traceability-tests.json --out-json temp/traceability.fixture.json --out-md temp/traceability.fixture.md

# Dev server flags
npm run start -- --no-build        # skip npm run build once (set DEVSERVER_NO_BUILD=1 for repeats)
npm run start -- --force-restart   # stop the background http-server before starting a new one
npm run monitor:dev -- --artifact artifacts/monitor/dev-monitor.json --wait-ready
npm run serve:start-smoke -- --artifact artifacts/monitor/start-smoke.json --log artifacts/monitor/start-smoke.log
node scripts/smoke.mjs --mode full --audio-intensity 0.95 --audio-intensity-threshold 5 --ci
node scripts/ci/audioIntensitySummary.mjs --file artifacts/summaries/audio-intensity.json

# Gold analytics board (local dry-run)
node scripts/ci/goldAnalyticsBoard.mjs \
  --summary docs/codex_pack/fixtures/gold/gold-summary-report.json \
  --timeline docs/codex_pack/fixtures/gold/gold-timeline-summary.json \
  --passive docs/codex_pack/fixtures/gold/passive-gold-summary.json \
  --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json \
  --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
  --out-json temp/gold-analytics-board.fixture.json \
  --markdown temp/gold-analytics-board.fixture.md
```

Run all commands from `apps/keyboard-defense/` unless noted. Release commands expect `GITHUB_TOKEN` when publishing; prefer `release:dry-run` locally and let CI own `npm run release`. Traceability commands reference `artifacts/summaries/vitest-summary*.json`, which CI now produces via the Vitest JSON reporter (dry-runs can rely on `docs/codex_pack/fixtures/traceability-tests.json`). Dev-server commands respect `.devserver/state.json` and emit monitor/start-smoke summaries under `artifacts/monitor/*.json`.

## Gold Analytics Snapshot
<!-- GOLD_ANALYTICS_BOARD:START -->

_Re-run `npm run codex:dashboard` after `npm run analytics:gold:report` to refresh this table with the latest CI artifacts._
Generated: 2025-11-15T15:14:49.341Z ([PASS], warnings: 0)
Starfield avg depth: 1.35, drift: 1.15, wave: 52.5%, castle: 70%, last tint: #fbbf24

| Scenario | Net delta | Median Gain | Median Spend | Starfield | Last Gold delta | Last Passive | Sparkline (delta@t + bars) | Alerts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| tutorial-skip | 175 | 60 | -35 | depth 1.35 / drift 1.15 / 52.5% wave / 70% castle / #fbbf24 | -60 @ 75.2s | gold L1 (+1.15) @ 78.2s | - | [PASS 4] |

Artifacts: `artifacts/summaries/gold-analytics-board.ci.json`
<!-- GOLD_ANALYTICS_BOARD:END -->

## HUD Snapshot Summary
<!-- UI_SNAPSHOT_GALLERY:START -->

_Re-run `npm run docs:gallery` after capturing screenshots, then `npm run codex:dashboard` to refresh this HUD snapshot summary._
Generated: 2025-11-14T22:29:35.250Z (shots: 8)

| Shot | Starfield | Summary |
| --- | --- | --- |
| hud-main | tutorial | Tutorial banner expanded; HUD passives expanded; HUD gold events expanded; Diagnostics sections collapsed |
| hud-main | tutorial | Compact viewport; Tutorial banner condensed; HUD passives collapsed; HUD gold events collapsed; Diagnostics condensed; Diagnostics sections — gold-events:collapsed, castle-passives:expanded |
| options-overlay | warning | Tutorial banner expanded; HUD passives expanded; HUD gold events expanded; Diagnostics sections collapsed |
| options-overlay | warning | Default viewport; HUD passives expanded; HUD gold events expanded; Options passives collapsed; Diagnostics expanded; Diagnostics sections — turret-dps:collapsed |
| tutorial-summary | tutorial | Tutorial banner expanded; HUD passives expanded; HUD gold events expanded; Diagnostics sections collapsed |
| ... | ... | 3 more entries |

Artifacts: `apps/keyboard-defense/artifacts/summaries/ui-snapshot-gallery.json`
<!-- UI_SNAPSHOT_GALLERY:END -->

## Task lifecycle

1. `npm run codex:next` → identifies the highest-priority TODO task.
2. Claim it in `docs/codex_pack/task_status.yml`.
3. Follow the task file under `docs/codex_pack/tasks/`.
4. Apply any domain-specific steps from `docs/CODEX_PLAYBOOKS.md`.
5. Run the command dashboard + task-specific verification.
6. Update status note Follow-up links, backlog references, Codex metadata, and regenerate the dashboard (`npm run codex:dashboard`).
7. Commit with task/backlog references.

## Fixtures & snippets

- Automation CLI dry-runs: `docs/codex_pack/fixtures/*.json`
- Audio telemetry fixtures: `docs/codex_pack/fixtures/audio-intensity/`
- CI snippet: `docs/codex_pack/snippets/status-ci-step.md`
- Verification boilerplate: `docs/codex_pack/snippets/verify-task.md`
- Task template: `docs/codex_pack/templates/task.md`

Keep this portal updated when new guides, playbooks, or scripts are added so
Codex always has a single navigation surface.
