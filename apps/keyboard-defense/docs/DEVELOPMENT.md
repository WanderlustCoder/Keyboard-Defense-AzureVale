# Development Workflow

## Prerequisites
- Node.js 18+ (project currently tested with Node 22 LTS).
- npm 9+.

Run `npm install` from `apps/keyboard-defense/` before building or running scripts.

## Building & Testing
- `npm run build` - compile TypeScript into `dist/`.
- `npm run test` - clean, build, and execute the Node test suite (uses the compiled artifacts in `dist/`).

Tests rely on deterministic seeds and the debug hooks exposed by the game engine, so they do not require a browser.

## Dev Server Automation
The repo ships with `scripts/devServer.mjs`, a thin wrapper around `http-server` that builds the project, serves `public/`, and emits readiness signals for automated tooling.

Commands:

| Command | Purpose |
| --- | --- |
| `npm run start` | Build + launch the dev server. Emits `DEV_SERVER_READY ...` once the static site is reachable. |
| `npm run serve:status` | Report whether the server is running and reachable; outputs URL/pid when active. |
| `npm run serve:check` | Fast readiness probe (non-zero exit code if unreachable). |
| `npm run serve:logs` | Tail the captured `http-server` log from `.devserver/server.log`. |
| `npm run serve:monitor` | Stream logs and periodic HTTP probes; exits when the server stops or on Ctrl+C. |
| `npm run serve:stop` | Gracefully terminate the background server and clear state files. |
| `npm run monitor:dev` | Standalone poller (`devMonitor.mjs`) that waits for the dev server to become reachable and emits a JSON artifact. |
| `npm run start:monitored` | Convenience wrapper that runs `npm run start` followed by the monitor (with `--wait-ready`) in one step. |
| `npm run smoke:tutorial:full` | Launches the dev server, runs the full tutorial smoke (`tutorialSmoke.mjs --mode full`), then stops the server. Requires `@playwright/test` + installed browser binaries. |

The script tracks runtime state in `.devserver/state.json` and writes logs to `.devserver/server.log`. On Windows/OneDrive the script avoids source-map locking by compiling without `.map` files.

`serve:monitor` keeps polling reachability every five seconds while streaming appended log lines, and exits automatically if the background process dies—useful for unattended smoke checks. `monitor:dev` works independently of the managed process and is handy when the server is launched through other tooling (e.g., `npm run start` in a separate terminal or remote VM); it writes its latest poll history to `monitor-artifacts/dev-monitor.json` by default. `start:monitored` bundles both steps so local workflows can kick off a fresh server and wait for readiness without juggling multiple terminals.

Example:

```bash
npm run start:monitored -- --timeout 60000 --artifact monitor-artifacts/run.json
```

Anything after `--` is forwarded to `devMonitor.mjs`.

When triggering the full smoke (`smoke:tutorial:full`), install Playwright first:

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
