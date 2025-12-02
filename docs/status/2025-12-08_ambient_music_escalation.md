# Ambient Music Escalation - 2025-12-08

## Summary
- Added ambient profile selector (`calm`, `rising`, `siege`, `dire`) driven by wave index/total and castle health, ensuring intensity ramps with siege progression and drops into “dire” when the castle is low.
- SoundManager now supports ambient loops (synthesized pads, fade transitions, intensity scaling, stop on mute) via WebAudio with safe guards for non-browser/test environments.
- GameController feeds the ambient selector each render so wave transitions update music automatically; muting stops ambient playback; intensity slider remaps ambient gain.

## Verification
- `cd apps/keyboard-defense && npx vitest run ambientProfiles.test.js`

## Related Work
- `apps/keyboard-defense/src/audio/soundManager.ts`
- `apps/keyboard-defense/src/audio/ambientProfiles.ts`
- `apps/keyboard-defense/src/controller/gameController.ts`
- `apps/keyboard-defense/tests/ambientProfiles.test.js`
- Backlog #88
