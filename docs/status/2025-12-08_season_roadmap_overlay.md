# Season Roadmap Overlay - 2025-12-08

## Summary
- Added a Season 1 roadmap catalog (`apps/keyboard-defense/docs/roadmap/season1.json`) plus an evaluator that scores each milestone by wave, castle level, tutorial completion, and lore unlocks.
- HUD now includes an interactive roadmap overlay (filters for story/systems/challenge/lore, optional completed visibility, progress pills, and a tracked-step capsule) and a glance widget in the HUD with persisted tracking preferences.
- GameController feeds tutorial/lore progress into the overlay; Escape closes the roadmap modal; preferences are stored safely with guards and tests around roadmap evaluation and persistence.

## Verification
- `cd apps/keyboard-defense && npx vitest run seasonRoadmap.test.js`

## Related Work
- `apps/keyboard-defense/public/index.html`
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/hud.ts`
- `apps/keyboard-defense/src/data/roadmap.ts`
- `apps/keyboard-defense/src/utils/roadmapPreferences.ts`
- `apps/keyboard-defense/tests/seasonRoadmap.test.js`
- Backlog #86
