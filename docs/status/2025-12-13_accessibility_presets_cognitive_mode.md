# Accessibility Presets & Cognitive Load Mode - 2025-12-13

## Summary
- Added a dyslexia-friendly preset button to the accessibility onboarding that enables the dyslexia font and wider spacing in one click, marking onboarding as complete (Season 4 backlog #48).
- Introduced a Reduced Cognitive Load toggle in Options that persists per profile, hides metrics/wave preview/battle log, mutes roadmap/debug/hint panels, and disables the panel visibility toggles while active (Season 4 backlog #49).
- Player settings bumped to carry the new preference, HUD/options wiring updated, and styles honor the new `data-cognitive-mode` flag for lower-visual-noise layouts.

## Verification
- `cmd /c npm test` (fails during `npm run build:dist` because Windows denied unlinking `public/dist/src/audio/ambientProfiles.d.ts`; lint/format phases completed beforehand).
- Manual: open accessibility onboarding and click the Dyslexia preset (font + spacing toggle on, overlay closes); toggle Reduced Cognitive Load in Options to hide metrics/wave preview/battle log and see the related panel toggles disabled until it is turned off.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/dist/src/utils/playerSettings.{js,d.ts}
- apps/keyboard-defense/tests/hud.test.js
- apps/keyboard-defense/tests/playerSettings.test.js
- apps/keyboard-defense/docs/season4_backlog_status.md
