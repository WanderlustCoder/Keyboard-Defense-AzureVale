# Campaign Map Launch + Return Clarity Checklist (2026-02-20)

Purpose: Verify pre-launch confirmation cues and post-summary campaign return context clarity.

## Setup

- Open campaign map with at least one unlocked node.
- Complete one single-wave node and return through summary to campaign map.

## Checklist

- [x] Selection strip shows launch confirmation cue after first `Enter` on focused unlocked node.
- [x] Second `Enter` within confirmation window launches the focused node.
- [x] Launch confirmation expires if no second `Enter` is pressed in time.
- [x] Changing focused node clears pending launch confirmation state.
- [x] Returning from summary to campaign map shows return-context message banner.
- [x] Return-context banner uses outcome tone (reward/success/warning/neutral) color.
- [x] Returned node focus is synchronized to the campaign node associated with summary handoff.

## Notes

- Return context is handed off through `CampaignMapReturnContextService`.

## Execution Notes (2026-02-20)

- Automated and code-path verification completed:
- `CampaignMapLaunchFlowTests` validates confirm window, second-press launch, and focus-change cancellation.
- `CampaignMapScreenFlowIntegrationTests` validates combined keyboard-inspection + confirm launch flow and summary-return context pipeline.
- `CampaignMapReturnContextServiceTests` and `RunSummaryNavigationPolicyTests` validate summary handoff messaging/tone behavior and campaign-map return gating.
- `CampaignMapScreen` rendering logic confirms selection-strip confirmation cue and outcome-tone banner color mapping.
- Status: PASS.
