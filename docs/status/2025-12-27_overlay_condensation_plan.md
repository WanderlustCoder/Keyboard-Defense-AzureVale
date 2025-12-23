> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Overlay condensation & layering plan

Goal: Make large overlays (quests, museum, lore, certificates, analytics) faster to scan and less overwhelming, while keeping castle/typing flavor and accessibility.

### Objectives
- Reduce vertical sprawl with collapsible sections, tabbed subviews, and inline summaries.
- Keep primary CTAs visible (close, print/download, open drill) without scrolling past the fold.
- Add contextual filters/pills to slice content (e.g., quest status, artifact type, scroll category).
- Maintain keyboard-first navigation and reduced-motion safety.

### Planned changes by overlay
1) **Quest overlay**: add status filter pills (Active/Completed); collapse quest descriptions by default with a “More” toggle; show progress bars inline; keep “Close” and “Open CTA” pinned at top/right.
2) **Museum overlay**: tabbed categories (Skins, Artifacts, Companions, Scrolls, Medals, Certificates, Drills). Each tab lists cards with small thumbnails and a quick stat line; expanded details on click.
3) **Lore scroll overlay**: left column scroll list, right column detail; preserve reading-friendly text size; add search/filter by title/category; ensure keyboard selection updates detail without scroll jumps.
4) **Certificates overlay**: condensed stats header (lessons, accuracy, WPM, combo, drills, time) with download/print buttons pinned; collapsible “Details” section for full breakdown.
5) **Analytics/Diagnostics overlays**: stack into tabs (“Summary”, “Traces”, “Exports”), add compact tables with horizontal scroll where needed, and a “copy link”/”export” mini-bar pinned.

### Interaction & layout
- Tab headers keyboard-focusable with `aria-selected`; remember last tab per overlay.
- Collapsible cards use data attributes for tests; hide content from tab order when collapsed; reduced-motion: no animated height when prefers-reduced-motion is set.
- Filters/pills show active state; optional “Clear” pill to reset filters.
- Sticky top bar per overlay: title + close button + primary CTA (download/print/open) to avoid scroll hunting.

### Testing
- DOM/unit: tab switching updates panels, aria state on tabs/collapsibles, filters hide/show entries, sticky bar exists, reduced-motion guard.
- Visual/snapshot: condensed museum/quest/lore/cert overlays in wide and short viewports; verify pinned controls remain visible.
- Regression: ensure existing overlay entry points still open the right default tab, and keyboard navigation sequences remain consistent.

