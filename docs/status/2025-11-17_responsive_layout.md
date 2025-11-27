## Responsive HUD Layout & Touch Targets - 2025-11-17

**Summary**
- Reflowed the HUD/game layout below 1024px so the canvas stacks above a grid-based HUD that auto-fits two columns when space allows and collapses to one column on phones, preventing the sidebar from overflowing narrow screens.
- Added tablet/phone friendly padding plus horizontal scrolling safeguards for analytics tables, ensuring debug viewers and overlays remain usable without desktop-resolution widths.
- Options, wave scorecard, and main-menu overlays now pin to the top with reduced padding and scrollable cards so touch devices are no longer trapped by fixed-height modals.
- Coarse-pointer media queries enlarge buttons, selects, and text inputs (typing field, debug controls, telemetry endpoint) to at least 44px tall while keeping option toggles multi-line friendly for tap accuracy.

**Next Steps**
1. Audit the tutorial banners and passive logs for additional condensed states so very short, landscape phones avoid excessive scroll.
2. Consider dynamically rescaling the canvas render resolution on ultra-small devices so the WebGL/canvas workload matches the reduced viewport.

## Follow-up
- `docs/codex_pack/tasks/37-responsive-condensed-audit.md`
- `docs/codex_pack/tasks/21-canvas-dpr-monitor.md`
