## 2025-12-27 - UI navigation & quick-access plan

Context: Menus and HUD overlays require too much vertical scrolling and scatter controls. This plan complements the collapsible menu work by adding navigation aids, pinned quick controls, and responsive layouts so players reach key settings without leaving the playfield view.

### Objectives
- Keep essential actions visible: Resume/Pause, Sound toggle/volume, Reduced Motion, HUD/Layout, and Accessibility presets.
- Provide fast navigation to deeper sections via sticky mini-nav and inline jump links.
- Reduce vertical footprint with responsive columns and condensed cards, without breaking keyboard or screen reader flows.
- Maintain reduced-motion-safe behaviors and clear focus order.

### Plan
1) **Sticky quick bar** at the top of options overlay: Resume, Sound toggle/volume, Reduced Motion, HUD zoom/layout, Accessibility preset button. Remains visible while scrolling/collapsing other sections.
2) **Mini-nav pills**: Audio, HUD/Layout, Accessibility, Gameplay/Visuals, Overlays/Shortcuts, Diagnostics. Clicking/pressing jumps to the section and expands it if collapsed; shows active state.
3) **Responsive layout**: Two-column on wide screens; single-column on narrow/short with auto-collapse and smaller padding/margins. Cap max width and center content to avoid spanning the whole viewport.
4) **Condensed cards** for long lists (diagnostics, overlays shortcuts) with truncated previews and “expand details” control to avoid tall blocks.
5) **Keyboard/ARIA**: Pills and sticky bar items are focusable; `aria-current` on active pill; jump links move focus to section headers. Maintain `aria-expanded` on collapsible sections and skip hidden content in tab order.
6) **Persistence**: Store last open section and scroll/jump preference per profile alongside collapse state. Default to opening at the top with quick bar focused on first load.
7) **Visual hierarchy**: Clear headers, subtle dividers, consistent spacing tokens; avoid excessive drop shadows. Respect reduced motion for any subtle reveal transitions.
8) **Testing**: DOM tests for nav pills (jump + expand), sticky quick bar presence on short viewports, aria/current states, reduced-motion guards, and persistence rehydration. Visual/snapshot for wide vs short layouts.

### Risks / mitigations
- Sticky bar overlap: ensure top padding for underlying content and z-index audit; add reduced-motion-safe reveal.
- Focus jumps causing confusion: announce section jumps with `aria-live="polite"` hint; move focus to section header after jump.
- Persistence conflicts: normalize stored state on first run to avoid broken positions after release.
