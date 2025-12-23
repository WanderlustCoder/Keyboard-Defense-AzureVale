# Left-Handed HUD Layout - 2025-12-12
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a “Left-Handed HUD Layout” toggle to the Options overlay that flips the HUD to the left of the game canvas (body dataset `hudLayout="left"`), easing reach for left-handed players.
- New player setting `hudLayout` (right/left) with normalization and version bump; persists per profile alongside HUD zoom.
- HUD sync applies the layout state immediately and exposes the toggle in tests to ensure wiring stays intact.

## Verification
- `cd apps/keyboard-defense && npm test` (full lint/build/dist + Vitest) — covers HUD options wiring including the new toggle.
- Manual: open Options → enable Left-Handed HUD Layout; HUD moves left, persists after refresh; combining with HUD Zoom still works independently of game canvas.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/tests/hud.test.js
- apps/keyboard-defense/docs/season4_backlog_status.md

