> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Canvas Resolution Scaling - 2025-11-18

**Summary**
- Canvas now measures its flex container and device pixel ratio, then sets an internal render size so ultra-small layouts draw fewer pixels without losing clarity. The ResizeObserver path updates the renderer whenever the HUD stack wraps or the player rotates their device.
- DPR-specific media queries now reapply the scaling math when the browser zooms or accessibility zoom toggles, so Retina/HiDPI displays stay sharp without manual refreshes.
- CanvasRenderer exposes a `resize` method that recalculates cached dimensions and clears pattern caches, ensuring post-resize renders stay crisp.
- Added shared `calculateCanvasResolution` helper plus unit tests, so future overlays/devtools can reuse the same scaling math.
- Diagnostics/Tutorial responsive work already benefits: small tablets drop the workload from 960px wide to whatever width is actually visible while keeping the CSS aspect ratio consistent.
- A `ResolutionTransitionController` now captures the previous frame to an overlay canvas and fades it out over ~250 ms, masking DPR/viewport jumps without freezing gameplay or relying solely on CSS opacity.
- Hud + diagnostics Vitest suites assert the new `data-canvas-transition` and `data-reduced-motion` datasets through `HudView.setCanvasTransitionState` / `setReducedMotionEnabled`, so regressions in automation hooks get caught before Playwright.
- GameController now drives the shared `createDprListener`, persists the latest devicePixelRatio/HUD layout in player settings, and threads both values through analytics snapshots so telemetry/export tooling knows which responsive mode was active.
- `analyticsAggregate` surfaces the responsive metadata via new CSV columns (`uiHudLayout`, the `uiResolution*` set, and `uiPrefDevicePixelRatio`/`uiPrefHudLayout`) while Vitest coverage guards the flattened output for dashboards.
- Every resolution change now emits a telemetry payload (`ui.canvasResolutionChanged`) and is captured inside analytics snapshots (`ui.resolution`, `ui.resolutionChanges[]`), so dashboards can confirm DPR listeners fired and HUD layout state during transitions.
- Added `npm run debug:dpr-transition` so engineers can replay DPR buckets/transition timings headlessly and update analytics fixtures without reaching for the browser zoom tools.
- The DPR debugger now accepts `--markdown <path>`, emitting a ready-to-post summary table alongside the JSON payload so CI summaries/PR notes can embed the transitions without extra scripting.
- `CanvasRenderer.resize()` accepts a cause flag (and exposes `getLastResizeCause()`), letting diagnostics/telemetry distinguish viewport vs DPR resizes directly from the renderer layer.
- Diagnostics overlay now surfaces the last canvas resize cause so engineers can confirm whether recent transitions were triggered by viewport shifts, manual overrides, or DPR listeners without digging through logs.
- `document.body.dataset.canvasResizeCause` mirrors the renderer’s last-known cause, giving automation hooks and DevTools a deterministic flag without scraping the diagnostics overlay.

**Next Steps**
1. Add Vitest coverage around `npm run debug:dpr-transition` so scripted DPR buckets and telemetry payloads stay stable across refactors (consider snapshotting the JSON output for default steps).
2. Graduate from the current Linkedom/Vitest assertions to a Playwright smoke that zooms the canvas, verifies the fade visualization, and records reduced-motion short-circuit behavior (unit coverage is in place, but we still need an end-to-end proof).
3. Hook the new `uiResolution*`/`uiHudLayout` columns into the Codex dashboards so responsive regressions show up alongside the passive/telemetry feeds.

