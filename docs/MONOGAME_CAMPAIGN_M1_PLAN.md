# MonoGame Campaign M1 Plan

## Milestone Objective

Deliver the first campaign-progression milestone after vertical-slice completion:

- Launch node battles from campaign map with node-specific wave profiles.
- Persist node completion and one-time node rewards through run summary.
- Return to campaign map with updated unlock state and reward feedback.

## Milestone Status

- Completed on February 20, 2026.

## Definition of Done

1. Campaign node victories mark completion in progression state.
2. Node rewards are granted exactly once per node.
3. Defeats preserve progression stats without granting node-complete rewards.
4. Run summary shows campaign node outcome messaging from shared progression service.
5. Regression tests cover profile resolution and campaign summary progression handoff.

## Ordered Task Backlog

1. [x] `CM1-001` Campaign node profile binding
   - Ensure campaign node IDs resolve to explicit or heuristic profile IDs.
   - Add catalog-level regression checks for shipped profile data.
2. [x] `CM1-002` Battle -> summary handoff contract
   - Use a typed handoff payload for campaign metadata passed into summary flow.
   - Keep retry flow on the same node/profile/reward metadata.
3. [x] `CM1-003` Campaign progression application
   - Apply victory/defeat progression updates from summary with one-time reward behavior.
   - Keep non-campaign summary runs side-effect free.
4. [x] `CM1-004` Campaign outcome feedback
   - Keep summary messaging consistent with progression outcome.
   - Use shared service message formatting and tone mapping.
5. [x] `CM1-005` Regression and determinism safety
   - Add/maintain tests for progression handoff, reward-once behavior, and mapping fallbacks.
   - Keep profile resolution tests isolated from parallel static-state interference.

## Acceptance Checklist

- [x] Campaign-node victory grants completion + reward once.
- [x] Repeat victory on same node does not grant additional node reward.
- [x] Defeat does not grant node reward and keeps retry messaging clear.
- [x] Summary messaging is derived from shared campaign outcome state.
- [x] Test suite covers node mapping, handoff, and reward semantics.

## Out of Scope (for this milestone)

- Multi-node chapter unlock cinematics.
- Expanded economy/building systems beyond single-node rewards.
- Narrative scripting beyond existing dialogue hooks.
