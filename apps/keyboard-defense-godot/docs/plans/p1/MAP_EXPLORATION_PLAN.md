# Map Exploration Plan

Roadmap ID: P1-MAP-001 (Status: Not started)

## Map progression model
- Expand the grid with deterministic biome variants and POIs.
- Keep fog-of-war reveal rules consistent (discover per explore).
- Add map metadata for regions or tiers without changing sim RNG usage.

## Exploration reward loop
- Each explore reveals one tile and rolls a deterministic reward.
- Events/POIs should be data-driven and deterministic (hash-based selection).
- Rewards must respect action point constraints and resource pacing.

## UX requirements
- Maintain clear terrain legend and overlays for discovered/undiscovered tiles.
- Inspector panel must show tile type, POI/event info, and buildable status.
- Log entries must be short and readable for exploration outcomes.

## Acceptance criteria
- Exploration events are data-driven and deterministically repeatable.
- UI shows terrain, POIs, and exploration rewards without ambiguity.
- Headless tests validate event selection and reward ranges.

## Test plan
- Unit tests for map event table parsing and deterministic selection.
- Scenario tests for day exploration and reward outcomes.
- Manual checks: map overlay readability at 1280x720.

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/COMPARATIVE_MECHANICS_MAPPING.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/RESEARCH_SUPER_FANTASY_KINGDOM.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/extended/EVENT_POI_SYSTEM_SPEC.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`
