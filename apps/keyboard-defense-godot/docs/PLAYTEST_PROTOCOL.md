# Playtest Protocol

## Purpose
Validate that new players understand the typing-first loop, can navigate panels, and can complete a day/night cycle with clear feedback.

## Test environments
- Godot editor run (current default).
- Exported build (future) once the export pipeline is documented.

## Session script (30-45 minutes)
Phase A: First-run comprehension (10-15 minutes)
- Start the game and observe tutorial panel.
- Use core commands: `help`, `status`, `lesson`, `goal`, `map`.
- Toggle Settings, Lessons, Trend, and History panels.

Phase B: Day planning (10-15 minutes)
- Use `explore`, `build`, `inspect`, and `cursor` to plan a day.
- End the day with `end` and review the log for production events.

Phase C: Night defense (10-15 minutes)
- Type enemy words to defend; confirm safe prefix behavior.
- Use `wait` once to confirm step-based flow.
- Review typing report at dawn or game over.

## Data to capture
- Seed (if shown), day reached, lesson id, goal id.
- Health label (GOOD/OK/WARN) and trend summary.
- Accuracy, hit rate, backspace rate, incomplete rate.
- Confusion points or unclear UI labels.

## Bug reporting template
- Build version:
- Seed (if visible):
- Lesson / Goal:
- Steps to reproduce:
- Expected behavior:
- Actual behavior:
- Screenshot/video (if available):

## Exit criteria
- Player completes one day->night->dawn loop.
- Player can explain how to type enemy words to defend.
- No blocking UI or input focus issues observed.

## Sources (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/PLAYTEST_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/BALANCE_PLAYTEST_SCRIPT.md`
