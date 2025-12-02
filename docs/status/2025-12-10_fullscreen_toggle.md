# Fullscreen Toggle - 2025-12-10

## Summary
- Added a fullscreen toggle button in the HUD header. It uses the browser Fullscreen API, updates its label/pressed state, and syncs automatically on `fullscreenchange`.
- Button disables itself if the Fullscreen API is unavailable to keep the HUD consistent on restricted platforms.

## Verification
- `cd apps/keyboard-defense && npm run serve:open`; click “Fullscreen” to enter and “Exit Fullscreen” to leave. The button should reflect the current state even if you exit via Esc or browser UI.

## Related Work
- `apps/keyboard-defense/public/index.html`
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/hud.ts`
- `apps/keyboard-defense/src/controller/gameController.ts`
