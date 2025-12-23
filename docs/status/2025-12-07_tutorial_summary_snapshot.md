# Tutorial Summary Snapshot Tests - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a tutorial summary overlay snapshot test to ensure stat fields render deterministic text (accuracy, combo, breaches, gold) and CTA wiring remains intact.
- Harness reuses the in-app HUD markup to instantiate `HudView`, normalize the summary HTML, and assert CTA callbacks fire.
- Backlog #97 is now covered with DOM-level verification of the wrap-up modal.

## Verification
- `cd apps/keyboard-defense && npx vitest run tutorialSummarySnapshot.test.js`

## Related Work
- `apps/keyboard-defense/tests/tutorialSummarySnapshot.test.js`
- `apps/keyboard-defense/public/index.html` (tutorial summary markup)
- Backlog #97

