# Meta Progression Plan

Roadmap ID: P2-META-001 (Status: Not started)

## Goals
- Reward practice over time without forcing grind.
- Keep mastery aligned to lesson progression and typing goals.
- Avoid changing deterministic combat balance for core runs.

## Candidate meta systems
- Lesson unlock tracks (new lessons after milestones).
- Optional perk trees (minor convenience, not power spikes).
- Cosmetic unlocks (palette swaps, UI badges, titles).

## Persistence design
- Store meta progression in `user://profile.json`.
- Keep run-state data (resources, enemies, map) in `user://savegame.json` only.
- Do not alter RNG state or enemy word selection based on meta unlocks.

## Interaction with lessons/goals/trends
- Tie unlocks to lesson completion counts or goal pass streaks.
- Provide coach suggestions that reference unlocked practice paths.
- Ensure goals only change coaching thresholds, not run difficulty.

## Risks
- Power creep that trivializes early waves.
- Hidden difficulty spikes from progression locks.
- Overlapping progression systems causing confusion.

## Acceptance criteria
- Meta unlocks do not modify sim outcomes for the same seed/actions.
- Unlocks are optional and clearly communicated in UI.
- Progression is reversible or respec-friendly.

## References (planpack + research)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/PROJECT_ROADMAP.md`
- `docs/RESEARCH_SFK_SUMMARY.md`
