# MonoGame Campaign M2 Plan

## Milestone Objective

Deliver campaign progression hardening and player-facing clarity after M1:

- Preserve campaign progression side effects exactly once per summary lifecycle.
- Improve campaign map feedback for cleared vs uncleared nodes.
- Expand regression coverage around campaign retry and re-entry flows.

## Milestone Status

- Completed on February 20, 2026.

## Definition of Done

1. Campaign summary side effects (profile stats + progression) are idempotent.
2. Campaign map clearly communicates node status and expected reward semantics.
3. Retry/return flows keep campaign node metadata stable across transitions.
4. Regression tests cover retry and summary re-entry edge cases.

## Ordered Task Backlog

1. [x] `CM2-001` Summary side-effect safety
   - Prevent duplicate progression/profile writes if summary screen re-enters.
   - Keep behavior unchanged for first summary entry.
2. [x] `CM2-002` Campaign map status cues
   - Add explicit UI cues for first-clear reward availability vs already-cleared replay.
   - Keep node unlock/readability unchanged for existing progression.
3. [x] `CM2-003` Retry metadata parity
   - Ensure retry from summary preserves campaign node/profile/reward handoff metadata.
   - Validate parity with initial campaign node launch path.
4. [x] `CM2-004` Regression coverage
   - Add tests for no-double-apply behavior and retry metadata consistency.
   - Keep test isolation stable for static campaign data loaders.

## Acceptance Checklist

- [x] Summary progression and profile updates apply exactly once per summary instance.
- [x] Campaign map distinguishes first clear reward state from replay state.
- [x] Retry from summary targets same node/profile and preserves reward metadata.
- [x] Test suite covers M2 edge cases and remains fully green.

## Out of Scope (for this milestone)

- Full chapter/cinematic campaign layer.
- New non-vertical-slice combat systems.
- Economy overhaul beyond node reward signaling.
