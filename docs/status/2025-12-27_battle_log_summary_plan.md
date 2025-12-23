> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Battle log summary & filters plan

Goal: Make the battle log easier to skim without scrolling, surfacing the most important events (breaches, perfect streaks, medals, quests) with keyboard-friendly filters and castle/typing flavor.

### Objectives
- Add quick filters (Breach, Perfect, Medals, Quests, Upgrades) with keycap badges to jump to relevant entries.
- Provide a condensed summary strip above the log (counts, last event) that stays visible.
- Add pagination/virtualization to avoid long scroll; allow “pin” important events.
- Keep aria/live-friendly updates without overwhelming screen readers.

### Planned changes
1) **Summary strip**: small bar atop the log showing breach count, perfect words streak, medals earned, quests completed; clicking items scrolls/highlights matching log entries; keycaps for filters (e.g., Alt+B for Breaches).
2) **Filter pills**: toggle show/hide for categories; active state visible; “Clear” pill resets. Default to showing all, but auto-apply “Key Events” when viewport is short.
3) **Pin & jump**: allow pinning important entries (breach, medal, quest) to a “Pinned” mini-list above the log; click to jump/focus the original entry.
4) **Virtualized log**: limit rendered entries, with “Load more”/auto-append; keeps height stable and avoids scrolling the entire page.
5) **Keyboard/ARIA**: filters and summary items are buttons with `aria-pressed`; log entries mark role=listitem; live region throttled so only key events announce.
6) **Visual flavor**: breach icon (shield crack), medal icon, scroll icon for quests, keycap badges; reduced-motion-safe highlights.

### Testing
- DOM/unit: filter toggles, pinned list, jump-to-entry, summary counts update, reduced-motion guard, aria-pressed/live throttling.
- Visual/snapshot: summary strip and filters on wide/short viewports; ensure log height stays capped and doesn’t push playfield.

