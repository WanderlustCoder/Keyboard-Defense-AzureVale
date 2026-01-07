# Hero System Plan

Roadmap ID: P2-HERO-001 (Status: Not started)

## Hero role in the gameplay loop
- Optional hero/faction choice before a run.
- Small tactical bonuses that reinforce typing, not replace it.

## Ability activation model
- Typing-first commands (e.g., `ability shield`) or quick command aliases.
- Cooldowns tracked in sim; UI exposes ready state.
- Abilities must not require mouse input.

## Balance constraints and UI needs
- Bonuses must be readable and modest (no hard counters).
- HUD should show active hero, cooldowns, and effects.
- Inspector/log should explain why a bonus applied.

## Lesson alignment
- Hero bonuses should reinforce lesson goals (accuracy, backspace control, speed).
- Avoid bonuses that encourage reckless typing mistakes.

## Acceptance criteria
- Hero selection is optional and reversible.
- Abilities are deterministic and tested headless.
- UI clearly communicates hero effects.

## Test plan
- Unit tests for ability cooldown and effect application.
- Determinism tests for identical seeds/actions.
- Manual smoke: ability trigger via typing command.

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/COMPARATIVE_MECHANICS_MAPPING.md`
