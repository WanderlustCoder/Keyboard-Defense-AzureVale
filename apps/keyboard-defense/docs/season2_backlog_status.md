# Season 2 Backlog Status (Rolling)

Quick status for the Season 2 backlog items referenced in `season2_backlog.md`.

| ID | Title | Status | Notes |
| --- | --- | --- | --- |
| 54 | Low-graphics toggle for weak devices | Done | Low graphics mode disables starfield/heavy effects, enforces reduced motion, and trims visuals for slow laptops. |
| 56 | Virtual keyboard (optional) for accessibility | Done | Toggle in options shows on-screen QWERTY highlighting the next key; hides by default. |
| 86 | Keyboard focus trap & ESC hotkey | Done | ESC now closes overlays or toggles pause; focus trap refocuses typing input when clicking non-interactive areas. |
| 94 | Loading screen with tips and pixel animation | Done | Rotating typing tips (3.8s), pixel bob animation with reduced-motion fallback, and doc `loading_screen.md` to edit tips safely. |
| 95 | Build-time lint/tests gate expanded to lesson JSON validator | Done | `npm run lint` now runs strict wordlist/lesson lint; pre-commit and CI enforce it. |
| 96 | Wordlist/lesson content lints | Done | Validator covers safe chars, denylist, lengths, sorting, gating; seed lists added. |
| 97 | Automatic playtest script (bot) to simulate key input for perf smoke | Done | `npm run playtest:bot` types headless via Playwright; writes summary artifact. |
| 98 | Visual regression baselines for core screens | Done | HUD/overlay baselines refreshed; new loading and caps-lock shots tracked. |
| 99 | Deployment checklist for browser compatibility (Edge/Chrome) | Done | `docs/deployment_checklist.md` added; smoke and accessibility steps captured. |
| 100 | Post-Season roadmap placeholder for multiplayer/co-op ideas (not active now) | Pending | Reserved for future planning; no multiplayer work in scope. |
