# Loading Screen (Tips + Pixel Animation)

Purpose: soften initial load with useful typing reminders and a light pixel-art
animation while assets initialize. This is targeted at ages 8-16 and must stay
accessible in Edge/Chrome.

## Behavior
- Visible while assets/config load; hidden once `AssetLoader` is idle.
- Status text is updated during atlas/manifest/audio prep (`GameController`).
- Tips rotate every ~3.8s (skips rotation if only one tip).
- Prefers-reduced-motion: bobbing animation pauses automatically.
- `aria-live="polite"` + `aria-busy="true"` announce changes without noise.

## Visual Notes
- Pixel sprite: 3x3 blocky defender with a bob animation and soft glow.
- Card: glassy navy surface with subtle outline + shadow; width caps at 560px.
- Background: radial gradients over dark navy to keep focus on the card.
- Colors: align with accent blues; stay high-contrast on dark (#0f172a).

## Tips Source
Defined in `src/data/loadingTips.ts`. Keep the first tip aligned with the
default copy in `public/index.html` to avoid baseline churn in visual tests.
Tone: clear, encouraging, avoids jargon, age-appropriate, 1-line max.

## Accessibility
- All text stays readable at 100% font scale and respects HUD font scaling.
- Reduced-motion users still see the card and rotating tips (no bobbing).
- Screen readers hear the current status and tip; rotation interval is modest
  to avoid chatter.

## Editing Guide
- Add/edit tips in `src/data/loadingTips.ts`; avoid duplicates and keep it
  under ~14 entries to keep repetition low without a long cycle time.
- If visuals change, update Playwright baselines via
  `npm run test:visual:update` (loading screen project).
- Keep the pixel sprite simple (no multi-frame spritesheets yet); target 14-28
  px blocks with `image-rendering: pixelated`.
