---
id: passive-iconography
title: "HUD passive iconography & quick parsing"
priority: P3
effort: M
depends_on: []
produces:
  - asset additions (icons/svg) or CSS classes
  - HUD/options overlay updates showing icons
  - screenshot fixtures covering new visuals
status_note: docs/status/2025-11-06_castle_passives.md
backlog_refs:
  - "#30"
---

**Context**  
Castle passives are listed as text only. Designers asked for visual icons so
players can quickly scan regen/armor/gold buffs in HUD and options overlay.

## Steps

1. **Icon design**
   - Create simple SVG/emoji-style icons for regen, armor, gold.
   - Place under `public/assets/icons/passives/` or inline data URIs.
2. **HUD integration**
   - Update `HudView` passive list to display icon + text (with tooltip).
   - Ensure condensed/mobile layouts keep icons legible.
3. **Options overlay**
   - Mirror icons in options passive list + summary.
4. **Accessibility/tests**
   - Provide `aria-label` descriptions (e.g., "Regen passive icon").
   - Update HUD tests to assert icon presence.
5. **Docs/screenshots**
   - Refresh HUD screenshots to capture the new icons.

## Acceptance criteria

- All passive lists show icons consistently (HUD + options overlay).
- Icons have accessible labels and degrade gracefully if assets fail to load.
- Tests/snapshots updated.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run `node scripts/hudScreenshots.mjs --ci` (or local variant) to ensure icons appear in artifacts.
