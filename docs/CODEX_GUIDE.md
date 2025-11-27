# Codex Development Guide

This project is built primarily by Codex. Use this guide as the single entry
point for finding work, running commands, and updating documentation. For
domain-specific checklists (automation, gameplay/UI, analytics), see
`docs/CODEX_PLAYBOOKS.md`.

## 1. Where to find work

1. **Automation tasks** – `docs/codex_pack/manifest.yml` + `task_status.yml`.
   - Follow `docs/codex_pack/CODEX_RUNBOOK.md` to claim and deliver these.
2. **Feature/backlog items** – `apps/keyboard-defense/docs/season1_backlog.md`.
   - Each entry notes the Codex task (when applicable). If a backlog item has no
     task yet, author one via `docs/codex_pack/templates/task.md`.
3. **Historical context** – `docs/status/*.md`. Every status note should end with
   a “Follow-up” (or “Notes”) section linking to the relevant Codex task. When
   you finish work, update the status note accordingly.

## 2. Execution loop

1. Pick the next task/backlog item (see above).
2. Update `docs/codex_pack/task_status.yml` if you’re claiming an automation task.
3. Implement code/tests/scripts exactly as described in the backlog/task/status
   chain.
4. Update documentation:
   - Status notes: add/adjust the Follow-up section with the canonical task link.
   - Backlog: mark the item as done or note the active Codex task.
   - Codex Pack: ensure `manifest.yml`, task file, and `task_status.yml` stay
     in sync (new tasks must include `status_note` + `backlog_refs`).
5. Run the verification checklist (below) before committing.
6. Summarize your changes referencing task IDs/backlog numbers.

## 3. Command checklist

From `apps/keyboard-defense/`:

```bash
npm install
npm run lint
npm run test
npm run codex:validate-pack
npm run codex:validate-links
npm run codex:status
```

Run additional commands listed under each Codex task's `## Verification`
section (e.g., Playwright snapshots, CLI dry-runs with fixtures). For scripts
that require sample data, use the JSON files in `docs/codex_pack/fixtures/`.

> **Audio intensity telemetry** - When driving `node scripts/smoke.mjs` locally, set
> `--audio-intensity <0.5..1.5>` (percent values like `75` are accepted) and optionally
> `--audio-intensity-threshold <percent>` so drift is flagged in the smoke summary. Example:
> `node scripts/smoke.mjs --mode full --audio-intensity 0.95 --audio-intensity-threshold 5 --ci`.
> After the run, inspect `artifacts/summaries/audio-intensity.(json|csv)` or render the Markdown
> table via `node scripts/ci/audioIntensitySummary.mjs --file artifacts/summaries/audio-intensity.json`.
> **Defeat animation sprites** - The pause/options overlay now ships a **Defeat Animations** select (`options-defeat-animation`) so QA can force `auto`, `sprite`, or `procedural` burst rendering. Sprite mode consumes the new `defeatAnimations` manifest entries, procedural sticks with the legacy gradients, and player settings bumped to v15 to persist the choice across sessions.
> **Preview defeat atlases** - Use `npm run defeat:preview -- --animations docs/codex_pack/fixtures/defeat-animations/sample.json` (or `--manifest public/assets/manifest.json` once the art lands) to emit `artifacts/summaries/defeat-animations-preview.(json|md)`. The CLI surfaces frame counts, total duration, fallback chains, and warnings so Codex dashboards can flag malformed sprite drops.

## 4. Documentation rules

- **Status notes** must reference the authoritative Codex task path
  (`docs/codex_pack/tasks/<id>.md`) inside their Follow-up section. If no task
  exists yet, say so explicitly (“Future work will add a Codex task once scoped”).
- **Codex tasks** must include:
  - `status_note`
  - `backlog_refs`
  - `## Steps`, `## Acceptance criteria`, and `## Verification`
  - Links to snippets/fixtures when applicable.
- **Backlog items** should call out the Codex task IDs that deliver them.
- Use `docs/codex_pack/templates/task.md` when drafting new tasks and
  `docs/codex_pack/snippets/verify-task.md` as a starter verification block.

## 5. Tooling & scripts

| Command | Purpose |
| --- | --- |
| `npm run codex:status` | Prints the task → state table. |
| `npm run codex:validate-pack` | Ensures manifest/tasks/tracker are consistent and that only one owner has an in-progress task. |
| `npm run codex:validate-links` | Confirms every status note follow-up points to a real task and every task references an existing status note. |
| `node scripts/ci/emit-summary.mjs --smoke docs/codex_pack/fixtures/smoke-summary.json --gold docs/codex_pack/fixtures/gold-summary.json --condensed-audit docs/codex_pack/fixtures/responsive/condensed-audit.json` | Local dry-run for the CI summary task (now includes condensed audit status/coverage rows when the responsive summary exists). |
| `npm run release:dry-run` | Runs semantic-release locally, generating `artifacts/release/keyboard-defense-<version>.zip` + manifest without publishing. |
| `npm run release` | Publishes via semantic-release (requires `GITHUB_TOKEN`); CI workflow `semantic-release` handles production runs on `master` and `nightly`. |
| `npm run start -- --no-build` | Skip `npm run build` when launching the dev server (or set `DEVSERVER_NO_BUILD=1`). Pair with `--force-restart` to auto-stop an existing `.devserver` instance. |
| `npm run monitor:dev -- --artifact artifacts/monitor/dev-monitor.json --wait-ready` | Poll the dev server independently and write the JSON used by CI summaries/dashboards (latency, uptime, flags). |
| `npm run serve:start-smoke -- --artifact artifacts/monitor/start-smoke.json` | Force-restart/start/stop smoke harness that copies `.devserver/server.log` + JSON summary so CI can guard `npm run start`. |
| `node scripts/smoke.mjs --mode full --audio-intensity 0.95 --audio-intensity-threshold 5 --ci` | Runs the tutorial smoke harness end-to-end, capturing gold summaries plus `artifacts/summaries/audio-intensity.(json|csv)` for telemetry/correlation dashboards. |
| `npm run docs:condensed-audit` | Validates the condensed HUD/options/diagnostics panels listed in `docs/codex_pack/fixtures/responsive/condensed-matrix.yml` against the latest HUD snapshot metadata so CI/docs fail fast when badges regress. |
| `npm run assets:integrity -- --check --mode strict --telemetry artifacts/summaries/asset-integrity.json --telemetry-md artifacts/summaries/asset-integrity.md --history artifacts/history/asset-integrity.log` | Verifies sprite manifest checksums, emits telemetry (counts + first failure) for dashboards/CI, appends each run to the history log, and honors `ASSET_INTEGRITY_MODE`, `ASSET_INTEGRITY_SUMMARY*`, `ASSET_INTEGRITY_SCENARIO`, and `ASSET_INTEGRITY_HISTORY` overrides. |
| `node scripts/ci/assetIntegritySummary.mjs --telemetry artifacts/summaries/asset-integrity.json --history artifacts/history/asset-integrity.log --out-json temp/asset-integrity-report.json --markdown temp/asset-integrity-report.md` | Aggregates the latest telemetry/history entries into a JSON + Markdown summary so Codex dashboards and CI steps can display integrity counts without opening raw logs. |
| `node scripts/ci/traceabilityReport.mjs --test-report artifacts/summaries/vitest-summary.json --out-json temp/traceability.json --mode warn` | Builds the spec→task→test matrix (JSON + Markdown). Use fixture results via `--test-report ../../docs/codex_pack/fixtures/traceability-tests.json` for local dry-runs. |
| `node scripts/ci/goldPercentileGuard.mjs docs/codex_pack/fixtures/gold-summary.json` | Validates percentile metadata before dashboards ingest gold summary artifacts and writes the guard summary JSON/Markdown. |
| `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn` | Generates the passive unlock + gold dashboard summary locally (mirrors the CI passive/gold step). |
| `node scripts/analyticsAggregate.mjs --passive-summary temp/passive-summary.json --passive-summary-csv temp/passive-summary.csv docs/codex_pack/fixtures/passives/sample.json` | Runs the analytics aggregate CLI while also writing passive unlock summaries (JSON/CSV/Markdown via the `--passive-summary*` flags) for dashboards/automation. |
| `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn` | Produces the gold timeline dashboard summary (derived metrics + Markdown) matching the CI step. |
| `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold-summary.json --summary temp/gold-summary-report.fixture.json --percentile-alerts temp/gold-percentiles.fixture.json --mode warn` | Surfaces gold summary metrics (median/p90 gains/spends, net delta) plus the new starfield columns (`starfieldDepth`, `starfieldDrift`, `starfieldWaveProgress`, `starfieldCastleRatio`, `starfieldTint`) and writes the percentile drift payload consumed by `goldAnalyticsBoard`/CI (`artifacts/summaries/gold-percentiles*.json`). |
| `node scripts/ci/audioIntensitySummary.mjs --file artifacts/summaries/audio-intensity.json` | Renders the latest audio intensity telemetry (requested/recorded/avg/correlations, drift %) as a Markdown table for dashboards or PR notes. |
| `node scripts/taunts/validateCatalog.mjs --catalog apps/keyboard-defense/docs/taunts/catalog.json` | Lints the Episode 1 taunt catalog (duplicate ids/text, required tags, rarity) so HUD/analytics stay aligned (task `taunt-catalog-expansion`). |
| `node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach/base.json --summary temp/castle-breach-summary.fixture.json --mode warn` | Aggregates castle breach artifacts (time-to-breach, turret loadouts, warnings) and mirrors the CI Castle Breach Watch tile. |
| `npm run debug:dpr-transition -- --steps 1:960:init,1.5:840:pinch,2:720:zoom --json --markdown temp/dpr-transition.md` | Simulates DPR transitions without a browser, emits the telemetry payloads captured in analytics/CI, and writes a Markdown summary that can be dropped into PR notes or Codex dashboards (task `canvas-dpr-monitor`). |
| `node scripts/ci/goldAnalyticsBoard.mjs --summary <file> --timeline <file> --passive <file> --percentile-guard <file> --percentile-alerts <file> --out temp/gold-analytics-board.fixture.json` | Aggregates the gold summary, timeline, passive, and percentile guard feeds into one Markdown/JSON bundle (now including starfield averages + per-scenario starfield notes) for dashboards and CI summaries (task `gold-analytics-board`). |
| `npm run gold:percentiles:refresh` | Runs the baseline CLI across CI gold summary outputs + fixtures, rewrites `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`, updates `scripts/ci/gold-percentile-thresholds.json`, and emits `artifacts/summaries/gold-percentiles.md` with the refresh timestamp. Append `-- --check` to verify the committed files without writing (task `gold-percentile-baseline-refresh`). |
| `node scripts/ci/diagnosticsDashboard.mjs docs/codex_pack/fixtures/diagnostics-dashboard/sample.analytics.json --summary temp/diagnostics-dashboard.fixture.json --markdown temp/diagnostics-dashboard.fixture.md --mode warn` | Builds the gold delta + passive unlock diagnostics dashboard summary (JSON + Markdown) exactly like the CI step (task `diagnostics-dashboard`). |
| `node scripts/analytics/goldDeltaAggregator.mjs docs/codex_pack/fixtures/gold-delta-aggregates/sample.analytics.json --output temp/gold-delta-aggregates.fixture.json --markdown temp/gold-delta-aggregates.fixture.md --mode warn` | Rolls gold event streams into per-wave aggregates (task `gold-delta-aggregates`). |
| `node scripts/analytics/validate-schema.mjs docs/codex_pack/fixtures/analytics --report temp/analytics-validate.fixture.json --report-md temp/analytics-validate.fixture.md --mode warn` | Validates analytics snapshots against the JSON Schema, emitting JSON + Markdown summaries; use `--mode warn` for local triage and default `fail` in CI (task `schema-contracts`). |
| `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots --starfield-scene tutorial` | Captures deterministic HUD/Tutorial screenshots, forces the requested starfield tint (`tutorial|warning|breach`), and writes `*.meta.json` sidecars (condensed state, taunt details, starfield badges) for docs/hud_gallery.md + CI summaries. |
| `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --output docs/hud_gallery.md --json artifacts/summaries/ui-snapshot-gallery.json --verify` | Rebuilds the HUD screenshot gallery, emits a JSON summary for dashboards, and fails when required screenshots/badges are missing. |
| `npm run docs:verify-hud-snapshots -- --meta artifacts/screenshots ../../docs/codex_pack/fixtures/ui-snapshot` | Runs the HUD metadata verifier and, via the chained condensed audit, ensures every required panel/breakpoint badge from `docs/codex_pack/fixtures/responsive/condensed-matrix.yml` remains covered; emits `artifacts/summaries/condensed-audit.(json|md)` so CI and dashboards can surface the results. |
| `npx playwright test --config playwright.config.ts --project=visual --grep \"hud-main|options-overlay|tutorial-summary|wave-scorecard\"` | Visual verification for HUD screenshots. |

### Nightly dashboard refresh

- Workflow `codex-dashboard-nightly` runs daily at 05:30 UTC (or on dispatch) to regenerate `docs/codex_dashboard.md` and `docs/CODEX_PORTAL.md` from the gold board fixtures, keeping the portal starfield telemetry tile current without manual runs.
- To use live artifacts instead of fixtures, dispatch the workflow with inputs (`summary`, `timeline`, `passive`, `guard`, `alerts`) pointing at real paths once CI produces them.

### Spark bars (gold analytics board)

- Spark bars sit next to the `delta@t` sparkline in Markdown and the portal. Characters scale against the largest absolute delta: `. :- = * #` (smallest to largest), prefixed with `+`/`-` for direction.
- Example: `-60@75, +50@63, +75@46, +10@30 -*+=+#+.` reads as a large spend, medium gain, peak gain, then a tiny gain.
- Everything stays ASCII so CI summaries and GitHub step logs render cleanly.

### Starfield severity badges

- Starfield rows in the gold board/portal now carry `CALM/WARN/BREACH` badges based on castle ratio thresholds (breach < 50%, warn < 65% by default).
- Severity appears at the start of each starfield note and in the summary bullet so castle damage drift is visible without opening artifacts.
- Override thresholds when running the board via `--castle-warn <percent>` / `--castle-breach <percent>` (or env `GOLD_STARFIELD_WARN` / `GOLD_STARFIELD_BREACH`) to match new economy cutlines.

## 6. CI expectations

- Mirror the local checklist inside GitHub Actions (see
  `docs/codex_pack/snippets/status-ci-step.md`). Codex commits should never
  bypass these checks.
- When adding new workflows, include a `Validate Codex Pack/Links/Status`
  block so automation fails fast if documentation drifts.

Keep this guide updated whenever the process changes. If Codex needs new
fixtures, commands, or templates, add them here and in the relevant scripts so
future automation can rely on the documented contract.
