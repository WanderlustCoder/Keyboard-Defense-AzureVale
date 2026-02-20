# Campaign Map Inspection UX Checklist (2026-02-20)

## Purpose

Focused M3 regression checklist for campaign map legend, hover tooltip, and keyboard-only node inspection.

## Scope

- Screen: `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapScreen.cs`
- Features:
- Micro-legend rendering
- Hover node detail tooltip
- Keyboard node inspection (`Tab` / `Shift+Tab`) and launch (`Enter`)

## Manual Verification Checklist

- [ ] Open campaign map and confirm legend panel is visible in lower-left region.
- [ ] Confirm legend text includes keyboard inspection hints (`Tab / Shift+Tab`, `Enter`).
- [ ] Hover an unlocked node and verify tooltip shows:
- Status
- Reward state (`available` or `claimed`)
- Lesson ID
- Resolved wave profile ID
- [ ] Hover a locked node and verify status reads `Locked`.
- [ ] Press `Tab` to cycle node inspection without moving mouse.
- [ ] Press `Shift+Tab` to reverse cycle direction.
- [ ] Confirm keyboard-focused node receives visible border emphasis.
- [ ] With keyboard focus on an unlocked node, press `Enter` and verify battle launch begins.
- [ ] With keyboard focus on a locked node, press `Enter` and verify no launch occurs.

## Expected Text Patterns

- Legend:
- `Tab / Shift+Tab: inspect nodes without mouse`
- `Enter: launch currently focused unlocked node`
- Tooltip:
- `Status: ...`
- `Reward: +{node.RewardGold}g available`
- `Reward: +{node.RewardGold}g claimed`
- `Wave profile: {profileId}`

## Notes

- This checklist supplements automated tests by covering runtime readability and interaction affordances.
