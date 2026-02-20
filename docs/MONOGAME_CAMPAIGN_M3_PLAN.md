# MonoGame Campaign M3 Plan

## Milestone Objective

Deliver campaign map readability and pre-run clarity improvements:

- Add lightweight map legend guidance directly in campaign view.
- Add hover node detail tooltip with status, reward state, lesson, and wave profile.
- Preserve all existing campaign launch/progression behavior.

## Milestone Status

- Active as of February 20, 2026.

## Definition of Done

1. Campaign map renders a clear micro-legend for node state semantics.
2. Hovering a node shows concise, readable details for run planning.
3. First-clear reward state remains obvious on both card and tooltip.
4. Existing campaign launch flow remains unchanged.
5. Test suite remains green after campaign map UI polish changes.

## Ordered Task Backlog

1. [x] `CM3-001` Campaign map micro-legend
   - Add a compact legend panel describing unlocked/cleared/reward cues.
   - Keep visual style aligned with existing map palette.
2. [x] `CM3-002` Hover node detail tooltip
   - Show status, reward state, lesson ID, and resolved wave profile on hover.
   - Clamp tooltip position to viewport bounds for readability.
3. [ ] `CM3-003` Keyboard-only node inspection polish
   - Add keyboard focus/selection parity for node details (without mouse hover dependency).
   - Preserve existing launch controls and map navigation semantics.
4. [ ] `CM3-004` Map UX regression guardrails
   - Add or update checklist/test coverage for node detail readability and cue consistency.
   - Keep campaign map rendering performance and state transitions stable.

## Acceptance Checklist

- [x] Campaign map legend is visible and readable at runtime.
- [x] Hover tooltip shows node status, reward, lesson, and profile data.
- [x] Tooltip and legend coexist without obscuring top-bar controls.
- [ ] Keyboard-only inspection parity is implemented.
- [ ] M3 regressions are documented and covered by test/checklist artifacts.

## Out of Scope (for this milestone)

- Campaign chapter narrative/cinematic systems.
- Non-campaign battle mode feature expansions.
- Economy rebalance beyond campaign reward messaging clarity.
