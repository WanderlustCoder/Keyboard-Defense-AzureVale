---
id: enemy-defeat-spriteframes
title: "Swap procedural defeat bursts with sprite-based frames"
priority: P3
effort: M
depends_on: []
produces:
  - sprite atlas entries for defeat frames
  - renderer updates toggling between procedural & sprite modes
  - docs/tests describing how to add new defeat art
status_note: docs/status/2025-11-07_enemy_defeat_animation.md
backlog_refs:
  - "#66"
---

**Context**  
We currently render enemy defeat bursts procedurally. Once art lands, we want an
easy path to layer sprite-based frames while keeping the procedural fallback.

## Steps

1. **Asset pipeline**
   - Add defeat sprite frames to the asset manifest (e.g., `public/assets/defeat/*.png`).
   - Update `assetIntegrity`/build scripts to hash the new assets.
2. **Renderer toggle**
   - Extend the renderer (CanvasRenderer/SpriteRenderer) to check for available
     defeat sprites; if present, play them instead of procedural bursts.
   - Keep a feature flag or fallback to procedural bursts when sprites missing.
3. **Configuration**
   - Document in `config.assetManifest` how to reference defeat frames.
   - Provide a `scripts/defeatFramesPreview.mjs` CLI (JSON + Markdown outputs) so art reviews can sanity check atlases before dropping them into `public/assets/`.
4. **Tests**
   - Add tests ensuring the renderer selects sprites when configured.
   - Ensure reduced-motion mode still bypasses animations.

## Implementation Notes

- Asset plumbing + renderer toggles now exist (player setting, CanvasRenderer sprite burst support, analytics breadcrumbs). This task now focuses on delivering the actual atlas assets + preview tooling.
- **Asset format**
  - Store defeat frames in a dedicated atlas (`assets/defeat/atlas.json`) generated via the existing sprite pipeline; include metadata such as frame duration, easing, tint overrides, and enemy type tags.
  - Support per-enemy overrides by naming conventions (`defeat_brute_01.png`) and fallback to `defeat_generic_*` when no match.
  - Update `assetIntegrity` manifest to include checksums for the atlas + individual PNGs so strict mode (task #31) can gate missing assets.
- **Renderer integration**
  - Extend `SpriteRenderer` with a `DefeatAnimationController` that:
    - Looks up the correct frame set based on enemy archetype.
    - Streams frames via `requestAnimationFrame`, respecting the existing animation budget.
    - Falls back to the procedural particle burst when no frames or when reduced-motion is enabled.
  - Add a config flag (`defeatAnimationMode: "auto" | "sprite" | "procedural"`) toggled via player settings and CLI (`--defeat-animation-mode` for smoke tests).
- **Performance considerations**
  - Preload defeat atlases during the loading screen, but only decode the frames once per archetype to avoid GC churn mid-wave.
  - Add a pool/reuse mechanism for sprite quads so repeated defeats don’t allocate new canvases.
- **Tooling**
  - Provide a `scripts/defeatFramesPreview.mjs` CLI that renders the sprites to a temporary canvas or generates GIF/WebP previews for art review; document usage in `apps/keyboard-defense/docs/HUD_NOTES.md`.
- **Docs**
  - Update `apps/keyboard-defense/docs/ARCHITECTURE.md` (rendering section) to describe how defeat animations resolve, plus `docs/CODEX_PLAYBOOKS.md` with steps for refreshing the atlas.
  - Include a “Drop-in checklist” in the status note or README: required directory structure, atlas metadata, CLI commands.

## Deliverables & Artifacts

- New sprite atlas files + manifest entries under `public/assets/defeat/`.
- Renderer/controller code + unit tests verifying sprite/procedural selection and reduced-motion handling.
- CLI preview script + documentation updates (architecture, playbook, status note).
- Updated analytics/fixtures if telemetry differentiates sprite vs procedural usage.

## Acceptance criteria

- Defeat sprites can be dropped into assets and render automatically.
- Procedural fallback remains for missing art.
- Tests cover both code paths.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Local manual test: drop sample sprites and confirm they display on defeat.
