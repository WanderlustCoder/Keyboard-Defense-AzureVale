# Keyboard Defense

Keyboard Defense is a typing-driven castle defense game where fast, accurate input powers both direct attacks and turret support. The playable app lives under `apps/keyboard-defense/` and is written in TypeScript, compiled to an ES module bundle for the browser.

## Features

- Deterministic game engine for repeatable playtests and automation.
- Upgradeable castle and turret archetypes (arrow, arcane, flame) with unique behaviors.
- Passive castle buffs (regen, armor, gold bonus) unlock as you upgrade and surface in HUD/options overlays.
- Save and apply turret loadout presets with gold-cost previews for rapid experimentation.
- Crystal Pulse turret archetype (feature toggle) that deals bonus shield damage to counter barrier-heavy waves.
- Analytics tracking for wave summaries, accuracy, breaches, and DPS.
- HUD with combo tracking, battle log, resource deltas, and an upcoming-enemy preview panel sourced from the wave scheduler.
- Debug overlay and `window.keyboardDefense` hooks for runtime inspection and mutation.
- Optional Web Audio feedback for projectile launches, impacts, breaches, and upgrades.
- Accessibility and comfort toggles for reduced motion, readable fonts, adjustable HUD scale, an audio intensity slider, and a colorblind-friendly palette.
- Endless practice mode accessible from the main menu, looping waves indefinitely for warm-up runs.

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
```

### Development Server

A helper script (`scripts/devServer.mjs`) wraps `http-server` so automation can detect readiness and manage the lifecycle.

```bash
npm run start          # build + launch, emits DEV_SERVER_READY ... when ready
npm run serve:status   # report URL/pid and HTTP reachability
npm run serve:check    # exit 0 only when the server responds successfully
npm run serve:logs     # tail the captured http-server output
npm run serve:stop     # terminate the detached server and clear state files
```

Runtime state lives in `.devserver/state.json`, and logs are written to `.devserver/server.log`. Override defaults with `PORT` and `HOST` environment variables before running `npm run start`.

### Tests

The Vitest suite targets compiled modules in `dist/`, using deterministic seeds and debug hooks to avoid any browser dependency. Run `npm run test` after changing engine, system, or HUD logic.

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

- Use `npm run analytics:aggregate` to convert JSON snapshots into a CSV. Columns include turret/typing damage, DPS splits, shield breaks, castle bonus gold, and castle repair usage (count, HP restored, gold spent) per wave.
- Review [`docs/analytics_schema.md`](../docs/analytics_schema.md) for the full snapshot and CSV schema, including tutorial telemetry fields.
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
| `node scripts/hudScreenshots.mjs` | Capture HUD and options overlay screenshots into `artifacts/screenshots/` for documentation and regression references.                                 |
| `node scripts/castleBreachReplay.mjs` | Replay the deterministic castle-breach drill and emit a JSON artifact summarising the timeline.                                                     |
| `node scripts/analyticsAggregate.mjs` | Convert analytics snapshots into the detailed wave-by-wave CSV described in `docs/analytics_schema.md`.                                           |
| `node scripts/analyticsLeaderboard.mjs` | Generate a leaderboard-ready CSV (or JSON) ranked by combo, accuracy, and DPS from exported analytics snapshots.                              |

Pass `--ci` to any script to write artifacts into `artifacts/<task>/...` for pipeline consumption.
