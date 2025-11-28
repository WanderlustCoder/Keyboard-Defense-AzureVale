# Codex Playbooks

Use these playbooks when tackling new work. Each section maps a type of work to
the relevant docs, Codex tasks, verification commands, and documentation
expectations.

## Automation & CI Playbook

- **Read first**: `docs/codex_pack/README.md`, `docs/codex_pack/CODEX_RUNBOOK.md`.
- **Typical flow**
  1. Pick the highest-priority task from `docs/codex_pack/manifest.yml`.
  2. Claim it in `docs/codex_pack/task_status.yml` (`state: in-progress` and your
     owner id).
  3. Follow the task instructions (snippets + fixtures live under
     `docs/codex_pack/snippets` and `docs/codex_pack/fixtures`).
  4. Run verification:
     ```bash
     npm run lint
     npm run test
     npm run codex:validate-pack
     npm run codex:validate-links
     npm run codex:status
     ```
     plus any task-specific commands listed under `## Verification`.
  5. Update documentation (status note follow-up, backlog reference, manifest,
     task file, tracker).
  6. Commit with the task id/backlog number in the message.
- **CI**: ensure `.github/workflows/ci-e2e-azure-vale.yml` contains the Codex
  validation block (see `docs/codex_pack/snippets/status-ci-step.md`).
- **Dev server harness**: run `npm run serve:start-smoke -- --artifact temp/start-smoke.json --log temp/start-smoke.log` after touching `scripts/devServer.mjs` so you can reproduce the same readiness/stop guard CI executes. If `http-server` resolution fails locally, inspect `.devserver/resolution-error.json` for attempted paths and quick fixes.
- **Nightly dispatch**: trigger scheduled runs manually when needed:
  - `gh workflow run ci-matrix-nightly.yml --ref master` (runs scenario matrix + asset integrity + HUD gallery + condensed audit).
  - `gh workflow run codex-dashboard-nightly.yml --ref master` (rebuilds Codex dashboard/portal from live CI artifacts or fixtures).
  - See `docs/nightly_ops.md` for artifact expectations and quick recovery commands.
  - Need artifacts without rerunning? `npm run ci:download-artifacts -- --workflow ci-matrix-nightly.yml --name ci-matrix-summary --name codex-dashboard-nightly` (requires `gh` auth).

### Semantic Release (task `semantic-release`)

1. **Prep + scope**
   - Read `docs/status/2025-11-21_semantic_release.md` and `docs/codex_pack/tasks/06-semantic-release.md`.
   - Ensure `.github/workflows/release.yml` mirrors the local checklist (lint/test/codex validation before publishing).
2. **Local dry-run**
   ```bash
   npm run release:dry-run
   ls artifacts/release
   ```
   - Inspect the generated `keyboard-defense-<version>.zip` and `release-manifest-<version>.json` before tagging/merging.
3. **CI publishing**
   - CI sets `GITHUB_TOKEN` and runs `npm run release` automatically on `master` (stable) and `nightly` (prerelease channel).
   - The `scripts/packageRelease.mjs` hook captures the static bundle + docs so GitHub releases always ship a downloadable zip + checksum manifest.
4. **Artifacts + docs**
   - Update `CHANGELOG.md` via semantic-release (`@semantic-release/changelog` + git plugin commit the entry).
   - Reference the release status note in `docs/docs_index.md` and Codex dashboards when the workflow changes.
5. **Verification checklist**
   ```bash
   npm run lint
   npm run test
   npm run codex:validate-pack
   npm run codex:validate-links
   npm run release:dry-run
   ```

### Traceability Report (task `ci-traceability-report`)

1. **Prep**
   - Read `docs/status/2025-11-06_ci_pipeline.md` and the task file `docs/codex_pack/tasks/14-ci-traceability-report.md`.
   - Add `traceability.tests` metadata to the Codex tasks you touch so backlog IDs inherit explicit test files + commands.
2. **Local dry-run**
   ```bash
   node scripts/ci/traceabilityReport.mjs \
     --test-report ../../docs/codex_pack/fixtures/traceability-tests.json \
     --out-json temp/traceability.fixture.json \
     --out-md temp/traceability.fixture.md \
     --mode warn
   ```
3. **CI integration**
   - `ci-e2e-azure-vale.yml` now runs `npx vitest run --reporter=json --outputFile artifacts/summaries/vitest-summary-nodeXX.json` after coverage, feeding `npm run ci:traceability`.
   - Node 20 matrix appends `artifacts/summaries/traceability-report-node20.md` to `$GITHUB_STEP_SUMMARY` and uploads the JSON.
4. **Extensibility**
   - Point `--test-report` at additional summaries (Playwright, smoke CLI, dashboards) to surface UI/E2E coverage.
   - Filters (`--filter "#53,#71"`) help debug isolated backlog entries without parsing the full manifest.
5. **Verification**
   ```bash
   npm run lint
   npm run test -- traceabilityReport
   npm run codex:validate-pack
   npm run codex:validate-links
   node scripts/ci/traceabilityReport.mjs --manifest docs/codex_pack/manifest.yml --backlog apps/keyboard-defense/docs/season1_backlog.md --test-report artifacts/summaries/vitest-summary.json --out-json temp/traceability.json
   ```

## Gameplay & UI Playbook

- **Docs to read**
  - `docs/status/2025-11-17_hud_condensed_lists.md`
  - `docs/status/2025-11-17_responsive_layout.md`
  - `apps/keyboard-defense/docs/season1_backlog.md` (UI/backlog numbers)
- **Implementation steps**
  1. Identify the backlog item (e.g., #53 responsive layout). If no Codex task
     exists, create one via `docs/codex_pack/templates/task.md`.
  2. Update `docs/status/<date>_*.md` with both the change summary and a
     Follow-up reference to the Codex task.
  3. When defeat animation work is involved, use the pause/options **Defeat Animations** select (`options-defeat-animation`) to verify auto/sprite/procedural modes persist via player settings v15 and that diagnostics/CI artifacts still report sprite/procedural burst counts for each mode.
  4. Preview defeat atlas metadata via `npm run defeat:preview -- --manifest public/assets/manifest.json` (or point at fixtures under `docs/codex_pack/fixtures/defeat-animations/`) so reviewers get JSON + Markdown summaries of frame counts, total duration, fallbacks, and warnings before shipping new art.
  5. Modify code/tests under `apps/keyboard-defense/src/ui`, `public/styles.css`,
     etc.
  6. Run:
     ```bash
     npm run lint
     npm run test
     npm run codex:validate-pack
     npm run codex:validate-links
     ```
     plus any Playwright/HUD screenshot commands relevant to the change.
  7. Capture before/after context in the task file if needed (link screenshots or
     artifacts).
- **Artifacts**: for visual work, use `node scripts/hudScreenshots.mjs --ci --starfield-scene tutorial`
  (swap `tutorial|warning|breach` as needed) to capture all six required shots
  (`hud-main`, `diagnostics-overlay`, `options-overlay`, `shortcut-overlay`, `tutorial-summary`,
  `wave-scorecard`) or the Playwright visual tests once `visual-diffs` lands.
  When new screenshots are captured, refresh `docs/hud_gallery.md` via
  `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --meta artifacts/screenshots`
  so the gallery dedupes fixture/live sources and lists every `.meta.json` under
  each shot. The `--starfield-scene` flag locks the parallax tint for
  reproducible baselines; omit it or pass `auto` when you want the live
  gameplay-driven starfield back.
- **Responsive condensed checklist**: keep `docs/codex_pack/fixtures/responsive/condensed-matrix.yml`
  in sync with any HUD/options/diagnostics changes. `npm run docs:verify-hud-snapshots`
  now chains the condensed audit automatically; use `npm run docs:condensed-audit`
  (backs `scripts/docs/condensedAudit.mjs`) for faster dry-runs while iterating on snapshots.
  The audit writes `artifacts/summaries/condensed-audit.(json|md)` so dashboards and CI (`scripts/ci/emit-summary.mjs`) can surface the latest pass/fail status without re-running the script.

### Audio Intensity Telemetry (task `audio-intensity-telemetry`)

1. **Scope**
   - Read `docs/status/2025-11-16_audio_intensity_slider.md` for the UX/telemetry background.
   - Track requirements via `docs/codex_pack/tasks/23-audio-intensity-telemetry.md`.
2. **Implementation outline**
   - Thread `--audio-intensity` and `--audio-intensity-threshold` through `scripts/smoke.mjs`
     so automation explicitly records slider targets, drift, and history.
   - Persist the summary payload (`artifacts/summaries/audio-intensity.(json|csv)`) and expose it
     via `node scripts/ci/audioIntensitySummary.mjs`.
   - Extend analytics exports (`analyticsAggregate.mjs` + schema/tests) so dashboards can plot
     average intensity, deltas, and combo/accuracy correlations per session.
3. **Verification commands**
   ```bash
   node scripts/smoke.mjs --mode full --audio-intensity 0.95 --audio-intensity-threshold 5 --ci
   npm run test -- tutorialSmoke
   npm run test -- analyticsAggregate
   node scripts/ci/audioIntensitySummary.mjs --file artifacts/summaries/audio-intensity.json
   ```
4. **Artifacts**
   - `artifacts/summaries/audio-intensity.ci.json|csv` (fed into CI dashboards + Codex Portal).
   - Updated analytics CSV columns (`audioIntensitySamples`, `audioIntensityAvg`, etc.) for downstream dashboards.

### Canvas DPR Monitor & Transitions (task `canvas-dpr-monitor`)

1. **Files to touch**
   - `apps/keyboard-defense/src/ui/canvasResolution.ts` (helpers)
   - `apps/keyboard-defense/src/ui/diagnostics.ts` (HUD overlays)
   - `apps/keyboard-defense/src/controller/gameController.ts` (player settings)
   - `apps/keyboard-defense/src/config/ui.ts` (tuning knobs)
2. **Implementation outline**
   - Register `matchMedia("(resolution: Xdppx)")` listeners that call
     `calculateCanvasResolution` whenever `devicePixelRatio` changes. Debounce
     events so pinch/zoom doesn’t thrash renders.
   - Introduce a `ResolutionTransitionController` that captures the previous
     frame, fades it out (≈150 ms), and applies a hold period so overlays never
     “pop” mid-wave.
   - Persist the latest DPR multiplier + resolved HUD layout in player settings (`lastDevicePixelRatio`, `lastHudLayout`) and emit a telemetry event (`ui.canvasResolutionChanged`) via `analyticsAggregate`.
   - Surface the responsive metadata in `analyticsAggregate` (new `uiHudLayout`, `uiResolution*`, `uiPrefDevicePixelRatio`, `uiPrefHudLayout` columns) so dashboards/tests can assert transitions.
3. **Testing**
   - Add Vitest coverage for the DPR listener (mock `matchMedia` + timers).
   - Extend analytics tests to assert the telemetry payload.
   - Optionally add a DOM/Vitest test to confirm fade classes toggle as expected.
4. **Verification commands**
   ```bash
   npm run lint
   npm run test -- canvasResolution
   npm run test -- analyticsAggregate
   npm run codex:validate-pack
   npm run codex:validate-links
   npm run codex:status
   ```
   Then manually tweak zoom/devicePixelRatio in the browser to confirm smoother
   transitions.

## Analytics & Telemetry Playbook

- **Docs to read**
  - `docs/analytics_schema.md`
  - Gold/telemetry status notes (`docs/status/2025-11-08_gold_summary_cli.md`,
    `docs/status/2025-11-14_gold_summary_ci_guard.md`, etc.)
- **Execution**
  1. Locate the backlog item (#76 schema contracts, #101+ for gold metrics).
  2. Ensure a Codex task exists (e.g., `schema-contracts`, `ci-guards`).
  3. Update status notes with Follow-up links when creating new automation work.
  4. Run data validators/dry-runs (Ajv scripts, goldSummary CLI) plus the core
     command checklist.
    - Use `node scripts/ci/goldPercentileGuard.mjs artifacts/smoke` to verify
      gold summary artifacts before dashboards ingest them; the guard writes
      `artifacts/summaries/gold-percentile-guard*.json` + Markdown so CI
      summaries stay in sync.
    - Run `node scripts/ci/passiveGoldDashboard.mjs artifacts/smoke --summary artifacts/summaries/passive-gold.local.json --mode warn`
      to reproduce the passive unlock + gold dashboard output locally; CI uploads
      the resulting `artifacts/summaries/passive-gold*.json` files alongside the
      tutorial smoke and e2e bundles.
    - Need a fast passive unlock table/Markdown card without the full dashboard CLI? Add `--passive-summary <json> [--passive-summary-csv <csv>] [--passive-summary-md <md>]` to the `analyticsAggregate` invocation so the existing aggregation step writes `artifacts/summaries/passive-analytics.*`.
    - Use `node scripts/ci/goldTimelineDashboard.mjs artifacts/smoke --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --summary artifacts/summaries/gold-timeline.local.json --mode warn`
      to regenerate the derived gold timeline dashboard (net delta, spend streaks, recent events) and compute drift vs the committed percentile baselines (this keeps the analytics board baseline column populated).
    - Run `node scripts/ci/goldSummaryReport.mjs artifacts/smoke/gold-summary.ci.json --summary artifacts/summaries/gold-summary-report.local.json --percentile-alerts artifacts/summaries/gold-percentiles.local.json --mode warn`
      to mirror the CI gold summary dashboard (median/p90 gains & spends, thresholds) and emit the percentile drift payload used by `goldAnalyticsBoard`. Update baselines via `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`
      and thresholds via `scripts/ci/gold-percentile-thresholds.json` when economy expectations shift.
    - If the gold analytics board warns about missing baselines, rerun the timeline dashboard with `--baseline <path>` and pass the same file to `goldAnalyticsBoard.mjs --timeline-baseline <path>` so the baseline drift column populates cleanly.
    - Use `node scripts/ci/diagnosticsDashboard.mjs docs/codex_pack/fixtures/diagnostics-dashboard/sample.analytics.json --summary temp/diagnostics-dashboard.fixture.json --markdown temp/diagnostics-dashboard.fixture.md --mode warn`
      to preview the diagnostics dashboard (gold delta trend + passive timeline) before committing changes.
    - Run `node scripts/analytics/goldDeltaAggregator.mjs docs/codex_pack/fixtures/gold-delta-aggregates/sample.analytics.json --output temp/gold-delta-aggregates.fixture.json --markdown temp/gold-delta-aggregates.fixture.md --mode warn`
      to regenerate the per-wave gold delta report used by docs/dashboards (task `gold-delta-aggregates`).
    - Run `node scripts/analyticsAggregate.mjs artifacts/smoke` (or fixtures) to verify `comboWarningCount`, `comboWarningDelta*`, and `comboWarningHistory` columns, then `node scripts/ci/emit-summary.mjs --tutorial artifacts/smoke/smoke-summary.json` to confirm CI will surface the warning count/avg/worst deltas.
    - Validate snapshot structure via `node scripts/analytics/validate-schema.mjs docs/codex_pack/fixtures/analytics ./artifacts/analytics --report temp/analytics-validate.local.json --report-md temp/analytics-validate.local.md --mode warn` so schema regressions fail locally before CI (switch to the default `fail` mode inside workflows). This command feeds both artifacts into dashboards for task `schema-contracts`.
    - Reproduce DPR transitions without a browser via `npm run debug:dpr-transition -- --steps 1:960:init,1.5:840:pinch,2:720:zoom --json` so telemetry payloads (`ui.canvasResolutionChanged`) and analytics fixtures can be refreshed deterministically (task `canvas-dpr-monitor`).
    - Capture HUD screenshots (`node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots --starfield-scene breach`) after taunt/UI changes and confirm each `.meta.json` contains the `taunt` block and starfield scene badge so docs/hud_gallery.md and the Codex dashboard surface the active callout without inspecting raw JSON.
    - Verify snapshot metadata via `cd apps/keyboard-defense && npm run docs:verify-hud-snapshots -- --meta artifacts/screenshots ../../docs/codex_pack/fixtures/ui-snapshot` so diagnostics collapsed-sections + prefs remain present before regenerating docs/hud_gallery.md or pushing to CI.
    - Rebuild both docs + JSON gallery outputs via `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --meta artifacts/screenshots --verify --json artifacts/summaries/ui-snapshot-gallery.json` so the Codex Portal (JSON) and docs stay in sync.
 5. Keep fixtures/sample artifacts under `docs/codex_pack/fixtures` for future
     runs.

### Gold Analytics Board (task `gold-analytics-board`)

1. **Scope review** – read the Nov-20 gold status notes plus
   `docs/codex_pack/tasks/38-gold-analytics-board.md` to understand how the
   summary, timeline, passive, and percentile feeds should merge.
2. **Local dry-run** – stitch fixtures together before touching the CI pipeline:
   ```bash
   node scripts/ci/goldAnalyticsBoard.mjs \
     --summary docs/codex_pack/fixtures/gold/gold-summary-report.json \
     --timeline docs/codex_pack/fixtures/gold/gold-timeline-summary.json \
     --passive docs/codex_pack/fixtures/gold/passive-gold-summary.json \
     --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json \
     --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
     --out-json temp/gold-analytics-board.fixture.json \
     --markdown temp/gold-analytics-board.fixture.md \
     --mode warn
   ```
   The CLI emits both Markdown and JSON (`artifacts/summaries/gold-analytics-board*.{json,md}`) so CI can attach a single dashboard tile per run—verify the resulting Markdown includes the starfield aggregate bullet (`Starfield avg depth: ...`) and the per-scenario `Starfield` column before shipping changes.
   Run the baseline guard alongside the board to catch missing baseline rows:  
   `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn`.
3. **Dashboard wiring** - update `docs/codex_dashboard.md` plus CI workflows to
   publish the aggregated Markdown in `$GITHUB_STEP_SUMMARY`.
4. **Sparkline legend** - the board table surfaces `delta@t` plus an ASCII bar strip
   scaled to the largest recent delta (e.g., `+50@63.1, +75@46.4 ... ++=**`).
   Positive bars are prefixed with `+`, negatives with `-`, and zero/unknown with
   a leading space. Keep output ASCII-only for CI summaries and portals.
5. **Documentation** - list the new command and artifacts inside the Guide,
   Playbooks, and affected status notes. Keep `docs/codex_pack/task_status.yml`
   synced while implementing.

### Taunt Catalog Expansion (task `taunt-catalog-expansion`)

1. **Catalog updates** – edit `apps/keyboard-defense/docs/taunts/catalog.json`
   so every Episode 1 boss/elite/affix has at least two entries (unique ids,
   lore tags, optional `voiceLineId`). Document additions in
   `apps/keyboard-defense/docs/taunts/README.md`.
2. **Validation** – run `npm run taunts:validate` (or
   `node scripts/taunts/validateCatalog.mjs --catalog apps/keyboard-defense/docs/taunts/catalog.json`)
   to ensure there are no duplicate ids/text and every entry contains the
   required tags. Wire the CLI into CI as needed.
3. **Game config** – import `getTauntText` inside `src/core/config.ts` and wire
   catalog entries into tier taunt pools/wave spawns. Boss/affix showcases
   should set `taunt` strings explicitly so HUD + analytics capture the IDs.
4. **Tests + docs** – add Vitest coverage (`tests/tauntsCatalog.test.js`) to
   keep the catalog/CLI honest and refresh
   `docs/status/2025-11-19_enemy_taunts.md` with a summary of the new lines.

### Gold Percentile Baseline Refresh (task `gold-percentile-baseline-refresh`)

1. **Inputs** - gather the latest gold analytics outputs (smoke/e2e summary,
   timeline, passive) or rely on the default sources baked into the CLI
   (`artifacts/summaries/gold-summary-report*.json` plus the fixtures under
   `docs/codex_pack/fixtures/gold/`).
2. **Generator CLI** - run `npm run gold:percentiles:refresh` to aggregate the
   summaries, rewrite `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`,
   update `apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json`, and
   emit the Markdown snapshot (`artifacts/summaries/gold-percentiles.md`). Append
   `-- --check` to verify the committed files without writing.
3. **Threshold tuning** - pass `--delta abs=25` / `--delta pct=0.25` /
   `--delta medianGain:abs=15,pct=0.25` to tighten defaults when refreshing,
   then re-run the guard locally via
   `node scripts/ci/goldPercentileGuard.mjs artifacts/smoke`.
4. **Docs + status** - update `docs/status/2025-11-20_gold_percentile_alerts.md`,
   `CODEX_GUIDE.md`, and `docs/codex_dashboard.md` with the refresh procedure
   and the timestamp of the latest baseline.

### Castle Breach Analytics (task `castle-breach-analytics`)

1. **Prereqs**
   - Read `docs/status/2025-11-06_castle_breach_replay.md` and
     `docs/codex_pack/tasks/29-castle-breach-analytics.md`.
   - Ensure fixtures exist under `docs/codex_pack/fixtures/castle-breach/`.
2. **CLI instrumentation**
   - Extend `scripts/castleBreachReplay.mjs` with `--turret slot:type`,
     repeatable `--enemy` flags, and derived metrics (`timeToBreachMs`,
     `castleHpDelta`, `damageSource`, etc.).
   - Persist CLI options + metrics inside `artifacts/castle-breach*.json`.
3. **Summary generator**
   - Implement `scripts/ci/castleBreachSummary.mjs` that accepts one or more
     breach artifacts/fixtures, emits normalized JSON
     (`artifacts/summaries/castle-breach.ci.json`), and prints Markdown suitable
     for `$GITHUB_STEP_SUMMARY`. Support `--mode warn|fail` and thresholds like
     `--max-time-to-breach-ms`.
4. **CI/docs wiring**
   - Update `.github/workflows/ci-e2e-azure-vale.yml` to run the summary script
     after `npm run task:breach`, upload the JSON, and append Markdown.
   - Add a “Castle Breach Watch” tile to `docs/codex_dashboard.md`, plus
     guidance in `docs/CODEX_GUIDE.md`/`README.md`.
5. **Verification commands**
   ```bash
   node scripts/castleBreachReplay.mjs --seed 2025 --lane 1 --artifact temp/castle-breach.fixture.json --no-artifact
   node scripts/castleBreachReplay.mjs --seed 1337 --turret slot-2:arcane@2 --enemy brute:2 --enemy witch:1 --artifact temp/castle-breach-turrets.fixture.json --no-artifact
   node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach --summary temp/castle-breach-summary.fixture.json --mode warn
   npx vitest run tests/castleBreachReplay.test.js tests/castleBreachSummary.test.js
   npm run codex:validate-pack
   npm run codex:validate-links
   npm run codex:status
   ```

## Documentation & Status Playbook

- Every status note must end with a **Follow-up** block that lists the canonical
  Codex tasks using the `docs/codex_pack/tasks/<id>.md` path.
- When a Follow-up has no task yet, note that explicitly (“Future work will add
  a Codex task once scoped”) so the validator passes.
- Backlog entries should reference Codex task ids using the format
  `*(Codex: \`task-id\`)*`.
- Before committing documentation changes:
  ```bash
  npm run codex:validate-pack
  npm run codex:validate-links
  npm run codex:status
  ```
- Use `docs/CODEX_GUIDE.md` for the global workflow, while
  `docs/codex_pack/README.md` + task files cover the automation-specific
  details.

## Submission Checklist (all work)

1. `npm run lint`
2. `npm run test`
3. `npm run codex:validate-pack`
4. `npm run codex:validate-links`
5. `npm run codex:status` (ensure only one task is `in-progress` per owner)
6. Task-specific verification commands (Playwright, CLI fixtures, etc.)
7. Status note Follow-up links updated
8. Backlog references updated
9. `docs/codex_pack/task_status.yml` updated (if automation task)

Keep this file updated whenever new domains or workflows are added. The goal is
for Codex to follow these playbooks without human intervention.
