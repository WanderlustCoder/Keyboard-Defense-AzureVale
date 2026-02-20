# MonoGame Campaign Milestone M6 Plan

Status: Completed  
Last Updated: 2026-02-20  
Predecessor: `docs/MONOGAME_CAMPAIGN_M5_PLAN.md`

## Objective

Polish campaign flow clarity from map inspect to battle launch and post-battle return, with explicit onboarding cues for first-time campaign users.

## Scope

- Improve first-time campaign onboarding prompts and affordances.
- Tighten campaign node launch clarity (selected node, expected profile, reward state).
- Reduce confusion during summary return-to-map flow after single-wave runs.
- Add regression coverage for campaign navigation and summary handoff messaging.

## Planned Workstreams

## M6-01 First-time onboarding pass

Status: Implemented in this slice

- Add first-time-only campaign map hint stack (inspection, traversal mode, launch).
- Ensure hints can be dismissed and do not reappear every run.
- Align hint text with current keybinds (`Tab`, `Shift+Tab`, `Q/E`, `IJKL`, `Enter`).
- Persist completion in progression state via `campaign_map_onboarding_done` flag.

Acceptance criteria:

- New profile shows onboarding hints once.
- Returning users are not repeatedly interrupted.
- Hint copy matches actual input behavior.

## M6-02 Launch and return-flow clarity

Status: Implemented in this slice

- Highlight selected node intent in summary strip immediately before launch.
- Confirm campaign return messaging after win/loss/retry remains explicit and consistent.
- Ensure reward claim state is obvious on map after first clear.
- Added launch confirmation gating (`Enter` twice within a short window) for focused keyboard launch.
- Added campaign return-context handoff from summary to map with outcome tone messaging.

Acceptance criteria:

- Launch intent is visible before battle transition.
- Post-battle summary handoff copy remains accurate for reward claimed/unclaimed states.
- Returning to map preserves useful context for next decision.

## M6-03 Validation and guardrails

Status: Implemented in this slice

- Add test coverage for campaign onboarding display state and summary return messaging.
- Extend campaign checklist artifacts for onboarding and flow clarity.
- Keep docs index and milestone status synchronized with implemented slices.
- Added onboarding policy tests in `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapOnboardingPolicyTests.cs`.
- Added launch-flow and screen-flow integration tests in `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapLaunchFlowTests.cs` and `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapScreenFlowIntegrationTests.cs`.
- Added summary-handoff messaging regression tests in `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapReturnContextServiceTests.cs` and `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/RunSummaryNavigationPolicyTests.cs`.
- Updated launch/return clarity checklist with automated execution evidence in `docs/status/2026-02-20_campaign_map_launch_return_clarity_checklist.md`.

Milestone completion note:

- M6 objectives are satisfied with onboarding persistence, launch-confirm/return-context flow, and expanded regression coverage (502 passing tests in latest validation run).

## Out of Scope (M6)

- Reworking campaign graph topology or progression unlock requirements.
- Story-content authoring beyond minimal onboarding/flow support text.
- Controller/gamepad navigation implementation.
