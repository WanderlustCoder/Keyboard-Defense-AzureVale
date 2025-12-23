# Tutorial completion QA metric (2025-12-07)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- QA/static dashboard now reports tutorial attempt/completion counts and per-session completion rate.
- Scenario matrix runs carry tutorial completion data so each mode shows completions alongside status/duration.
- Dashboard payload includes `tutorialMetrics` for downstream automation/validation.

## Notes
- `generateStaticDashboard.mjs` renders completion rows for tutorial smoke and matrix tables; helper exports added for testability with CLI guard.
- Added coverage in `tests/staticDashboard.test.js` to assert completion rate formatting and DOM rendering via the inline script.
- `run-matrix.mjs` records attempted/completed/replayed counts to feed the dashboard.

## Validation
- `cd apps/keyboard-defense && npx vitest tests/staticDashboard.test.js`

