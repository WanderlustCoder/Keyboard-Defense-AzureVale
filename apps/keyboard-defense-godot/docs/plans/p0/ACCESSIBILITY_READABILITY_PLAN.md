# P0 Accessibility and Readability Plan

Roadmap IDs: P0-ACC-001

## Focus areas
- Font size and panel density for HUD, wave panel, and reports.
- Contrast and color reliance (text must still be clear in grayscale).
- Keyboard-only navigation and focus behavior across panels.
- Reduced noise options (sparklines toggle already exists).

## UX constraints
- Typing-first flow remains primary; no required mouse actions.
- Do not hide PASS/NOT YET behind color alone.
- Maintain consistent command bar focus and safe Enter rules.

## Candidate improvements
- Add font scale and high-contrast toggles (UI-only prefs).
- Optional compact HUD mode with fewer lines.
- Consistent panel headers and spacing rules.

## Planning references
- `docs/plans/planpack_2025-12-27_tempPlans/generated/UI_UX_ACCESSIBILITY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/ACCESSIBILITY_SPEC.md`

## Acceptance criteria
- Panels remain readable at 1280x720 without truncation.
- Every panel is reachable and dismissible via keyboard.
- Accessibility toggles persist in `user://profile.json`.

## Test plan
- Manual: run through panels with only keyboard input.
- Add headless tests for new UI preference defaults.
