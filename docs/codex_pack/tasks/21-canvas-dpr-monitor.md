---
id: canvas-dpr-monitor
title: "Canvas DPR monitor & transition smoothing"
priority: P2
effort: M
depends_on: []
produces:
  - canvas scaling updates (devicePixelRatio listener, smoothing)
  - tests verifying the behavior
  - documentation describing new hooks
status_note: docs/status/2025-11-18_canvas_scaling.md
backlog_refs:
  - "#53"
---

**Context**  
Canvas scaling now adapts to flex container width and base DPR, but we still need
to listen for dynamic `devicePixelRatio` changes and smooth transitions.

## Steps

1. **DPR listener**
   - Add `window.matchMedia("(resolution: Xdppx)")` watcher to re-run scaling when
     `devicePixelRatio` changes (zoom/accessibility toggles).
   - Debounce updates so we don’t thrash.
2. **Transition smoothing**
   - Introduce a short hold/fade frame when resolution changes mid-wave to avoid
     jarring pop-ins.
   - Consider locking the scene for a few frames or animating the change (configurable).
3. **Tests**
   - Add unit tests for the DPR listener (using `matchMedia` mocks) and smoothing logic.
4. **Docs**
   - Update canvas scaling doc/status once feature ships and reference the new hooks.

## Acceptance criteria

- Canvas resizing re-triggers automatically when `devicePixelRatio` changes.
- Transitions feel smoother (no sudden pop) thanks to the fade/hold.
- Tests cover the new behavior.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Manual test: adjust browser zoom / simulate DPR change and confirm canvas resizes smoothly.
