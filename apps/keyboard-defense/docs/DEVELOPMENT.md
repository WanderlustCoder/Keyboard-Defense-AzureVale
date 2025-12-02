# Development Workflow

## Prerequisites
- Node.js 18+ (project currently tested with Node 22 LTS).
- npm 9+.

Run `npm install` from `apps/keyboard-defense/` before building or running scripts.

## Building & Testing
- `npm run build` - type-check the authored TypeScript and regenerate `public/dist/src` (JS + `.d.ts`) so the shipped bundle matches the sources.
- `npm run build:dist` - skip the type-checking pass and only refresh `public/dist/src` (useful when iterating on UI files such as `src/ui/diagnostics.ts`).
- `npm run test` - clean, build, and execute the Node/Vitest suite (includes the Playwright fixtures and depends on the regenerated `public/dist/src` tree).

Tests rely on deterministic seeds and the debug hooks exposed by the game engine, so they do not require a browser.

Additional linting:
- `npm run lint` - Runs ESLint plus strict wordlist/lesson linting and writes `artifacts/summaries/wordlist-lint.json` (warnings fail the run).
- `npm run lint:wordlists:strict` - Shortcut for the strict lint (writes the summary artifact).
- `npm run lint:wordlists -- [--fix-sort] [--strict] [--out <file>]` - Validate lesson/word bank files under `data/wordlists` (safe characters, denylist, lengths, duplicates, weights, lesson gating). Use `--fix-sort` to auto-sort words and rewrite files; `--strict` fails on warnings; `--out` writes a JSON summary (created automatically in strict mode).

## Dev Server Automation
The repo ships with `scripts/devServer.mjs`, a thin wrapper around `http-server` that builds the project, serves `public/`, and emits readiness signals for automated tooling.

Commands:

| Command | Purpose |
| --- | --- |
| `npm run start` | Build + launch the dev server. Emits `DEV_SERVER_READY ...` once the static site is reachable. |
| `npm run serve:status` | Report whether the server is running and reachable; outputs URL/pid when active. |
| `npm run serve:check` | Fast readiness probe (non-zero exit code if unreachable). |
| `npm run serve:open` | Start the dev server with `--no-build` if needed and open it in your default browser. Pass `--force-restart` to replace an existing instance; `--host`/`--port` forward overrides to the managed server. |
| `npm run serve:logs` | Tail the captured `http-server` log from `.devserver/server.log`. |
| `npm run serve:monitor` | Stream logs and periodic HTTP probes; exits when the server stops or on Ctrl+C. |
| `npm run serve:smoke` | Launch `npm run start`, wait for readiness, issue reachability checks, and shut everything down again (used in CI). Emits `artifacts/smoke/devserver-smoke-summary.json` (override via `DEVSERVER_SMOKE_SUMMARY`), automatically prints the tail of `.devserver/server.log` when failures occur, and supports `--json` to dump the summary to stdout for automation-friendly parsing. |
| `npm run serve:start-smoke` | Force-restarts the dev server with `--no-build`, waits for readiness, then stops and writes `artifacts/monitor/start-smoke.json` plus a copied log so CI can fail fast on regressions. |
| `npm run serve:stop` | Gracefully terminate the background server and clear state files. |
| `npm run monitor:dev` | Standalone poller (`devMonitor.mjs`) that waits for the dev server to become reachable and emits a JSON artifact under `artifacts/monitor/dev-monitor.json`. |
| `npm run start:monitored` | Convenience wrapper that runs `npm run start` followed by the monitor (with `--wait-ready`) in one step. |
| `npm run smoke:tutorial:full` | Launches the dev server, runs the full tutorial smoke (`tutorialSmoke.mjs --mode full`), then stops the server. Requires `@playwright/test` + installed browser binaries. |
| `npm run test:visual` | Runs the Playwright visual regression suite (`tests/visual/hud.spec.ts`) against the local dev server. Baselines live in `baselines/visual/visual/<spec>/`; use `npm run test:visual:update` after intentional HUD/overlay changes to refresh them. |
| `npm run test:visual:auto` | Spins up the dev server with `--no-build` if needed, runs the visual suite, then stops the server unless `--keep-alive` is passed. Supports `--update` to refresh baselines, `--host`/`--port` to target custom binds, and forwards extra args to Playwright after `--`. |
| `npm run ci:matrix` | Executes the scenario matrix runner (tutorial smoke modes + castle breach seeds) and writes `artifacts/ci-matrix-summary.json`. |
| `npm run dashboard:static` | Generates the static dashboard under `static-dashboard/` from the latest artifacts so GitHub Pages can publish it. |
| `gh workflow run ci-matrix-nightly.yml --ref master` | Manually trigger the nightly scenario matrix (asset integrity + HUD gallery + condensed audit). |
| `gh workflow run codex-dashboard-nightly.yml --ref master` | Manually trigger the nightly dashboard/portal refresh (uses live CI artifacts when present). |

The script tracks runtime state in `.devserver/state.json` and writes logs to `.devserver/server.log`. On Windows/OneDrive the script avoids source-map locking by compiling without `.map` files.

`serve:monitor` keeps polling reachability every five seconds while streaming appended log lines, and exits automatically if the background process dies—useful for unattended smoke checks. `monitor:dev` works independently of the managed process and is handy when the server is launched through other tooling (e.g., `npm run start` in a separate terminal or remote VM); it writes its latest poll history to `artifacts/monitor/dev-monitor.json` by default. `serve:start-smoke` force-restarts the server with `--no-build`, waits for readiness, copies `.devserver/server.log`, and shuts everything down so CI can verify the harness quickly (summary lives at `artifacts/monitor/start-smoke.json`). `start:monitored` bundles both steps so local workflows can kick off a fresh server and wait for readiness without juggling multiple terminals. Flags such as `--no-build` or `--force-restart` are forwarded to `npm run start`, while the remaining arguments still configure the monitor (`--timeout`, `--artifact`, etc.). If `http-server` cannot be resolved, `scripts/devServer.mjs` writes `.devserver/resolution-error.json` with attempted paths and quick fixes—inspect that file whenever the start command fails before the build phase.

Dev server flags:

- `--no-build` (or `DEVSERVER_NO_BUILD=1`) - skip `npm run build` for rapid restarts.
- `--force-restart` - stop any existing `.devserver` instance before starting a new one.

Example:

```bash
npm run start:monitored -- --no-build --timeout 60000 --artifact artifacts/monitor/dev-monitor.json
```

Anything after `--` is forwarded to `devMonitor.mjs`.

When triggering the full smoke (`smoke:tutorial:full`), the visual regression suite (`npm run test:visual`), or the static dashboard build (`npm run dashboard:static`), install Playwright first:

```bash
npm install
npm exec playwright install chromium
```

When you are finished with the session, call `npm run serve:stop` to terminate the background server and clean up `.devserver/` state.

To force a specific port/host:

```powershell
$env:PORT = "4200"
$env:HOST = "0.0.0.0"
npm run start
```

The readiness token and log file make it easy to integrate with higher-level automation (CI, scripted playtesting, etc.).

### Remote Visual Testing Quickstart
- Start the dev server bound to your LAN IP:
  - `npm run serve:open -- --host 0.0.0.0 --port 4200 --force-restart`
- Run Playwright visuals against that host/port (adds `--update` to refresh baselines):
  - `npm run test:visual:auto -- --host 0.0.0.0 --port 4200 -- --grep hud-main`
- Optional: add `--keep-alive` to leave the server running after the visual suite.

## In-Game HUD Preview
The HUD now shows an "Upcoming Enemies" list sourced from `GameEngine.getUpcomingSpawns()`. This previews lane, wave, tier, and ETA (including partial lookahead into the next wave) so you can plan turret placements or typing priorities without pausing the game. The section uses the same data exposed through debug APIs, making it useful for automated scenarios as well.

## Tutorial Controls
- Completing the Episode 1 tutorial writes a `keyboard-defense:tutorialCompleted` flag to `localStorage`; subsequent sessions bypass the onboarding sequence automatically.
- The wrap-up overlay now presents accuracy, best combo, breach count, and remaining gold, with explicit "Proceed" and "Replay" options.
- From the browser console you can invoke `keyboardDefense.replayTutorial()` or `keyboardDefense.skipTutorial()` (exposed via the debug API), or use the "Replay Tutorial" button in the debug panel to reset progress for the current session.
- `keyboardDefense.getTutorialAnalytics()` returns the current onboarding telemetry (event log, assists, summary stats) for automation and diagnostics.
- Tutorial completion is versioned (`v2` as of this build); old completions are ignored so players automatically revisit updated tutorials.
- The in-game Options overlay now exposes a "Readable Font" toggle that switches the HUD to a dyslexia-friendly font stack and persists via player settings.

## Asset Pipeline Notes
- Runtime art loads through `public/assets/manifest.json`. Missing entries automatically fall back to procedural SVG sprites so the first render is never blocked.
- Each manifest entry can include a `sha256-...` integrity string; the loader re-fetches the sprite bytes, hashes them via `crypto.subtle`, and refuses to cache assets whose digest does not match (logging an error for dashboards). When integrity metadata exists but a key is missing, a warning is emitted so we notice gaps early.
- Run `npm run assets:integrity` (or `node scripts/assetIntegrity.mjs`) whenever sprite assets change to recompute the manifest's `integrity` map; pass `--check` in CI to verify hashes without rewriting the file.
- `AssetLoader` exposes `onImageLoaded` and `whenIdle()` helpers. Tooling can listen for individual sprite arrivals or await the whole batch before capturing screenshots.
- `GameController.waitForAssets()` bridges that promise to gameplay code-automation can await it after constructing the controller to ensure sprite swaps are applied before play begins.
- `GameController.start()` now defers the main loop until `assetReadyPromise` settles, so automation calling `start()` ahead of `waitForAssets()` won't run the simulation before sprites land.
- Run `npm run assets:integrity -- --check` (optional `--mode strict` or `ASSET_INTEGRITY_MODE=strict`) to verify manifest hashes. When `CI=1` (or `ASSET_INTEGRITY_SUMMARY`/`ASSET_INTEGRITY_SUMMARY_MD` are set) the script now writes telemetry under `artifacts/summaries/asset-integrity.(json|md)` so dashboards/CI summaries can ingest checked/missing/failure counts.

## Canvas DPR Monitor & Telemetry
- Reproduce canvas/devicePixelRatio transitions without touching the browser via `npm run debug:dpr-transition -- --steps 1:960:init,1.5:840:pinch,2:720:zoom --json --markdown temp/dpr-transition.md`. The JSON mirrors the `ui.resolutionChanges[]` entries stored inside analytics exports, while the Markdown is drop-in ready for PR notes or Codex dashboards.
- `node scripts/analyticsAggregate.mjs artifacts/analytics/*.json > artifacts/summaries/analytics.csv` flattens the responsive metadata into the CSV columns `uiHudLayout`, `uiResolutionCssWidth/Height/Render*`, `uiResolutionDevicePixelRatio`, `uiResolutionLastCause`, `uiPrefDevicePixelRatio`, and `uiPrefHudLayout`, giving Codex dashboards and spreadsheets deterministic hooks to audit DPR changes.
- At runtime the diagnostics overlay prints “Last canvas resize: …” and `document.body.dataset.canvasResizeCause` is updated each render from `CanvasRenderer.getLastResizeCause()`, so automation (Linkedom/Playwright) can assert DPR-driven resizes without diffing HUD text.
