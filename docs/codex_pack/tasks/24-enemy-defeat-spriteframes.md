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
4. **Tests**
   - Add tests ensuring the renderer selects sprites when configured.
   - Ensure reduced-motion mode still bypasses animations.

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
