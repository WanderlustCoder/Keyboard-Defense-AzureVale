---
id: starfield-parallax-effects
title: "Layer starfield parallax cues + visual baselines"
priority: P3
effort: M
depends_on: [visual-diffs]
produces:
  - parallax-aware starfield configuration
  - updated HUD screenshot baselines
status_note: docs/status/2025-11-07_starfield.md
backlog_refs:
  - "#68"
  - "#94"
---

**Context**  
The ambient starfield already animates gently, but Next Steps call for dynamic
parallax tied to wave progress/castle damage plus refreshed HUD screenshots that
showcase the effect. Without a task, Codex contributors keep guessing how to wire
the cues or update baselines.

## Steps

1. **Parallax + narrative hooks**
   - Extend the starfield renderer with parallax layers driven by:
     - Wave progress (speed/offset increase as waves intensify).
    - Castle HP damage (color tint/pulse when breaches occur).
  - Gate the behavior behind config so diagnostics/tests can fix determinism.
2. **Configuration + diagnostics**
   - Add tunable settings (JSON or constants) documenting how to tweak parallax
     speed, direction, and tint thresholds.
   - Surface current parallax state inside diagnostics overlay (e.g., "Starfield:
     drift 1.2x, tint Amber") for CI evidence.
3. **Visual baselines**
   - Refresh `scripts/hudScreenshots.mjs` fixtures (tutorial, wave scorecard,
     diagnostics) with the starfield enabled, ensuring Codex visual baselines live
     in `docs/hud_gallery.md` / Playwright diff suites.
   - Update docs to highlight the parallax narrative cues and link to screenshots.

## Implementation Notes

- **Renderer architecture**
  - Create a `StarfieldParallaxController` that owns multiple layers (background dust, mid-tier comets, foreground particles). Each layer should support:
    - Base velocity vector.
    - Wave-progress multiplier (0–1 from `waveController`).
    - Castle HP tint offset (map health % to color ramp: cyan → amber → red).
    - Optional particle density scaling for performance.
  - Feed deterministic seeds from `gameState.random` so smoke/tests stay reproducible even when parallax responds to gameplay.
- **Configuration**
  - Store tunables inside `apps/keyboard-defense/src/config/starfield.ts` with exported defaults and comments describing recommended ranges. Include:
    - `maxWaveSpeedMultiplier`
    - `breachTintColors`
    - `parallaxDepthOffsets`
    - `reducedMotionBehavior` (e.g., freeze parallax, keep tint only)
  - Expose CLI flags (`--starfield-depth`, `--starfield-static`) for diagnostics + screenshot generation to control the effect.
- **Diagnostics & analytics**
  - Add a diagnostics overlay card (and analytics snapshot fields) showing current parallax depth, tint, and active layer velocities (`starfield.depth=2.3`, `tint=#FFB347`).
  - Record events (`visual.starfieldStateChanged`) whenever wave progress or castle damage pushes the parallax controller into a new state; log them into smoke artifacts for regression monitoring.
- **Visual baselines**
  - Update `scripts/hudScreenshots.mjs` to accept `--starfield-scene tutorial|wave|breach` so we can capture consistent backgrounds showing each tint stage.
  - Ensure Playwright visual tests include updated baselines and fail with actionable error guidance when starfield visuals drift.
- **Performance safeguards**
  - Profile on low-end devices; consider capping particle counts when FPS drops below threshold (tie into diagnostics/perf metrics).
  - Guard the effect behind feature toggles so CI smoke can explicitly enable/disable parallax for deterministic results.
- **Docs**
  - Document tuning knobs in `apps/keyboard-defense/docs/ARCHITECTURE.md` and `HUD_NOTES.md`.
  - Update `docs/status/2025-11-07_starfield.md` with the new behavior, referencing diagnostics hooks + screenshot refresh flow.

## Deliverables & Artifacts

- `StarfieldParallaxController` + config + tests.
- Diagnostics + analytics updates capturing starfield state.
- Refreshed screenshots/Playwright baselines stored in `docs/hud_gallery.md`.
- Documentation + status updates describing tuning workflow and CLI flags.

## Acceptance criteria

- Starfield exposes parallax/tint reactions to wave progress + castle damage.
- Diagnostics overlay and config docs explain how to tune/verify the effect.
- HUD screenshot baselines capture the new visuals so visual regressions are
  obvious in Playwright diff reviews.

## Verification

- npm run test -- starfield
- npm run task:screenshots -- --ci --out artifacts/screenshots
- npx playwright test visual-diffs
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
