# Performance Budget (Edge/Chrome, Ages 8-16)

Guardrails for visuals, audio, and runtime load to keep the game smooth on typical school laptops (Edge/Chrome, 1280x720 target). Applies to Season 3 content drop and ongoing art/audio additions.

## Targets
- 60 fps sustained during waves at 1280x720; brief dips to 50 fps max during heavy effects.
- Time to interactive (from load) <= 2.5s on warmed cache, <= 5s cold.
- Main thread frame time budget: 12 ms average, 16 ms worst on typical waves.
- GPU overdraw: <= 3x in densest lanes; avoid full-screen blends.
- Audio: no clipping; mix peak below -1 dBFS; concurrent SFX <= 8.

## Metrics & Budgets
- Draw calls: <= 250 per frame during combat; <= 350 during boss VFX.
- Sprites on screen: <= 120 (enemies + projectiles + UI fx). Favor atlased quads; avoid individual textures.
- Particle count: <= 400 live; cap per effect to 60 and set lifetimes <= 800 ms.
- Overdraw hotspots: limit layered glows/shadows to 2 layers per entity; prefer masked sprites over translucent quads.
- CPU: per-frame scripting <= 6 ms (logic + typing + spawners). Pathfinding kept to lane grids; no per-frame allocations in hot loops.
- Memory (process): steady-state < 400 MB after wave 10; asset preloading should not exceed 150 MB on top of base.
- Audio: simultaneous loops (music + ambient + up to 2 layered) plus max 8 SFX. Fade/duck instead of stacking.
- Network/asset size: initial payload <= 6 MB gzipped; lazy-load heavy art/audio in background; keep atlas pages <= 2048x2048.

## Sprite & Atlas
- Atlas pages: 2048x2048 max, RGBA; prefer combining idle/attack frames by unit type.
- Pixel art defenders/enemies: idle/attack/death frames stitched; reuse palettes to reduce texture switches.
- Castle damage states share a page to avoid swaps during cracks/breaks.
- UI icons: 32x32 and 48x48 packed together; avoid standalone PNGs.

## Effects & Particles
- Use baked spritesheets for spells (fire/ice/lightning/ward) instead of runtime shape drawing.
- Cap concurrent spell impacts to 3 per lane; fall back to simplified hit flashes beyond that.
- Screen-space flashes: limit to 1 at a time; keep alpha < 0.35; duration <= 180 ms.
- Motion: respect reduced-motion toggle; fall back to alpha-only fades when enabled.

## Audio
- Music: 2 loops (calm/intense) with crossfade <= 1200 ms; levels around -18 LUFS integrated.
- SFX: normalize to -6 dB peak; avoid overlapping duplicate hits by debouncing identical clips within 120 ms.
- Voice/coach (future): duck music by 4 dB and SFX by 2 dB during callouts.

## Measurement & Verification
- Dev overlay (`npm run serve:monitor`) to watch fps, draw calls, overdraw flags if available.
- Memory watchdog (Diagnostics overlay) shows heap usage; warns once >82% of `jsHeapSizeLimit`.
- Playtest bot + telemetry (`npm run playtest:bot`) to stress input without human variability.
- Profiling passes: Chrome DevTools performance + memory snapshots after wave 10 and boss wave.
- Visual regression (`npm run test:visual:auto`) to ensure budget-friendly effects remain visible after trims.

## Change Discipline
- For new VFX, record expected particle counts, texture pages touched, and lifespan in PR notes.
- When adding art/audio, update asset manifest and confirm atlas/loop sizes against these budgets.
- If a feature exceeds a budget, document the exception and mitigation (e.g., reduced particle counts on low-spec). 
