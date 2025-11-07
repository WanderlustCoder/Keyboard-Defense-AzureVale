## Canvas Resolution Scaling - 2025-11-18

**Summary**
- Canvas now measures its flex container and device pixel ratio, then sets an internal render size so ultra-small layouts draw fewer pixels without losing clarity. The ResizeObserver path updates the renderer whenever the HUD stack wraps or the player rotates their device.
- DPR-specific media queries now reapply the scaling math when the browser zooms or accessibility zoom toggles, so Retina/HiDPI displays stay sharp without manual refreshes.
- CanvasRenderer exposes a `resize` method that recalculates cached dimensions and clears pattern caches, ensuring post-resize renders stay crisp.
- Added shared `calculateCanvasResolution` helper plus unit tests, so future overlays/devtools can reuse the same scaling math.
- Diagnostics/Tutorial responsive work already benefits: small tablets drop the workload from 960px wide to whatever width is actually visible while keeping the CSS aspect ratio consistent.

**Next Steps**
1. Listen for `devicePixelRatio` media query changes so zooming on desktop or toggling accessibility resolution also retriggers the scaling pass.
2. Consider smoothing transitions (fade/hold frame) when the canvas resolution changes mid-wave so pause overlays aren't required during drastic rotations.
