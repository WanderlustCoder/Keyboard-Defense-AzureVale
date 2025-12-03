# Mastery Certificates - 2025-12-22

## Summary
- Added a print-ready Mastery Certificate overlay with learner name field (persisted), session stats (lessons, accuracy, WPM, best combo, drills, minutes), and a download/print button.
- New HUD panel and Options shortcut surface the latest certificate stats and provide quick access to the overlay; panel allows inline name editing.
- Certificate stats update live from session progress and lesson completions, so families can export or print a current snapshot at any time.

## Verification
- Open Options → Mastery Certificate (or the HUD panel) to view the overlay; edit the learner name and confirm it persists after closing/reloading.
- Complete drills/lessons and confirm the certificate stats update (lessons, accuracy/WPM, combo, drills, minutes).
- Use “Download / Print” to trigger the browser print dialog for saving to PDF.

## Related Work
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/public/index.html, apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/tests/hud.test.js
