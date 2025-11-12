---
id: taunt-catalog-expansion
title: "Expand taunt catalog for bosses/affixes"
priority: P3
effort: M
depends_on: []
produces:
  - expanded taunt metadata (wave configs + tier pools)
  - fixtures/tests covering new taunts
status_note: docs/status/2025-11-19_enemy_taunts.md
backlog_refs:
  - "#83"
  - "#87"
---

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
