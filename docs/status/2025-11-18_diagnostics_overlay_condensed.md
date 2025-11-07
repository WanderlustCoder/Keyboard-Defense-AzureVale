## Diagnostics Overlay Compact Mode - 2025-11-18

**Summary**
- Diagnostics overlay now watches viewport height/width breakpoints and flips into a condensed card along the bottom edge on short or landscape-first screens, preventing it from obscuring the canvas.
- CSS adds scrollable max-height, reduced typography, and wider padding for the condensed state so telemetry lines remain readable without forcing desktop dimensions.
- Tests stub `window.matchMedia` to assert that the overlay automatically adds/removes the `data-condensed` flag, ensuring the behavior survives future refactors.
- Added a floating toggle that collapses verbose sections (gold events, turret DPS, passive details) when condensed, trimming scrolling to a single summary line until expanded.
- Automation can now detect condensed + collapsed state via `body.dataset.diagnosticsCondensed` and `body.dataset.diagnosticsSectionsCollapsed`, keeping screenshot tooling in sync with the responsive HUD.

**Next Steps**
1. Pipe the condensed-state signal into automation screenshots so mobile captures show the minimized diagnostics position.
2. Explore collapsing long telemetry sections (turret DPS, gold events) behind toggles when condensed to reduce scrolling even further.
