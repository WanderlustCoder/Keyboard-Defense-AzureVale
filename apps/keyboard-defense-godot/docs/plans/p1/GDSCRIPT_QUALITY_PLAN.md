# GDScript Quality Plan (P1-QA-001)

## Problem statement
GDScript indentation drift and mixed whitespace can cause parse errors or subtle diffs. We need a lightweight quality plan that avoids breaking determinism and keeps diffs reviewable.

References:
- `docs/QUALITY_GATES.md`
- `docs/plans/p1/QA_AUTOMATION_PLAN.md`

## Options and evaluation criteria
Formatter criteria:
- Idempotent output on repeated runs.
- Godot 4 syntax support.
- CLI-friendly and fast.

Linter criteria:
- Detects common mistakes (unused vars, shadowing, invalid indentation).
- Fast enough for pre-commit usage.

## Proposed workflow
- Local optional pre-commit hook (future): format changed `.gd` files.
- CI stage (future): validate formatting and run headless tests.
- Always run headless tests after any `.gd` change (immediate guardrail).

## Minimal guardrails (immediate)
- Keep `.gd` diffs small and focused.
- Avoid mixed tabs/spaces; use project-standard indentation.
- Run `scripts/test.ps1` or `scripts/test.sh` after edits.

## Acceptance criteria
- No indentation-related parse errors in CI.
- Formatting tool selection documented with usage steps.
- Quality checks do not alter sim determinism.

## Future steps
- Evaluate formatter candidates and trial on a small subset of scripts.
- Add lint checks after formatter is stable.
