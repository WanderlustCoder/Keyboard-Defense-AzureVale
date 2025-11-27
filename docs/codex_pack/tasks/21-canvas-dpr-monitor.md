---
id: canvas-dpr-monitor
title: "Canvas DPR monitor & transition smoothing"
priority: P2
effort: M
depends_on: []
produces:
  - canvas scaling updates (devicePixelRatio listener, smoothing)
  - tests verifying the behavior
  - documentation describing new hooks
status_note: docs/status/2025-11-18_canvas_scaling.md
backlog_refs:
  - "#53"
---

**Context**  
The Nov-18 canvas scaling work normalized render size to flex width + initial
`window.devicePixelRatio`, but zoom/pinch gestures after boot still leave the
canvas stale. HUD overlays also “pop” when we recompute resolution mid-wave.
Codex needs prescriptive steps for listening to DPR changes, smoothing the
transition, persisting player preferences, and exporting telemetry for smoke
tests.

## Steps

1. **DPR change detection**
   - Teach `apps/keyboard-defense/src/ui/canvasResolution.ts` (or the helper
     chosen in the responsive layout PR) to register a `matchMedia` listener per
     devicePixelRatio bucket (e.g., `window.matchMedia("(resolution: 2dppx)")`).
     Keep a map so multiple listeners can be swapped as DPR changes.
   - On change, call the existing `calculateCanvasResolution` helper and forward
     the new dimensions to `CanvasRenderer.resize`.
   - Debounce/batch events (50–100 ms) to avoid thrashing during pinch zoom.
2. **Transition smoothing**
   - Add a `ResolutionTransitionController` inside
     `apps/keyboard-defense/src/ui/diagnostics.ts` (or another shared HUD file)
     that:
       - Captures the previous canvas frame to a `ImageBitmap` or `<canvas>`
         buffer.
       - Fades the buffer out over ~150 ms while the new resolution fades in.
       - Exposes hooks so overlays (diagnostics/tutorial) can pause animations
         during the transition if desired.
   - Provide config knobs (`HUD_RESOLUTION_FADE_MS`, `HUD_RESOLUTION_HOLD_FRAMES`)
     via `apps/keyboard-defense/src/config/ui.ts`.
3. **Player preference + telemetry**
   - Extend `gameController.initializePlayerSettings` so the last DPR multiplier
     (e.g., 1x/1.25x/2x) is persisted under `playerSettings.hud.dpr`.
   - Emit a lightweight telemetry event (`ui.canvasResolutionChanged`) inside
     `analyticsAggregate` with `{fromDpr, toDpr, width, height, transitionMs}` so
     smoke runs can assert that DPR listeners fire.
4. **Tests**
   - Add Vitest coverage for the new listener module (mock `matchMedia` and
     assert debounce behavior).
   - Extend `apps/keyboard-defense/tests/analyticsAggregate.test.js` (or add a
     sibling) to ensure the telemetry payload is included.
   - If feasible, create a Playwright/Vitest DOM test that simulates DPR changes
     via `window.devicePixelRatio` mocking to verify fade classes are applied.
5. **Docs + status bookkeeping**
   - Update `docs/status/2025-11-18_canvas_scaling.md` with the smoothing +
     telemetry summary and confirm the Follow-up still references this task.
   - Document the new commands/hooks inside `docs/CODEX_PLAYBOOKS.md` (Gameplay
     section) and `docs/docs_index.md` so Codex can discover the workflow.

## Implementation Cheatsheet

- **Listener utility** – build a dedicated `createDprListener()` in
  `canvasResolution.ts` that exposes `start()`, `stop()`, and `simulate(dpr)`
  helpers so tests and devtools can trigger the same code paths.
- **Renderer contract** – extend `CanvasRenderer.resize` with an optional
  `cause` (`"viewport" | "dpr" | "manual"`) so analytics and diagnostics can log
  the source of each resize.
- **HUD orchestration** – drop a small store (Zustand/simple observable) that
  tracks `{dpr, renderWidth, renderHeight, transitionState}` and lets overlays
  subscribe without reaching into the renderer directly.
- **Telemetry hook** – emit `ui.canvasResolutionChanged` via the existing
  analytics dispatcher and include `transitionDurationMs` so CI artifacts can
  confirm the fade path ran.
- **CLI helper** - add `npm run debug:dpr-transition` that repeatedly calls the
  listener's `simulate()` while logging the telemetry payload (and, via
  `--markdown <file>`, produces a ready-to-share summary table) so Codex has a
  deterministic repro without browser zooming.
- **HUD datasets** – `HudView` now exposes `setCanvasTransitionState` and
  `setReducedMotionEnabled`, wiring `data-canvas-transition`/`data-reduced-motion`
  attributes directly on the HUD root + document so diagnostics and tutorials
  can rely on a single source of truth instead of duplicating DOM handling.

## Deliverables & Artifacts

- `apps/keyboard-defense/src/ui/canvasResolution.ts` – listener + helpers with
  Vitest coverage (`tests/canvasResolution.test.ts`).
- `apps/keyboard-defense/src/ui/ResolutionTransitionController.ts` – encapsulated
  fade logic with DOM class toggles + unit tests for timing math.
- `apps/keyboard-defense/src/config/ui.ts` – new knobs documented inline and in
  `apps/keyboard-defense/docs/HUD_NOTES.md`.
- `artifacts/summaries/ui-canvas-resolution.json` – optional CI artifact that
  captures the telemetry payload from the latest smoke run for regression diffing.
- Updated docs (`docs/CODEX_PLAYBOOKS.md`, `docs/status/...`) describing how to
  re-run the DPR simulation locally.

## Milestone plan

1. **M1 – Listener + resize plumbing (Day 1-2)**
   - Ship the `createDprListener()` helper, hook it into the renderer bootstrap,
     and gate it behind a feature flag (`HUD_ENABLE_DPR_LISTENER`) so we can
     deploy incrementally.
   - Add smoke-level logging (`console.debug` behind `NODE_ENV !== "production"`)
     that prints `{prevDpr, nextDpr, width, height, pendingFrames}` whenever a
     DPI change is detected.
2. **M2 – Transition controller + HUD orchestration (Day 3-4)**
   - Implement `ResolutionTransitionController` with a simple frame buffer +
     `requestAnimationFrame` loop, and expose a `transition:start/end` event that
     HUD overlays can subscribe to (so they can pause at mid-wave).
   - Wire the controller into `diagnostics.ts` + `hud.ts`, add CSS classes for
     fading, and provide configuration in `config/ui.ts`.
   - **Status:** The controller now captures the previous frame into a fixed overlay
     canvas, fades it out over ~250 ms, and logs the transition metadata for analytics.
     HUD + diagnostics listen for the transition state via `data-canvas-transition`
     so they can pause interactions while the fade plays.
3. **M3 – Telemetry + persistence (Day 5)**
   - Extend `playerSettings` persistence, emit `ui.canvasResolutionChanged`
     events via `analyticsAggregate`, and add CLI/fixture coverage so CI can
     assert telemetry is present.
   - Document the CLI hook (`npm run debug:dpr-transition`) and update
     `docs/status/2025-11-18_canvas_scaling.md` with the new behavior.
   - **Status:** Analytics exports now include `ui.resolution` +
     `ui.resolutionChanges[]`, and the game emits the `ui.canvasResolutionChanged`
     telemetry event whenever DPR or viewport shifts fire.
   - **New:** `npm run debug:dpr-transition` simulates DPR buckets/transition timings
     headlessly so fixtures/tests can be refreshed without browser zooming.

## Telemetry contract

- Event name: `ui.canvasResolutionChanged`
- Payload structure:
  ```jsonc
  {
    "fromDpr": 1,
    "toDpr": 1.25,
    "renderWidth": 1280,
    "renderHeight": 720,
    "durationMs": 180,
    "transitionState": "completed",
    "prefersCondensedHud": true,
    "captureTime": "2025-11-18T15:04:05.000Z"
  }
  ```
- Emit once per completed transition; if multiple DPR changes happen rapidly,
  collapse them into a single event with `transitionState: "debounced"`.
- Include the active HUD layout (`"stacked" | "grid" | "condensed"`) so the
  analytics pipeline can spot layout regressions.
- Store the latest event at `analytics.ui.canvasResolutionChanges[]` with a max
  length of 10; CLI fixtures should exercise both short and long histories to
  confirm trimming works.

## Testing matrix

- **Unit (Vitest)**
  - Listener debounce: simulate rapid `matchMedia` toggles and expect the resize
    callback to fire once per debounce interval.
  - Transition math: ensure the controller schedules the correct number of frames
    for default/faster transitions and cancels gracefully when destroyed.
  - Telemetry reducer: feed fake events into `analyticsAggregate` and assert the
    output includes the payload + truncated history.
  - HUD datasets: `tests/hud.test.js` now asserts that
    `HudView.setCanvasTransitionState`/`setReducedMotionEnabled` toggle the
    relevant data attributes and CSS classes so automation hooks remain wired.
- **Integration (DOM-focused)**
  - In `tests/canvasResolution.test.tsx`, mount the HUD, simulate DPR changes via
    `window.devicePixelRatio` mocks, and assert CSS classes
    (`.hud--resizing`, `.hud--condensed`) toggle as expected.
  - Add a Playwright smoke (`npm run debug:dpr-transition`) that zooms the page,
    waits for the fade, and screenshots the result to ensure visual smoothness.
- **Telemetry/CLI**
  - Extend `docs/codex_pack/fixtures/analytics/valid.snapshot.json` with
    `ui.canvasResolutionChanges` examples and validate them through the schema.
  - Add a mini CLI (`scripts/debug/dprTransition.mjs`) referenced in fixtures +
    docs, so QA can reproduce transitions deterministically.

## Acceptance criteria

- Canvas automatically re-runs resolution math whenever DPR/zoom changes without
  requiring a reload.
- Fade/hold transitions mask the resize so overlays no longer “pop”.
- Telemetry + persisted settings capture the new DPR so smoke/analytics suites
  can assert the flow.
- Unit tests cover listeners, smoothing, and telemetry wiring.

## Verification

- npm run lint
- npm run test -- canvasResolution
- npm run test -- analyticsAggregate
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Manual: adjust browser zoom / simulate DPR change in devtools and confirm the
  canvas resizes smoothly while the fade plays.
