# Deployment Checklist (Edge/Chrome, Free Single-Player)

Use this list before publishing builds or sharing milestones. Audience ages 8-16; runs in Edge and Chrome.

## Automated Gates
- `npm run lint` (includes strict wordlist/lesson lint) and `npm run format:check`.
- `npm run build` (regenerates dist + type checks).
- `npm test` (vitest suite) and, when art/UI changed, `npm run test:visual` (update baselines intentionally).
- `npm run assets:manifest:verify` and `npm run assets:integrity -- --check` for sprite/hash drift.
- `npm run assets:licensing -- --check` to ensure shipped assets have licensing/source metadata.
- `npm run serve:smoke` to ensure the dev server boots cleanly.

## Browser Smoke (Edge + Chrome)
- Load `/` fresh (no cache), confirm loading screen animation/tip, and that it dismisses automatically.
- Typing input: characters echo, caps-lock warning appears when toggled, focus is trapped in the input while typing.
- HUD controls: fullscreen toggle works (enter/exit), audio mute/intensity, readable font toggle, options overlay opens/closes.
- Game loop: start a wave, defeat an enemy, pause/resume, and confirm lives/gold update.
- Local storage: profile/tutorial flags persist across reload; clear storage and verify first-run tutorial appears.
- Assets: castle/enemy sprites render (no SVG fallbacks unless expected), SFX play on hits/defeat.
- Offline/PWA: load once online (service worker installs), toggle DevTools to Offline, then reload and confirm the game shell loads.

## Accessibility & Performance
- Keyboard-only navigation through main controls (options, fullscreen, audio).
- Focus rings visible; text meets contrast targets (WCAG AA) on HUD and overlays.
- Reduced motion: respect OS prefers-reduced-motion (starfield/animations tone down).
- Basic perf sanity: page responsive after start; no console errors; network requests stay under 1 MB on first load.

## Packaging/Release
- Version/build metadata stamped (CI artifacts or release notes).
- Publish notes include known issues and supported browsers (Edge/Chrome), no account requirements, no tracking beyond local storage.
