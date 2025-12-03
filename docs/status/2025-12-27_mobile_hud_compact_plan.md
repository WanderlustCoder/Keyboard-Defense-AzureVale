## 2025-12-27 - Mobile/short-viewport HUD compact plan

Goal: Ensure the HUD/options remain usable without scrolling on short viewports (small laptops, tablets in landscape), preserving the castle/typing feel and accessibility.

### Objectives
- Auto-compact layout on limited height: tighter padding, condensed lists, collapsible sections.
- Keep primary controls visible: pause/resume, sound, reduced motion, HUD zoom/layout, quest/museum buttons, hotkey rail.
- Maintain readability: no micro text; preserve contrast and focus rings; reduced-motion-safe transitions.

### Planned changes
1) **Viewport detection**: apply `data-viewport="short"` when height under a threshold; gate compact CSS, auto-collapse secondary sections, and pin the quick bar.
2) **Compact spacing tokens**: smaller vertical margins, reduced card padding, tightened list items for panels like quests, scrolls, museum. No change to font size unless user sets it.
3) **One-column defaults**: force single-column layout for options/HUD overlays on short viewports; reorder sections to keep critical controls first.
4) **Auto-collapse secondary panels**: diagnostics, analytics, overlays shortcuts default collapsed; “expand all” available but capped at a set height with internal scrolling to avoid full-page scroll.
5) **Floating action buttons** (FAB-like) for frequent actions: quest log, museum, side-quests; placed just below the playfield with keycap badges, respecting reduced motion and screen readers.
6) **Sticky headers**: section headers stick while scrolling within the overlay to keep context; subtle shadow; reduced-motion-safe.
7) **Testing hooks**: add `data-compact="true"` to toggle compact mode in tests; ensure aria-expanded and focus order still correct when compact rules apply.

### Testing
- DOM/unit: `data-viewport` toggling, compact class application, auto-collapse of secondary sections, sticky header presence, FAB visibility and labels.
- Visual/snapshot: short viewport baseline, ensuring no overflow beyond playfield; check FAB placement doesn’t overlap text.
- Accessibility: verify aria labels on FABs, `aria-expanded` on collapsed sections, and that tab order skips hidden content.
