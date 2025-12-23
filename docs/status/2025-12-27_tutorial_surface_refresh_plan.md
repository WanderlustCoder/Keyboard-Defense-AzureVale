> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Tutorial surface refresh plan

Goal: Make tutorial hints/overlays faster to consume without covering the playfield, with castle/typing flavor and strong keyboard accessibility.

### Objectives
- Convert tall tutorial cards into compact, dismissible hints anchored near the playfield edges.
- Add a “Tutorial dock” to revisit steps without scrolling; keep progress visible.
- Preserve aria-live messaging but throttle chatter; respect reduced motion.

### Planned changes
1) **Hint anchors**: small edge-aligned hint cards (top-left/right) for current step; include keycap for continue/skip (e.g., `Enter`/`S`) and a close (X). Cards auto-shrink on short viewports.
2) **Tutorial dock**: collapsible strip with step list and status (done/active); opens a small modal to replay a step. Dock is keyboard focusable, lives above the playfield, remembers last position.
3) **Progress capsule**: tiny pill showing “Step 2/6 · Typing Basics”; clicking moves focus to the hint card; no scrolling required.
4) **Reduced-motion guard**: hints fade instantly when prefers-reduced-motion is on; otherwise use a 120ms fade/slide from edge.
5) **Accessibility**: aria-live polite on new hints; `aria-expanded` on dock; ensure closed hints are removed from tab order; keycap badges + `aria-keyshortcuts` for continue/skip.
6) **Persistence**: remember whether the dock is collapsed and last completed step per profile; hydrate safely on load.

### Testing
- DOM/unit: dock collapse/expand, hint visibility, aria-live throttle, keyshortcuts present, progress capsule link, reduced-motion guard.
- Visual/snapshot: short/wide viewports with hint anchors and dock; ensure no overlap with playfield text.

