> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-27 - Collapsible menus plan

Context: Options/HUD overlays currently require scrolling below the playfield to reach many settings. Goal is to make menus collapsible, faster to navigate, and more accessible without vertical scrolling, especially on shorter viewports.

### Objectives
- Reduce vertical scroll by grouping settings into collapsible sections with sensible defaults.
- Keep critical controls (resume/pause, sound, reduced motion) always visible.
- Preserve accessibility: keyboard toggling, `aria-expanded`, focus order, reduced-motion-safe transitions.
- Persist user collapse choices per profile; adapt to viewport height.

### Scope (v1)
- Options overlay: audio, HUD/layout, accessibility, gameplay/visuals, overlays/shortcuts, diagnostics/debug.
- Quick-jump navigation at the top (pills/links) to jump to sections without scrolling.
- Collapse-all / expand-all controls plus auto-collapse on short viewports.

### Interaction rules
- Section headers are buttons with `aria-expanded`, toggle on Enter/Space/mouse. Focus stays within opened content.
- Default collapse policy: non-critical sections collapsed on short viewports; last user state restored from profile settings.
- Reduced-motion guard: use simple height/display toggles; avoid animated transitions when reduced motion is enabled.
- Two-column layout on wide screens; single-column with auto-collapse on narrow/short screens. Critical controls remain pinned.

### Implementation steps
1) Audit current sections and height drivers; capture target breakpoints and minimum visible controls.
2) Add layout container with sticky header and mini-nav for quick jumps.
3) Implement collapsible panels (CSS classes + data attributes) with optional max-height transitions; guard with reduced motion.
4) Extend options overlay state to store per-section collapse flags; persist in profile settings; hydrate on load.
5) Add “collapse all / expand all” buttons and viewport-height auto-collapse fallback.
6) Wire keyboard/focus logic; ensure tab order skips hidden content; add aria labels/expanded states.
7) Update tests: DOM/unit to verify aria/visibility/persistence; snapshot/visual for short/desktop viewports.

### Risks / mitigations
- Focus/ARIA regressions: cover with DOM tests for `aria-expanded`, focusable elements, and reduced-motion behavior.
- Overflow on tiny viewports: auto-collapse most sections and keep a slim “Quick Controls” strip always visible.
- Persisted states conflicting with new defaults: on first run after release, normalize stored flags to new groups.

### Success criteria
- Options overlay fits above the playfield on common laptop viewports without manual scrolling for primary controls.
- Keyboard users can toggle sections and jump between them without losing focus context.
- Collapse/expand state persists per profile and respects reduced-motion preferences.

