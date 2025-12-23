# Lesson Medal Tiers - 2025-12-21
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added bronze/silver/gold/platinum medals to typing drills using accuracy/WPM/combo/error thresholds, with local history storage and per-mode best tracking.
- HUD panel + overlay surface the latest medal, per-mode bests, recent runs, and a replay hint; options now include a Lesson Medals shortcut.
- Typing drill summaries show the earned medal and a replay CTA to chase the next tier; medal progress syncs to the new HUD views and persists in storage.

## Verification
- Complete any typing drill and confirm the medal badge appears in the summary along with a replay button and next-tier hint.
- Open Lesson Medals from the HUD panel or Options overlay; verify best-per-mode cards render and history populates after runs.
- Reload the page and confirm medal state persists (badges + history still present).

## Related Work
- apps/keyboard-defense/src/utils/lessonMedals.ts
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/index.html, apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/tests/lessonMedals.test.js, apps/keyboard-defense/tests/hud.test.js

