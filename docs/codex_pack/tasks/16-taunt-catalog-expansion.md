---
id: taunt-catalog-expansion
title: "Expand taunt catalog for bosses/affixes"
priority: P3
effort: M
depends_on: []
produces:
  - expanded taunt metadata (wave configs + tier pools)
  - docs/taunts/catalog.json + validator CLI/tests
  - fixtures/tests covering new taunts
status_note: docs/status/2025-11-19_enemy_taunts.md
backlog_refs:
  - "#83"
  - "#87"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Current taunt support only covers a handful of tiers (brutes/witches) and two wave
spawns. Episode 1 bosses, affixes, and lore characters still lack voice lines, so
analytics/tests have limited coverage.

## Steps

1. **Catalog additions**
   - For each special unit (boss wave, affixes, elite variants), add an array of
     taunts under their tier config (`enemyTiers`, `waves`).
   - Ensure text references Episode 1 lore (Archivist Lyra, affix traits, etc.).
2. **Wave config coverage**
   - Update key wave JSON entries (boss wave, elite spawns) with `taunt` fields so
     they fire deterministically.
3. **Tests**
   - Extend HUD/unit tests to cover the new taunts (ensuring they rotate, respect
     condensed hint behavior, etc.).
4. **Docs**
   - Update `docs/status/2025-11-19_enemy_taunts.md` after implementation and list
     the new catalog entries.

## Implementation Notes

- **Data model**
  - Store taunts in `apps/keyboard-defense/src/data/taunts.ts` (or similar) with structure:
    ```ts
    type TauntEntry = {
      id: "brute_01";
      enemyType: "brute";
      rarity: "elite" | "boss";
      text: "I’ll crack your walls!";
      localeKey?: "taunt.brute.01";
      tags: ["episode1", "affix-frenzy"];
    };
    ```
  - Reference entries from wave configs (`waves/*.json`) via `tauntPool: ["brute_elite", "affix_arcane"]` so assignments stay deterministic.
  - Support optional audio hooks (`voiceLineId`) for future VO integration.
- **Authoring workflow**
  - Add a JSON/Markdown catalog (`apps/keyboard-defense/docs/taunts/catalog.json`) listing each taunt, source enemy, tags, and narrative reference. Use this as the single source of truth for localization.
  - Provide a CLI (`scripts/taunts/validateCatalog.mjs`) that ensures:
    - No duplicate IDs/text.
    - Required tags present (enemy type, episode).
    - Every catalog entry maps to a wave/enemy config.
- **Wave config updates**
  - Focus on Episode 1 high-visibility units: Archivist Lyra boss, affix elites (shielded, armored, slow aura), special lore events.
  - Ensure each target wave sets `tauntPool` or inline `taunt` with deterministic order so analytics can capture them.
  - For multi-phase bosses, allow sequential taunts (pre-phase, mid-phase, defeat).
- **HUD/analytics integration**
  - Ensure the HUD logging system pulls localized strings (fallback to English) and records `tauntId` for analytics (ties into task 17).
  - Add metadata to `uiSnapshot` so screenshot galleries can label which taunt is visible.
- **Testing**
  - Extend unit tests to assert:
    - Catalog validator catches duplicates/missing tags.
    - Wave configs referencing taunts can load without undefined entries.
    - HUD taunt rotation respects cooldowns and condensed states.
  - Add fixture-based tests to ensure analytics exports include new taunt IDs.
- **Docs & localization**
  - Document the catalog + CLI inside `apps/keyboard-defense/docs/HUD_NOTES.md`.
  - Update localization files with new keys and mention them in `docs/taunts/README.md`.
  - Refresh the status note with a table of newly added taunts per enemy.

## Deliverables & Artifacts

- Taunt catalog data + validator CLI + fixtures.
- Updated wave configs referencing new taunt pools.
- Tests (HUD, analytics, CLI) covering catalog integrity + runtime behavior.
- Documentation/localization updates + status note refresh.

## Acceptance criteria

- Every boss/affix/elite from Episode 1 has at least 2 taunts configured.
- Tests confirm HUD logging/hint behavior for the new taunts.
- Catalog documented so future episodes can append easily.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






