# Release Readiness Checklist (Season 3 Drop)

Edge/Chrome, ages 8-16, single-player, free, cartoonish pixel art. Use this before tagging a release.

## Functional & Gameplay
- Tutorials: intro + assists verified; skip/replay flows clean.
- Campaign + practice runs: no soft-locks; pause/resume safe.
- Typing input: caps/num lock indicators work; buffers purge correctly; backspace/ctrl+backspace paths verified.
- Dynamic difficulty: comfort targets met (use `npm run analytics:difficulty-tuning` on fresh bot runs).
- Accessibility toggles: reduced motion, brightness, dyslexia spacing, lock indicators, readable font apply immediately and persist.
- Onboarding/local storage: player settings read/write without version errors; save migration not needed or verified.

## Performance & Stability
- Perf budgets met (see `docs/performance_budget.md`): fps ~60, draw calls/particles within limits, heap watchdog not warning during 10+ waves.
- Asset loading: manifest/atlas valid; prewarm runs; no first-use hitches for new sprites/effects.
- Memory: no leak across repeated runs; reduced-motion + low-graphics paths render essential cues.
- Dev server smoke: `npm run serve:smoke` and `npm run serve:start-smoke` pass.

## Visual & Audio
- HUD readability at 1280x720 and condensed layout; brightness slider, font scale, dyslexia spacing confirmed.
- Reduced-motion visual variant: defeat effects and UI transitions respect toggle.
- Audio mix: volumes respect sliders; no clipping; calm vs intense loops transition cleanly; mute works.

## QA & Content
- Enemy/trap behaviors pass `docs/qa_enemy_behaviors.md`.
- Typing edge cases: run `docs/qa_typing_edge_cases.md` scenarios.
- Wordlist lint: `npm run lint:wordlists:strict` clean.
- Visual baselines: `npm run test:visual:auto` (or update snapshots with review).
- Assets integrity: `npm run assets:manifest:verify` and `npm run assets:integrity` clean.

## Analytics & Telemetry
- Codex pack/status validation: `npm run codex:validate-pack` and `npm run codex:validate-links`.
- Telemetry toggle honored; export works when enabled; diagnostics overlay available for dev builds.
- Gold/typing analytics scripts still pass (`npm run analytics:gold:check`, `npm run telemetry:typing-drills` if applicable).

## Packaging & Ops
- Build pipeline: `npm run build` and `npm test` pass on clean tree.
- Release notes drafted (summary, accessibility wins, performance notes).
- Version/tag plan confirmed; semantic-release config unchanged.
- Smoke instructions recorded for manual reviewers: dev server URL, credentials not required.
