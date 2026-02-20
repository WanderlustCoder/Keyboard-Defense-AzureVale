# Campaign Map Selection Strip + Navigation Checklist (2026-02-20)

## Purpose

Focused M4 regression checklist for selection summary strip correctness and keyboard traversal behavior.

## Scope

- Screen: `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapScreen.cs`
- Features:
- Selection summary strip
- Keyboard traversal polish for inspection focus
- Hover/keyboard inspection parity

## Manual Verification Checklist

- [ ] Open campaign map and verify selection summary strip is visible near top of map area.
- [ ] Confirm strip shows guidance text when no node is inspected.
- [ ] Hover a node and confirm strip updates with:
- Node label
- Node status (`Cleared`, `Ready`, or `Locked`)
- Reward state (`available` or `claimed`)
- Resolved wave profile
- Inspection mode label `Mouse`
- [ ] Move mouse off nodes and use `Tab` to start keyboard inspection.
- [ ] Confirm focused node highlight appears and strip inspection mode changes to `Keyboard`.
- [ ] Use `Shift+Tab` and confirm reverse traversal.
- [ ] Use arrow keys (`Left`/`Right`/`Up`/`Down`) and confirm directional focus stepping feels column/row aware.
- [ ] Press `Enter` on focused unlocked node and verify battle launch begins.
- [ ] Press `Enter` on focused locked node and verify no launch occurs.

## Expected Text Patterns

- `Inspect [Mouse] ...`
- `Inspect [Keyboard] ...`
- `Reward: +{node.RewardGold}g available`
- `Reward: +{node.RewardGold}g claimed`
- `Profile: {profileId}`

## Notes

- This checklist is intended as a runtime UX guardrail complementing automated progression tests.
