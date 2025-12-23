> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Accessibility shortcuts & presets plan

Goal: Make accessibility tools instantly reachable from the HUD/options without scrolling, with castle/keyboard flavor and strong screen reader support.

### Objectives
- One-tap presets (Dyslexia, High Contrast, Reduced Motion, Large Text) exposed in a pinned strip and in the options quick bar.
- Clear keyboard shortcuts and aria-keyshortcuts for each preset; visible keycap badges.
- Contextual confirmations and safe fallbacks (no motion/flash) when toggling presets mid-play.

### Planned changes
1) **Accessibility strip** (pinned near quick bar): preset buttons for Dyslexia, High Contrast, Reduced Motion, Large Text, and a “Quick Test” entry. Uses keycap badges (e.g., `Alt+D`, `Alt+H`, `Alt+M`, `Alt+L`, `Alt+T`).
2) **Preset cards** in options: condensed cards with short descriptions and “Apply”/“Details” links. Cards collapse into a single row on wide screens, stack on narrow screens.
3) **Shortcut overlay**: pressing `Alt+/` opens a small overlay listing accessibility shortcuts; screen-reader friendly with `aria-live` gentle confirmation when a preset toggles.
4) **State persistence**: store last preset and custom mix; allow “restore default” button. Respect reduced-motion when enabling other presets (no animated transitions).
5) **Conflict guard**: detect browser/OS conflicts for modifiers; hide badges that would misfire (e.g., Alt+F4) and surface a “rebind not yet supported” note.
6) **Safety rails**: when High Contrast or Large Text is enabled, ensure overlays/tabs/accordions reflow without clipping; add QA hooks (`data-accessibility-active`) for tests.

### Testing
- DOM/unit: aria-keyshortcuts on preset buttons, strip visibility, overlay toggle via shortcut, persistence rehydration, reduced-motion guard, conflict hiding.
- Visual/snapshot: preset strip on wide and short viewports; confirm no overlap with playfield text and clear contrast on badges.
- Screen reader/manual: ensure announcements on toggle, focus order remains predictable, and “restore default” works.

