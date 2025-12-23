# Contrast Audit Overlay - 2025-12-15
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a Contrast Audit overlay to the Options menu that scans common UI regions (HUD, options, scorecards, diagnostics, roadmap) and highlights low-contrast areas with on-screen markers plus a summary list.
- The audit is launched from a dedicated button (non-persistent), respects Reduced Motion, and uses live DOM colors to flag warnings/failures against the 4.5:1 target.
- HUD wiring, controller hook, styles, and overlay markup are included so the audit can be rerun anytime without toggling settings.

## Verification
- `cd apps/keyboard-defense && npm test`
- Manual: open Options → run Contrast Audit; expect overlay markers/list; close via the X button; verify highlights update if colors change.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/tests/hud.test.js
- apps/keyboard-defense/docs/season4_backlog_status.md (#60)
- apps/keyboard-defense/docs/changelog.md

