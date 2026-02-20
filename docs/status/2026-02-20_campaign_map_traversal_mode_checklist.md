# Campaign Map Traversal Mode Checklist (2026-02-20)

Purpose: Verify linear/spatial traversal behavior and runtime hinting in MonoGame campaign map.

## Setup

- Launch MonoGame app and open campaign map screen.
- Ensure at least one unlocked node is available.

## Checklist

- [ ] `F6` toggles traversal mode label between `Linear` and `Spatial` in legend.
- [ ] Selection summary strip reflects current traversal mode.
- [ ] `Tab` and `Shift+Tab` continue to cycle inspected node focus.
- [ ] `Q`/`E` cycle inspected node focus for compact-keyboard fallback.
- [ ] In `Linear` mode, arrow keys continue map scrolling behavior.
- [ ] In `Spatial` mode, arrow keys move focus to directional nearest nodes.
- [ ] In `Spatial` mode, `I`/`J`/`K`/`L` perform directional nearest-node traversal.
- [ ] Keyboard focus traversal auto-scroll keeps the focused node fully visible.
- [ ] Hovering a node no longer overrides keyboard focus unless mouse movement/click re-enters mouse inspection.
- [ ] `Enter` launches focused unlocked node in both traversal modes.
- [ ] Hover tooltip and keyboard inspection tooltip both remain readable after mode toggles.

## Notes

- This checklist is intentionally manual until campaign-map input flow tests are added.
