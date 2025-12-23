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
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **Icon assets**
  - Deliver SVGs sized for 24×24 logical pixels with viewBox 0–24; keep strokes aligned to 1px grid to avoid blurring at DPR changes.
  - Store source files in `public/assets/icons/passives/` and add an optional CSS fallback using inline data URIs so storybook/tests can render without fetching.
  - If vector art isn't ready, use CSS mask + background color combos with tokens in `src/styles/tokens.scss`.
- **HUD wiring**
  - Introduce a `PassiveIcon` component that maps passive ids (`regen`, `armor`, `gold`) to asset URLs + `aria-label` strings, so both HUD and options overlay reuse the same logic.
  - Update condensed/mobile layouts (tutorial responsive work) to ensure icons shrink gracefully (min 16px) and align left of text with `gap: 0.5rem`.
  - Provide tooltip text describing the passive effect; reuse localization strings if available.
- **Options overlay + diagnostics**
  - Ensure the options passive list and diagnostics overlay share the same icon component for consistency.
  - When condensed (task #37), display icon-only rows with accessible labels; allow users to expand for text details.
- **Testing**
  - Extend HUD/unit tests to assert:
    - Icons render when passives active.
    - `aria-label` attributes exist.
    - Fallback text displays when assets missing (simulate network failure).
  - Add visual regression checks (Playwright) capturing HUD + options overlay.
- **Docs + artifacts**
  - Update `apps/keyboard-defense/docs/HUD_NOTES.md` with icon usage guidelines and color references.
  - Refresh `docs/hud_gallery.md` entries plus metadata to note icon presence.
  - Mention the workflow (regenerate icons, run `npm run task:screenshots`) inside `CODEX_PLAYBOOKS.md`.

## Deliverables & Artifacts

- SVG/icon assets + manifest entries.
- Shared `PassiveIcon` component + styles/tests.
- Refreshed HUD/options screenshots + gallery metadata.
- Documentation updates (HUD notes, playbook, status).

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






