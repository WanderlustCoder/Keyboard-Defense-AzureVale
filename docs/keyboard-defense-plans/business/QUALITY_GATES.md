# Quality Gates

## Gate 0 - Repo Hygiene
- `.\apps\keyboard-defense-godot\scripts\run_tests.ps1` passes
- Any linting step (if added) passes
- Export build succeeds for target platforms

## Gate 1 - Vertical Slice Stability
- No softlocks in a 30-minute run
- Save/load works for at least 10 consecutive in-game days
- Typing difficulty is adjustable and never blocks progress completely

## Gate 2 - MVP Content Stability
- No content definition can crash the game (validation enforced)
- Auto-tiling and atlas generation stable in CI
- Audio generator cannot produce NaNs or runaway gain

## Gate 3 - Release Readiness
- Versioned builds with changelog
- Store copy and core screenshots available
- Crash reporting stance documented
- Accessibility checklist reviewed



