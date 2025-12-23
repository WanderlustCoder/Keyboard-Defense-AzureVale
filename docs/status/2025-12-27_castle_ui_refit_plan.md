> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Castle UI refit plan (keyboard/defense flavored)

Theme: Keep the castle command HUD tight and battle-ready, with quick access to typing/defense controls without scrolling. Lean into the castle defense + keyboard mastery vibe (lanes, turrets, scrolls, quests).

### Objectives
- Surface high-priority controls “above the battlements”: pause/resume, sound, reduced motion, HUD zoom/layout, accessibility preset, and lane/turret hotkeys.
- Reduce scroll and clutter by condensing secondary panels (diagnostics, analytics, overlays) into expandable drawers and tabbed stacks.
- Preserve keyboard-first interaction: hotkeys for sections, focus rings, `aria-expanded`, and predictable tab order.
- Keep visual flavor: pixel parchment tabs, shield/turret icons, keycaps for shortcuts; reduced-motion-safe transitions.

### Planned changes
1) **Command strip** (sticky top): pause/resume, sound toggle/volume, reduced motion, HUD zoom/layout, accessibility preset, quest log + castle skin selector. Uses keycap-style buttons (e.g., `F1` for help, `Q` for quests) and remains pinned while scrolling.
2) **Tabbed stacks** for deep content: consolidate diagnostics, analytics, and overlays into tabbed panes (e.g., “Status”, “Analytics”, “Scrolls”, “Museum”, “Quests”) to avoid vertical sprawl. Tabs are keyboard-cyclable (Ctrl+Tab equivalent).
3) **Collapsible drawers** on the sides: optional slide-in for lane/turret helpers and typing drills; drawers auto-collapse on short viewports and remember last state per profile.
4) **Mini-map of sections**: castle-themed breadcrumb or mini-map showing which pane is open (turret icon for “Defense”, scroll icon for “Lore”, quill for “Quests”). Click or hotkey to jump without scrolling.
5) **Adaptive density**: auto-condense panels (smaller padding, compact lists) when viewport height is tight; auto-expand when height is ample. Reduced-motion guard keeps reveals instant.
6) **Keyboard shortcuts overlay**: a quick reference sheet (opened via `?`/F1) listing section hotkeys, lane/turret keys, and menu toggles; accessible with screen readers.

### Implementation notes
- Persist: command strip visibility, open tab, drawer states per profile; hydrate on load and normalize legacy states.
- Accessibility: `aria-selected` for tabs, `aria-expanded` for drawers; ensure hidden panels are removed from tab order; focus moves to active tab header on jump.
- Styling: pixel parchment tab headers, subtle shadowed cards, keycap badges for shortcuts; respect reduced motion and high-contrast modes.

### Testing
- DOM/unit: tab selection via click/keyboard, drawer open/close, aria states, focus management, persistence across reloads, reduced-motion behavior.
- Snapshot/visual: tall vs short viewports, left/right drawer alignment, command strip overlap checks.
- Regression: existing overlays (quests, museum, lore scrolls, certificates, medals) open correctly within the tabbed/condensed layout.

