## 2025-12-27 - Typing lane & hotkey UX plan

Goal: Make lane/turret controls and typing helpers faster to reach without scrolling, leaning into the keyboard mastery + castle defense fantasy.

### Objectives
- Give clear, consistent hotkeys for lanes/turrets and display them as keycap badges across HUD and overlays.
- Add a compact “Hotkey rail” pinned near the playfield showing active bindings, cooldowns, and disabled states.
- Provide in-HUD tutorials/tooltips for new bindings without interrupting play; keep reduced-motion and screen-reader friendly.

### Planned changes
1) **Hotkey rail (pinned)**: a slim bar above the playfield listing lane select (1-5), turret types (Q/W/E/R), pause (P), options (Esc), quest log (Q), and help (?) with keycap visuals; shows disabled/cooldown with dimming and aria labels.
2) **Context badges**: keycap badges beside buttons (e.g., “Options [Esc]”, “Quest Log [Q]”, “Toggle HUD [H]”, “Collapse All [C]”) visible in options overlay and HUD panels, no scroll needed.
3) **Adaptive hints**: on first use or after a missed click, show a brief tooltip “Press 1–5 to focus lanes” or “Press Q/W/E/R to place turrets” that auto-dismisses; respects reduced motion and disappears after a few triggers.
4) **Profile persistence**: store “show hotkey rail” preference and “show hints” toggle per profile; default on for new players, off if reduced cognitive load is enabled.
5) **Accessibility/ARIA**: `aria-keyshortcuts` attributes on actionable controls; tooltips use `aria-live="polite"`; ensure badges are hidden from tab order but labels are announced.
6) **Conflict guard**: detect OS/browser reserved keys; if conflicts arise (e.g., Cmd+W), surface a “rebinding not yet supported” notice and hide badge for that key.

### Testing
- DOM/unit: hotkey rail renders with correct bindings, aria-keyshortcuts set, hints throttle and dismiss, reduced-motion guard, toggle persistence per profile.
- UX/manual: short viewport check (rail wraps or scrolls horizontally if needed), confirm no overlap with playfield text, verify disabled/cooldown visuals.
