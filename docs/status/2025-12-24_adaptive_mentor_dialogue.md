## 2025-12-24 — Adaptive mentor dialogue (Season 4 backlog #70)

### What changed
- Added a mentor card to the companion panel that adapts between accuracy, speed, and balanced guidance based on live typing stats (accuracy, total inputs, WPM).
- Tips rotate per focus with cooldowns to avoid chatter and honor Reduced Motion styling; default text stays balanced until enough input data is present.

### Verification
- Ran `npm test` (full suite) after wiring the new HUD card and focus logic.
- Added HUD unit test to assert focus flips from accuracy to speed when stats change.
