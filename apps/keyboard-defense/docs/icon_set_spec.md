# Pixel UI Icon Set Specification

Guidelines for the pixel-art UI icons used across menus, HUD controls, and overlays. Target devices: Edge/Chrome laptops; audience ages 8–16. Style: cartoonish pixel art, crisp at 1x/2x scaling, readability-first.

## Canvas & Grid
- Base sizes: 16x16 for inline glyphs (icons in buttons, toggles, pills) and 24x24 for primary controls (roadmap, pause, fullscreen, audio).
- Pixel grid: align strokes and fills to the pixel grid; avoid subpixel AA.
- Padding: leave 2px safe inset on 16x16 and 3px on 24x24 to prevent clipping when scaled.
- Stroke: 1px outer stroke; interior details 1px; avoid double strokes unless width >= 3px.
- Corners: prefer 90° or 45° angles; round corners via 1px chamfers, not AA curves.

## Palette
- Base light: `#e2e8f0` (text), `#cbd5e1` (secondary).
- Accent primary: `#38bdf8` (fill) with stroke `#0ea5e9`; hover accent `#60a5fa`; active accent `#1d4ed8` shadow.
- Success: `#34d399` fill, `#0f766e` stroke. Warning: `#fb923c` fill, `#c2410c` stroke. Danger: `#f87171` fill, `#b91c1c` stroke.
- Disabled: base fills `#1f2937` with stroke `#111827` and highlight dots `#334155`.
- Outline glow for focus: single 1px halo using `rgba(96, 165, 250, 0.55)` on 24x24 only.

## States
- Default: solid fill + stroke per palette above; no shadow.
- Hover: brighten fill by ~10% and lift via 1px lighter top edge.
- Active/pressed: darken fill by ~12% and inset a 1px top edge.
- Disabled: swap to disabled palette; remove interior details except silhouettes.
- Focus-visible: add halo (see palette) outside stroke; keep shape unchanged.

## Icon Set (16x16 unless noted)
- Check/tick, X/close, minus, plus, chevron left/right/up/down (for toggles and drawers).
- Pause (two bars), play triangle, stop square (24x24 variants for media controls).
- Fullscreen in/out (24x24) matching HUD toggle: corners arrows pointing outward/inward.
- Speaker/mute, volume low/high (24x24), wave count using 2–3 bars.
- Settings/gear (24x24), info “i”, help “?”, warning triangle, success badge.
- Roadmap/map pin (24x24) matching current HUD roadmap button silhouette.
- Keyboard glyph (24x24) for typing overlays; shift keycap for shift training tips.
- Colorblind eye icon with diagonal stripe; dyslexia/reading aid book icon (24x24).
- Font size A+/A- pair (16x16) for HUD font scale control.
- Caps-lock indicator (16x16) up-arrow with dot.

## Export & Naming
- Export individual PNG sprites: `ui/icon-<name>-<size>.png` (e.g., `ui/icon-fullscreen-in-24.png`).
- Provide a combined sprite sheet for UI: `ui/icons-1x.png`, `ui/icons-2x.png`, with JSON mapping `{ name, x, y, w, h }` aligned to 32px grid slots for ease of packing.
- Keep monochrome source masters (aseprite/psd) with locked palette; avoid embedded color profiles.

## Integration Notes
- Icons live in the HUD/theme namespace; reserve game-entity sprites for enemies/defenders separately.
- When used inside buttons, center both horizontally and vertically; ensure minimum 12px clickable padding around glyph in CSS.
- Respect reduced-motion: no pulsing; focus halo only. Hover lifts via color, not motion.
- For dark theme only; if a light theme ships later, plan a tone-inverted sheet with identical geometry.
