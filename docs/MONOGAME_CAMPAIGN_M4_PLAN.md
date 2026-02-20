# MonoGame Campaign M4 Plan

## Milestone Objective

Deliver campaign progression UX clarity improvements with lightweight runtime guidance:

- Surface a compact selection summary strip for currently inspected campaign node.
- Keep keyboard and mouse inspection behavior consistent.
- Expand campaign map interaction guardrails and validation artifacts.

## Milestone Status

- Completed on February 20, 2026.

## Definition of Done

1. Campaign map displays an always-available selection summary strip.
2. Summary strip reflects inspected node status, reward state, and resolved profile.
3. Keyboard focus inspection and hover inspection use the same display semantics.
4. Campaign map guidance and checklist artifacts are updated for M4 interactions.
5. Test suite remains green after M4 scope changes.

## Ordered Task Backlog

1. [x] `CM4-001` Selection summary strip
   - Add compact strip showing inspected node label, status, reward state, and profile.
   - Keep strip readable without overlapping top controls.
2. [x] `CM4-002` Inspection parity consistency
   - Use shared inspected-node source for mouse hover and keyboard focus.
   - Expose current inspection mode (`Mouse` vs `Keyboard`) in strip text.
3. [x] `CM4-003` Focus navigation polish
   - Improve keyboard inspection traversal heuristics for dense maps.
   - Ensure focus progression remains intuitive across columns/rows.
4. [x] `CM4-004` M4 regression artifacts
   - Extend status checklist coverage for summary strip correctness.
   - Capture map UX validation notes for keyboard + mouse parity.

## Acceptance Checklist

- [x] Selection summary strip renders in campaign map runtime.
- [x] Summary strip updates for both hovered and keyboard-focused nodes.
- [x] Strip includes reward state and resolved wave profile information.
- [x] Keyboard focus traversal polish is completed.
- [x] M4-specific regression artifacts are documented.

## Out of Scope (for this milestone)

- Campaign narrative/chapter progression systems.
- New combat mechanics outside campaign map UX.
- Economy rebalance beyond reward-state clarity.
