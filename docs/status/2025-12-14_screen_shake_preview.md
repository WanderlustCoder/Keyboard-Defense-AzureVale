# Screen Shake Preview - 2025-12-14

## Summary
- Added a screen shake toggle with an intensity slider and inline preview tile in the Options overlay; the control defaults off, respects Reduced Motion, and persists per profile via player settings v27.
- Impact effects now drive a clamped canvas shake path when enabled, while the preview button reuses the same animation so players can test comfort before turning it on.
- HUD wiring, CSS, and tests cover the new controls, including labels, disabled states under Reduced Motion, and the stored intensity value.

## Verification
- `cd apps/keyboard-defense && npm test`
- Manual: open Options, preview shake with Reduced Motion on/off, enable shake and trigger hits/breaches to see mild canvas jiggle.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/dist/src/utils/playerSettings.{js,d.ts}
- apps/keyboard-defense/tests/hud.test.js
- apps/keyboard-defense/tests/playerSettings.test.js
- apps/keyboard-defense/docs/season4_backlog_status.md (#58)
