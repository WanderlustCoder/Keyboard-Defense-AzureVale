# Keyboard Defense

Keyboard Defense is a typing program inspired by classic edutainment (think Mavis Beacon). The castle defense layer is a playful backdrop that helps gauge typing performance; the core goal is to build accuracy, speed, and consistency. The playable app lives under `apps/keyboard-defense/` and is written in TypeScript, compiled to an ES module bundle for the browser.

## Features

- Typing-first training loop with drills and practice modes; the castle defense layer is a progress gauge, not the end goal.
- Deterministic game engine for repeatable playtests and automation.
- Upgradeable castle and turret archetypes (arrow, arcane, flame) with unique behaviors.
- Passive castle buffs (regen, armor, gold bonus) unlock as you upgrade and surface in HUD/options overlays.
- Castle upgrade panel keeps a running log of the last few gold events (delta, total, timestamp) so sudden economy swings are visible without opening diagnostics.
- Save and apply turret loadout presets with gold-cost previews for rapid experimentation.
- Crystal Pulse turret archetype (feature toggle) that deals bonus shield damage to counter barrier-heavy waves.
- Analytics tracking for wave summaries, accuracy, breaches, and DPS.
- HUD with combo tracking, battle log, resource deltas, and an upcoming-enemy preview panel sourced from the wave scheduler.
- Asset manifest with SHA-256 integrity hashes; sprites fail closed when tampering or corruption is detected at load time.
- Debug overlay and `window.keyboardDefense` hooks for runtime inspection and mutation.
- Optional Web Audio feedback for projectile launches, impacts, breaches, and upgrades.
- Dynamic music suites that layer stems by castle danger with an options overlay picker/preview.
- Refreshed SFX library with selectable palettes and an options overlay preview.
- Procedural enemy defeat bursts with easing-driven gradients so kills feel readable even before bespoke sprites ship.
- Accessibility and comfort toggles for reduced motion, readable fonts, adjustable HUD scale, an audio intensity slider, an audio narration toggle for spoken cues, and a colorblind-friendly palette.
- Focus outline presets (system, high-contrast ring, glow halo) for clearer keyboard navigation, saved per profile.
- Layout preview overlay that compares left/right-handed HUD placements and lets players apply their choice before exiting options.
- Large-text subtitles toggle with a preview overlay to boost caption size and contrast for dialogue, taunts, and overlay summaries.
- Tutorial pacing slider (75-125%) to slow down or speed up scripted tutorial prompts and timings.
- Profile-bound accessibility preset toggle that bundles reduced motion, narration, readable/dyslexia fonts, spaced letters, large subtitles, and a simplified HUD.
- UI sound scheme picker with preview/apply controls to switch between refreshed interface sound sets.
- Voice pack selector with text-based stubs so players can pick a narration style per profile.
- Reduced-motion VFX variants: particle systems switch to low-motion fades and a global `data-vfx-mode` attribute gates motion-heavy effects when reduced motion is on.
- Posture checklist overlay with a 5-minute micro reminder toast so players can reset posture between waves.
- Endless practice mode accessible from the main menu, looping waves indefinitely for warm-up runs.
- Typing drills overlay (Burst, Endurance, Shield Breaker) that lets players warm up combos and accuracy without risking the castle.
- Personal WPM ladder that records per-mode best runs with a HUD card, options shortcut, and local-only overlay.
- Training calendar heatmap that tracks daily lessons/drills locally with a HUD card and overlay grid.
- Pixel-art biome gallery that lets you pick an active backdrop, preview palettes/tags, and track runs/lessons/drills per biome with a HUD card, options shortcut, and local-only overlay.
- Day/night palette toggle to swap global HUD theming (panels, overlays, biome cards) with local persistence.
- Enemy readability guide overlay that highlights refreshed silhouettes, tier colors, and quick tips for every enemy tier.
- Layered parallax backgrounds (day/night/storm) with gentle motion that pauses for Reduced Motion/Low Graphics, selectable from options.
- Streak-freeze tokens awarded on 5-day streaks to protect progress; shown in HUD with an options shortcut.

## Getting Started

```bash
npm install
```

### Build & Test

```bash
npm run lint          # ESLint across src/, tests/, scripts/ (warnings fail the run)
npm run format:check  # Assert Prettier formatting without modifying files
npm run build         # compile TypeScript to dist/ (invoked automatically by npm run test)
npm run test          # clean, lint, format check, build, then run vitest --coverage

# Visual Regression (Playwright)
npm run test:visual:auto        # auto-start dev server (no build), run visual snapshots, stop afterward
npm run test:visual:auto -- --update  # refresh baselines after intentional HUD/overlay changes
npm run test:visual:auto -- --host 0.0.0.0 --port 4200  # target a custom bind/port (e.g., remote device)
npm run test:visual:auto -- --grep hud-main  # run a single visual spec
```

### Nightly workflows (manual dispatch)

Use GitHub CLI when you need to kick the scheduled jobs on demand:

```bash
gh workflow run ci-matrix-nightly.yml --ref master      # scenario matrix + asset integrity + HUD gallery + condensed audit
gh workflow run codex-dashboard-nightly.yml --ref master # rebuild Codex dashboard/portal from live artifacts or fixtures
```

### Download CI/Nightly artifacts

Use the helper script (requires GitHub CLI auth):

```bash
npm run ci:download-artifacts -- --workflow ci-matrix-nightly.yml --name ci-matrix-summary
npm run ci:download-artifacts -- --workflow codex-dashboard-nightly.yml --name codex-dashboard-nightly
```

### Development Server

A helper script (`scripts/devServer.mjs`) wraps `http-server` so automation can detect readiness and manage the lifecycle.

```bash
npm run start          # build + launch, emits DEV_SERVER_READY ... when ready
npm run serve:status   # report URL/pid and HTTP reachability
npm run serve:check    # exit 0 only when the server responds successfully
npm run serve:open     # start/reuse the server with --no-build, open the browser (supports --force-restart, --host, --port)
npm run serve:logs     # tail the captured http-server output
npm run serve:stop     # terminate the detached server and clear state files
```

Runtime state lives in `.devserver/state.json`, and logs are written to `.devserver/server.log`. Override defaults with `PORT` and `HOST` environment variables before running `npm run start`.

Need a fast confidence check without keeping the server up? `npm run serve:smoke` launches the dev server (skipping the redundant build by default), waits for readiness, performs HTTP probes, and then shuts everything down-perfect for CI or unattended validation of the harness. The run records a JSON summary at `artifacts/smoke/devserver-smoke-summary.json` (set `DEVSERVER_SMOKE_SUMMARY` to override), automatically prints the tail of `.devserver/server.log` if anything fails, and accepts `--json` to echo the summary to stdout so automation can capture it without touching the filesystem.

Want to validate the start/stop lifecycle itself? `npm run serve:start-smoke` force-restarts the server with `--no-build`, waits for readiness, copies `.devserver/server.log`, writes `artifacts/monitor/start-smoke.json`, and then stops everything again. CI runs this after the regular smoke so regressions in `npm run start` surface immediately. If the `http-server` binary ever goes missing, `scripts/devServer.mjs` now emits `.devserver/resolution-error.json` with attempted paths, PATH information, and install suggestions-check that file whenever `npm run start` fails before the build phase.

### Wave Authoring & Preview

- Edit/export designer configs from core data and toggles:
  - `npm run wave:edit -- --create-from-core --force` (write `config/waves.designer.json`).
  - `npm run wave:edit -- --input config/waves.designer.json --summarize --no-write` (validate + summarize).
  - Apply feature toggles: `npm run wave:edit -- --set-toggle evacuationEvents=false`.
- Live preview for designers:
  - `npm run wave:preview -- --config config/waves.designer.json --open` (or `npm run wave:preview:open`)
  - Features: lane filters, event-type toggles (spawns/hazards/dynamic/evac/boss), timelines, search tokens, SSE auto-reload when config or schema changes.
  - Validation errors render inline so you can fix the file and refresh instantly.
- Evacuation events avoid lanes already booked by hazards or dynamic events; if all lanes are occupied, the evacuation is skipped for that wave.

### Tests

The Vitest suite targets compiled modules in `dist/`, using deterministic seeds and debug hooks to avoid any browser dependency. Run `npm run test` after changing engine, system, or HUD logic.

### Git Hooks

Local commits should always pass the same gates as CI. The repo ships with an auto-generated pre-commit hook that runs:

1. `npm run lint`
2. `npm run test`
3. `npm run codex:validate-pack`
4. `npm run codex:validate-links`
5. `npm run codex:status`

Hooks install automatically after `npm install`, or you can run `npm run hooks:install`. Set `SKIP_HOOKS=1` before committing to bypass them (useful inside CI jobs that already executed the checks).

## Project Layout

```
apps/keyboard-defense/
  public/           # index.html, styles, static assets (manifest-driven sprites)
  src/              # TypeScript sources (engine, systems, UI, debug helpers)
  tests/            # Node test files (compiled before execution)
  scripts/devServer.mjs
  docs/             # Architecture and development notes
  dist/             # Generated output from `npm run build`
```

## Debugging & QA

- `window.keyboardDefense` exposes pause/resume, wave stepping, spawn injection, resource grants, analytics export, and more.
- The diagnostics overlay (toggle in the debug panel) surfaces difficulty bands, typing metrics, projectile counts, and recent wave summaries.
- The HUD wave preview shows lane, wave index, enemy tier, ETA, and a lane summary banner to plan turret coverage.

## Planned Enhancements

- Replace placeholder SVG sprites with production art/animations via the asset manifest pipeline.
- Extend tests to cover additional HUD interactions and analytics edge cases.
- Add optional damage/priority indicators to the wave preview summary for deeper strategic insight.

## Analytics Export

- Use `npm run analytics:aggregate` to convert JSON snapshots into a CSV. Columns include turret/typing damage, DPS splits, shield breaks, castle bonus gold, castle repair usage (count, HP restored, gold spent), passive unlock counts/details, and recent gold event telemetry per wave.
- Use `npm run analytics:passives` to emit a castle passive unlock timeline (JSON or `--csv`) when analyzing exported snapshots or automation artifacts. Pass `--merge-gold --gold-window <seconds>` to attach the closest gold delta event to each unlock for economy dashboards.
- Use `npm run analytics:gold` to export a gold event timeline (JSON by default, `--csv` optional) containing delta, resulting total, timestamp, time-since data, and (optionally) the nearest passive unlock (`--merge-passives --passive-window <seconds>`).
- Use `npm run analytics:gold:summary` to condense one or more timelines/snapshots into per-file economy stats (net delta, max gain/spend, percentile gains/spends, passive linkage counts). Append `--global` to include an overall aggregate row; CI smoke runs and `npm run analytics:gold:report` default to `--percentiles 25,50,90` so dashboards always receive the same cutlines (override as needed). JSON output now wraps the rows along with the `percentiles` array so downstream tooling can assert which cutlines were used; CSV output appends a `summaryPercentiles` column carrying the same data.
- Use `npm run analytics:gold:check` to validate one or more gold summary artifacts (JSON or CSV) and ensure they embed the expected percentile list—ideal for dashboards/alerts that ingest artifacts outside the standard smoke workflow.
- Use `npm run analytics:gold:report` to generate both the passive-aware timeline and matching summary in one shot (uses the same flags as the underlying CLIs).
- Review [`docs/analytics_schema.md`](../docs/analytics_schema.md) for the full snapshot and CSV schema, including tutorial telemetry fields.
- Snapshot JSONs now expose a `ui` object that records tutorial banner layout, HUD/pause collapse preferences, and diagnostics overlay responsiveness so automated consumers can distinguish mobile-first captures without scraping the DOM.
- Snapshot JSONs are generated via the in-game analytics download button (debug panel) or the options overlay when analytics export is enabled.

### Telemetry

- Enable telemetry from the main menu or debug panel when the `telemetry` feature toggle is active.
- Supply an HTTPS endpoint to post queued envelopes; batches flush automatically when the queue reaches its threshold or via the debug “Flush Telemetry” control.
- The client prefers `navigator.sendBeacon`, falls back to `fetch`, and requeues on synchronous transport failures (custom transports can throw to trigger a retry).

### Smoke Tests

- `npm run smoke:tutorial` connects to a running dev server, skips the tutorial via the debug API, and writes smoke artifacts under `smoke-artifacts/`. Install `@playwright/test` before running.
- `npm run smoke:tutorial:full` spins up the dev server, replays the entire tutorial deterministically, and captures analytics/wave artifacts.
- `npm run smoke:campaign` exercises a post-tutorial campaign slice by auto-placing a turret, defeating a staged enemy, and recording the resulting analytics snapshot.

### Automation Script Layer

The new generation of orchestration scripts lives in `scripts/`:

| Script                         | Description                                                                                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `node scripts/build.mjs`       | Clean + lint + prettier check + compile (wraps clean/lint/format:check/build).                                                                          |
| `node scripts/unit.mjs`        | Run the Vitest unit suite (`vitest run --coverage`).                                                                                                    |
| `node scripts/integration.mjs` | Execute `*.integration.test.js` specs when present.                                                                                                     |
| `node scripts/smoke.mjs`       | Invoke the tutorial smoke CLI (default `--mode skip`).                                                                                                  |
| `node scripts/seed.mjs`        | Emit deterministic local storage fixtures under `artifacts/seed/`.                                                                                      |
| `node scripts/e2e.mjs`         | Start the dev server, run full tutorial & campaign smokes, archive artifacts (`artifacts/e2e/tutorial-full.json`, `campaign.json`, `e2e-summary.json`). |
| `node scripts/hudScreenshots.mjs` | Capture the standard HUD, options overlay, tutorial summary, and wave scorecard screenshots under `artifacts/screenshots/`; the summary JSON embeds a `uiSnapshot` for each capture so you can see whether the HUD was condensed, which panels were collapsed, and if diagnostics were minimized. |
| `node scripts/castleBreachReplay.mjs` | Replay the deterministic castle-breach drill and emit a JSON artifact summarising the timeline.                                                     |
| `node scripts/analyticsAggregate.mjs` | Convert analytics snapshots into the detailed wave-by-wave CSV described in `docs/analytics_schema.md`.                                           |
| `node scripts/analyticsLeaderboard.mjs` | Generate a leaderboard-ready CSV (or JSON) ranked by combo, accuracy, and DPS from exported analytics snapshots.                              |
| `node scripts/goldTimeline.mjs` | Emit the recent-gold timeline (JSON or CSV) from analytics snapshots or smoke artifacts, with optional `--merge-passives` support for correlating unlocks. |
| `node scripts/goldSummary.mjs` | Aggregate one or more timelines/snapshots into per-file economy stats (net totals, max gain/spend, configurable gain/spend percentiles via `--percentiles`, passive linkage counts). |
| `node scripts/goldSummaryCheck.mjs` | Validate gold summary artifacts (JSON/CSV) to ensure they embed the expected percentile list (`--percentiles 25,50,90` by default). |
| `node scripts/goldReport.mjs` | Convenience wrapper that runs the timeline + summary CLIs sequentially so you get both artifacts via one command; defaults to `--percentiles 25,50,90` when invoking `goldSummary.mjs` so local reports match CI. |
| `node scripts/ci/inputStressTest.mjs` | Simulate rapid typing bursts (correct/wrong/hold/backspace) against TypingSystem to surface buffer overflow or throughput regressions; writes a JSON summary. |
| `node scripts/helm.mjs` | Lightweight task runner that proxies common npm workflows (`start`, `build`, `test`, `smoke`, `gold-check`). |
| `node scripts/assetIntegrity.mjs` | Hash every manifest-listed asset (SHA-256) and rewrite/verify the manifest integrity map (`--check` to verify without writing).                      |

Pass `--ci` to any script to write artifacts into `artifacts/<task>/...` for pipeline consumption.
