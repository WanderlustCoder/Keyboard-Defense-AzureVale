# Campaign Map Reward Cues Checklist (2026-02-20)

## Purpose

Focused UI verification checklist for campaign node reward cue rendering after CM2.

## Scope

- Screen: `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapScreen.cs`
- Cue states:
- First-clear reward available
- First-clear reward claimed

## Manual Verification Checklist

- [ ] Launch campaign map with an uncleared reward node.
- [ ] Confirm node line contains `First clear: +<gold>g available`.
- [ ] Confirm reward line uses highlighted reward color (`ThemeColors.GoldAccent`).
- [ ] Complete the same node and return to campaign map.
- [ ] Confirm node line changes to `First clear: +<gold>g claimed`.
- [ ] Confirm claimed line uses dimmed color (`ThemeColors.TextDim`).
- [ ] Replay cleared node and verify text remains `claimed` (no reset to `available`).

## Expected Text Patterns

- `First clear: +{node.RewardGold}g available`
- `First clear: +{node.RewardGold}g claimed`

## Notes

- This checklist is a UI artifact for CM2-002 and is intended to accompany automated progression tests.
