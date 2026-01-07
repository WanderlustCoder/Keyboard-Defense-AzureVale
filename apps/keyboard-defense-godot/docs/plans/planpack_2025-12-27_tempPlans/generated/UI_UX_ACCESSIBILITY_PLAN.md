# UI, UX, and Accessibility Plan

## Purpose
Improve readability, navigation, and accessibility while keeping a typing-first
interaction model.

## Sources
- apps/keyboard-defense-godot/docs/ROADMAP.md
- apps/keyboard-defense-godot/docs/PROJECT_STATUS.md
- apps/keyboard-defense-godot/docs/COMMAND_REFERENCE.md
- docs/keyboard-defense-plans/UX_CONTROLS.md
- docs/status/*_plan.md (UI/navigation/accessibility plans, 2025-12-27)

## Scope
- Command bar discoverability and help surfaces.
- HUD/panel readability and layout consistency.
- Keyboard navigation and focus order across panels.
- Accessibility toggles for motion, contrast, and font scale.

## Workstreams
1) Command bar and onboarding UX
   - Add in-context hints and a short primer for day/night commands.
   - Ensure help surfaces are accessible without mouse.
2) HUD readability and hierarchy
   - Normalize panel spacing, typography, and contrast.
   - Consolidate dense overlays to avoid information overload.
3) Keyboard navigation
   - Audit focus order for map, panels, and settings.
   - Ensure consistent hotkeys and rebindable actions.
4) Accessibility options
   - Add reduced motion and extra legibility toggles.
   - Support high-contrast modes and larger fonts.
5) UI plan alignment
   - Incorporate the 2025-12-27 UI plan docs (navigation, HUD compacting,
     overlay condensation, and accessibility shortcuts).

## Acceptance criteria
- HUD/panel layout tests pass for main scenes.
- All panels and settings are reachable via keyboard.
- Accessibility toggles have visible state and persist across sessions.
- Help/command primer reduces first-run friction without blocking play.
