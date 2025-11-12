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
