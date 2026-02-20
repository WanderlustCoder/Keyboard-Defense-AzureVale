# MonoGame Campaign Milestone M5 Plan

Status: Completed  
Last Updated: 2026-02-20  
Predecessor: `docs/MONOGAME_CAMPAIGN_M4_PLAN.md`
Successor: `docs/MONOGAME_CAMPAIGN_M6_PLAN.md`

## Objective

Improve campaign-map keyboard accessibility and interaction consistency by making traversal behavior explicit, configurable at runtime, and easy to validate.

## Scope

- Add traversal mode support (`Linear` and `Spatial`) for keyboard campaign-map inspection.
- Surface traversal mode state in on-screen help/inspection UI.
- Document M5 backlog slices and provide a focused manual checklist for traversal behavior.

## M5 Workstreams

## M5-01 Traversal mode toggle and runtime hinting

Status: Implemented in this slice

- Add runtime traversal toggle (`F6`) in `CampaignMapScreen`.
- Keep `Tab` and `Shift+Tab` cycling behavior available for deterministic keyboard inspection.
- In `Spatial` mode, use arrow keys for directional nearest-node traversal.
- Show active traversal mode in map legend and selection summary strip.

Acceptance criteria:

- Pressing `F6` changes traversal mode between `Linear` and `Spatial`.
- Selection summary text shows active traversal mode.
- Legend communicates current traversal mode and controls.
- Focused-node launch via `Enter` still works for unlocked nodes.

## M5-02 Focus retention and visibility polish

Status: Implemented in this slice

- Auto-scroll to keep keyboard-focused node visible after traversal.
- Ensure pointer hover does not permanently disrupt keyboard focus order.
- Add reduced-conflict keybind pass for map scroll/traversal on compact keyboards (`Q/E`, `IJKL`, `M` fallback toggle).

## M5-03 Validation and regression guardrails

Status: Implemented in this slice

- Keep a dedicated status checklist for traversal behavior.
- Add/expand campaign-map tests once test harness coverage is defined for screen input flows.
- Added deterministic traversal helper tests in `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapTraversalTests.cs`.
- Added input arbitration and compact-binding policy tests in `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapInputPolicyTests.cs`.

## Validation Artifacts

- `docs/status/2026-02-20_campaign_map_traversal_mode_checklist.md`
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapTraversalTests.cs`

## Out of Scope (M5)

- Reworking campaign map graph layout algorithm.
- Introducing controller/gamepad navigation for map nodes.
- Broad UI theming changes unrelated to campaign-map input and readability.
