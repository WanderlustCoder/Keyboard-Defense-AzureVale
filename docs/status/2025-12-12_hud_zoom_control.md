# HUD Zoom Control - 2025-12-12

## Summary
- Added a HUD zoom selector (90–120%) in the Options overlay to scale the entire HUD for small displays or low-vision comfort; persisted per profile and logged in HUD history.
- Introduced a new `hudZoom` player setting with normalization/clamping and storage version bump.
- Styling now respects `--hud-zoom` with smooth scaling, and the HUD options UI wires keyboard/focus interactions for the new control.

## Verification
- `cd apps/keyboard-defense && npm test` (covers HUD options wiring, persistence, and UI interactions).
- Manual: open Options overlay, adjust HUD Zoom; HUD scales immediately, persists across reloads, and stays independent of game canvas scale.

## Related Work
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/public/dist/src/utils/playerSettings.{js,d.ts}
- docs/season4_backlog_status.md (item 46 marked Done)
