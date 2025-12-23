---
id: visual-diffs
title: "Enable Playwright visual regression gating"
priority: P1
effort: M
depends_on: [ci-step-summary]
produces:
  - tests/visual/*.spec.ts
  - playwright.config.ts (modified)
status_note: docs/status/2025-11-06_hud_screenshots.md
backlog_refs:
  - "#94"
traceability:
  tests:
    - path: apps/keyboard-defense/tests/renderHudGallery.test.js
      description: HUD gallery rendering + metadata
    - path: apps/keyboard-defense/tests/hudScreenshotsMetadata.test.js
      description: HUD screenshot metadata validation
  commands:
    - npx playwright test --config playwright.config.ts --project=visual
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
`hudScreenshots.mjs` captures PNGs. Convert core screens into **diff‑gated** baselines.

## Steps

1) In Playwright tests, add scenarios for `hud-main`, `options-overlay`, `tutorial-summary`, `wave-scorecard` using your debug hooks.
2) Use `expect(page).toHaveScreenshot('hud-main.png', { maxDiffPixelRatio: 0.01 })` with animations disabled.
3) Commit baselines under `tests/__screenshots__/` and enable diffs in CI.

## Acceptance criteria

- PRs fail on visual diffs; summary links to diff artifact.
- Baseline update path documented (e.g., label `update-screenshots`).

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npx playwright test --config playwright.config.ts --project=visual --grep \"hud-main|options-overlay|tutorial-summary|wave-scorecard\"

## Snippet

See `snippets/playwright.config.additions.ts` for minimal config additions.






