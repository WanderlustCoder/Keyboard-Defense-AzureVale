---
id: taunt-analytics-metadata
title: "Include taunt metadata in analytics/screenshots"
priority: P2
effort: M
depends_on: [ci-step-summary, diagnostics-dashboard]
produces:
  - analytics schema updates capturing taunt events
  - screenshot/CI metadata for active taunts
  - docs updates describing the fields
status_note: docs/status/2025-11-19_enemy_taunts.md
backlog_refs:
  - "#41"
  - "#79"
---

**Context**  
Taunts now appear in the HUD/log, but automation artifacts (analytics exports,
HUD screenshots) don't record which taunt was active. Reviewers want to know when
captures happen during special callouts.

## Steps

1. **Analytics snapshot changes**
   - Augment `analyticsSnapshot` to store the last taunt text, source unit,
     timestamp.
   - Update `docs/analytics_schema.md` accordingly.
   - Ensure CLI exports (gold summary, diagnostics) include these fields.
2. **Screenshot metadata**
   - Update `scripts/hudScreenshots.mjs` to append `taunt` info to the JSON
     summary so reviewers know which taunt was active.
3. **CI summary**
   - Extend `scripts/ci/emit-summary.mjs` to note if a taunt was captured
     (e.g., "Active taunt: Brute: 'I’ll crush your gates'").
4. **Tests**
   - Add targeted tests ensuring analytics snapshots capture taunt metadata and
     that the screenshot summary lists it when present.

## Implementation Notes

- **Analytics schema**
  - Snapshot fields should include:
    - `taunt.active` (boolean), `taunt.text`, `taunt.enemyType`, `taunt.waveIndex`, `taunt.timestampMs`.
    - Rolling counters (`taunt.countPerWave`, `taunt.uniqueLines`) to help dashboards detect repetition.
  - Update `docs/analytics_schema.md` + fixtures to reflect the new block; ensure CSV exports maintain deterministic column ordering.
- **Event instrumentation**
  - Emit `combat.tauntTriggered` events from the HUD/log when taunts fire, carrying localization key + resolved text.
  - Persist the latest event in `gameState.analytics` so snapshots and smoke artifacts can read it without scanning logs.
- **Screenshot metadata**
  - `scripts/hudScreenshots.mjs` should read the latest taunt from the analytics snapshot (or DOM attribute) and add:
    ```json
    {
      "taunt": {
        "text": "You will fall!",
        "enemyType": "Brute",
        "timestamp": "2025-11-19T18:45:12Z"
      }
    }
    ```
  - Surface the taunt as a badge/table row in `docs/hud_gallery.md` so reviewers know exactly what dialogue the screenshot captured.
- **CI summary & dashboards**
  - Extend `scripts/ci/emit-summary.mjs` (or a helper) to show the most recent taunt per scenario and flag when expected taunts are missing (e.g., tutorial smoke should record at least one).
  - Feed the same data into `docs/codex_dashboard.md` with a “Taunt spotlight” tile linking to artifacts/screenshots.
- **Testing**
  - Vitest coverage for analytics snapshot + event bridge.
  - CLI tests for `hudScreenshots` ensuring metadata JSON includes taunt info.
  - Markdown snapshot tests for the gallery + CI summary to catch formatting regressions.
- **Docs**
  - Update `docs/status/2025-11-19_enemy_taunts.md` once metadata lands, documenting how to regenerate fixtures and interpret dashboards.
  - Add guidance to `CODEX_PLAYBOOKS.md` (Analytics + UI sections) describing the taunt metadata workflow.

## Deliverables & Artifacts

- Analytics/state updates + fixtures capturing taunt metadata.
- Screenshot metadata enhancements + gallery updates.
- CI summary output highlighting taunts.
- Documentation + status updates explaining the new fields.

## Acceptance criteria

- Analytics exports and screenshots clearly record taunt details.
- CI summary surfaces active taunt info when present.
- Schema/docs updated.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run analytics CLI + screenshot script using fixtures to confirm taunt metadata
  appears in the summaries.
