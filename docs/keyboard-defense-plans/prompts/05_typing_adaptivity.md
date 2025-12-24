# Codex prompt - Milestone E: typing adaptivity

## Goal
Introduce adaptive typing selection:
- track weak letters and common errors
- bias drill targets toward weak keys
- keep variety to avoid repetition

## Constraints
- Keep scoring and selection logic in scripts/TypingSystem.gd or a new helper.
- Add unit tests for selection logic.

## Landmarks
- scripts/TypingSystem.gd
- scripts/tests/test_typing_system.gd
- data/lessons.json (optional extensions)

## Acceptance
- scripts/run_tests.ps1 passes.
- Tests verify weak-key bias and variety rules.
