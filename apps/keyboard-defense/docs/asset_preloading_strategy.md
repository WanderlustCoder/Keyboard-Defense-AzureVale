# Asset Preloading Strategy (Season 3 Item 94)

Goal: avoid hitching when enemies spawn, defeat VFX play, or overlays appear by decoding and caching assets ahead of time on Edge/Chrome laptops (offline-friendly). Applies to cartoonish pixel art, audio cues, and UI sprites. Single-player only.

## Guardrails
- Keep first-contentful paint fast: prioritize interactive HUD, typing input, and castle sprites.
- Respect reduced-motion and low-graphics toggles (skip heavy preloads when enabled).
- Stay offline-safe: all fetches are local; no network calls beyond packaged assets.
- Never block the main thread for long; use idle time and small batches.

## Asset Buckets and Order
1) **Critical:** sprite atlas, defeat frames, castle/turret sprites, HUD icons, keyboard/tip overlays.
2) **Interactive:** projectile frames, enemy variants, VFX particles, boss silhouettes.
3) **Cosmetic/ambient:** parallax layers, weather overlays, menu backgrounds.
4) **Audio:** keypress, hit/miss, wave start/end; load decode asynchronously.

## Runtime Plan
- **Startup:** load atlas + manifest; fall back to inline SVG sprites if manifest fails.
- **Idle prewarm:** once manifest is idle, decode the first N atlas frames (defeat sprites, castle icons) using `requestIdleCallback` fallback to `setTimeout`.
- **Wave lookahead (future hook):** before wave N+1 starts, enqueue its enemy/enemy-VFX frames if not cached; skip when low-graphics or reduced-motion is active.
- **Overlay prewarm (future hook):** when opening the main menu/options, prefetch UI icon set and keyboard highlights to avoid first-open jank.
- **Audio decode (future hook):** trigger `AudioContext.decodeAudioData` lazily after input focus to satisfy autoplay policies.

## How to Add New Assets
1) Add files under `public/assets/...` and regenerate the manifest (`npm run assets:manifest`).
2) If assets should preload, add their keys to the wave/overlay lookahead lists (once implemented) and keep them small (≤200KB per image, ≤1MB per atlas image).
3) For palette swaps or skins, reuse atlases when possible; avoid many tiny standalone PNGs.
4) Update `docs/season3_backlog_status.md` when a preloading milestone lands.

## Performance Notes
- Batch prewarm in groups of ~16-32 frames to prevent long tasks.
- Use `force-cache` on fetches (already used by the asset loader) to let the browser dedupe.
- Honor `prefers-reduced-motion` and low-graphics: do not preload optional VFX when enabled.
- Telemetry (future): record the first render timestamp for defeat VFX and overlays to catch hitches.

## Current Implementation Snapshot
- Manifest + atlas load first; inline SVG fallbacks exist.
- Idle prewarm decodes atlas frames after the manifest finishes (see `GameController.scheduleAssetPrewarm`).
- Status tracked in `docs/season3_backlog_status.md` under item 94.
