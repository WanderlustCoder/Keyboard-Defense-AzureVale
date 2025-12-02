# Backlog Slicing Plan - 2025-12-07

## Scope
Outlined manageable sub-tasks for remaining “Not Started” backlog items to enable incremental delivery.

## Slices
- **#63 Sprite atlas generation**
  - Add CLI `scripts/assets/buildAtlas.mjs` to pack `public/assets/sprites/*` into an atlas + JSON map (dry-run fixture first).
  - Update `AssetLoader` to consume the atlas with fallback to individual sprites when missing/disabled.
  - Wire atlas generation into build/dist behind a flag; tests cover atlas JSON shape, fallback path, loader selection.

- **#64 Deferred high-res asset loading**
  - Introduce dual-tier manifest (low-res then high-res) with a loader “ready” signal.
  - Gate high-res apply behind a feature toggle and surface status in diagnostics; respect reduced-motion.
  - Tests: fallback to low-res on failure, timing guard after first render, toggle on/off behavior.

- **#65 Projectile particle systems (offscreen canvas)**
  - Implement offscreen renderer stub with one lightweight effect (muzzle puff) and a frame-budget guard.
  - Respect reduced-motion and fallback to inline canvas when offscreen unsupported.
  - Tests: no-op without support, budget clamping, reduced-motion bypass.

- **#67 Castle visual morphing across upgrades**
  - Add per-level castle sprite references to config and renderer swap logic.
  - Hook into upgrade events; surface current visual tier in diagnostics.
  - Tests: upgrade changes sprite class/key; persisted state restores correct visual.

- **#70 Asset manifest generation from source sprites**
  - Create `scripts/assets/generateManifest.mjs` to scan assets and emit a hashed manifest.
  - Integrate into build/dist and integrity checks; provide “verify only” mode.
  - Tests: fixture snapshot generation and manifest-based integrity pass/fail.

- **#94 Visual regression harness for HUD layout snapshots**
  - Add Playwright project `visual` with deterministic seeds/fixtures and fixed viewport(s).
  - Capture key overlays (hud-main, options, tutorial-summary, wave-scorecard) to `baselines/visual`.
  - Add `npm run test:visual` using Playwright snapshot/pixelmatch with small tolerance; document baseline updates.

- **#91 Tutorial state tests for assist cues/replay/skip**
  - Extend tutorial manager tests to trigger assist threshold and assert cue state.
  - Add replay/skip flow assertions (completion/version reset, state clears).

- **#97 Tutorial summary modal snapshot tests**
  - Render summary overlay with fixture stats; capture DOM snapshot/HTML and assert key fields.
  - Wire into tutorial test harness with deterministic data.

- **#98 Soak test alternating tutorial replay/skip**
  - Add CLI/test loop that toggles replay/skip repeatedly, verifying persisted completion/version and stability.
  - Record summary of attempts and final completion flag.

## Next Action
- #94 harness delivered with cross-platform baselines in `baselines/visual`. Next priority: wire sprite atlas loading (#63) using the new atlas builder and add loader fallbacks/tests.
