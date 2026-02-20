# Campaign Map Onboarding Hints Checklist (2026-02-20)

Purpose: Verify first-time-only campaign onboarding hints and dismissal persistence.

## Setup

- Use a profile/save without `campaign_map_onboarding_done` in progression data.
- Launch MonoGame app and open campaign map.

## Checklist

- [ ] On first campaign map entry, onboarding overlay appears automatically.
- [ ] Overlay includes guidance for inspect, traversal mode, and launch/return flow.
- [ ] `Enter`, `Space`, `Tab`, or left-click advances onboarding steps.
- [ ] `Esc` dismisses onboarding immediately.
- [ ] Completing or dismissing onboarding stores completion flag and suppresses future auto-show.
- [ ] Returning to campaign map in same session does not reopen onboarding.
- [ ] Restarting app/profile with persisted progression keeps onboarding hidden.

## Notes

- Completion flag: `campaign_map_onboarding_done` in `ProgressionState.CompletedAchievements`.
