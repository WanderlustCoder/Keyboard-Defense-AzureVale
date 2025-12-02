# Post-Season Multiplayer / Co-op Parking Lot

Placeholder plan for future multiplayer and co-op experiments. **Not in active scope for Season 2**; keep the live game single-player, local-only, and kid-safe. Use this doc to capture ideas so we do not lose them, and to gate any future work behind clear criteria.

## Guardrails
- Audience: 8-16, Edge/Chrome, free game, no monetization.
- Privacy: no accounts, no chat/UGC, no tracking beyond local settings unless a guardian flow is designed.
- Safety: strict language filters for all surfaced text; no open text input in multiplayer until a safe-name system is proven.
- Art: keep cartoonish pixel art style consistent with current castle/defenders.
- Performance: low-graphics and reduced-motion modes must stay available in shared experiences.

## Prerequisites for any multiplayer exploration
- Stable single-player loop with curriculum coverage and good retention (daily/weekly goals met).
- Networking plan: transport choice (WebRTC vs. WebSockets), NAT fallback, and pause/latency behavior.
- Anti-abuse basics: rate limiting, replay validation, and tamper checks for wave data.
- Accessibility: existing focus traps, colorblind palettes, text sizing, and virtual keyboard must carry over.
- Analytics & QA: deterministic replays, bot harness coverage, and visual baselines for multiplayer HUD variants.

## Concept parking lot (do not build yet)
- **Co-op Castle Defense**: two players protect shared walls; alternate lanes or split roles (builder vs. typer).
- **Asynchronous “Ghost” Battles**: play against recorded runs of friends; no real-time chat required.
- **Boss Raids**: short timed encounters with layered words (numbers/punctuation) and shared shield mechanics.
- **Mentor Mode**: parent/coach sends curated drills; learner plays locally with “coach ghost” hints.

## Go/No-Go checklist (must be true before prototyping)
- Core curriculum delivered (letters, numbers, punctuation) with stable accuracy/WPM outcomes.
- Error and cheat handling defined; minimum fairness rules for word spawn and scoring.
- Content safety pass for any names/handles; safe-name generator ready.
- Hosting plan for session brokering and replay storage with size and retention limits.
- Legal/privacy review for minors; opt-in guardian notices if any networked feature is added.

## Non-goals right now
- No real-time text or voice chat.
- No cosmetics tied to payments or ads.
- No ranked ladders until fairness and anti-cheat are validated.

## Next steps when green-lit
- Build a small vertical slice (1 lane, 5-minute session) behind a feature flag.
- Reuse existing bot harness to simulate multi-client latency and packet loss.
- Update art backlog for co-op sprites (ally defenders, team banners) while staying in the pixel style.
