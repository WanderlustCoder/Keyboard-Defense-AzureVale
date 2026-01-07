# Codex Milestone: Accessibility Settings System (Time/Contrast/Motion)

## Landmark: Objective
Implement the settings in `docs/keyboard-defense-plans/preprod/ACCESSIBILITY_SPEC.md`
so they can be used by gameplay and UI:
- time multiplier (affects prompt timers and wave pacing)
- high contrast UI mode
- reduced motion mode
- practice mode toggle

## Landmark: Tasks
1) Create a settings store
   - `apps/keyboard-defense-godot/scripts/settings/settings_store.gd`
   - typed settings object with defaults
   - signal or callback mechanism for UI and sim
2) Apply time multiplier
   - prompt timer calculations
   - optional enemy speed scaling
3) High contrast and reduced motion
   - theme or color constants
   - disable camera shake and heavy particles when reduced motion
4) Save integration
   - settings persist via save system
5) Tests
   - settings defaults and serialization
   - time multiplier affects computed timers deterministically

## Landmark: Verification steps
- `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
- manual: toggle settings in UI or a debug menu and observe effect

Summarize with LANDMARKS:
- A: Settings store
- B: Where settings are applied
- C: Tests and manual validation steps
